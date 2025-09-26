# Excel Export Module for Task Progress Tracking
# Phase 1: Data Export and Preparation for Excel-based Task Tracker

function Export-TaskDataForExcel {
    param(
        [string]$ExportFolder = "./ExcelExport/Data",
        [switch]$IncludeMetadata = $true,
        [switch]$Verbose = $false
    )
    
    Write-Host "`n📊 Starting Excel Export Process..." -ForegroundColor Cyan
    
    # Ensure export folder exists
    if (-not (Test-Path $ExportFolder)) {
        New-Item -ItemType Directory -Path $ExportFolder -Force | Out-Null
        Write-Host "✅ Created export directory: $ExportFolder" -ForegroundColor Green
    }
    
    # Phase 1.1: Export Current Task Data
    Export-CurrentTaskData -ExportFolder $ExportFolder -Verbose:$Verbose
    
    # Phase 1.2: Export Historical Snapshots
    Export-HistoricalSnapshots -ExportFolder $ExportFolder -Verbose:$Verbose
    
    # Phase 1.3: Generate Metadata
    if ($IncludeMetadata) {
        Generate-ExcelMetadata -ExportFolder $ExportFolder -Verbose:$Verbose
    }
    
    # Phase 1.4: Create Excel-friendly combined dataset
    Create-CombinedDataset -ExportFolder $ExportFolder -Verbose:$Verbose
    
    Write-Host "`n🎉 Excel export completed successfully!" -ForegroundColor Green
    Write-Host "📁 Data exported to: $ExportFolder" -ForegroundColor Yellow
    
    # Show export summary
    Show-ExportSummary -ExportFolder $ExportFolder
}

