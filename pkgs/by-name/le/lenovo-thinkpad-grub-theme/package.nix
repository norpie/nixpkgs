{
  lib,
  stdenvNoCC,
  fetchzip,
  scale ? "1.5x", # override with "1x", "1.5x", or "2x"
  mode ? "light", # override with "light" or "dark"
}:

assert builtins.any (s: scale == s) [
  "1x"
  "1.5x"
  "2x"
];

assert builtins.any (m: mode == m) [
  "light"
  "dark"
];

let
  version = "1.1";
  # Map scale to URL format (1.5x -> 1.5x)
  scaleUrl = scale;
in
stdenvNoCC.mkDerivation {
  pname = "lenovo-thinkpad-grub-theme";
  inherit version;

  src = fetchzip {
    url = "https://github.com/AlexanderKh/lenovo-thinkpad-efi-grub-theme/releases/download/v${version}/Lenovo.Thinkpad.EFI.${scaleUrl}-${mode}.zip";
    hash =
      {
        "1x-light" = "sha256-3bOUKoyPdxks0jQRiUzvc1ftpw/R4ROrML37DoUG8EU=";
        "1x-dark" = "sha256-Ykv9Q8NLnyuX3NVNU5odNp+dyqH7Sr3hfIy0mLNrYbM=";
        "1.5x-light" = "sha256-RogRsdtDsJ8kJZbjIFbTXeW9pZ4EkAHuERNu5ztOJQU=";
        "1.5x-dark" = "sha256-mQiIo9SvVcg028mU7N771LIoivXWbOSY0lHjYVrxSLE=";
        "2x-light" = "sha256-GkLgEH1sx9269zAbXRXsPv3Mx9ktudkMvoaaevTbVAA=";
        "2x-dark" = "sha256-0XwjVJwIs+WnI+A0BBx1t250SZjKKbkSHY1Dsm6Y7QU=";
      }
      ."${scale}-${mode}";
    stripRoot = false;
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/
    cp -r "Lenovo Thinkpad EFI ${scale}-${mode}/lenovo-thinkpad-efi"/* $out/

    runHook postInstall
  '';

  meta = {
    description = "Lenovo ThinkPad inspired GRUB bootloader theme for EFI systems";
    homepage = "https://github.com/AlexanderKh/lenovo-thinkpad-efi-grub-theme";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ norpie ];
  };
}
