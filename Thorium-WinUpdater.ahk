; Thorium WinUpdater - https://codeberg.org/ltguillaume/thorium-winupdater
;@Ahk2Exe-SetFileVersion 1.8.5
;@Ahk2Exe-SetProductVersion 1.8.5

;@Ahk2Exe-Base Unicode 32*
;@Ahk2Exe-SetCompanyName The Chromium Authors and Alex313031
;@Ahk2Exe-SetCopyright ltguillaume and Alex313031
;@Ahk2Exe-SetDescription Thorium Browser Windows Updater
;@Ahk2Exe-SetMainIcon Thorium-WinUpdater.ico
;@Ahk2Exe-AddResource Thorium-WinUpdaterLogo.ico, 160
;@Ahk2Exe-SetOrigFilename Thorium-WinUpdater.exe
;@Ahk2Exe-SetProductName Thorium WinUpdater
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,206`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,207`, ,,,,1
;@Ahk2Exe-PostExec ResourceHacker.exe -open "%A_WorkFileName%" -save "%A_WorkFileName%" -action delete -mask ICONGROUP`,208`, ,,,,1

#NoEnv
#SingleInstance, Off

Global Args       := ""
, Browser         := "Thorium"
, ExtractDir      := A_Temp "\" Browser "-Extracted"
, BrowserExe      := "thorium.exe"
, PortableDir     := A_ScriptDir "\Bin"
, PortableBrowser := PortableDir "\" BrowserExe
, ConnectCheckUrl := "https://github.com/manifest.json"
, InstallerFile   := "installer\.exe"
, PortableFile    := "\.zip"
, ReleaseApiUrl   := "https://api.github.com/repos/Alex313031/Thorium-{}/releases/latest"
, SelfUpdateZip   := Browser "-WinUpdater.zip"
, SetupParams     := "--do-not-launch-chrome"
, TaskCreateFile  := "ScheduledTask-Create.ps1"
, TaskRemoveFile  := "ScheduledTask-Remove.ps1"
, UpdaterFile     := Browser "-WinUpdater.exe"
, IsPortable      := FileExist(PortableBrowser)
, RunningPortable := A_Args[1] = "/Portable"
, Scheduled       := A_Args[1] = "/Scheduled"
, SettingTask     := A_Args[1] = "/CreateTask" Or A_Args[1] = "/RemoveTask"
, ChangesMade     := False
, Done            := False
, IniFile, LocalAppData, Path, ProgramW6432, Repo, Build, UpdateSelf, Task, CurrentUpdaterVersion, ReleaseInfo, CurrentVersion, NewVersion, SetupFile, GuiHwnd, LogField, ProgField, VerField, TaskSetField, UpdateButton

; Strings
Global _Updater       := Browser " WinUpdater"
, _NoConnectionError  := "Could not connect to " SubStr(ConnectCheckUrl, 1, InStr(ConnectCheckUrl, "/",,, 3) - 1) "."
, _IsRunningError     := _Updater " is already running."
, _IsElevated         := "To set up scheduled tasks properly, please do not run WinUpdater as administrator."
, _NoDefaultBrowser   := "Could not open your default browser."
, _Checking           := "Checking for new version..."
, _SetTask            := "Schedule a task for automatic update checks while`nuser {} is logged on."
, _SettingTask        := (A_Args[1] = "/CreateTask" ? "Creating" : "Removing") " scheduled task..."
, _Done               := " Done."
, _GetPathError       := "Could not find the path to " Browser ".`nBrowse to " BrowserExe " in the following dialog."
, _SelectFileTitle    := _Updater " - Select " BrowserExe "..."
, _WritePermError     := "Could not write to`n{}. Please check the current user account's write permissions for this folder."
, _CopyError          := "Could not copy {}"
, _GetBuildError      := "Could not determine the build type of " Browser "."
, _GetVersionError    := "Could not determine the current version of`n{}"
, _DownloadJsonError  := "Could not download the {Task} releases file."
, _ApiRateLimit       := "GitHub's API rate limit was exceeded for your IP. You can try again later."
, _JsonVersionError   := "Could not get version info from the {Task} releases file."
, _FindUrlError       := "Could not find the URL to download {Task}."
, _Downloading        := "Downloading new version..."
, _DownloadSelfError  := "Could not download the new WinUpdater version."
, _DownloadSetupError := "Could not download the setup file."
, _Downloaded         := "New version downloaded."
, _CheckingHash       := "Checking file integrity..."
, _FindSumsUrlError   := "Could not find the URL to the checksum file."
, _FindChecksumError  := "Could not find the checksum for the downloaded file."
, _ChecksumMatchError := "The file checksum did not match, so it's possible the download failed."
, _ChangesMade        := "However, new files were written to the target folder!"
, _NoChangesMade      := "No changes were made to your " Browser " folder."
, _Extracting         := "Extracting portable version..."
, _StartUpdate        := "  &Start update  "
, _Installing         := "Installing new version..."
, _UpdateError        := "Error while updating."
, _SilentUpdateError  := "Silent update did not complete.`nDo you want to run the interactive installer?"
, _NewVersionFound    := "A new version is available.`nClose " Browser " to start updating..."
, _NoNewVersion       := "No new version found."
, _ExtractionError    := "Could not extract the {Task} archive.`nMake sure " Browser " is not running and restart the updater."
, _MoveToTargetError  := "Could not move the following file into the target folder:`n{}"
, _IsUpdated          := Browser " has been updated."
, _To                 := "to"
, _GoToWebsite        := "<a>Restart WinUpdater</a> or visit the <a>project website</a> for help."

