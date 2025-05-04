{
  pkgs ? import <nixpkgs> { system = builtins.currentSystem; }, 
  lib ? pkgs.lib,
  stdenv ? pkgs.stdenv,
  pam ? pkgs.pam,
  fetchFromGitHub ? pkgs.fetchFromGitHub,
}:


let 
  pkgs =  import <nixpkgs> {}; # bring all of Nixpkgs into scope
in

pkgs.stdenv.mkDerivation rec {
  pname = "pam_oauth2_device";
  version = "20cd504709d49e509ad1606e4b85cfe858e2e498";

  src = fetchFromGitHub {
    owner = "stfc";
    repo = "pam_oauth2_device";
    rev = version;
    hash = "sha256-3qOF7+rn222GMRwxpQgACuIwuPyCku01JKvNefPxxsM=";
  };

  nativeBuildInputs = [ ];
  buildInputs = [ pam pkgs.curl pkgs.openldap ];


  buildPhase = ''
    runHook preBuild

    make

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p -v $out/bin $out/lib/security
    mkdir -p -v $out/etc/pam_oauth2_device/
    cp pam_oauth2_device.so $out/lib/security
    cp config_template.json $out/etc/pam_oauth2_device/config-template.json
    chmod +755 $out/lib/security
  '';

  meta = with lib; {
    homepage = "https://github.com/slaclab/pam_oauth2_device";
    description = "PAM Oauth2 Device Flow";
    mainProgram = "pam_oauth2_device";
    #license = licenses.apache20;
    #maintainers = with maintainers; [ pcs3rd ];
    platforms = platforms.linux;
  };
}