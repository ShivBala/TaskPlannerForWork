# V9/V10 CSV Adapter Module
# Purpose: Provides compatibility layer between helper.ps1 and html_console_v9/v10.html export format
# Author: GitHub Copilot
# Date: 2025

<#
.SYNOPSIS
    Multi-section CSV parser for V9/V10 HTML export format

.DESCRIPTION
    The V9/V10 HTML console exports configuration in a multi-section CSV format:
    - SECTION,METADATA: Export metadata (date, version, description)
    - SECTION,SETTINGS: Application settings (base hours, project hours, start date, ticket ID)
    - SECTION,TASK_SIZES: Size definitions (S, M, L, XL with days and removable flag)
    - SECTION,PEOPLE: Team members with weekly availability and project readiness
    - SECTION,STAKEHOLDERS: (V10) Stakeholder names
    - SECTION,INITIATIVES: (V10) Initiative names with creation and start dates
    - SECTION,TICKETS: Task tickets with full history and details (V10 adds UUID, Stakeholder, Initiative)

.NOTES
    This adapter preserves all sections when reading/writing to ensure full round-trip compatibility
    between PowerShell task management and HTML console.
    Supports both V9 and V10 formats with backward compatibility.
#>

# Global configuration - Define paths as variables for easy customization
$script:OutputFolderPath = Join-Path $PSScriptRoot "Output"
$script:DownloadsFolderPath = "$HOME/Downloads"

$script:V9ConfigCache = @{
    LastConfigFile = $null
    Metadata = $null
    Settings = $null
    TaskSizes = $null
    People = $null
    Stakeholders = $null  # V10
    Initiatives = $null   # V10
    Tickets = $null
}

