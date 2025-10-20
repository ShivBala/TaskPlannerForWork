# PowerShell Interface for html_console_v10.html - V10 Config Management
# Purpose: Simplified task management for V10 exported configs (with V9 backward compatibility)
# Author: GitHub Copilot
# Date: October 17, 2025

<#
.SYNOPSIS
    Clean PowerShell interface for V10 config file management

.DESCRIPTION
    This script provides a regex-based command interface for managing tasks
    in V10 config files exported from html_console_v10.html. It supports:
    - Quick task add/modify by person name
    - Capacity queries
    - Availability checks
    - V10: Stakeholders and Initiatives management
    - V10: UUID-based task tracking
    - V10: Duplicate detection
    
.NOTES
    V10 Primary - Also supports V9 configs for backward compatibility
    Config files are synced from Downloads to Output folder automatically
#>

# Configuration - Define paths as variables for easy customization
$script:OutputFolderPath = Join-Path $PSScriptRoot "Output"
$script:DownloadsFolderPath = "$HOME/Downloads"

# Import V9 adapter
. "$PSScriptRoot/v9_csv_adapter.ps1"

# Import Person Summary module
. "$PSScriptRoot/person_summary.ps1"

# Global state
$global:V9Config = $null
$global:V9ConfigPath = $null

#region Helper Functions

function Get-FileSHA1Hash {
    <#
    .SYNOPSIS
        Calculates SHA1 hash of a file
    #>
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        return $null
    }
    
    try {
        $sha1 = [System.Security.Cryptography.SHA1]::Create()
        $fileStream = [System.IO.File]::OpenRead($FilePath)
        $hashBytes = $sha1.ComputeHash($fileStream)
        $fileStream.Close()
        
        $hashString = [System.BitConverter]::ToString($hashBytes) -replace '-', ''
        return $hashString
    } catch {
        Write-Host "❌ Error calculating hash for $FilePath : $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Rename-ConfigFileAfterEdit {
    <#
    .SYNOPSIS
        Renames config file to add 'psedited' marker after PowerShell edits
    #>
    param([string]$FilePath)
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "⚠️  File not found for rename: $FilePath" -ForegroundColor Yellow
        return $FilePath
    }
    
    # Skip if already has psedited marker
    if ($FilePath -match '\.psedited\.csv$') {
        return $FilePath
    }
    
    # Insert .psedited before .csv extension
    $newPath = $FilePath -replace '\.csv$', '.psedited.csv'
    
    try {
        Rename-Item -Path $FilePath -NewName (Split-Path $newPath -Leaf) -Force
        Write-Host "📝 File renamed to indicate PS edit: $(Split-Path $newPath -Leaf)" -ForegroundColor Cyan
        
        # Update global config path
        $global:V9ConfigPath = $newPath
        
        return $newPath
    } catch {
        Write-Host "⚠️  Could not rename file: $($_.Exception.Message)" -ForegroundColor Yellow
        return $FilePath
    }
}

function Sync-ConfigFiles {
    <#
    .SYNOPSIS
        Enhanced sync logic with SHA1 validation to detect PS edits
    
    .DESCRIPTION
        Compares Downloads vs Output folders:
        - If Output is newer: Checks if it was edited by PS (compares SHA1 of Downloads vs History backup)
        - If Downloads is newer: Copies to Output
        - Warns user if Output has PS edits not yet imported to HTML
    #>
    param(
        [switch]$Silent
    )
    
    $downloadsPath = $script:DownloadsFolderPath
    $outputPath = $script:OutputFolderPath
    $historyPath = Join-Path (Split-Path $outputPath -Parent) "history"
    
    if (-not $Silent) {
        Write-Host "`n🔄 Syncing config files..." -ForegroundColor Cyan
    }
    
    # Ensure folders exist
    if (-not (Test-Path $outputPath)) {
        New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
    }
    if (-not (Test-Path $historyPath)) {
        New-Item -Path $historyPath -ItemType Directory -Force | Out-Null
    }
    
    # Get latest files from both folders (including .psedited.csv files)
    $downloadsFiles = Get-ChildItem -Path $downloadsPath -Filter "project_config_*.csv" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '_closed_' } |
        Sort-Object LastWriteTime -Descending
    
    $outputFiles = Get-ChildItem -Path $outputPath -Filter "project_config_*.csv" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '_closed_' } |
        Sort-Object LastWriteTime -Descending
    
    # If no files in either location
    if ($downloadsFiles.Count -eq 0 -and $outputFiles.Count -eq 0) {
        if (-not $Silent) {
            Write-Host "⚠️  No project_config files found in Downloads or Output" -ForegroundColor Yellow
            Write-Host "   Please export from html_console_v10.html first" -ForegroundColor Yellow
        }
        return $false
    }
    
    # If no files in Output, copy from Downloads
    if ($outputFiles.Count -eq 0 -and $downloadsFiles.Count -gt 0) {
        $latestDownload = $downloadsFiles[0]
        $destPath = Join-Path $outputPath $latestDownload.Name
        Copy-Item -Path $latestDownload.FullName -Destination $destPath -Force
        if (-not $Silent) {
            Write-Host "✅ Copied from Downloads: $($latestDownload.Name)" -ForegroundColor Green
        }
        return $true
    }
    
    # Compare timestamps
    $latestOutput = $outputFiles[0]
    $latestDownload = if ($downloadsFiles.Count -gt 0) { $downloadsFiles[0] } else { $null }
    
    # If Output is newer than Downloads (or no Downloads file)
    if ($null -eq $latestDownload -or $latestOutput.LastWriteTime -gt $latestDownload.LastWriteTime) {
        if (-not $Silent) {
            Write-Host "📊 Output file is newer than Downloads" -ForegroundColor Cyan
        }
        
        # Check if Output was edited by PowerShell
        # Logic: If Downloads hash == most recent History backup hash, then Output has PS edits
        if ($null -ne $latestDownload) {
            $downloadsHash = Get-FileSHA1Hash -FilePath $latestDownload.FullName
            
            # Get most recent backup file
            $backupFiles = Get-ChildItem -Path $historyPath -Filter "*.backup_*" -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending
            
            if ($backupFiles.Count -gt 0) {
                $latestBackup = $backupFiles[0]
                $backupHash = Get-FileSHA1Hash -FilePath $latestBackup.FullName
                
                if ($downloadsHash -eq $backupHash) {
                    # Output has PS edits not yet imported to HTML
                    Write-Host "" -ForegroundColor Yellow
                    Write-Host "⚠️  WARNING: Output file has PowerShell edits!" -ForegroundColor Yellow
                    Write-Host "   The current Output file was last edited by this PowerShell script." -ForegroundColor Yellow
                    Write-Host "   You should import it to HTML console and test before making more edits." -ForegroundColor Yellow
                    Write-Host "" -ForegroundColor Yellow
                    Write-Host "   Output file: $($latestOutput.Name) (modified: $($latestOutput.LastWriteTime))" -ForegroundColor Gray
                    Write-Host "   Downloads file: $($latestDownload.Name) (modified: $($latestDownload.LastWriteTime))" -ForegroundColor Gray
                    Write-Host "" -ForegroundColor Yellow
                    
                    Write-Host "Continue anyway? (y/n): " -NoNewline -ForegroundColor Yellow
                    $response = Read-Host
                    
                    if ($response -ne 'y' -and $response -ne 'Y') {
                        Write-Host "❌ Sync cancelled. Please import Output file to HTML first." -ForegroundColor Red
                        return $false
                    }
                    
                    Write-Host "✅ Continuing with current Output file" -ForegroundColor Green
                }
            }
        }
        
        if (-not $Silent) {
            Write-Host "✅ Using Output file: $($latestOutput.Name)" -ForegroundColor Green
        }
        return $true
    }
    
    # Downloads is newer - copy to Output
    if (-not $Silent) {
        Write-Host "📥 Downloads file is newer, copying to Output..." -ForegroundColor Cyan
    }
    
    $destPath = Join-Path $outputPath $latestDownload.Name
    Copy-Item -Path $latestDownload.FullName -Destination $destPath -Force
    
    if (-not $Silent) {
        Write-Host "✅ Copied: $($latestDownload.Name)" -ForegroundColor Green
        Write-Host "   From: Downloads (modified: $($latestDownload.LastWriteTime))" -ForegroundColor Gray
        Write-Host "   To: Output" -ForegroundColor Gray
    }
    
    return $true
}

#endregion

#region Core Functions

function Initialize-V9Config {
    <#
    .SYNOPSIS
        Loads the latest V10/V9 config from Output folder (syncing from Downloads if needed)
    #>
    
    Write-Host "`n🔍 Looking for V10/V9 config..." -ForegroundColor Cyan
    
    # Run enhanced sync logic first
    $syncSuccess = Sync-ConfigFiles -Silent
    if (-not $syncSuccess) {
        return $false
    }
    
    # Get latest config file from Output folder
    $configFile = Get-LatestV9ConfigFile
    if ($null -eq $configFile) {
        Write-Host "❌ No V10/V9 config found" -ForegroundColor Red
        Write-Host "   Please export config from html_console_v10.html to Downloads folder first" -ForegroundColor Yellow
        return $false
    }
    
    $config = Read-V9ConfigFile -FilePath $configFile
    if ($null -eq $config) {
        Write-Host "❌ Failed to load config file" -ForegroundColor Red
        return $false
    }
    
    $global:V9Config = $config
    $global:V9ConfigPath = $configFile
    
    # Get projectHoursPerDay from settings (default 8)
    $global:ProjectHoursPerDay = 8
    $hoursPerDaySetting = $config.Settings | Where-Object { $_.Key -eq 'projectHoursPerDay' -or $_.Key -eq 'hoursPerDay' }
    if ($hoursPerDaySetting) {
        $global:ProjectHoursPerDay = [int]$hoursPerDaySetting.Value
    }
    
    # Initialize person availability arrays (8 weeks, default 25 hours/week)
    foreach ($person in $config.People) {
        if (-not $person.Availability) {
            $person.Availability = @(25, 25, 25, 25, 25, 25, 25, 25)
        } elseif ($person.Availability.Count -lt 8) {
            $lastValue = if ($person.Availability.Count -gt 0) { $person.Availability[-1] } else { 25 }
            while ($person.Availability.Count -lt 8) {
                $person.Availability += $lastValue
            }
        } elseif ($person.Availability.Count -gt 8) {
            $person.Availability = $person.Availability[0..7]
        }
    }
    
    Write-Host "✅ Loaded: $(Split-Path $configFile -Leaf)" -ForegroundColor Green
    Write-Host "   📊 $($config.Tickets.Count) tickets | $($config.People.Count) people" -ForegroundColor Cyan
    Write-Host "   ⏰ Project Hours/Day: $global:ProjectHoursPerDay" -ForegroundColor Cyan
    
    # Store file timestamp for change detection
    if (Test-Path $configFile) {
        $global:V9ConfigTimestamp = (Get-Item $configFile).LastWriteTime
    }
    
    return $true
}

function Test-ConfigChanged {
    <#
    .SYNOPSIS
        Checks if the config file has been modified since last load
    #>
    if ($null -eq $global:V9ConfigPath -or -not (Test-Path $global:V9ConfigPath)) {
        return $false
    }
    
    $currentTimestamp = (Get-Item $global:V9ConfigPath).LastWriteTime
    if ($null -eq $global:V9ConfigTimestamp -or $currentTimestamp -gt $global:V9ConfigTimestamp) {
        return $true
    }
    
    return $false
}

function Ensure-ConfigCurrent {
    <#
    .SYNOPSIS
        Reloads config if the CSV file has been modified externally (e.g., by HTML console)
    #>
    if (Test-ConfigChanged) {
        Write-Host "🔄 Config file was modified externally, reloading..." -ForegroundColor Cyan
        Initialize-V9Config
    }
}

function Get-BusinessDays {
    <#
    .SYNOPSIS
        Calculates number of business days between two dates (excluding weekends)
    #>
    param(
        [DateTime]$StartDate,
        [DateTime]$EndDate
    )
    
    $businessDays = 0
    $currentDate = $StartDate
    
    while ($currentDate -le $EndDate) {
        $dayOfWeek = [int]$currentDate.DayOfWeek
        if ($dayOfWeek -ge 1 -and $dayOfWeek -le 5) { # Monday to Friday
            $businessDays++
        }
        $currentDate = $currentDate.AddDays(1)
    }
    
    return $businessDays
}

