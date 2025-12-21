{ inputs, outputs, lib, pkgs, ... }:{
  environment.systemPackages = with pkgs; [
    python313Packages.meshtastic
    wsjtx
    fldigi
    hamlib
    gpredict
    soundmodem
    direwolf
    cqrlog
    flrig
    js8call
    suwidgets
    qradiolink
    digiham
    carla
		firefox
  ];
}