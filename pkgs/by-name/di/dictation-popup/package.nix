{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  cmake,
  clang,
  llvm,
  makeWrapper,
  pipewire,
  alsa-lib,
  wayland,
  wayland-protocols,
  libxkbcommon,
  libGL,
  xorg,
  libnotify,
  wl-clipboard,
}:

rustPlatform.buildRustPackage rec {
  pname = "dictation-popup";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "norpie";
    repo = "dictation";
    rev = "6dc1ac3bf50a0b7263b78f3de49cb4a880ef2537";
    hash = "sha256-S869crgz1YQUEXaPBP36anzd+DJ+Pt5El73/vgKldhE=";
  };

  cargoHash = "sha256-RF7ZFnBIs/ee5iURwKCQQBAl/rhbU1xawmBQlEJ7igw=";

  nativeBuildInputs = [
    pkg-config
    cmake
    clang
    llvm
    makeWrapper
  ];

  buildInputs = [
    pipewire
    alsa-lib
    wayland
    wayland-protocols
    libxkbcommon
    libGL
    xorg.libX11
    xorg.libXcursor
    xorg.libXrandr
    xorg.libXi
    libnotify
    wl-clipboard
  ];

  # Ensure Wayland and OpenGL libraries are available at runtime
  postInstall = ''
    wrapProgram $out/bin/dictation-popup \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ wayland libxkbcommon libGL ]}
  '';

  # Only build the popup binary
  cargoBuildFlags = [ "--bin" "dictation-popup" ];

  meta = {
    description = "Voice dictation popup UI for Wayland Linux with Whisper speech recognition";
    homepage = "https://github.com/norpie/dictation";
    license = with lib.licenses; [ mit asl20 ];
    maintainers = with lib.maintainers; [ ]; # Add yourself if you want
    platforms = lib.platforms.linux;
    mainProgram = "dictation-popup";
  };
}