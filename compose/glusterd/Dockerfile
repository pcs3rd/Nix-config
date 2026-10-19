# glusterd for the borg drones (only used with services.glusterCluster.daemon = "container").
# trixie ships GlusterFS 11.x, matching the nixpkgs client on the hosts.
FROM debian:trixie-slim
RUN apt-get update \
 && apt-get install -y --no-install-recommends glusterfs-server procps \
 && rm -rf /var/lib/apt/lists/*
CMD ["glusterd", "-N", "--log-file=-"]
