# PowerShell Dynamic Function Dispatcher with Regex Mapping

# Import Excel Export Module
. "$PSScriptRoot/ExcelExport/export_to_excel.ps1"
. "$PSScriptRoot/ExcelExport/create_excel_template.ps1"

function Send-NetworkPing {
    param(
        [string]$TargetHost,
        [int]$Count = 4
    )
    Write-Host "Pinging $TargetHost ($Count times)" -ForegroundColor Blue
    Test-Connection -ComputerName $TargetHost -Count $Count
}

function Convert-StringToProgressiveRegex {
    Write-Host "String to convert?" -ForegroundColor Yellow -NoNewline
    $InputString = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($InputString)) {
        Write-Host "No input provided." -ForegroundColor Red
        return
    }
    
    Write-Host "`nConverting: '$InputString'" -ForegroundColor Blue
    
    # Split by semicolon first, then process each segment
    $segments = $InputString -split ';'
    $regexParts = @()
    
    foreach ($segment in $segments) {
        # Remove colon and convert to lowercase
        $cleanSegment = $segment -replace ':', '' | ForEach-Object { $_.ToLower() }
        
        if ($cleanSegment.Length -eq 0) {
            continue
        }
        
        # Build progressive regex for this segment
        $chars = $cleanSegment.ToCharArray()
        $regexPart = ""
        
        # Start from the end and work backwards
        for ($i = $chars.Length - 1; $i -ge 0; $i--) {
            if ($i -eq $chars.Length - 1) {
                # Last character - just the character with optional ?
                $regexPart = $chars[$i] + "?"
            } else {
                # Wrap the previous part: char(previous)?
                $regexPart = $chars[$i] + "(" + $regexPart + ")?"
            }
        }
        
        # For segments after the first, we don't need the trailing ?
        if ($regexParts.Count -eq 0) {
            # First segment - keep the trailing ?
            $regexParts += $regexPart
        } else {
            # Remove the trailing ? for subsequent segments
            if ($regexPart.EndsWith("?")) {
                $regexPart = $regexPart.Substring(0, $regexPart.Length - 1)
            }
            $regexParts += $regexPart
        }
    }
    
    $finalRegex = $regexParts -join ''
    
    Write-Host "Result: $finalRegex" -ForegroundColor Green
    Write-Host "Copied to clipboard!" -ForegroundColor Cyan
    
    # Copy to clipboard (works on Windows and Mac)
    try {
        $finalRegex | Set-Clipboard
    } catch {
        Write-Host "Note: Could not copy to clipboard automatically" -ForegroundColor DarkYellow
    }
}

function Calculate-Progress {
    param(
        [bool]$IsNewTask,
        [string]$CurrentProgress
    )
    
    if ($IsNewTask) {
        # For new tasks, return default 0%
        Write-Host "Calculating progress for new task..." -ForegroundColor DarkGray
        return "0%"
    } else {
        # For existing tasks, return current value
        Write-Host "Keeping current progress: $CurrentProgress" -ForegroundColor DarkGray
        return $CurrentProgress
    }
}

function Calculate-Priority {
    param(
        [Parameter(Mandatory=$true)]
        [string]$EmployeeName,
        
        [Parameter(Mandatory=$true)]
        [string]$RequestedPriority,
        
        [Parameter(Mandatory=$false)]
        [string]$TaskDescription = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$IsNewTask = $true,
        
        [Parameter(Mandatory=$false)]
        [string]$CurrentPriority = ""
    )
    
    $TaskFile = "./task_progress_data.csv"
    
    # Validate priority input (1-9, configurable)
    $MaxPriority = 9  # Configurable maximum priority level
    if ($RequestedPriority -notmatch '^[1-9]$' -or [int]$RequestedPriority -gt $MaxPriority) {
        Write-Host "❌ Invalid priority. Must be 1-$MaxPriority (1=Highest, $MaxPriority=Lowest)" -ForegroundColor Red
        return $null
    }
    
    # Load existing tasks
    if (Test-Path $TaskFile) {
        $AllTasks = Import-Csv $TaskFile
        $PersonTasks = $AllTasks | Where-Object { 
            $_.EmployeeName -eq $EmployeeName -and 
            $_.Status -ne "Completed" -and 
            $_.Status -ne "Cancelled" -and
            $_.Status -ne "Archived"
        }
    } else {
        $PersonTasks = @()
    }
    
    # Check for priority conflicts
    $ConflictingTask = $PersonTasks | Where-Object { 
        $_.Priority -eq $RequestedPriority -and 
        $_.'Task Description' -ne $TaskDescription 
    }
    
    if ($ConflictingTask) {
        Write-Host "`n⚠️  Priority Conflict Detected!" -ForegroundColor Yellow
        Write-Host "Employee: $EmployeeName" -ForegroundColor White
        Write-Host "Requested Priority: $RequestedPriority" -ForegroundColor White
        Write-Host "Conflicting Task: $($ConflictingTask.'Task Description')" -ForegroundColor Red
        
        # Calculate effort allocation impact
        $Priority1Tasks = $PersonTasks | Where-Object { $_.Priority -eq "1" }
        $CurrentP1Count = $Priority1Tasks.Count
        $NewP1Count = if ($RequestedPriority -eq "1") { $CurrentP1Count + 1 } else { $CurrentP1Count }
        
        Write-Host "`n📊 Effort Allocation Analysis:" -ForegroundColor Cyan
        Write-Host "Current Priority 1 tasks: $CurrentP1Count" -ForegroundColor White
        if ($RequestedPriority -eq "1") {
            Write-Host "After assignment: $NewP1Count Priority 1 tasks" -ForegroundColor White
            $EffortPerP1Task = if ($NewP1Count -gt 0) { [math]::Round(60 / $NewP1Count, 1) } else { 0 }
            Write-Host "Effort per Priority 1 task: $EffortPerP1Task%" -ForegroundColor $(if ($EffortPerP1Task -lt 15) { "Red" } else { "Green" })
            
            if ($EffortPerP1Task -lt 15) {
                Write-Host "⚠️  Warning: Too many Priority 1 tasks may reduce effectiveness" -ForegroundColor Yellow
            }
        }
        
        # Suggest reordering options
        Write-Host "`n🔄 Suggested Resolution Options:" -ForegroundColor Cyan
        Write-Host "1. Keep current priorities (reject new priority)" -ForegroundColor White
        Write-Host "2. Move conflicting task to Priority $([int]$RequestedPriority + 1)" -ForegroundColor White
        Write-Host "3. Cascade: Shift all tasks down from Priority $RequestedPriority" -ForegroundColor White
        Write-Host "4. Manual reorder (you'll choose new priorities)" -ForegroundColor White
        
        Write-Host "`nChoose resolution (1-4): " -NoNewline -ForegroundColor Yellow
        $Resolution = Read-Host
        
        switch ($Resolution) {
            "1" {
                Write-Host "❌ Priority assignment cancelled - keeping current priorities" -ForegroundColor Red
                return $CurrentPriority
            }
            
            "2" {
                $MaxPriority = 9  # Should match the validation above
                
                # Find the next available priority slot
                $NewConflictPriority = [int]$RequestedPriority + 1
                $UsedPriorities = $PersonTasks | ForEach-Object { [int]$_.Priority } | Sort-Object
                
                # Keep incrementing until we find an available slot
                while ($NewConflictPriority -le $MaxPriority -and $UsedPriorities -contains $NewConflictPriority) {
                    $NewConflictPriority++
                }
                
                if ($NewConflictPriority -gt $MaxPriority) {
                    Write-Host "❌ Cannot move to available priority - all slots up to Priority $MaxPriority are occupied" -ForegroundColor Red
                    Write-Host "💡 Suggestion: Use Option 3 (Cascade) or Option 4 (Manual Reorder) instead" -ForegroundColor Yellow
                    return $CurrentPriority
                }
                
                Write-Host "`n🔄 Moving conflicting task to next available Priority $NewConflictPriority" -ForegroundColor Green
                
                # Update the conflicting task
                $UpdatedTasks = @()
                foreach ($Task in $AllTasks) {
                    if ($Task.EmployeeName -eq $EmployeeName -and 
                        $Task.'Task Description' -eq $ConflictingTask.'Task Description' -and
                        $Task.Priority -eq $RequestedPriority) {
                        $Task.Priority = [string]$NewConflictPriority
                        Write-Host "Updated: '$($Task.'Task Description')' → Priority $NewConflictPriority" -ForegroundColor Cyan
                    }
                    $UpdatedTasks += $Task
                }
                
                # Save updated CSV
                $UpdatedTasks | Export-Csv -Path $TaskFile -NoTypeInformation
                
                # Log the change
                $ChangeLog = "Priority conflict resolution: Moved '$($ConflictingTask.'Task Description')' from Priority $RequestedPriority to next available Priority $NewConflictPriority to accommodate new task assignment."
                Write-Priority-ChangeLog -EmployeeName $EmployeeName -ChangeDescription $ChangeLog -TaskDescription $TaskDescription
                
                return $RequestedPriority
            }
            
            "3" {
                Write-Host "`n🔄 Cascading priorities from Priority $RequestedPriority" -ForegroundColor Green
                
                # Find all tasks that need to be shifted
                $TasksToShift = $PersonTasks | Where-Object { 
                    [int]$_.Priority -ge [int]$RequestedPriority -and
                    $_.'Task Description' -ne $TaskDescription
                } | Sort-Object Priority
                
                if ($TasksToShift.Count -eq 0) {
                    Write-Host "✅ No tasks need shifting" -ForegroundColor Green
                    return $RequestedPriority
                }
                
                # Check if cascade is possible
                $MaxPriority = 9  # Should match the validation above
                $MaxNewPriority = ($TasksToShift | ForEach-Object { [int]$_.Priority + 1 } | Measure-Object -Maximum).Maximum
                if ($MaxNewPriority -gt $MaxPriority) {
                    Write-Host "❌ Cannot cascade - would exceed Priority $MaxPriority maximum" -ForegroundColor Red
                    return $CurrentPriority
                }
                
                # Perform cascade
                $UpdatedTasks = @()
                $ShiftedTasks = @()
                
                foreach ($Task in $AllTasks) {
                    if ($Task.EmployeeName -eq $EmployeeName -and 
                        [int]$Task.Priority -ge [int]$RequestedPriority -and
                        $Task.'Task Description' -ne $TaskDescription -and
                        $Task.Status -notin @("Completed", "Cancelled", "Archived")) {
                        
                        $OldPriority = $Task.Priority
                        $Task.Priority = [string]([int]$Task.Priority + 1)
                        $ShiftedTasks += "  '$($Task.'Task Description')': Priority $OldPriority → $($Task.Priority)"
                    }
                    $UpdatedTasks += $Task
                }
                
                # Save updated CSV
                $UpdatedTasks | Export-Csv -Path $TaskFile -NoTypeInformation
                
                # Display changes
                Write-Host "`n📋 Priority Changes:" -ForegroundColor Cyan
                $ShiftedTasks | ForEach-Object { Write-Host $_ -ForegroundColor White }
                
                # Log the change
                $ChangeLog = "Priority cascade: Shifted $($ShiftedTasks.Count) tasks down by one priority level to accommodate new Priority $RequestedPriority assignment. Details: $($ShiftedTasks -join '; ')"
                Write-Priority-ChangeLog -EmployeeName $EmployeeName -ChangeDescription $ChangeLog -TaskDescription $TaskDescription
                
                return $RequestedPriority
            }
            
            "4" {
                Write-Host "`n🔄 Manual Priority Reordering" -ForegroundColor Green
                Write-Host "Current active tasks for $EmployeeName (ordered by priority):" -ForegroundColor Cyan
                
                # Sort tasks by priority (1=highest, 9=lowest) for better visualization
                $ActiveTasks = $PersonTasks | Sort-Object { [int]$_.Priority }
                for ($i = 0; $i -lt $ActiveTasks.Count; $i++) {
                    $task = $ActiveTasks[$i]
                    $PriorityColor = switch ([int]$task.Priority) {
                        1 { "Red" }      # Highest priority - red
                        2 { "Yellow" }   # High priority - yellow  
                        3 { "Cyan" }     # Medium priority - cyan
                        default { "White" } # Lower priorities - white
                    }
                    Write-Host "$($i + 1). [P$($task.Priority)] $($task.'Task Description')" -ForegroundColor $PriorityColor
                }
                
                Write-Host "`nEnter new priorities for each task (format: 1=3,2=1,3=2...):" -ForegroundColor Yellow
                Write-Host "Or type 'cancel' to abort: " -NoNewline -ForegroundColor Yellow
                $ReorderInput = Read-Host
                
                if ($ReorderInput.ToLower() -eq "cancel") {
                    Write-Host "❌ Manual reordering cancelled" -ForegroundColor Red
                    return $CurrentPriority
                }
                
                # Parse reorder input
                try {
                    $ReorderMap = @{}
                    $Assignments = $ReorderInput -split ','
                    
                    foreach ($Assignment in $Assignments) {
                        $Parts = $Assignment.Trim() -split '='
                        if ($Parts.Count -eq 2) {
                            $TaskIndex = [int]$Parts[0] - 1
                            $NewPriority = $Parts[1].Trim()
                            
                            if ($TaskIndex -ge 0 -and $TaskIndex -lt $ActiveTasks.Count -and $NewPriority -match '^[1-9]$') {
                                $ReorderMap[$TaskIndex] = $NewPriority
                            }
                        }
                    }
                    
                    # Check for duplicate priorities
                    $AssignedPriorities = $ReorderMap.Values
                    $DuplicatePriorities = $AssignedPriorities | Group-Object | Where-Object { $_.Count -gt 1 }
                    
                    if ($DuplicatePriorities) {
                        Write-Host "❌ Duplicate priorities detected: $($DuplicatePriorities.Name -join ', ')" -ForegroundColor Red
                        return $CurrentPriority
                    }
                    
                    # Apply reordering
                    $UpdatedTasks = @()
                    $Changes = @()
                    
                    foreach ($Task in $AllTasks) {
                        $TaskFound = $false
                        for ($i = 0; $i -lt $ActiveTasks.Count; $i++) {
                            if ($Task.EmployeeName -eq $ActiveTasks[$i].EmployeeName -and 
                                $Task.'Task Description' -eq $ActiveTasks[$i].'Task Description' -and
                                $ReorderMap.ContainsKey($i)) {
                                
                                $OldPriority = $Task.Priority
                                $Task.Priority = $ReorderMap[$i]
                                $Changes += "  '$($Task.'Task Description')': Priority $OldPriority → $($Task.Priority)"
                                $TaskFound = $true
                                break
                            }
                        }
                        $UpdatedTasks += $Task
                    }
                    
                    # Save updated CSV
                    $UpdatedTasks | Export-Csv -Path $TaskFile -NoTypeInformation
                    
                    # Display changes
                    Write-Host "`n📋 Priority Changes Applied:" -ForegroundColor Cyan
                    $Changes | ForEach-Object { Write-Host $_ -ForegroundColor White }
                    
                    # Log the change
                    $ChangeLog = "Manual priority reordering: $($Changes -join '; ')"
                    Write-Priority-ChangeLog -EmployeeName $EmployeeName -ChangeDescription $ChangeLog -TaskDescription $TaskDescription
                    
                    return $RequestedPriority
                    
                } catch {
                    Write-Host "❌ Invalid reorder format. Use: 1=3,2=1,3=2" -ForegroundColor Red
                    return $CurrentPriority
                }
            }
            
            default {
                Write-Host "❌ Invalid option. Keeping current priorities." -ForegroundColor Red
                return $CurrentPriority
            }
        }
    } else {
        # No conflict - assign requested priority
        Write-Host "✅ Priority $RequestedPriority assigned (no conflicts)" -ForegroundColor Green
        
        # Log for new Priority 1 assignments
        if ($RequestedPriority -eq "1") {
            $Priority1Tasks = $PersonTasks | Where-Object { $_.Priority -eq "1" }
            $NewP1Count = $Priority1Tasks.Count + 1
            $EffortPerP1Task = [math]::Round(60 / $NewP1Count, 1)
            
            Write-Host "📊 Priority 1 Analysis: $NewP1Count tasks, $EffortPerP1Task% effort each" -ForegroundColor Cyan
            
            if ($NewP1Count -gt 4) {
                Write-Host "⚠️  Warning: $NewP1Count Priority 1 tasks may impact focus and effectiveness" -ForegroundColor Yellow
            }
        }
        
        return $RequestedPriority
    }
}

