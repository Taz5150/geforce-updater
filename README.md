# GeForce Check & Updater Tool
Small AHK script that checks latest GeForce gameready driver, backs-up nVidia Control Panel 3D settings and automatically clean installs drivers.

This version checks for GeForce RTX 5070 ti Windows 11 drivers.

NOTES:

query inputs for https://www.nvidia.com/Download/processFind.aspx consists of:

	- psid: product series ID, see: https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=2
	- pfid: product ID, see https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=3
	- osid: operating system ID, see https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=4
	- lid: language ID (US English == 1), see https://www.nvidia.com/Download/API/lookupValueSearch.aspx?TypeID=5"

The core of this tool is based on Juhani Naskali's development: https://gist.github.com/jnaskali/080299ccaa94da60c565ea068d467d15

