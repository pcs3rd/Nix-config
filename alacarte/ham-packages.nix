{ inputs, outputs, lib, pkgs, ... }:{
  environment.systemPackages = with pkgs; [
    python313Packages.meshtastic
    wsjtx
    fldigi
    hamlib
    soundmodem
    direwolf
    flrig
    js8call
    digiham
		firefox
    pat
		minicom
    qlog
    nanovna-saver
  ];
}