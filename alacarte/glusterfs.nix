{ inputs, outputs, lib, pkgs, config, ... }:
# Turnkey GlusterFS for identical, dynamically-named borg drones.
#
# Every drone gets the exact same config. On boot each drone:
#   1. creates a btrfs subvolume for its brick at ${brickRoot}
#      (nested inside the existing /stateful subvolume -- no repartitioning,
#      works on already-installed drones and fresh installs alike),
#   2. runs glusterd (natively, or in a container deployed by doco-cd),
#   3. runs gluster-bootstrap every 2 minutes. On the *leader* this probes
#      every peer, and once all of them are connected creates + starts the
#      replicated volume. On every node it makes sure the volume is started.
#   4. mounts the volume at `mountPoint` on first access (automount), so
#      containers can just bind-mount it.
#
# The leader is whichever drone matches the FIRST entry of the peer list
# (by hostname or by any of its IPs), or any drone holding the marker
#   /stateful/sys-data/gluster/leader
# Only the leader ever probes / creates, which avoids two drones forming
# separate pools that can never be merged.
#
# Peer list: set `services.glusterCluster.peers` in flake.nix, or drop one
# address per line into /stateful/sys-data/gluster/peers (the file wins).
# With no peers at all, bootstrap stays idle and you can drive gluster by hand.
#
# Per-node state (all persisted):
#   /stateful/var/lib/glusterd            glusterd state, native mode (node UUID, peers, volumes)
#   /stateful/sys-data/gluster/glusterd   glusterd state, container mode
#   /stateful/gluster/<volume>            the brick (own btrfs subvolume)
let
  cfg = config.services.glusterCluster;

  stateDir = "/stateful/sys-data/gluster";
  glusterdState = "${stateDir}/glusterd";
  brickRoot = "/stateful/gluster";
  brickDir = "${brickRoot}/${cfg.volumeName}";

  native = cfg.daemon == "native";
  glusterCli =
    if native
    then "${pkgs.glusterfs}/bin/gluster --mode=script"
    else "${pkgs.docker}/bin/docker exec ${cfg.containerName} gluster --mode=script";
  daemonUnit = if native then "glusterd.service" else "docker.service";

  peersStatic = lib.concatStringsSep "\n" cfg.peers;
  optionsFile = pkgs.writeText "gluster-volume-options"
    (lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k} ${v}") cfg.volumeOptions));
