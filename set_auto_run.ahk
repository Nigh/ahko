
target:=""
name:=""
remove:=false
args:=" "
for n, param in A_Args
{
	args.=param " "
	if(RegExMatch(param, "--target=(\S+)", &match)){
		if(FileExist(match[1])){
			target:='"' match[1] '"'
		}
	}
	if(RegExMatch(param, "--name=(\S+)", &match)){
		name:=match[1]
	}
	if(RegExMatch(param, "--remove")){
		remove:=true
	}
}

if(name=="") {
	ExitApp -1
}
if not remove {
	if(target=="") {
		ExitApp -2
	}
}

UAC(args)

if remove {
	RegDelete("HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run",name)
} else {
	RegWrite(target,"REG_SZ","HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Run",name)
}
ExitApp 0

UAC(arg)
{
	full_command_line := DllCall("GetCommandLine", "str")
	if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)")) {
		try {
			Run '*RunAs "' A_ScriptFullPath '" /restart' arg
		}
		ExitApp
	}
}
