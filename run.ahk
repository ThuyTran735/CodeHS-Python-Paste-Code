#Requires AutoHotkey v2
#SingleInstance Force
#Warn

; Create the GUI
MyGui := Gui()
MyGui.Title := "AutoTyper v2"
MyGui.Opt("+AlwaysOnTop") ; Make the GUI always on top
MyGui.Add("Text",, "Start Delay (ms):")
MyGui.Add("Edit", "vStartDelay w300", "2000")  ; Default start delay
MyGui.Add("Text",, "Typing Offset (ms):")
MyGui.Add("Edit", "vTypingOffset w300", "100") ; Default typing offset
MyGui.Add("Text",, "Typing Speed (ms):")
MyGui.Add("Edit", "vTypingSpeed w300", "50")   ; Default typing speed
MyGui.Add("Text",, "Text to Type:")
MyGui.Add("Edit", "vInputText r5 w300", "") ; InputText will not be saved
MyGui.Add("Button", "Default w80", "Start Typing").OnEvent("Click", StartTyping)
MyGui.Add("Button", "w80", "Save Settings").OnEvent("Click", SaveSettings)
MyGui.Show()

LoadSettings()

StartTyping(*) {
    global MyGui
    Values := MyGui.Submit(False)
    StartDelay := Values.StartDelay
    TypingOffset := Values.TypingOffset
    TypingSpeed := Values.TypingSpeed
    InputText := Values.InputText

    Sleep StartDelay

    Lines := StrSplit(InputText, "`n", "`r")
    IndentStack := [0]  ; Stack for keeping track of indentation levels
    LastIndent := 0     ; Track the last indentation level

    for Line in Lines {
        
        CleanLine := Trim(Line, " `t")  ; Remove leading/trailing spaces
        CurrentIndent := StrLen(Line) - StrLen(CleanLine)  ; Count leading spaces

        ; Handle indentation correctly
        if (CurrentIndent < LastIndent) {
            IndentDiff := (LastIndent - CurrentIndent) // 4  ; Assuming 4 spaces per indent
            Loop IndentDiff {
                Send "{Backspace 1}"
                Sleep 50
            }
        }

        ; Type the cleaned line
        Loop Parse, CleanLine {
            Send "{Text}" A_LoopField
            Sleep TypingSpeed + Random(1, TypingOffset)
        }
        
        Send "{Enter}"
        LastIndent := CurrentIndent  ; Update the last indent level
    }
    
    MsgBox("Typing complete!")
}

; Save settings to settings.ini
SaveSettings(*) {
    global MyGui
    Values := MyGui.Submit(False)
    IniWrite Values.StartDelay, "settings.ini", "Settings", "StartDelay"
    IniWrite Values.TypingOffset, "settings.ini", "Settings", "TypingOffset"
    IniWrite Values.TypingSpeed, "settings.ini", "Settings", "TypingSpeed"
    MsgBox("Settings saved!", "AutoTyper", "0x40000")
}

; Load settings from settings.ini
LoadSettings() {
    global MyGui
    StartDelay := IniRead("settings.ini", "Settings", "StartDelay", "2000")
    TypingOffset := IniRead("settings.ini", "Settings", "TypingOffset", "100")
    TypingSpeed := IniRead("settings.ini", "Settings", "TypingSpeed", "50")
    MyGui["StartDelay"].Text := StartDelay
    MyGui["TypingOffset"].Text := TypingOffset
    MyGui["TypingSpeed"].Text := TypingSpeed
}