# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{ config, lib, pkgs, modulesPath, ... }:

let
  zfsRoot.partitionScheme = {
    biosBoot = "-part5";
    efiBoot = "-part1";
    swap = "-part4";
    bootPool = "-part2";
    rootPool = "-part3";
  };
  zfsRoot.devNodes = "/dev/disk/by-id/"; # MUST have trailing slash! /dev/disk/by-id/
  zfsRoot.bootDevices = (import ./machine.nix).bootDevices;
  zfsRoot.mirroredEfi = "/boot/efis/";

in {
  imports = [
    # (modulesPath + "/profiles/qemu-guest.nix")
    # (modulesPath + "/profiles/all-hardware.nix")
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
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
		git.enable = true;
		gnupg.agent = {
			enable = true;
			enableSSHSupport = true;
		};
		mtr.enable = true;
    vim = {
			defaultEditor = true;
    };
		zsh = {
			enable = true;
			ohMyZsh = {
				enable = true;
				plugins = [ "git" "man" ];
				theme = "bureau";
			};
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

  boot.initrd.availableKernelModules = [
    "ahci"
    "xhci_pci"
    "virtio_pci"
    "virtio_blk"
    "ehci_pci"
    "nvme"
    "uas"
    "sd_mod"
    "sr_mod"
    "sdhci_pci"
  ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-intel" "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems = {
    "/" = {
      device = "rpool/nixos/root";
      fsType = "zfs";
      options = [ "X-mount.mkdir" ];
    };

    "/home" = {
      device = "rpool/nixos/home";
      fsType = "zfs";
      options = [ "X-mount.mkdir" ];
    };

    "/var/lib" = {
      device = "rpool/nixos/var/lib";
      fsType = "zfs";
      options = [ "X-mount.mkdir" ];
    };

    "/var/log" = {
      device = "rpool/nixos/var/log";
      fsType = "zfs";
      options = [ "X-mount.mkdir" ];
    };

    "/boot" = {
      device = "bpool/nixos/root";
      fsType = "zfs";
      options = [ "X-mount.mkdir" ];
    };
  } // (builtins.listToAttrs (map (diskName: {
    name = zfsRoot.mirroredEfi + diskName + zfsRoot.partitionScheme.efiBoot;
    value = {
      device = zfsRoot.devNodes + diskName + zfsRoot.partitionScheme.efiBoot;
      fsType = "vfat";
      options = [
        "x-systemd.idle-timeout=1min"
        "x-systemd.automount"
        "noauto"
        "nofail"
      ];
    };
  }) zfsRoot.bootDevices));

  swapDevices = (map (diskName: {
    device = zfsRoot.devNodes + diskName + zfsRoot.partitionScheme.swap;
    discardPolicy = "both";
    randomEncryption = {
      enable = true;
      allowDiscards = true;
    };
  }) zfsRoot.bootDevices);

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  boot.supportedFilesystems = [ "zfs" ];
  networking.hostId = "abcd1234";
  boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;
  boot.loader.efi.efiSysMountPoint = with builtins;
    (zfsRoot.mirroredEfi + (head zfsRoot.bootDevices) + zfsRoot.partitionScheme.efiBoot);
  boot.zfs.devNodes = zfsRoot.devNodes;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.generationsDir.copyKernels = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.copyKernels = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.zfsSupport = true;
  boot.loader.grub.extraInstallCommands = with builtins;
    (toString (map (diskName:
      "cp -r " + config.boot.loader.efi.efiSysMountPoint + "/EFI" + " "
      + zfsRoot.mirroredEfi + diskName + zfsRoot.partitionScheme.efiBoot + "\n")
      (tail zfsRoot.bootDevices)));
  boot.loader.grub.devices =
    (map (diskName: zfsRoot.devNodes + diskName) zfsRoot.bootDevices);
}

