{ config, pkgs, ... }:
let
  home-manager = builtins.fetchTarball https://github.com/rycee/home-manager/archive/release-19.09.tar.gz;
in
{
  nix.nixPath = [
    "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
    "nixos-config=/home/cmacrae/dev/nix/thinkpad/configuration.nix:/nix/var/nix/profiles/per-user/root/channels"
  ];

  imports = [
    "${home-manager}/nixos"
    ../lib/home.nix

    (import ../lib/desktop.nix {
      extraPkgs = with pkgs; [
        awscli
        aws-iam-authenticator
        docker-compose
        eksctl
        kubernetes
        minikube
        nfs-utils
        pantheon.elementary-files
        slack
        spotify
      ];

      inputs = ''
        input "1:1:AT_Translated_Set_2_keyboard" {
            xkb_layout gb
            xkb_options ctrl:nocaps
        }
        
        input "1739:0:Synaptics_TM3381-002" {
            pointer_accel 0.7
            tap enabled
            dwt enabled
            natural_scroll enabled
        }
      '';

      outputs = ''
        {
          output eDP-1
        }
        {
          output HDMI-A-2 position 0,0
          output eDP-1 position 320,1440
        }
        {
          output DP-1 position 0,0
          output HDMI-A-2 position 2560,0
          output eDP-1 position 1596,1440
        }
      '';

      extraSwayConfig = ''
        bindsym $mod+Print exec slurp | grim -g - - | wl-copy
      '';
    })

    # Sys Specific
    ./hardware-configuration.nix
  ];

  boot.cleanTmpDir = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.zfsSupport = true;
  boot.loader.grub.copyKernels = true;
  boot.loader.grub.device = "nodev";
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.checkJournalingFS = false;
  boot.supportedFilesystems = [ "zfs" ];

  powerManagement.enable = true;
  services.tlp.enable = true;
  services.logind.extraConfig = ''
    HandlePowerKey=ignore
  '';

  networking = {
    hostId = "9938e3e0";
    hostName = "thinkpad";
    networkmanager.enable = true;
  };

  services.openvpn.servers.moo = {
    autoStart = false;
    config = "config /home/cmacrae/dev/nix/thinkpad/moo.ovpn";
    up = "echo nameserver $nameserver | ${pkgs.openresolv}/sbin/resolvconf -m 0 -a $dev";
    down = "${pkgs.openresolv}/sbin/resolvconf -d $dev";
  };

  virtualisation.libvirtd.enable = true;

  security.sudo.extraConfig = ''
    %wheel	ALL=(root)	NOPASSWD: ${pkgs.systemd}/bin/systemctl * openvpn-moo
  '';

  system.stateVersion = "19.09";
}