Init()
CheckArgs()
CheckPaths()
GetCurrentVersion()
If (ThisUpdaterRunning())
	Die(_IsRunningError,, !Scheduled)	; Show only if not scheduled
Unelevate()
CheckWriteAccess()
If (SettingTask)
	TaskSet()
CheckConnection()
If (UpdateSelf And A_IsCompiled)
	SelfUpdate()
If (GetNewVersion())
	StartUpdate()
Exit()

Init() {
	FileGetVersion, CurrentUpdaterVersion, %A_ScriptFullPath%
	CurrentUpdaterVersion := SubStr(CurrentUpdaterVersion, 1, -2)
	EnvGet, ProgramW6432, ProgramW6432
	EnvGet, LocalAppData, LocalAppData
	SplitPath, A_ScriptFullPath,,,, BaseName
	IniFile := A_ScriptDir "\" BaseName ".ini"
	IniRead, UpdateSelf, %IniFile%, Settings, UpdateSelf, 1	; Using "False" in .ini causes If (UpdateSelf) to be True
	SetWorkingDir, %A_Temp%
	Menu, Tray, Tip, %_Updater% %CurrentUpdaterVersion%
	Menu, Tray, NoStandard
	Menu, Tray, Add, Show, TrayAction
;	Menu, Tray, Add, Portable, TrayAction
	Menu, Tray, Add, WinUpdater, TrayAction
	Menu, Tray, Add, Exit, TrayAction
	Menu, Tray, Default, Show

	; Set up GUI
	Gui, +HwndGuiHwnd -MaximizeBox
	Gui, Color, 23222B
	Gui, Add, Picture, x12 y10 w64 h64 Icon2, %A_ScriptFullPath%
	Gui, Font, cC58FC1 s22 w700, Segoe UI
	Gui, Add, Text, x85 y4 BackgroundTrans, %Browser%
	Gui, Font, cFFFFFF s9 w700
	Gui, Add, Text, vVerField x86 y42 w222 BackgroundTrans, `n
	Gui, Font, w400
	Gui, Add, Progress, vProgField w217 h20 cB483BB, 10
	Gui, Add, Text, vLogField w222
	Gui, Margin,, 15
	Gui, Show, Hide, %_Updater% %CurrentUpdaterVersion%

	If (SettingTask Or !A_Args.Length()) {	; No arguments: when not running as portable or as a scheduled task
		If (!IsPortable And FileExist(A_ScriptDir "\" TaskCreateFile) And FileExist(A_ScriptDir "\" TaskRemoveFile)) {	; No scheduled tasks for portable version
			Gui, Add, CheckBox, vTaskSetField gTaskSet x15 y+10 w290 cBCBCBC Center Check3 -Tabstop, % StrReplace(_SetTask, "{}", A_UserName)
			TaskCheck()
		}
		GuiShow()
	}
}

TrayAction(ItemName, GuiEvent, LinkIndex) {
	If (ItemName = "Show") {
		If (!WinExist("ahk_id " GuiHwnd))
			GuiShow()
		WinWait, ahk_id %GuiHwnd%
		WinActivate
		Return
	} Else If (ItemName = "Exit") {
		If (Done)
			GuiClose()
		Else
			GuiShow()
		Return
	}
	If (LinkIndex = 1)
		Return Restart()
	If (LinkIndex = 2)
		ItemName := "WinUpdater"

	Url := "https://codeberg.org/ltguillaume/" Browser "-" ItemName
	Try Run, %Url%
	Catch {
		RegRead, DefBrowser, HKCR, .html
		RegRead, DefBrowser, HKCR, %DefBrowser%\Shell\Open\Command
		Run, % StrReplace(DefBrowser, "%1", Url)
		If (ErrorLevel)
			MsgBox, 48, %_Updater%, %_NoDefaultBrowser%
	}
}

CheckArgs() {
	Args := ""
	For i, Arg in A_Args
	{
		If (InStr(Arg, A_Space))
			Arg := """" Arg """"
		Args .= " " Arg
	}
}

CheckPaths() {
	If (IsPortable)
		Path := PortableBrowser
	Else {
		IniRead, Path, %IniFile%, Settings, Path, 0	; Need to use 0, because False would become a string
		If (!Path) {
			RegRead, Path, HKLM\SOFTWARE\Clients\StartMenuInternet\%Browser%\shell\open\command
			If (ErrorLevel)
				Path = %LocalAppData%\%Browser%\Application\%BrowserExe%
		}
		Path := Trim(Path, """")	; FileExist chokes on double quotes

		If (FileExist(Path) And (InStr(Path, ProgramW6432) Or InStr(Path, A_ProgramFiles)))
			SetupParams .= " --system-level"
		Else If (A_IsAdmin And !IsPortable)
			Unelevate(True)
	}
;MsgBox, Path = %Path%`nSetupParams = %SetupParams%

	CheckPath:
	If (!FileExist(Path)) {
		MsgBox, 48, %_Updater%, %_GetPathError%
		FileSelectFile, Path, 3, %Path%, %_SelectFileTitle%, %BrowserExe%
		If (ErrorLevel)
			ExitApp
		Else {
			IniWrite, %Path%, %IniFile%, Settings, Path
			Goto, CheckPath
		}
	}
}

