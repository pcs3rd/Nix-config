{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
boot.loader = {
  efi = {
    canTouchEfiVariables = true;
  };
  grub = {
     enable = true;
     efiSupport = true;
  };
    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    boot.loader.grub.efiInstallAsRemovable = true;
};
}