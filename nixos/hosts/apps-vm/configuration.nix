{pkgs, ...}: {
  imports = [
    # Include the results of the hardware scan.
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  # Nix settings, auto cleanup and enable flakes
  nix = {
    settings.auto-optimise-store = true;
    settings.allowed-users = ["nixos"];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-outputs = true
      keep-derivations = true
    '';
  };

  # Boot settings: clean /tmp/, latest kernel and enable bootloader
  boot = {
    tmp.cleanOnBoot = true;
    loader = {
      systemd-boot.enable = true;
      systemd-boot.editor = true;
      efi.canTouchEfiVariables = true;
      timeout = 5;
    };
  };

  # Networking and firewall
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [
        2283                # Immich
        3001                # Homepage
        8000                # Vaultwarden
        8001                # Paperless-NGX
        8080                # SearXNG
        8081                # MicroBin
      ];
      allowPing = true;
    };
  };

  # Set up locales (timezone and keyboard layout)
  time.timeZone = "Europe/Stockholm";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "sv-latin1";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    users = {
      nixos = {
        initialHashedPassword = "$y$j9T$Jih.ZSsWCOQvhyFP9jQLT0$2N.14vBexUwO1Dc3ns4f2LS0TIwU5jN4Ww8KnE05FL9"; # Run mkpasswd "password" to get hash, default password is nixos
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAJ0zwaPTeICiyrcPwdFbxxDUOHH+G5CkQ8iKIE31vKc" # Homeserver SSH key in Termius
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHol1wiu9VO1bBu1tbt3+YN7/0csvMy94F+y8yQ0MNVN" # Apple MacBook Pro M5 SSH key
        ];
        isNormalUser = true;
        uid = 1000;
        group = "nixos";
        extraGroups = ["input" "wheel"];
        linger = true; # This does so docker containers (and systemd services) can start at boot rather then at login
        shell = pkgs.zsh;
      };
    };
    groups = {
      nixos = {
        gid = 1000;
      };
    };
  };
    
  # Mount SMB Share for Nextcloud, Immich, Paperless etc
  fileSystems."/mnt/data" = {
    device = "//192.168.20.101/app-data";
    fsType = "cifs";
    options = let
      automount_opts = "x-systemd.automount,noauto,x-systemd.idle-timeout=60,x-systemd.device-timeout=5s,x-systemd.mount-timeout=5s,user,users";
    in ["${automount_opts},credentials=/home/nixos/.smb-credentials,uid=1000,gid=1000"];
  };

  # Enable zsh
  programs.zsh.enable = true;

  # Enable QEMU Guest agent
  services.qemuGuest.enable = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "no";
    settings.PasswordAuthentication = false;
  };

  virtualisation.docker = {
    enable = true;
  };

  # Apparmor
  security.apparmor = {
    enable = true;
  };

  # Enables Remote SSH with VSCode
  programs.nix-ld.enable = true;

  # Install packages
  environment.systemPackages = with pkgs; [
      cifs-utils # For SMB client (mount smb share)
      git
      htop
  ]; 

  system.stateVersion = "25.05";
}
