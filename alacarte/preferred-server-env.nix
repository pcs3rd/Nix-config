{ inputs, outputs, lib, pkgs, ... }:{
  i18n.defaultLocale = "en_US.UTF-8";
  environment.variables = {
    "EDITOR" = "nano";
  };
  documentation.enable = false; # documentation of packages
  documentation.nixos.enable = false; # nixos documentation
  documentation.man.enable = false; # manual pages and the man command
  documentation.info.enable = false; # info pages and the info command
  documentation.doc.enable = false; # documentation distributed in packages' /share/doc
  nix.settings.auto-optimise-store = true;
  system.autoUpgrade.enable = true;
  system.autoUpgrade.allowReboot = false;
  services.devmon.enable = true; # I want to auto-mount disks.
  services.gvfs.enable = true; 
  services.udisks2.enable = true;
  programs.udevil.enable = true;

  systemd.services.automount = {
    description = "Automatically mount storage mediums";
    startLimitBurst = 5;
    startLimitIntervalSec = 500;
    serviceConfig = {
      ExecStart = "${pkgs.udevil}/devmon &";
      Restart = "on-failure";
      RestartSec = "5s";
    };
  };

  boot.initrd = {
    systemd.users.root.shell = "/bin/sh";
    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 22;
        authorizedKeys = [ "ssh-rsa b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZWQyNTUxOQAAACDXn1u69Oflk3RLxUqIPcjvmOJXhHDzZbCOoqfvD8DWOgAAAKAax6N9GsejfQAAAAtzc2gtZWQyNTUxOQAAACDXn1u69Oflk3RLxUqIPcjvmOJXhHDzZbCOoqfvD8DWOgAAAEDzoRbCAzcW/j0aArAu8HLiGw5wfrgIbqV0ykqdRAC46defW7r05+WTdEvFSog9yO+Y4leEcPNlsI6ip+8PwNY6AAAAHXJkZWFuM0BSYXltb25kcy1NYWNCb29rLmxvY2Fs" ];
        hostKeys = [ "/stateful/etc/ssh/ssh_host_rsa_key" ]; # convienently already accessable.
      };
    };
  };

  users.motd = "UNAUTHORIZED ACCESS TO THIS DEVICE IS PROHIBITED

You must have explicit, authorized permission to access or configure this device. \n
Unauthorized attempts and actions to access or use this system may result in civil \n 
and/or criminal penalties. All activities performed on this device are logged and monitored.";
}
