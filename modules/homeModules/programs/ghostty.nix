{...}: {
  flake.homeModules.ghostty = {...}: {
    programs.ghostty = {
      enable = true;
      settings = {
        theme = "dankcolors";
        font-family = "FiraCode Nerd Font";
        font-size = 12;

        window-decoration = false;
        window-padding-x = 12;
        window-padding-y = 12;
        background-opacity = 0.9;
        background-blur = true;

        cursor-style = "block";
        cursor-style-blink = true;

        scrollback-limit = 3023;

        mouse-hide-while-typing = true;
        copy-on-select = true;
        confirm-close-surface = false;

        app-notifications = "no-clipboard-copy,no-config-reload";

        keybind = [
          "ctrl+shift+n=new_window"
          "ctrl+t=new_tab"
          "ctrl+plus=increase_font_size:1"
          "ctrl+minus=decrease_font_size:1"
          "ctrl+zero=reset_font_size"
          "shift+enter=text:\\n"
        ];

        unfocused-split-opacity = 0.7;
        unfocused-split-fill = "#44464f";

        gtk-titlebar = false;

        shell-integration = "detect";
        shell-integration-features = "cursor,sudo,title,no-cursor";
      };
    };
  };
}
