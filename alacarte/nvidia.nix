{ inputs, outputs, lib, pkgs, ... }:{
    environment.defaultPackages = lib.mkForce [
        pkgs.nvidia-container-toolkit
    ];
}
