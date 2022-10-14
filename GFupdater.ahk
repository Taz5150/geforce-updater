; NVidia Driver Checker by Juhani Naskali
;
; Requires JSON.ahk class from https://github.com/cocobelgica/AutoHotkey-JSON and 7-zip

#Include %A_ScriptDir%\lib\json.ahk

; Paths
7zip := "C:\Program Files\7-Zip\7z.exe"
pathNvidia := "C:\ProgramData\NVIDIA Corporation\Drs"
pathBackup := A_AppDataCommon  . "\NCP Backup"
pathTemp := A_Temp . "\GFupdater"

; Check if temp/backup directory exists. Else, create it
;if (FileExist(pathTemp)) {
;	FileRemoveDir, %pathTemp%, 1
;}
If !FileExist(pathBackup)
{
 FileCreateDir, %pathBackup%
} 

; Check if script is 32-bit but OS is 64-bit
if (A_PtrSize = 4 and A_Is64bitOS)
{
    SetRegView 64
}

; Get installed driver version
RegRead, installedVersion, HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{B2FE1952-0186-46C3-BAEC-A80AA35AC5B8}_Display.Driver, DisplayVersion

; Retreive and parse json with latest driver information 
url :="https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php?func=DriverManualLookup&psid=101&pfid=815&osID=57&languageCode=1033&beta=null&isWHQL=0&dltype=-1&dch=1&upCRD=null&qnf=0&sort1=0&numberOfResults=10"
oHttp := ComObjCreate("WinHttp.Winhttprequest.5.1")
oHttp.open("GET", url)
oHttp.send()
parsed := JSON.Load(oHttp.responseText)

; Check if update, install after confirmation
if(installedVersion = parsed.IDS[1].downloadInfo.Version)
{
	; Message box commented for scheduled running (do nothing if no update needed)
    MsgBox,, GeForce Updater, % "GeForce Driver " . parsed.IDS[1].downloadInfo.Version . " installed. No need to update." 
	Exit, 10
}
else
{
    MsgBox, 4,GeForce Updater, % "Latest GeForce Driver is " . parsed.IDS[1].downloadInfo.Version . "`nInstalled version is " . installedVersion . "`n`nDownload " . parsed.IDS[1].downloadInfo.DownloadURLFileSize . " and install?"
    IfMsgBox Yes
	{
		Url= % parsed.IDS[1].downloadInfo.DownloadURL
		FileCreateDir, %pathTemp%
		
		DownloadFile(Url, pathTemp . "\nvidia-install.exe")
		
		; Backup Control Panel settings
		FileCopy, %pathNvidia%\nvdrsdb*.bin, %pathBackup%
		
		; Unzip and install only needed files
		RunWait, %7zip% x %pathTemp%\nvidia-install.exe -o%pathTemp%
		RunWait %pathTemp%\setup.exe
		
		; Remove temporarily unzipped files and downloads without prompt
		FileCopy, %pathBackup%\nvdrsdb*.bin, %pathNvidia%
		FileRemoveDir, %pathTemp%, 1
	    FileDelete, nvidia-install.exe
    }
}



; -----------------------------------------------------------------------------------------------------
;  DownloadFile function with progress bar from https://autohotkey.com/boards/viewtopic.php?p=10020
; -----------------------------------------------------------------------------------------------------

DownloadFile(URL, SaveFileAs = "", Overwrite := True, UseProgressBar := True) {
	if !SaveFileAs {
		SplitPath, URL, SaveFileAs
		StringReplace, SaveFileAs, SaveFileAs, `%20, %A_Space%, All
	}

    ;Check if the file already exists and if we must not overwrite it
      If (!Overwrite && FileExist(SaveFileAs))
          Return
    ;Check if the user wants a progressbar
      If (UseProgressBar) {
          ;Initialize the WinHttpRequest Object
            WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
          ;Download the headers
            WebRequest.Open("HEAD", URL)
            WebRequest.Send()
          ;Store the header which holds the file size in a variable:
            FinalSize := WebRequest.GetResponseHeader("Content-Length")
          ;Create the progressbar and the timer
            Progress, H80, , Downloading..., %URL%
            File := FileOpen(SaveFileAs, "rw")
            SetTimer, __UpdateProgressBar, 1000
      }
    ;Download the file
      UrlDownloadToFile, %URL%, %SaveFileAs%
    ;Remove the timer and the progressbar because the download has finished
      If (UseProgressBar) {
          Progress, Off
          SetTimer, __UpdateProgressBar, Off
          File.Close()
      }
    Return
    
    ;The label that updates the progressbar
      __UpdateProgressBar:
          ;Get the current filesize and tick
            CurrentSize := File.Length ;FileGetSize wouldn't return reliable results
            CurrentSizeTick := A_TickCount
          ;Calculate the downloadspeed
            Speed := Round((CurrentSize/1024-LastSize/1024)/((CurrentSizeTick-LastSizeTick)/1000), 1)
          ;Calculate time remain
            TimeRemain := Round( (FinalSize-CurrentSize) / (Speed*1024) )

            time = 19990101
            time += %TimeRemain%, seconds
            FormatTime, mmss, %time%, mm:ss
            TimeRemain := LTrim(TimeRemain//3600 ":" mmss, "0:")
          ;Save the current filesize and tick for the next time
            LastSizeTick := CurrentSizeTick
            LastSize := CurrentSize
          ;Calculate percent done
            PercentDone := Round(CurrentSize/FinalSize*100)
          ;Update the ProgressBar
            Progress, %PercentDone%, %PercentDone%`% Done [Time: %TimeRemain%], Downloading...  (%Speed% Kb/s), Downloading %SaveFileAs% (%PercentDone%`%)
      Return
}