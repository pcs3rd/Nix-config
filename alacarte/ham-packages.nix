{ inputs, outputs, lib, pkgs, ... }:{
  environment.systemPackages = with pkgs; [
    contact
    python313Packages.meshtastic
    firefox
    wsjtx
    fldigi
    hamrs
    hamlib
    hamtransfer
    ax25-apps
    digiham
    tlf
    grig
    klog
    libax25
    flex-ncat
    gpredict
    soundmodem
    grig
    direwolf
    cqrlog
    flrig
    gqrx
    gnuradio
    telegraph
    js8call
    openwebrx
    sigdigger
    sigutils
    suwidgets
    qradiolink
    digiham
    carla
    browsh
    git
    kdePackages.kcalc # Calculator
    kdePackages.kcharselect # Tool to select and copy special characters from all installed fonts
    kdePackages.ksystemlog # KDE SystemLog Application
    kdePackages.sddm-kcm # Configuration module for SDDM
    kdePackages.partitionmanager # Optional: Manage the disk devices, partitions and file systems on your computer
    wayland-utils # Wayland utilities

  ];
}