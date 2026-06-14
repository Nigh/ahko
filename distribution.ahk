#SingleInstance Force
SetWorkingDir(A_ScriptDir)

#include meta.ahk

isCI := (EnvGet("CI") = "true")

Fail(msg) {
	global isCI
	if isCI
		FileAppend("ERROR: " msg "`n", "*")
	else
		MsgBox(msg)
	ExitApp(1)
}

try
{
	props := FileOpen("compile_prop.ahk", "w")
	props.WriteLine(";@Ahk2Exe-SetName " appName)
	props.WriteLine(";@Ahk2Exe-SetVersion " version)
	props.WriteLine(";@Ahk2Exe-SetMainIcon icon.ico")
	props.WriteLine(";@Ahk2Exe-SetCompanyName HelloWorks")
	props.WriteLine(";@Ahk2Exe-SetDescription ahko")
	props.WriteLine(";@Ahk2Exe-ExeName " appName)
	props.Close()
}
catch as e
{
	Fail("Writting compile props`nERROR CODE=" . e.Message)
}

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
		Fail("removing dist`nERROR CODE=" . e.Message)
	}
}

DirCreate("dist")

try {
	pid := 0
	exitCode := RunWait("./ahk-compile-toolset/tcc/tcc.exe ./updater.c -luser32", , , &pid)
	if (exitCode != 0)
		Fail("updater compile`nEXIT CODE=" . exitCode)
} catch as e {
	Fail("updater compile`nERROR CODE=" . e.Message)
}

try
{
	pid := 0
	exitCode := RunWait("./ahk-compile-toolset/ahk2exe.exe /in " ahkFilename " /out " binaryFilename " /base `"" A_AhkPath "`" /compress 1", , , &pid)
	if (exitCode != 0)
		Fail(ahkFilename . "`nEXIT CODE=" . exitCode)
}
catch as e
{
	Fail(ahkFilename . "`nERROR CODE=" . e.Message)
}

SplitPath(binaryFilename, , , , &nameNoExt)
bundleDllName := nameNoExt "_bundled.dll"

try
{
	pid := 0
	exitCode := RunWait("./ahk-compile-toolset/AutoHotkey64.exe gen_setup_dll.ahk", , , &pid)
	if (exitCode != 0)
		Fail("setup DLL gen`nEXIT CODE=" . exitCode)
}
catch as e
{
	Fail("setup DLL gen`nERROR CODE=" . e.Message)
}

try
{
	pid := 0
	exitCode := RunWait("./ahk-compile-toolset/AutoHotkey64.exe .\" . ahkFilename . " --out=version", , , &pid)
	if (exitCode != 0)
		Fail("get version`nEXIT CODE=" . exitCode)
}
catch as e
{
	Fail("get version`nERROR CODE=" . e.Message)
}

try
{
	pid := 0
	exitCode := RunWait("powershell -command `"Compress-Archive -Path .\" binaryFilename ",.\" bundleDllName " -DestinationPath " downloadFilename '"', , "Hide", &pid)
	if (exitCode != 0)
		Fail("compress`nEXIT CODE=" . exitCode)
}
catch as e
{
	Fail("compress`nERROR CODE=" . e.Message)
}
FileDelete(binaryFilename)
if FileExist(bundleDllName)
	FileDelete(bundleDllName)
FileDelete("updater.exe")
if !FileExist(downloadFilename)
	Fail(downloadFilename . " not found after compression")
FileMove(downloadFilename, "dist\" downloadFilename, 1)
if !FileExist(versionFilename)
	Fail(versionFilename . " not found")
FileMove(versionFilename, "dist\" versionFilename, 1)
