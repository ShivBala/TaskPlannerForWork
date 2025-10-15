# TROUBLESHOOTING: File Locked Error

## Problem
When running `helper.ps1`, you see:
```
❌ The process cannot access the file because it is being used by another process
⚙️  Falling back to legacy mode
```

## Cause
The V9 config file (`project_config_*.csv`) is open in another program:
- **Microsoft Excel**
- **VS Code**
- **Web Browser**
- **Another PowerShell session**

## Solution

### Quick Fix
1. **Close the CSV file** in Excel/VS Code/Browser
2. **Reload helper.ps1**:
   ```powershell
   pwsh -Command ./helper.ps1
   ```

### Check What's Locking the File
```bash
# On macOS/Linux
lsof ~/Downloads/project_config_*.csv

# On Windows PowerShell
Get-Process | Where-Object {$_.MainWindowTitle -like "*project_config*"}
```

### If File is in Excel
```
1. Switch to Excel
2. Close the CSV file (File → Close or Cmd+W)
3. Do NOT quit Excel entirely - just close the file
4. Go back to PowerShell and reload
```

### If File is in VS Code
```
1. Switch to VS Code
2. Close the CSV file tab
3. Go back to PowerShell and reload
```

### After Closing the File
```powershell
# Reload helper.ps1
pwsh -Command ./helper.ps1

# You should now see:
# ✅ V9 mode initialized
# (instead of: ⚙️ Using legacy mode)
```

## How to Avoid This

### Best Practice
**Don't keep the CSV file open while using PowerShell commands.**

Workflow:
```
1. Export from HTML → CSV file created
2. Close the file if you opened it
3. Use PowerShell commands → Updates CSV automatically
4. Import in HTML → See changes
```

### If You Need to View the File
1. Make a **copy** to view:
   ```bash
   cp ~/Downloads/project_config_*.csv ~/Downloads/project_config_VIEW.csv
   ```
2. Open the VIEW copy in Excel
3. PowerShell uses the original file

## Verification

After closing the file, run:
```powershell
pwsh -Command ". ./v9_integration.ps1; Write-Host 'V9 Active:' \$script:UseV9Format"
```

Expected output:
```
✅ V9 mode initialized
V9 Active: True
```

If you still see `False`, the file might still be locked.

---

**Quick Summary:**  
Close CSV file in Excel/VS Code → Reload helper.ps1 → V9 mode works! 🎉
