defaultUserName:
{ outputs, inputs, lib, config, pkgs, options, modulesPath, ... }:

{
  imports = [
    ../alacarte/phosh.nix
    ../home-configs/raymond.nix
  ];

  config = {
    services.xserver.desktopManager.phosh = {
      user = ${defaultUserName};
    };
  };
  mobile.boot.stage-1.kernel.useStrictKernelConfig = lib.mkDefault true;
}
