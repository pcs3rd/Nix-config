{
  stdenv,
  lib,
}:
{
    pam_oauth2_device = import ./pam_oauth2_device/default.nix;
}