#!/bin/bash
# Weekly cleanup for a Mac that builds iOS apps (the Mac mini runner).
# Removes only things Xcode recreates on demand:
#   - DerivedData project folders untouched for 7 days
#   - simulators whose iOS runtime is no longer installed
# Archives (which hold crash symbols) and device support files are left alone.
# Logs free space before and after to ~/Library/Logs/xcode-cleanup.log.
set -uo pipefail

LOG="$HOME/Library/Logs/xcode-cleanup.log"
DD="$HOME/Library/Developer/Xcode/DerivedData"
free_gb() { df -g / | awk 'NR==2 {print $4}'; }

{
  echo "== $(date '+%Y-%m-%d %H:%M') free before: $(free_gb) GB"
  if [ -d "$DD" ]; then
    find "$DD" -mindepth 1 -maxdepth 1 -type d -mtime +7 -print -exec rm -rf {} +
  fi
  xcrun simctl delete unavailable 2>&1 || true
  echo "   free after: $(free_gb) GB"
} >> "$LOG" 2>&1