function Add-BusinessDays {
    <#
    .SYNOPSIS
        Adds specified number of business days to a date
    #>
    param(
        [DateTime]$StartDate,
        [int]$Days
    )
    
    if ($Days -eq 7) {
        Add-Content -Path "debug_filter.txt" -Value "  >>> helper2 Add-BusinessDays: Start=$($StartDate.ToString('yyyy-MM-dd')), Days=$Days"
    }
    
    $currentDate = $StartDate
    $daysAdded = 0
    
    while ($daysAdded -lt $Days) {
        $currentDate = $currentDate.AddDays(1)
        $dayOfWeek = [int]$currentDate.DayOfWeek
        if ($Days -eq 7) {
            Add-Content -Path "debug_filter.txt" -Value "  >>> Loop: currentDate=$($currentDate.ToString('yyyy-MM-dd')), dayOfWeek=$dayOfWeek, daysAdded=$daysAdded"
        }
        if ($dayOfWeek -ge 1 -and $dayOfWeek -le 5) { # Monday to Friday
            $daysAdded++
        }
    }
    
    if ($Days -eq 7) {
        Add-Content -Path "debug_filter.txt" -Value "  >>> helper2 Result: $($currentDate.ToString('yyyy-MM-dd'))"
    }
    
    return $currentDate
}

function Adjust-DateToWeekday {
    <#
    .SYNOPSIS
        Adjusts weekend dates to Monday
    #>
    param([DateTime]$Date)
    
    $dayOfWeek = [int]$Date.DayOfWeek
    if ($dayOfWeek -eq 0) { # Sunday
        return $Date.AddDays(1) # Move to Monday
    } elseif ($dayOfWeek -eq 6) { # Saturday
        return $Date.AddDays(2) # Move to Monday
    }
    return $Date
}

function Get-TaskEffortHours {
    <#
    .SYNOPSIS
        Gets total effort hours for a task size (matches HTML effortMap)
    #>
    param([string]$Size)
    
    $sizeInfo = $global:V9Config.TaskSizes | Where-Object { $_.Key -eq $Size }
    if ($sizeInfo) {
        return [int]$sizeInfo.Days * $global:ProjectHoursPerDay
    }
    return $global:ProjectHoursPerDay # Default to 1 day
}

function Save-V9Config {
    <#
    .SYNOPSIS
        Saves changes back to the V9 config file
    #>
    
    if ($null -eq $global:V9Config -or $null -eq $global:V9ConfigPath) {
        Write-Host "❌ No config loaded" -ForegroundColor Red
        return $false
    }
    
    $success = Write-V9ConfigFile -FilePath $global:V9ConfigPath -ConfigData $global:V9Config -CreateBackup
    
    if ($success) {
        Write-Host "✅ Changes saved!" -ForegroundColor Green
        
        # Rename file to add psedited marker
        $global:V9ConfigPath = Rename-ConfigFileAfterEdit -FilePath $global:V9ConfigPath
        
        return $true
    } else {
        Write-Host "❌ Save failed" -ForegroundColor Red
        return $false
    }
}

#region V10 Management Functions

function Add-Stakeholder {
    <#
    .SYNOPSIS
        Adds a new stakeholder to V10 config
    #>
    param([string]$Name)
    
    if ([string]::IsNullOrWhiteSpace($Name)) {
        Write-Host "❌ Stakeholder name is required" -ForegroundColor Red
        return
    }
    
    if (-not $global:V9Config.Stakeholders) {
        $global:V9Config.Stakeholders = @()
    }
    
    if ($global:V9Config.Stakeholders -contains $Name) {
        Write-Host "❌ Stakeholder '$Name' already exists" -ForegroundColor Red
        return
    }
    
    $global:V9Config.Stakeholders += $Name
    
    if (Save-V9Config) {
        Write-Host "✅ Stakeholder '$Name' added successfully!" -ForegroundColor Green
    }
}

function Add-Initiative {
    <#
    .SYNOPSIS
        Adds a new initiative to V10 config
    #>
    param([string]$Name)
    
    if ([string]::IsNullOrWhiteSpace($Name)) {
        Write-Host "❌ Initiative name is required" -ForegroundColor Red
        return
    }
    
    if (-not $global:V9Config.Initiatives) {
        $global:V9Config.Initiatives = @()
    }
    
    if ($global:V9Config.Initiatives | Where-Object { $_.Name -eq $Name }) {
        Write-Host "❌ Initiative '$Name' already exists" -ForegroundColor Red
        return
    }
    
    $newInitiative = [PSCustomObject]@{
        Name = $Name
        CreationDate = (Get-Date -Format "yyyy-MM-dd")
        StartDate = $null
    }
    
    $global:V9Config.Initiatives += $newInitiative
    
    if (Save-V9Config) {
        Write-Host "✅ Initiative '$Name' added successfully!" -ForegroundColor Green
    }
}

function List-Stakeholders {
    <#
    .SYNOPSIS
        Lists all stakeholders in V10 config
    #>
    
    if (-not $global:V9Config.Stakeholders -or $global:V9Config.Stakeholders.Count -eq 0) {
        Write-Host "No stakeholders found (V9 config or empty)" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n📊 Stakeholders ($($global:V9Config.Stakeholders.Count)):" -ForegroundColor Cyan
    foreach ($sh in $global:V9Config.Stakeholders) {
        $taskCount = ($global:V9Config.Tickets | Where-Object { $_.Stakeholder -eq $sh }).Count
        Write-Host "  👥 $sh ($taskCount tasks)" -ForegroundColor White
    }
}

function List-Initiatives {
    <#
    .SYNOPSIS
        Lists all initiatives in V10 config
    #>
    
    if (-not $global:V9Config.Initiatives -or $global:V9Config.Initiatives.Count -eq 0) {
        Write-Host "No initiatives found (V9 config or empty)" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n📊 Initiatives ($($global:V9Config.Initiatives.Count)):" -ForegroundColor Cyan
    foreach ($init in $global:V9Config.Initiatives) {
        $taskCount = ($global:V9Config.Tickets | Where-Object { $_.Initiative -eq $init.Name }).Count
        $startInfo = if ($init.StartDate) { "starts: $($init.StartDate)" } else { "no start date" }
        Write-Host "  📈 $($init.Name) ($taskCount tasks, created: $($init.CreationDate), $startInfo)" -ForegroundColor White
    }
}

#endregion

function Get-PersonByName {
    <#
    .SYNOPSIS
        Finds a person in the config by name (case-insensitive)
    #>
    param([string]$Name)
    
    return $global:V9Config.People | Where-Object { $_.Name -ieq $Name }
}

function Parse-DateAlias {
    <#
    .SYNOPSIS
        Converts date aliases to YYYY-MM-DD format
    .DESCRIPTION
        Supports: today, tomorrow, yesterday, next/last [day of week]
    #>
    param([string]$DateInput)
    
    if ([string]::IsNullOrWhiteSpace($DateInput)) {
        return ""
    }
    
    $input = $DateInput.Trim().ToLower()
    $today = Get-Date
    
    # Simple aliases
    switch ($input) {
        "today" { return $today.ToString("yyyy-MM-dd") }
        "tomorrow" { return $today.AddDays(1).ToString("yyyy-MM-dd") }
        "yesterday" { return $today.AddDays(-1).ToString("yyyy-MM-dd") }
    }
    
    # Next/Last [day of week]
    if ($input -match "^(next|last)\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)$") {
        $direction = $matches[1]
        $dayName = $matches[2]
        
        # Map day names to DayOfWeek enum
        $dayMap = @{
            "monday" = [DayOfWeek]::Monday
            "tuesday" = [DayOfWeek]::Tuesday
            "wednesday" = [DayOfWeek]::Wednesday
            "thursday" = [DayOfWeek]::Thursday
            "friday" = [DayOfWeek]::Friday
            "saturday" = [DayOfWeek]::Saturday
            "sunday" = [DayOfWeek]::Sunday
        }
        
        $targetDay = $dayMap[$dayName]
        $currentDay = $today.DayOfWeek
        
        if ($direction -eq "next") {
            $daysAhead = ($targetDay - $currentDay + 7) % 7
            if ($daysAhead -eq 0) { $daysAhead = 7 }
            return $today.AddDays($daysAhead).ToString("yyyy-MM-dd")
        } else {
            $daysBehind = ($currentDay - $targetDay + 7) % 7
            if ($daysBehind -eq 0) { $daysBehind = 7 }
            return $today.AddDays(-$daysBehind).ToString("yyyy-MM-dd")
        }
    }
    
    # If it's already a date or unrecognized, return as-is
    return $DateInput
}

#endregion

#region Task Management Functions

function Add-TaskForPerson {
    <#
    .SYNOPSIS
        Adds a new task for a person
    #>
    param([string]$PersonName)
    
    $person = Get-PersonByName -Name $PersonName
    if ($null -eq $person) {
        Write-Host "❌ Person not found: $PersonName" -ForegroundColor Red
        return
    }
    
    Write-Host "`n➕ Adding task for $PersonName" -ForegroundColor Cyan
    
    # Description (required)
    Write-Host "`nDescription: " -NoNewline -ForegroundColor Yellow
    $description = Read-Host
    if ([string]::IsNullOrWhiteSpace($description)) {
        Write-Host "❌ Description is required" -ForegroundColor Red
        return
    }
    
    # Status (required)
    Write-Host "`nStatus:" -ForegroundColor Yellow
    Write-Host "  1. To Do" -ForegroundColor White
    Write-Host "  2. In Progress" -ForegroundColor White
    Write-Host "Choose (1/2): " -NoNewline -ForegroundColor Yellow
    $statusChoice = Read-Host
    
    $status = switch ($statusChoice) {
        "1" { "To Do" }
        "2" { "In Progress" }
        default { "To Do" }
    }
    
    # Start date (conditional default)
    $defaultStartDate = if ($status -eq "In Progress") { "today" } else { "tomorrow" }
    Write-Host "`nStart date (today/tomorrow/next wednesday, default: $defaultStartDate): " -NoNewline -ForegroundColor Yellow
    $startDateInput = Read-Host
    if ([string]::IsNullOrWhiteSpace($startDateInput)) {
        $startDateInput = $defaultStartDate
    }
    $startDate = Parse-DateAlias -DateInput $startDateInput
    
    # Size (default M)
    Write-Host "`nTask Size:" -ForegroundColor Yellow
    $sizeIndex = 1
    $sizeMap = @{}
    foreach ($size in $global:V9Config.TaskSizes) {
        Write-Host "  [$sizeIndex] $($size.Key) - $($size.Name) ($($size.Days) days)" -ForegroundColor White
        $sizeMap[$sizeIndex.ToString()] = $size.Key
        $sizeIndex++
    }
    
    # Find the default index for 'M'
    $defaultIndex = ($global:V9Config.TaskSizes | ForEach-Object -Begin { $i = 1 } -Process { 
        if ($_.Key -eq 'M') { $i }; $i++ 
    } | Select-Object -First 1)
    
    Write-Host "Choose (1-$($global:V9Config.TaskSizes.Count), or press Enter for M): " -NoNewline -ForegroundColor Yellow
    $sizeInput = Read-Host
    
    if ([string]::IsNullOrWhiteSpace($sizeInput)) {
        $size = "M"  # Default
    } elseif ($sizeMap.ContainsKey($sizeInput)) {
        $size = $sizeMap[$sizeInput]
    } else {
        Write-Host "⚠️  Invalid choice, using default (M)" -ForegroundColor Yellow
        $size = "M"
    }
    
    # Generate new ID
    $maxId = ($global:V9Config.Tickets | ForEach-Object { [int]$_.ID } | Measure-Object -Maximum).Maximum
    $newId = $maxId + 1
    
    # V10: Generate UUID
    $uuid = [guid]::NewGuid().ToString()
    
    # V10: Stakeholder selection (if V10 config)
    Ensure-ConfigCurrent  # Auto-reload if CSV was modified externally
    $stakeholder = "General"  # Default
    if ($global:V9Config.Stakeholders -and $global:V9Config.Stakeholders.Count -gt 0) {
        Write-Host "`nAvailable Stakeholders:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $global:V9Config.Stakeholders.Count; $i++) {
            Write-Host "  $($i + 1). $($global:V9Config.Stakeholders[$i])" -ForegroundColor White
        }
        Write-Host "Choose stakeholder (1-$($global:V9Config.Stakeholders.Count), or press Enter for General): " -NoNewline -ForegroundColor Yellow
        $stakeholderChoice = Read-Host
        if (-not [string]::IsNullOrWhiteSpace($stakeholderChoice) -and $stakeholderChoice -match '^\d+$') {
            $index = [int]$stakeholderChoice - 1
            if ($index -ge 0 -and $index -lt $global:V9Config.Stakeholders.Count) {
                $stakeholder = $global:V9Config.Stakeholders[$index]
            }
        }
    }
    
    # V10: Initiative selection (if V10 config)
    Ensure-ConfigCurrent  # Auto-reload if CSV was modified externally
    $initiative = "General"  # Default
    if ($global:V9Config.Initiatives -and $global:V9Config.Initiatives.Count -gt 0) {
        Write-Host "`nAvailable Initiatives:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $global:V9Config.Initiatives.Count; $i++) {
            $init = $global:V9Config.Initiatives[$i]
            $startInfo = if ($init.StartDate) { " (starts: $($init.StartDate))" } else { " (no start date yet)" }
            Write-Host "  $($i + 1). $($init.Name)$startInfo" -ForegroundColor White
        }
        Write-Host "Choose initiative (1-$($global:V9Config.Initiatives.Count), or press Enter for General): " -NoNewline -ForegroundColor Yellow
        $initiativeChoice = Read-Host
        if (-not [string]::IsNullOrWhiteSpace($initiativeChoice) -and $initiativeChoice -match '^\d+$') {
            $index = [int]$initiativeChoice - 1
            if ($index -ge 0 -and $index -lt $global:V9Config.Initiatives.Count) {
                $initiative = $global:V9Config.Initiatives[$index].Name
            }
        }
    }
    
    # Create new ticket (V10-aware)
    $newTicket = [PSCustomObject]@{
        ID = $newId
        Description = $description
        StartDate = $startDate
        Size = $size
        Priority = "P2"  # Default priority
        AssignedTeam = @($PersonName)
        Status = $status
        TaskType = "Fixed"  # Default task type
        PauseComments = ""
        StartDateHistory = ""
        EndDateHistory = ""
        SizeHistory = ""
        CustomEndDate = ""
        DetailsDescription = ""
        DetailsPositives = ""
        DetailsNegatives = ""
    }
    
    # Add V10 fields if this is a V10 config
    $isV10 = $global:V9Config.Tickets.Count -gt 0 -and 
             ($global:V9Config.Tickets[0].PSObject.Properties.Name -contains 'UUID')
    
    if ($isV10 -or $global:V9Config.Stakeholders.Count -gt 0 -or $global:V9Config.Initiatives.Count -gt 0) {
        $newTicket | Add-Member -NotePropertyName 'UUID' -NotePropertyValue $uuid
        $newTicket | Add-Member -NotePropertyName 'Stakeholder' -NotePropertyValue $stakeholder
        $newTicket | Add-Member -NotePropertyName 'Initiative' -NotePropertyValue $initiative
    }
    
    # Add to config
    $global:V9Config.Tickets += $newTicket
    
    # Save
    if (Save-V9Config) {
        Write-Host "`n✅ Task #$newId added successfully!" -ForegroundColor Green
        Write-Host "   $description" -ForegroundColor Cyan
        Write-Host "   Status: $status | Size: $size | Start: $startDate" -ForegroundColor Gray
        if ($newTicket.PSObject.Properties.Name -contains 'UUID') {
            Write-Host "   Stakeholder: $stakeholder | Initiative: $initiative" -ForegroundColor Gray
            Write-Host "   UUID: $uuid" -ForegroundColor DarkGray
        }
    }
}

