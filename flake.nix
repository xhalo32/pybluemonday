{
  description = "A basic flake";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  inputs.systems.url = "github:nix-systems/default";

  outputs =
    {
      self,
      systems,
      nixpkgs,
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = eachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              (final: prev: {
                python312 = prev.python312.override {
                  packageOverrides = finalPython: prevPython: {
                    # Can't work with nix
                    # setuptools-golang = prevPython.buildPythonPackage rec {
                    #   pname = "setuptools-golang";
                    #   version = "2.7.0";
                    #   pyproject = true;

                    #   src = prev.fetchFromGitHub {
                    #     owner = "asottile";
                    #     repo = "setuptools-golang";
                    #     rev = "v${version}";
                    #     hash = "sha256-1N0rUoV3nA/By/2YeeUdSceGoWXadtNikW0n+EwfSUg=";
                    #   };

                    #   build-system = with prevPython; [ setuptools ];
                    # };

                    pybluemonday = prevPython.buildPythonPackage {
                      pname = "pybluemonday";
                      version = "0.0.12";
                      pyproject = true;

                      dependencies = with prev.python3Packages; [
                        cffi
                      ];

                      postPatch = ''
                        substituteInPlace setup.py \
                          --replace-fail 'subprocess.call(["make", "clean"' '# dont run make clean to not clean the symlinked so' \
                          --replace-fail 'subprocess.call(["make", "so"' '# dont run make so' \
                          --replace-fail 'subprocess.call(["pip",' '# dont use pip' \
                          --replace-fail 'subprocess.call(["make", "ffi"' '# dont run make ffi' \
                          --replace-fail '    setup_requires=' '# dont use setuptools-golang' \
                          --replace-fail '    ext_modules=' '# no ext modules'
                        # substituteInPlace build_ffi.py \
                        #   --replace-fail '    extra_objects=["bluemonday.so"],' '    extra_objects=["
                        #     self.packages.${system}.pybluemonday
                        #   }/bluemonday.so"],'
                        ln -s ${self.packages.${system}.pybluemonday}/bluemonday.so pybluemonday/bluemonday.so
                        ln -s ${self.packages.${system}.pybluemonday}/bluemonday.h pybluemonday/bluemonday.h
                        ls -hartl
                      '';

                      # installPhase = ''
                      #   ls -hartl
                      #   ls -hartl build dist
                      #   # cp build/lib.linux-x86_64-cpython-312/pybluemonday/bluemonday.cpython-312-x86_64-linux-gnu.{so,h} $out/lib/python3.12/site-packages/pybluemonday/
                      # '';

                      src = pkgs.nix-gitignore.gitignoreSourcePure [
                        "flake.*"
                        ./.gitignore
                      ] ./.;

                      build-system = with pkgs.python3Packages; [
                        setuptools
                        # finalPython.setuptools-golang
                      ];
                    };
                  };
                };
              })
            ];
          };
        in
        {
          pybluemonday = pkgs.buildGoModule {
            pname = "pybluemonday";
            version = "0.0.12";
            src = pkgs.nix-gitignore.gitignoreSourcePure [
              "flake.*"
              ./.gitignore
            ] ./.;

            buildPhase = ''
              go build -buildmode=c-shared -o $out/bluemonday.so .
            '';

            vendorHash = "sha256-VDplcSE/xbTz4A89CU5nKJZw9ekxXxIgeCU+dksy7o8=";
          };

          python3Packages.pybluemonday = pkgs.python3Packages.pybluemonday;
        }
      );

      devShells = eachSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;

          };

          pythonPackages = pkgs.python312Packages;

          venvDir = "./venv";

          # This is to expose the venv in PYTHONPATH so that pylint can see venv packages
          # FIXME check CTFd
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
              # self.packages.${system}.pybluemonday

              python
              venvShellHook
              # setuptools-golang
              setuptools

              cffi # use nixpkgs version because pip version fails to build

              pkgs.go
            ];
          };
        }
      );
    };
}
