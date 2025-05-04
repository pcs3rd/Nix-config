{
  stdenv,
  lib,
  fetchFromGitHub,
  autoreconfHook,
  pam,
  qrencode,
}:

stdenv.mkDerivation rec {
  pname = "google-authenticator-libpam";
  version = "1.10";

  src = fetchFromGitHub {
    owner = "google";
    repo = "google-authenticator-libpam";
    rev = version;
    hash = "sha256-KEfwQeJIuRF+S3gPn+maDb8Fu0FRXLs2/Nlbjj2d3AE=";
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
    mainProgram = "google-authenticator";
    license = licenses.apache20;
    #maintainers = with maintainers; [ aneeshusa ];
    platforms = platforms.linux;
  };
}