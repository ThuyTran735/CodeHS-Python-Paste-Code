#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn

SetWorkingDir(A_ScriptDir)

AppName := "CodeHS Python AutoTyper"
SettingsPath := A_ScriptDir "\settings.ini"
StopRequested := false
IsTyping := false
TargetWindow := 0

MyGui := Gui(, AppName)
MyGui.MarginX := 14
MyGui.MarginY := 12
MyGui.SetFont("s9", "Segoe UI")

MyGui.Add("Text", "xm w680", "Paste your Python code below. Leading indentation is measured, but is not typed because CodeHS adds it automatically.")

MyGui.Add("Text", "xm", "Start delay (ms, 0-60000):")
StartDelayControl := MyGui.Add("Edit", "vStartDelay Number w160", "2000")

MyGui.Add("Text", "xm", "Typing speed (ms per character, 0-2000):")
TypingSpeedControl := MyGui.Add("Edit", "vTypingSpeed Number w160", "50")

MyGui.Add("Text", "xm", "Random extra delay (ms, 0-2000):")
TypingJitterControl := MyGui.Add("Edit", "vTypingJitter Number w160", "50")

MyGui.Add("Text", "xm", "Spaces per indentation level (1-8):")
IndentSizeControl := MyGui.Add("Edit", "vIndentSize Number w160", "4")

AlwaysOnTopControl := MyGui.Add("CheckBox", "vAlwaysOnTop xm", "Keep this window always on top")

MyGui.Add("Text", "xm", "Code to type:")
MyGui.SetFont("s10", "Consolas")
InputControl := MyGui.Add("Edit", "vInputText xm r18 w680 WantTab -Wrap HScroll")
MyGui.SetFont("s9", "Segoe UI")

StartButton := MyGui.Add("Button", "xm Default w120", "Start Typing")
SaveButton := MyGui.Add("Button", "x+10 w110", "Save Settings")
StatusText := MyGui.Add("Text", "xm w680", "Ready. F1 stops an active typing run.")

StartButton.OnEvent("Click", StartTyping)
SaveButton.OnEvent("Click", SaveSettings)
AlwaysOnTopControl.OnEvent("Click", ApplyAlwaysOnTop)
MyGui.OnEvent("Close", CloseApp)

LoadSettings()
ApplyAlwaysOnTop()
MyGui.Show()
return

#HotIf IsTypingNow()
F1::RequestStop()
#HotIf

StartTyping(*) {
    global MyGui, AppName, StartButton, StatusText
    global StopRequested, IsTyping, TargetWindow

    if IsTyping
        return

    Settings := GetValidatedSettings()
    if !IsObject(Settings)
        return

    if (Trim(Settings.InputText, " `t`r`n") = "") {
        MsgBox("Enter some Python code before starting.", AppName, "Icon!")
        return
    }

    StopRequested := false
    IsTyping := true
    TargetWindow := 0
    StartButton.Enabled := false
    StatusText.Text := "Waiting for the CodeHS editor..."

    ; Hiding the GUI activates the window beneath it. The configured delay gives
    ; the user time to click the CodeHS editor if a different window is active.
    MyGui.Hide()

    if !WaitForStartDelay(Settings.StartDelay) {
        FinishTyping("stopped")
        return
    }

    try TargetWindow := WinGetID("A")
    catch
        TargetWindow := 0

    if (!TargetWindow || TargetWindow = MyGui.Hwnd) {
        FinishTyping("no_target")
        return
    }

    Result := ""
    ErrorText := ""

    try {
        Result := TypeCode(Settings.InputText, Settings)
    } catch as Err {
        Result := "error"
        ErrorText := Err.Message
    }

    FinishTyping(Result, ErrorText)
}

