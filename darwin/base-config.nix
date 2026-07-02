
{ pkgs, ... }:

{
  nix.settings = {
    # enable flakes globally
    experimental-features = ["nix-command" "flakes"];

    # substituers that will be considered before the official ones(https://cache.nixos.org)
    substituters = [
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    builders-use-substitutes = true;
  };

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  # Local Linux VM builder — lets this Mac build x86_64-linux/aarch64-linux
  # derivations (e.g. `nix build .#packages.x86_64-linux.steammachine-installer-iso`)
  # without a remote builder. Starts on demand via launchd.
  nix.linux-builder = {
    enable = true;
    ephemeral = true; # wipes the VM's disk each restart, so diskSize changes below always take effect
    config = {
      virtualisation.cores = 4;
      virtualisation.darwin-builder.memorySize = 8 * 1024; # MiB
      virtualisation.darwin-builder.diskSize = 100 * 1024; # MiB — full NixOS live ISO + steammachine closure needs headroom
    };
  };

# General system config. 

  system = {
    stateVersion = 5;
    # activationScripts are executed every time you boot the system or run `nixos-rebuild` / `darwin-rebuild`.
    activationScripts.postUserActivation.text = ''
      # activateSettings -u will reload the settings from the database and apply them to the current session,
      # so we do not need to logout and login again to make the changes take effect.
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';

    defaults = {
      menuExtraClock.Show24Hour = false;  # show 24 hour clock
    };
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;

  # Create /etc/zshrc that loads the nix-darwin environment.
  # this is required if you want to use darwin's default shell - zsh
  programs.zsh.enable = true;

}