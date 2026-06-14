#Requires AutoHotkey v2.0
SetWorkingDir(A_ScriptDir)
#SingleInstance Force

#include lib/ahk-xaml/XAML_GUI.ahk
#include lib/ahk-xaml/AXML.ahk
#include lib/ahk-xaml/XAML_Components.ahk

global SetupAppState := AXML_State({
	Path: "",
	Hotkey: "",
	HotkeyWin: "False",
	HotkeyText: "",
	ShowAtIndex: 0,
	Fullscreen: "False",
	AutoStart: "False"
})

options := Map(
	"Sidebar", false,
	"BurgerMenu", false,
	"AppIcon", false,
	"MinMaxButtons", false,
	"Resize", false,
	"Width", 420,
	"Height", 530,
	"TitleBarHeight", 40,
	"CloseAction", "ExitApp"
)

app := XAML_GUI("ahko Setup", options)
app.tabs.Visibility("Collapsed")

result := AXML.ParseFile("setup\setup.axml", app.main, SetupAppState)
cmb := app.X.Find("CmbShowAt")
items := ["Primary monitor", "Follow mouse", "Follow active window", "Monitor #1", "Monitor #2"]
for item in items {
	cmb.Add("ComboBoxItem").Content(item)
}

ui := app.Compile()
AXML.BindAll(ui, result, SetupAppState)

app.ExportBundle("ahko_bundled.dll")
ExitApp