function Write-Priority-ChangeLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$EmployeeName,
        
        [Parameter(Mandatory=$true)]
        [string]$ChangeDescription,
        
        [Parameter(Mandatory=$false)]
        [string]$TaskDescription = ""
    )
    
    # Create priority-logs folder if it doesn't exist
    $LogsFolder = "./priority-logs"
    if (-not (Test-Path $LogsFolder)) {
        New-Item -ItemType Directory -Path $LogsFolder | Out-Null
    }
    
    # Create log entry
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = @"
[$Timestamp] PRIORITY CHANGE
Employee: $EmployeeName
Task Context: $TaskDescription
Change: $ChangeDescription
---
"@
    
    # Append to daily log file
    $LogFile = Join-Path $LogsFolder "priority-changes-$(Get-Date -Format 'yyyy-MM-dd').log"
    $LogEntry | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "📝 Priority change logged to: $(Split-Path $LogFile -Leaf)" -ForegroundColor DarkGray
}

function Write-ETA-ChangeLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$EmployeeName,
        
        [Parameter(Mandatory=$true)]
        [string]$ChangeDescription,
        
        [Parameter(Mandatory=$false)]
        [string]$TaskDescription = ""
    )
    
    # Create eta-logs folder if it doesn't exist
    $LogsFolder = "./eta-logs"
    if (-not (Test-Path $LogsFolder)) {
        New-Item -ItemType Directory -Path $LogsFolder | Out-Null
    }
    
    # Create log entry
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = @"
[$Timestamp] ETA CHANGE
Employee: $EmployeeName
Task Context: $TaskDescription
Change: $ChangeDescription
---
"@
    
    # Append to daily log file
    $LogFile = Join-Path $LogsFolder "eta-changes-$(Get-Date -Format 'yyyy-MM-dd').log"
    $LogEntry | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "📝 ETA change logged to: $(Split-Path $LogFile -Leaf)" -ForegroundColor DarkGray
}

function Create-HistorySnapshot {
    param(
        [string]$Action,
        [string]$EmployeeName,
        [string]$TaskDescription
    )
    
    $TaskFile = "./task_progress_data.csv"
    if (-not (Test-Path $TaskFile)) {
        Write-Host "No CSV file to backup" -ForegroundColor DarkYellow
        return
    }
    
    # Create history folder if it doesn't exist
    $HistoryFolder = "./history"
    if (-not (Test-Path $HistoryFolder)) {
        New-Item -ItemType Directory -Path $HistoryFolder | Out-Null
        Write-Host "Created history folder" -ForegroundColor DarkGray
    }
    
    # Create timestamp for filename
    $Timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $HistoryFileName = "$Timestamp" + "_" + $Action + "_" + $EmployeeName.Replace(" ", "_") + ".csv"
    $HistoryPath = Join-Path $HistoryFolder $HistoryFileName
    
    # Copy current CSV to history
    Copy-Item $TaskFile $HistoryPath
    
    # Create a summary file with change details
    $SummaryFile = Join-Path $HistoryFolder ($Timestamp + "_" + $Action + "_" + $EmployeeName.Replace(" ", "_") + "_SUMMARY.txt")
    $SummaryContent = @"
Change Summary
=============
Timestamp: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Action: $Action
Employee: $EmployeeName
Task: $TaskDescription
CSV Snapshot: $HistoryFileName

This snapshot was taken BEFORE the $Action operation was performed.
"@
    
    $SummaryContent | Out-File -FilePath $SummaryFile -Encoding UTF8
    
    Write-Host "History snapshot created: $HistoryFileName" -ForegroundColor DarkGray
}

# Helper functions for common update operations
function Get-MatchedPersonName {
    param(
        [Parameter(Mandatory=$true)]
        [string]$NamePattern,
        
        [Parameter(Mandatory=$false)]
        [string[]]$CommandPrefixes = @()
    )
    
    # Extract name from the captured pattern (handle concatenated commands)
    $CleanedName = $NamePattern
    if ($CommandPrefixes.Count -gt 0) {
        $PrefixPattern = '^(' + ($CommandPrefixes -join '|') + ')*'
        $CleanedName = $NamePattern -replace $PrefixPattern, '' -replace '^\s*', ''
    }
    
    # If nothing left after cleaning, use the original pattern
    if ([string]::IsNullOrWhiteSpace($CleanedName)) {
        $CleanedName = $NamePattern
    }
    
    # Load people from CSV
    $PeopleFile = "./people_and_capacity.csv"
    if (-not (Test-Path $PeopleFile)) {
        Write-Host "Error: $PeopleFile not found!" -ForegroundColor Red
        return $null
    }
    
    $People = Import-Csv $PeopleFile
    $MatchedName = $null
    
    # Find matching name (case-insensitive partial match) - try cleaned name first
    foreach ($Person in $People) {
        if ($Person.Name -match $CleanedName) {
            $MatchedName = $Person.Name
            break
        }
    }
    
    # If no match with cleaned name, try original pattern
    if (-not $MatchedName) {
        foreach ($Person in $People) {
            if ($Person.Name -match $NamePattern) {
                $MatchedName = $Person.Name
                break
            }
        }
    }
    
    if (-not $MatchedName) {
        Write-Host "No matching name found for pattern: '$NamePattern'" -ForegroundColor Red
        Write-Host "Cleaned pattern attempted: '$CleanedName'" -ForegroundColor Yellow
        Write-Host "Available names: $($People.Name -join ', ')" -ForegroundColor Yellow
        return $null
    }
    
    return $MatchedName
}

function Get-PersonActiveTasks {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PersonName
    )
    
    # Load tasks
    $CsvFile = "./task_progress_data.csv"
    if (-not (Test-Path $CsvFile)) {
        Write-Host "Error: $CsvFile not found!" -ForegroundColor Red
        return $null
    }
    
    $AllTasks = Import-Csv $CsvFile
    $PersonTasks = $AllTasks | Where-Object { 
        $_.EmployeeName -eq $PersonName -and 
        $_.Status -notin @("Completed", "Cancelled", "Archived")
    }
    
    if ($PersonTasks.Count -eq 0) {
        Write-Host "❌ No active tasks found for $PersonName" -ForegroundColor Red
        return $null
    }
    
    return $PersonTasks | Sort-Object { [int]$_.Priority }
}

function Show-TaskList {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks,
        
        [Parameter(Mandatory=$true)]
        [string]$PersonName,
        
        [Parameter(Mandatory=$false)]
        [string]$Context = "tasks"
    )
    
    Write-Host "`n📋 Current active $Context for $PersonName (ordered by priority):" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Tasks.Count; $i++) {
        $Task = $Tasks[$i]
        $PriorityColor = switch ([int]$Task.Priority) {
            1 { "Red" }
            2 { "Yellow" } 
            3 { "Cyan" }
            default { "White" }
        }
        
        Write-Host "$($i + 1). " -NoNewline -ForegroundColor White
        Write-Host "[P$($Task.Priority)] " -NoNewline -ForegroundColor $PriorityColor
        Write-Host "$($Task.'Task Description') " -NoNewline -ForegroundColor White
        Write-Host "(Progress: $($Task.Progress))" -NoNewline -ForegroundColor Gray
        
        # Add ETA display if showing ETA context
        if ($Context -eq "tasks for ETA update") {
            $ETADisplay = if ([string]::IsNullOrWhiteSpace($Task.ETA)) { "No ETA set" } else { $Task.ETA }
            Write-Host " (ETA: $ETADisplay)" -ForegroundColor Magenta
        } else {
            Write-Host ""
        }
    }
}

