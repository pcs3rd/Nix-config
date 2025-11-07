{ stdenv, fetchurl, undmg }:

stdenv.mkDerivation rec {
  pname = "Moonlight";
  version = "v6.1.0";

  buildInputs = [ undmg ];
  sourceRoot = ".";
  phases = [ "unpackPhase" "installPhase" ];
  installPhase = ''
      mkdir -p "$out/Applications"
      cp -r Moonlight.app "$out/Applications/Moonlight.app"
    '';

  src = fetchurl {
    url = "https://github.com/moonlight-stream/moonlight-qt/releases/download/${version}/Moonlight-${version}.dmg
";
    sha256 = "";
  };

  meta = with stdenv.lib; {
    description = "Moonlight Game Streaming Client";
    homepage = "https://moonlight-stream.org/#";
    maintainers = [ maintainers.pcs3rd ];
    platforms = platforms.darwin;
  };
}