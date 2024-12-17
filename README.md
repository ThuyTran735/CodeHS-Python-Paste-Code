# Overview:
If your teacher has disabled copy and paste on CodeHS, use this AHK script to quickly type in code. This will only work with Python Turtle.

## Prerequisites
- **AutoHotkey**: Ensure you have AutoHotkey installed. You can download it from the [official website](https://www.autohotkey.com/).

**Run the Script**:
   - Double-click the `run.ahk` file to run the script.
   - The main GUI window will appear.

## How to Use
1. **Input Text**:
   - Enter the text you want to type in the provided text box.

2. **Open Settings**:
   - Click the "Settings" button to customize typing settings:
     - **Typing Speed (ms delay)**: Set the delay between each keystroke.
     - **Start Delay (ms)**: Set the delay before the typing action starts.
     - **Always on Top**: Toggle whether the main GUI window remains on top of other windows.

3. **Save Settings**:
   - Adjust the settings and click "Save" to apply them.

4. **Start Typing**:
   - Click the "Start" button to begin typing the entered text into the focused application (such as the CodeHS Python editor).
   - Ensure the target application is in focus when you start the script.

5. **Stop Typing**:
   - Press `F1` at any time to stop the typing action.

## Script Features
- **Customizable Typing Speed**: Set the delay between keystrokes for a natural typing effect.
- **Start Delay**: Delay the typing action to give you time to focus the target application.
- **Always on Top Option**: Keep the main GUI window on top of other windows.
- **Indentation Handling**: Maintains proper indentation for Python code, adjusting for function and loop definitions.
- **Special Character Replacement**: Handles special characters such as `#`, `Tab`, and others.

## Notes
- Make sure the target application (e.g., CodeHS Python editor) is in focus before starting the script.
- Adjust the typing speed and start delay according to your preferences for smoother automation.
- Early version so expect a lot of bugs.
