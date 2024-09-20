{
  lib,
  python3,
  bluemonday,
  autoPatchelfHook,
  ...
}:
let
  versionTuple = (lib.strings.splitString "." python3.version);
  versionString = "${builtins.elemAt versionTuple 0}${builtins.elemAt versionTuple 1}";
in
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

  buildInputs = with python3.pkgs; [
    cffi
    setuptools
    wheel
  ];

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  postPatch = ''
    ln -s ${bluemonday}/include/bluemonday.h bluemonday.h
    substituteInPlace build_ffi.py \
      --replace-fail 'bluemonday.so' '${bluemonday}/lib/bluemonday.so'

    substituteInPlace setup.py \
      --replace-fail 'bluemonday.cpython-311-x86_64-linux-gnu.so' 'bluemonday.cpython-${versionString}-x86_64-linux-gnu.so'
  '';

  # For debugging:
  # postBuild = ''
  #   ls -hartl build/lib
  #   ls -hartl build/lib/pybluemonday
  #   ldd build/lib/pybluemonday/bluemonday.cpython-${versionString}-x86_64-linux-gnu.so
  # '';

  build-system = [ python3.pkgs.setuptools ];

  doCheck = false;

  pythonImportsCheck = [
    "pybluemonday"
    "pybluemonday.bluemonday"
  ];
}
