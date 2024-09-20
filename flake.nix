{
  description = "A basic flake";

  inputs.systems.url = "github:nix-systems/default";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    {
      self,
      systems,
      nixpkgs,
      ...
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          inherit (pkgs) lib;
          python3 = pkgs.python311;
        in
        rec {
          bluemonday = pkgs.callPackage ./bluemonday.nix { };
          pybluemonday = python3.pkgs.callPackage ./. { inherit bluemonday; };

          default = pybluemonday;
        }
      );

      devShells = eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          pythonPackages = pkgs.python312Packages;

          venvDir = "./venv";

          postShellHook = ''
            PYTHONPATH=''$PWD/\${venvDir}/\${pythonPackages.python.sitePackages}/:''$PYTHONPATH
            pip install -r development.txt
          '';
        in
        {
          default = pkgs.mkShell {
            inherit venvDir;
            # inherit postShellHook;
            name = "devshell";
            packages = with pkgs.python312Packages; [
              python
              venvShellHook
              setuptools

              cffi

              pkgs.go
            ];
          };
        }
      );
    };
}
