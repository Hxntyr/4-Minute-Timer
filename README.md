# 4 Minute Timer

A Windows PowerShell timer that counts down from four minutes, plays a short chime, and automatically repeats.

A lightweight alternative to keeping a browser-based timer running. This script runs locally without internet connection.

![4 Minute Timer](Timer%20Window.png)

## Features

* 4-minute repeating countdown
* Start / Stop toggle
* Mute / Unmute toggle
* Self-generated chime — no audio file required
* Remembers its last window position
* Always stays on top (changeable via bool, see code line 80)
* No installation or external dependencies
* Uses standard Windows PowerShell / WinForms components

## Usage

For ease of use I personally recommend storing the .ps1 script in `%USERPROFILE%` then putting a shortcut to the script in `%APPDATA%\Microsoft\Windows\Start Menu\Programs` for a one-click run from the start menu.

Alternatively:
Download `timer_4min.ps1` and run it with PowerShell:

```powershell
.\timer_4min.ps1
```

### Note
If PowerShell script execution is disabled, a reasonable per-user setting is:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

The timer opens stopped at `4:00`. Press **Start** to begin. When the countdown reaches zero, it plays a chime, resets to four minutes, and continues running.

Closing and reopening the timer resets the countdown and mute state. Window position is saved in:

```text
%LOCALAPPDATA%\FourMinuteTimer\settings.json
```

## License

MIT License. See `LICENSE` for details.