function Get-TaskSelection {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Tasks,
        
        [Parameter(Mandatory=$false)]
        [string]$PromptText = "Select task number"
    )
    
    $TaskNumber = Read-Host "`n$PromptText"
    
    if (-not ($TaskNumber -match '^\d+$') -or [int]$TaskNumber -lt 1 -or [int]$TaskNumber -gt $Tasks.Count) {
        Write-Host "❌ Invalid task number. Please select a number between 1 and $($Tasks.Count)" -ForegroundColor Red
        return $null
    }
    
    return $Tasks[[int]$TaskNumber - 1]
}

function Update-TaskInCSV {
    param(
        [Parameter(Mandatory=$true)]
        [string]$EmployeeName,
        
        [Parameter(Mandatory=$true)]
        [string]$TaskDescription,
        
        [Parameter(Mandatory=$true)]
        [string]$StartDate,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$UpdateFields
    )
    
    # Load all tasks
    $AllTasks = Import-Csv "./task_progress_data.csv"
    
    # Find and update the matching task
    $TaskFound = $false
    foreach ($Task in $AllTasks) {
        if ($Task.EmployeeName -eq $EmployeeName -and 
            $Task.'Task Description' -eq $TaskDescription -and
            $Task.StartDate -eq $StartDate) {
            
            # Update specified fields
            foreach ($Field in $UpdateFields.Keys) {
                $Task.$Field = $UpdateFields[$Field]
            }
            $TaskFound = $true
            break
        }
    }
    
    if ($TaskFound) {
        # Save back to CSV
        $AllTasks | Export-Csv "./task_progress_data.csv" -NoTypeInformation
        return $true
    } else {
        Write-Host "❌ Error: Could not find task to update" -ForegroundColor Red
        return $false
    }
}

function Parse-FlexibleDate {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DateString
    )
    
    if ([string]::IsNullOrWhiteSpace($DateString)) {
        return $null
    }
    
    # Try multiple date formats to handle various input formats
    $dateFormats = @("dd/MM/yyyy", "d/M/yyyy", "dd/M/yyyy", "d/MM/yyyy", "MM/dd/yyyy", "M/d/yyyy")
    
    foreach ($format in $dateFormats) {
        try {
            return [DateTime]::ParseExact($DateString.Trim(), $format, $null)
        } catch {
            # Continue to next format
        }
    }
    
    # If all formats fail, try the default .NET parsing
    try {
        return [DateTime]::Parse($DateString)
    } catch {
        Write-Host "Warning: Could not parse date '$DateString'" -ForegroundColor Yellow
        return $null
    }
}

# Import the HTML report generator from external file
. "./report-generator.ps1"

# Import the one-page banking report generator from external file
. "./one-page-report-generator.ps1"

function Get-DateFromAlias {
    param(
        [string]$DateInput
    )
    
    $DateInput = $DateInput.Trim().ToLower()
    $Today = Get-Date
    
    switch -Regex ($DateInput) {
        "^today$" { 
            return $Today.ToString("dd/MM/yyyy") 
        }
        "^yesterday$" { 
            return $Today.AddDays(-1).ToString("dd/MM/yyyy") 
        }
        "^tomorrow$" { 
            return $Today.AddDays(1).ToString("dd/MM/yyyy") 
        }
        "^last (monday|tuesday|wednesday|thursday|friday|saturday|sunday)$" {
            $DayName = $Matches[1]
            $TargetDay = [System.DayOfWeek]$DayName
            $DaysBack = ($Today.DayOfWeek - $TargetDay + 7) % 7
            if ($DaysBack -eq 0) { $DaysBack = 7 }  # If it's the same day, go back a full week
            return $Today.AddDays(-$DaysBack).ToString("dd/MM/yyyy")
        }
        "^next (monday|tuesday|wednesday|thursday|friday|saturday|sunday)$" {
            $DayName = $Matches[1]
            $TargetDay = [System.DayOfWeek]$DayName
            $DaysForward = ($TargetDay - $Today.DayOfWeek + 7) % 7
            if ($DaysForward -eq 0) { $DaysForward = 7 }  # If it's the same day, go forward a full week
            return $Today.AddDays($DaysForward).ToString("dd/MM/yyyy")
        }
        default {
            # If it's not an alias, return as-is (assume it's already in dd/MM/yyyy format)
            return $DateInput
        }
    }
}

function Get-ETAFromInput {
    param(
        [Parameter(Mandatory=$true)]
        [bool]$IsNewTask,
        
        [Parameter(Mandatory=$false)]
        [string]$CurrentETA = ""
    )
    
    if ($IsNewTask) {
        # New task: default is empty, show current as "none"
        Write-Host "ETA (dd/mm/yyyy, date aliases, or leave blank): " -NoNewline -ForegroundColor Yellow
        $ETAInput = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($ETAInput)) {
            return ""
        } else {
            return Get-DateFromAlias -DateInput $ETAInput
        }
    } else {
        # Existing task: show current value and use as default
        $CurrentDisplay = if ([string]::IsNullOrWhiteSpace($CurrentETA)) { "none" } else { $CurrentETA }
        Write-Host "ETA [current: $CurrentDisplay] (dd/mm/yyyy, date aliases, or leave blank): " -NoNewline -ForegroundColor Yellow
        $ETAInput = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($ETAInput)) {
            return $CurrentETA  # Keep existing value
        } else {
            return Get-DateFromAlias -DateInput $ETAInput
        }
    }
}

function Update-TaskPriority {
    param(
        [string]$NamePattern
    )
    
    # Get matched person name using helper function
    $MatchedName = Get-MatchedPersonName -NamePattern $NamePattern -CommandPrefixes @("upd", "update", "pri", "priority", "prio")
    if (-not $MatchedName) { return }
    
    Write-Host "`n🎯 Priority Update for: $MatchedName" -ForegroundColor Green
    
    # Get person's active tasks using helper function
    $SortedPersonTasks = Get-PersonActiveTasks -PersonName $MatchedName
    if (-not $SortedPersonTasks) { return }
    
    # Display tasks using helper function
    Show-TaskList -Tasks $SortedPersonTasks -PersonName $MatchedName -Context "tasks"
    
    # Get task selection using helper function
    $SelectedTask = Get-TaskSelection -Tasks $SortedPersonTasks -PromptText "Select task number to update priority"
    if (-not $SelectedTask) { return }
    
    Write-Host "`n🔧 Updating priority for: '$($SelectedTask.'Task Description')'" -ForegroundColor Green
    Write-Host "Current Priority: $($SelectedTask.Priority)" -ForegroundColor White
    Write-Host "New Priority (1-9): " -NoNewline -ForegroundColor Yellow
    $NewPriorityInput = Read-Host
    
    # Use existing Calculate-Priority function for conflict resolution
    $NewPriority = Calculate-Priority -EmployeeName $MatchedName -RequestedPriority $NewPriorityInput -TaskDescription $SelectedTask.'Task Description' -IsNewTask $false -CurrentPriority $SelectedTask.Priority
    
    if (-not $NewPriority) {
        Write-Host "❌ Priority update cancelled" -ForegroundColor Red
        return
    }
    
    # Create history snapshot before modifying
    Create-HistorySnapshot -Action "PRIORITY_UPDATE" -EmployeeName $MatchedName -TaskDescription $SelectedTask.'Task Description'
    
    # Update task using helper function
    $OldPriority = $SelectedTask.Priority
    $UpdateSuccess = Update-TaskInCSV -EmployeeName $MatchedName -TaskDescription $SelectedTask.'Task Description' -StartDate $SelectedTask.StartDate -UpdateFields @{ Priority = $NewPriority }
    
    if ($UpdateSuccess) {
        Write-Host "`n✅ Priority updated: '$($SelectedTask.'Task Description')' → Priority $OldPriority → Priority $NewPriority" -ForegroundColor Green
        
        # Log the change
        $ChangeLog = "Direct priority update: Changed '$($SelectedTask.'Task Description')' from Priority $OldPriority to Priority $NewPriority"
        Write-Priority-ChangeLog -EmployeeName $MatchedName -ChangeDescription $ChangeLog -TaskDescription $SelectedTask.'Task Description'
        
        Write-Host "`n🎯 Priority update completed successfully!" -ForegroundColor Green
        Write-Host "Employee: $MatchedName | Task: '$($SelectedTask.'Task Description')' | New Priority: $NewPriority" -ForegroundColor White
    }
}

function Update-ETA {
    param(
        [string]$NamePattern
    )
    
    # Get matched person name using helper function
    $MatchedName = Get-MatchedPersonName -NamePattern $NamePattern -CommandPrefixes @("upd", "update", "eta")
    if (-not $MatchedName) { return }
    
    Write-Host "`n🕒 ETA Update for: $MatchedName" -ForegroundColor Magenta
    
    # Get person's active tasks using helper function
    $SortedTasks = Get-PersonActiveTasks -PersonName $MatchedName
    if (-not $SortedTasks) { return }
    
    # Display tasks with ETA information using helper function
    Show-TaskList -Tasks $SortedTasks -PersonName $MatchedName -Context "tasks for ETA update"
    
    # Get task selection using helper function
    $SelectedTask = Get-TaskSelection -Tasks $SortedTasks -PromptText "Select task number to update ETA"
    if (-not $SelectedTask) { return }
    
    Write-Host "`n🔧 Updating ETA for: '$($SelectedTask.'Task Description')'" -ForegroundColor Yellow
    $CurrentETA = if ([string]::IsNullOrWhiteSpace($SelectedTask.ETA)) { "Not set" } else { $SelectedTask.ETA }
    Write-Host "Current ETA: $CurrentETA" -ForegroundColor Gray
    
    # Get new ETA
    Write-Host "`nEnter new ETA (format: dd/mm/yyyy or leave empty to clear):" -ForegroundColor Cyan
    $NewETA = Read-Host "New ETA"
    
    # Validate date format if provided
    if (-not [string]::IsNullOrWhiteSpace($NewETA)) {
        $ParsedDate = Parse-FlexibleDate -DateString $NewETA
        if ($null -eq $ParsedDate) {
            Write-Host "❌ Invalid date format. Please use dd/mm/yyyy (e.g., 25/12/2025)" -ForegroundColor Red
            return
        }
        $NewETA = $ParsedDate.ToString("dd/MM/yyyy")
    }
    
    # Update task using helper function
    $OldETA = $SelectedTask.ETA
    $UpdateSuccess = Update-TaskInCSV -EmployeeName $MatchedName -TaskDescription $SelectedTask.'Task Description' -StartDate $SelectedTask.StartDate -UpdateFields @{ ETA = $NewETA }
    
    if ($UpdateSuccess) {
        # Log the change
        $ETAChangeLog = if ([string]::IsNullOrWhiteSpace($NewETA)) {
            "ETA cleared for '$($SelectedTask.'Task Description')' (was: $OldETA)"
        } else {
            "ETA updated for '$($SelectedTask.'Task Description')': $OldETA → $NewETA"
        }
        
        Write-ETA-ChangeLog -EmployeeName $MatchedName -ChangeDescription $ETAChangeLog -TaskDescription $SelectedTask.'Task Description'
        
        Write-Host "`n🕒 ETA update completed successfully!" -ForegroundColor Green
        $ETAStatus = if ([string]::IsNullOrWhiteSpace($NewETA)) { "cleared" } else { "set to $NewETA" }
        Write-Host "Employee: $MatchedName | Task: '$($SelectedTask.'Task Description')' | ETA $ETAStatus" -ForegroundColor White
    }
}

