{ config, lib, pkgs, ... }:
let
  swayAssets = "https://raw.githubusercontent.com/swaywm/sway/master/assets";
  wall = (builtins.fetchurl "${swayAssets}/Sway_Wallpaper_Blue_1920x1080.png");
  url = "https://github.com/colemickens/nixpkgs-wayland/archive/master.tar.gz";
  waylandOverlay = (import (builtins.fetchTarball url));
in
{
  nixpkgs.overlays = [ waylandOverlay ];
  programs.sway-beta = {
    enable = true;
    extraPackages = with pkgs; [
      swayidle
      swaylock

      waybar        # polybar-alike
      i3status-rust # simpler bar written in Rust

      grim     # screen image capture
      slurp    # screen are selection tool
      mako     # notification daemon
      wlstream # screen recorder
      oguri    # animated background utility
      kanshi   # dynamic display configuration helper
      redshift-wayland # patched to work with wayland gamma protocol

      rofi
      xwayland
      libnl
      libpulseaudio
    ];
    extraSessionCommands = ''
      # Tell toolkits to use wayland
      export GDK_BACKEND=wayland
      export CLUTTER_BACKEND=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      export SDL_VIDEODRIVER=wayland

      # Fix krita and other Egl-using apps
      export LD_LIBRARY_PATH=/run/opengl-driver/lib

      # Disable HiDPI scaling for X apps
      # https://wiki.archlinux.org/index.php/HiDPI#GUI_toolkits
      export GDK_SCALE=1
      export QT_AUTO_SCREEN_SCALE_FACTOR=0
      
      # capslock as ctrl
      export XKB_DEFAULT_OPTIONS=ctrl:nocaps
    '';
  };

  home-manager.users.cmacrae = {
    xdg.enable = true;
    xdg.configFile."sway/config" = {
        source = pkgs.substituteAll {
          name = "sway-config";
          src = ./conf.d/sway-config;
          wallpaper = "${wall}";
        };
        onChange = ''
          echo "Reloading sway"
          # FIXME: swaymsg reload
          #   ERR: 'sway socket not detected'
        '';
    };

    xdg.configFile."kanshi/config".text = ''
      {
        output eDP-1
      }
      {
        output HDMI-A-1 resolution 1920x1080 pos 0 0
        output eDP-1 position 330 1080
      }
    '';

    xdg.configFile."waybar/config".text = (builtins.readFile ./conf.d/waybar.json);
    xdg.configFile."waybar/style.css".text = (builtins.readFile ./conf.d/waybar.css);

    # Give termite a little padding
    xdg.configFile."gtk-3.0/gtk.css".text = ''
      VteTerminal, vte-terminal {
          padding: 15px;
      }
    '';

    programs.termite = {
      enable = true;
      clickableUrl = true;
      mouseAutohide = true;
      audibleBell = false;
      urgentOnBell = true;
      dynamicTitle = true;
      scrollbar = "off";
      browser = "${pkgs.xdg_utils}/xdg-open";

      # Darktooth
      backgroundColor = "rgba(29, 32, 33)";
      cursorColor = "#D5C4A1";
      cursorForegroundColor = "#1D2021";
      foregroundColor = "#A89984";
      foregroundBoldColor = "#D5C4A1";
      colorsExtra = ''
        # Black, Gray, Silver, White
        color0  = #1D2021
        color8  = #665C54
        color7  = #A89984
        color15 = #FDF4C1

        # Red
        color1  = #FB543F
        color9  = #FB543F

        # Green
        color2  = #95C085
        color10 = #95C085

        # Yellow
        color3  = #FAC03B
        color11 = #FAC03B

        # Blue
        color4  = #0D6678
        color12 = #0D6678
        # Purple
        color5  = #8F4673
        color13 = #8F4673

        # Teal
        color6  = #8BA59B
        color14 = #8BA59B

        # Extra colors
        color16 = #FE8625
        color17 = #A87322
        color18 = #32302F
        color19 = #504945
        color20 = #928374
        color21 = #D5C4A1
      '';
    };
  };
}
