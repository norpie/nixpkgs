{
  lib,
  stdenvNoCC,
  fetchurl,
  resolution ? "1920x1080", # override with "1920x1080" or "2560x1440"
}:

assert builtins.any (r: resolution == r) [
  "1920x1080"
  "2560x1440"
];

let
  version = "0.2.0";
in
stdenvNoCC.mkDerivation {
  pname = "space-isolation-grub-theme";
  inherit version;

  src = fetchurl {
    url = "https://github.com/callmenoodles/space-isolation/releases/download/v${version}/space-isolation-${resolution}.tar.gz";
    hash =
      {
        "1920x1080" = "sha256-At3cYjJL/AO3cxHXw5Ap70LgoKdbDgWoz7gSac4/u4w=";
        "2560x1440" = "sha256-b5WF9V0iL9IKGxIhDExVd01r5vum6aqAUGgxwe4iog8=";
      }
      .${resolution};
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/
    cp -r * $out/

    runHook postInstall
  '';

  meta = {
    description = "GRUB theme based on the main menu of Alien: Isolation";
    homepage = "https://github.com/callmenoodles/space-isolation";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ norpie ];
  };
}
