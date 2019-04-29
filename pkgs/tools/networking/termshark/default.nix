{ stdenv, fetchFromGitHub, go }:

stdenv.mkDerivation rec {
  name = "termshark-${version}";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "gcla";
    repo = "termshark";
    rev = "v${version}";
    sha256 = "b6b2c35461d9910710c8ef03f95f21a879240d2b";
  };

  nativeBuildInputs = [ go ];

  buildPhase = ''
    go build
  '';

  meta = with stdenv.lib; {
    homepage = https://termshark.io/;
    description = "A terminal UI for tshark, inspired by Wireshark";
    platforms = platforms.linux;
    license = licenses.mit;
    maintainers = maintainers.winpat;
  };
}
