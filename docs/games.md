# Games

## EQ Legends

Work by: Codex

This documents the working EQ Legends setup on Aura so it can be reproduced on a fresh install.

### Nix Prereqs

EQ Legends is launched with Faugus and wrapped in Gamescope for a controlled game-facing resolution.

Required repo state:
- `pkgs.faugus-launcher` is installed by `modules/homeModules/users/oj/base.nix`.
- `programs.gamescope.enable = true;` is enabled by `modules/nixosModules/programs/gaming.nix`.
- Do not enable `programs.gamescope.capSysNice` for this path. The capability wrapper caused UMU/pressure-vessel/bubblewrap to abort with `bwrap: Unexpected capabilities but not setuid`.

Apply the config on Aura:

```fish
just switch host=aura
```

### Install Through Faugus

1. Download the EQ Legends installer to `~/Downloads/EQLegends_setup.exe`.
2. Open Faugus Launcher.
3. Add a game with:
   - Title: `EQ Legends`
   - Path: `/home/oj/Downloads/EQLegends_setup.exe`
   - Prefix: `/home/oj/Faugus/eq-legends`
   - Runner: `Proton-GE Latest`
   - Launch Arguments: `WINEDLLOVERRIDES=winepulse.drv=d`
4. Launch it once to run the installer.
5. After install, edit the Faugus game entry:
   - Path: `/home/oj/Faugus/eq-legends/drive_c/users/Public/Daybreak Game Company/Installed Games/EverQuest Legends/LaunchPad.exe`
   - Prefix: `/home/oj/Faugus/eq-legends`
   - Runner: `Proton-GE Latest`

### Gamescope Launch Arguments

In Faugus, edit `EQ Legends` and set the per-game `Launch Arguments` field to:

```fish
WINEDLLOVERRIDES=winepulse.drv=d gamescope -w 2048 -h 1152 -W 1920 -H 1080 -b --
```

This makes Faugus build the command in this shape:

```fish
WINEDLLOVERRIDES=winepulse.drv=d gamescope -w 2048 -h 1152 -W 1920 -H 1080 -b -- umu-run LaunchPad.exe
```

Do not launch Faugus itself inside Gamescope. That caused Gamescope to treat `faugus-launcher` as the primary child; when Faugus spawned UMU/Proton and exited, Gamescope killed the game process tree.

### Resolution Notes

Gamescope uses two resolution pairs:
- `-w` / `-h`: resolution exposed to EQ.
- `-W` / `-H`: size of the Gamescope window on the niri desktop.

Aura's panel is physically `2880x1800`, but niri runs it at scale `1.5`, so apps see a logical desktop around `1920x1200`. Use logical sizes for `-W` / `-H`, not raw panel pixels.

Tested results:
- `1280x800` worked but made the UI too large.
- `1600x1000` crashed or behaved poorly.
- `1920x1080` worked as a stable baseline.
- `2048x1152` is the preferred game-facing size.
- `2560x1440` worked but made the UI too tiny.

The working setup intentionally uses a `16:9` Gamescope window on Aura's `16:10` display. This leaves small bars, but it is stable and gives a usable EQ UI size.

Avoid the attempted `16:10` Gamescope modes for this game:
- `1920x1200`, `2048x1280`, and `2160x1350` caused Gamescope to abort after Proton launched.
- The journal showed `gamescope-wl` dumping core in `gamescope::CWaylandInputThread::ThreadFunc` / `gamescope::IWaitable::OnPollHangUpEv`.
- Wine's later X11 errors were downstream of Gamescope's Xwayland server disappearing.
- `gamescope --backend sdl` avoided that exact abort path but hung instead.

Current preferred setting:

```fish
gamescope -w 2048 -h 1152 -W 1920 -H 1080 -b --
```

### EQ Client INI

Leave EQ's `eqclient.ini` alone for the durable Gamescope setup. During testing, direct no-Gamescope launches with windowed `1920x1200`, `1680x1050`, and `1280x720` changed the initial niri window size, but once fullscreened the EQ UI remained too small. The direct path was therefore abandoned.

The relevant file is:

```text
/home/oj/Faugus/eq-legends/drive_c/users/Public/Daybreak Game Company/Installed Games/EverQuest Legends/eqclient.ini
```

The known-restored settings after testing were:

```ini
Width=2880
Height=1800
WindowedWidth=2871
WindowedHeight=1765
FullscreenBitsPerPixel=32
FullscreenRefreshRate=0
Fullscreen=1
MaxFPS=120
```

### Runtime Config Location

Faugus stores game entries in:

```text
~/.config/faugus-launcher/games.json
```

The EQ Legends entry should contain the stable launch arguments:

```json
{
  "gameid": "eq-legends",
  "title": "EQ Legends",
  "path": "/home/oj/Faugus/eq-legends/drive_c/users/Public/Daybreak Game Company/Installed Games/EverQuest Legends/LaunchPad.exe",
  "prefix": "/home/oj/Faugus/eq-legends",
  "launch_arguments": "WINEDLLOVERRIDES=winepulse.drv=d gamescope -w 2048 -h 1152 -W 1920 -H 1080 -b --",
  "runner": "Proton-GE Latest",
  "prevent_sleep": true
}
```

Keep the rest of Faugus' generated fields as written by the UI.

### Debug Command

For debugging outside the Faugus UI, create a temporary launcher script using the current `umu-run` path from the installed Faugus package:

```fish
#!/usr/bin/env fish
set -l eqdir "/home/oj/Faugus/eq-legends/drive_c/users/Public/Daybreak Game Company/Installed Games/EverQuest Legends"
set -l umu_run "/nix/store/9fq84cwg489qwqk7qx3snpkmm9yhvpbw-umu-launcher-1.4.0/bin/umu-run"

env \
  WINEPREFIX="/home/oj/Faugus/eq-legends" \
  PROTONPATH="/home/oj/.local/share/Steam/compatibilitytools.d/Proton-GE Latest" \
  GAMEID="eq-legends" \
  UMU_ID="eq-legends" \
  UMU_LOG="1" \
  PROTON_LOG="1" \
  PROTON_LOG_DIR="/home/oj/.config/faugus-launcher/logs/eq-legends" \
  WINEDLLOVERRIDES="winepulse.drv=d" \
  gamescope -w 2048 -h 1152 -W 1920 -H 1080 -b -- \
  "$umu_run" \
  "$eqdir/LaunchPad.exe"
```

The store path for `umu-run` can change after rebuilds or package updates, so prefer the Faugus `Launch Arguments` method for the durable setup.

### Troubleshooting Notes

If Faugus launches the game at `2048x1280`, change it back to the stable `2048x1152 -> 1920x1080` setting. `2048x1280` was one of the crashing `16:10` attempts.

If the game starts outside Gamescope but the UI is too small, that is expected from the direct path. The INI resolution changes did not fix the final fullscreen UI scale under niri.

If Gamescope crashes, check:

```fish
journalctl --user -b --grep 'gamescope|IWaitable|dumped core'
```

The expected bad signature from the failed `16:10` attempts is a Gamescope coredump in its Wayland input/waitable handling, followed by Gamescope's reaper killing Proton/EQ children.