TypeCode(InputText, Settings) {
    NormalizedText := StrReplace(InputText, "`r`n", "`n")
    NormalizedText := StrReplace(NormalizedText, "`r", "`n")
    Lines := StrSplit(NormalizedText, "`n")
    LastIndentLevel := 0

    for Index, Line in Lines {
        State := CurrentRunState()
        if (State != "")
            return State

        ; Keep the indentation for comparison, but type only Content. This avoids
        ; adding source spaces on top of CodeHS's automatic indentation.
        Content := LTrim(Line, " `t")
        LeadingWhitespace := SubStr(Line, 1, StrLen(Line) - StrLen(Content))

        ; A blank line must not reset LastIndentLevel. Resetting it to zero would
        ; break the indentation of the next non-blank line in the same block.
        if (Content = "") {
            if (Index < Lines.Length) {
                Send("{Enter}")
                if !TypingPause(Max(25, Settings.TypingSpeed))
                    return CurrentRunState()
            }
            continue
        }

        IndentWidth := MeasureIndent(LeadingWhitespace, Settings.IndentSize)
        CurrentIndentLevel := IndentWidth // Settings.IndentSize

        ; CodeHS performs indentation increases after Enter. Shift+Tab is sent
        ; only when the source code moves back one or more indentation levels.
        if (CurrentIndentLevel < LastIndentLevel) {
            DedentCount := LastIndentLevel - CurrentIndentLevel

            Loop DedentCount {
                Send("+{Tab}")
                if !TypingPause(Max(25, Settings.TypingSpeed))
                    return CurrentRunState()
            }
        }

        Loop Parse, Content {
            State := CurrentRunState()
            if (State != "")
                return State

            SendText(A_LoopField)
            Delay := Settings.TypingSpeed
            if (Settings.TypingJitter > 0)
                Delay += Random(0, Settings.TypingJitter)

            if !TypingPause(Delay)
                return CurrentRunState()
        }

        LastIndentLevel := CurrentIndentLevel

        ; Send Enter only when the input contains another line. This prevents an
        ; unwanted newline from being added to input which does not end with one.
        if (Index < Lines.Length) {
            Send("{Enter}")
            if !TypingPause(Max(25, Settings.TypingSpeed))
                return CurrentRunState()
        }
    }

    return "complete"
}

MeasureIndent(Whitespace, IndentSize) {
    Columns := 0

    Loop Parse, Whitespace {
        if (A_LoopField = "`t")
            Columns += IndentSize - Mod(Columns, IndentSize)
        else
            Columns += 1
    }

    return Columns
}

WaitForStartDelay(DelayMs) {
    global StopRequested

    EndTime := A_TickCount + DelayMs
    LastSecond := -1

    while (A_TickCount < EndTime) {
        if StopRequested {
            ToolTip()
            return false
        }

        Remaining := EndTime - A_TickCount
        Seconds := Ceil(Remaining / 1000)

        if (Seconds != LastSecond) {
            ToolTip("Focus the CodeHS editor.`nTyping starts in " Seconds " second(s).`nPress F1 to cancel.")
            LastSecond := Seconds
        }

        Sleep(Min(50, Remaining))
    }

    ToolTip()
    return !StopRequested
}

TypingPause(DelayMs) {
    State := CurrentRunState()
    if (State != "")
        return false

    if (DelayMs <= 0)
        return true

    EndTime := A_TickCount + DelayMs

    while (A_TickCount < EndTime) {
        State := CurrentRunState()
        if (State != "")
            return false

        Sleep(Min(20, EndTime - A_TickCount))
    }

    return true
}

CurrentRunState() {
    global StopRequested, TargetWindow

    if StopRequested
        return "stopped"

    if (!TargetWindow || !WinActive("ahk_id " TargetWindow))
        return "focus_lost"

    return ""
}

FinishTyping(Result, ErrorText := "") {
    global MyGui, StartButton, StatusText
    global StopRequested, IsTyping, TargetWindow

    ToolTip()
    StopRequested := false
    IsTyping := false
    TargetWindow := 0
    StartButton.Enabled := true

    MyGui.Show()
    ApplyAlwaysOnTop()

    switch Result {
        case "complete":
            StatusText.Text := "Typing complete."
            SoundBeep(1000, 120)
        case "stopped":
            StatusText.Text := "Typing stopped with F1."
        case "focus_lost":
            StatusText.Text := "Stopped because the target window lost focus."
        case "no_target":
            StatusText.Text := "No target window was selected. Try again and focus CodeHS during the countdown."
        case "error":
            StatusText.Text := "Typing stopped because of an error: " ErrorText
        default:
            StatusText.Text := "Typing stopped."
    }
}