function Add-TaskProgressEntry {
    param(
        [string]$NamePattern
    )
    
    # Get matched person name using helper function (no command prefixes for this function)
    $MatchedName = Get-MatchedPersonName -NamePattern $NamePattern
    if (-not $MatchedName) { return }
    
    Write-Host "Found employee: $MatchedName" -ForegroundColor Green
    
    # Ask whether to add or modify
    Write-Host "`nAdd or Modify task? " -NoNewline -ForegroundColor Cyan
    $Action = Read-Host
    
    $IsAdd = $Action -match "a(d(d)?)?"
    $IsModify = $Action -match "m(o(d(i(f(y)?)?)?)?)?"
    
    if (-not $IsAdd -and -not $IsModify) {
        Write-Host "Invalid action. Please type 'add' or 'modify'" -ForegroundColor Red
        return
    }
    
    if ($IsModify) {
        # Show existing tasks for this person
        $TaskFile = "./task_progress_data.csv"
        if (-not (Test-Path $TaskFile)) {
            Write-Host "No existing tasks found. Creating new task instead." -ForegroundColor Yellow
            $IsAdd = $true
            $IsModify = $false
        } else {
            $AllTasks = Import-Csv $TaskFile
            $PersonTasks = $AllTasks | Where-Object { $_.EmployeeName -eq $MatchedName }
            
            if ($PersonTasks.Count -eq 0) {
                Write-Host "No existing tasks found for $MatchedName. Creating new task instead." -ForegroundColor Yellow
                $IsAdd = $true
                $IsModify = $false
            } else {
                Write-Host ("`nExisting tasks for " + $MatchedName + " (ordered by priority):") -ForegroundColor Cyan
                
                # Sort tasks by priority (1=highest, 9=lowest)
                $SortedPersonTasks = $PersonTasks | Sort-Object { [int]$_.Priority }
                
                for ($i = 0; $i -lt $SortedPersonTasks.Count; $i++) {
                    $task = $SortedPersonTasks[$i]
                    $TaskDesc = $task.'Task Description'
                    $PriorityDisplay = "Priority: $($task.Priority)"
                    $ProgressDisplay = "Progress: $($task.Progress)"
                    $StatusDisplay = if ($task.Status -and $task.Status -ne "Active") { " [$($task.Status)]" } else { "" }
                    
                    Write-Host "$($i + 1). $TaskDesc ($PriorityDisplay, $ProgressDisplay)$StatusDisplay" -ForegroundColor White
                }
                
                # Update PersonTasks to use the sorted version for subsequent operations
                $PersonTasks = $SortedPersonTasks
                
                Write-Host "`nSelect task number to modify: " -NoNewline -ForegroundColor Yellow
                $TaskNumber = Read-Host
                
                try {
                    $SelectedTaskIndex = [int]$TaskNumber - 1
                    if ($SelectedTaskIndex -lt 0 -or $SelectedTaskIndex -ge $PersonTasks.Count) {
                        throw "Invalid selection"
                    }
                    $SelectedTask = $PersonTasks[$SelectedTaskIndex]
                } catch {
                    Write-Host "Invalid task number selected." -ForegroundColor Red
                    return
                }
            }
        }
    }
    
    if ($IsAdd) {
        # Collect task details for new task
        Write-Host "`nEnter task details:" -ForegroundColor Cyan
    } else {
        # Modify existing task
        $ModifyingTaskName = $SelectedTask.'Task Description'
        Write-Host "`nModifying task: $ModifyingTaskName" -ForegroundColor Cyan
    }
    
    if ($IsAdd) {
        Write-Host "Task Description: " -NoNewline -ForegroundColor Yellow
        $TaskDescription = Read-Host
        
        Write-Host "Priority (1-9): " -NoNewline -ForegroundColor Yellow
        $PriorityInput = Read-Host
        $Priority = Calculate-Priority -EmployeeName $MatchedName -RequestedPriority $PriorityInput -TaskDescription $TaskDescription -IsNewTask $true
        
        if (-not $Priority) {
            Write-Host "❌ Task creation cancelled due to priority conflict" -ForegroundColor Red
            return
        }
        
        Write-Host "Start Date (dd/mm/yyyy, or: today, yesterday, tomorrow, last/next [day]): " -NoNewline -ForegroundColor Yellow
        $StartDateInput = Read-Host
        $StartDate = Get-DateFromAlias -DateInput $StartDateInput
        
        $ETA = Get-ETAFromInput -IsNewTask $true
        
        Write-Host "Progress (0-100%, 'decide', 'calculate') [default: 0%]: " -NoNewline -ForegroundColor Yellow
        $ProgressInput = Read-Host
        if ([string]::IsNullOrWhiteSpace($ProgressInput)) {
            $Progress = "0%"
        } elseif ($ProgressInput -match "de(c(i(d(e)?)?)?)?|cal(c(u(l(a(t(e)?)?)?)?)?)?") {
            $Progress = Calculate-Progress -IsNewTask $true -CurrentProgress ""
        } else {
            $Progress = $ProgressInput
        }
        
        # Automatically set report sent fields to "n" for new tasks
        $ProgressReportSent = "n"
        $FinalReportSent = "n"
        
        # Set current date as created date
        $CreatedDate = Get-Date -Format "dd/MM/yyyy"
    } else {
        # Modify existing task - only editable fields
        # Keep original values for non-editable fields
        $TaskDescription = $SelectedTask.'Task Description'
        $StartDate = $SelectedTask.StartDate
        $CreatedDate = if ($SelectedTask.Created_Date) { $SelectedTask.Created_Date } else { "" }
        
        Write-Host "Priority [current: $($SelectedTask.Priority)]: " -NoNewline -ForegroundColor Yellow
        $PriorityInput = Read-Host
        if ([string]::IsNullOrWhiteSpace($PriorityInput)) {
            $Priority = $SelectedTask.Priority
        } else {
            $Priority = Calculate-Priority -EmployeeName $MatchedName -RequestedPriority $PriorityInput -TaskDescription $SelectedTask.'Task Description' -IsNewTask $false -CurrentPriority $SelectedTask.Priority
            
            if (-not $Priority) {
                Write-Host "❌ Task modification cancelled due to priority conflict" -ForegroundColor Red
                return
            }
        }
        
        $ETA = Get-ETAFromInput -IsNewTask $false -CurrentETA $SelectedTask.ETA
        
        Write-Host "Progress [current: $($SelectedTask.Progress)] ('decide', 'calculate' supported): " -NoNewline -ForegroundColor Yellow
        $ProgressInput = Read-Host
        if ([string]::IsNullOrWhiteSpace($ProgressInput)) {
            $Progress = $SelectedTask.Progress
        } elseif ($ProgressInput -match "de(c(i(d(e)?)?)?)?|cal(c(u(l(a(t(e)?)?)?)?)?)?") {
            $Progress = Calculate-Progress -IsNewTask $false -CurrentProgress $SelectedTask.Progress
        } else {
            $Progress = $ProgressInput
        }
        
        $CurrentStatus = if ($SelectedTask.Status) { $SelectedTask.Status } else { "Active" }
        Write-Host "Status [current: $CurrentStatus] (Active, Completed, Cancelled, Archived): " -NoNewline -ForegroundColor Yellow
        $StatusInput = Read-Host
        if ([string]::IsNullOrWhiteSpace($StatusInput)) {
            $Status = $CurrentStatus
        } else {
            $Status = $StatusInput
        }
        
        # Keep original values for report fields (these don't usually change during updates)
        $ProgressReportSent = $SelectedTask.ProgressReportSent
        $FinalReportSent = $SelectedTask.FinalReportSent
    }
    
    if ($IsAdd) {
        # Create new entry
        $NewEntry = [PSCustomObject]@{
            EmployeeName = $MatchedName
            'Task Description' = $TaskDescription
            Priority = $Priority
            StartDate = $StartDate
            ETA = $ETA
            Progress = $Progress
            Status = "Active"
            ProgressReportSent = $ProgressReportSent
            FinalReportSent = $FinalReportSent
            Created_Date = $CreatedDate
        }
        
        # Append to CSV
        $TaskFile = "./task_progress_data.csv"
        $NewEntry | Export-Csv -Path $TaskFile -Append -NoTypeInformation
        
        Write-Host "`nTask added successfully!" -ForegroundColor Green
        Write-Host "Employee: $MatchedName | Task: $TaskDescription | Priority: $Priority" -ForegroundColor White
    } else {
        # Create history snapshot before modifying
        Create-HistorySnapshot -Action "MODIFY" -EmployeeName $MatchedName -TaskDescription $SelectedTask.'Task Description'
        
        # Update existing task
        $AllTasks = Import-Csv $TaskFile
        
        # Find and update the specific task
        for ($i = 0; $i -lt $AllTasks.Count; $i++) {
            if ($AllTasks[$i].EmployeeName -eq $MatchedName -and 
                $AllTasks[$i].'Task Description' -eq $SelectedTask.'Task Description' -and
                $AllTasks[$i].StartDate -eq $SelectedTask.StartDate) {
                
                $AllTasks[$i].'Task Description' = $TaskDescription
                $AllTasks[$i].Priority = $Priority
                $AllTasks[$i].StartDate = $StartDate
                $AllTasks[$i].ETA = $ETA
                $AllTasks[$i].Progress = $Progress
                $AllTasks[$i].Status = $Status
                $AllTasks[$i].ProgressReportSent = $ProgressReportSent
                $AllTasks[$i].FinalReportSent = $FinalReportSent
                $AllTasks[$i].Created_Date = $CreatedDate
                break
            }
        }
        
        # Save updated CSV
        $AllTasks | Export-Csv -Path $TaskFile -NoTypeInformation
        
        Write-Host "`nTask updated successfully!" -ForegroundColor Green
        Write-Host "Employee: $MatchedName | Task: $TaskDescription | Priority: $Priority" -ForegroundColor White
    }
}

