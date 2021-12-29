; # requirements:
; # ahk2exe.exe in PATH [1.1.34.00_Beta_8]
; # AutoHotkey64.exe in PATH [v2.0-beta.3]
; # mpress in ahk2exe path

#SingleInstance Force
SetWorkingDir(A_ScriptDir)

#include meta.ahk

if FileExist(binaryFilename)
{
	FileDelete(binaryFilename)
}

if FileExist(versionFilename)
{
	FileDelete(versionFilename)
}

if InStr(FileExist("dist"), "D")
{
	try
	{
		DirDelete("dist", 1)
	}
	catch as e
	{
		MsgBox("removing dist`nERROR CODE=" . e.Message)
		ExitApp
	}
}

DirCreate("dist")

try
{
	RunWait("ahk2exe.exe /in updater.ahk /out updater.exe /base `"" A_AhkPath "`" /compress 1")
}
catch as e
{
	MsgBox("updater.ahk`nERROR CODE=" . e.Message)
	ExitApp
}

try
{
	RunWait("ahk2exe.exe /in " ahkFilename " /out " binaryFilename " /base `"" A_AhkPath "`" /icon icon.ico /compress 1")
}
catch as e
{
	MsgBox(ahkFilename . "`nERROR CODE=" . e.Message)
	ExitApp
}

try
{
	RunWait("AutoHotkey64.exe .\" . ahkFilename . " --out=version")
}
catch as e
{
	MsgBox("get version`nERROR CODE=" . e.Message)
	ExitApp
}

try
{
	RunWait("powershell -command `"Compress-Archive -Path .\" binaryFilename " -DestinationPath " downloadFilename '"',, "Hide")
}
catch as e
{
	MsgBox("compress`nERROR CODE=" . e.Message)
	ExitApp
}
FileDelete(binaryFilename)
FileDelete("updater.exe")
FileMove(downloadFilename, "dist\" downloadFilename, 1)
FileMove(versionFilename, "dist\" versionFilename, 1)
MsgBox("Build Finished")
