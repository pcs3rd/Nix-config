#https://github.com/mrjones2014/opnix
{ config, ... }: {
  opnix = {
    # This is where you put your Service Account token in .env file format, e.g.
    # OP_SERVICE_ACCOUNT_TOKEN="{your token here}"
    # See: https://developer.1password.com/docs/service-accounts/use-with-1password-cli/#get-started
    # This file should have permissions 400 (file owner read only) or 600 (file owner read-write)
    # The systemd script will print a warning for you if it's not
    environmentFile = "/stateful/sys-data/opnix.env";
    # Set the systemd services that will use 1Password secrets; this makes them wait until
    # secrets are deployed before attempting to start the service.
    systemdWantedBy = [ "my-systemd-service" "homepage-dashboard" ];
    # Specify the secrets you need
    secrets = {
      # The 1Password Secret Reference in here (the `op://` URI)
      # will get replaced with the actual secret at runtime
      some-secret.source = ''
        # You can put arbitrary config markup in here, for example, TOML config
        [ConfigRoot]
        SomeSecretValue="{{ op://MyVault/MySecretItem/token }}"
      '';
      # you can also specify the UNIX file owner, group, and mode
      some-secret.user = "911";
      some-secret.group = "911";
      some-secret.mode = "0600";
      # If you need to, you can even customize the path that the secret gets installed to
      some-secret.path = "/some/other/path/some-secret";
      # You can also disable symlinking the secret into the installation destination
      some-secret.symlink = false;
    };
  };

  # run a systemd service
  systemd.services.my-systemd-service = {
    enable = true;
    # here, `config.opnix.secrets.some-secret.path` is the ramfs path
    # of the file with the actual secret injected
    script = ''
      some-script --env-file ${config.opnix.secrets.some-secret.path}
    '';
    wantedBy = [ "multi-user.target" ];
  };

  # or if there's a NixOS module and it has an `environmentFile` option,
  # you can provide your secrets that way
  services.homepage-dashboard = {
    enable = true;
    environmentFile = config.opnix.secrets.some-secret.path;
    # ... the rest of your homepage config here
  };
}