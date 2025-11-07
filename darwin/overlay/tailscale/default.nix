{ stdenv, fetchurl, undmg }:

stdenv.mkDerivation rec {
  pname = "Moonlight";
  version = "1.90.6";

  buildInputs = [ undmg ];
  sourceRoot = ".";
  phases = [ "unpackPhase" "installPhase" ];
  installPhase = ''
      mkdir -p "$out/Applications"
      cp -r Moonlight.app "$out/Applications/Moonlight.app"
    '';

  src = fetchurl {
    url = "https://dl.tailscale.com/stable/Tailscale-${version}-macos.pkg";
    sha256 = "";
  };

  meta = with stdenv.lib; {
    description = "Moonlight Game Streaming Client";
    homepage = "https://moonlight-stream.org/#";
    maintainers = [ maintainers.pcs3rd ];
    platforms = platforms.darwin;
  };
}