RequestStop(*) {
    global StopRequested, IsTyping

    if IsTyping
        StopRequested := true
}

IsTypingNow() {
    global IsTyping
    return IsTyping
}

SaveSettings(*) {
    global SettingsPath, AppName, StatusText

    Settings := GetValidatedSettings()
    if !IsObject(Settings)
        return

    IniWrite(Settings.StartDelay, SettingsPath, "Settings", "StartDelay")
    IniWrite(Settings.TypingSpeed, SettingsPath, "Settings", "TypingSpeed")
    IniWrite(Settings.TypingJitter, SettingsPath, "Settings", "TypingJitter")
    IniWrite(Settings.IndentSize, SettingsPath, "Settings", "IndentSize")
    IniWrite(Settings.AlwaysOnTop, SettingsPath, "Settings", "AlwaysOnTop")

    ApplyAlwaysOnTop()
    StatusText.Text := "Settings saved."
    MsgBox("Settings saved.", AppName, "Iconi")
}

LoadSettings() {
    global SettingsPath
    global StartDelayControl, TypingSpeedControl, TypingJitterControl
    global IndentSizeControl, AlwaysOnTopControl

    StartDelayControl.Value := ReadIntegerSetting("StartDelay", 2000, 0, 60000)
    TypingSpeedControl.Value := ReadIntegerSetting("TypingSpeed", 50, 0, 2000)

    ; TypingOffset keeps compatibility with the original settings.ini.
    LegacyJitter := IniRead(SettingsPath, "Settings", "TypingOffset", "")
    JitterDefault := RegExMatch(LegacyJitter, "^\d+$") ? LegacyJitter : 50
    TypingJitterControl.Value := ReadIntegerSetting("TypingJitter", JitterDefault, 0, 2000)

    IndentSizeControl.Value := ReadIntegerSetting("IndentSize", 4, 1, 8)
    AlwaysOnTopControl.Value := ReadIntegerSetting("AlwaysOnTop", 1, 0, 1)
}

ReadIntegerSetting(Key, DefaultValue, Minimum, Maximum) {
    global SettingsPath

    Value := IniRead(SettingsPath, "Settings", Key, DefaultValue)
    TextValue := Trim(Value)

    if !RegExMatch(TextValue, "^\d+$")
        return DefaultValue

    NumericValue := TextValue + 0
    if (NumericValue < Minimum || NumericValue > Maximum)
        return DefaultValue

    return NumericValue
}

GetValidatedSettings() {
    global MyGui

    Values := MyGui.Submit(false)

    if !ValidateInteger(Values.StartDelay, "Start delay", 0, 60000, &StartDelay)
        return false

    if !ValidateInteger(Values.TypingSpeed, "Typing speed", 0, 2000, &TypingSpeed)
        return false

    if !ValidateInteger(Values.TypingJitter, "Random extra delay", 0, 2000, &TypingJitter)
        return false

    if !ValidateInteger(Values.IndentSize, "Indent size", 1, 8, &IndentSize)
        return false

    return {
        StartDelay: StartDelay,
        TypingSpeed: TypingSpeed,
        TypingJitter: TypingJitter,
        IndentSize: IndentSize,
        AlwaysOnTop: Values.AlwaysOnTop ? 1 : 0,
        InputText: Values.InputText
    }
}

ValidateInteger(Value, Label, Minimum, Maximum, &Result) {
    global AppName

    TextValue := Trim(Value)

    if !RegExMatch(TextValue, "^\d+$") {
        MsgBox(Label " must be a whole number between " Minimum " and " Maximum ".", AppName, "Iconx")
        return false
    }

    Result := TextValue + 0

    if (Result < Minimum || Result > Maximum) {
        MsgBox(Label " must be between " Minimum " and " Maximum ".", AppName, "Iconx")
        return false
    }

    return true
}

ApplyAlwaysOnTop(*) {
    global MyGui, AlwaysOnTopControl

    if AlwaysOnTopControl.Value
        MyGui.Opt("+AlwaysOnTop")
    else
        MyGui.Opt("-AlwaysOnTop")
}

CloseApp(*) {
    ExitApp()
}
