{
  buildGoModule,
  nix-gitignore,
  autoPatchelfHook,
  lib,
  ...
}:
buildGoModule {
  pname = "pybluemonday-go";
  version = "0.0.12";
  src = lib.cleanSourceWith {
    src = lib.cleanSource ./.;
    filter =
      name: type:
      (builtins.any (x: x) [
        (lib.hasSuffix ".mod" name)
        (lib.hasSuffix ".sum" name)
        (lib.hasSuffix ".go" name)
        (lib.hasSuffix "Makefile" name)
      ]);
  };

  buildPhase = ''
    make so
  '';

  installPhase = ''
    runHook preInstall
    install -m755 -D bluemonday.so $out/lib/bluemonday.so
    install -m755 -D bluemonday.h $out/include/bluemonday.h
    runHook postInstall
  '';

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  vendorHash = "sha256-VDplcSE/xbTz4A89CU5nKJZw9ekxXxIgeCU+dksy7o8=";
}
