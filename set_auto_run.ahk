
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
	RunWait('schtasks /delete /tn "' name '" /f', , "Hide")
} else {
	RunWait('schtasks /create /tn "' name '" /tr ' target ' /sc onlogon /rl highest /f', , "Hide")
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
