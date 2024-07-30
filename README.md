<img src="Thorium-WinUpdater.ico" align="right">

# Thorium WinUpdater
By ltGuillaume: [Codeberg](https://codeberg.org/ltGuillaume) | [GitHub](https://github.com/ltGuillaume) | [Buy me a beer](https://buymeacoff.ee/ltGuillaume) 🍺

## Support has ended
I have decided to stop support for Thorium WinUpdater. This is primarily because of the lack of regular updates to the Thorium project, which leaves users vulnerable to 0-days for many months at a time. As such, I feel uncomfortable to recommend using Thorium by offering this updater. Additionally, due to a lack of proper release and naming conventions of the Thorium project, I have found it to be impossible to guarantee a reliant update flow via WinUpdater. For more information, see https://github.com/ltguillaume/thorium-winupdater/issues/7#issuecomment-2072405293. You are free to fork this repo to continue development. _I would greatly appreciate it if you dropped a note here if you are going to continue the project._

An attempt to make updating [Thorium for Windows](https://github.com/Alex313031/Thorium-Win-AVX2) much easier. This is a fork of [LibreWolf WinUpdater](https://codeberg.org/ltGuillaume/librewolf-winupdater).

![Thorium WinUpdater](SCREENSHOT.png)

## Usage
- If you want to run the portable version of Thorium, download and extract [`Thorium_???_xxx.x.xxxx.x.zip`](https://github.com/Alex313031/Thorium-Win/releases). Put `Thorium-WinUpdater.exe` in the same folder.  
  Then, if you wish to perform an update, just run `Thorium-WinUpdater.exe`.
- When you have installed Thorium using the [Thorium_???_mini_installer.exe](https://github.com/Alex313031/Thorium-Win/releases), just run `Thorium-WinUpdater.exe` from any location to check for updates. If one is available, the new mini installer will be downloaded immediately.

## Scheduled Updates
- Run Thorium WinUpdater and select the option to automatically check for updates. This will prompt for administrative permissions and a blue (PowerShell) window will open and notify you of the result. The scheduled task will run while the current user account is logged on (at start-up and every 24 hours).
- If your account has administrator privileges, the update will be fully automatic. If not, the update will be downloaded and you will be asked by WinUpdater to start the update.  
- If Thorium is already running, the updater will notify you of the new version. The update will start as soon as you close the browser.

## Remarks
- The updater needs to be able to write to `Thorium-WinUpdater.ini` in its own folder (so make sure it has permission to do so), otherwise WinUpdater will copy itself to `%LocalAppData%\Thorium\WinUpdater` and run from there.
- `Thorium-WinUpdater.ini` contains a `[Log]` section that shows the results of the last update check and update action.
- Thorium WinUpdater also updates itself automatically, so you won't have to check for new releases here. If you prefer to update WinUpdater yourself, add the following to the .ini file:
  ```ini
  [Settings]
  UpdateSelf=0
  ```
- Thorium should automatically detect which build you are currently using (e.g. `SSE3`, `AVX`, or `AVX2`) thanks to the `thor_ver` file. It'll show the detected version next to the version number in the UI and in the `[Log]` part of `Thorium-WinUpdater.ini`.
- __NOTE:__ The `AVX` build is for systems lacking [AVX2 instructions](https://en.wikipedia.org/wiki/Advanced_Vector_Extensions#CPUs_with_AVX2). The [Win7](https://github.com/Alex313031/Thorium-Win7/releases) builds are for Windows 7/8/8.1 systems, because of Chromium deprecating support for these OSes as per [here](https://support.google.com/chrome/thread/185534985/).

## Building
- Requires [AutoHotKey 1.1](https://www.autohotkey.com/) \
  See [BUILDING.md](BUILDING.md)

## Credits
* [Thorium](https://thorium.rocks) by [Alex Frick](https://github.com/Alex313031)
* [The Chromium Project](https://www.chromium.org)
* [Original icon](https://github.com/Alex313031/thorium/blob/main/logos/NEW/win/thorium.ico) by Alex Frick
* [Original logo](https://github.com/Alex313031/thorium/blob/main/logos/STAGING/Thorium90_252.jpg) by Alex Frick
