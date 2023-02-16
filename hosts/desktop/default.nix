#
#  Specific system configuration settings for desktop
#
#  flake.nix
#   ├─ ./hosts
#   │   └─ ./desktop
#   │        ├─ default.nix *
#   │        └─ hardware-configuration.nix
#   └─ ./modules
#       ├─ ./desktop
#       │   ├─ ./hyprland
#       │   │   └─ default.nix
#       │   └─ ./virtualisation
#       │       └─ default.nix
#       ├─ ./programs
#       │   └─ games.nix
#       └─ ./hardware
#           └─ default.nix
#

{ config, lib, pkgs, modulesPath, ... }:

{
  imports =                                               # For now, if applying to other system, swap files
    [(import ./hardware-configuration.nix)] ++            # Current system hardware config @ /etc/nixos/hardware-configuration.nix
    [(import ../../modules/programs/games.nix)] ++        # Gaming
    [(import ../../modules/desktop/hyprland/default.nix)] ++ # Window Manager
    (import ../../modules/desktop/virtualisation) ++      # Virtual Machines & VNC
    (import ../../modules/hardware);                      # Hardware devices

  systemd.services.zfs-mount.enable = false;

	hardware.opengl.driSupport = true;

  networking = {
		firewall.enable = false;
		hostName = "desktop";
		networkmanager.enable = true;
		wireless.enable = false;
	};

  users = {
		defaultUserShell = pkgs.zsh;
		users.tboston = {
			isNormalUser = true;
      extraGroups = [ "wheel" "video" "audio" "camera" "networkmanager" "kvm" "libvirtd" ];
			openssh.authorizedKeys.keys = [
				"ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIINkmizml/XsSRzp3mNIumb3ZEPQoZhi/TtDU7rOUiKA tboston@macbook"
			];
		};
  };

  programs = {
		gnupg.agent = {
			enable = true;
			enableSSHSupport = true;
		};
		mtr.enable = true;
    vim = {
			defaultEditor = true;
    };
  };

  services = {
		xserver = {
			enable = true;
			displayManager = {
				gdm = {
					enable = true;
					wayland = true;
				};
			};
			layout = "us";
			xkbOptions = "eurosign:e";
			videoDrivers = [ "amdgpu" ];
		};
  };

	security = {
		doas.enable = true;
    doas.extraRules = [{
        users = [ "tboston" ];
        keepEnv = true;
        noPass = true;
    }];
	}; 

}