function Get-LatestV9ConfigFile {
    <#
    .SYNOPSIS
        Auto-detects the latest project_config_*.csv file from Output folder, syncing from Downloads if needed
    
    .DESCRIPTION
        Finds the most recent project_config_*.csv file (excluding closed items files).
        First checks Downloads folder for new files and copies them to Output if they're newer.
        Then returns the latest file from Output folder.
    
    .PARAMETER DownloadsPath
        Optional custom Downloads folder path. Defaults to the global $script:DownloadsFolderPath
    
    .PARAMETER OutputPath
        Optional custom Output folder path. Defaults to the global $script:OutputFolderPath
    
    .EXAMPLE
        $configFile = Get-LatestV9ConfigFile
        if ($configFile) {
            Write-Host "Found: $configFile"
        }
    #>
    param(
        [string]$DownloadsPath = $script:DownloadsFolderPath,
        [string]$OutputPath = $script:OutputFolderPath
    )
    
    try {
        # Ensure Output folder exists
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            Write-Host "📁 Created Output folder: $OutputPath" -ForegroundColor Cyan
        }
        
        # Check Downloads folder for new files
        $downloadsFiles = Get-ChildItem -Path $DownloadsPath -Filter "project_config_*.csv" -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '_closed_' } |
            Sort-Object LastWriteTime -Descending
        
        # Check Output folder for existing files
        $outputFiles = Get-ChildItem -Path $OutputPath -Filter "project_config_*.csv" -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '_closed_' } |
            Sort-Object LastWriteTime -Descending
        
        # Sync from Downloads to Output if needed
        if ($downloadsFiles.Count -gt 0) {
            $latestDownloadFile = $downloadsFiles[0]
            
            # Check if this file is newer than what's in Output
            $needsCopy = $false
            if ($outputFiles.Count -eq 0) {
                $needsCopy = $true
                Write-Host "📥 No files in Output folder, copying from Downloads..." -ForegroundColor Cyan
            } else {
                $latestOutputFile = $outputFiles[0]
                if ($latestDownloadFile.LastWriteTime -gt $latestOutputFile.LastWriteTime) {
                    $needsCopy = $true
                    Write-Host "📥 Newer file found in Downloads, copying to Output..." -ForegroundColor Cyan
                }
            }
            
            if ($needsCopy) {
                $destPath = Join-Path $OutputPath $latestDownloadFile.Name
                Copy-Item -Path $latestDownloadFile.FullName -Destination $destPath -Force
                Write-Host "✅ Copied: $($latestDownloadFile.Name)" -ForegroundColor Green
                Write-Host "   From: Downloads (modified: $($latestDownloadFile.LastWriteTime))" -ForegroundColor Gray
                Write-Host "   To: Output" -ForegroundColor Gray
                
                # Refresh output files list
                $outputFiles = Get-ChildItem -Path $OutputPath -Filter "project_config_*.csv" -ErrorAction SilentlyContinue |
                    Where-Object { $_.Name -notmatch '_closed_' } |
                    Sort-Object LastWriteTime -Descending
            }
        }
        
        # Return latest file from Output folder
        if ($outputFiles.Count -eq 0) {
            Write-Host "⚠️  No project_config_*.csv files found in Downloads or Output" -ForegroundColor Yellow
            Write-Host "   Please export configuration from html_console_v9.html first." -ForegroundColor Yellow
            return $null
        }
        
        $latestFile = $outputFiles[0]
        Write-Host "✅ Using config from Output: $($latestFile.Name) (modified: $($latestFile.LastWriteTime))" -ForegroundColor Green
        return $latestFile.FullName
        
    } catch {
        Write-Host "❌ Error searching for config files: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Read-V9ConfigFile {
    <#
    .SYNOPSIS
        Parses a V9 multi-section CSV file into structured data
    
    .DESCRIPTION
        Reads and parses all sections of a V9 CSV file:
        - Metadata (export info)
        - Settings (application configuration)
        - Task Sizes (size definitions)
        - People (team availability)
        - Tickets (task data)
    
    .PARAMETER FilePath
        Full path to the V9 CSV file to parse
    
    .PARAMETER UseCache
        If true, uses cached data if available for the same file
    
    .OUTPUTS
        Hashtable with keys: Metadata, Settings, TaskSizes, People, Tickets
        Returns $null if parsing fails
    
    .EXAMPLE
        $config = Read-V9ConfigFile -FilePath "~/Downloads/project_config_2025-01-15_10-30-00.csv"
        $tickets = $config.Tickets
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [switch]$UseCache
    )
    
    # Check cache
    if ($UseCache -and $script:V9ConfigCache.LastConfigFile -eq $FilePath) {
        Write-Verbose "Using cached config data for: $FilePath"
        return @{
            Metadata = $script:V9ConfigCache.Metadata
            Settings = $script:V9ConfigCache.Settings
            TaskSizes = $script:V9ConfigCache.TaskSizes
            People = $script:V9ConfigCache.People
            Stakeholders = $script:V9ConfigCache.Stakeholders
            Initiatives = $script:V9ConfigCache.Initiatives
            Tickets = $script:V9ConfigCache.Tickets
        }
    }
    
    if (!(Test-Path $FilePath)) {
        Write-Host "❌ Config file not found: $FilePath" -ForegroundColor Red
        return $null
    }
    
    try {
        Write-Host "📖 Reading config from: $(Split-Path $FilePath -Leaf)" -ForegroundColor Cyan
        
        try {
            $content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        } catch {
            if ($_.Exception.Message -like "*being used by another process*") {
                Write-Host "❌ Config file is open in another program (Excel, Browser, etc.)" -ForegroundColor Red
                Write-Host "   Please close the file and try again" -ForegroundColor Yellow
            }
            throw
        }
        
        $lines = $content -split "`r?`n"
        
        $result = @{
            Metadata = @{}
            Settings = @{}
            TaskSizes = @()
            People = @()
            Stakeholders = @()  # V10
            Initiatives = @()   # V10
            Tickets = @()
        }
        
        $currentSection = $null
        $sectionHeaders = $null
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            
            # Skip empty lines
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }
            
            # Check for section header
            if ($line -match '^SECTION,(.+)$') {
                $currentSection = $Matches[1]
                $sectionHeaders = $null
                continue
            }
            
            # Parse section content
            switch ($currentSection) {
                'METADATA' {
                    if ($sectionHeaders -eq $null) {
                        $sectionHeaders = $true
                        continue  # Skip "Key,Value" header
                    }
                    if ($line -match '^([^,]+),(.+)$') {
                        $result.Metadata[$Matches[1]] = $Matches[2]
                    }
                }
                
                'SETTINGS' {
                    if ($sectionHeaders -eq $null) {
                        $sectionHeaders = $true
                        continue  # Skip "Key,Value" header
                    }
                    if ($line -match '^([^,]+),(.*)$') {
                        $result.Settings[$Matches[1]] = $Matches[2]
                    }
                }
                
                'TASK_SIZES' {
                    if ($sectionHeaders -eq $null) {
                        $sectionHeaders = $true
                        continue  # Skip header row
                    }
                    # Parse: Size Key,Name,Days,Removable
                    # Example: S,"Small",1,false
                    if ($line -match '^([^,]+),"([^"]+)",(\d+),(true|false)$') {
                        $result.TaskSizes += [PSCustomObject]@{
                            Key = $Matches[1]
                            Name = $Matches[2]
                            Days = [int]$Matches[3]
                            Removable = $Matches[4] -eq 'true'
                        }
                    }
                }
                
                'PEOPLE' {
                    if ($sectionHeaders -eq $null) {
                        $sectionHeaders = $true
                        continue  # Skip header row
                    }
                    # Parse: Name,Week1-Week8,Project Ready
                    # Example: "Person Name",25,25,25,25,25,25,25,25,Yes
                    if ($line -match '^"([^"]+)",(.+)$') {
                        $name = $Matches[1]
                        $values = $Matches[2] -split ','
                        
                        # Extract 8 weeks of availability and project ready status
                        $availability = @()
                        for ($w = 0; $w -lt 8 -and $w -lt $values.Count; $w++) {
                            $availability += [int]$values[$w]
                        }
                        
                        $projectReady = $values.Count -gt 8 ? $values[8] -eq 'Yes' : $true
                        
                        $result.People += [PSCustomObject]@{
                            Name = $name
                            Availability = $availability
                            ProjectReady = $projectReady
                        }
                    }
                }
                
                'STAKEHOLDERS' {
                    # V10: Parse stakeholders
                    if ($sectionHeaders -eq $null) {
                        $sectionHeaders = $true
                        if (-not $result.ContainsKey('Stakeholders')) {
                            $result.Stakeholders = @()
                        }
                        continue  # Skip "Name" header
                    }
                    # Parse: "Stakeholder Name"
                    if ($line -match '^"([^"]+)"$') {
                        $result.Stakeholders += $Matches[1]
                    }
                }
                
                'INITIATIVES' {
                    # V10: Parse initiatives
                    if ($sectionHeaders -eq $null) {
                        $sectionHeaders = $true
                        if (-not $result.ContainsKey('Initiatives')) {
                            $result.Initiatives = @()
                        }
                        continue  # Skip "Name,Creation Date,Start Date" header
                    }
                    # Parse: "Initiative Name","2025-10-16","2025-11-01"
                    if ($line -match '^"([^"]+)","([^"]*)","([^"]*)"$') {
                        $result.Initiatives += [PSCustomObject]@{
                            Name = $Matches[1]
                            CreationDate = $Matches[2]
                            StartDate = if ($Matches[3]) { $Matches[3] } else { $null }
                        }
                    }
                }
                
                'TICKETS' {
                    if ($sectionHeaders -eq $null) {
                        # Store actual header to detect V9 vs V10 format
                        $sectionHeaders = $line
                        continue  # Skip header row
                    }
                    
                    # Parse ticket line (complex due to CSV quoting)
                    # Use PowerShell's ConvertFrom-Csv for proper CSV parsing
                    # V10 format includes: UUID,ID,Description,... (before ID)
                    # V10 format also adds: ...,Stakeholder,Initiative (after Assigned Team)
                    $tempCsv = "$sectionHeaders`n$line"
                    $ticket = $tempCsv | ConvertFrom-Csv
                    
                    if ($ticket) {
                        $ticketObj = [PSCustomObject]@{
                            ID = $ticket.ID
                            Description = $ticket.Description
                            StartDate = $ticket.'Start Date'
                            Size = $ticket.Size
                            Priority = $ticket.Priority
                            AssignedTeam = if ($ticket.'Assigned Team') { $ticket.'Assigned Team' -split ';' } else { @() }
                            Status = $ticket.Status
                            TaskType = $ticket.'Task Type'
                            PauseComments = $ticket.'Pause Comments'
                            StartDateHistory = $ticket.'Start Date History'
                            EndDateHistory = $ticket.'End Date History'
                            SizeHistory = $ticket.'Size History'
                            CustomEndDate = $ticket.'Custom End Date'
                            DetailsDescription = $ticket.'Details: Description'
                            DetailsPositives = $ticket.'Details: Positives'
                            DetailsNegatives = $ticket.'Details: Negatives'
                        }
                        
                        # V10 fields (if present)
                        if ($ticket.PSObject.Properties.Name -contains 'UUID') {
                            $ticketObj | Add-Member -NotePropertyName 'UUID' -NotePropertyValue $ticket.UUID
                        }
                        if ($ticket.PSObject.Properties.Name -contains 'Stakeholder') {
                            $ticketObj | Add-Member -NotePropertyName 'Stakeholder' -NotePropertyValue $ticket.Stakeholder
                        }
                        if ($ticket.PSObject.Properties.Name -contains 'Initiative') {
                            $ticketObj | Add-Member -NotePropertyName 'Initiative' -NotePropertyValue $ticket.Initiative
                        }
                        
                        $result.Tickets += $ticketObj
                    }
                }
            }
        }
        
        # Cache the results
        $script:V9ConfigCache.LastConfigFile = $FilePath
        $script:V9ConfigCache.Metadata = $result.Metadata
        $script:V9ConfigCache.Settings = $result.Settings
        $script:V9ConfigCache.TaskSizes = $result.TaskSizes
        $script:V9ConfigCache.People = $result.People
        $script:V9ConfigCache.Stakeholders = $result.Stakeholders
        $script:V9ConfigCache.Initiatives = $result.Initiatives
        $script:V9ConfigCache.Tickets = $result.Tickets
        
        $formatVersion = if ($result.Stakeholders.Count -gt 0 -or $result.Initiatives.Count -gt 0) { "V10" } else { "V9" }
        $v10Info = if ($formatVersion -eq "V10") { ", $($result.Stakeholders.Count) stakeholders, $($result.Initiatives.Count) initiatives" } else { "" }
        Write-Host "✅ Parsed $formatVersion config: $($result.Tickets.Count) tickets, $($result.People.Count) people$v10Info" -ForegroundColor Green
        
        return $result
        
    } catch {
        Write-Host "❌ Error parsing V9 config file: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        return $null
    }
}

