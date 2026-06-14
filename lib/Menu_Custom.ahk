/************************************************************************
 * @description Robust, Modular Menu (No-Crash Dependency Checking)
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/08
 * @version 1.3.1
 ***********************************************************************/

#Requires AutoHotkey v2.0

Menu_Custom() {

    TrayMenu := A_TrayMenu
    MoreMenu := TrayMenu.HasProp("MoreMenu") ? TrayMenu.MoreMenu : ""

    TrayMenu.Rename(App.Name, "Block Active Window`t(Ctrl+Alt+B)")
    TrayMenu.Insert("More", "Select from Running", (*) => ShowRunningApps())
    TrayMenu.Insert("More", "Select from File", (*) => SelectAnyFile())
    TrayMenu.Insert("More", "Manage Blocked", (*) => ShowRulesGUI())
    TrayMenu.Insert("More", )



/* 
SelectAnyFile() {
    SetTimer(SetFileDialogIcon, 10)
    filepicked := FileSelect(3, , "Select a program to block network access", "All Files (*.*)")
    SetTimer(SetFileDialogIcon, 0)

    SetFileDialogIcon() {
        static hIcon := 0

        if (!hIcon) {
            hIcon := DllCall("LoadImage"
                , "ptr", 0
                , "str", App.Icon
                , "uint", 1 ; IMAGE_ICON
                , "int", 0
                , "int", 0
                , "uint", 0x10 ; LR_LOADFROMFILE
                , "ptr")
        }

        hwnd := WinExist("ahk_class #32770")

        if (hwnd) {
            ; WM_SETICON = 0x80
            SendMessage(0x80, 0, hIcon, , hwnd) ; ICON_SMALL
            SendMessage(0x80, 1, hIcon, , hwnd) ; ICON_BIG
            SetTimer(SetFileDialogIcon, 0)
        }
    }

    if filepicked != ""
        ToggleFirewall(filepicked)
}
 */







    ; Custom items
/*
    ; INSERT AT POSITION
    TrayMenu.Insert("3&", "Sound Control Panel", (*) => Run("control mmsys.cpl sounds"))
    TrayMenu.Insert("4&", "Volume Mixer", (*) => Run("sndvol.exe"))
    TrayMenu.Insert("5&")
 */

    ; INSERT OVER 'More'
;    TrayMenu.Insert("More", "Sound Control Panel", (*) => Run("control mmsys.cpl sounds"))
;    TrayMenu.Insert("More", "Volume Mixer", (*) => Run("sndvol.exe"))
;    TrayMenu.Insert("More")

    ; Clean up Suspend and Pause
;    if (MoreMenu != "") {
;    try MoreMenu.Delete("4&")
;    try MoreMenu.Delete("Suspend")
;    try MoreMenu.Delete("Pause")
;    }

    IsFunctionDefined(Name) {
        try return HasMethod(%Name%)
        return false
    }
}

;A_TrayMenu.Delete()