function Add-QuickTask {
    <#
    .SYNOPSIS
        Adds a quick task with minimal prompts (description + stakeholder only)
    .DESCRIPTION
        Quick task creation with smart defaults:
        - Assigned Person: Unassigned (empty array)
        - Initiative: General
        - Status: To Do
        - Start Date: Tomorrow
        - Size: M (Medium)
        - Priority: P2
    #>
    
    Write-Host "`n⚡ Quick Task (minimal setup)" -ForegroundColor Cyan
    
    # Description (required)
    Write-Host "`nDescription: " -NoNewline -ForegroundColor Yellow
    $description = Read-Host
    if ([string]::IsNullOrWhiteSpace($description)) {
        Write-Host "❌ Description is required" -ForegroundColor Red
        return
    }
    
    # Stakeholder selection (required)
    Ensure-ConfigCurrent  # Auto-reload if CSV was modified externally
    $stakeholder = "General"  # Default
    if ($global:V9Config.Stakeholders -and $global:V9Config.Stakeholders.Count -gt 0) {
        Write-Host "`nStakeholder:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $global:V9Config.Stakeholders.Count; $i++) {
            Write-Host "  $($i + 1). $($global:V9Config.Stakeholders[$i])" -ForegroundColor White
        }
        Write-Host "Choose (1-$($global:V9Config.Stakeholders.Count), or press Enter for General): " -NoNewline -ForegroundColor Yellow
        $stakeholderChoice = Read-Host
        if (-not [string]::IsNullOrWhiteSpace($stakeholderChoice) -and $stakeholderChoice -match '^\d+$') {
            $index = [int]$stakeholderChoice - 1
            if ($index -ge 0 -and $index -lt $global:V9Config.Stakeholders.Count) {
                $stakeholder = $global:V9Config.Stakeholders[$index]
            }
        }
    }
    
    # All defaults (no prompts)
    $status = "To Do"
    $startDate = Parse-DateAlias -DateInput "tomorrow"
    $size = "M"
    $priority = "P2"
    $initiative = "General"
    $assignedTeam = @()  # Unassigned - empty array for filtering in HTML
    
    # Generate new ID
    $maxId = ($global:V9Config.Tickets | ForEach-Object { [int]$_.ID } | Measure-Object -Maximum).Maximum
    $newId = $maxId + 1
    
    # Generate UUID
    $uuid = [guid]::NewGuid().ToString()
    
    # Create new ticket
    $newTicket = [PSCustomObject]@{
        ID = $newId
        Description = $description
        StartDate = $startDate
        Size = $size
        Priority = $priority
        AssignedTeam = $assignedTeam  # Unassigned
        Status = $status
        TaskType = "Fixed"
        PauseComments = ""
        StartDateHistory = ""
        EndDateHistory = ""
        SizeHistory = ""
        CustomEndDate = ""
        DetailsDescription = ""
        DetailsPositives = ""
        DetailsNegatives = ""
    }
    
    # Add V10 fields
    $isV10 = $global:V9Config.Tickets.Count -gt 0 -and 
             ($global:V9Config.Tickets[0].PSObject.Properties.Name -contains 'UUID')
    
    if ($isV10 -or $global:V9Config.Stakeholders.Count -gt 0 -or $global:V9Config.Initiatives.Count -gt 0) {
        $newTicket | Add-Member -NotePropertyName 'UUID' -NotePropertyValue $uuid
        $newTicket | Add-Member -NotePropertyName 'Stakeholder' -NotePropertyValue $stakeholder
        $newTicket | Add-Member -NotePropertyName 'Initiative' -NotePropertyValue $initiative
    }
    
    # Add to config
    $global:V9Config.Tickets += $newTicket
    
    # Save
    if (Save-V9Config) {
        # Get size days from config
        $sizeInfo = $global:V9Config.TaskSizes | Where-Object { $_.Key -eq $size } | Select-Object -First 1
        $sizeDays = if ($sizeInfo) { $sizeInfo.Days } else { "?" }
        
        Write-Host "`n✅ Quick task #$newId added!" -ForegroundColor Green
        Write-Host "   $description" -ForegroundColor Cyan
        Write-Host "   Status: $status | Size: $size ($sizeDays days) | Priority: $priority | Start: $startDate" -ForegroundColor Gray
        Write-Host "   Stakeholder: $stakeholder | Initiative: $initiative | Assigned: Unassigned" -ForegroundColor Gray
        Write-Host "   UUID: $uuid" -ForegroundColor DarkGray
    }
}

function Modify-TaskForPerson {
    <#
    .SYNOPSIS
        Modifies an existing task for a person
    #>
    param([string]$PersonName)
    
    $person = Get-PersonByName -Name $PersonName
    if ($null -eq $person) {
        Write-Host "❌ Person not found: $PersonName" -ForegroundColor Red
        return
    }
    
    # Get active tasks for this person
    $tasks = $global:V9Config.Tickets | Where-Object {
        $_.AssignedTeam -contains $PersonName -and $_.Status -ne 'Closed'
    } | Sort-Object { [int]$_.Priority.Replace('P', '') }
    
    if ($tasks.Count -eq 0) {
        Write-Host "❌ No active tasks found for $PersonName" -ForegroundColor Yellow
        return
    }
    
    # Show tasks
    Write-Host "`n📋 Active tasks for $PersonName" -ForegroundColor Cyan
    for ($i = 0; $i -lt $tasks.Count; $i++) {
        $task = $tasks[$i]
        Write-Host "  $($i + 1). [$($task.Priority)] $($task.Description) - $($task.Status)" -ForegroundColor White
    }
    
    Write-Host "`nSelect task (1-$($tasks.Count)): " -NoNewline -ForegroundColor Yellow
    $selection = Read-Host
    
    try {
        $index = [int]$selection - 1
        if ($index -lt 0 -or $index -ge $tasks.Count) {
            throw "Invalid selection"
        }
        
        $selectedTask = $tasks[$index]
        
        # Show modification menu
        Write-Host "`n📝 Modifying: $($selectedTask.Description)" -ForegroundColor Cyan
        Write-Host "`nWhat to update?" -ForegroundColor Yellow
        Write-Host "  1. Status" -ForegroundColor White
        Write-Host "  2. Priority" -ForegroundColor White
        Write-Host "  3. Size" -ForegroundColor White
        Write-Host "  4. Description" -ForegroundColor White
        Write-Host "Choose (1-4): " -NoNewline -ForegroundColor Yellow
        $updateChoice = Read-Host
        
        switch ($updateChoice) {
            "1" {
                Write-Host "`nNew Status:" -ForegroundColor Yellow
                Write-Host "  1. To Do" -ForegroundColor White
                Write-Host "  2. In Progress" -ForegroundColor White
                Write-Host "  3. Completed" -ForegroundColor White
                Write-Host "  4. Blocked" -ForegroundColor White
                Write-Host "  5. Closed" -ForegroundColor White
                Write-Host "Choose (1-5): " -NoNewline -ForegroundColor Yellow
                $statusChoice = Read-Host
                
                $newStatus = switch ($statusChoice) {
                    "1" { "To Do" }
                    "2" { "In Progress" }
                    "3" { "Completed" }
                    "4" { "Blocked" }
                    "5" { "Closed" }
                    default { $selectedTask.Status }
                }
                
                $selectedTask.Status = $newStatus
                Write-Host "✅ Status updated to: $newStatus" -ForegroundColor Green
            }
            "2" {
                Write-Host "`nPriority (current: $($selectedTask.Priority)):" -ForegroundColor Yellow
                Write-Host "  1. P1 (Highest)" -ForegroundColor White
                Write-Host "  2. P2 (High)" -ForegroundColor White
                Write-Host "  3. P3 (Medium)" -ForegroundColor White
                Write-Host "  4. P4 (Low)" -ForegroundColor White
                Write-Host "  5. P5 (Lowest)" -ForegroundColor White
                Write-Host "Choose (1-5, or press Enter to keep current): " -NoNewline -ForegroundColor Yellow
                $priorityChoice = Read-Host
                
                if (-not [string]::IsNullOrWhiteSpace($priorityChoice) -and $priorityChoice -match '^[1-5]$') {
                    $newPriority = "P$priorityChoice"
                    $selectedTask.Priority = $newPriority
                    Write-Host "✅ Priority updated to: $newPriority" -ForegroundColor Green
                } elseif (-not [string]::IsNullOrWhiteSpace($priorityChoice)) {
                    Write-Host "❌ Invalid choice. Priority not changed." -ForegroundColor Red
                }
            }
            "3" {
                Write-Host "`nAvailable sizes:" -ForegroundColor Yellow
                foreach ($size in $global:V9Config.TaskSizes) {
                    Write-Host "  $($size.Key) - $($size.Name): $($size.Days) days" -ForegroundColor White
                }
                Write-Host "New size (current: $($selectedTask.Size)): " -NoNewline -ForegroundColor Yellow
                $newSize = Read-Host
                if (-not [string]::IsNullOrWhiteSpace($newSize)) {
                    $selectedTask.Size = $newSize
                    Write-Host "✅ Size updated to: $newSize" -ForegroundColor Green
                }
            }
            "4" {
                Write-Host "`nNew description: " -NoNewline -ForegroundColor Yellow
                $newDesc = Read-Host
                if (-not [string]::IsNullOrWhiteSpace($newDesc)) {
                    $selectedTask.Description = $newDesc
                    Write-Host "✅ Description updated" -ForegroundColor Green
                }
            }
            default {
                Write-Host "❌ Invalid choice" -ForegroundColor Red
                return
            }
        }
        
        # Save changes
        Save-V9Config
        
    } catch {
        Write-Host "❌ Invalid selection" -ForegroundColor Red
    }
}

