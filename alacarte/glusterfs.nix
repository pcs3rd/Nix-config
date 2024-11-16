{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
# See glusterFS quickstart: https://docs.gluster.org/en/latest/Quick-Start-Guide/Quickstart/#step-5-configure-the-trusted-pool

  environment.systemPackages = with pkgs; [
    glusterfs
  ];
  services.glusterfs = {
      enable = true;
      tlsSettings.caCert = "/stateful/sys-data/gluster/certs/glusterfs.ca";
      tlsSettings.tlsPem = "/stateful/sys-data/gluster/certs/glusterfs.pem";
      tlsSettings.tlsKeyPath = "/stateful/sys-data/gluster/certs/glusterfs.key";
  };
}