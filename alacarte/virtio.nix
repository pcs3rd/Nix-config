{ lib, inputs, outputs, ... }:{
  boot.initrd.availableKernelModules = [ "xhci_pci" "virtio_pci" "btrfs" "virtio_blk" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
}