{
  lib,
  python,
  bluemonday,
  autoPatchelfHook,
  buildPythonPackage,

  # Python packages
  cffi,
  setuptools,
  wheel,
  ...
}:
let
  versionTuple = (lib.strings.splitString "." python.version);
  versionString = "${builtins.elemAt versionTuple 0}${builtins.elemAt versionTuple 1}";
in
buildPythonPackage {
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

  buildInputs = [
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

  build-system = [ setuptools ];

  doCheck = false;

  pythonImportsCheck = [
    "pybluemonday"
    "pybluemonday.bluemonday"
  ];
}
