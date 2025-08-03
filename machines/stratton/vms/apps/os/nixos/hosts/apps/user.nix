{...}: {
  # Set user's home directory and username for home-manager
  home.username = "nixos";
  home.homeDirectory = "/home/nixos";

  home.file."docker-services".source = ./docker-services;

  home.stateVersion = "25.11";
}