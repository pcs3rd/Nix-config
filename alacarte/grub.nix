{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
boot.loader = {
  efi = {
    canTouchEfiVariables = true;
  };
  grub = {
     enable = true;
     timeoutStyle = "hidden";
     efiSupport = true;
     version = 3;
  };
};
}