#!/bin/bash
# Read tasks completed today from Things3 logbook
# Output: one task per line as "name | notes | completion_date"

osascript -e '
tell application "Things3"
  set output to ""
  set today to current date
  set time of today to 0

  set logItems to to dos of list "ログブック"
  repeat with t in logItems
    set compDate to completion date of t
    if compDate >= today then
      set todoName to name of t
      set todoNotes to notes of t
      set output to output & todoName & " | " & todoNotes & linefeed
    end if
  end repeat
  return output
end tell
'
