{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
# See glusterFS quickstart: https://docs.gluster.org/en/latest/Quick-Start-Guide/Quickstart/#step-5-configure-the-trusted-pool
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.impermanence.nixosModules.impermanence
    inputs.disko.nixosModule.disko
    ];

  environment.systemPackages = with pkgs; [
    glusterfs
  ];
  services.glusterfs.enable = true;
}