ThisUpdaterRunning() {
	Process, Exist	; Put launcher's process id into ErrorLevel
	Query := "Select ProcessId from Win32_Process where ProcessId!=" ErrorLevel " and ExecutablePath=""" StrReplace(A_ScriptFullPath, "\", "\\") """"
	For Process in ComObjGet("winmgmts:").ExecQuery(Query) {
		Sleep, 1000
		For Process in ComObjGet("winmgmts:").ExecQuery(Query)
			Return True
		Break
	}
}

SelfUpdate() {
	Task := _Updater
;MsgBox, % GetLatestVersion() " > " CurrentUpdaterVersion
	If (!VerCompare(GetLatestVersion(), ">" CurrentUpdaterVersion))
		Return

	RegExp := "i)name"":\s*""" Browser "-WinUpdater.+?\.zip"".*?browser_download_url"":\s*""(.*?)"""
	RegExMatch(ReleaseInfo, RegExp, DownloadUrl)
;MsgBox, %DownloadUrl1%
	If (!DownloadUrl1)
		Return Log("SelfUpdate", _FindUrlError, True)

	UrlDownloadToFile, %DownloadUrl1%, %SelfUpdateZip%
	If (!FileExist(SelfUpdateZip))
		Return Log("SelfUpdate", _DownloadSelfError, True)
;MsgBox, Extracting Self-Update
	FileMove, %A_ScriptFullPath%, %A_ScriptFullPath%.wubak, 1
	If (!Extract(A_Temp "\" SelfUpdateZip, A_ScriptDir))
		Return Log("SelfUpdate", _ExtractionError, True)

	If (IsPortable) {
		FileDelete, %A_ScriptDir%\%TaskCreateFile%
		FileDelete, %A_ScriptDir%\%TaskRemoveFile%
	}

	If (!FileExist(A_ScriptDir "\" UpdaterFile))
		Die(_ExtractionError)

	If (A_ScriptName <> UpdaterFile)
		FileMove, %A_ScriptDir%\%UpdaterFile%, %A_ScriptFullPath%

	Run, %A_ScriptFullPath% %Args%
	ExitApp
}

CheckWriteAccess() {
	If (!FileExist(A_ScriptDir "\" BrowserExe)) {
		FileAppend,, %IniFile%
		If (!ErrorLevel)
			Return
	}

	AppData := LocalAppData "\" Browser "\WinUpdater"

	If (IsPortable Or A_ScriptDir = AppData)
		Die(_WritePermError, A_ScriptDir)

	FileCreateDir, %AppData%
	If (ErrorLevel)
		Die(_WritePermError, AppData)

	Files := [ A_ScriptName, TaskCreateFile, TaskRemoveFile ]
	For Index, File in Files {
		If (!FileExist(AppData "\" File))
			FileCopy, %A_ScriptDir%\%File%, %AppData%
		If (ErrorLevel)
			Die(_CopyError, File " " _To "`n" AppData)
	}

	Run, %AppData%\%A_ScriptName% %Args%
	ExitApp
}

GetCurrentVersion() {
	; FileVersion() by SKAN https://www.autohotkey.com/boards/viewtopic.php?&t=4282
	If (Sz := DllCall("Version\GetFileVersionInfoSizeW", "WStr", Path, "Int", 0))
		If (DllCall("Version\GetFileVersionInfoW", "WStr", Path, "Int", 0, "UInt", VarSetCapacity(V, Sz), "Str", V))
			If (DllCall("Version\VerQueryValueW", "Str", V, "WStr", "\StringFileInfo\040904B0\ProductVersion", "PtrP", pInfo, "Int", 0))
				CurrentVersion := StrGet(pInfo, "UTF-16")

	If (!CurrentVersion)
		Die(_GetVersionError, Path)

	GetCurrentBuild()

	GuiControl,, VerField, %CurrentVersion% (%Repo%/%Build%)
}

GetCurrentBuild() {
	SplitPath, Path,, PathDir
	VerFile := PathDir "\thor_ver"
;MsgBox, %VerFile%
	FileReadLine, Repo, %VerFile%, 1
	If (ErrorLevel)
		Die(_GetBuildError)

	FileReadLine, Build, %VerFile%, 2
	If (!ErrorLevel)
		Build := Build
	Else Switch Repo {	; Legacy
		Case "AVX", "Win":
			Repo  := "Win"
			Build := "AVX"
			Return
		Case "Special", "SSE3":
			Repo  := "Win"
			Build := "SSE3"
			Return
		Default:
			If (InStr(Repo, "-")) {
				Split := StrSplit(Repo, "-")
				Repo  := Split[1]
				Build := Split[2]
			} Else Die(_GetBuildError)
	}
}

CheckConnection() {
	If (!Download(ConnectCheckUrl))
		Die(_NoConnectionError,, !Scheduled)	; Show only if not scheduled
}

GetNewVersion() {
	Progress(_Checking)
	Task := Browser
	NewVersion := StrReplace(GetLatestVersion(), "M")
;MsgBox, ReleaseInfo = %ReleaseInfo%`nCurrentVersion = %CurrentVersion%`nNewVersion = %NewVersion%
	IniRead, LastUpdateTo, %IniFile%, Log, LastUpdateTo, False
	If (NewVersion = CurrentVersion) {
		Progress(_NoNewVersion, True)
		Log("LastResult", _NoNewVersion)
		Return False
	}
	Return True
}

StartUpdate() {
	GuiControl,, VerField, %CurrentVersion% %_To%`n%NewVersion% (%Repo%/%Build%)
	If (Portable Or !Scheduled)
		GuiShow()

	WaitForClose()
	DownloadUpdate()
}

WaitForClose() {
	; Notify and wait if browser is running
	PathDS   := StrReplace(Path, "\", "\\")
	Wait:
	For Proc in ComObjGet("winmgmts:").ExecQuery("Select ProcessId from Win32_Process where ExecutablePath=""" PathDS """") {
		If (!Notified) {
			Progress(_NewVersionFound)
			Notify(_NewVersionFound)
			Notified := True
		}
		Process, WaitClose, % Proc.ProcessId
		Goto, Wait
	}

	; Check for newer version since notification was shown
	If (Notified And GetNewVersion())
		WaitForClose()
}

DownloadUpdate() {
	; Get setup file URL
	FileNameEnd := IsPortable ? PortableFile : InstallerFile
;FileAppend, %ReleaseInfo%, %A_Temp%\ReleaseInfo.txt
	RegExMatch(ReleaseInfo, "i)""name"":\s*""(" Browser "_" Build "_.{1,30}?" FilenameEnd ")"".+?""browser_download_url"":\s*""(.+?)""", DownloadUrl)
;MsgBox, Downloading`n%DownloadUrl2%`nto`n%DownloadUrl1%
	If (!DownloadUrl1 Or !DownloadUrl2)
		Die(_FindUrlError)

	; Download setup file
	Progress(_Downloading)
	SetupFile := DownloadUrl1
	UrlDownloadToFile, %DownloadUrl2%, %SetupFile%
	If (!FileExist(SetupFile))
		Die(_DownloadSetupError)

	VerifyChecksum()
}

VerifyChecksum() {	; Skipped
	; Get checksum file
;	RegExMatch(ReleaseInfo, "i)""name"":\s*""sha256sums\.txt"",.*?""browser_download_url"":\s*""(.+?)""", ChecksumUrl)
;	If (!ChecksumUrl1)
;		Die(_FindSumsUrlError)
;	Checksum := Download(ChecksumUrl1)

	; Get checksum for downloaded file
;	RegExMatch(Checksum, "i)(\S+?)\s+\*?\Q" SetupFile "\E", Checksum)
;	If (!Checksum1)
;		Die(_FindChecksumError)

	; Compare checksum with downloaded file
;	If (Checksum1 <> Hash(SetupFile))
;		Die(_ChecksumMatchError)

	RunUpdate()
}

RunUpdate() {
	If (IsPortable)
		ExtractPortable()
	Else {
;		If (A_IsAdmin)
			Install()
;		Else {
;			Progress(_Downloaded)
;			Gui, Add, Button, vUpdateButton gInstall w148 x86 y125 Default, %_StartUpdate%
;			GuiControl, Move, TaskSetField, y161
;			GuiShow(True)	; Wait for user action
;		}
	}
}

ExtractPortable() {
	WaitForClose()
	PreventRunningWhileUpdating()
; Extract archive of portable version
	Progress(_Extracting)
	If (!Extract(A_Temp "\" SetupFile, ExtractDir))
		Die(_ExtractionError)

;	Loop, Files, %ExtractDir%\*, D
;	{
;MsgBox, Traversing %A_LoopFilePath%
;		SetWorkingDir, %A_LoopFilePath%	; Enter the first folder of the extracted archive
		SetWorkingDir, %ExtractDir%
		Loop, Files, *, R
		{
			If (A_LoopFileName = UpdaterFile)
				Continue
			FileGetSize, CurrentFileSize, %A_ScriptDir%\%A_LoopFilePath%
;MsgBox, % A_LoopFilePath "`n" A_LoopFileSize "`n" CurrentFileSize "`n" Hash(A_LoopFilePath) "`n" Hash(A_ScriptDir "\" A_LoopFilePath)
			If (!FileExist(A_ScriptDir "\" A_LoopFileDir))
				FileCreateDir, %A_ScriptDir%\%A_LoopFileDir%
			If (!FileExist(A_ScriptDir "\" A_LoopFilePath) Or A_LoopFileSize <> CurrentFileSize Or Hash(A_LoopFilePath) <> Hash(A_ScriptDir "\" A_LoopFilePath)) {
;MsgBox, Moving %A_LoopFilePath%
				FileMove, %A_LoopFilePath%, %A_ScriptDir%\%A_LoopFilePath%, 1
				If (ErrorLevel)
					Die(_MoveToTargetError, A_LoopFilePath)
				ChangesMade := True
			}
		}
;	}
	SetWorkingDir, %A_Temp%
	FileRemoveDir, % A_ScriptDir "\Bin\" CurrentVersion, 1

	WriteReport()
}

Install() {
	GuiControl, Disable, UpdateButton
	WaitForClose()
	PreventRunningWhileUpdating()
	Progress(_Installing)
	If (Scheduled)
		Notify(_Installing, CurrentVersion " " _To " v" NewVersion, 3000)
	Folder := StrReplace(Path, BrowserExe, "")
;	SetupParams := StrReplace(SetupParams, "{}", Folder)
;MsgBox, %SetupFile% %SetupParams%
	; Run silent setup
;	RunWait, %SetupFile% %SetupParams% /S,, UseErrorLevel
;	If (!ErrorLevel)
;		WriteReport()
;	Else {
;		MsgBox, 52, %_Updater%, %_SilentUpdateError%
;		IfMsgBox No
;			Progress(_UpdateError, True)
;		Else {
			RunWait, %SetupFile% %SetupParams%,, UseErrorLevel
			If (ErrorLevel Or !FileExist(Folder NewVersion))
				Die(_UpdateError (ErrorLevel ? " " A_LastError : ""))
			Else
				WriteReport()
;		}
;	}
}

PreventRunningWhileUpdating() {
	If (A_IsAdmin Or IsPortable)
		FileMove, %Path%, %Path%.wubak, 1
}

WriteReport() {
	; Report update if completed
	Log("LastUpdate", "(" Repo "/" Build ")", True)
	Log("LastUpdateFrom", CurrentVersion)
	Log("LastUpdateTo", NewVersion)
	Log("LastResult", _IsUpdated)
	Progress(_IsUpdated, True)
	Notify(_IsUpdated, CurrentVersion " " _To " v" NewVersion, Scheduled ? 60000 : 0)

	Exit()
}

Restart() {
	Return Exit(True)
}

Exit(Restart = False) {
; Wait for close
	If (!Restart And !A_Args.Length() And WinExist("ahk_id " GuiHwnd))
		WinWaitClose, ahk_id %GuiHwnd%
	Else
		Gui, Destroy

; Clean up
;	If (RunningPortable And FileExist(PortableBrowser)) {
;		A_Args.RemoveAt(1)	; Remove "/Portable" from array
;		CheckArgs()
;MsgBox, %Args%
;		Run, %PortableBrowser% %Args%
;	}
	Log("LastRun",, True)
	If (SetupFile) {
		Sleep, 2000
		FileDelete, %SetupFile%
	}
	If (IsPortable)
		FileRemoveDir, %ExtractDir%, 1
	FileDelete, %A_ScriptFullPath%.wubak
	FileDelete, %SelfUpdateZip%
	If (FileExist(Path ".wubak")) {
		If (FileExist(Path))
			FileDelete, %Path%.wubak
		Else
			FileMove, %Path%.wubak, %Path%
	}

	If (Restart)
		Run, % A_ScriptFullPath StrReplace(Args, "/Scheduled")
	ExitApp
}

; Helper functions

Die(Error, Var = False, Show = True) {
	If (Var)
		Error := StrReplace(Error, "{}", Var)
	Error := StrReplace(Error, "{Task}", Task)
	Log("LastResult", Error)
	GuiControl, Hide, ProgField
	GuiControl, Hide, LogField
	GuiControl, Disable, TaskSetField
	GuiControl, Hide, TaskSetField
	Gui, Font, s38
	Gui, Add, Text, x264 y-2 cYellow, % Chr("0x26A0")
	Gui, Font, s9
	Msg := Error " " (ChangesMade ? _ChangesMade : _NoChangesMade) "`n`n" _GoToWebsite
	Gui, Add, Link, gTrayAction x15 y81 w290 cCCCCCC, %Msg%

	Done := True
	If (Show)
		GuiShow(True)	; Wait for user action
	Else
		Exit()
}

Download(URL) {
	Try {
		Object := ComObjCreate("Msxml2.XMLHTTP")
		Object.open("GET", URL, false)
		Object.send()
		Result := Object.responseText
;MsgBox, %Result%
		Return Result
	} Catch {
		Return False
	}
}

Extract(From, To) {
;MsgBox, %From% to %To%
	FileRemoveDir, %ExtractDir%, 1
	FileCopyDir, %From%, %To%, 1
	Error := ErrorLevel
	If (Error) {	; PowerShell fallback
;MsgBox, Trying PowerShell fallback
		FileRemoveDir, %ExtractDir%, 1
		FileCreateDir, %ExtractDir%
		SetWorkingDir, %To%
		RunWait, powershell.exe -NoProfile -Command "Expand-Archive """%From%""" . -Force" -ErrorAction Stop,, Hide
		Error := ErrorLevel
		SetWorkingDir, %A_Temp%
	}
;MsgBox, Extract(%From%, %To%) ErrorLevel = %Error%

	Return !(Error <> 0)
}

GetLatestVersion() {
	ReleaseUrl := (Task = _Updater ? "https://codeberg.org/api/v1/repos/ltguillaume/" Browser "-winupdater/releases/latest" : StrReplace(ReleaseApiUrl, "{}", Repo))
	ReleaseInfo := Download(ReleaseUrl)
	If (!ReleaseInfo) {
		If (Task = _Updater)
			Return CurrentUpdaterVersion
		Else
			Die(_DownloadJsonError)
	}
	RegExMatch(ReleaseInfo, "i)tag_name"":\s*""M?(.+?)""", Release)
	LatestVersion := Release1
	If (!LatestVersion) {
		If (Task = _Updater And InStr(ReleaseInfo, "{") <> 1)	; Codeberg non-JSON error page
			Return CurrentUpdaterVersion
		Else If (InStr(ReleaseInfo, "API rate limit exceeded")) {	; GitHub API rate limit
			If (!Scheduled)
				Die(_ApiRateLimit)
			Else {
				Log("LastResult", _ApiRateLimit)
				Exit()
			}
		} Else
			Die(_JsonVersionError)
	}

	Return LatestVersion
}

GuiClose() {
	try {
		Gui, Destroy
	} catch {}
	Exit()
}

GuiEscape:
	If (Done)	; Only when error or done
		GuiClose()
Return

GuiShow(Wait = False) {
	Focus  := WinActive("ahk_id " GuiHwnd) Or !Scheduled
	NoFocus := WinExist("ahk_id " GuiHwnd) ? "NA" : "Minimize"
	Gui, Show, % "AutoSize " (Focus ? "" : NoFocus)
	If (!Focus)
		Gui, Flash
	ControlFocus, SysLink1
	If (Wait)
		WinWaitClose, ahk_id %GuiHwnd%
}

Hash(filePath, hashType = 4) {
; https://www.autohotkey.com/board/topic/66139-ahk-l-calculating-md5sha-checksum-from-file/
	PROV_RSA_AES := 24
	CRYPT_VERIFYCONTEXT := 0xF0000000
	BUFF_SIZE := 1024 * 1024	; 1MB
	HP_HASHVAL := 0x0002
	HP_HASHSIZE := 0x0004

	HASH_ALG := hashType = 1 ? (CALG_MD2 := 32769) : HASH_ALG
	HASH_ALG := hashType = 2 ? (CALG_MD5 := 32771) : HASH_ALG
	HASH_ALG := hashType = 3 ? (CALG_SHA := 32772) : HASH_ALG
	HASH_ALG := hashType = 4 ? (CALG_SHA_256 := 32780) : HASH_ALG
	HASH_ALG := hashType = 5 ? (CALG_SHA_384 := 32781) : HASH_ALG
	HASH_ALG := hashType = 6 ? (CALG_SHA_512 := 32782) : HASH_ALG

	f := FileOpen(filePath, "r", "CP0")
	If (!IsObject(f))
		Return 0

	If (!hModule := DllCall("GetModuleHandleW", "str", "Advapi32.dll", "Ptr"))
		hModule := DllCall("LoadLibraryW", "str", "Advapi32.dll", "Ptr")

	If (!DllCall("Advapi32\CryptAcquireContextW"
			,"Ptr*", hCryptProv
			,"Uint", 0
			,"Uint", 0
			,"Uint", PROV_RSA_AES
			,"UInt", CRYPT_VERIFYCONTEXT))
		Goto, FreeHandles

	If (!DllCall("Advapi32\CryptCreateHash"
			, "Ptr",  hCryptProv
			, "Uint", HASH_ALG
			, "Uint", 0
			, "Uint", 0
			, "Ptr*", hHash))
		Goto, FreeHandles

	VarSetCapacity(read_buf, BUFF_SIZE, 0)
	hCryptHashData := DllCall("GetProcAddress", "Ptr", hModule, "AStr", "CryptHashData", "Ptr")

	While (cbCount := f.RawRead(read_buf, BUFF_SIZE)) {
		If (cbCount = 0)
			Break

		If (!DllCall(hCryptHashData
				, "Ptr",  hHash
				, "Ptr",  &read_buf
				, "Uint", cbCount
				, "Uint", 0))
			Goto, FreeHandles
	}

	If (!DllCall("Advapi32\CryptGetHashParam"
			, "Ptr",   hHash
			, "Uint",  HP_HASHSIZE
			, "Uint*", HashLen
			, "Uint*", HashLenSize := 4
			, "UInt",  0))
		Goto, FreeHandles

	VarSetCapacity(pbHash, HashLen, 0)
	If (!DllCall("Advapi32\CryptGetHashParam"
			, "Ptr",   hHash
			, "Uint",  HP_HASHVAL
			, "Ptr",   &pbHash
			, "Uint*", HashLen
			, "UInt",  0))
		Goto, FreeHandles

	SetFormat, Integer, Hex
	Loop, %HashLen%
	{
		num := NumGet(pbHash, A_Index - 1, "UChar")
		hashVal .= SubStr((num >> 4), 0) . substr((num & 0xf), 0)
	}
	SetFormat, Integer, D

FreeHandles:
	f.Close()
	DllCall("FreeLibrary", "Ptr", hModule)
	DllCall("Advapi32\CryptDestroyHash", "Ptr", hHash)
	DllCall("Advapi32\CryptReleaseContext", "Ptr", hCryptProv, "UInt", 0)
	Return hashVal
}

Log(Key, Msg = "", PrefixTime = False) {
	Msg := StrReplace(Msg, "{Task}", Task)
	If (PrefixTime) {
		FormatTime, CurrentTime
		Msg := CurrentTime " " Msg
	}
	Msg := StrReplace(Msg, "`n", " ")
	IniWrite, %Msg%, %IniFile%, Log, %Key%
}

Notify(Msg, Ver = 0, Delay = 0) {
	If (!Ver)
		Ver := NewVersion
	Menu, Tray, Tip, %Msg%
	If (Scheduled Or Delay) {
		TrayTip, %Msg%, v%Ver%,, 16
		Sleep, %Delay%
	}
}

Progress(Msg, End = False) {
	GuiControl,, LogField, % SubStr(Msg, InStr(Msg, "`n") + 1)
	If (End)
		GuiControl,, ProgField, 100
	Else If (Msg <> _NewVersionFound)
		GuiControl,, ProgField, +15
	Menu, Tray, Tip, %Msg%

	GuiControlGet, Prog,, ProgField
	Done := Prog >= 100
}

TaskCheck() {
	RunWait schtasks.exe /query /tn "%_Updater% (%A_UserName%)",, Hide
	GuiControl,, TaskSetField, % ErrorLevel = 0
	Gui, Submit, NoHide
}

TaskSet() {
	If (SettingTask) {
		Progress(_SettingTask)
		If (A_Args[1] = "/CreateTask")
			TaskSetField := 0
		Else If (A_Args[1] = "/RemoveTask")
			TaskSetField := 1
		Sleep, 1000
	}

	Script := A_ScriptDir "\" (TaskSetField = 0 ? TaskCreateFile : TaskRemoveFile)
	GuiControl,, TaskSetField, -1
	RunWait, powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File "%Script%"
	WinWaitActive, ahk_id %GuiHwnd%
	Sleep, 1000
	WinWaitActive
	TaskCheck()

	If (SettingTask) {
		SettingTask := 0
		Progress(_SettingTask _Done, True)
		GuiShow(True)	; Don't start updating, just wait for close
	}
}

Unelevate(Forced = False) {
	If (!A_IsAdmin Or IsPortable Or (Scheduled And !Forced) Or RegExMatch(DllCall("GetCommandLine", "str"), " /Restart(?!\S)"))
		Return

	If (RunUnelevated(A_ScriptFullPath, "/Restart " Args, A_ScriptDir))
		ExitApp
	Else
		Die(_IsElevated)
}

RunUnelevated(Prms*) {
	; ShellRun(Prms*) from AutoHotkey's Installer.ahk
	Try {
		ShellWindows := ComObjCreate("Shell.Application").Windows
		VarSetCapacity(_Hwnd, 4, 0)
		Desktop := ShellWindows.FindWindowSW(0, "", 8, ComObj(0x4003, &_Hwnd), 1)
		If Ptlb := ComObjQuery(Desktop
				, "{4C96BE40-915C-11CF-99D3-00AA004AE837}"	; SID_STopLevelBrowser
				, "{000214E2-0000-0000-C000-000000000046}")	; IID_IShellBrowser
		{
				If DllCall(NumGet(NumGet(Ptlb + 0) + 15 * A_PtrSize), "ptr", Ptlb, "ptr*", Psv := 0) = 0
				{
						VarSetCapacity(IID_IDispatch, 16)
						NumPut(0x46000000000000C0, NumPut(0x20400, IID_IDispatch, "int64"), "int64")
						DllCall(NumGet(NumGet(psv+0)+15*A_PtrSize), "ptr", Psv
							, "uint", 0, "ptr", &IID_IDispatch, "ptr*", Pdisp := 0)
						Shell := ComObj(9, Pdisp, 1).Application
						Shell.ShellExecute(Prms*)
						ObjRelease(Psv)
				}
				ObjRelease(Ptlb)
		}
		Return True
	} Catch e
		Return False
}