function Write-V9ConfigFile {
    <#
    .SYNOPSIS
        Writes V9 multi-section CSV file with all data preserved
    
    .DESCRIPTION
        Takes structured config data and writes it back to V9 CSV format.
        Preserves all sections (metadata, settings, task sizes, people) and
        ensures full round-trip compatibility with HTML console.
    
    .PARAMETER FilePath
        Full path where to save the V9 CSV file
    
    .PARAMETER ConfigData
        Hashtable with keys: Metadata, Settings, TaskSizes, People, Tickets
        (as returned by Read-V9ConfigFile)
    
    .PARAMETER CreateBackup
        If true, creates a backup of existing file before overwriting
    
    .OUTPUTS
        Boolean: $true if successful, $false otherwise
    
    .EXAMPLE
        $config = Read-V9ConfigFile -FilePath $file
        # Modify $config.Tickets...
        Write-V9ConfigFile -FilePath $file -ConfigData $config -CreateBackup
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$ConfigData,
        
        [switch]$CreateBackup
    )
    
    try {
        # Create backup if requested
        if ($CreateBackup -and (Test-Path $FilePath)) {
            $backupPath = "$FilePath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            Copy-Item -Path $FilePath -Destination $backupPath -Force
            Write-Host "💾 Backup created: $(Split-Path $backupPath -Leaf)" -ForegroundColor Cyan
        }
        
        Write-Host "💾 Writing V9 config to: $(Split-Path $FilePath -Leaf)" -ForegroundColor Cyan
        
        $csvContent = [System.Text.StringBuilder]::new()
        
        # Metadata section
        [void]$csvContent.AppendLine("SECTION,METADATA")
        [void]$csvContent.AppendLine("Key,Value")
        foreach ($key in $ConfigData.Metadata.Keys) {
            [void]$csvContent.AppendLine("$key,$($ConfigData.Metadata[$key])")
        }
        [void]$csvContent.AppendLine()
        
        # Settings section
        [void]$csvContent.AppendLine("SECTION,SETTINGS")
        [void]$csvContent.AppendLine("Key,Value")
        foreach ($key in $ConfigData.Settings.Keys) {
            [void]$csvContent.AppendLine("$key,$($ConfigData.Settings[$key])")
        }
        [void]$csvContent.AppendLine()
        
        # Task Sizes section
        [void]$csvContent.AppendLine("SECTION,TASK_SIZES")
        [void]$csvContent.AppendLine("Size Key,Name,Days,Removable")
        foreach ($size in $ConfigData.TaskSizes) {
            [void]$csvContent.AppendLine("$($size.Key),`"$($size.Name)`",$($size.Days),$($size.Removable.ToString().ToLower())")
        }
        [void]$csvContent.AppendLine()
        
        # People section
        [void]$csvContent.AppendLine("SECTION,PEOPLE")
        [void]$csvContent.AppendLine("Name,Week1,Week2,Week3,Week4,Week5,Week6,Week7,Week8,Project Ready")
        foreach ($person in $ConfigData.People) {
            $avail = $person.Availability -join ','
            $ready = if ($person.ProjectReady) { "Yes" } else { "No" }
            [void]$csvContent.AppendLine("`"$($person.Name)`",$avail,$ready")
        }
        [void]$csvContent.AppendLine()
        
        # V10: Stakeholders section (if present)
        if ($ConfigData.ContainsKey('Stakeholders') -and $ConfigData.Stakeholders.Count -gt 0) {
            [void]$csvContent.AppendLine("SECTION,STAKEHOLDERS")
            [void]$csvContent.AppendLine("Name")
            foreach ($stakeholder in $ConfigData.Stakeholders) {
                [void]$csvContent.AppendLine("`"$stakeholder`"")
            }
            [void]$csvContent.AppendLine()
        }
        
        # V10: Initiatives section (if present)
        if ($ConfigData.ContainsKey('Initiatives') -and $ConfigData.Initiatives.Count -gt 0) {
            [void]$csvContent.AppendLine("SECTION,INITIATIVES")
            [void]$csvContent.AppendLine("Name,Creation Date,Start Date")
            foreach ($initiative in $ConfigData.Initiatives) {
                $creationDate = if ($initiative.CreationDate) { $initiative.CreationDate } else { "" }
                $startDate = if ($initiative.StartDate) { $initiative.StartDate } else { "" }
                [void]$csvContent.AppendLine("`"$($initiative.Name)`",`"$creationDate`",`"$startDate`"")
            }
            [void]$csvContent.AppendLine()
        }
        
        # Tickets section - Detect if V10 format (has UUID, Stakeholder, Initiative fields)
        $isV10 = $ConfigData.Tickets.Count -gt 0 -and 
                 ($ConfigData.Tickets[0].PSObject.Properties.Name -contains 'UUID')
        
        [void]$csvContent.AppendLine("SECTION,TICKETS")
        if ($isV10) {
            [void]$csvContent.AppendLine("UUID,ID,Description,Start Date,Size,Priority,Assigned Team,Stakeholder,Initiative,Status,Task Type,Pause Comments,Start Date History,End Date History,Size History,Custom End Date,Details: Description,Details: Positives,Details: Negatives")
        } else {
            [void]$csvContent.AppendLine("ID,Description,Start Date,Size,Priority,Assigned Team,Status,Task Type,Pause Comments,Start Date History,End Date History,Size History,Custom End Date,Details: Description,Details: Positives,Details: Negatives")
        }
        
        foreach ($ticket in $ConfigData.Tickets) {
            # Escape quotes in fields and handle null/empty values
            $desc = if ($ticket.Description) { $ticket.Description -replace '"', '""' } else { "" }
            $assignedTeam = if ($ticket.AssignedTeam) { ($ticket.AssignedTeam -join ';') } else { "" }
            $detailsDesc = if ($ticket.DetailsDescription) { $ticket.DetailsDescription -replace '"', '""' } else { "" }
            $detailsPos = if ($ticket.DetailsPositives) { $ticket.DetailsPositives -replace '"', '""' } else { "" }
            $detailsNeg = if ($ticket.DetailsNegatives) { $ticket.DetailsNegatives -replace '"', '""' } else { "" }
            $pauseComments = if ($ticket.PauseComments) { $ticket.PauseComments -replace '"', '""' } else { "" }
            $startDateHistory = if ($ticket.StartDateHistory) { $ticket.StartDateHistory -replace '"', '""' } else { "" }
            $endDateHistory = if ($ticket.EndDateHistory) { $ticket.EndDateHistory -replace '"', '""' } else { "" }
            $sizeHistory = if ($ticket.SizeHistory) { $ticket.SizeHistory -replace '"', '""' } else { "" }
            $customEndDate = if ($ticket.CustomEndDate) { $ticket.CustomEndDate } else { "" }
            $startDate = if ($ticket.StartDate) { $ticket.StartDate } else { "" }
            $taskType = if ($ticket.TaskType) { $ticket.TaskType } else { "Fixed" }
            
            if ($isV10) {
                # V10 format with UUID, Stakeholder, Initiative
                $uuid = if ($ticket.UUID) { $ticket.UUID } else { "" }
                $stakeholder = if ($ticket.Stakeholder) { $ticket.Stakeholder } else { "General" }
                $initiative = if ($ticket.Initiative) { $ticket.Initiative } else { "General" }
                $line = "`"$uuid`",$($ticket.ID),`"$desc`",$startDate,$($ticket.Size),$($ticket.Priority),`"$assignedTeam`",`"$stakeholder`",`"$initiative`",`"$($ticket.Status)`",`"$taskType`",`"$pauseComments`",`"$startDateHistory`",`"$endDateHistory`",`"$sizeHistory`",`"$customEndDate`",`"$detailsDesc`",`"$detailsPos`",`"$detailsNeg`""
            } else {
                # V9 format
                $line = "$($ticket.ID),`"$desc`",$startDate,$($ticket.Size),$($ticket.Priority),`"$assignedTeam`",`"$($ticket.Status)`",`"$taskType`",`"$pauseComments`",`"$startDateHistory`",`"$endDateHistory`",`"$sizeHistory`",`"$customEndDate`",`"$detailsDesc`",`"$detailsPos`",`"$detailsNeg`""
            }
            [void]$csvContent.AppendLine($line)
        }
        
        # Write to file
        $csvContent.ToString() | Set-Content -Path $FilePath -Encoding UTF8 -NoNewline
        
        $formatVersion = if ($isV10) { "V10" } else { "V9" }
        $v10Info = if ($isV10) { ", $($ConfigData.Stakeholders.Count) stakeholders, $($ConfigData.Initiatives.Count) initiatives" } else { "" }
        Write-Host "✅ $formatVersion config saved successfully: $($ConfigData.Tickets.Count) tickets$v10Info" -ForegroundColor Green
        
        return $true
        
    } catch {
        Write-Host "❌ Error writing V9 config file: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Line: $($_.InvocationInfo.ScriptLineNumber)" -ForegroundColor Red
        return $false
    }
}

function Convert-V9TicketToLegacyTask {
    <#
    .SYNOPSIS
        Converts a V9 ticket object to legacy task_progress_data.csv format
    
    .DESCRIPTION
        Maps V9 ticket fields to the legacy flat CSV format used by helper.ps1:
        - ID → Ticket ID
        - Description → Task Description
        - AssignedTeam → EmployeeName (first person, or "UA" if unassigned)
        - Priority → Priority (P1→1, P2→2, etc.)
        - StartDate → StartDate
        - Status → Status
    
    .PARAMETER Ticket
        V9 ticket object to convert
    
    .OUTPUTS
        PSCustomObject compatible with legacy task format
    
    .EXAMPLE
        $task = Convert-V9TicketToLegacyTask -Ticket $v9Ticket
    #>
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Ticket
    )
    
    # Map V9 status to legacy status
    $statusMap = @{
        'To Do' = 'Planned'
        'In Progress' = 'Active'
        'Completed' = 'Completed'
        'Blocked' = 'Blocked'
        'Closed' = 'Completed'
    }
    
    $legacyStatus = if ($statusMap.ContainsKey($Ticket.Status)) {
        $statusMap[$Ticket.Status]
    } else {
        'Planned'
    }
    
    # Extract first assigned person or use "UA" for unassigned
    $employeeName = if ($Ticket.AssignedTeam -and $Ticket.AssignedTeam.Count -gt 0) {
        $Ticket.AssignedTeam[0]
    } else {
        "UA"
    }
    
    # Convert priority (P1→1, P2→2, etc.)
    $priority = if ($Ticket.Priority -match 'P(\d+)') {
        $Matches[1]
    } else {
        "3"  # Default to 3
    }
    
    return [PSCustomObject]@{
        TicketID = $Ticket.ID
        EmployeeName = $employeeName
        'Task Description' = $Ticket.Description
        Priority = $priority
        StartDate = $Ticket.StartDate
        Size = $Ticket.Size
        Status = $legacyStatus
        V9Status = $Ticket.Status  # Preserve original status
        AssignedTeam = $Ticket.AssignedTeam -join ';'
        TaskType = $Ticket.TaskType
    }
}

function Test-V9ConfigFile {
    <#
    .SYNOPSIS
        Validates a V9 config file for integrity
    
    .DESCRIPTION
        Performs validation checks on a V9 config file:
        - File exists and is readable
        - All required sections present
        - Required fields in each section
        - Data consistency (ticket IDs unique, references valid, etc.)
    
    .PARAMETER FilePath
        Path to the V9 config file to validate
    
    .OUTPUTS
        Hashtable with keys: IsValid (bool), Errors (array), Warnings (array)
    
    .EXAMPLE
        $validation = Test-V9ConfigFile -FilePath $configFile
        if (!$validation.IsValid) {
            $validation.Errors | ForEach-Object { Write-Host $_ -ForegroundColor Red }
        }
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$FilePath
    )
    
    $result = @{
        IsValid = $true
        Errors = @()
        Warnings = @()
    }
    
    if (!(Test-Path $FilePath)) {
        $result.IsValid = $false
        $result.Errors += "File not found: $FilePath"
        return $result
    }
    
    try {
        $config = Read-V9ConfigFile -FilePath $FilePath
        
        if ($null -eq $config) {
            $result.IsValid = $false
            $result.Errors += "Failed to parse config file"
            return $result
        }
        
        # Check for required sections
        if ($config.Metadata.Count -eq 0) {
            $result.Warnings += "Missing or empty METADATA section"
        }
        
        if ($config.Settings.Count -eq 0) {
            $result.Warnings += "Missing or empty SETTINGS section"
        }
        
        if ($config.TaskSizes.Count -eq 0) {
            $result.IsValid = $false
            $result.Errors += "Missing or empty TASK_SIZES section"
        }
        
        if ($config.People.Count -eq 0) {
            $result.Warnings += "No people defined in PEOPLE section"
        }
        
        # Check for duplicate ticket IDs
        $ticketIds = $config.Tickets | ForEach-Object { $_.ID }
        $duplicates = $ticketIds | Group-Object | Where-Object { $_.Count -gt 1 }
        if ($duplicates) {
            $result.IsValid = $false
            $result.Errors += "Duplicate ticket IDs found: $($duplicates.Name -join ', ')"
        }
        
        # Check for invalid task sizes
        $validSizes = $config.TaskSizes | ForEach-Object { $_.Key }
        $invalidSizes = $config.Tickets | Where-Object { $_.Size -notin $validSizes }
        if ($invalidSizes.Count -gt 0) {
            $result.Warnings += "$($invalidSizes.Count) tickets have invalid size references"
        }
        
        # Check for invalid person assignments
        $validPeople = $config.People | ForEach-Object { $_.Name }
        foreach ($ticket in $config.Tickets) {
            $invalidPeople = $ticket.AssignedTeam | Where-Object { $_ -notin $validPeople -and $_ -ne '' }
            if ($invalidPeople.Count -gt 0) {
                $result.Warnings += "Ticket $($ticket.ID) assigned to unknown people: $($invalidPeople -join ', ')"
            }
        }
        
        Write-Host "✅ V9 config validation complete" -ForegroundColor Green
        if ($result.Errors.Count -gt 0) {
            Write-Host "   ❌ $($result.Errors.Count) errors found" -ForegroundColor Red
        }
        if ($result.Warnings.Count -gt 0) {
            Write-Host "   ⚠️  $($result.Warnings.Count) warnings found" -ForegroundColor Yellow
        }
        
    } catch {
        $result.IsValid = $false
        $result.Errors += "Validation exception: $($_.Exception.Message)"
    }
    
    return $result
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-LatestV9ConfigFile',
    'Read-V9ConfigFile',
    'Write-V9ConfigFile',
    'Convert-V9TicketToLegacyTask',
    'Test-V9ConfigFile'
)

Write-Host "✅ V10/V9 CSV Adapter module loaded" -ForegroundColor Green
Write-Host "   Available functions: Get-LatestV9ConfigFile, Read-V9ConfigFile, Write-V9ConfigFile, Convert-V9TicketToLegacyTask, Test-V9ConfigFile" -ForegroundColor Cyan
Write-Host "   📌 V10 primary with V9 backward compatibility" -ForegroundColor DarkCyan