function Calculate-PersonCapacity {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Person,
        
        [Parameter(Mandatory=$true)]
        [array]$Tasks,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$Week1Start,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$Week1End,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$Week2Start,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$Week2End,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$Week3Start,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$Week3End,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$Week4Start,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$Week4End,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$Week5Start,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$Week5End
    )
    
    # Function to parse date (handle multiple formats)
    function Parse-Date {
        param($DateString)
        if ([string]::IsNullOrWhiteSpace($DateString)) { return $null }
        
        # Use the centralized flexible date parser
        return Parse-FlexibleDate -DateString $DateString
    }
    
    $PersonName = $Person.Name
    $HoursPerWeek = [int]$Person.HoursPerWeek
    
    # Get active tasks for this person
    $PersonTasks = $Tasks | Where-Object { 
        $_.EmployeeName -like "*$PersonName*" -and 
        $_.Progress -ne "100%" 
    }
    
    # Initialize weekly commitments
    $Week1Hours = 0; $Week2Hours = 0; $Week3Hours = 0; $Week4Hours = 0; $Week5Hours = 0
    $Week1Tasks = @(); $Week2Tasks = @(); $Week3Tasks = @(); $Week4Tasks = @(); $Week5Tasks = @()
    
    foreach ($Task in $PersonTasks) {
        $StartDate = Parse-Date $Task.StartDate
        $ETADate = Parse-Date $Task.ETA
        $Progress = [int]($Task.Progress -replace '%', '')
        
        if ($StartDate) {
            # Estimate remaining effort (simple heuristic - to be improved)
            $RemainingProgress = 100 - $Progress
            $EstimatedHoursRemaining = ($RemainingProgress / 100) * ($HoursPerWeek * 2) # Assume 2-week tasks on average
            
            # Distribute across weeks (simplified distribution - to be improved)
            if ($StartDate -le $Week1End) {
                $Week1Hours += [math]::Min($EstimatedHoursRemaining * 0.4, $HoursPerWeek * 0.8)
                $Week1Tasks += $Task.'Task Description'
            }
            if ($StartDate -le $Week2End -and (!$ETADate -or $ETADate -ge $Week2Start)) {
                $Week2Hours += [math]::Min($EstimatedHoursRemaining * 0.3, $HoursPerWeek * 0.6)
                $Week2Tasks += $Task.'Task Description'
            }
            if ($StartDate -le $Week3End -and (!$ETADate -or $ETADate -ge $Week3Start)) {
                $Week3Hours += [math]::Min($EstimatedHoursRemaining * 0.2, $HoursPerWeek * 0.4)
                $Week3Tasks += $Task.'Task Description'
            }
            if ($StartDate -le $Week4End -and (!$ETADate -or $ETADate -ge $Week4Start)) {
                $Week4Hours += [math]::Min($EstimatedHoursRemaining * 0.1, $HoursPerWeek * 0.2)
                $Week4Tasks += $Task.'Task Description'
            }
            if ($StartDate -le $Week5End -and (!$ETADate -or $ETADate -ge $Week5Start)) {
                $Week5Hours += [math]::Min($EstimatedHoursRemaining * 0.05, $HoursPerWeek * 0.1)
                $Week5Tasks += $Task.'Task Description'
            }
        }
    }
    
    # Cap at maximum hours per week
    $Week1Hours = [math]::Min($Week1Hours, $HoursPerWeek)
    $Week2Hours = [math]::Min($Week2Hours, $HoursPerWeek)
    $Week3Hours = [math]::Min($Week3Hours, $HoursPerWeek)
    $Week4Hours = [math]::Min($Week4Hours, $HoursPerWeek)
    $Week5Hours = [math]::Min($Week5Hours, $HoursPerWeek)
    
    # Return capacity data object
    return [PSCustomObject]@{
        Name = $PersonName
        HoursPerWeek = $HoursPerWeek
        Week1Used = [math]::Round($Week1Hours, 1)
        Week1Available = [math]::Round($HoursPerWeek - $Week1Hours, 1)
        Week1Tasks = ($Week1Tasks -join ", ")
        Week2Used = [math]::Round($Week2Hours, 1)
        Week2Available = [math]::Round($HoursPerWeek - $Week2Hours, 1)
        Week2Tasks = ($Week2Tasks -join ", ")
        Week3Used = [math]::Round($Week3Hours, 1)
        Week3Available = [math]::Round($HoursPerWeek - $Week3Hours, 1)
        Week3Tasks = ($Week3Tasks -join ", ")
        Week4Used = [math]::Round($Week4Hours, 1)
        Week4Available = [math]::Round($HoursPerWeek - $Week4Hours, 1)
        Week4Tasks = ($Week4Tasks -join ", ")
        Week5Used = [math]::Round($Week5Hours, 1)
        Week5Available = [math]::Round($HoursPerWeek - $Week5Hours, 1)
        Week5Tasks = ($Week5Tasks -join ", ")
    }
}

