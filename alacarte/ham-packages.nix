{ inputs, outputs, lib, pkgs, ... }:{
  environment.systemPackages = with pkgs; [
    contact
    python313Packages.meshtastic
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
    js8call
    openwebrx
    sigdigger
    sigutils
    suwidgets
    qradiolink
    digiham
    carla
		firefox
    calf

  ];
}