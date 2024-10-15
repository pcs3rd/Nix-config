{ lib, config, pkgs, ... }:
{
  users.ldap = {
    enable = true;
    base = "dc=example,dc=com";
    server = "ldap://example.com/";
    useTLS = true;
    extraConfig = ''
      ldap_version 3
      pam_password md5
      nss_override_attribute_value loginShell /run/current-system/sw/bin/bash
    '';
  };

  security.pam.services.sshd.makeHomeDir = true;
  systemd.tmpfiles.rules = [
    "L /bin/bash - - - - /run/current-system/sw/bin/bash"
  ];

  security.pam.services.sshd = {
    makeHomeDir = true;

    # see https://stackoverflow.com/a/47041843 for why this is required
    text = lib.mkDefault (
      lib.mkBefore ''
        auth required pam_listfile.so \
          item=group sense=allow onerr=fail file=/etc/allowed_groups
      ''
    );
  };

  environment.etc.allowed_groups = {
    text = "admins";
    mode = "0444";
  };

}