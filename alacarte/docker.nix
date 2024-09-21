{ inputs, outputs, lib, pkgs, ... }:{
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  virtualisation.docker.liveRestore = false; # This breaks swarms
}
