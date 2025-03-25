gotoWebpage_maker(page)
{
	webpage(*) {
		Run(page)
	}
	return webpage
}

setTray()
{
	global version, trueExit, customTrayMenu
	trayExit(*) {
		trueExit("", "")
	}
	Reloads(*) {
		Reload
	}
	tray := A_TrayMenu
	tray.delete
	tray.add("v" . version, (*) => {})
	tray.add()
	if (customTrayMenu.HasOwnProp("valid") && customTrayMenu.HasOwnProp("menu")) {
		For , Value in customTrayMenu.menu
		{
			tray.add(Value.name, Value.func)
			tray.Default := Value.name
		}
		tray.add()
	}
	tray.add("Github 页面", gotoWebpage_maker("https://github.com/Nigh/ahko"))
	tray.add("Donate 捐助", gotoWebpage_maker("https://ko-fi.com/xianii"))
	tray.add("Reload 刷新", Reloads)
	tray.add("Exit", trayExit)
	tray.ClickCount := 1
}