function Show-WeeklyCapacity {
    <#
    .SYNOPSIS
        Shows capacity for current week (matches HTML calculation exactly)
    .DESCRIPTION
        Uses hours-based calculation with business days and overlap detection
    #>
    param([string]$PersonName)
    
    $person = Get-PersonByName -Name $PersonName
    if ($null -eq $person) {
        Write-Host "❌ Person not found: $PersonName" -ForegroundColor Red
        return
    }
    
    # Get current week bounds (Monday to Sunday)
    $today = Get-Date
    $daysFromMonday = ([int]$today.DayOfWeek + 6) % 7 # Distance from Monday
    $weekStart = $today.AddDays(-$daysFromMonday).Date
    $weekEnd = $weekStart.AddDays(6)
    
    Write-Host "`n📊 Weekly Capacity for $PersonName" -ForegroundColor Cyan
    Write-Host "   Week: $($weekStart.ToString('MMM dd')) - $($weekEnd.ToString('MMM dd, yyyy'))" -ForegroundColor Gray
    
    # Get person's availability for current week (week index 0)
    $weeklyAvailability = if ($person.Availability -and $person.Availability.Count -gt 0) {
        [double]$person.Availability[0]
    } else {
        $global:ProjectHoursPerDay * 5 # Default to 5 days
    }
    
    Write-Host "`n   Total Capacity: $weeklyAvailability hours/week" -ForegroundColor White
    
    # Calculate assigned hours for this week (matching HTML logic)
    $assignedHours = 0
    $activeTasksList = @()
    
    # Get active tickets
    $activeTickets = $global:V9Config.Tickets | Where-Object {
        $_.AssignedTeam -contains $PersonName -and 
        $_.Status -notin @('Closed', 'Completed') -and
        ![string]::IsNullOrWhiteSpace($_.StartDate)
    }
    
    foreach ($ticket in $activeTickets) {
        $taskStart = [DateTime]::ParseExact($ticket.StartDate, 'yyyy-MM-dd', $null)
        
        # Check if Fixed-Length or Flexible (default to Fixed)
        $isFixedLength = $ticket.TaskType -ne 'Flexible'
        
        # Get task size info
        $sizeInfo = $global:V9Config.TaskSizes | Where-Object { $_.Key -eq $ticket.Size }
        $totalTaskDays = if ($sizeInfo) { [int]$sizeInfo.Days } else { 1 }
        $totalTaskEffort = Get-TaskEffortHours -Size $ticket.Size
        
        # Calculate task end date and daily hours per person
        $taskEnd = $null
        $dailyHoursForPerson = 0
        $numAssignees = [Math]::Max($ticket.AssignedTeam.Count, 1)
        
        if ($isFixedLength) {
            # Fixed-Length: Duration stays same, capacity scales
            $taskEnd = Add-BusinessDays -StartDate $taskStart -Days ($totalTaskDays - 1)
            $dailyHoursForPerson = $totalTaskEffort / ($totalTaskDays * $numAssignees)
        } else {
            # Flexible: Duration splits among assignees
            $daysPerPerson = [Math]::Ceiling($totalTaskDays / $numAssignees)
            $taskEnd = Add-BusinessDays -StartDate $taskStart -Days ($daysPerPerson - 1)
            $dailyHoursForPerson = $global:ProjectHoursPerDay
        }
        
        # Adjust start date if on weekend
        $taskStart = Adjust-DateToWeekday -Date $taskStart
        
        # Check if task overlaps with this week
        if ($taskStart -le $weekEnd -and $taskEnd -ge $weekStart) {
            # Calculate overlap period
            $overlapStart = if ($taskStart -gt $weekStart) { $taskStart } else { $weekStart }
            $overlapEnd = if ($taskEnd -lt $weekEnd) { $taskEnd } else { $weekEnd }
            
            # Calculate business days in overlap
            $businessDays = Get-BusinessDays -StartDate $overlapStart -EndDate $overlapEnd
            
            # Assign hours
            $taskHours = $dailyHoursForPerson * $businessDays
            $assignedHours += $taskHours
            
            $activeTasksList += [PSCustomObject]@{
                Description = $ticket.Description
                Priority = $ticket.Priority
                Size = $ticket.Size
                Status = $ticket.Status
                Hours = [Math]::Round($taskHours, 1)
                Days = $totalTaskDays
            }
        }
    }
    
    # Calculate utilization
    $availableHours = $weeklyAvailability - $assignedHours
    $utilizationPct = if ($weeklyAvailability -gt 0) {
        [Math]::Round(($assignedHours / $weeklyAvailability) * 100, 1)
    } elseif ($assignedHours -gt 0) {
        999 # Overload indicator
    } else {
        0
    }
    
    # Determine color
    $utilizationColor = if ($utilizationPct -ge 999 -or $utilizationPct -gt 90) {
        "Red"
    } elseif ($utilizationPct -gt 60) {
        "Yellow"
    } else {
        "Green"
    }
    
    Write-Host "   Assigned: $([Math]::Round($assignedHours, 1)) hours ($($activeTasksList.Count) tasks)" -ForegroundColor Yellow
    Write-Host "   Available: $([Math]::Round($availableHours, 1)) hours" -ForegroundColor $(if ($availableHours -gt 0) { "Green" } else { "Red" })
    Write-Host "   Utilization: $utilizationPct%" -ForegroundColor $utilizationColor
    
    # Show active tasks
    if ($activeTasksList.Count -gt 0) {
        Write-Host "`n   Active Tasks:" -ForegroundColor Cyan
        foreach ($task in $activeTasksList) {
            Write-Host "     [$($task.Priority)] $($task.Description) ($($task.Hours)h, $($task.Status))" -ForegroundColor White
        }
    }
}

function Show-MostAvailable {
    <#
    .SYNOPSIS
        Shows who is most available today to pick up a task (matches HTML calculation)
    #>
    
    Write-Host "`n👥 Team Availability (Current Week)" -ForegroundColor Cyan
    Write-Host "   $(Get-Date -Format 'dddd, MMMM dd, yyyy')" -ForegroundColor Gray
    
    # Get current week bounds
    $today = Get-Date
    $daysFromMonday = ([int]$today.DayOfWeek + 6) % 7
    $weekStart = $today.AddDays(-$daysFromMonday).Date
    $weekEnd = $weekStart.AddDays(6)
    
    $availability = @()
    
    foreach ($person in $global:V9Config.People) {
        # Get person's availability for current week (index 0)
        $weeklyAvailability = if ($person.Availability -and $person.Availability.Count -gt 0) {
            [double]$person.Availability[0]
        } else {
            $global:ProjectHoursPerDay * 5
        }
        
        # Calculate assigned hours using same logic as HTML
        $assignedHours = 0
        $activeTaskCount = 0
        
        $activeTickets = $global:V9Config.Tickets | Where-Object {
            $_.AssignedTeam -contains $person.Name -and 
            $_.Status -notin @('Closed', 'Completed') -and
            ![string]::IsNullOrWhiteSpace($_.StartDate)
        }
        
        foreach ($ticket in $activeTickets) {
            $taskStart = [DateTime]::ParseExact($ticket.StartDate, 'yyyy-MM-dd', $null)
            
            $isFixedLength = $ticket.TaskType -ne 'Flexible'
            $sizeInfo = $global:V9Config.TaskSizes | Where-Object { $_.Key -eq $ticket.Size }
            $totalTaskDays = if ($sizeInfo) { [int]$sizeInfo.Days } else { 1 }
            $totalTaskEffort = Get-TaskEffortHours -Size $ticket.Size
            
            $taskEnd = $null
            $dailyHoursForPerson = 0
            $numAssignees = [Math]::Max($ticket.AssignedTeam.Count, 1)
            
            if ($isFixedLength) {
                $taskEnd = Add-BusinessDays -StartDate $taskStart -Days ($totalTaskDays - 1)
                $dailyHoursForPerson = $totalTaskEffort / ($totalTaskDays * $numAssignees)
            } else {
                $daysPerPerson = [Math]::Ceiling($totalTaskDays / $numAssignees)
                $taskEnd = Add-BusinessDays -StartDate $taskStart -Days ($daysPerPerson - 1)
                $dailyHoursForPerson = $global:ProjectHoursPerDay
            }
            
            $taskStart = Adjust-DateToWeekday -Date $taskStart
            
            # Check overlap with current week
            if ($taskStart -le $weekEnd -and $taskEnd -ge $weekStart) {
                $overlapStart = if ($taskStart -gt $weekStart) { $taskStart } else { $weekStart }
                $overlapEnd = if ($taskEnd -lt $weekEnd) { $taskEnd } else { $weekEnd }
                
                $businessDays = Get-BusinessDays -StartDate $overlapStart -EndDate $overlapEnd
                $assignedHours += $dailyHoursForPerson * $businessDays
                $activeTaskCount++
            }
        }
        
        # Calculate utilization
        $availableHours = $weeklyAvailability - $assignedHours
        $utilizationPct = if ($weeklyAvailability -gt 0) {
            [Math]::Round(($assignedHours / $weeklyAvailability) * 100, 1)
        } elseif ($assignedHours -gt 0) {
            999
        } else {
            0
        }
        
        $availability += [PSCustomObject]@{
            Name = $person.Name
            TotalCapacity = [Math]::Round($weeklyAvailability, 1)
            Assigned = [Math]::Round($assignedHours, 1)
            Available = [Math]::Round($availableHours, 1)
            Utilization = $utilizationPct
            ActiveTasks = $activeTaskCount
        }
    }
    
    # Sort by available hours (descending)
    $availability = $availability | Sort-Object Available -Descending
    
    Write-Host ""
    foreach ($person in $availability) {
        $availColor = if ($person.Available -gt 0) { "Green" } else { "Red" }
        $utilColor = if ($person.Utilization -ge 999 -or $person.Utilization -gt 90) {
            "Red"
        } elseif ($person.Utilization -gt 60) {
            "Yellow"
        } else {
            "Green"
        }
        
        Write-Host "   $($person.Name.PadRight(15)) " -NoNewline -ForegroundColor White
        Write-Host "Available: $($person.Available)h/$($person.TotalCapacity)h " -NoNewline -ForegroundColor $availColor
        Write-Host "($($person.Utilization)% utilized, $($person.ActiveTasks) tasks)" -ForegroundColor $utilColor
    }
    
    # Highlight most available
    $mostAvailable = $availability[0]
    $utilColor = if ($mostAvailable.Utilization -ge 999 -or $mostAvailable.Utilization -gt 90) {
        "Red"
    } elseif ($mostAvailable.Utilization -gt 60) {
        "Yellow"
    } else {
        "Cyan"
    }
    Write-Host "`n   🌟 Most Available: $($mostAvailable.Name) ($($mostAvailable.Available)h free, $($mostAvailable.Utilization)% utilized)" -ForegroundColor $utilColor
}

function Manage-Stakeholders {
    <#
    .SYNOPSIS
        Interactive stakeholder management for V10 config
    #>
    
    # First, list current stakeholders
    List-Stakeholders
    
    Write-Host "`n📝 Stakeholder Management" -ForegroundColor Cyan
    Write-Host "  1. Add new stakeholder" -ForegroundColor White
    Write-Host "  2. Remove stakeholder" -ForegroundColor White
    Write-Host "  3. Cancel" -ForegroundColor White
    Write-Host "`nChoose (1/2/3): " -NoNewline -ForegroundColor Yellow
    $choice = Read-Host
    
    switch ($choice) {
        "1" {
            # Add stakeholder
            Write-Host "`nEnter stakeholder name: " -NoNewline -ForegroundColor Yellow
            $name = Read-Host
            if (-not [string]::IsNullOrWhiteSpace($name)) {
                Add-Stakeholder -Name $name
            } else {
                Write-Host "❌ Name cannot be empty" -ForegroundColor Red
            }
        }
        "2" {
            # Remove stakeholder
            if (-not $global:V9Config.Stakeholders -or $global:V9Config.Stakeholders.Count -eq 0) {
                Write-Host "❌ No stakeholders to remove" -ForegroundColor Red
                return
            }
            
            Write-Host "`n📋 Select stakeholder to remove:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $global:V9Config.Stakeholders.Count; $i++) {
                $sh = $global:V9Config.Stakeholders[$i]
                $taskCount = ($global:V9Config.Tickets | Where-Object { $_.Stakeholder -eq $sh }).Count
                Write-Host "  $($i + 1). $sh ($taskCount tasks)" -ForegroundColor White
            }
            Write-Host "`nChoose (1-$($global:V9Config.Stakeholders.Count)): " -NoNewline -ForegroundColor Yellow
            $selection = Read-Host
            
            if ($selection -match '^\d+$') {
                $index = [int]$selection - 1
                if ($index -ge 0 -and $index -lt $global:V9Config.Stakeholders.Count) {
                    $stakeholderToRemove = $global:V9Config.Stakeholders[$index]
                    $taskCount = ($global:V9Config.Tickets | Where-Object { $_.Stakeholder -eq $stakeholderToRemove }).Count
                    
                    if ($taskCount -gt 0) {
                        Write-Host "`n⚠️  Warning: $taskCount tasks are assigned to '$stakeholderToRemove'" -ForegroundColor Yellow
                        Write-Host "These tasks will be reassigned to 'General'" -ForegroundColor Yellow
                        Write-Host "`nContinue? (y/n): " -NoNewline -ForegroundColor Yellow
                        $confirm = Read-Host
                        if ($confirm -ne 'y') {
                            Write-Host "Cancelled" -ForegroundColor Gray
                            return
                        }
                        
                        # Reassign tasks
                        foreach ($ticket in $global:V9Config.Tickets) {
                            if ($ticket.Stakeholder -eq $stakeholderToRemove) {
                                $ticket.Stakeholder = "General"
                            }
                        }
                    }
                    
                    # Remove stakeholder
                    $global:V9Config.Stakeholders = $global:V9Config.Stakeholders | Where-Object { $_ -ne $stakeholderToRemove }
                    
                    if (Save-V9Config) {
                        Write-Host "✅ Stakeholder '$stakeholderToRemove' removed successfully!" -ForegroundColor Green
                    }
                } else {
                    Write-Host "❌ Invalid selection" -ForegroundColor Red
                }
            } else {
                Write-Host "❌ Invalid input" -ForegroundColor Red
            }
        }
        "3" {
            Write-Host "Cancelled" -ForegroundColor Gray
        }
        default {
            Write-Host "❌ Invalid choice" -ForegroundColor Red
        }
    }
}

