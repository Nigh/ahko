
ahko_listview := Menu()
ahko_listview_init(ahko)
{
	global ahko_listview
	ahko_listview_sub:=[]
	For , layer0 in ahko
	{
		if(InStr(layer0.attrib, "D")){
			ahko_listview_sub.Push(Menu())
			For , layer1 in layer0.sub
			{
				ahko_listview_sub[-1].add(layer1.name, listview_run_maker(layer1.path))
				iconPath:=layer1.icon Or fileGethIcon(layer1.path)
				if(iconPath){
					Try{
						ahko_listview_sub[-1].setIcon(layer1.name, iconPath)
					}Catch as e{
						; MsgBox("Err:" e.Message "`norigin:" layer1.path "`nicon:" iconPath)
					}
				}
			}
			local_name:=layer0.name " [" layer0.sub.length "]"
			ahko_listview.add(local_name, ahko_listview_sub[-1])

			iconPath:=layer0.icon Or fileGethIcon(layer0.path)
			if(iconPath) {
				ahko_listview.setIcon(local_name, iconPath)
			}
		} else {
			ahko_listview_sub.Push("")
			ahko_listview.add(layer0.name, listview_run_maker(layer0.path))
		}
	}
}

listview_run_maker(file) {
	runner(*) {
		SplitPath(file,,&atDir)
		Run(file, atDir)
	}
	return runner
}
