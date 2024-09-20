{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
boot.loader = {
  efi = {
    canTouchEfiVariables = true;
  };
  grub = {
     enable = true;
     efiSupport = true;
  };
};
}