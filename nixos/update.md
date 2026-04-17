# Updating Nix config
1. Clone this repo with the new changes added to the `configuration.nix` file (or any other config file)
2. `cd` to the `nixos` directory of the files you just cloned
3. Run `sudo nixos-rebuild switch --flake .#"the name of the flake (look in flake.nix)"`


## Updating packages
- ...