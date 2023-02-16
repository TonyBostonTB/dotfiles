{ config, pkgs, ... }:

{
  home = {
  	username = "tboston";
  	homeDirectory = "/home/tboston";
  	packages = with pkgs; [
			brave
	];
  	stateVersion = "22.11";
  };

  programs = {
  	git = {
			enable = true;
			userName = "Tony Boston";
			userEmail = "tboston@posteo.net";
		};

  	home-manager.enable = true;

		neovim = {
			enable = true;
			extraConfig = ''
				set ts=2
				set sw=2
				set expandtab
				set number
			'';
      vimAlias = true;
		};
  };
}
