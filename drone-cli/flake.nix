{
  description =
    "This flake builds the Ory CLI using Nix's buildGoModule Function.";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # The Ory CLI is not a flake, so we have to use the Github input and build it ourselves.
    drone-cli = {
      type = "github";
      owner = "harness";
      repo = "drone-cli";
      ref = "v1.3.3";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, drone-cli }:
    # Use the flake-utils lib to easily create a multi-system flake
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Define some variables that we want to use in our package build. You'll want to update version and `ref` above to use a different version of drone-cli
        version = "1.3.3";
        pkgs = import nixpkgs { inherit system; };
        pname = "drone-cli";
        name = "drone-${version}";
      in
      {
        packages = {
          # Build the Drone CLI using Nix's buildGoModuleFunction
          drone-cli = pkgs.buildGoModule {
            inherit version;
            inherit pname;
            inherit name;

            revision = "v${version}";

            src = drone-cli;

            patches = [ ./0001-use-builtin-go-syscerts.patch ];

            ldflags = [
              "-X main.version=${version}"
            ];

            doCheck = false;

            # If the vendor folder is not checked in, we have to provide a hash for the vendor folder. Nix requires this to ensure the vendor folder is reproducible, and matches what we expect.
            vendorSha256 = "sha256-U4S9XYnV4kn921vCxVhpIle4HK4N3MkqDr3LHNYfBjo=";

            meta = with pkgs.lib; {
              mainProgram = "drone";
              maintainers = with maintainers; [ techknowlogick ];
              license = licenses.asl20;
              description = "Command line client for the Drone continuous integration server";
            };
          };
        };
      }
    );
}
