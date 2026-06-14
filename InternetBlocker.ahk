;@region Setup
;@region Description
/************************************************************************
 * @description To block / unblock network connections from programs using builtin Windows firewall
 * @author Melo (melo@meloprofessional.com)
 * @date 2026/06/14
 * @releasedate 2026/04/24
 * @version 1.38.0.0
 ***********************************************************************/

AppName := "Internet Blocker"
;@Ahk2Exe-Let U_LineAppName = %A_PriorLine%
AppVersion := "1.38.0.0"
;@Ahk2Exe-Let U_LineVersion = %A_PriorLine%
AppDescription := "To block / unblock network connections from programs using builtin Windows firewall"
;@endregion

;@region Directives
#Requires AutoHotkey v2.0
#SingleInstance Force
Persistent()
SetWorkingDir(A_ScriptDir)
A_AllowMainWindow := 0
A_IconHidden := true
; --- Optimization Settings ---
;ProcessSetPriority("High")
;ListLines(False)
;KeyHistory(0)
;A_MaxHotkeysPerInterval := 5000
;A_HotkeyInterval := 1000
;@endregion

;@region Includes
#Include *i <_CompilerDirectives>
#Include *i <_Config&Vars>
#Include *i <_MsgBoxCustom>
#Include *i <_SaveSettings>
#Include *i <_Theme>
#Include *i <_OSDCustom>
;#Include *i <_Color_Picker_Dialog>
#Include *i <_SplashScreen>
#Include *i <_About>
;#Include *i <_Help>
#Include *i <_Menu>

;#Include <Vars_Custom>
#Include <Menu_Custom>
#Include <Help>
#Include <GuiActiveRules>
#Include <GuiRunningProcesses>
;@endregion


;@region Startup
; SPLASHSCREEN
if IsSet(SplashScreen){
    SplashScreen("Icon")
}
; TRAY ICON + MENU
StartMenu()
Menu_Custom()

OSDSettings.FontSize := 10
OSDSettings.FontName := "Segoe UI"

OSDInfo := OSDCustom()
OSDInfo.Position := "x0.5 y0.85"
OSDInfo.TimeOut := 1800

OSDDone := OSDCustom()
OSDDone.Position := "x0.5 y0.9"
OSDDone.TimeOut := 3000

OSDError := OSDCustom()
OSDError.Position := "x0.5 y0.5"
OSDError.TimeOut := 7000
OSDError.Opacity := 255

; CHECK RELOAD ARGUMENTS
if (A_Args.Length >= 1) {
    targetFuncName := A_Args[1]

    try {
        fn := %targetFuncName%
        
        if (A_Args.Length >= 2) {
            fn(A_Args[2])
        } else {
            fn()
        }
    } catch as errmsg {
        MsgBoxCustom(,,,errmsg)
    }
}
;@endregion
;@endregion


;@region Helpers Functions

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

CheckAdmin(caller := "", parameter := "") {
    try {
        args := ' "' caller '"'
        if (parameter != "")
            args .= ' "' parameter '"'
        
        Run('*RunAs "' A_AhkPath '" "' A_ScriptFullPath '"' args)
        ExitApp()
    } catch {
        if MsgBoxCustom("Admin rights required!",App.Name, "RetryCancel") = "Retry" {
            CheckAdmin(caller, parameter)
        } else {
            Reload()
        }
    }
}
;@endregion

;@region CoreLogic


ToggleActiveWindow() {
    try {
        AppPath := ProcessGetPath(WinGetPID("A"))
        SplitPath(AppPath, &FileName)
        OSDInfo.Show("Processing: " FileName,,0)
        ToggleFirewall(AppPath)
        OSDInfo.Destroy()
    } catch as geterror {
        OSDError.Show("Error: Path Access Denied")
        MsgBoxCustom(,,,geterror )
    }
}

RulesRemove(FileName) {
    RuleName := "AHK_Block_" . FileName
    RunWait('powershell -NoProfile -Command "Remove-NetFirewallRule -DisplayName ' RuleName '"', , "Hide")
    OSDDone.Show("RESTORED: " FileName)
}

RulesAdd(AppPath) {
    SplitPath(AppPath, &FileName)
    RuleName := "AHK_Block_" . FileName
    RunWait('powershell -NoProfile -Command "New-NetFirewallRule -DisplayName ' RuleName ' -Direction Outbound -Program \"' AppPath '\" -Action Block"', , "Hide")
    RunWait('powershell -NoProfile -Command "New-NetFirewallRule -DisplayName ' RuleName ' -Direction Inbound -Program \"' AppPath '\" -Action Block"', , "Hide")
    OSDDone.Show("BLOCKED: " FileName)
}

ToggleFirewall(AppPath) {
    if !A_IsAdmin
        CheckAdmin("ToggleFirewall",AppPath)

    SplitPath(AppPath, &FileName)
    RuleName := "AHK_Block_" . FileName

    if FirewallRuleExists(RuleName) {
        RulesRemove(FileName)
    } else {
        RulesAdd(AppPath)
    }
}

FirewallRuleExists(RuleName) {
    tempFile := A_Temp "\fw_check.txt"
    
    if FileExist(tempFile)
        FileDelete(tempFile)

    psCommand := "powershell -NoProfile -WindowStyle Hidden -Command `"if (@(Get-NetFirewallRule -DisplayName '" RuleName "' -ErrorAction SilentlyContinue).Count -gt 0) { 'True' | Out-File '" tempFile "' } else { 'False' | Out-File '" tempFile "' }`""

    RunWait(psCommand, , "Hide")

    if FileExist(tempFile) {
        result := Trim(FileRead(tempFile))
        FileDelete(tempFile)
        return (InStr(result, "True") > 0)
    }
    
    return false
}
;@endregion

;@region Hotkeys
^!b::ToggleActiveWindow()
;@endregion