function Generate-CapacityPlanningReport {
    $TaskFile = "./task_progress_data.csv"
    $CapacityFile = "./people_and_capacity.csv"
    
    if (-not (Test-Path $TaskFile)) {
        Write-Host "❌ Task file not found: $TaskFile" -ForegroundColor Red
        return
    }
    
    if (-not (Test-Path $CapacityFile)) {
        Write-Host "❌ Capacity file not found: $CapacityFile" -ForegroundColor Red
        return
    }
    
    # Load data
    $Tasks = Import-Csv $TaskFile
    $People = Import-Csv $CapacityFile
    
    # Create reports folder if it doesn't exist
    $ReportsFolder = "./reports"
    if (-not (Test-Path $ReportsFolder)) {
        New-Item -ItemType Directory -Path $ReportsFolder -Force | Out-Null
    }
    
    $ReportFileName = Join-Path $ReportsFolder "Capacity_Planning_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').html"
    $ReportDate = Get-Date -Format "MMMM dd, yyyy 'at' HH:mm"
    $CurrentDate = Get-Date
    
    # Calculate 5 weeks starting from current date (including partial current week)
    # Find the start of current week (Monday)
    $DaysFromMonday = ([int]$CurrentDate.DayOfWeek + 6) % 7  # Convert to Monday = 0
    $CurrentWeekStart = $CurrentDate.AddDays(-$DaysFromMonday).Date
    
    $Week1Start = $CurrentWeekStart
    $Week1End = $CurrentWeekStart.AddDays(6)
    $Week2Start = $CurrentWeekStart.AddDays(7)
    $Week2End = $CurrentWeekStart.AddDays(13)
    $Week3Start = $CurrentWeekStart.AddDays(14)
    $Week3End = $CurrentWeekStart.AddDays(20)
    $Week4Start = $CurrentWeekStart.AddDays(21)
    $Week4End = $CurrentWeekStart.AddDays(27)
    $Week5Start = $CurrentWeekStart.AddDays(28)
    $Week5End = $CurrentWeekStart.AddDays(34)
    
    # Calculate capacity for each person using dedicated function
    $CapacityData = @()
    foreach ($Person in $People) {
        $PersonCapacity = Calculate-PersonCapacity -Person $Person -Tasks $Tasks `
            -Week1Start $Week1Start -Week1End $Week1End `
            -Week2Start $Week2Start -Week2End $Week2End `
            -Week3Start $Week3Start -Week3End $Week3End `
            -Week4Start $Week4Start -Week4End $Week4End `
            -Week5Start $Week5Start -Week5End $Week5End
            
        $CapacityData += $PersonCapacity
    }
    
    # Calculate weekly rankings (top 3 most available people for each week)
    $Week1Rankings = $CapacityData | Sort-Object Week1Available -Descending | Select-Object -First 3
    $Week2Rankings = $CapacityData | Sort-Object Week2Available -Descending | Select-Object -First 3
    $Week3Rankings = $CapacityData | Sort-Object Week3Available -Descending | Select-Object -First 3
    $Week4Rankings = $CapacityData | Sort-Object Week4Available -Descending | Select-Object -First 3
    $Week5Rankings = $CapacityData | Sort-Object Week5Available -Descending | Select-Object -First 3
    
    # Generate HTML
    $HTML = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Capacity Planning Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif; 
            background: #f8f9fa; 
            min-height: 100vh; 
            padding: 8px; 
            color: #2c3e50; 
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 4px;
            box-shadow: 0 2px 6px rgba(0,0,0,0.08);
            overflow: hidden;
        }
        
        .header {
            background: linear-gradient(135deg, #34495e 0%, #2c3e50 100%);
            color: white;
            padding: 10px 15px;
            text-align: center;
        }
        
        .header h1 {
            font-size: 18px;
            margin-bottom: 4px;
            font-weight: 500;
        }
        
        .header p {
            font-size: 11px;
            opacity: 0.9;
            background: rgba(255,255,255,0.1);
            padding: 2px 8px;
            border-radius: 8px;
            display: inline-block;
        }
        
        .content {
            padding: 12px;
        }
        
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
            gap: 8px;
            padding: 12px;
            background: #f8f9fb;
        }
        
        .summary-card {
            background: white;
            padding: 8px 10px;
            border-radius: 4px;
            text-align: center;
            box-shadow: 0 2px 4px rgba(0,0,0,0.06);
            transition: all 0.2s ease;
            border: 1px solid #e9ecef;
        }
        
        .summary-card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 12px rgba(0,0,0,0.1);
        }
        
        .summary-card h3 {
            margin: 0 0 4px 0;
            color: #495057;
            font-size: 10px;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        
        .summary-card .value {
            font-size: 16px;
            font-weight: 700;
            color: #2c3e50;
        }
        
        /* Availability Rankings Styles */
        .availability-rankings {
            margin: 20px 0;
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.06);
            border: 1px solid #e9ecef;
        }
        
        .availability-rankings h2 {
            margin: 0 0 15px 0;
            color: #2c3e50;
            font-size: 18px;
        }
        
        .ranking-cards {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(160px, 200px));
            gap: 12px;
            justify-content: center;
        }
        
        .ranking-card {
            background: #f8f9fa;
            border-radius: 6px;
            padding: 12px;
            text-align: center;
            border: 1px solid #e9ecef;
            transition: all 0.2s ease;
            max-width: 180px;
        }
        
        .ranking-card:hover {
            transform: translateY(-1px);
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
        }
        
        .ranking-card.immediate {
            border-color: #28a745;
            background: #f8fff9;
        }
        
        .ranking-card.first {
            border-color: #ffc107;
            background: #fffdf5;
        }
        
        .ranking-card.second {
            border-color: #6c757d;
            background: #f8f9fa;
        }
        
        .ranking-card.third {
            border-color: #fd7e14;
            background: #fff8f5;
        }
        
        .ranking-card h3 {
            margin: 0 0 6px 0;
            font-size: 12px;
            color: #495057;
        }
        
        .ranking-value {
            font-size: 15px;
            font-weight: 600;
            color: #2c3e50;
            margin-bottom: 4px;
        }
        
        .ranking-subtitle {
            font-size: 10px;
            color: #6c757d;
            font-style: italic;
        }
        
        /* Today Button and Modal Styles */
        .today-btn {
            background: #007bff;
            color: white;
            border: none;
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 10px;
            cursor: pointer;
            transition: background-color 0.2s;
        }
        
        .today-btn:hover {
            background: #0056b3;
        }
        
        .task-modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0,0,0,0.5);
        }
        
        .modal-content {
            background-color: white;
            margin: 5% auto;
            padding: 20px;
            border-radius: 8px;
            width: 80%;
            max-width: 600px;
            max-height: 80vh;
            overflow-y: auto;
        }
        
        .modal-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            border-bottom: 1px solid #e9ecef;
            padding-bottom: 10px;
        }
        
        .modal-close {
            background: none;
            border: none;
            font-size: 24px;
            cursor: pointer;
            color: #6c757d;
        }
        
        .task-list {
            list-style: none;
            padding: 0;
            margin: 0;
        }
        
        .task-item-modal {
            background: #f8f9fa;
            border-left: 4px solid #007bff;
            padding: 12px;
            margin-bottom: 8px;
            border-radius: 4px;
        }
        
        .task-priority-high {
            border-left-color: #dc3545;
        }
        
        .task-priority-medium {
            border-left-color: #ffc107;
        }
        
        .task-priority-low {
            border-left-color: #28a745;
        }
        
        .task-title {
            font-weight: 600;
            color: #2c3e50;
            margin-bottom: 4px;
        }
        
        .task-details {
            font-size: 12px;
            color: #6c757d;
            display: flex;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
        }
        
        .task-progress-bar {
            width: 100%;
            height: 6px;
            background: #e9ecef;
            border-radius: 3px;
            margin-top: 6px;
            overflow: hidden;
        }
        
        .task-progress-fill {
            height: 100%;
            background: #28a745;
            border-radius: 3px;
            transition: width 0.3s ease;
        }
        
        .capacity-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
            background: white;
            border-radius: 4px;
            overflow: hidden;
            box-shadow: 0 2px 4px rgba(0,0,0,0.06);
            border: 1px solid #e9ecef;
        }
        
        .capacity-table th {
            background: #f8f9fb;
            color: #495057;
            padding: 6px 10px;
            text-align: center;
            font-weight: 600;
            font-size: 10px;
            text-transform: uppercase;
            letter-spacing: 0.3px;
            border-bottom: 1px solid #dee2e6;
        }
        
        .capacity-table td {
            padding: 6px 10px;
            text-align: center;
            border-bottom: 1px solid #f1f3f4;
            font-size: 11px;
        }
        
        .capacity-table tr:hover {
            background: #f8f9fa;
        }
        
        .employee-name {
            font-weight: 600;
            color: #2c3e50;
            text-align: left !important;
            padding-left: 12px !important;
            font-size: 12px;
        }
        
        .available {
            color: #27ae60;
            font-weight: bold;
        }
        
        .busy {
            color: #e74c3c;
            font-weight: bold;
        }
        
        .moderate {
            color: #f39c12;
            font-weight: bold;
        }
        
        .task-list {
            font-size: 0.8em;
            color: #666;
            max-width: 150px;
            word-wrap: break-word;
        }
        
        .week-header {
            background: #34495e !important;
            color: white !important;
            position: relative;
        }
        
        .week-rankings {
            font-size: 8px;
            line-height: 1;
            margin-top: 2px;
            color: #ecf0f1;
            opacity: 0.9;
        }
        
        .week-rankings .rank {
            display: block;
            margin: 1px 0;
        }
        
        .week-rankings .rank-1 { color: #f1c40f; font-weight: bold; }
        .week-rankings .rank-2 { color: #bdc3c7; }
        .week-rankings .rank-3 { color: #e67e22; }
        
        .legend {
            margin-top: 10px;
            display: flex;
            justify-content: center;
            gap: 15px;
            flex-wrap: wrap;
            font-size: 11px;
        }
        
        .legend-item {
            display: flex;
            align-items: center;
            gap: 6px;
        }
        
        .legend-color {
            width: 10px;
            height: 10px;
            border-radius: 2px;
        }
        
        .export-buttons {
            margin-top: 15px;
            text-align: center;
            padding: 10px;
            background: #f8f9fb;
            border-top: 1px solid #e9ecef;
        }
        
        .btn {
            background: #34495e;
            color: white;
            border: none;
            padding: 8px 16px;
            margin: 0 5px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            font-weight: 500;
            transition: all 0.2s ease;
        }
        
        .btn:hover {
            background: #2c3e50;
            transform: translateY(-1px);
        }
        
        @media (max-width: 1200px) {
            .capacity-table {
                font-size: 10px;
            }
            
            .capacity-table th,
            .capacity-table td {
                padding: 4px 6px;
            }
        }
        
        @media (max-width: 768px) {
            .container {
                margin: 4px;
                border-radius: 4px;
            }
            
            .header {
                padding: 8px;
            }
            
            .header h1 {
                font-size: 16px;
            }
            
            .content {
                padding: 8px;
            }
            
            .capacity-table {
                display: block;
                overflow-x: auto;
                white-space: nowrap;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Capacity Planning Report</h1>
            <p>Generated on $ReportDate</p>
        </div>
        
        <div class="content">
            <div class="summary">
"@

    # Calculate summary statistics
    $TotalPeople = $CapacityData.Count
    $AvgWeek1Available = ($CapacityData | Measure-Object -Property Week1Available -Average).Average
    $AvgWeek2Available = ($CapacityData | Measure-Object -Property Week2Available -Average).Average
    $AvgWeek3Available = ($CapacityData | Measure-Object -Property Week3Available -Average).Average
    $AvgWeek4Available = ($CapacityData | Measure-Object -Property Week4Available -Average).Average
    $AvgWeek5Available = ($CapacityData | Measure-Object -Property Week5Available -Average).Average
    
    # Calculate most available person based on overall average availability across all weeks
    $CapacityWithOverallAvg = $CapacityData | ForEach-Object {
        $OverallAvg = ($_.Week1Available + $_.Week2Available + $_.Week3Available + $_.Week4Available + $_.Week5Available) / 5
        $_ | Add-Member -NotePropertyName "OverallAvgAvailable" -NotePropertyValue $OverallAvg -PassThru
    }
    
    # Rankings by overall availability
    $AvailabilityRanking = $CapacityWithOverallAvg | Sort-Object OverallAvgAvailable -Descending
    $MostAvailable = $AvailabilityRanking[0].Name
    $SecondMostAvailable = if ($AvailabilityRanking.Count -gt 1) { $AvailabilityRanking[1].Name } else { "N/A" }
    $ThirdMostAvailable = if ($AvailabilityRanking.Count -gt 2) { $AvailabilityRanking[2].Name } else { "N/A" }
    
    # Immediately available (highest Week 1 availability)
    $ImmediatelyAvailable = ($CapacityData | Sort-Object Week1Available -Descending | Select-Object -First 1).Name

    $HTML += @"
                <div class="summary-card">
                    <h3>Team Members</h3>
                    <div class="value">$TotalPeople</div>
                </div>
                <div class="summary-card">
                    <h3>Avg Available (Week 1)</h3>
                    <div class="value">$([math]::Round($AvgWeek1Available, 1))h</div>
                </div>
                <div class="summary-card">
                    <h3>Avg Available (Week 2)</h3>
                    <div class="value">$([math]::Round($AvgWeek2Available, 1))h</div>
                </div>
                <div class="summary-card">
                    <h3>Avg Available (Week 3)</h3>
                    <div class="value">$([math]::Round($AvgWeek3Available, 1))h</div>
                </div>
                <div class="summary-card">
                    <h3>Avg Available (Week 4)</h3>
                    <div class="value">$([math]::Round($AvgWeek4Available, 1))h</div>
                </div>
                <div class="summary-card">
                    <h3>Avg Available (Week 5)</h3>
                    <div class="value">$([math]::Round($AvgWeek5Available, 1))h</div>
                </div>
            </div>
            
            <!-- Availability Rankings Section -->
            <div class="availability-rankings">
                <h2>📊 Availability Rankings</h2>
                <div class="ranking-cards">
                    <div class="ranking-card immediate">
                        <h3>🚀 Immediately Available</h3>
                        <div class="ranking-value">$ImmediatelyAvailable</div>
                        <div class="ranking-subtitle">Highest Week 1 availability</div>
                    </div>
                    <div class="ranking-card first">
                        <h3>🥇 Most Available Overall</h3>
                        <div class="ranking-value">$MostAvailable</div>
                        <div class="ranking-subtitle">Best 4-week average</div>
                    </div>
                    <div class="ranking-card second">
                        <h3>🥈 2nd Most Available</h3>
                        <div class="ranking-value">$SecondMostAvailable</div>
                        <div class="ranking-subtitle">Second best average</div>
                    </div>
                    <div class="ranking-card third">
                        <h3>🥉 3rd Most Available</h3>
                        <div class="ranking-value">$ThirdMostAvailable</div>
                        <div class="ranking-subtitle">Third best average</div>
                    </div>
                </div>
            </div>
            
            <table class="capacity-table">
                <thead>
                    <tr>
                        <th rowspan="2">Employee</th>
                        <th rowspan="2">Hours/Week</th>
                        <th rowspan="2">Today</th>
                        <th colspan="3" class="week-header">
                            Week 1 ($(Get-Date $Week1Start -Format "MMM dd") - $(Get-Date $Week1End -Format "MMM dd"))
                            <div class="week-rankings">
                                <span class="rank rank-1">🥇 $($Week1Rankings[0].Name) ($($Week1Rankings[0].Week1Available)h)</span>
                                <span class="rank rank-2">🥈 $($Week1Rankings[1].Name) ($($Week1Rankings[1].Week1Available)h)</span>
                                <span class="rank rank-3">🥉 $($Week1Rankings[2].Name) ($($Week1Rankings[2].Week1Available)h)</span>
                            </div>
                        </th>
                        <th colspan="3" class="week-header">
                            Week 2 ($(Get-Date $Week2Start -Format "MMM dd") - $(Get-Date $Week2End -Format "MMM dd"))
                            <div class="week-rankings">
                                <span class="rank rank-1">🥇 $($Week2Rankings[0].Name) ($($Week2Rankings[0].Week2Available)h)</span>
                                <span class="rank rank-2">🥈 $($Week2Rankings[1].Name) ($($Week2Rankings[1].Week2Available)h)</span>
                                <span class="rank rank-3">🥉 $($Week2Rankings[2].Name) ($($Week2Rankings[2].Week2Available)h)</span>
                            </div>
                        </th>
                        <th colspan="3" class="week-header">
                            Week 3 ($(Get-Date $Week3Start -Format "MMM dd") - $(Get-Date $Week3End -Format "MMM dd"))
                            <div class="week-rankings">
                                <span class="rank rank-1">🥇 $($Week3Rankings[0].Name) ($($Week3Rankings[0].Week3Available)h)</span>
                                <span class="rank rank-2">🥈 $($Week3Rankings[1].Name) ($($Week3Rankings[1].Week3Available)h)</span>
                                <span class="rank rank-3">🥉 $($Week3Rankings[2].Name) ($($Week3Rankings[2].Week3Available)h)</span>
                            </div>
                        </th>
                        <th colspan="3" class="week-header">
                            Week 4 ($(Get-Date $Week4Start -Format "MMM dd") - $(Get-Date $Week4End -Format "MMM dd"))
                            <div class="week-rankings">
                                <span class="rank rank-1">🥇 $($Week4Rankings[0].Name) ($($Week4Rankings[0].Week4Available)h)</span>
                                <span class="rank rank-2">🥈 $($Week4Rankings[1].Name) ($($Week4Rankings[1].Week4Available)h)</span>
                                <span class="rank rank-3">🥉 $($Week4Rankings[2].Name) ($($Week4Rankings[2].Week4Available)h)</span>
                            </div>
                        </th>
                        <th colspan="3" class="week-header">
                            Week 5 ($(Get-Date $Week5Start -Format "MMM dd") - $(Get-Date $Week5End -Format "MMM dd"))
                            <div class="week-rankings">
                                <span class="rank rank-1">🥇 $($Week5Rankings[0].Name) ($($Week5Rankings[0].Week5Available)h)</span>
                                <span class="rank rank-2">🥈 $($Week5Rankings[1].Name) ($($Week5Rankings[1].Week5Available)h)</span>
                                <span class="rank rank-3">🥉 $($Week5Rankings[2].Name) ($($Week5Rankings[2].Week5Available)h)</span>
                            </div>
                        </th>
                    </tr>
                    <tr>
                        <th>Used</th>
                        <th>Available</th>
                        <th>Tasks</th>
                        <th>Used</th>
                        <th>Available</th>
                        <th>Tasks</th>
                        <th>Used</th>
                        <th>Available</th>
                        <th>Tasks</th>
                        <th>Used</th>
                        <th>Available</th>
                        <th>Tasks</th>
                        <th>Used</th>
                        <th>Available</th>
                        <th>Tasks</th>
                    </tr>
                </thead>
                <tbody>
"@

    foreach ($Person in $CapacityData) {
        # Determine availability classes
        $Week1Class = if ($Person.Week1Available -ge ($Person.HoursPerWeek * 0.7)) { "available" } 
                     elseif ($Person.Week1Available -ge ($Person.HoursPerWeek * 0.3)) { "moderate" } 
                     else { "busy" }
        
        $Week2Class = if ($Person.Week2Available -ge ($Person.HoursPerWeek * 0.7)) { "available" } 
                     elseif ($Person.Week2Available -ge ($Person.HoursPerWeek * 0.3)) { "moderate" } 
                     else { "busy" }
        
        $Week3Class = if ($Person.Week3Available -ge ($Person.HoursPerWeek * 0.7)) { "available" } 
                     elseif ($Person.Week3Available -ge ($Person.HoursPerWeek * 0.3)) { "moderate" } 
                     else { "busy" }
        
        $Week4Class = if ($Person.Week4Available -ge ($Person.HoursPerWeek * 0.7)) { "available" } 
                     elseif ($Person.Week4Available -ge ($Person.HoursPerWeek * 0.3)) { "moderate" } 
                     else { "busy" }

        $Week5Class = if ($Person.Week5Available -ge ($Person.HoursPerWeek * 0.7)) { "available" } 
                     elseif ($Person.Week5Available -ge ($Person.HoursPerWeek * 0.3)) { "moderate" } 
                     else { "busy" }

        $HTML += @"
                    <tr>
                        <td class="employee-name">$($Person.Name)</td>
                        <td>$($Person.HoursPerWeek)h</td>
                        <td><button class="today-btn" onclick="showPersonTasks('$($Person.Name)')">Today</button></td>
                        <td>$($Person.Week1Used)h</td>
                        <td class="$Week1Class">$($Person.Week1Available)h</td>
                        <td class="task-list">$($Person.Week1Tasks)</td>
                        <td>$($Person.Week2Used)h</td>
                        <td class="$Week2Class">$($Person.Week2Available)h</td>
                        <td class="task-list">$($Person.Week2Tasks)</td>
                        <td>$($Person.Week3Used)h</td>
                        <td class="$Week3Class">$($Person.Week3Available)h</td>
                        <td class="task-list">$($Person.Week3Tasks)</td>
                        <td>$($Person.Week4Used)h</td>
                        <td class="$Week4Class">$($Person.Week4Available)h</td>
                        <td class="task-list">$($Person.Week4Tasks)</td>
                        <td>$($Person.Week5Used)h</td>
                        <td class="$Week5Class">$($Person.Week5Available)h</td>
                        <td class="task-list">$($Person.Week5Tasks)</td>
                    </tr>
"@
    }

    $HTML += @"
                </tbody>
            </table>
            
            <div class="legend">
                <div class="legend-item">
                    <div class="legend-color available" style="background: #27ae60;"></div>
                    <span>High Availability (70%+ free)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color moderate" style="background: #f39c12;"></div>
                    <span>Moderate Availability (30-70% free)</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color busy" style="background: #e74c3c;"></div>
                    <span>Low Availability (<30% free)</span>
                </div>
            </div>
            
            <div class="export-buttons">
                <button class="btn" onclick="window.print()">📄 Print/PDF</button>
                <button class="btn" onclick="exportToCSV()">📊 Export CSV</button>
            </div>
        </div>
    </div>
"@

    # Add JavaScript and modal functionality
    $HTML += @"
    
    <!-- DEBUG: JavaScript section started -->
    <script>
        // Task data for modal functionality
        const allTasks = [];
        console.log('JavaScript loaded successfully');
        
        function exportToCSV() {
            const rows = [];
            const table = document.querySelector('.capacity-table');
            
            // Headers
            rows.push(['Employee', 'Hours/Week', 'Week1_Used', 'Week1_Available', 'Week1_Tasks',
                      'Week2_Used', 'Week2_Available', 'Week2_Tasks', 'Week3_Used', 'Week3_Available', 
                      'Week3_Tasks', 'Week4_Used', 'Week4_Available', 'Week4_Tasks']);
            
            // Data rows
            const dataRows = table.querySelectorAll('tbody tr');
            dataRows.forEach(row => {
                const cols = row.querySelectorAll('td');
                const rowData = [];
                cols.forEach(col => rowData.push(col.textContent.trim()));
                rows.push(rowData);
            });
            
            // Create CSV content
            const csvContent = rows.map(row => row.map(field => '"' + field + '"'.replace(/"/g, '""')).join(',')).join('\n');
            
            // Download
            const blob = new Blob([csvContent], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'capacity_planning_$((Get-Date).ToString("yyyy-MM-dd")).csv';
            a.click();
            window.URL.revokeObjectURL(url);
            
            alert('📊 CSV export completed!');
        }
        
        // Modal functionality for task details
        function showPersonTasks(personName) {
            // Find person's tasks
            const personTasks = allTasks.filter(task => 
                task.EmployeeName && task.EmployeeName.toLowerCase() === personName.toLowerCase()
            );
            
            // Sort by priority (1 -> 2 -> 3 -> 4) and then by due date
            personTasks.sort((a, b) => {
                const priorityA = parseInt(a.Priority) || 999;
                const priorityB = parseInt(b.Priority) || 999;
                if (priorityA !== priorityB) return priorityA - priorityB;
                
                // Then by due date (ETA)
                const dueDateA = a.ETA ? new Date(a.ETA) : new Date('9999-12-31');
                const dueDateB = b.ETA ? new Date(b.ETA) : new Date('9999-12-31');
                return dueDateA - dueDateB;
            });
            
            // Convert priority numbers to labels
            const getPriorityLabel = (priority) => {
                switch(priority) {
                    case '1': return 'High';
                    case '2': return 'Medium';
                    case '3': return 'Low';
                    case '4': return 'Very Low';
                    default: return 'None';
                }
            };
            
            // Create modal content
            let modalContent = `
                <h3>📋 `+personName+`'s Current Tasks</h3>
                <div class="task-summary">
                    <span class="task-count">Total Tasks: `+personTasks.length+`</span>
                    <span class="high-priority">High: `+personTasks.filter(t => t.Priority === '1').length+`</span>
                    <span class="medium-priority">Medium: `+personTasks.filter(t => t.Priority === '2').length+`</span>
                    <span class="low-priority">Low: `+personTasks.filter(t => t.Priority === '3' || t.Priority === '4').length+`</span>
                </div>
                <div class="task-list">`;
            
            if (personTasks.length === 0) {
                modalContent += '<div class="no-tasks">🎉 No assigned tasks - fully available!</div>';
            } else {
                personTasks.forEach(task => {
                    const priority = getPriorityLabel(task.Priority);
                    const priorityClass = priority.toLowerCase().replace(' ', '-');
                    const progress = parseInt(task.Progress) || 0;
                    const startDate = task.StartDate ? new Date(task.StartDate).toLocaleDateString() : 'Not set';
                    const dueDate = task.ETA ? new Date(task.ETA).toLocaleDateString() : 'Not set';
                    
                    // Calculate days until due
                    let dueDateInfo = '';
                    if (task.ETA) {
                        const today = new Date();
                        const due = new Date(task.ETA);
                        const diffTime = due - today;
                        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                        
                        if (diffDays < 0) {
                            dueDateInfo = `<span class="overdue">⚠️ `+Math.abs(diffDays)+` days overdue</span>`;
                        } else if (diffDays <= 3) {
                            dueDateInfo = `<span class="urgent">🔥 Due in `+diffDays+` days</span>`;
                        } else {
                            dueDateInfo = `<span class="normal">📅 `+diffDays+` days remaining</span>`;
                        }
                    }
                    
                    modalContent += `
                        <div class="task-item `+priorityClass+`">
                            <div class="task-header">
                                <span class="task-title">`+(task['Task Description'] || 'Unnamed Task')+`</span>
                                <span class="task-priority priority-`+priorityClass+`">`+priority+`</span>
                            </div>
                            <div class="task-dates">
                                <span>📅 Start: `+startDate+`</span>
                                <span>🎯 Due: `+dueDate+`</span>
                                `+dueDateInfo+`
                            </div>
                            <div class="task-progress">
                                <div class="progress-bar">
                                    <div class="progress-fill" style="width: `+progress+`%"></div>
                                </div>
                                <span class="progress-text">`+progress+`% complete</span>
                            </div>
                        </div>`;
                });
            }
            
            modalContent += '</div>';
            
            // Show modal
            document.getElementById('taskModalContent').innerHTML = modalContent;
            document.getElementById('taskModal').style.display = 'flex';
        }
        
        function closeModal() {
            document.getElementById('taskModal').style.display = 'none';
        }
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('taskModal');
            if (event.target === modal) {
                closeModal();
            }
        }
    </script>
    
    <!-- Task Details Modal -->
    <div id="taskModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <span class="close" onclick="closeModal()">&times;</span>
            </div>
            <div id="taskModalContent">
                <!-- Task details will be inserted here -->
            </div>
        </div>
    </div>
"@

    # Add JavaScript and modal functionality  
    $HTML += @"
    
    <!-- DEBUG: JavaScript section started -->
    <script>
        // Task data for modal functionality
        const allTasks = [];
        console.log('JavaScript loaded successfully');
        
        function exportToCSV() {
            const rows = [];
            const table = document.querySelector('.capacity-table');
            
            // Headers
            rows.push(['Employee', 'Hours/Week', 'Week1_Used', 'Week1_Available', 'Week1_Tasks',
                      'Week2_Used', 'Week2_Available', 'Week2_Tasks', 'Week3_Used', 'Week3_Available', 
                      'Week3_Tasks', 'Week4_Used', 'Week4_Available', 'Week4_Tasks']);
            
            // Data rows
            const dataRows = table.querySelectorAll('tbody tr');
            dataRows.forEach(row => {
                const cells = row.querySelectorAll('td');
                const rowData = [];
                cells.forEach((cell, index) => {
                    if (index < cells.length - 1) { // Skip the "Today" button column
                        rowData.push(cell.textContent.trim());
                    }
                });
                if (rowData.length > 0) {
                    rows.push(rowData);
                }
            });
            
            // Create CSV
            const csvContent = rows.map(row => 
                row.map(cell => \`"\${cell.replace(/"/g, '""')}"\`).join(',')
            ).join('\\n');
            
            // Download
            const blob = new Blob([csvContent], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'capacity_planning_$((Get-Date).ToString("yyyy-MM-dd")).csv';
            a.click();
            window.URL.revokeObjectURL(url);
            
            alert('📊 CSV export completed!');
        }
        
        // Generate filtered one-page report for specific person
        function openPersonReport(personName) {
            // Show loading message
            const loadingMsg = document.createElement('div');
            loadingMsg.style.cssText = 'position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); background: white; padding: 30px; border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); z-index: 10000; font-family: Arial, sans-serif; max-width: 500px;';
            loadingMsg.innerHTML = \`
                <div style="text-align: center;">
                    <div style="font-size: 18px; margin-bottom: 15px;">📋 Generate Filtered Report</div>
                    <div style="color: #666; margin-bottom: 15px;">To generate a one-page report filtered for <strong>\${personName}</strong>:</div>
                    <div style="background: #f5f5f5; padding: 15px; border-radius: 4px; font-family: monospace; margin-bottom: 15px; font-size: 12px;">
                        pwsh -Command ". ./helper.ps1; 'filtered \${personName}'; 'exit'"
                    </div>
                    <div style="font-size: 12px; color: #999; margin-bottom: 20px;">Copy and run this command in your terminal</div>
                    <button onclick="document.body.removeChild(this.parentElement.parentElement)" style="background: #007cba; color: white; border: none; padding: 10px 20px; border-radius: 4px; cursor: pointer;">Close</button>
                </div>
            \`;
            document.body.appendChild(loadingMsg);
        }
            const rows = [];
            const table = document.querySelector('.capacity-table');
            
            // Headers
            rows.push(['Employee', 'Hours/Week', 'Week1_Used', 'Week1_Available', 'Week1_Tasks',
                      'Week2_Used', 'Week2_Available', 'Week2_Tasks', 'Week3_Used', 'Week3_Available', 
                      'Week3_Tasks', 'Week4_Used', 'Week4_Available', 'Week4_Tasks']);
            
            // Data rows
            const dataRows = table.querySelectorAll('tbody tr');
            dataRows.forEach(row => {
                const cells = row.querySelectorAll('td');
                const rowData = [];
                cells.forEach((cell, index) => {
                    if (index < cells.length - 1) { // Skip the "Today" button column
                        rowData.push(cell.textContent.trim());
                    }
                });
                if (rowData.length > 0) {
                    rows.push(rowData);
                }
            });
            
            // Create CSV
            const csvContent = rows.map(row => 
                row.map(cell => `"${cell.replace(/"/g, '""')}"`).join(',')
            ).join('\\n');
            
            // Download
            const blob = new Blob([csvContent], { type: 'text/csv' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'capacity_planning_$((Get-Date).ToString("yyyy-MM-dd")).csv';
            a.click();
            window.URL.revokeObjectURL(url);
            
            alert('📊 CSV export completed!');
        }
        
        // Modal functionality for task details
        function showPersonTasks(personName) {
            // Find person's tasks
            const personTasks = allTasks.filter(task => 
                task.EmployeeName && task.EmployeeName.toLowerCase() === personName.toLowerCase()
            );
            
            // Sort by priority (1 -> 2 -> 3 -> 4) and then by due date
            personTasks.sort((a, b) => {
                const priorityA = parseInt(a.Priority) || 999;
                const priorityB = parseInt(b.Priority) || 999;
                if (priorityA !== priorityB) return priorityA - priorityB;
                
                // Then by due date (ETA)
                const dueDateA = a.ETA ? new Date(a.ETA) : new Date('9999-12-31');
                const dueDateB = b.ETA ? new Date(b.ETA) : new Date('9999-12-31');
                return dueDateA - dueDateB;
            });
            
            // Convert priority numbers to labels
            const getPriorityLabel = (priority) => {
                switch(priority) {
                    case '1': return 'High';
                    case '2': return 'Medium';
                    case '3': return 'Low';
                    case '4': return 'Very Low';
                    default: return 'None';
                }
            };
            
            // Create modal content
            let modalContent = `
                <h3>📋 `+personName+`'s Current Tasks</h3>
                <div class="task-summary">
                    <span class="task-count">Total Tasks: `+personTasks.length+`</span>
                    <span class="high-priority">High: `+personTasks.filter(t => t.Priority === '1').length+`</span>
                    <span class="medium-priority">Medium: `+personTasks.filter(t => t.Priority === '2').length+`</span>
                    <span class="low-priority">Low: `+personTasks.filter(t => t.Priority === '3' || t.Priority === '4').length+`</span>
                </div>
                <div class="task-list">`;
            
            if (personTasks.length === 0) {
                modalContent += '<div class="no-tasks">🎉 No assigned tasks - fully available!</div>';
            } else {
                personTasks.forEach(task => {
                    const priority = getPriorityLabel(task.Priority);
                    const priorityClass = priority.toLowerCase().replace(' ', '-');
                    const progress = parseInt(task.Progress) || 0;
                    const startDate = task.StartDate ? new Date(task.StartDate).toLocaleDateString() : 'Not set';
                    const dueDate = task.ETA ? new Date(task.ETA).toLocaleDateString() : 'Not set';
                    
                    // Calculate days until due
                    let dueDateInfo = '';
                    if (task.ETA) {
                        const today = new Date();
                        const due = new Date(task.ETA);
                        const diffTime = due - today;
                        const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
                        
                        if (diffDays < 0) {
                            dueDateInfo = `<span class="overdue">⚠️ `+Math.abs(diffDays)+` days overdue</span>`;
                        } else if (diffDays <= 3) {
                            dueDateInfo = `<span class="urgent">🔥 Due in `+diffDays+` days</span>`;
                        } else {
                            dueDateInfo = `<span class="normal">📅 `+diffDays+` days remaining</span>`;
                        }
                    }
                    
                    modalContent += `
                        <div class="task-item `+priorityClass+`">
                            <div class="task-header">
                                <span class="task-title">`+(task['Task Description'] || 'Unnamed Task')+`</span>
                                <span class="task-priority priority-`+priorityClass+`">`+priority+`</span>
                            </div>
                            <div class="task-dates">
                                <span>📅 Start: `+startDate+`</span>
                                <span>🎯 Due: `+dueDate+`</span>
                                `+dueDateInfo+`
                            </div>
                            <div class="task-progress">
                                <div class="progress-bar">
                                    <div class="progress-fill" style="width: `+progress+`%"></div>
                                </div>
                                <span class="progress-text">`+progress+`% complete</span>
                            </div>
                        </div>`;
                });
            }
            
            modalContent += '</div>';
            
            // Show modal
            document.getElementById('taskModalContent').innerHTML = modalContent;
            document.getElementById('taskModal').style.display = 'flex';
        }
        
        function closeModal() {
            document.getElementById('taskModal').style.display = 'none';
        }
        
        // Close modal when clicking outside
        window.onclick = function(event) {
            const modal = document.getElementById('taskModal');
            if (event.target === modal) {
                closeModal();
            }
        }
    </script>
    
    <!-- Task Details Modal -->
    <div id="taskModal" class="modal">
        <div class="modal-content">
            <div class="modal-header">
                <span class="close" onclick="closeModal()">&times;</span>
            </div>
            <div id="taskModalContent">
                <!-- Task details will be inserted here -->
            </div>
        </div>
    </div>
</body>
</html>
"@

    # Save and open report
    $HTML | Out-File -FilePath $ReportFileName -Encoding UTF8
    
    Write-Host "`n🎯 Capacity Planning Report Generated!" -ForegroundColor Green
    Write-Host "📊 Report: $([System.IO.Path]::GetFileName($ReportFileName))" -ForegroundColor Cyan
    Write-Host "📁 Location: $ReportFileName" -ForegroundColor Blue
    
    # Try to open the file
    try {
        if ($IsWindows) {
            Start-Process $ReportFileName
        } elseif ($IsMacOS) {
            Start-Process "open" -ArgumentList $ReportFileName
        } else {
            Start-Process "xdg-open" -ArgumentList $ReportFileName
        }
        Write-Host "🌐 Opening in default browser..." -ForegroundColor Yellow
    }
    catch {
        Write-Host "📋 Please manually open: $ReportFileName" -ForegroundColor Yellow
    }
}

