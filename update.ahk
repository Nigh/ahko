
#include meta.ahk

if FileExist("updater.exe")
{
	FileDelete("updater.exe")
}

outputVersion(){
	global
	if A_Args.Length > 0
	{
		for n, param in A_Args
		{
			RegExMatch(param, "--out=(\w+)", &outName)
			if(outName[1]=="version") {
				f := FileOpen(versionFilename,"w","UTF-8-RAW")
				f.Write(version)
				f.Close()
				ExitApp
			}
		}
	}
}

update_log:="
(
text your update log here
)"

lastUpdate:=IniRead("setting.ini", "update", "last", 0)
autoUpdate:=IniRead("setting.ini", "update", "autoupdate", 1)
updateMirror:=IniRead("setting.ini", "update", "mirror", "fastgit")
IniWrite(updateMirror, "setting.ini", "update", "mirror")
today:=A_MM . A_DD
if(autoUpdate) {
	if(lastUpdate!=today) {
		get_latest_version()
	} else {
		version_str:=IniRead("setting.ini", "update", "ver", "0")
		if(version_str!=version) {
			IniWrite(version, "setting.ini", "update", "ver")
			MsgBox(version . "`nUpdate log`n`n" . update_log)
		}
	}
} else {
	; MsgBox,,Update,Update Skiped`n`nCurrent version`nv%version%,2
}

; updateSite:=""
get_latest_version(){
	global
	req := ComObject("MSXML2.ServerXMLHTTP")
	if(updateMirror=="fastgit") {
		updateSite:="https://download.fastgit.org"
	} else if(updateMirror=="cnpmjs") {
		updateSite:="https://github.com.cnpmjs.org"
	} else {
		updateSite:="https://github.com"
	}
	req.open("GET", updateSite . downloadUrl . versionFilename, true)
	req.onreadystatechange := updateReady
	req.send()
}

; with MSXML2.ServerXMLHTTP method, there would be multiple callback called
updateReqDone:=0
updateReady(){
	global req, version, updateReqDone, updateSite, downloadUrl, downloadFilename
	; log("update req.readyState=" req.readyState, 1)
    if(req.readyState != 4){  ; Not done yet.
        return
	}
	if(updateReqDone){
		; log("state already changed", 1)
		Return
	}
	updateReqDone := 1
	; log("update req.status=" req.status, 1)
    if(req.status == 200){ ; OK.
        ; MsgBox % "Latest version: " req.responseText
		RegExMatch(version, "(\d+)\.(\d+)\.(\d+)", &verNow)
		RegExMatch(req.responseText, "(\d+)\.(\d+)\.(\d+)", &verNew)
		if((verNew[1]>verNow[1])
		|| (verNew[1]==verNow[1] && ((verNew[2]>verNow[2])
			|| (verNew[2]==verNow[2] && verNew[3]>verNow[3])))){
			result:=MsgBox("Found new version " . req.responseText . ", download?", "Download", 0x2024)
			if result = "Yes"
			{
				try {
					Download(updateSite . downloadUrl . downloadFilename, "./" . downloadFilename)
					MsgBox("Download finished`nProgram will restart now",, "T3")
					todayUpdated()
					FileInstall("updater.exe", "updater.exe", 1)
					Run("updater.exe")
					ExitApp
				} catch as e {
					TrayTip "An exception was thrown!`nSpecifically: " . e.Message, "upgrade failed", 0x3
					; MsgBox("An exception was thrown!`nSpecifically: " . e.Message,"Upgrade failed",16)
				}
			}
		} else {
			todayUpdated()
		}
	} else {
		TrayTip "Status=" req.status, "update failed", 0x3
        ; MsgBox("Status=" req.status,"Update failed",16)
	}
}

todayUpdated(){
	IniWrite(A_MM . A_DD, "setting.ini", "update", "last")
}
