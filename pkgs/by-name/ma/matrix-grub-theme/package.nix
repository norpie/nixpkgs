{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  variant ? "window", # override with "window" or "sidebar"
  resolution ? "1080p", # override with "1080p", "2k", or "4k"
}:

assert builtins.any (v: variant == v) [
  "window"
  "sidebar"
];

assert builtins.any (r: resolution == r) [
  "1080p"
  "2k"
  "4k"
];

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "matrix-grub-theme";
  version = "unstable-2025-03-14";

  src = fetchFromGitHub {
    owner = "yeyushengfan258";
    repo = "Matrix-grub-theme";
    rev = "3aed8ee042e540246ee5b02d61d21c1d7889a208"; # Latest commit as of 2025-03-14
    hash = "sha256-sn7bAVlFwuwmCjmzKDALeSuuUV7awiZlLpqPUpXpWGI=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/

    # Extract the appropriate theme from releases
    tar -xf releases/Matrices-${variant}-grub-themes.tar.xz -C .

    # Copy the theme files for the selected resolution
    cp -r Matrices-${variant}-grub-themes/${resolution}/Matrices-${variant}/* $out/

    runHook postInstall
  '';

  meta = {
    description = "Matrix-inspired GRUB2 bootloader theme";
    homepage = "https://github.com/yeyushengfan258/Matrix-grub-theme";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ norpie ];
  };
})
