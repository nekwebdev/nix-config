{...}: {
  flake.homeModules.mangohud = {...}: {
    programs.mangohud = {
      enable = true;
      settings = {
        control = "mangohud";
        fsr_steam_sharpness = 5;
        nis_steam_sharpness = 10;
        legacy_layout = 0;
        horizontal = true;
        position = "top-center";
        gpu_stats = true;
        cpu_stats = true;
        cpu_power = true;
        gpu_power = true;
        ram = true;
        fps = true;
        frametime = 0;
        hud_no_margin = true;
        table_columns = 14;
        frame_timing = 1;
      };
    };
  };
}
