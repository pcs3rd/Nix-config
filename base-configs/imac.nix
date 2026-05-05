{ outputs, inputs, lib, config, pkgs, modulesPath, ... }:{
  imports =
    [ (modulesPath + "/hardware/network/broadcom-43xx.nix")
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  services.openssh = {
    enable = true;
  };
# Network
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  networking.networkmanager.enable = true;
  time.timeZone = "America/New_York";


  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
    hardware = {
    # Ensure libinput is enabled for input handling
    opengl.enable = true;
    };

services.xserver.libinput.enable = true;
  system.stateVersion = "24.05";
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "ohci_pci" "ehci_pci" "firewire_ohci" "usbhid" "uas" "sd_mod" "sdhci_pci" "hid-magicmouse"];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

}
