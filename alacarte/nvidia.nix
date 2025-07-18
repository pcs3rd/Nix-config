{ inputs, outputs, lib, pkgs, config, ... }:{
    environment.defaultPackages = lib.mkForce [
        pkgs.nvidia-container-toolkit
        pkgs.git
        pkgs.gitRepo
        pkgs.gnupg
        pkgs.autoconf
        pkgs.curl
        pkgs.procps
        pkgs.gnumake
        pkgs.util-linux
        pkgs.m4
        pkgs.gperf
        pkgs.unzip
        pkgs.cudatoolkit
        pkgs.linuxPackages.nvidia_x11
        pkgs.libGLU pkgs.libGL
        pkgs.xorg.libXi pkgs.xorg.libXmu pkgs.freeglut
        pkgs.xorg.libXext pkgs.xorg.libX11 pkgs.xorg.libXv pkgs.xorg.libXrandr pkgs.zlib 
        pkgs.ncurses5
        pkgs.stdenv.cc
        pkgs.binutils
    ];
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics = {
    enable = true;
  };
  hardware.nvidia-container-toolkit.enable = true;
  hardware.nvidia = {

    # Modesetting is required.
    modesetting.enable = true;

    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    # Enable this if you have graphical corruption issues or application crashes after waking
    # up from sleep. This fixes it by saving the entire VRAM memory to /tmp/ instead 
    # of just the bare essentials.
    powerManagement.enable = false;

    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;

    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    open = false;

    # Enable the Nvidia settings menu,
	# accessible via `nvidia-settings`.
    nvidiaSettings = false;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