function Manage-Initiatives {
    <#
    .SYNOPSIS
        Interactive initiative management for V10 config
    #>
    
    # First, list current initiatives
    List-Initiatives
    
    Write-Host "`n📝 Initiative Management" -ForegroundColor Cyan
    Write-Host "  1. Add new initiative" -ForegroundColor White
    Write-Host "  2. Modify initiative" -ForegroundColor White
    Write-Host "  3. Remove initiative" -ForegroundColor White
    Write-Host "  4. Cancel" -ForegroundColor White
    Write-Host "`nChoose (1/2/3/4): " -NoNewline -ForegroundColor Yellow
    $choice = Read-Host
    
    switch ($choice) {
        "1" {
            # Add initiative
            Write-Host "`nEnter initiative name: " -NoNewline -ForegroundColor Yellow
            $name = Read-Host
            if (-not [string]::IsNullOrWhiteSpace($name)) {
                Add-Initiative -Name $name
            } else {
                Write-Host "❌ Name cannot be empty" -ForegroundColor Red
            }
        }
        "2" {
            # Modify initiative
            if (-not $global:V9Config.Initiatives -or $global:V9Config.Initiatives.Count -eq 0) {
                Write-Host "❌ No initiatives to modify" -ForegroundColor Red
                return
            }
            
            Write-Host "`n📋 Select initiative to modify:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $global:V9Config.Initiatives.Count; $i++) {
                $init = $global:V9Config.Initiatives[$i]
                $taskCount = ($global:V9Config.Tickets | Where-Object { $_.Initiative -eq $init.Name }).Count
                $startInfo = if ($init.StartDate) { "starts: $($init.StartDate)" } else { "no start date" }
                Write-Host "  $($i + 1). $($init.Name) ($taskCount tasks, $startInfo)" -ForegroundColor White
            }
            Write-Host "`nChoose (1-$($global:V9Config.Initiatives.Count)): " -NoNewline -ForegroundColor Yellow
            $selection = Read-Host
            
            if ($selection -match '^\d+$') {
                $index = [int]$selection - 1
                if ($index -ge 0 -and $index -lt $global:V9Config.Initiatives.Count) {
                    $initiative = $global:V9Config.Initiatives[$index]
                    
                    Write-Host "`n📝 Modifying: $($initiative.Name)" -ForegroundColor Cyan
                    Write-Host "  1. Change name" -ForegroundColor White
                    Write-Host "  2. Set start date" -ForegroundColor White
                    Write-Host "  3. Cancel" -ForegroundColor White
                    Write-Host "`nChoose (1/2/3): " -NoNewline -ForegroundColor Yellow
                    $modChoice = Read-Host
                    
                    switch ($modChoice) {
                        "1" {
                            Write-Host "`nEnter new name: " -NoNewline -ForegroundColor Yellow
                            $newName = Read-Host
                            if (-not [string]::IsNullOrWhiteSpace($newName)) {
                                # Check if name already exists
                                if ($global:V9Config.Initiatives | Where-Object { $_.Name -eq $newName -and $_.Name -ne $initiative.Name }) {
                                    Write-Host "❌ Initiative '$newName' already exists" -ForegroundColor Red
                                    return
                                }
                                
                                $oldName = $initiative.Name
                                $initiative.Name = $newName
                                
                                # Update all tasks with this initiative
                                foreach ($ticket in $global:V9Config.Tickets) {
                                    if ($ticket.Initiative -eq $oldName) {
                                        $ticket.Initiative = $newName
                                    }
                                }
                                
                                if (Save-V9Config) {
                                    Write-Host "✅ Initiative renamed from '$oldName' to '$newName'!" -ForegroundColor Green
                                }
                            } else {
                                Write-Host "❌ Name cannot be empty" -ForegroundColor Red
                            }
                        }
                        "2" {
                            Write-Host "`nEnter start date (yyyy-MM-dd or 'today'): " -NoNewline -ForegroundColor Yellow
                            $dateInput = Read-Host
                            if (-not [string]::IsNullOrWhiteSpace($dateInput)) {
                                if ($dateInput -eq 'today') {
                                    $initiative.StartDate = Get-Date -Format "yyyy-MM-dd"
                                } else {
                                    try {
                                        $parsedDate = [DateTime]::ParseExact($dateInput, 'yyyy-MM-dd', $null)
                                        $initiative.StartDate = $parsedDate.ToString('yyyy-MM-dd')
                                    } catch {
                                        Write-Host "❌ Invalid date format. Use yyyy-MM-dd or 'today'" -ForegroundColor Red
                                        return
                                    }
                                }
                                
                                if (Save-V9Config) {
                                    Write-Host "✅ Initiative start date set to $($initiative.StartDate)!" -ForegroundColor Green
                                }
                            } else {
                                Write-Host "❌ Date cannot be empty" -ForegroundColor Red
                            }
                        }
                        "3" {
                            Write-Host "Cancelled" -ForegroundColor Gray
                        }
                        default {
                            Write-Host "❌ Invalid choice" -ForegroundColor Red
                        }
                    }
                } else {
                    Write-Host "❌ Invalid selection" -ForegroundColor Red
                }
            } else {
                Write-Host "❌ Invalid input" -ForegroundColor Red
            }
        }
        "3" {
            # Remove initiative
            if (-not $global:V9Config.Initiatives -or $global:V9Config.Initiatives.Count -eq 0) {
                Write-Host "❌ No initiatives to remove" -ForegroundColor Red
                return
            }
            
            Write-Host "`n📋 Select initiative to remove:" -ForegroundColor Cyan
            for ($i = 0; $i -lt $global:V9Config.Initiatives.Count; $i++) {
                $init = $global:V9Config.Initiatives[$i]
                $taskCount = ($global:V9Config.Tickets | Where-Object { $_.Initiative -eq $init.Name }).Count
                Write-Host "  $($i + 1). $($init.Name) ($taskCount tasks)" -ForegroundColor White
            }
            Write-Host "`nChoose (1-$($global:V9Config.Initiatives.Count)): " -NoNewline -ForegroundColor Yellow
            $selection = Read-Host
            
            if ($selection -match '^\d+$') {
                $index = [int]$selection - 1
                if ($index -ge 0 -and $index -lt $global:V9Config.Initiatives.Count) {
                    $initiativeToRemove = $global:V9Config.Initiatives[$index].Name
                    $taskCount = ($global:V9Config.Tickets | Where-Object { $_.Initiative -eq $initiativeToRemove }).Count
                    
                    if ($taskCount -gt 0) {
                        Write-Host "`n⚠️  Warning: $taskCount tasks are assigned to '$initiativeToRemove'" -ForegroundColor Yellow
                        Write-Host "These tasks will be reassigned to 'General'" -ForegroundColor Yellow
                        Write-Host "`nContinue? (y/n): " -NoNewline -ForegroundColor Yellow
                        $confirm = Read-Host
                        if ($confirm -ne 'y') {
                            Write-Host "Cancelled" -ForegroundColor Gray
                            return
                        }
                        
                        # Reassign tasks
                        foreach ($ticket in $global:V9Config.Tickets) {
                            if ($ticket.Initiative -eq $initiativeToRemove) {
                                $ticket.Initiative = "General"
                            }
                        }
                    }
                    
                    # Remove initiative
                    $global:V9Config.Initiatives = $global:V9Config.Initiatives | Where-Object { $_.Name -ne $initiativeToRemove }
                    
                    if (Save-V9Config) {
                        Write-Host "✅ Initiative '$initiativeToRemove' removed successfully!" -ForegroundColor Green
                    }
                } else {
                    Write-Host "❌ Invalid selection" -ForegroundColor Red
                }
            } else {
                Write-Host "❌ Invalid input" -ForegroundColor Red
            }
        }
        "4" {
            Write-Host "Cancelled" -ForegroundColor Gray
        }
        default {
            Write-Host "❌ Invalid choice" -ForegroundColor Red
        }
    }
}

