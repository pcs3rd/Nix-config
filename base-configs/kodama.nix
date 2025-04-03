{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:{

let
  defaultUserName = "rdean";
in
{
  imports = [
    ../alacarte/phosh.nix
    ../home-configs/raymond.nix
  ];

  config = {

    services.xserver.desktopManager.phosh = {
      user = defaultUserName;
    };
  };
}
  mobile.boot.stage-1.kernel.useStrictKernelConfig = lib.mkDefault true;
}
