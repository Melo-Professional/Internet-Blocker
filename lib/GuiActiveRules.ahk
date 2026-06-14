#Requires AutoHotkey v2.0

ShowRulesGUI() {
    if !A_IsAdmin
        CheckAdmin("ShowRulesGUI")
    MyGuiTitle := App.Name " - Currently Blocking"
    MyGuiOptions := "+LastFound -MinimizeBox"
    MyGui := Gui(MyGuiOptions, MyGuiTitle)
    MyGui.SetFont("s" Settings.GuiFontSizeMedium, Settings.GuiFontName)
    MyGui.MarginX := 20
    MyGui.MarginY := 20

    MyGui.Add("Text", "y+20 ", "Currently blocked programs:")

    LB := MyGui.AddListBox("r12 w350 +Multi Sort")
    LB.Add(["Reading"])
    LB.Enabled := false
    LB.OnEvent("Change", (ctrl, *) => Btn.Enabled := (ctrl.Value.Length > 0))

    totalwidth := (MyGui.MarginX * 2) + 350
    BtX := (totalwidth //2) - (150 //2)

    Btn := MyGui.AddButton("x" BtX " Default w150 h35", "Unblock Selected")
    Btn.Enabled := false

    ; Setup events
    Btn.OnEvent("Click", (*) => RemoveSelectedRules(LB, MyGui))
    MyGui.OnEvent("Close", CleanDestroy)
    MyGui.OnEvent("Escape", CleanDestroy)

    ApplyThemeToGui(MyGui)
    WatchedGUIs.Push(MyGui)

    MyGui.Show()

    CleanDestroy(*) {
            RemoveGuiFromArray(MyGui)
            MyGui.Destroy()
        }

    SetTimer(() => PerformScan(LB), -10)

    PerformScan(LB) {
        LB.Delete()
        LB.Add(["Reading..."])

        PSCmd := 'powershell -NoProfile -Command "Get-NetFirewallRule -DisplayName AHK_Block_* | Group-Object DisplayName | Select-Object Name | ConvertTo-Csv -NoTypeInformation"'

        try {
            TempFile := A_Temp "\ahk_rules.csv"
            RunWait(A_ComSpec ' /c ' PSCmd ' > "' TempFile '"', , "Hide")
            if FileExist(TempFile) {
                Out := FileRead(TempFile)
                FileDelete(TempFile)
                LB.Delete()
                
                Loop Parse, Out, "`n", "`r" {
                    if (A_Index > 1 && Trim(A_LoopField) != "") {
                        CleanName := StrReplace(A_LoopField, '"', '')
                        CleanName := StrReplace(CleanName, "AHK_Block_", "")
                        LB.Add([CleanName])
                    }
                }
            }
        }

        LB.Enabled := true
    }

    RemoveSelectedRules(LB, GuiObj) {
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
            OSDInfo.Destroy()
            OSDInfo.Show("Processing: " FileName,,0)
            RulesRemove(FileName)
        }
        OSDInfo.Destroy()
        PerformScan(LB)
    }
}