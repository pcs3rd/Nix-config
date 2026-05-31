{ inputs, outputs, lib, pkgs, ... }:{
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker.liveRestore = false; # This breaks swarms
  # Have docker start after network
  systemd.services.my-service = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    before = [ "multi-user.target" ];

    wantedBy = [ "multi-user.target" ];
  };
}