function Show-InitiativeChart {
    <#
    .SYNOPSIS
        Generates an interactive HTML chart showing initiative timelines
    .DESCRIPTION
        Creates a horizontal bar chart of initiatives with:
        - Olive green: Currently active initiatives
        - Light blue: Future initiatives
        - Light pink: Initiatives with >50% paused tasks
        - Past initiatives are hidden
        - Sorted by start date
    #>
    
    Write-Host "`n📊 Generating Initiative Timeline Chart..." -ForegroundColor Cyan
    
    if ($null -eq $global:V9Config) {
        Write-Host "❌ No config loaded. Run 'reload' first." -ForegroundColor Red
        return
    }
    
    if ($global:V9Config.Initiatives.Count -eq 0) {
        Write-Host "❌ No initiatives found in config." -ForegroundColor Red
        return
    }
    
    $today = Get-Date
    
    # Calculate initiative data
    $initiativeData = @()
    
    foreach ($initiative in $global:V9Config.Initiatives) {
        # Get all tasks for this initiative
        $tasks = $global:V9Config.Tickets | Where-Object { $_.Initiative -eq $initiative.Name }
        
        if ($tasks.Count -eq 0) {
            continue
        }
        
        # Calculate start and end dates from tasks
        $taskStartDates = $tasks | Where-Object { $_.StartDate } | ForEach-Object { [DateTime]::Parse($_.StartDate) }
        $taskEndDates = $tasks | Where-Object { $_.EndDate } | ForEach-Object { [DateTime]::Parse($_.EndDate) }
        
        if ($taskStartDates.Count -eq 0) {
            continue
        }
        
        $startDate = ($taskStartDates | Measure-Object -Minimum).Minimum
        $endDate = if ($taskEndDates.Count -gt 0) { 
            ($taskEndDates | Measure-Object -Maximum).Maximum 
        } else { 
            $today.AddDays(30) # Default 30 days if no end dates
        }
        
        # Skip past initiatives
        if ($endDate -lt $today) {
            continue
        }
        
        # Determine status and color
        $pausedTasks = ($tasks | Where-Object { $_.Status -eq 'Paused' }).Count
        $pausedPercentage = if ($tasks.Count -gt 0) { ($pausedTasks / $tasks.Count) * 100 } else { 0 }
        
        $color = if ($pausedPercentage -gt 50) {
            '#FFB6C1' # Light pink - mostly paused
        } elseif ($startDate -le $today -and $endDate -ge $today) {
            '#6B8E23' # Olive green - currently active
        } else {
            '#87CEEB' # Light blue - future
        }
        
        $status = if ($pausedPercentage -gt 50) {
            "Paused (${pausedPercentage:N0}%)"
        } elseif ($startDate -le $today -and $endDate -ge $today) {
            "Active"
        } else {
            "Future"
        }
        
        $durationDays = ($endDate - $startDate).Days
        
        $initiativeData += [PSCustomObject]@{
            Name = $initiative.Name
            StartDate = $startDate
            EndDate = $endDate
            DurationDays = $durationDays
            TaskCount = $tasks.Count
            Status = $status
            Color = $color
            PausedPercentage = $pausedPercentage
        }
    }
    
    # Sort by start date
    $initiativeData = $initiativeData | Sort-Object StartDate
    
    if ($initiativeData.Count -eq 0) {
        Write-Host "❌ No current or future initiatives to display." -ForegroundColor Yellow
        return
    }
    
    # Calculate max duration for scaling bars
    $maxDuration = ($initiativeData | Measure-Object -Property DurationDays -Maximum).Maximum
    if ($maxDuration -eq 0) { $maxDuration = 1 }
    
    # Generate HTML
    $htmlPath = Join-Path $PSScriptRoot "initChart.html"
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Initiative Timeline - Strategic Overview</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, 'Arial', sans-serif;
            background: #f0f2f5;
            padding: 15px;
            min-height: 100vh;
        }
        .container {
            max-width: 1800px;
            margin: 0 auto;
            background: white;
            border-radius: 4px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.08);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #003d82 0%, #0056b3 100%);
            color: white;
            padding: 10px 20px;
            border-bottom: 3px solid #002855;
        }
        .header h1 {
            font-size: 1.2em;
            font-weight: 600;
            margin-bottom: 2px;
            letter-spacing: -0.3px;
        }
        .header p {
            font-size: 0.75em;
            opacity: 0.95;
            font-weight: 300;
        }
        .content {
            padding: 12px 20px;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(4, 1fr);
            gap: 8px;
            margin-bottom: 10px;
        }
        .stat-card {
            background: #f8f9fa;
            border-left: 3px solid #0056b3;
            padding: 8px 12px;
            border-radius: 2px;
        }
        .stat-value {
            font-size: 1.4em;
            font-weight: 700;
            color: #003d82;
            margin-bottom: 2px;
            line-height: 1;
        }
        .stat-label {
            font-size: 0.65em;
            color: #666;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .legend {
            display: flex;
            justify-content: center;
            gap: 16px;
            margin-bottom: 8px;
            padding: 6px;
            background: #f8f9fa;
            border-radius: 2px;
            border: 1px solid #e0e0e0;
        }
        .legend-item {
            display: flex;
            align-items: center;
            gap: 6px;
            font-weight: 500;
            font-size: 0.7em;
            color: #333;
        }
        .legend-color {
            width: 22px;
            height: 12px;
            border-radius: 2px;
            border: 1px solid rgba(0,0,0,0.1);
        }
        .chart {
            margin-top: 12px;
        }
        .initiative {
            display: grid;
            grid-template-columns: 260px 1fr 320px;
            gap: 12px;
            align-items: center;
            margin-bottom: 4px;
            padding: 6px 0;
            border-bottom: 1px solid #e8e8e8;
        }
        .initiative:last-child {
            border-bottom: none;
        }
        .initiative-name {
            font-size: 0.85em;
            font-weight: 600;
            color: #1a1a1a;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }
        .initiative-meta {
            font-size: 0.7em;
            color: #666;
            text-align: right;
            white-space: nowrap;
            overflow: visible;
        }
        .bar-container {
            position: relative;
            background: #f0f0f0;
            border-radius: 2px;
            height: 20px;
            border: 1px solid #d0d0d0;
        }
        .bar {
            height: 100%;
            border-radius: 2px;
            display: flex;
            align-items: center;
            padding: 0 8px;
            color: white;
            font-weight: 600;
            font-size: 0.65em;
            transition: all 0.3s ease;
            box-shadow: inset 0 -1px 2px rgba(0,0,0,0.1);
            text-shadow: 0 1px 1px rgba(0,0,0,0.2);
        }
        .bar:hover {
            opacity: 0.85;
        }
        .bar-label {
            font-weight: 600;
            white-space: nowrap;
        }
        .footer {
            margin-top: 10px;
            padding: 8px 20px;
            background: #f8f9fa;
            text-align: center;
            color: #666;
            font-size: 0.65em;
            border-top: 1px solid #e0e0e0;
        }
        .footer p {
            margin: 2px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Initiative Timeline Dashboard</h1>
            <p>Strategic Overview - Generated $(Get-Date -Format 'MMMM dd, yyyy')</p>
        </div>
        
        <div class="content">
            <div class="stats">
                <div class="stat-card">
                    <div class="stat-value">$(($initiativeData | Where-Object { $_.Status -eq 'Active' }).Count)</div>
                    <div class="stat-label">Active Now</div>
                </div>
            <div class="stat-card">
                <div class="stat-value">$(($initiativeData | Where-Object { $_.Status -eq 'Future' }).Count)</div>
                <div class="stat-label">Future Initiatives</div>
            </div>
                <div class="stat-card">
                    <div class="stat-value">$(($initiativeData | Where-Object { $_.Status -eq 'Future' }).Count)</div>
                    <div class="stat-label">Upcoming</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">$(($initiativeData | Where-Object { $_.Status -like 'Paused*' }).Count)</div>
                    <div class="stat-label">Paused</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">$(($initiativeData | Measure-Object -Property TaskCount -Sum).Sum)</div>
                    <div class="stat-label">Total Tasks</div>
                </div>
            </div>
            
            <div class="legend">
                <div class="legend-item">
                    <div class="legend-color" style="background: #6B8E23;"></div>
                    <span>Active Now</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color" style="background: #87CEEB;"></div>
                    <span>Future</span>
                </div>
                <div class="legend-item">
                    <div class="legend-color" style="background: #FFB6C1;"></div>
                    <span>Paused (>50%)</span>
                </div>
            </div>
            
            <div class="chart">
"@
    
    # Add each initiative with variable-width bars
    foreach ($init in $initiativeData) {
        $startStr = $init.StartDate.ToString('MMM dd')
        $endStr = $init.EndDate.ToString('MMM dd')
        $duration = "$($init.DurationDays)d"
        $dateRange = "▶ $startStr - ■ $endStr"
        $meta = "$dateRange | $duration | $($init.TaskCount) tasks | $($init.Status)"
        
        # Calculate bar width as percentage of max duration (minimum 20% for visibility)
        $barWidthPercent = [Math]::Max(20, [Math]::Round(($init.DurationDays / $maxDuration) * 100))
        
        $html += @"
            <div class="initiative">
                <div class="initiative-name">$($init.Name)</div>
                <div class="bar-container">
                    <div class="bar" style="background: $($init.Color); width: ${barWidthPercent}%;">
                        <span class="bar-label">$duration</span>
                    </div>
                </div>
                <div class="initiative-meta">$meta</div>
            </div>
"@
    }
    
    $html += @"
            </div>
        </div>
        
        <div class="footer">
            <p><strong>Initiative Timeline Dashboard</strong> | Generated from V10 Configuration</p>
            <p>Displaying $($initiativeData.Count) current and future initiatives | Past initiatives hidden</p>
            <p style="margin-top: 8px; font-size: 0.8em; color: #999;">Bar length represents initiative duration</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Write HTML file
    $html | Set-Content -Path $htmlPath -Encoding UTF8
    
    Write-Host "✅ Chart generated: $htmlPath" -ForegroundColor Green
    Write-Host "   📊 Showing $($initiativeData.Count) current/future initiatives" -ForegroundColor Cyan
    
    # Open in browser
    Write-Host "`n🌐 Opening chart in browser..." -ForegroundColor Cyan
    
    try {
        if ($IsMacOS) {
            Start-Process "open" -ArgumentList "`"$htmlPath`""
        } elseif ($IsLinux) {
            Start-Process "xdg-open" -ArgumentList "`"$htmlPath`""
        } else {
            Start-Process "`"$htmlPath`""
        }
        Write-Host "✅ Chart opened successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to open chart: $_" -ForegroundColor Red
        Write-Host "   Please open manually: $htmlPath" -ForegroundColor Yellow
    }
}

#endregion

#region Smart Router and Ambiguity Handler

function Get-FuzzyMatches {
    <#
    .SYNOPSIS
        Performs fuzzy matching against People and Stakeholders
    
    .PARAMETER SearchTerm
        The term to search for (after removing action and type keywords)
    
    .RETURNS
        Hashtable with PersonMatches and StakeholderMatches arrays, each with Name and Score
    #>
    param(
        [string]$SearchTerm
    )
    
    $result = @{
        PersonMatches = @()
        StakeholderMatches = @()
    }
    
    if ([string]::IsNullOrWhiteSpace($SearchTerm)) {
        return $result
    }
    
    # Check if config is loaded
    if ($null -eq $global:V9Config) {
        Write-Host "⚠️  Config not loaded. Please load a config first." -ForegroundColor Yellow
        return $result
    }
    
    $searchLower = $SearchTerm.ToLower()
    
    # Search in People
    if ($null -ne $global:V9Config.People -and $global:V9Config.People.Count -gt 0) {
        foreach ($person in $global:V9Config.People) {
            if ($null -eq $person.Name -or [string]::IsNullOrWhiteSpace($person.Name)) {
                continue
            }
            
            # Split name into first and last
            $nameParts = $person.Name -split '\s+', 2
            $firstName = if ($nameParts.Count -gt 0) { $nameParts[0] } else { "" }
            $lastName = if ($nameParts.Count -gt 1) { $nameParts[1] } else { "" }
            
            $fullName = $person.Name.ToLower()
            $firstNameLower = $firstName.ToLower()
            $lastNameLower = $lastName.ToLower()
            $compactName = ($person.Name -replace '\s+', '').ToLower()
        
        $score = 0
        # Exact match (highest priority)
        if ($fullName -eq $searchLower -or $compactName -eq $searchLower) {
            $score = 100
        }
            # First name exact match
            elseif ($firstNameLower -eq $searchLower) {
                $score = 90
            }
            # Last name exact match
            elseif ($lastNameLower -eq $searchLower) {
                $score = 85
            }
            # Contains in full name
            elseif ($fullName -like "*$searchLower*") {
                $score = 70
            }
            # Contains in compact name
            elseif ($compactName -like "*$searchLower*") {
                $score = 65
            }
            # Starts with in first or last name
            elseif ($firstNameLower -like "$searchLower*" -or $lastNameLower -like "$searchLower*") {
                $score = 60
            }
            
            if ($score -gt 0) {
                $result.PersonMatches += @{
                    Name = $person.Name
                    FirstName = $firstName
                    LastName = $lastName
                    Score = $score
                    Object = $person
                }
            }
        }
    }    # Search in Stakeholders
    if ($null -ne $global:V9Config.Stakeholders -and $global:V9Config.Stakeholders.Count -gt 0) {
        foreach ($stakeholder in $global:V9Config.Stakeholders) {
            if ([string]::IsNullOrWhiteSpace($stakeholder)) {
                continue
            }
            
            $stakeholderLower = $stakeholder.ToLower()
            $stakeholderCompact = ($stakeholder -replace '\s+', '').ToLower()
            
            $score = 0
        # Exact match
        if ($stakeholderLower -eq $searchLower) {
            $score = 100
        }
        # Exact match without spaces
        elseif ($stakeholderCompact -eq $searchLower) {
            $score = 95
        }
        # Contains
        elseif ($stakeholderLower -like "*$searchLower*") {
            $score = 70
        }
        # Starts with
        elseif ($stakeholderLower -like "$searchLower*") {
            $score = 60
        }
        
        if ($score -gt 0) {
            $result.StakeholderMatches += @{
                Name = $stakeholder
                Score = $score
            }
        }
    }
    }
    
    # Remove duplicates (by Name) and sort by score descending
    if ($result.PersonMatches.Count -gt 0) {
        $result.PersonMatches = @($result.PersonMatches | 
            Group-Object -Property Name | 
            ForEach-Object { 
                $_.Group | Sort-Object -Property Score -Descending | Select-Object -First 1 
            } |
            Sort-Object -Property Score -Descending)
    }
    
    if ($result.StakeholderMatches.Count -gt 0) {
        $result.StakeholderMatches = @($result.StakeholderMatches | 
            Group-Object -Property Name | 
            ForEach-Object { 
                $_.Group | Sort-Object -Property Score -Descending | Select-Object -First 1 
            } |
            Sort-Object -Property Score -Descending)
    }
    
    return $result
}

function Handle-AmbiguousInput {
    <#
    .SYNOPSIS
        Handles ambiguous user input with case statements for each scenario
    
    .PARAMETER AmbiguityType
        Type of ambiguity: NoActionOrType, NoTargetType, MultipleMatches, PersonAndStakeholder
    
    .PARAMETER Matches
        Match data from fuzzy search
    
    .PARAMETER Action
        Action if already determined (add/modify)
    
    .RETURNS
        Hashtable with resolved Action, TargetType, Entity, and EntityType
    #>
    param(
        [string]$AmbiguityType,
        $Matches,
        [string]$Action = $null
    )
    
    $result = @{
        Action = $Action
        TargetType = $null
        Entity = $null
        EntityType = $null
        Cancelled = $false
    }
    
    switch ($AmbiguityType) {
        'NoActionOrType' {
            # Just a name, no action or type specified - Show context-appropriate menu
            # If it's a Person, only show task options
            # If it's a Stakeholder, only show initiative options
            
            # Determine if it's a person or stakeholder from matches
            $isPerson = $Matches.PersonMatches.Count -gt 0
            $isStakeholder = $Matches.StakeholderMatches.Count -gt 0
            
            if ($isPerson -and -not $isStakeholder) {
                # Person only - show task options
                Write-Host "`n📋 What would you like to do?" -ForegroundColor Cyan
                Write-Host "   [1] Add Task" -ForegroundColor White
                Write-Host "   [2] Modify Task" -ForegroundColor White
                Write-Host "   [x] Cancel" -ForegroundColor Gray
                
                $choice = Read-Host "`nChoice"
                switch ($choice) {
                    '1' { $result.Action = 'add'; $result.TargetType = 'task' }
                    '2' { $result.Action = 'modify'; $result.TargetType = 'task' }
                    default { $result.Cancelled = $true }
                }
            }
            elseif ($isStakeholder -and -not $isPerson) {
                # Stakeholder only - show initiative options
                Write-Host "`n📋 What would you like to do?" -ForegroundColor Cyan
                Write-Host "   [1] Add Initiative" -ForegroundColor White
                Write-Host "   [2] Modify Initiative" -ForegroundColor White
                Write-Host "   [x] Cancel" -ForegroundColor Gray
                
                $choice = Read-Host "`nChoice"
                switch ($choice) {
                    '1' { $result.Action = 'add'; $result.TargetType = 'initiative' }
                    '2' { $result.Action = 'modify'; $result.TargetType = 'initiative' }
                    default { $result.Cancelled = $true }
                }
            }
            else {
                # Both person and stakeholder - show all options (shouldn't happen often)
                Write-Host "`n📋 What would you like to do?" -ForegroundColor Cyan
                Write-Host "   [1] Add Task" -ForegroundColor White
                Write-Host "   [2] Modify Task" -ForegroundColor White
                Write-Host "   [3] Add Initiative" -ForegroundColor White
                Write-Host "   [4] Modify Initiative" -ForegroundColor White
                Write-Host "   [x] Cancel" -ForegroundColor Gray
                
                $choice = Read-Host "`nChoice"
                switch ($choice) {
                    '1' { $result.Action = 'add'; $result.TargetType = 'task' }
                    '2' { $result.Action = 'modify'; $result.TargetType = 'task' }
                    '3' { $result.Action = 'add'; $result.TargetType = 'initiative' }
                    '4' { $result.Action = 'modify'; $result.TargetType = 'initiative' }
                    default { $result.Cancelled = $true }
                }
            }
        }
        
        'NoTargetType' {
            # Action specified but no task/initiative - Ask
            Write-Host "`n❓ Task or Initiative?" -ForegroundColor Cyan
            Write-Host "   [1] Task" -ForegroundColor White
            Write-Host "   [2] Initiative" -ForegroundColor White
            Write-Host "   [x] Cancel" -ForegroundColor Gray
            
            $choice = Read-Host "`nChoice"
            switch ($choice) {
                '1' { $result.TargetType = 'task' }
                '2' { $result.TargetType = 'initiative' }
                default { $result.Cancelled = $true }
            }
        }
        
        'MultipleMatches' {
            # Multiple people or stakeholders matched - Show numbered list
            $matchList = @()
            
            if ($Matches.PersonMatches.Count -gt 0) {
                Write-Host "`n👥 Multiple people found:" -ForegroundColor Cyan
                $index = 1
                foreach ($match in $Matches.PersonMatches) {
                    Write-Host "   [$index] $($match.Name)" -ForegroundColor White
                    $matchList += @{ Index = $index; Type = 'Person'; Data = $match }
                    $index++
                }
            }
            
            if ($Matches.StakeholderMatches.Count -gt 0) {
                Write-Host "`n🏢 Multiple stakeholders found:" -ForegroundColor Cyan
                foreach ($match in $Matches.StakeholderMatches) {
                    Write-Host "   [$index] $($match.Name)" -ForegroundColor White
                    $matchList += @{ Index = $index; Type = 'Stakeholder'; Data = $match }
                    $index++
                }
            }
            
            Write-Host "   [x] Cancel" -ForegroundColor Gray
            
            $choice = Read-Host "`nChoice"
            if ($choice -match '^\d+$' -and [int]$choice -le $matchList.Count) {
                $selected = $matchList[[int]$choice - 1]
                $result.EntityType = $selected.Type
                $result.Entity = $selected.Data
            } else {
                $result.Cancelled = $true
            }
        }
        
        'PersonAndStakeholder' {
            # Name matches both a person and stakeholder - Clarify
            Write-Host "`n🔀 Name matches both person and stakeholder:" -ForegroundColor Yellow
            Write-Host "   [1] Person: $($Matches.PersonMatches[0].Name)" -ForegroundColor White
            Write-Host "   [2] Stakeholder: $($Matches.StakeholderMatches[0].Name)" -ForegroundColor White
            Write-Host "   [x] Cancel" -ForegroundColor Gray
            
            $choice = Read-Host "`nChoice"
            switch ($choice) {
                '1' {
                    $result.EntityType = 'Person'
                    $result.Entity = $Matches.PersonMatches[0]
                }
                '2' {
                    $result.EntityType = 'Stakeholder'
                    $result.Entity = $Matches.StakeholderMatches[0]
                }
                default { $result.Cancelled = $true }
            }
        }
    }
    
    return $result
}