# Generate filtered one-page report for specific employee
function Generate-FilteredOnePageReport {
    param(
        [Parameter(Mandatory=$true)]
        [string]$EmployeeName
    )
    
    Write-Host "🎯 Generating filtered one-page report for: $EmployeeName" -ForegroundColor Cyan
    
    # Check if one-page-report-generator.ps1 exists
    $OnePageScript = "./one-page-report-generator.ps1"
    if (-not (Test-Path $OnePageScript)) {
        Write-Host "❌ One-page report generator not found: $OnePageScript" -ForegroundColor Red
        return
    }
    
    try {
        # Load and execute the one-page report generator with employee filter
        . $OnePageScript
        $ReportFileName = Generate-OnePageReport -FilterEmployee $EmployeeName
        
        Write-Host "✅ Filtered report generated successfully!" -ForegroundColor Green
        Write-Host "📁 Report location: $ReportFileName" -ForegroundColor Blue
        
        return $ReportFileName
    }
    catch {
        Write-Host "❌ Error generating filtered report: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Excel Export Wrapper Functions
function Invoke-ExcelExportVerbose {
    Export-TaskDataForExcel -Verbose
}

function New-ExcelTaskTemplate {
    param([switch]$OpenAfterCreation)
    
    Write-Host "🚀 Creating Excel Template with VBA Framework - Phase 2..." -ForegroundColor Cyan
    . "$PSScriptRoot/ExcelExport/create_excel_template.ps1"
    
    if ($OpenAfterCreation) {
        New-ExcelTaskTemplate -OpenAfterCreation
    } else {
        New-ExcelTaskTemplate
    }
}

# Function Map with Regex patterns and corresponding function calls
$FunctionMap = @{
    
    # Network Ping
    "^(?:ping|test)\s+(\S+)(?:\s+(\d+)\s*(?:times?))?" = @{
        Function = "Send-NetworkPing"
        Parameters = @("TargetHost", "Count")
    }
    
    # String to Progressive Regex Converter
    "^pattern$" = @{
        Function = "Convert-StringToProgressiveRegex"
        Parameters = @()
    }
    
    # Add Task Progress Entry
    "^task\s+(.+)$" = @{
        Function = "Add-TaskProgressEntry"
        Parameters = @("NamePattern")
    }
    
    # Update Task Priority - Progressive regex for "updatepriority [name]"
    "^u(?:pd?(?:ate?)?)?pr?(?:io?(?:rity?)?)?(.+)" = @{
        Function = "Update-TaskPriority"
        Parameters = @("NamePattern")
    }
    
    # Update Task ETA - Progressive regex for "updateeta [name]"
    "^u(?:pd?(?:ate?)?)?e(?:ta?)?(.+)" = @{
        Function = "Update-ETA"
        Parameters = @("NamePattern")
    }
    
    # Generate HTML Report
    "^report$" = @{
        Function = "Generate-HTMLReport"
        Parameters = @()
    }
    
    # Generate One-Page Banking Report
    "^onepagereport$" = @{
        Function = "Generate-OnePageReport"
        Parameters = @()
    }
    
    # Generate Capacity Planning Report
    "^capacity$" = @{
        Function = "Generate-CapacityPlanningReport"
        Parameters = @()
    }
    
    # Generate Filtered One-Page Report for specific employee
    "^filtered\s+(.+)$" = @{
        Function = "Generate-FilteredOnePageReport"
        Parameters = @("EmployeeName")
    }
    
    # Excel Export - Progressive regex for "excel", "export", "exportexcel"
    "^e(?:x(?:c(?:e(?:l)?)?)?|x(?:p(?:o(?:r(?:t(?:e(?:x(?:c(?:e(?:l)?)?)?)?)?)?)?)?)?)?$" = @{
        Function = "Export-TaskDataForExcel"
        Parameters = @()
    }
    
    # Excel Export with verbose - "excel verbose", "export verbose"
    "^e(?:x(?:c(?:e(?:l)?)?)?|x(?:p(?:o(?:r(?:t)?)?)?)?)\s+v(?:e(?:r(?:b(?:o(?:s(?:e)?)?)?)?)?)?$" = @{
        Function = "Invoke-ExcelExportVerbose"
        Parameters = @()
    }
    
    # Excel Template Creation - "template", "temp"
    "^t(?:e(?:m(?:p(?:l(?:a(?:t(?:e)?)?)?)?)?)?)?$" = @{
        Function = "New-ExcelTaskTemplate"
        Parameters = @("-OpenAfterCreation")
    }
}

# Function to match input against regex patterns and execute corresponding function
function Invoke-FunctionFromInput {
    param(
        [string]$UserInput
    )
    
    $UserInput = $UserInput.Trim()
    $MatchFound = $false
    
    foreach ($Pattern in $FunctionMap.Keys) {
        if ($UserInput -match $Pattern) {
            $MatchFound = $true
            $FunctionInfo = $FunctionMap[$Pattern]
            $FunctionName = $FunctionInfo.Function
            $ParameterNames = $FunctionInfo.Parameters
            
            Write-Host "`nMatched pattern: $Pattern" -ForegroundColor DarkGray
            Write-Host "Calling function: $FunctionName" -ForegroundColor DarkGray
            
            # Build parameters hashtable
            $Parameters = @{}
            for ($i = 0; $i -lt $ParameterNames.Count; $i++) {
                $CaptureGroup = $i + 1
                if ($Matches.Count -gt $CaptureGroup -and $Matches[$CaptureGroup]) {
                    $ParamName = $ParameterNames[$i]
                    $ParamValue = $Matches[$CaptureGroup]
                    $Parameters[$ParamName] = $ParamValue
                    Write-Host "Parameter: $ParamName = $ParamValue" -ForegroundColor DarkGray
                }
            }
            
            # Execute the function
            try {
                Write-Host ("`n" + "="*50) -ForegroundColor White
                & $FunctionName @Parameters
                Write-Host ("="*50) -ForegroundColor White
            }
            catch {
                Write-Error "Error executing function '$FunctionName': $($_.Exception.Message)"
            }
            
            break
        }
    }
    
    if (-not $MatchFound) {
        Write-Host "No matching function found for: '$UserInput'" -ForegroundColor Red

    }
}



# Main execution loop
function Start-InteractiveMode {
    Write-Host "PowerShell Function Dispatcher" -ForegroundColor Green
    Write-Host "Type 'help' for available commands or 'exit' to quit`n" -ForegroundColor Yellow
    
    do {
        Write-Host "How can I help? " -NoNewline -ForegroundColor White
        $UserInput = Read-Host
        
        switch ($UserInput.ToLower().Trim()) {
            "exit" { 
                Write-Host "Goodbye!" -ForegroundColor Green
                return 
            }
            "help" { 
                Show-Help 
            }
            "" { 
                # Do nothing for empty input
            }
            default { 
                Invoke-FunctionFromInput -UserInput $UserInput 
            }
        }
        
        Write-Host # Empty line for readability
    } while ($true)
}

# Start the interactive mode
Start-InteractiveMode