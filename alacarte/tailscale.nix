{ inputs, outputs, lib, pkgs, ... }:{
  boot.kernel.sysctl."net.ipv4.ip_forward" = true;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
  services.tailscale.enable = true;
  networking.nftables.enable = true;
}