function Resolve-UserIntent {
    <#
    .SYNOPSIS
        Smart router that interprets flexible user input
    
    .DESCRIPTION
        Parses user input to determine:
        1. Action (add/modify/edit)
        2. Target type (task/initiative)
        3. Entity (person/stakeholder)
        
        Algorithm:
        1. Remove spaces from input
        2. Extract action keyword (add, mod, edit, etc.)
        3. Extract target type (task, init, etc.)
        4. Fuzzy match remaining string against people/stakeholders
        5. Handle ambiguities
    
    .PARAMETER UserInput
        Raw user input string
    
    .RETURNS
        Hashtable with Action, TargetType, Entity, EntityType, or null if cancelled
    #>
    param(
        [string]$UserInput
    )
    
    # Check if config is loaded
    if ($null -eq $global:V9Config) {
        Write-Host "⚠️  Config not loaded. Please load a config first using 'reload' command." -ForegroundColor Yellow
        return $null
    }
    
    # Step 1: Remove all spaces
    $processed = $UserInput -replace '\s+', ''
    $processedLower = $processed.ToLower()
    
    $action = $null
    $targetType = $null
    $remaining = $processedLower
    
    # Step 2: Extract ACTION
    # Patterns: add, mod(ify), edit
    if ($processedLower -match '^(add)(.*)$') {
        $action = 'add'
        $remaining = $Matches[2]
    }
    elseif ($processedLower -match '^(mod(i(f(y)?)?)?)(.*)$') {
        $action = 'modify'
        $remaining = $Matches[5]
    }
    elseif ($processedLower -match '^(ed(i(t)?)?)(.*)$') {
        $action = 'modify'
        $remaining = $Matches[4]
    }
    
    # Step 3: Extract TARGET TYPE
    # Patterns: task, init(iative)
    if ($remaining -match '^(task)(.*)$') {
        $targetType = 'task'
        $remaining = $Matches[2]
    }
    elseif ($remaining -match '^(init(i(a(t(i(v(e)?)?)?)?)?)?)(.*)$') {
        $targetType = 'initiative'
        $remaining = $Matches[8]
    }
    
    # Special handling for initiatives: they don't need entity matching
    # If we have action + initiative but no remaining string, handle directly
    if ($targetType -eq 'initiative' -and [string]::IsNullOrWhiteSpace($remaining)) {
        return @{
            Action = $action
            TargetType = 'initiative'
            Entity = $null
            EntityType = $null
        }
    }
    
    # Step 4: Fuzzy match remaining string (only for tasks or if there's a remaining string)
    $matches = Get-FuzzyMatches -SearchTerm $remaining
    
    # Step 5: Determine ambiguity type and handle
    $personCount = $matches.PersonMatches.Count
    $stakeholderCount = $matches.StakeholderMatches.Count
    $totalMatches = $personCount + $stakeholderCount
    
    # No matches found
    if ($totalMatches -eq 0) {
        Write-Host "❌ No person or stakeholder found matching '$UserInput'" -ForegroundColor Red
        if ($null -ne $global:V9Config.People -and $global:V9Config.People.Count -gt 0) {
            $peopleNames = $global:V9Config.People | ForEach-Object { ($_.Name -split '\s+')[0] }
            Write-Host "   Available people: $($peopleNames -join ', ')" -ForegroundColor Gray
        }
        if ($null -ne $global:V9Config.Stakeholders -and $global:V9Config.Stakeholders.Count -gt 0) {
            Write-Host "   Available stakeholders: $($global:V9Config.Stakeholders -join ', ')" -ForegroundColor Gray
        }
        return $null
    }
    
    # Determine result and handle ambiguity
    $result = @{
        Action = $action
        TargetType = $targetType
        Entity = $null
        EntityType = $null
    }
    
    # Single person match, no stakeholder
    if ($personCount -eq 1 -and $stakeholderCount -eq 0) {
        $result.Entity = $matches.PersonMatches[0]
        $result.EntityType = 'Person'
    }
    # Single stakeholder match, no person
    elseif ($stakeholderCount -eq 1 -and $personCount -eq 0) {
        $result.Entity = $matches.StakeholderMatches[0]
        $result.EntityType = 'Stakeholder'
    }
    # Both person and stakeholder matched
    elseif ($personCount -gt 0 -and $stakeholderCount -gt 0) {
        $resolved = Handle-AmbiguousInput -AmbiguityType 'PersonAndStakeholder' -Matches $matches -Action $action
        if ($resolved.Cancelled) { return $null }
        $result.Entity = $resolved.Entity
        $result.EntityType = $resolved.EntityType
        if ($resolved.Action) { $result.Action = $resolved.Action }
        if ($resolved.TargetType) { $result.TargetType = $resolved.TargetType }
    }
    # Multiple matches (person or stakeholder)
    elseif ($totalMatches -gt 1) {
        $resolved = Handle-AmbiguousInput -AmbiguityType 'MultipleMatches' -Matches $matches -Action $action
        if ($resolved.Cancelled) { return $null }
        $result.Entity = $resolved.Entity
        $result.EntityType = $resolved.EntityType
        if ($resolved.Action) { $result.Action = $resolved.Action }
        if ($resolved.TargetType) { $result.TargetType = $resolved.TargetType }
    }
    
    # Handle missing action or target type
    if (-not $result.Action -or -not $result.TargetType) {
        if (-not $result.Action -and -not $result.TargetType) {
            # No action and no type - show menu
            $resolved = Handle-AmbiguousInput -AmbiguityType 'NoActionOrType' -Matches $matches -Action $null
            if ($resolved.Cancelled) { return $null }
            $result.Action = $resolved.Action
            $result.TargetType = $resolved.TargetType
        }
        elseif (-not $result.TargetType) {
            # Has action but no type - ask
            $resolved = Handle-AmbiguousInput -AmbiguityType 'NoTargetType' -Matches $matches -Action $result.Action
            if ($resolved.Cancelled) { return $null }
            $result.TargetType = $resolved.TargetType
        }
        elseif (-not $result.Action) {
            # Has type but no action - ask (repurpose NoActionOrType but filter by type)
            Write-Host "`n📋 What would you like to do with this $($result.TargetType)?" -ForegroundColor Cyan
            Write-Host "   [1] Add" -ForegroundColor White
            Write-Host "   [2] Modify" -ForegroundColor White
            Write-Host "   [x] Cancel" -ForegroundColor Gray
            
            $choice = Read-Host "`nChoice"
            switch ($choice) {
                '1' { $result.Action = 'add' }
                '2' { $result.Action = 'modify' }
                default { return $null }
            }
        }
    }
    
    return $result
}

#endregion

#region Command Dispatcher

