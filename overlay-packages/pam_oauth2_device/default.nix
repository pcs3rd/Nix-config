{
  stdenv,
  lib,
  fetchFromGitHub,
  autoreconfHook,
  pam,
}:

let 
  pkgs =  import <nixpkgs> {}; # bring all of Nixpkgs into scope
in

pkgs.stdenv.mkDerivation rec {
  pname = "pam_oauth2_device";
  version = "v1.03";

  src = fetchFromGitHub {
    owner = "stfc";
    repo = "pam_oauth2_device";
    rev = version;
    hash = "20cd504709d49e509ad1606e4b85cfe858e2e498";
  };

  nativeBuildInputs = [ autoreconfHook ];
  buildInputs = [ pam ];


  buildPhase = ''
    runHook preBuild

    make

    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib/security
    mkdir -p $out/etc/pam_oauth2_device/
    cp pam_oauth2_device.so $out/lib/security
    cp config_template.json /etc/pam_oauth2_device/config.json
  '';

  meta = with lib; {
    homepage = "https://github.com/slaclab/pam_oauth2_device";
    description = "PAM Oauth2 Device Flow";
    mainProgram = "pam_oauth2_device";
    license = licenses.apache20;
    #maintainers = with maintainers; [ pcs3rd ];
    platforms = platforms.linux;
  };
}