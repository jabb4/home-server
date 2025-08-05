{...}: {
  # Set user's home directory and username for home-manager
  home.username = "nixos";
  home.homeDirectory = "/home/nixos";

  home.file.".smb-credentials".source = ./smb-credentials;

  home.stateVersion = "25.11";
}