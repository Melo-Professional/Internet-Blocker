#Requires AutoHotkey v2.0

ShowRunningApps() {
    MyGuiTitle := App.Name " - Running Processes"
    MyGuiOptions := "+LastFound -MinimizeBox"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    MyGui.MarginX := 15
    MyGui.MarginY := 20
    ProcessMap := Map()

    MyGui.Add("Text", "y+20 ", "Select a process to block/ unblock network access:")

    LB := MyGui.AddListBox("r30 w400 +Multi Sort")
    LB.Add(["Reading"])
    LB.Enabled := false
    LB.OnEvent("Change", (ctrl, *) => Btn.Enabled := (ctrl.Value.Length > 0))
    
    totalwidth := (MyGui.MarginX * 2) + 400
    BtX := (totalwidth // 2) - (150 // 2)

    Btn := MyGui.AddButton("Default x" BtX " w150 h35", "Block / Unblock")
    Btn.Enabled := false
    
    ; Setup events
    Btn.OnEvent("Click", (*) => ProcessSelection(ProcessMap, LB, MyGui))
    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)

    ApplyThemeToGui(MyGui)
    WatchedGUIs.Push(MyGui)

    MyGui.Show()

    CleanDestroy(*) {
            RemoveGuiFromArray(MyGui)
            MyGui.Destroy()
        }

    SetTimer(() => PerformScan(LB, ProcessMap), -10)

    PerformScan(LB, ProcessMap) {
        LB.Delete()
        LB.Add(["Reading..."])
        ProcessMap.Clear()
        BlockedMap := Map()

        PSCmd := 'powershell -NoProfile -Command "Get-NetFirewallRule -DisplayName AHK_Block_* -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DisplayName"'
        
        try {
            TempFile := A_Temp "\ahk_chk.txt"
            ; This still takes a moment, but since the GUI is already "active", it won't feel blocked.
            RunWait(A_ComSpec ' /c ' PSCmd ' > "' TempFile '"', , "Hide")
            
            if FileExist(TempFile) {
                RulesRaw := FileRead(TempFile)
                FileDelete(TempFile)
                Loop Parse, RulesRaw, "`n", "`r" {
                    if Trim(A_LoopField) != ""
                        BlockedMap[StrReplace(A_LoopField, "AHK_Block_", "")] := true
                }
            }
        }

        try {
            WMI := ComObjGet("winmgmts:")
            Query := WMI.ExecQuery("Select * from Win32_Process")
            LB.Delete()
            
            for proc in Query {
                if proc.ExecutablePath {
                    SplitPath(proc.ExecutablePath, &Name)
                    if !ProcessMap.Has(Name) {
                        ProcessMap[Name] := proc.ExecutablePath
                        DisplayName := (BlockedMap.Has(Name)) ? "* [BLOCKED] " Name : Name
                        LB.Add([DisplayName])
                    }
                }
                ; Briefly yield control back to the OS every 20 processes 
                ; to keep the GUI smooth if the list is huge.
                if (Mod(A_Index, 20) == 0)
                    Sleep(-1)
            }
        }

        LB.Enabled := true
    }

    ProcessSelection(ProcessMap, LB, GuiObj) {
        if !LB.Value || LB.Value.Length = 0 {
            return
        }

        for _, ctrlObj in guiObj {
            if (ctrlObj.Type == "ListBox") || (ctrlObj.Type == "Button")
                ctrlObj.Enabled := false
        }

        SelectedNames := []
        for index in LB.Value {
            Items := ControlGetItems(LB.Hwnd)
            SelectedNames.Push(Items[index])
        }

        for FileName in SelectedNames {
            CleanName := RegExReplace(FileName, "^\* \[BLOCKED\] ", "")
            OSDInfo.Destroy()
            OSDInfo.Show("Processing: " CleanName,,0)
            ToggleFirewall(ProcessMap[CleanName])
        }

        OSDInfo.Destroy()
        PerformScan(LB, ProcessMap)
    }

}