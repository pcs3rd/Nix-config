{ inputs, outputs, lib, pkgs, modulesPath, ... }:{
services.kasmweb = {
    enable = true; 
    listenPort = 2143;
    datastorePath = "/persist/prod/web/kasm"
}

}