{ config, lib, pkgs, ... }:
let
  homeDir = "/Users/cmacrae";
  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/master.tar.gz;
  autoterm = pkgs.writeShellScriptBin "autoterm" ''
    ARGS=("$@")
    exec /usr/bin/login "''${ARGS[@]}" \
    ${pkgs.htop}/bin/htop -C
  '';

in
{
  imports = [ ../lib/home.nix "${home-manager}/nix-darwin" ];

  system.stateVersion = 4;
  nix.maxJobs = 8;
  nix.buildCores = 0;
  nix.package = pkgs.nix;
  nixpkgs.config.allowUnfree = true;

  # Remote builder for linux
  services.nix-daemon.enable = true;
  nix.distributedBuilds = true;
  nix.buildMachines = [
    {
      hostName = "compute1";
      sshUser = "root";
      sshKey = "${homeDir}/.ssh/id_rsa";
      systems = [ "x86_64-linux" ];
      maxJobs = 16;
    }
    # {
    #   hostName = "compute2";
    #   sshUser = "root";
    #   sshKey = "${homeDir}/.ssh/id_rsa";
    #   systems = [ "x86_64-linux" ];
    #   maxJobs = 16;
    # }
    # {
    #   hostName = "compute3";
    #   sshUser = "root";
    #   sshKey = "${homeDir}/.ssh/id_rsa";
    #   systems = [ "x86_64-linux" ];
    #   maxJobs = 16;
    # }
    {
      hostName = "net1";
      sshUser = "root";
      sshKey = "${homeDir}/.ssh/id_rsa";
      systems = [ "aarch64-linux" ];
      maxJobs = 4;
    }
  ];

  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;
  environment.darwinConfig = "${homeDir}/dev/nix/darwin/configuration.nix";
  environment.systemPackages = [ pkgs.gcc ];

  time.timeZone = "Europe/London";

  system.defaults = {
    dock = {
      autohide = true;
      mru-spaces = false;
      minimize-to-application = true;
    };

    screencapture.location = "/tmp";

    finder = {
      AppleShowAllExtensions = true;
      _FXShowPosixPathInTitle = true;
      FXEnableExtensionChangeWarning = false;
    };

    trackpad = {
      Clicking = true;
      TrackpadThreeFingerDrag = true;
    };
  };

  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToControl = true;
  };

  # VT220 hacks
  # --
  # I use and old DEC VT220 terminal at home.
  # These hacks put in place auto-login with getty.
  # This is done using a 'Plugable' USB to DB9 serial
  # adapter. The drivers from Plugable's site should
  # be installed first.
  environment.etc."gettytab".text = ''
    ${builtins.readFile ../conf.d/gettytab.orig}
    #
    # VT220 via USB serial - added by cmacrae
    #
    std.ttyusbserial:\
    	:np:tt=vt220:sp#19200:im=\r\n:al=cmacrae:lo=${autoterm}/bin/autoterm:
  '';

  launchd.daemons.serialconsole = {
    command = "/usr/libexec/getty std.ttyusbserial cu.usbserial";
    serviceConfig.KeepAlive = true;
  };

  # Recreate /run/current-system symlink after boot
  services.activate-system.enable = true;
}
