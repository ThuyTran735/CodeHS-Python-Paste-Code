#Persistent ; Keep the script running
#SingleInstance Force ; Ensure only one instance of the script runs at a time

; Variables to store settings
global TypingSpeed := 100
global StartDelay := 0
global AlwaysOnTop := false

; Load settings from file if it exists
if FileExist("settings.ini") {
    IniRead, TypingSpeed, settings.ini, Settings, TypingSpeed, 100
    IniRead, StartDelay, settings.ini, Settings, StartDelay, 0
    IniRead, AlwaysOnTop, settings.ini, Settings, AlwaysOnTop, 0
    if AlwaysOnTop {
        Gui, Main: +AlwaysOnTop
    } else {
        Gui, Main: -AlwaysOnTop
    }
}

; Create the main GUI
Gui, Main: +Resize ; Allow resizing by dragging the corners
Gui, Main: Add, Text, x10 y10 w200 h20, Enter text to type:
Gui, Main: Add, Edit, vUserInput x10 y40 w300 h100 ; A text box to input text
Gui, Main: Add, Button, x10 y150 w100 h30 gOpenSettings, Settings ; Button to open settings
Gui, Main: Add, Button, x120 y150 w100 h30 gStart, Start ; Button to trigger the typing action
Gui, Main: Show, w320 h200, Text Typing Tool ; Show the main GUI window

; Create the settings GUI
Gui, Settings: +Resize ; Allow resizing by dragging the corners
Gui, Settings: Add, Text, x10 y10 w200 h20, Typing Speed (ms delay):
Gui, Settings: Add, Edit, vTypingSpeed x10 y40 w100, %TypingSpeed% ; Input box to set typing speed
Gui, Settings: Add, Text, x10 y80 w200 h20, Start Delay (ms):
Gui, Settings: Add, Edit, vStartDelay x10 y100 w100, %StartDelay% ; Input box to set start delay
Gui, Settings: Add, CheckBox, vAlwaysOnTop x10 y130 w200 h20 Checked%AlwaysOnTop%, Always on Top ; Checkbox to toggle always-on-top
Gui, Settings: Add, Button, x10 y160 w100 h30 gSaveSettings, Save ; Button to save settings
Gui, Settings: Add, Button, x120 y160 w100 h30 gCancelSettings, Cancel ; Button to cancel settings

; Hotkey to stop typing when F1 is pressed
global StopTyping := false
F1:: StopTyping := true ; Stop typing when F1 is pressed
return ; Exit the F1 hotkey without breaking the script

; Open settings GUI
OpenSettings:
Gui, Settings: Show, w320 h220, Settings
Gui, Settings: +AlwaysOnTop ; Ensure the settings window is always on top
return

; Save settings and return to main GUI
SaveSettings:
Gui, Submit, NoHide ; Save the settings
IniWrite, %TypingSpeed%, settings.ini, Settings, TypingSpeed
IniWrite, %StartDelay%, settings.ini, Settings, StartDelay
IniWrite, %AlwaysOnTop%, settings.ini, Settings, AlwaysOnTop
Gui, Settings: Hide ; Hide the settings GUI
Gui, Main: Default
if AlwaysOnTop {
    Gui, Main: +AlwaysOnTop ; Enable always-on-top if the checkbox is checked
} else {
    Gui, Main: -AlwaysOnTop ; Disable always-on-top if the checkbox is unchecked
}
return

; Cancel settings and return to main GUI
CancelSettings:
Gui, Settings: Hide ; Hide the settings GUI
Gui, Main: Default
return

; Button action when Start is clicked
Start:
Gui, Submit, NoHide ; Get the text from the input box and keep GUI open
Sleep, %StartDelay% ; Delay before starting to type, based on user input
StopTyping := false ; Reset the stop typing flag
Clipboard := UserInput ; Copy the text to the clipboard
ControlFocus, , ahk_class Chrome_WidgetWin_1 ; Focus on CodeHS Python editor
FunctionCount := 0 ; Counter for function definitions
Loop, Parse, Clipboard, `n, `r ; Handle multiline input (if any)
{
    if StopTyping ; Check if F1 was pressed to stop typing
        break
    NewField := A_LoopField ; Assign A_LoopField to a new variable
    ; Detect function and loop definitions
    if (RegExMatch(NewField, "^\s*(def|for|if|while)\s")) {
        FunctionCount++
        if (FunctionCount > 1) {
            ; Backspace twice for indentation
            Send, {BS 2}
        }
    }
    ; Replace special characters
    StringReplace, NewField, NewField, `#, {Shift Down}3{Shift Up}, All ; Handle #
    StringReplace, NewField, NewField, `t, {Tab}, All ; Replace tabs with {Tab} for indentation
    StringReplace, NewField, NewField, `, {Backtick}, All ; Replace backticks with {Backtick}
    StringReplace, NewField, NewField, `%, {Percent}, All ; Replace % with {Percent}
    ; Remove leading spaces or tabs to ensure correct indentation
    While (SubStr(NewField, 1, 1) = " " || SubStr(NewField, 1, 1) = A_Tab)
    {
        StringTrimLeft, NewField, NewField, 1
    }
    SendInput, %NewField%
    Sleep, %TypingSpeed% ; Use the value from the typing speed input box
    Send, {Enter} ; Add Enter key press for multiline typing
}
MsgBox, Done ; Display a message box saying "Done"
Gui, Main: Default ; Reset focus to the main GUI
return

; Close the GUI if the user closes the window
GuiClose:
ExitApp ; Close the script if the GUI is closed
