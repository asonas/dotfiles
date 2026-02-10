#!/bin/bash
# Read today's tasks from Things3
# Output: one task per line as "status | name | notes"
# status: open or completed

osascript -e '
tell application "Things3"
  set output to ""
  set todoList to every to do of list "今日"
  repeat with t in todoList
    set todoName to name of t
    set todoStatus to status of t
    set todoNotes to notes of t
    if todoStatus is open then
      set statusStr to "open"
    else
      set statusStr to "completed"
    end if
    set output to output & statusStr & " | " & todoName & " | " & todoNotes & linefeed
  end repeat
  return output
end tell
'
