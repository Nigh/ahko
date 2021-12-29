

setTray()
{
	global version, trueExit
	donate(ItemName, ItemPos, MyMenu){
		Run("https://ko-fi.com/xianii")
	}
	pages(ItemName, ItemPos, MyMenu){
		Run("https://github.com/Nigh/ahk-autoupdate-template")
	}
	donothing(ItemName, ItemPos, MyMenu){
	}
	trayExit(ItemName, ItemPos, MyMenu){
		trueExit("","")
	}
	tray := A_TrayMenu
	tray.delete
	tray.add("v" . version, donothing)
	tray.add()
	tray.add("Github 页面", pages)
	tray.add("Donate 捐助", donate)
	tray.add("Exit", trayExit)
	tray.ClickCount := 1
}