in
{
  options.services.glusterCluster = {
    enable = lib.mkEnableOption "turnkey replicated GlusterFS volume across the drones" // { default = true; };

    daemon = lib.mkOption {
      type = lib.types.enum [ "native" "container" ];
      default = "native";
      description = ''
        "native": NixOS runs glusterd itself (no image to build, ordered properly at boot).
        "container": glusterd is deployed by doco-cd from compose/glusterd/ in this repo;
        NixOS only prepares the brick, persists state, bootstraps and mounts.
      '';
    };

    containerName = lib.mkOption {
      type = lib.types.str;
      default = "glusterd";
      description = "container_name of the doco-cd deployed glusterd (container mode only).";
    };

    peers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "borg-drone-d5a1" "borg-drone-1a2b" "borg-drone-3c4d" ];
      description = ''
        Addresses (Tailscale MagicDNS names, DNS names or IPs) of every drone in the
        cluster, including this one. The first entry is the bootstrap leader.
        Overridden by /stateful/sys-data/gluster/peers if that file exists.
      '';
    };

    volumeName = lib.mkOption {
      type = lib.types.str;
      default = "gv0";
    };

    replica = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Replica count. null = one full copy on every peer. Peer count must be a multiple of it.";
    };

    brickQuota = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "200G";
      description = ''
        Cap the brick subvolume with a btrfs simple quota so a full volume can't fill
        /stateful (and the drone with it). null = no quota (quotas cost some btrfs performance).
      '';
    };

    volumeOptions = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = { "network.ping-timeout" = "10"; };
      description = "gluster volume set options, (re)applied whenever they change.";
    };

    mountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/mnt/${cfg.volumeName}";
      description = "Where every drone mounts the volume (bind this into containers).";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      # Client side (mount.glusterfs + gluster CLI) is needed in both modes.
      environment.systemPackages = [ pkgs.glusterfs ];
      system.fsPackages = [ pkgs.glusterfs ];

      # Brick: its own btrfs subvolume nested inside /stateful.
      # Nested subvolumes are skipped by snapshots of /stateful, which is what
      # you want -- a rolled-back brick would fight its replicas.
      systemd.services.gluster-brick-prep = {
        description = "Prepare GlusterFS brick subvolume and state dirs";
        wantedBy = [ "multi-user.target" ];
        before = [ daemonUnit ];
        requiredBy = lib.optional native "glusterd.service";
        unitConfig.RequiresMountsFor = [ "/stateful" ];
        path = [ pkgs.btrfs-progs pkgs.coreutils pkgs.util-linux ];
        serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
        script = ''
          set -eu
          mkdir -p ${stateDir} ${glusterdState}
          chmod 0700 ${stateDir}

          if [ ! -e ${brickRoot} ]; then
            if [ "$(stat -f -c %T /stateful)" = btrfs ]; then
              btrfs subvolume create ${brickRoot}
            else
              echo "gluster-brick-prep: /stateful is not btrfs, using a plain directory" >&2
              mkdir -p ${brickRoot}
            fi
          fi
          # The brick lives one level down so gluster never sees a bare mount/subvolume root,
          # and a missing subvolume shows up as a missing brick instead of silently writing to /.
          mkdir -p ${brickDir}

          ${lib.optionalString (cfg.brickQuota != null) ''
            if btrfs subvolume show ${brickRoot} >/dev/null 2>&1; then
              btrfs quota status /stateful >/dev/null 2>&1 || btrfs quota enable --simple /stateful
              btrfs qgroup limit ${cfg.brickQuota} ${brickRoot}
            fi
          ''}
        '';
      };

      # Idempotent bootstrap, re-run on a timer so drones can come up in any order.
      systemd.services.gluster-bootstrap = {
        description = "Probe GlusterFS peers and create/start the volume";
        after = [ "gluster-brick-prep.service" daemonUnit "network-online.target" "tailscaled.service" ];
        wants = [ "network-online.target" ];
        path = [ pkgs.coreutils pkgs.gnugrep pkgs.gawk pkgs.iproute2 pkgs.getent ];
        serviceConfig.Type = "oneshot";
        script = ''
          set -u
          G="${glusterCli}"
          VOL=${lib.escapeShellArg cfg.volumeName}

          # --- peers: file overrides flake list -------------------------------
          if [ -s ${stateDir}/peers ]; then
            PEERS="$(grep -v '^\s*\(#\|$\)' ${stateDir}/peers | tr -d '[:blank:]')"
          else
            PEERS=${lib.escapeShellArg peersStatic}
          fi
          if [ -z "$PEERS" ]; then
            echo "gluster-bootstrap: no peers configured (services.glusterCluster.peers or ${stateDir}/peers); idle"
            exit 0
          fi
          NPEERS=$(printf '%s\n' "$PEERS" | grep -c .)
          LEADER=$(printf '%s\n' "$PEERS" | head -n1)

          # --- wait for glusterd -----------------------------------------------
          if ! $G pool list >/dev/null 2>&1; then
            echo "gluster-bootstrap: glusterd not reachable yet; will retry"
            exit 0
          fi

          # --- volume exists: keep it started, apply option changes ------------
          apply_options() {
            want=$(sha256sum ${optionsFile} | cut -d' ' -f1)
            [ "$(cat ${stateDir}/options.applied 2>/dev/null)" = "$want" ] && return 0
            ok=1
            while read -r k v; do
              [ -n "$k" ] || continue
              $G volume set "$VOL" "$k" "$v" || ok=0
            done < ${optionsFile}
            [ $ok = 1 ] && echo "$want" > ${stateDir}/options.applied
          }

          if $G volume info "$VOL" >/dev/null 2>&1; then
            if ! $G volume info "$VOL" | grep -q '^Status: Started'; then
              $G volume start "$VOL" || true
            fi
            apply_options
            exit 0
          fi

          # --- only the leader builds the pool and the volume ------------------
          is_leader() {
            [ -e ${stateDir}/leader ] && return 0
            for n in "$(uname -n)" "$(uname -n | cut -d. -f1)"; do [ "$n" = "$LEADER" ] && return 0; done
            local_ips=$(ip -o addr show | awk '{print $4}' | cut -d/ -f1)
            for a in $(getent ahosts "$LEADER" | awk '{print $1}' | sort -u); do
              printf '%s\n' "$local_ips" | grep -qx "$a" && return 0
            done
            return 1
          }
          if ! is_leader; then
            echo "gluster-bootstrap: not the leader ($LEADER); waiting for it to create $VOL"
            exit 0
          fi

          for p in $PEERS; do
            $G peer probe "$p" >/dev/null 2>&1 || echo "gluster-bootstrap: probe $p failed (not up yet?)"
          done

          CONNECTED=$($G pool list | grep -c 'Connected')   # includes localhost
          if [ "$CONNECTED" -lt "$NPEERS" ]; then
            echo "gluster-bootstrap: $CONNECTED/$NPEERS peers connected; will retry"
            exit 0
          fi

          REPLICA=${if cfg.replica == null then "$NPEERS" else toString cfg.replica}
          BRICKS=""
          for p in $PEERS; do BRICKS="$BRICKS $p:${brickDir}"; done

          echo "gluster-bootstrap: creating $VOL (replica $REPLICA):$BRICKS"
          if [ "$REPLICA" -gt 1 ]; then
            $G volume create "$VOL" replica "$REPLICA" $BRICKS || exit 0
          else
            $G volume create "$VOL" $BRICKS || exit 0
          fi
          $G volume start "$VOL"
          apply_options
        '';
      };

      systemd.timers.gluster-bootstrap = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "2min";
        };
      };

      # Client mount on every drone. Automount = mounted on first access, so boot
      # never hangs waiting on the cluster and containers starting early just retry.
      fileSystems.${cfg.mountPoint} = {
        device = "localhost:/${cfg.volumeName}";
        fsType = "glusterfs";
        options = [
          "_netdev"
          "noauto"
          "nofail"
          "x-systemd.automount"
          "x-systemd.mount-timeout=30s"
          "x-systemd.after=${daemonUnit}"
          "x-systemd.after=network-online.target"
        ] ++ lib.optional (cfg.peers != [ ])
          "backup-volfile-servers=${lib.concatStringsSep ":" cfg.peers}";
      };

      # Only matters if the firewall is ever turned back on.
      networking.firewall = {
        allowedTCPPorts = [ 24007 24008 ];
        allowedTCPPortRanges = [ { from = 49152; to = 49251; } ]; # one port per brick
      };
    }

    (lib.mkIf native {
      services.glusterfs = {
        enable = true;
        useRpcbind = false;          # only needed for gluster's legacy NFS server
        enableGlustereventsd = false;
        # Keep brick processes (and therefore mounts) alive when glusterd restarts
        # during nixos-rebuild / autoUpgrade.
        killMode = "process";
      };

      # Root is tmpfs: glusterd state (node UUID, peers, volume defs) must persist,
      # or every reboot turns the drone into a stranger to its own cluster.
      environment.persistence."/stateful".directories = [ "/var/lib/glusterd" ];
      systemd.services.glusterd = {
        after = [ "gluster-brick-prep.service" "tailscaled.service" ];
        unitConfig.RequiresMountsFor = [ "/var/lib/glusterd" "/stateful" ];
      };
    })
  ]);
}
