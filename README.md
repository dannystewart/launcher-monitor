# Steam Launcher Monitor

An AutoHotkey v2 script that automatically closes game launchers when the actual game isn't running, preventing inflated Steam hour counts.

## Problem Solved

When you run a game through Steam that has a launcher:

1. Steam → Launcher → Game
2. When you quit the game, you're back to the launcher
3. Steam keeps counting hours as long as the launcher is open
4. Forgetting to close the launcher can add 8-12+ hours of fake playtime

This script monitors both the launcher and game processes and automatically closes the launcher if the game hasn't been running for a specified timeout period (default: 30 minutes).

## Setup Instructions

### 1. Install AutoHotkey

- Download and install AutoHotkey from: <https://www.autohotkey.com/>
- **Choose AutoHotkey v2** (this script is written for v2)

### 2. Configure Process Names

You need to find the exact process names for your game's launcher and the actual game executable.

**To find process names:**

1. Open Task Manager (Ctrl+Shift+Esc)
2. Go to the "Details" tab
3. Launch your game through Steam
4. Look for the launcher process (usually appears first)
5. Click "Play" in the launcher
6. Look for the game process (appears when game actually starts)
7. Note both process names (without the .exe extension)

**Common examples:**

- **Bethesda.net Launcher**: `Bethesda.net_Launcher` (launcher) + `eso64` (game)
- **Rockstar Games Launcher**: `LauncherPatcher` (launcher) + `RDR2` (game)
- **Epic Games Launcher**: `EpicGamesLauncher` (launcher) + `FortniteClient-Win64-Shipping` (game)
- **Ubisoft Connect**: `upc` (launcher) + `ACValhalla` (game)
- **EA Desktop**: `EADesktop` (launcher) + `FIFA23` (game)

### 3. Run and Configure the Script

**Normal startup** (with notification):

```bash
SteamLauncherMonitor.ahk
```

**Silent startup** (no notification):

```bash
SteamLauncherMonitor.ahk -silent
```

1. Double-click `SteamLauncherMonitor.ahk` to run it
2. Right-click the system tray icon (near your clock)
3. Select "Configure"
4. Enter your launcher and game process names
5. Set your desired timeout (default: 30 minutes)
6. Set force close timeout (default: 10 seconds)
7. Click "Save"

## Usage

### System Tray Menu

Right-click the tray icon to access:

- **Show Status**: View current monitoring status
- **Configure**: Change process names and timeouts
- **View Log**: Open the log file to see activity
- **Reload Script**: Restart the script (useful after making changes)
- **Exit**: Stop the script

### Hotkeys

- `Ctrl+Alt+S`: Show status window
- `Ctrl+Alt+C`: Open configuration window

### How It Works

1. Script monitors for both launcher and game processes every 10 seconds
2. When launcher starts, timer begins
3. When game starts, script knows you're actively playing
4. When game closes, script starts a configurable countdown (default: 30 minutes)
5. If launcher is still open after the timeout without the game, it gets closed automatically
6. Uses graceful close first, then force-close after configurable timeout (default: 10 seconds)
7. All activity is logged to `launcher_monitor.log`

## Configuration File

Settings are automatically saved to `config.ini` in the script directory:

```ini
[Settings]
LauncherProcess=Bethesda.net_Launcher
GameProcess=eso64
TimeoutMinutes=30
ForceCloseTimeoutSeconds=10
EnableLogging=1
```

## Running at Startup (Optional)

To have the script start automatically with Windows:

1. Press `Win+R`, type `shell:startup`, press Enter
2. Create a shortcut to `SteamLauncherMonitor.ahk` in this folder
3. Edit the shortcut properties and add `-silent` to the target for quiet startup:

```text
"C:\path\to\SteamLauncherMonitor.ahk" -silent
```

4. The script will now start silently with Windows

## Command Line Options

- **No arguments**: Normal startup with notification
- **`-silent` or `/silent`**: Start without showing startup notification (perfect for startup scripts)

## Troubleshooting

### Script doesn't detect processes

- Verify process names in Task Manager (Details tab)
- Process names are case-sensitive
- Don't include the `.exe` extension in configuration

### Launcher closes too quickly/slowly

- Adjust the main timeout in configuration (minutes)
- Adjust the force close timeout for stubborn launchers (seconds)
- Check the log file to see timing information

### Script not working

- Make sure **AutoHotkey v2** is installed (not v1.1)
- Check if antivirus is blocking the script
- Run as administrator if needed

## Log File

The script creates `launcher_monitor.log` with timestamps for:

- When launcher/game processes start and stop
- When timeouts occur and launcher is closed
- Configuration changes
- Script startup and shutdown

## Safety Features

- Uses graceful window close first, then force-close if needed
- Configurable force-close timeout for stubborn launchers
- Only closes the specific launcher process you configure
- Logs all actions for troubleshooting
- Can be easily disabled/enabled via tray menu
- Silent mode for automated startup

## New Features

- **AutoHotkey v2 compatibility**
- **Silent mode** with `-silent` command line flag
- **Reload script** option in tray menu
- **Configurable force-close timeout** for launchers that take time to close
- **Startup notifications** (can be disabled with silent mode)

## Customization

You can modify the script to:

- Change the check interval (default: 10 seconds)
- Add multiple game/launcher pairs
- Customize notification behavior
- Add additional hotkeys
- Modify timeout behaviors

Enjoy your accurate Steam hour counts!