function Export-CurrentTaskData {
    param(
        [string]$ExportFolder,
        [switch]$Verbose
    )
    
    if ($Verbose) { Write-Host "📋 Exporting current task data..." -ForegroundColor Yellow }
    
    $TaskFile = "./task_progress_data.csv"
    $OutputFile = Join-Path $ExportFolder "current_tasks.csv"
    
    if (Test-Path $TaskFile) {
        # Copy current tasks with Excel-friendly formatting
        $Tasks = Import-Csv $TaskFile
        
        # Add Excel-specific columns and formatting
        $ExcelTasks = $Tasks | ForEach-Object {
            [PSCustomObject]@{
                EmployeeName = $_.'EmployeeName' -replace '"', ''
                TaskDescription = $_.'Task Description' -replace '"', ''
                Priority = [int]$_.Priority
                StartDate = $_.StartDate
                ETA = $_.ETA
                Progress = [int]($_.Progress -replace '%', '')
                ProgressPercent = $_.Progress
                Status = $_.Status
                ProgressReportSent = $_.ProgressReportSent
                FinalReportSent = $_.FinalReportSent
                CreatedDate = $_.Created_Date
                SnapshotType = "Current"
                SnapshotDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
        
        $ExcelTasks | Export-Csv -Path $OutputFile -NoTypeInformation
        
        if ($Verbose) { 
            Write-Host "  ✅ Current tasks exported: $($ExcelTasks.Count) tasks" -ForegroundColor Green 
        }
    } else {
        Write-Host "  ⚠️ Current task file not found: $TaskFile" -ForegroundColor Yellow
    }
}

function Export-HistoricalSnapshots {
    param(
        [string]$ExportFolder,
        [switch]$Verbose
    )
    
    if ($Verbose) { Write-Host "📚 Exporting historical snapshots..." -ForegroundColor Yellow }
    
    $HistoryFolder = "./history"
    $OutputFile = Join-Path $ExportFolder "historical_snapshots.csv"
    
    if (-not (Test-Path $HistoryFolder)) {
        Write-Host "  ⚠️ History folder not found: $HistoryFolder" -ForegroundColor Yellow
        return
    }
    
    $AllHistoricalTasks = @()
    $SnapshotCount = 0
    
    # Get all CSV files sorted by date
    $HistoryFiles = Get-ChildItem $HistoryFolder -Filter "*.csv" | Sort-Object Name
    
    foreach ($HistoryFile in $HistoryFiles) {
        try {
            $HistoryData = Import-Csv $HistoryFile.FullName
            $Timestamp = $HistoryFile.Name.Split('_')[0..1] -join '_'
            $ParsedDate = [DateTime]::ParseExact($Timestamp, "yyyy-MM-dd_HH-mm-ss", $null)
            
            # Process each task in this snapshot
            foreach ($Task in $HistoryData) {
                $ExcelTask = [PSCustomObject]@{
                    EmployeeName = Normalize-EmployeeName -Name $Task.EmployeeName
                    TaskDescription = $Task.'Task Description' -replace '"', ''
                    Priority = [int]$Task.Priority
                    StartDate = $Task.StartDate
                    ETA = $Task.ETA
                    Progress = [int]($Task.Progress -replace '%', '')
                    ProgressPercent = $Task.Progress
                    Status = $Task.Status
                    ProgressReportSent = $Task.ProgressReportSent
                    FinalReportSent = $Task.FinalReportSent
                    CreatedDate = $Task.Created_Date
                    SnapshotType = "Historical"
                    SnapshotDate = $ParsedDate.ToString("yyyy-MM-dd HH:mm:ss")
                    SnapshotFile = $HistoryFile.Name
                    SnapshotIndex = $SnapshotCount
                }
                $AllHistoricalTasks += $ExcelTask
            }
            
            $SnapshotCount++
            
        } catch {
            if ($Verbose) {
                Write-Host "  ⚠️ Skipped invalid file: $($HistoryFile.Name)" -ForegroundColor Yellow
            }
        }
    }
    
    # Export all historical data
    $AllHistoricalTasks | Export-Csv -Path $OutputFile -NoTypeInformation
    
    if ($Verbose) {
        Write-Host "  ✅ Historical snapshots exported: $SnapshotCount snapshots, $($AllHistoricalTasks.Count) total task records" -ForegroundColor Green
    }
}

function Normalize-EmployeeName {
    param([string]$Name)
    
    if (-not $Name) { return $Name }
    
    $CleanName = $Name.Trim().Replace('"', '')
    $LowerName = $CleanName.ToLower()
    
    switch ($LowerName) {
        'peter' { return 'Peter' }
        'vipul' { return 'Vipul' }
        'siva' { return 'Siva' }
        'sivakumar' { return 'Sivakumar' }
        default { 
            return $CleanName.Substring(0,1).ToUpper() + $CleanName.Substring(1).ToLower()
        }
    }
}

function Generate-ExcelMetadata {
    param(
        [string]$ExportFolder,
        [switch]$Verbose
    )
    
    if ($Verbose) { Write-Host "📋 Generating metadata..." -ForegroundColor Yellow }
    
    $MetadataFile = Join-Path $ExportFolder "metadata.json"
    
    # Collect metadata information
    $CurrentTasks = @()
    $HistoricalSnapshots = @()
    $Employees = @()
    
    # Get current task count
    $CurrentTaskFile = Join-Path $ExportFolder "current_tasks.csv"
    if (Test-Path $CurrentTaskFile) {
        $CurrentTasks = Import-Csv $CurrentTaskFile
    }
    
    # Get historical snapshot info
    $HistoricalFile = Join-Path $ExportFolder "historical_snapshots.csv"
    if (Test-Path $HistoricalFile) {
        $AllHistorical = Import-Csv $HistoricalFile
        $HistoricalSnapshots = $AllHistorical | Group-Object SnapshotDate | ForEach-Object {
            @{
                Date = $_.Name
                TaskCount = $_.Count
                Snapshot = ($_.Group | Select-Object -First 1).SnapshotFile
                Index = ($_.Group | Select-Object -First 1).SnapshotIndex
            }
        }
        
        # Get unique employees
        $Employees = ($AllHistorical + $CurrentTasks) | 
            Select-Object -ExpandProperty EmployeeName -Unique | 
            Sort-Object
    }
    
    $Metadata = @{
        ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        CurrentTaskCount = $CurrentTasks.Count
        HistoricalSnapshotCount = $HistoricalSnapshots.Count
        TotalTaskRecords = ($CurrentTasks.Count + $AllHistorical.Count)
        Employees = $Employees
        DateRange = @{
            Earliest = ($HistoricalSnapshots | Sort-Object Date | Select-Object -First 1).Date
            Latest = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        }
        ExcelSettings = @{
            TimelineMaxIndex = $HistoricalSnapshots.Count
            DefaultView = "Dashboard"
            EnableAutoRefresh = $true
            RefreshIntervalMinutes = 5
        }
        HistoricalSnapshots = $HistoricalSnapshots
    }
    
    $Metadata | ConvertTo-Json -Depth 10 | Out-File -FilePath $MetadataFile -Encoding UTF8
    
    if ($Verbose) {
        Write-Host "  ✅ Metadata generated with $($Employees.Count) employees and $($HistoricalSnapshots.Count) snapshots" -ForegroundColor Green
    }
}

function Create-CombinedDataset {
    param(
        [string]$ExportFolder,
        [switch]$Verbose
    )
    
    if ($Verbose) { Write-Host "🔄 Creating combined dataset..." -ForegroundColor Yellow }
    
    $CombinedFile = Join-Path $ExportFolder "combined_timeline_data.csv"
    $AllData = @()
    
    # Load current tasks
    $CurrentFile = Join-Path $ExportFolder "current_tasks.csv"
    if (Test-Path $CurrentFile) {
        $CurrentData = Import-Csv $CurrentFile
        $AllData += $CurrentData
    }
    
    # Load historical tasks
    $HistoricalFile = Join-Path $ExportFolder "historical_snapshots.csv"
    if (Test-Path $HistoricalFile) {
        $HistoricalData = Import-Csv $HistoricalFile
        $AllData += $HistoricalData
    }
    
    # Sort by snapshot date and employee name
    $SortedData = $AllData | Sort-Object SnapshotDate, EmployeeName, TaskDescription
    
    # Export combined dataset
    $SortedData | Export-Csv -Path $CombinedFile -NoTypeInformation
    
    if ($Verbose) {
        Write-Host "  ✅ Combined dataset created with $($SortedData.Count) total records" -ForegroundColor Green
    }
}

function Show-ExportSummary {
    param([string]$ExportFolder)
    
    Write-Host "`n📊 EXPORT SUMMARY" -ForegroundColor Cyan
    Write-Host "===========================================" -ForegroundColor Cyan
    
    $Files = @(
        @{ Name = "current_tasks.csv"; Description = "Current task data" }
        @{ Name = "historical_snapshots.csv"; Description = "All historical snapshots" }
        @{ Name = "combined_timeline_data.csv"; Description = "Combined timeline dataset" }
        @{ Name = "metadata.json"; Description = "Export metadata and settings" }
    )
    
    foreach ($File in $Files) {
        $FilePath = Join-Path $ExportFolder $File.Name
        if (Test-Path $FilePath) {
            $Size = (Get-Item $FilePath).Length
            $SizeKB = [math]::Round($Size / 1024, 2)
            Write-Host "✅ $($File.Name.PadRight(30)) - $($File.Description) ($SizeKB KB)" -ForegroundColor Green
        } else {
            Write-Host "❌ $($File.Name.PadRight(30)) - Missing" -ForegroundColor Red
        }
    }
    
    Write-Host "`n🎯 Next Steps:" -ForegroundColor Yellow
    Write-Host "   1. Data is ready for Excel import" -ForegroundColor White
    Write-Host "   2. Use 'excel' command to continue with Template creation" -ForegroundColor White
    Write-Host "   3. Or manually import CSV files into Excel" -ForegroundColor White
}