function Invoke-Command {
    <#
    .SYNOPSIS
        Matches user input to commands using regex patterns with smart routing
    #>
    param([string]$UserInput)
    
    $inputText = $UserInput.Trim().ToLower()
    
    # Special commands (process first before smart router)
    # Capacity query
    if ($inputText -match "^capacity\s+(.+)$") {
        $personName = (Get-Culture).TextInfo.ToTitleCase($matches[1].Trim())
        Show-WeeklyCapacity -PersonName $personName
        return
    }
    
    if ($inputText -match "^capacity$") {
        Write-Host "Usage: capacity <person name>" -ForegroundColor Yellow
        Write-Host "Example: capacity vipul" -ForegroundColor Gray
        return
    }
    
    # Person summary (HTML report)
    # Matches: "summary sarah" or "summarysarah" (with or without space)
    if ($inputText -match "^summary\s*(.+)$") {
        $personName = (Get-Culture).TextInfo.ToTitleCase($matches[1].Trim())
        Show-PersonSummary -PersonName $personName
        return
    }
    
    if ($inputText -match "^summary$") {
        Write-Host "Usage: summary <person name> (or summary<name> without space)" -ForegroundColor Yellow
        Write-Host "Examples: summary sarah, summarysarah" -ForegroundColor Gray
        return
    }
    
    # Availability query
    if ($inputText -match "^availability$") {
        Show-MostAvailable
        return
    }
    
    # Quick task (minimal prompts)
    if ($inputText -match "^(qt|quick|quicktask)$") {
        Add-QuickTask
        return
    }
    
    # V10: Initiative management
    if ($inputText -match "^initiative$|^initiatives$") {
        Manage-Initiatives
        return
    }
    
    # V10: Stakeholder (owner) management
    if ($inputText -match "^owner$|^owners$|^stakeholder$|^stakeholders$") {
        Manage-Stakeholders
        return
    }
    
    # V10: Initiative Timeline Chart
    if ($inputText -match "^initchart$") {
        Show-InitiativeChart
        return
    }
    
    # Help
    if ($inputText -match "^help$") {
        Show-Help
        return
    }
    
    # Reload config
    if ($inputText -match "^reload$") {
        Initialize-V9Config
        return
    }
    
    # Sync config files
    if ($inputText -match "^sync$") {
        Sync-ConfigFiles
        return
    }
    
    # Open HTML console
    if ($inputText -match "^html$|^console$|^open$") {
        Open-HTMLConsole
        return
    }
    
    # SMART ROUTER: Try to resolve user intent for task/initiative management
    $intent = Resolve-UserIntent -UserInput $UserInput
    
    if ($null -ne $intent) {
        # Successfully resolved intent - route to appropriate worker
        if ($intent.TargetType -eq 'initiative') {
            # Initiative doesn't have entity, show simpler message
            Write-Host "`n✨ Resolved: $($intent.Action) $($intent.TargetType)" -ForegroundColor Green
        } else {
            # Task has entity (person/stakeholder)
            Write-Host "`n✨ Resolved: $($intent.Action) $($intent.TargetType) for $($intent.EntityType): $($intent.Entity.Name)" -ForegroundColor Green
        }
        
        if ($intent.TargetType -eq 'task') {
            if ($intent.EntityType -eq 'Person') {
                # Task for a person
                $personName = $intent.Entity.Name
                if ($intent.Action -eq 'add') {
                    Add-TaskForPerson -PersonName $personName
                } else {
                    Modify-TaskForPerson -PersonName $personName
                }
            } else {
                # Task for stakeholder (not yet implemented, fallback)
                Write-Host "⚠️  Tasks for stakeholders not yet implemented" -ForegroundColor Yellow
                Write-Host "   Please use HTML console for stakeholder task management" -ForegroundColor Gray
                Open-HTMLConsole
            }
        }
        elseif ($intent.TargetType -eq 'initiative') {
            # Initiative management (no entity/stakeholder needed)
            if ($intent.Action -eq 'add') {
                # Add initiative - prompt for name
                Write-Host "`n➕ Adding new initiative" -ForegroundColor Cyan
                Write-Host "`nEnter initiative name: " -NoNewline -ForegroundColor Yellow
                $initName = Read-Host
                
                if ([string]::IsNullOrWhiteSpace($initName)) {
                    Write-Host "❌ Initiative name cannot be empty" -ForegroundColor Red
                } else {
                    Add-Initiative -Name $initName
                }
            } else {
                # Modify initiative - show list and let user pick
                Write-Host "`n📝 Modifying initiative" -ForegroundColor Cyan
                
                if (-not $global:V9Config.Initiatives -or $global:V9Config.Initiatives.Count -eq 0) {
                    Write-Host "❌ No initiatives to modify" -ForegroundColor Red
                    return
                }
                
                # List initiatives
                Write-Host "`n📊 Current Initiatives:" -ForegroundColor Cyan
                for ($i = 0; $i -lt $global:V9Config.Initiatives.Count; $i++) {
                    $init = $global:V9Config.Initiatives[$i]
                    $taskCount = ($global:V9Config.Tickets | Where-Object { $_.Initiative -eq $init.Name }).Count
                    $startInfo = if ($init.StartDate) { "starts: $($init.StartDate)" } else { "no start date" }
                    Write-Host "  $($i + 1). $($init.Name) ($taskCount tasks, $startInfo)" -ForegroundColor White
                }
                Write-Host "`nChoose initiative (1-$($global:V9Config.Initiatives.Count), or press Enter to cancel): " -NoNewline -ForegroundColor Yellow
                $selection = Read-Host
                
                if ([string]::IsNullOrWhiteSpace($selection)) {
                    Write-Host "❌ Cancelled" -ForegroundColor Yellow
                    return
                }
                
                if ($selection -match '^\d+$') {
                    $index = [int]$selection - 1
                    if ($index -ge 0 -and $index -lt $global:V9Config.Initiatives.Count) {
                        $initiative = $global:V9Config.Initiatives[$index]
                        
                        Write-Host "`n📝 Modifying: $($initiative.Name)" -ForegroundColor Cyan
                        Write-Host "  [1] Change name" -ForegroundColor White
                        Write-Host "  [2] Set start date" -ForegroundColor White
                        Write-Host "  [x] Cancel" -ForegroundColor Gray
                        Write-Host "`nChoose (1/2/x): " -NoNewline -ForegroundColor Yellow
                        $modChoice = Read-Host
                        
                        switch ($modChoice) {
                            "1" {
                                Write-Host "`nEnter new name: " -NoNewline -ForegroundColor Yellow
                                $newName = Read-Host
                                if (-not [string]::IsNullOrWhiteSpace($newName)) {
                                    # Check if name already exists
                                    if ($global:V9Config.Initiatives | Where-Object { $_.Name -eq $newName -and $_.Name -ne $initiative.Name }) {
                                        Write-Host "❌ Initiative '$newName' already exists" -ForegroundColor Red
                                        return
                                    }
                                    
                                    $oldName = $initiative.Name
                                    $initiative.Name = $newName
                                    
                                    # Update all tasks with this initiative
                                    foreach ($ticket in $global:V9Config.Tickets) {
                                        if ($ticket.Initiative -eq $oldName) {
                                            $ticket.Initiative = $newName
                                        }
                                    }
                                    
                                    if (Save-V9Config) {
                                        Write-Host "✅ Initiative renamed from '$oldName' to '$newName'!" -ForegroundColor Green
                                    }
                                } else {
                                    Write-Host "❌ Name cannot be empty" -ForegroundColor Red
                                }
                            }
                            "2" {
                                Write-Host "`nEnter start date (yyyy-MM-dd or 'today'): " -NoNewline -ForegroundColor Yellow
                                $dateInput = Read-Host
                                if (-not [string]::IsNullOrWhiteSpace($dateInput)) {
                                    $startDate = if ($dateInput -eq 'today') { Get-Date -Format 'yyyy-MM-dd' } else { $dateInput }
                                    $initiative.StartDate = $startDate
                                    
                                    if (Save-V9Config) {
                                        Write-Host "✅ Start date set to: $startDate" -ForegroundColor Green
                                    }
                                } else {
                                    Write-Host "❌ Date cannot be empty" -ForegroundColor Red
                                }
                            }
                            default {
                                Write-Host "❌ Cancelled" -ForegroundColor Yellow
                            }
                        }
                    } else {
                        Write-Host "❌ Invalid selection" -ForegroundColor Red
                    }
                } else {
                    Write-Host "❌ Invalid selection" -ForegroundColor Red
                }
            }
        }
        return
    }
    
    # If smart router didn't match, try legacy person name patterns for backward compatibility
    if ($inputText -match "^(siva|vipul|peter|sameet|sharanya|divya)$") {
        $personName = (Get-Culture).TextInfo.ToTitleCase($matches[1])
        
        # Check if person exists in config
        $person = Get-PersonByName -Name $personName
        if ($null -eq $person) {
            Write-Host "❌ Person not found in config: $personName" -ForegroundColor Red
            return
        }
        
        Write-Host "`nAdd or Modify task for $personName?" -ForegroundColor Cyan
        Write-Host "  1. Add    :" -ForegroundColor White
        Write-Host "  2. Modify :" -ForegroundColor White
        Write-Host "Choose: " -NoNewline -ForegroundColor Yellow
        $choice = Read-Host
        
        $choiceLower = $choice.Trim().ToLower()
        
        # Match add variants
        if ($choiceLower -match "^(1|a|ad|add)$") {
            Add-TaskForPerson -PersonName $personName
        }
        # Match modify variants
        elseif ($choiceLower -match "^(2|m|mo|mod|modi|modif|modify)$") {
            Modify-TaskForPerson -PersonName $personName
        }
        else {
            Write-Host "❌ Invalid choice" -ForegroundColor Red
        }
        return
    }
    
    # Default: Open HTML console for any unrecognized command
    Write-Host "🌐 Unknown command: $UserInput" -ForegroundColor Yellow
    Write-Host "   Opening HTML console for advanced features..." -ForegroundColor Cyan
    Open-HTMLConsole
}

function Open-HTMLConsole {
    <#
    .SYNOPSIS
        Opens html_console_v10.html in the default browser
    #>
    
    $htmlPath = Join-Path $PSScriptRoot "html_console_v10.html"
    
    if (-not (Test-Path $htmlPath)) {
        Write-Host "❌ HTML console not found: $htmlPath" -ForegroundColor Red
        return
    }
    
    Write-Host "`n🌐 Opening HTML Console..." -ForegroundColor Cyan
    
    try {
        if ($IsMacOS) {
            # Use open with quoted path to handle spaces
            Start-Process "open" -ArgumentList "`"$htmlPath`""
        } elseif ($IsLinux) {
            Start-Process "xdg-open" -ArgumentList "`"$htmlPath`""
        } else {
            # Windows
            Start-Process "`"$htmlPath`""
        }
        Write-Host "✅ HTML console opened in browser" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to open HTML console: $_" -ForegroundColor Red
        Write-Host "   Path: $htmlPath" -ForegroundColor Yellow
    }
}

function Show-Help {
    Write-Host "`n📚 Available Commands" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Task Management:" -ForegroundColor Yellow
    Write-Host "  siva|vipul|peter|sameet|sharanya|divya" -ForegroundColor White
    Write-Host "    → Add or modify tasks for a person (V10: prompts for Stakeholder & Initiative)" -ForegroundColor Gray
    Write-Host "  qt | quick | quicktask" -ForegroundColor White
    Write-Host "    → Quick task (minimal prompts: description + stakeholder, auto-defaults for rest)" -ForegroundColor Gray
    Write-Host "    → Defaults: Unassigned, General, To Do, tomorrow, M size, P2 priority" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "V10 Management:" -ForegroundColor Yellow
    Write-Host "  initiative | initiatives" -ForegroundColor White
    Write-Host "    → List/add/modify initiatives" -ForegroundColor Gray
    Write-Host "  owner | stakeholder | owners | stakeholders" -ForegroundColor White
    Write-Host "    → List/add/remove stakeholders" -ForegroundColor Gray
    Write-Host "  initchart" -ForegroundColor White
    Write-Host "    → Generate initiative timeline chart (HTML)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Capacity & Availability:" -ForegroundColor Yellow
    Write-Host "  capacity <name>" -ForegroundColor White
    Write-Host "    → Show weekly capacity for a person" -ForegroundColor Gray
    Write-Host "    Example: capacity vipul" -ForegroundColor DarkGray
    Write-Host "  summary <name>" -ForegroundColor White
    Write-Host "    → Generate HTML report with person's weekly work summary" -ForegroundColor Gray
    Write-Host "    Example: summary sarah" -ForegroundColor DarkGray
    Write-Host "  availability" -ForegroundColor White
    Write-Host "    → Show who is most available today" -ForegroundColor Gray
    Write-Host ""
    Write-Host "System:" -ForegroundColor Yellow
    Write-Host "  html | console | open" -ForegroundColor White
    Write-Host "    → Open html_console_v10.html in browser" -ForegroundColor Gray
    Write-Host "  sync" -ForegroundColor White
    Write-Host "    → Sync config files between Downloads and Output (with SHA1 validation)" -ForegroundColor Gray
    Write-Host "  reload" -ForegroundColor White
    Write-Host "    → Reload config from Downloads" -ForegroundColor Gray
    Write-Host "  help" -ForegroundColor White
    Write-Host "    → Show this help" -ForegroundColor Gray
    Write-Host "  exit" -ForegroundColor White
    Write-Host "    → Exit helper" -ForegroundColor Gray
    Write-Host ""
    Write-Host "💡 Tip: Any unrecognized command will open the HTML console" -ForegroundColor DarkGray
    Write-Host ""
}

function Start-InteractiveMode {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║  PowerShell Helper for html_console_v10.html  ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    
    # Initialize V9 config
    if (-not (Initialize-V9Config)) {
        Write-Host "`nCannot start without V9 config. Exiting." -ForegroundColor Red
        return
    }
    
    Write-Host "`nType 'help' for available commands or 'exit' to quit`n" -ForegroundColor Gray
    
    do {
        Write-Host "helper2> " -NoNewline -ForegroundColor Cyan
        $userInput = Read-Host
        
        if ($userInput -eq "exit") {
            Write-Host "Goodbye! 👋" -ForegroundColor Cyan
            break
        }
        
        if ([string]::IsNullOrWhiteSpace($userInput)) {
            continue
        }
        
        try {
            Invoke-Command -UserInput $userInput
        } catch {
            Write-Host "❌ Error: $_" -ForegroundColor Red
        }
        
        Write-Host ""
    } while ($true)
}


#endregion


# Start the interactive mode (unless being dot-sourced for testing)
if ($MyInvocation.InvocationName -ne '.') {
    Start-InteractiveMode
}