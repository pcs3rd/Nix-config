{ inputs, outputs, lib, pkgs, config, ... }:
# k3s in HA mode (embedded etcd) for identical, dynamically-named hosts.
#
# Every host gets the exact same config: role = server. What differs per node
# lives in /stateful (persisted), and a preflight unit turns it into a k3s
# config file at boot:
#
#   /stateful/sys-data/k3s/token         shared cluster secret (required on every node)
#   /stateful/sys-data/k3s/cluster-init  touch this on the FIRST node only -> bootstraps etcd
#   /stateful/sys-data/k3s/server        (optional) join URL, overrides `joinAddr` below
#
# Bootstrap:
#   1st drone:  openssl rand -hex 32 > /stateful/sys-data/k3s/token
#               touch /stateful/sys-data/k3s/cluster-init
#               systemctl restart k3s
#   others:     copy the same token file over,
#               echo https://<first-drone>:6443 > /stateful/sys-data/k3s/server   (or set joinAddr)
#               systemctl restart k3s
#
# Once a node has joined, its etcd data lives under /var/lib/rancher and the
# marker files no longer matter (k3s ignores --server / --cluster-init on an
# existing member).
let
  stateDir = "/stateful/sys-data/k3s";
  runConfig = "/run/k3s-borg/config.yaml";

  # Baked-in join address used when a node has no ${stateDir}/server file.
  # Point it at something that always resolves to a live server
  # (e.g. a DNS name with every drone's IP, or a kube-vip VIP). Empty = require the file.
  joinAddr = "";
in
{
  services.k3s = {
    enable = true;
    role = "server";
    tokenFile = "${stateDir}/token";
    configPath = runConfig;
    gracefulNodeShutdown.enable = true;
    extraFlags = [
      "--write-kubeconfig-mode=0600"
    ];
  };

  # Build the per-node k3s config from the markers in /stateful before k3s starts.
  systemd.services.k3s-preflight = {
    description = "Generate per-node k3s config (cluster-init vs join)";
    wantedBy = [ "k3s.service" ];
    before = [ "k3s.service" ];
    after = [ "local-fs.target" "dynamic-hostname.service" ];
    unitConfig.RequiresMountsFor = [ "/stateful" "/var/lib/rancher" ];
    path = [ pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      set -eu
      mkdir -p ${stateDir} "$(dirname ${runConfig})"
      chmod 0700 ${stateDir}

      if [ ! -s ${stateDir}/token ]; then
        echo "k3s-preflight: ${stateDir}/token is missing or empty; refusing to start k3s" >&2
        exit 1
      fi

      JOIN="${joinAddr}"
      [ -s ${stateDir}/server ] && JOIN="$(tr -d '[:space:]' < ${stateDir}/server)"

      if [ -e ${stateDir}/cluster-init ]; then
        echo "cluster-init: true" > ${runConfig}
        echo "k3s-preflight: bootstrapping a new etcd cluster on this node" >&2
      elif [ -d /var/lib/rancher/k3s/server/db/etcd ]; then
        # Already an etcd member; keep the join address if we have one, harmless otherwise.
        if [ -n "$JOIN" ]; then echo "server: $JOIN" > ${runConfig}; else echo "# existing etcd member" > ${runConfig}; fi
      elif [ -n "$JOIN" ]; then
        echo "server: $JOIN" > ${runConfig}
        echo "k3s-preflight: joining $JOIN" >&2
      else
        echo "k3s-preflight: no cluster-init marker and no join address; set ${stateDir}/server or joinAddr" >&2
        exit 1
      fi
      chmod 0600 ${runConfig}
    '';
  };

  systemd.services.k3s = {
    requires = [ "k3s-preflight.service" ];
    after = [ "k3s-preflight.service" "tailscaled.service" ];
    # Never let k3s fall back to writing images/etcd into the tmpfs root.
    unitConfig.RequiresMountsFor = [ "/var/lib/rancher" "/var/lib/kubelet" ];
  };

  boot.kernelModules = [ "br_netfilter" "overlay" ];
  boot.kernel.sysctl = {
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
  };

  # Only matters if the firewall is ever turned back on.
  networking.firewall = {
    allowedTCPPorts = [
      6443 # kube-apiserver
      2379 2380 # etcd client/peer
      10250 # kubelet
    ];
    allowedUDPPorts = [ 8472 ]; # flannel VXLAN
  };

  # kubeconfig lives here; rancher/kubelet state get their own btrfs subvolumes (see disko-configs/borg.nix).
  environment.persistence."/stateful".directories = [ "/etc/rancher" ];

  environment.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
  ];
}
