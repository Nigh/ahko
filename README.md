# ahko

> tested with Autohotkey 2.0-beta.3 on Windows 10

ahko is a quick launcher for windows.

## Screenshots

### Gridview :

![](./assets/screenshot_gridview.png)

### Listview(**Deprecated**) :

![](./assets/screenshot_listview.png)

## Setup

![](./assets/setup.png)

right click the `ahko` tray icon, and then click the `Setup`

![](./assets/setupui.png)

## Usage

ahko scans two levels of directories in the watch folder. The number of objects per directory level is limited to 16. This means that a maximum of 16x16 = 256 objects can be listed.  
This is because too many objects would NOT make the launcher "quick" enough.

### icon

Icons can be obtained automatically. And you can set it by your own.  
Folder icons can be set by placing a png image with the name `_icon.png` in the folder.  
Item's icon can be set by placing a png image with the same name as the item. For example, put `abc.lnk` and `abc.png` in the same folder, the icon of `abc.lnk` would be set to `abc.png`.

## Template

Created with ahk autoupdate [template](https://github.com/Nigh/ahk-autoupdate-template/generate)

