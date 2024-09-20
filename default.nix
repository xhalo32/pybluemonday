{
  lib,
  python3,
  bluemonday,
  autoPatchelfHook,
  ...
}:
python3.pkgs.buildPythonPackage {
  name = "pybluemonday";
  src = lib.cleanSourceWith {
    src = lib.cleanSource ./.;
    filter =
      name: type:
      !(builtins.any (x: x) [
        (lib.hasSuffix ".nix" name)
        (lib.hasPrefix "." (builtins.baseNameOf name))
        (lib.hasSuffix "flake.lock" name)
      ]);
  };

  # SOURCE_DATE_EPOCH = "315532800"; # https://nixos.org/manual/nixpkgs/stable/#python-setup.py-bdist_wheel-cannot-create-.whl

  buildInputs = with python3.pkgs; [
    cffi
    setuptools
    wheel
  ];

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  postPatch =
    let
      versionTuple = (lib.strings.splitString "." python3.version);
      versionString = "${builtins.elemAt versionTuple 0}${builtins.elemAt versionTuple 1}";
    in
    ''
      ln -s ${bluemonday}/include/bluemonday.h bluemonday.h
      substituteInPlace build_ffi.py \
        --replace-fail 'bluemonday.so' '${bluemonday}/lib/bluemonday.so'

      substituteInPlace setup.py \
        --replace-fail 'bluemonday.cpython-311-x86_64-linux-gnu.so' 'bluemonday.cpython-${versionString}-x86_64-linux-gnu.so'
    '';

  build-system = [ python3.pkgs.setuptools ];

  pythonImportsCheck = [ "pybluemonday.bluemonday" ];
}
