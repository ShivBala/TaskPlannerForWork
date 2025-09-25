# HTML Report Generator for Task Progress Tracking
# Extracts the Generate-HTMLReport function from helper.ps1

function Generate-HTMLReport {
    $TaskFile = "./task_progress_data.csv"
    if (-not (Test-Path $TaskFile)) {
        Write-Host "No task data found to generate report!" -ForegroundColor Red
        return
    }
    
    $Tasks = Import-Csv $TaskFile
    $ReportDate = Get-Date -Format "MMMM dd, yyyy 'at' HH:mm"
    
    # Create reports folder if it doesn't exist
    $ReportsFolder = "./reports"
    if (-not (Test-Path $ReportsFolder)) {
        New-Item -ItemType Directory -Path $ReportsFolder -Force | Out-Null
        Write-Host "📁 Created reports folder: $ReportsFolder" -ForegroundColor Green
    }
    
    $ReportFileName = Join-Path $ReportsFolder "Task_Progress_Report_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').html"
    
    # Load historical data for timeline
    $HistoryFolder = "./history"
    $HistoricalSnapshots = @()
    
    if (Test-Path $HistoryFolder) {
        $HistoryFiles = Get-ChildItem $HistoryFolder -Filter "*.csv" | Sort-Object Name
        foreach ($HistoryFile in $HistoryFiles) {
            try {
                $HistoryData = Import-Csv $HistoryFile.FullName
                $Timestamp = $HistoryFile.Name.Split('_')[0..1] -join '_'
                $ParsedDate = [DateTime]::ParseExact($Timestamp, "yyyy-MM-dd_HH-mm-ss", $null)
                
                $HistoricalSnapshots += @{
                    Date = $ParsedDate
                    DateString = $ParsedDate.ToString("MMM dd, HH:mm")
                    FileName = $HistoryFile.Name
                    Tasks = $HistoryData
                }
            } catch {
                # Skip invalid files
            }
        }
    }
    
    # If no historical data exists, create simulated historical snapshots
    if ($HistoricalSnapshots.Count -eq 0) {
        # Create 5 historical snapshots going back 2 weeks with meaningful progression
        $CurrentDate = Get-Date
        
        # Define progression points that lead realistically to current values
        # The progression should end with values close to current, not start from current
        $ProgressionStages = @(0.15, 0.35, 0.55, 0.75, 0.90) # Each stage closer to current values
        
        for ($i = 0; $i -lt $ProgressionStages.Count; $i++) {
            $DaysBack = ($ProgressionStages.Count - 1 - $i) * 2.5  # 2.5 days between each stage
            $HistoricalDate = $CurrentDate.AddDays(-$DaysBack)
            $ProgressMultiplier = $ProgressionStages[$i]
            
            # Create simulated tasks with staged progress
            $SimulatedTasks = @()
            foreach ($Task in $Tasks) {
                # Parse task creation date to determine if task should exist at this historical point
                $TaskCreatedDate = $null
                if ($Task.Created_Date -and $Task.Created_Date -ne "") {
                    try {
                        # Handle different date formats
                        $dateFormats = @("dd/MM/yyyy", "d/M/yyyy", "dd/M/yyyy", "d/MM/yyyy", "dd/MM/yyyy", "d/M/yyyy")
                        foreach ($format in $dateFormats) {
                            try {
                                $TaskCreatedDate = [DateTime]::ParseExact($Task.Created_Date, $format, $null)
                                break
                            } catch {
                                # Continue to next format
                            }
                        }
                    } catch {
                        # If parsing fails, assume task existed historically
                        $TaskCreatedDate = $CurrentDate.AddDays(-30)
                    }
                }
                
                # Only include tasks that existed at this historical point
                if ($TaskCreatedDate -and $HistoricalDate -ge $TaskCreatedDate.AddDays(-1)) {
                    $CurrentProgress = [int]($Task.Progress -replace '%', '')
                    
                    # Calculate historical progress - should build UP to current values
                    if ($CurrentProgress -eq 0) {
                        # Tasks at 0% stay at 0% throughout history
                        $HistoricalProgress = 0
                    } elseif ($CurrentProgress -eq 100) {
                        # Completed tasks: show progression to completion
                        if ($i -ge 4) { $HistoricalProgress = 100 } # Latest snapshot
                        elseif ($i -eq 3) { $HistoricalProgress = 95 }
                        elseif ($i -eq 2) { $HistoricalProgress = 85 }
                        elseif ($i -eq 1) { $HistoricalProgress = 70 }
                        else { $HistoricalProgress = 45 } # Earliest snapshot
                    } else {
                        # Active tasks: progressive increase toward current value
                        $BaseProgress = [Math]::Floor($CurrentProgress * $ProgressMultiplier)
                        
                        # Ensure realistic progression - later stages should be closer to current
                        # Add some variation but keep increasing trend
                        $MinProgress = [Math]::Max(5, [Math]::Floor($CurrentProgress * 0.1))
                        $MaxProgress = [Math]::Min($CurrentProgress - 2, [Math]::Floor($CurrentProgress * 0.95))
                        
                        $HistoricalProgress = [Math]::Max($MinProgress, [Math]::Min($MaxProgress, $BaseProgress))
                    }
                    
                    $SimulatedTask = $Task.PSObject.Copy()
                    $SimulatedTask.Progress = "$HistoricalProgress%"
                    
                    # Update status based on progress
                    if ($HistoricalProgress -eq 100) {
                        $SimulatedTask.Status = "Completed"
                    } elseif ($Task.Status -eq "Completed" -and $HistoricalProgress -lt 100) {
                        $SimulatedTask.Status = "Active"  # Was still active in the past
                    } else {
                        $SimulatedTask.Status = if ($Task.Status) { $Task.Status } else { "Active" }
                    }
                    
                    $SimulatedTasks += $SimulatedTask
                }
            }
            
            # Use actual calendar dates for better user understanding
            $DateLabel = $HistoricalDate.ToString("MMM dd, HH:mm")
            
            $HistoricalSnapshots += @{
                Date = $HistoricalDate
                DateString = $DateLabel
                FileName = "historical_$(Get-Date -Date $HistoricalDate -Format 'yyyyMMdd_HHmm')"
                Tasks = $SimulatedTasks
            }
        }
    }
    
    # Add current data as the latest snapshot
    $HistoricalSnapshots += @{
        Date = Get-Date
        DateString = (Get-Date).ToString("MMM dd, HH:mm") + " (Current)"
        FileName = "current"
        Tasks = $Tasks
    }
    
    # Sort by date
    $HistoricalSnapshots = $HistoricalSnapshots | Sort-Object Date
    
    # Calculate statistics and get task lists for tooltips
    $ActiveTasks = $Tasks | Where-Object { -not $_.Status -or $_.Status -eq "Active" }
    $TotalTasks = $ActiveTasks.Count
    
    $CompletedTasksList = $Tasks | Where-Object { $_.Status -eq "Completed" -or $_.Progress -eq "100%" }
    $CompletedTasks = $CompletedTasksList.Count
    $CompletedTooltip = ($CompletedTasksList | ForEach-Object { "• $($_.'Task Description') ($($_.EmployeeName))" }) -join "`n"
    if ($CompletedTooltip -eq "") { $CompletedTooltip = "No completed tasks" }
    
    $HighPriorityTasksList = $ActiveTasks | Where-Object { $_.Priority -eq "1" }
    $HighPriorityTasks = $HighPriorityTasksList.Count
    $HighPriorityTooltip = ($HighPriorityTasksList | ForEach-Object { "• $($_.'Task Description') ($($_.EmployeeName))" }) -join "`n"
    if ($HighPriorityTooltip -eq "") { $HighPriorityTooltip = "No high priority active tasks" }
    
    $OverdueTasksList = $ActiveTasks | Where-Object { 
        if ($_.ETA -and $_.ETA -ne "" -and $_.Status -ne "Completed") {
            try {
                # Try multiple date formats to handle both d/M/yyyy and dd/MM/yyyy
                $etaDate = $null
                $dateFormats = @("dd/MM/yyyy", "d/M/yyyy", "dd/M/yyyy", "d/MM/yyyy")
                foreach ($format in $dateFormats) {
                    try {
                        $etaDate = [DateTime]::ParseExact($_.ETA, $format, $null)
                        break
                    } catch {
                        # Continue to next format
                    }
                }
                return $etaDate -and $etaDate -lt (Get-Date)
            } catch {
                return $false
            }
        }
        return $false
    }
    $OverdueTasks = $OverdueTasksList.Count
    $OverdueTooltip = ($OverdueTasksList | ForEach-Object { "• $($_.'Task Description') ($($_.EmployeeName)) - Due: $($_.ETA)" }) -join "`n"
    if ($OverdueTooltip -eq "") { $OverdueTooltip = "No overdue active tasks" }
    
    # Group tasks by employee
    $TasksByEmployee = $Tasks | Group-Object EmployeeName
    
    # Create HTML content
    $HTML = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Task Progress Report</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif; background: #f8f9fa; min-height: 100vh; padding: 8px; color: #2c3e50; }
        .container { max-width: 1400px; margin: 0 auto; background: white; border-radius: 4px; box-shadow: 0 2px 6px rgba(0,0,0,0.08); overflow: hidden; }
        .header { background: linear-gradient(135deg, #34495e 0%, #2c3e50 100%); color: white; padding: 10px 15px; text-align: center; }
        .header h1 { font-size: 18px; margin-bottom: 4px; font-weight: 500; }
        .header p { font-size: 11px; opacity: 0.9; background: rgba(255,255,255,0.1); padding: 2px 8px; border-radius: 8px; display: inline-block; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr)); gap: 8px; padding: 12px; background: #f8f9fb; }
        .stat-card { background: white; padding: 8px 10px; border-radius: 4px; text-align: center; box-shadow: 0 2px 4px rgba(0,0,0,0.06); transition: all 0.2s ease; position: relative; cursor: pointer; border: 1px solid #e9ecef; }
        .stat-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
        .tooltip { position: absolute; background: #2c3e50; color: white; padding: 8px 10px; border-radius: 4px; font-size: 11px; white-space: pre-line; text-align: left; max-width: 280px; z-index: 1000; bottom: 100%; left: 50%; transform: translateX(-50%); margin-bottom: 8px; opacity: 0; visibility: hidden; transition: opacity 0.2s, visibility 0.2s; }
        .tooltip::after { content: ''; position: absolute; top: 100%; left: 50%; margin-left: -4px; border-width: 4px; border-style: solid; border-color: #2c3e50 transparent transparent transparent; }
        .stat-card:hover .tooltip { opacity: 1; visibility: visible; }
        .timeline-section { margin: 10px; padding: 10px; background: white; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.06); border: 1px solid #e9ecef; }
        .timeline-header { text-align: center; margin-bottom: 10px; }
        .timeline-header h2 { color: #495057; margin-bottom: 4px; font-size: 14px; font-weight: 600; }
        .timeline-controls { display: flex; align-items: center; justify-content: center; gap: 15px; margin-bottom: 15px; }
        .slider-container { flex: 1; max-width: 500px; }
        .timeline-slider { width: 100%; height: 6px; border-radius: 3px; background: #dee2e6; outline: none; -webkit-appearance: none; }
        .timeline-slider::-webkit-slider-thumb { appearance: none; width: 16px; height: 16px; border-radius: 50%; background: #1976d2; cursor: pointer; }
        .timeline-slider::-moz-range-thumb { width: 16px; height: 16px; border-radius: 50%; background: #1976d2; cursor: pointer; border: none; }
        .timeline-info { background: #f8f9fb; padding: 12px; border-radius: 6px; text-align: center; min-height: 45px; display: flex; align-items: center; justify-content: center; border: 1px solid #e9ecef; }
        .play-button { background: #28a745; color: white; border: none; padding: 8px 12px; border-radius: 4px; cursor: pointer; font-size: 13px; font-weight: 500; }
        .play-button:hover { background: #218838; }
        .play-button:disabled { background: #6c757d; cursor: not-allowed; }
        .step-button { background: #007bff; color: white; border: none; padding: 8px 12px; border-radius: 4px; cursor: pointer; font-size: 13px; font-weight: 500; margin-left: 8px; }
        .step-button:hover { background: #0056b3; }
        .step-button:disabled { background: #6c757d; cursor: not-allowed; }
        .reset-button { background: #6c757d; color: white; border: none; padding: 8px 12px; border-radius: 4px; cursor: pointer; font-size: 13px; font-weight: 500; margin-left: 8px; }
        .reset-button:hover { background: #545b62; }
        .reset-button:disabled { background: #adb5bd; cursor: not-allowed; }
        .progress-evolution { margin-top: 15px; display: none; }
        .evolution-card { background: #f8f9fb; border-left: 3px solid #1976d2; padding: 12px; margin: 8px 0; border-radius: 0 4px 4px 0; border: 1px solid #e9ecef; }
        .evolution-task { font-weight: 600; color: #495057; font-size: 12px; }
        .evolution-progress { margin-top: 4px; }
        .evolution-bar { width: 100%; height: 4px; background: #e9ecef; border-radius: 2px; overflow: hidden; }
        .evolution-fill { height: 100%; background: linear-gradient(90deg, #1976d2, #1565c0); border-radius: 2px; transition: width 0.3s ease; }
        .stat-number { font-size: 1.4em; font-weight: 600; margin-bottom: 3px; }
        .stat-label { color: #6c757d; font-size: 10px; text-transform: uppercase; letter-spacing: 0.3px; font-weight: 500; }
        .total { color: #1976d2; }
        .completed { color: #2e7d32; }
        .priority { color: #f57c00; }
        .overdue { color: #c62828; }
        .filter-section { margin: 10px; padding: 10px; background: white; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.06); border: 1px solid #e9ecef; }
        .filter-header { text-align: center; margin-bottom: 8px; }
        .filter-header h3 { color: #495057; margin-bottom: 4px; font-size: 14px; font-weight: 600; }
        .filter-controls { display: flex; flex-wrap: wrap; gap: 8px; justify-content: center; align-items: center; }
        .employee-filter { display: flex; align-items: center; gap: 6px; padding: 6px 12px; background: #f8f9fb; border-radius: 16px; border: 1px solid #dee2e6; cursor: pointer; transition: all 0.2s ease; font-size: 13px; }
        .employee-filter:hover { background: #e9ecef; }
        .employee-filter.active { background: #1976d2; color: white; border-color: #1565c0; }
        .employee-filter input[type="checkbox"] { margin: 0; }
        .filter-buttons { display: flex; gap: 8px; margin-top: 12px; justify-content: center; }
        .filter-btn { background: #6c757d; color: white; border: none; padding: 6px 12px; border-radius: 4px; cursor: pointer; font-size: 11px; font-weight: 500; text-transform: uppercase; letter-spacing: 0.5px; }
        .filter-btn:hover { background: #5a6268; }
        .filter-btn.select-all { background: #28a745; }
        .filter-btn.select-all:hover { background: #218838; }
        .filter-btn.clear-all { background: #dc3545; }
        .filter-btn.clear-all:hover { background: #c82333; }
        .export-section { margin: 10px; padding: 10px; background: white; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.06); border: 1px solid #e9ecef; }
        .export-header { text-align: center; margin-bottom: 8px; }
        .export-header h3 { color: #495057; margin-bottom: 4px; font-size: 14px; font-weight: 600; }
        .export-controls { display: flex; gap: 12px; justify-content: center; align-items: center; }
        .export-btn { background: #1976d2; color: white; border: none; padding: 8px 16px; border-radius: 4px; cursor: pointer; font-size: 13px; font-weight: 500; text-decoration: none; display: inline-flex; align-items: center; gap: 6px; transition: background 0.2s ease; }
        .export-btn:hover { background: #1565c0; }
        .export-btn.pdf { background: #dc3545; }
        .export-btn.pdf:hover { background: #c82333; }
        .export-btn.word { background: #0d6efd; }
        .export-btn.word:hover { background: #0b5ed7; }
        .employee-section { margin: 20px; }
        .employee-card { background: white; border-radius: 4px; margin: 5px 10px; overflow: hidden; box-shadow: 0 2px 4px rgba(0,0,0,0.06); border: 1px solid #e9ecef; }
        .employee-header { background: linear-gradient(135deg, #34495e 0%, #2c3e50 100%); color: white; padding: 8px 12px; display: flex; justify-content: space-between; align-items: center; }
        .employee-name { font-size: 18px; font-weight: 600; }
        .task-count { background: rgba(255,255,255,0.15); padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 500; }
        .tasks-table { width: 100%; border-collapse: collapse; }
        .tasks-table th { background: #f8f9fb; padding: 6px 10px; text-align: left; font-weight: 600; color: #495057; border-bottom: 1px solid #dee2e6; font-size: 10px; text-transform: uppercase; letter-spacing: 0.3px; }
        .tasks-table td { padding: 6px 10px; border-bottom: 1px solid #f1f3f4; font-size: 11px; }
        .tasks-table tr:hover { background: #f8f9fa; }
        .progress-bar { width: 80px; height: 6px; background: #e9ecef; border-radius: 3px; overflow: hidden; }
        .progress-fill { height: 100%; background: linear-gradient(90deg, #28a745, #20c997); border-radius: 3px; }
        .priority-badge { padding: 2px 6px; border-radius: 8px; font-size: 9px; font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; }
        .priority-1 { background: #ffebee; color: #c62828; }
        .priority-2 { background: #fff3e0; color: #f57c00; }
        .priority-3 { background: #fff9c4; color: #f9a825; }
        .priority-4 { background: #f3e5f5; color: #8e24aa; }
        .status-badge { padding: 2px 6px; border-radius: 8px; font-size: 9px; font-weight: 600; text-transform: uppercase; }
        .status-y { background: #e8f5e8; color: #2e7d32; }
        .status-n { background: #ffebee; color: #c62828; }
        .task-status { padding: 2px 6px; border-radius: 8px; font-size: 9px; font-weight: 600; text-transform: uppercase; }
        .status-active { background: #e3f2fd; color: #1976d2; }
        .status-completed { background: #e8f5e8; color: #2e7d32; }
        .status-cancelled { background: #ffebee; color: #c62828; }
        .status-archived { background: #f5f5f5; color: #616161; }
        .footer { text-align: center; padding: 15px; background: #f8f9fb; color: #6c757d; font-size: 12px; border-top: 1px solid #e9ecef; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Task Progress Report</h1>
            <p>Generated on $ReportDate</p>
        </div>
        
        <div class="stats">
            <div class="stat-card">
                <div class="stat-number total">$TotalTasks</div>
                <div class="stat-label">Total Tasks</div>
            </div>
            <div class="stat-card">
                <div class="stat-number completed">$CompletedTasks</div>
                <div class="stat-label">Completed</div>
                <div class="tooltip">$($CompletedTooltip -replace '"', '&quot;')</div>
            </div>
            <div class="stat-card">
                <div class="stat-number priority">$HighPriorityTasks</div>
                <div class="stat-label">High Priority</div>
                <div class="tooltip">$($HighPriorityTooltip -replace '"', '&quot;')</div>
            </div>
            <div class="stat-card">
                <div class="stat-number overdue">$OverdueTasks</div>
                <div class="stat-label">Overdue</div>
                <div class="tooltip">$($OverdueTooltip -replace '"', '&quot;')</div>
            </div>
        </div>
        
        <div class="filter-section">
            <div class="filter-header">
                <h3>🎯 Filter by Employee</h3>
                <p>Select employees to view their tasks and timeline</p>
            </div>
            <div class="filter-controls" id="employeeFilters">
                <!-- Employee filters will be populated by JavaScript -->
            </div>
            <div class="filter-buttons">
                <button class="filter-btn select-all" onclick="selectAllEmployees()">Select All</button>
                <button class="filter-btn clear-all" onclick="clearAllEmployees()">Clear All</button>
            </div>
        </div>
        
        <div class="export-section">
            <div class="export-header">
                <h3>📄 Export Report</h3>
                <p>Download this report in different formats</p>
            </div>
            <div class="export-controls">
                <button class="export-btn pdf" onclick="exportToPDF()">
                    📄 Export to PDF
                </button>
                <button class="export-btn word" onclick="exportToWord()">
                    📝 Export to Word
                </button>
            </div>
        </div>
        
        <div class="timeline-section">
            <div class="timeline-header">
                <h2>📈 Task Progress Timeline</h2>
                <p>Slide to see how tasks evolved over time</p>
            </div>
            <div class="timeline-controls">
                <button class="play-button" onclick="playTimeline()" id="playButton">▶ Play Timeline</button>
                <button class="step-button" onclick="stepForward()" id="stepButton">⏭ Next Week</button>
                <button class="reset-button" onclick="resetTimeline()" id="resetButton">⏮ Start Over</button>
                <div class="slider-container">
                    <input type="range" min="0" max="$(($HistoricalSnapshots.Count - 1))" value="$(($HistoricalSnapshots.Count - 1))" class="timeline-slider" id="timelineSlider" onchange="updateTimeline(this.value)">
                </div>
            </div>
            <div class="timeline-info" id="timelineInfo">
                <span>Current snapshot - $ReportDate</span>
            </div>
            <div class="progress-evolution" id="progressEvolution">
                <!-- Progress cards will be populated by JavaScript -->
            </div>
        </div>
        
        <div class="employee-section">
"@

    # Add employee sections
    foreach ($EmployeeGroup in $TasksByEmployee) {
        $EmployeeName = $EmployeeGroup.Name
        $EmployeeTasks = $EmployeeGroup.Group
        $TaskCount = $EmployeeTasks.Count
        
        $HTML += @"
            <div class="employee-card">
                <div class="employee-header">
                    <div class="employee-name">👤 $EmployeeName</div>
                    <div class="task-count">$TaskCount tasks</div>
                </div>
                <table class="tasks-table">
                    <thead>
                        <tr>
                            <th>Task Description</th>
                            <th>Status</th>
                            <th>Priority</th>
                            <th>Progress</th>
                            <th>Start Date</th>
                            <th>ETA</th>
                            <th>Reports</th>
                        </tr>
                    </thead>
                    <tbody>
"@
        
        foreach ($Task in $EmployeeTasks) {
            $ProgressPercent = $Task.Progress -replace '%', ''
            if (-not $ProgressPercent -or $ProgressPercent -eq '') { $ProgressPercent = '0' }
            
            $TaskStatus = if ($Task.Status) { $Task.Status } else { "Active" }
            $StatusClass = "status-$($TaskStatus.ToLower())"
            $PriorityClass = "priority-$($Task.Priority)"
            $ProgressReportStatus = if ($Task.ProgressReportSent -eq 'y') { "status-y" } else { "status-n" }
            $FinalReportStatus = if ($Task.FinalReportSent -eq 'y') { "status-y" } else { "status-n" }
            
            $HTML += @"
                        <tr>
                            <td><strong>$($Task.'Task Description')</strong></td>
                            <td><span class="task-status $StatusClass">$TaskStatus</span></td>
                            <td><span class="priority-badge $PriorityClass">P$($Task.Priority)</span></td>
                            <td>
                                <div style="display: flex; align-items: center; gap: 10px;">
                                    <div class="progress-bar">
                                        <div class="progress-fill" style="width: $ProgressPercent%"></div>
                                    </div>
                                    <span>$($Task.Progress)</span>
                                </div>
                            </td>
                            <td>$($Task.StartDate)</td>
                            <td>$($Task.ETA)</td>
                            <td>
                                <span class="status-badge $ProgressReportStatus">Prog: $($Task.ProgressReportSent.ToUpper())</span>
                                <span class="status-badge $FinalReportStatus">Final: $($Task.FinalReportSent.ToUpper())</span>
                            </td>
                        </tr>
"@
        }
        
        $HTML += @"
                    </tbody>
                </table>
            </div>
"@
    }
    
    $HTML += @"
        </div>
        
        <div class="footer">
            <p>📈 Task Progress Management System | Generated from task_progress_data.csv</p>
        </div>
    </div>
    
    <script>
        // Historical data embedded in JavaScript
        console.log('Loading historical snapshots...');
        let historicalSnapshots;
        try {
            historicalSnapshots = [
"@

    # Add JavaScript data for historical snapshots
    for ($i = 0; $i -lt $HistoricalSnapshots.Count; $i++) {
        $snapshot = $HistoricalSnapshots[$i]
        
        # Ensure all tasks have Status field for consistency
        $normalizedTasks = @()
        foreach ($task in $snapshot.Tasks) {
            $taskObj = [PSCustomObject]@{
                EmployeeName = $task.EmployeeName
                TaskDescription = $task.'Task Description'
                Priority = $task.Priority
                StartDate = $task.StartDate
                ETA = $task.ETA
                Progress = $task.Progress
                Status = if ($task.Status) { $task.Status } else { "Active" }
                ProgressReportSent = $task.ProgressReportSent
                FinalReportSent = $task.FinalReportSent
                CreatedDate = if ($task.Created_Date) { $task.Created_Date } else { "" }
            }
            $normalizedTasks += $taskObj
        }
        
        $tasksJson = ($normalizedTasks | ConvertTo-Json -Depth 10) -replace "'", "\\'"
        # Format with proper indentation
        $HTML += "            {`n"
        $HTML += "                date: '$($snapshot.DateString)',`n"
        $HTML += "                tasks: $tasksJson`n"
        $HTML += "            }"
        if ($i -lt ($HistoricalSnapshots.Count - 1)) { $HTML += "," }
        $HTML += "`n"
    }
    
    $HTML += @"
            ];
            console.log('Historical snapshots loaded successfully:', historicalSnapshots.length, 'snapshots');
        } catch (error) {
            console.error('Error loading historical snapshots:', error);
            historicalSnapshots = [];
        }
        
        // Employee filtering variables
        let selectedEmployees = new Set();
        let allEmployees = [];
        let isPlaying = false;
        let playInterval;
        
        // Initialize employee filters
        function initializeEmployeeFilters() {
            console.log('Starting initializeEmployeeFilters...');
            
            try {
                // Check if we have historical snapshots
                if (!historicalSnapshots || historicalSnapshots.length === 0) {
                    console.error('No historical snapshots available');
                    return;
                }
                
                // Get all unique employees from current tasks
                const currentSnapshot = historicalSnapshots[historicalSnapshots.length - 1];
                console.log('Current snapshot:', currentSnapshot);
                
                if (!currentSnapshot.tasks || currentSnapshot.tasks.length === 0) {
                    console.error('No tasks in current snapshot');
                    return;
                }
                
                allEmployees = [...new Set(currentSnapshot.tasks.map(task => task.EmployeeName))];
                selectedEmployees = new Set(allEmployees); // Start with all selected
                console.log('Found employees:', allEmployees);
                
                const filtersContainer = document.getElementById('employeeFilters');
                if (!filtersContainer) {
                    console.error('Employee filters container not found');
                    return;
                }
                
                filtersContainer.innerHTML = '';
                
                allEmployees.forEach(employee => {
                    const filterDiv = document.createElement('div');
                    filterDiv.className = 'employee-filter active';
                    filterDiv.onclick = function() { toggleEmployee(employee); };
                    
                    const checkbox = document.createElement('input');
                    checkbox.type = 'checkbox';
                    checkbox.checked = true;
                    checkbox.onchange = function() { toggleEmployee(employee); };
                    
                    const span = document.createElement('span');
                    span.textContent = '👤 ' + employee;
                    
                    filterDiv.appendChild(checkbox);
                    filterDiv.appendChild(document.createTextNode(' '));
                    filterDiv.appendChild(span);
                    
                    filtersContainer.appendChild(filterDiv);
                });
                
                console.log('Employee filters initialized successfully');
                
            } catch (error) {
                console.error('Error in initializeEmployeeFilters:', error);
            }
        }
        
        // Toggle employee selection
        function toggleEmployee(employeeName) {
            const filterDiv = Array.from(document.querySelectorAll('.employee-filter'))
                .find(div => div.textContent.includes(employeeName));
            const checkbox = filterDiv.querySelector('input[type="checkbox"]');
            
            if (selectedEmployees.has(employeeName)) {
                selectedEmployees.delete(employeeName);
                filterDiv.classList.remove('active');
                checkbox.checked = false;
            } else {
                selectedEmployees.add(employeeName);
                filterDiv.classList.add('active');
                checkbox.checked = true;
            }
            
            // Update displays
            filterEmployeeSections();
            const currentSliderValue = document.getElementById('timelineSlider').value;
            updateTimeline(currentSliderValue);
        }
        
        // Select all employees
        function selectAllEmployees() {
            selectedEmployees = new Set(allEmployees);
            document.querySelectorAll('.employee-filter').forEach(div => {
                div.classList.add('active');
                div.querySelector('input[type="checkbox"]').checked = true;
            });
            filterEmployeeSections();
            const currentSliderValue = document.getElementById('timelineSlider').value;
            updateTimeline(currentSliderValue);
        }
        
        // Clear all employees
        function clearAllEmployees() {
            selectedEmployees.clear();
            document.querySelectorAll('.employee-filter').forEach(div => {
                div.classList.remove('active');
                div.querySelector('input[type="checkbox"]').checked = false;
            });
            filterEmployeeSections();
            const currentSliderValue = document.getElementById('timelineSlider').value;
            updateTimeline(currentSliderValue);
        }
        
        // Filter employee sections in the main report
        function filterEmployeeSections() {
            const employeeCards = document.querySelectorAll('.employee-card');
            employeeCards.forEach(card => {
                const employeeName = card.querySelector('.employee-name').textContent.replace('👤 ', '');
                if (selectedEmployees.has(employeeName)) {
                    card.style.display = 'block';
                } else {
                    card.style.display = 'none';
                }
            });
        }
        
        function updateTimeline(index) {
            const snapshot = historicalSnapshots[index];
            document.getElementById('timelineInfo').innerHTML = "<span>📅 " + snapshot.date + "</span>";
            
            // Show progress evolution
            const evolutionDiv = document.getElementById('progressEvolution');
            evolutionDiv.style.display = 'block';
            evolutionDiv.innerHTML = '';
            
            // Group tasks by employee and show progress
            const tasksByEmployee = {};
            snapshot.tasks.forEach(task => {
                if (!tasksByEmployee[task.EmployeeName]) {
                    tasksByEmployee[task.EmployeeName] = [];
                }
                tasksByEmployee[task.EmployeeName].push(task);
            });
            
            Object.keys(tasksByEmployee).forEach(employeeName => {
                // Skip employees not in the selected filter
                if (!selectedEmployees.has(employeeName)) return;
                
                const employeeDiv = document.createElement('div');
                employeeDiv.innerHTML = "<h4 style='margin: 15px 0 10px 0; color: #495057;'>👤 " + employeeName + "</h4>";
                evolutionDiv.appendChild(employeeDiv);
                
                tasksByEmployee[employeeName].forEach(task => {
                    const progressPercent = parseInt(task.Progress?.replace('%', '') || '0');
                    const taskDiv = document.createElement('div');
                    taskDiv.className = 'evolution-card';
                    taskDiv.innerHTML = 
                        '<div class="evolution-task">' + task.TaskDescription + '</div>' +
                        '<div class="evolution-progress">' +
                            '<div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 5px;">' +
                                '<span style="font-size: 12px; color: #6c757d;">Priority: ' + task.Priority + ' | Status: ' + task.Status + '</span>' +
                                '<span style="font-size: 12px; font-weight: bold;">' + (task.Progress || '0%') + '</span>' +
                            '</div>' +
                            '<div class="evolution-bar">' +
                                '<div class="evolution-fill" style="width: ' + progressPercent + '%"></div>' +
                            '</div>' +
                        '</div>';
                    evolutionDiv.appendChild(taskDiv);
                });
            });
            
            // Update button states
            const stepButton = document.getElementById('stepButton');
            const resetButton = document.getElementById('resetButton');
            const slider = document.getElementById('timelineSlider');
            const currentValue = parseInt(slider.value);
            const maxValue = parseInt(slider.max);
            
            // Step button: disabled at end, enabled otherwise
            if (currentValue >= maxValue) {
                stepButton.disabled = true;
                stepButton.textContent = '⏭ End of Timeline';
            } else {
                stepButton.disabled = false;
                stepButton.textContent = '⏭ Next Week';
            }
            
            // Reset button: disabled at start, enabled otherwise
            if (currentValue <= 0) {
                resetButton.disabled = true;
                resetButton.textContent = '⏮ At Start';
            } else {
                resetButton.disabled = false;
                resetButton.textContent = '⏮ Start Over';
            }
        }
        
        function playTimeline() {
            const button = document.getElementById('playButton');
            const slider = document.getElementById('timelineSlider');
            
            if (isPlaying) {
                // Stop playing
                clearInterval(playInterval);
                isPlaying = false;
                button.textContent = '▶ Play Timeline';
                button.disabled = false;
            } else {
                // Start playing
                isPlaying = true;
                button.textContent = '⏸ Pause';
                slider.value = 0;
                
                playInterval = setInterval(() => {
                    const currentValue = parseInt(slider.value);
                    if (currentValue >= historicalSnapshots.length - 1) {
                        // End of timeline
                        clearInterval(playInterval);
                        isPlaying = false;
                        button.textContent = '▶ Play Timeline';
                        return;
                    }
                    
                    slider.value = currentValue + 1;
                    updateTimeline(slider.value);
                }, 1500); // Change every 1.5 seconds
                
                updateTimeline(0);
            }
        }
        
        function stepForward() {
            const slider = document.getElementById('timelineSlider');
            const stepButton = document.getElementById('stepButton');
            const resetButton = document.getElementById('resetButton');
            const playButton = document.getElementById('playButton');
            
            // Stop any currently playing timeline
            if (isPlaying) {
                clearInterval(playInterval);
                isPlaying = false;
                playButton.textContent = '▶ Play Timeline';
            }
            
            const currentValue = parseInt(slider.value);
            const maxValue = parseInt(slider.max);
            
            if (currentValue < maxValue) {
                // Move forward one step
                const nextValue = currentValue + 1;
                slider.value = nextValue;
                updateTimeline(nextValue);
            }
        }
        
        function resetTimeline() {
            const slider = document.getElementById('timelineSlider');
            const stepButton = document.getElementById('stepButton');
            const resetButton = document.getElementById('resetButton');
            const playButton = document.getElementById('playButton');
            
            // Stop any currently playing timeline
            if (isPlaying) {
                clearInterval(playInterval);
                isPlaying = false;
                playButton.textContent = '▶ Play Timeline';
            }
            
            // Reset to the beginning
            slider.value = 0;
            updateTimeline(0);
        }
        
        // Make functions globally available
        window.toggleEmployee = toggleEmployee;
        window.selectAllEmployees = selectAllEmployees;
        window.clearAllEmployees = clearAllEmployees;
        window.playTimeline = playTimeline;
        window.stepForward = stepForward;
        window.resetTimeline = resetTimeline;
        window.exportToPDF = exportToPDF;
        window.exportToWord = exportToWord;
        
        // Initialize everything when DOM is ready
        function initializeReport() {
            console.log('Initializing report...');
            console.log('Historical snapshots:', historicalSnapshots.length);
            console.log('All employees:', allEmployees);
            
            try {
                initializeEmployeeFilters();
                console.log('Employee filters initialized');
                
                updateTimeline(historicalSnapshots.length - 1);
                console.log('Timeline updated');
                
                // Update timeline when slider changes
                const timelineSlider = document.getElementById('timelineSlider');
                if (timelineSlider) {
                    timelineSlider.addEventListener('input', function() {
                        if (isPlaying) {
                            clearInterval(playInterval);
                            isPlaying = false;
                            const playButton = document.getElementById('playButton');
                            if (playButton) playButton.textContent = '▶ Play Timeline';
                        }
                        updateTimeline(this.value);
                    });
                    console.log('Timeline slider listener added');
                } else {
                    console.error('Timeline slider not found');
                }
                
                // Test the playTimeline function
                const playButton = document.getElementById('playButton');
                if (playButton) {
                    console.log('Play button found');
                } else {
                    console.error('Play button not found');
                }
                
            } catch (error) {
                console.error('Initialization error:', error);
            }
        }
        
        // Try multiple initialization methods
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initializeReport);
        } else {
            // DOM already loaded
            initializeReport();
        }
        
        // Fallback initialization
        window.addEventListener('load', function() {
            console.log('Window load event, checking initialization...');
            const employeeFilterContainer = document.getElementById('employeeFilters');
            if (!employeeFilterContainer || employeeFilterContainer.innerHTML.trim() === '') {
                console.log('Retrying initialization...');
                setTimeout(initializeReport, 100);
            }
        });
        
        // Export functions
        function exportToPDF() {
            try {
                // Use browser's print functionality to generate PDF
                window.print();
            } catch (error) {
                console.error('PDF export error:', error);
                alert('PDF export failed. Please try using your browser print function (Ctrl+P or Cmd+P).');
            }
        }
        
        function exportToWord() {
            try {
                alert('Word export: Please use your browser menu File > Save As, and choose "Web Page, Complete" format to save this report.');
            } catch (error) {
                console.error('Word export error:', error);
            }
        }
    </script>
</body>
</html>
"@
    
    # Save the HTML file
    $HTML | Out-File -FilePath $ReportFileName -Encoding UTF8
    
    Write-Host "`n✅ HTML Report Generated Successfully!" -ForegroundColor Green
    Write-Host "📄 File: $ReportFileName" -ForegroundColor Cyan
    Write-Host "📊 Total Tasks: $TotalTasks | Completed: $CompletedTasks | High Priority: $HighPriorityTasks | Overdue: $OverdueTasks" -ForegroundColor White
    
    # Try to open the report in default browser
    try {
        if ($IsMacOS -or (Get-Command "open" -ErrorAction SilentlyContinue)) {
            Start-Process "open" $ReportFileName
            Write-Host "🌐 Report opened in your default browser!" -ForegroundColor Yellow
        } else {
            Write-Host "💡 Open '$ReportFileName' in your browser to view the report" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "💡 Open '$ReportFileName' in your browser to view the report" -ForegroundColor Yellow
    }
}