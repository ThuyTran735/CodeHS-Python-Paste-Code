# CodeHS Python AutoTyper

An AutoHotkey v2 utility that types Python code into the active CodeHS editor one character at a time.

CodeHS automatically inserts indentation after Enter. To prevent double indentation, this script measures the leading spaces in each source line but never types those spaces. It lets CodeHS handle indentation increases and sends `Shift+Tab` only when the source code moves back to a lower indentation level.

> Use this tool only where automated typing is permitted. Follow your teacher's, school's, and CodeHS's rules.

## Requirements

- Windows 10 or Windows 11
- [AutoHotkey v2](https://www.autohotkey.com/)
- CodeHS configured to use standard Python indentation

AutoHotkey v1 is not supported.

## Files

- `run.ahk` — the application
- `settings.ini` — saved defaults
- `README.md` — usage and troubleshooting
- `LICENSE` — project license

Keep `run.ahk` and `settings.ini` in the same folder.

## Run the application

1. Install AutoHotkey v2.
2. Extract the ZIP file.
3. Double-click `run.ahk`.
4. Paste your Python code into the large **Code to type** box.
5. Open CodeHS and place the cursor where the code should begin.
6. Click **Start Typing**.
7. During the countdown, focus the CodeHS editor.
8. Do not switch windows while typing. Press `F1` to stop safely.

The application hides during the countdown. When the countdown ends, it locks onto the active window. If that window loses focus, typing stops instead of continuing into another application.

## Settings

| Setting | Description | Default |
| --- | --- | ---: |
| Start delay | Time available to focus the CodeHS editor | 2000 ms |
| Typing speed | Base pause after each character | 50 ms |
| Random extra delay | Adds a random pause from zero to this value | 50 ms |
| Spaces per indentation level | Used to interpret source indentation | 4 |
| Always on top | Keeps the setup window above other windows | On |

Click **Save Settings** to write the values to `settings.ini`. The code in the text box is never saved.

## Indentation behavior

For every non-blank source line, the script separates the line into:

- leading spaces or tabs, used only to calculate the source indentation level;
- the line content, which is the only part typed into CodeHS.

The script then follows these rules:

1. When indentation increases, it sends no spaces and lets CodeHS auto-indent.
2. When indentation stays the same, it begins typing at CodeHS's current indentation.
3. When indentation decreases, it sends one `Shift+Tab` for each level removed.
4. Blank lines are entered without resetting the remembered indentation level.
5. Tabs in the source are measured using the configured indentation size.

This prevents the source's leading spaces from being added on top of CodeHS's automatic indentation.

## Safety features

- `F1` stops both the countdown and active typing.
- Typing stops if the selected target window loses focus.
- Settings are checked before typing starts.
- A second typing run cannot start while one is active.
- The script does not add a final Enter unless the input contains a final newline.
- Special characters are sent literally with AutoHotkey's `SendText` function.

## Known limitations

- The indentation logic is intended for standard Python blocks using a consistent indentation width.
- The first line of a complete program should normally begin at indentation level zero.
- Unusual hanging indentation, intentionally indented multiline-string contents, or mixed indentation may need manual correction.
- `Shift+Tab` must be mapped to one-level dedentation in the CodeHS editor.
- The script targets the active window, not a specific website account or assignment.

## Troubleshooting

### The code is double-indented

Make sure you are running this version of `run.ahk`. It types `Content`, not the complete source `Line`, so normal leading spaces are measured but never sent.

Also verify that the source uses ordinary spaces or tabs. Non-breaking spaces and other unusual Unicode whitespace are not valid normal Python indentation.

### Dedented lines still have extra spaces

Click inside the CodeHS editor and test `Shift+Tab` manually on an indented blank line. It must remove one complete indentation level. If it does not, CodeHS or the browser may be using a different shortcut.

### Typing stops immediately

The CodeHS browser window was not active when the countdown finished, or it lost focus after typing began. Start again and click directly inside the editor during the countdown.

### F1 does not stop typing

Confirm that AutoHotkey is running in the system tray. Some laptops require `Fn+F1` to produce the F1 key.

### Characters are missing

Increase **Typing speed** and reduce **Random extra delay**. Browser performance and editor responsiveness vary between computers.

## Changes from the original version

- Added functional F1 cancellation.
- Replaced single Backspace dedentation with one `Shift+Tab` per indentation level.
- Fixed trailing spaces being counted as indentation.
- Fixed blank lines resetting indentation state.
- Added tab-aware indentation measurement.
- Prevented an unwanted final newline.
- Added numeric settings validation and bounds.
- Added a working Always-on-Top setting.
- Added target-window focus protection.
- Made settings paths relative to the script folder.
- Updated the interface and documentation.
