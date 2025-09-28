# One-Page Banking Report Generator for Task Progress Tracking
# Professional, compact design suitable for banking environments

function Generate-OnePageReport {
    param(
        [Parameter(Mandatory=$false)]
        [string]$FilterEmployee = $null
    )
    
    $TaskFile = "./task_progress_data.csv"
    if (-not (Test-Path $TaskFile)) {
        Write-Host "No task data found to generate report!" -ForegroundColor Red
        return
    }
    
    $Tasks = Import-Csv $TaskFile
    
    # Apply employee filter if specified
    if ($FilterEmployee) {
        $Tasks = $Tasks | Where-Object { $_.EmployeeName -eq $FilterEmployee }
        Write-Host "🔍 Filtering tasks for employee: $FilterEmployee" -ForegroundColor Yellow
        Write-Host "📊 Found $($Tasks.Count) tasks for $FilterEmployee" -ForegroundColor Cyan
        
        if ($Tasks.Count -eq 0) {
            Write-Host "❌ No tasks found for employee: $FilterEmployee" -ForegroundColor Red
            return
        }
    }
    
    $ReportDate = Get-Date -Format "MMMM dd, yyyy 'at' HH:mm"
    
    # Create reports folder if it doesn't exist
    $ReportsFolder = "./reports"
    if (-not (Test-Path $ReportsFolder)) {
        New-Item -ItemType Directory -Path $ReportsFolder -Force | Out-Null
    }
    
    # Generate filename based on whether it's filtered or not
    if ($FilterEmployee) {
        $SafeEmployeeName = $FilterEmployee -replace '[^\w\-_]', '_'
        $ReportFileName = Join-Path $ReportsFolder "OnePage_${SafeEmployeeName}_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').html"
    } else {
        $ReportFileName = Join-Path $ReportsFolder "OnePage_Task_Report_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').html"
    }
    
    # Load historical data for compact timeline
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
    
    # Add current data as the latest snapshot
    $HistoricalSnapshots += @{
        Date = Get-Date
        DateString = "Today"
        FileName = "current"
        Tasks = $Tasks
    }
    
    # Sort by date
    $HistoricalSnapshots = $HistoricalSnapshots | Sort-Object Date
    
    # Calculate statistics
    $ActiveTasks = $Tasks | Where-Object { -not $_.Status -or $_.Status -eq "Active" }
    $TotalTasks = $ActiveTasks.Count
    
    $CompletedTasksList = $Tasks | Where-Object { $_.Status -eq "Completed" -or $_.Progress -eq "100%" }
    $CompletedTasks = $CompletedTasksList.Count
    
    $HighPriorityTasksList = $ActiveTasks | Where-Object { $_.Priority -eq "1" }
    $HighPriorityTasks = $HighPriorityTasksList.Count
    
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
    
    # Calculate tasks for later (tasks without start date)
    $TasksForLaterList = $Tasks | Where-Object { -not $_.StartDate -or $_.StartDate -eq "" }
    $TasksForLater = $TasksForLaterList.Count
    
    # Group tasks by employee
    $TasksByEmployee = $Tasks | Group-Object EmployeeName
    
    # Create compact HTML content with banking-appropriate styling
    $HTML = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Task Progress Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', 'Helvetica Neue', Arial, sans-serif; 
            background: #f8f9fa; 
            padding: 15px; 
            color: #2c3e50;
            font-size: 13px;
            line-height: 1.4;
        }
        .container { 
            max-width: 1400px; 
            margin: 0 auto; 
            background: white; 
            border-radius: 8px; 
            box-shadow: 0 2px 10px rgba(0,0,0,0.08); 
            overflow: hidden;
            height: calc(100vh - 30px);
            display: flex;
            flex-direction: column;
        }
        .header { 
            background: linear-gradient(135deg, #34495e 0%, #2c3e50 100%); 
            color: white; 
            padding: 20px 30px; 
            display: flex; 
            justify-content: space-between; 
            align-items: center;
            flex-shrink: 0;
        }
        .header h1 { 
            font-size: 24px; 
            font-weight: 300; 
            margin: 0;
        }
        .header .date { 
            font-size: 12px; 
            opacity: 0.9; 
            background: rgba(255,255,255,0.1);
            padding: 4px 12px;
            border-radius: 12px;
        }
        .main-content {
            flex: 1;
            display: grid;
            grid-template-columns: 260px 1fr 360px;
            grid-template-rows: auto 1fr;
            gap: 15px;
            padding: 15px;
            overflow: hidden;
        }
        .stats-panel {
            grid-column: 1;
            grid-row: 1 / 3;
            background: #f8f9fb;
            border-radius: 6px;
            padding: 15px;
            border: 1px solid #e9ecef;
        }
        .tasks-grid {
            grid-column: 2;
            grid-row: 1 / 3;
            overflow-y: auto;
            border: 1px solid #e9ecef;
            border-radius: 6px;
            background: white;
        }
        .timeline-panel {
            grid-column: 3;
            grid-row: 1 / 3;
            background: #f8f9fb;
            border-radius: 6px;
            padding: 15px;
            border: 1px solid #e9ecef;
        }
        .stat-item { 
            display: flex; 
            justify-content: space-between; 
            align-items: center;
            padding: 12px 0; 
            border-bottom: 1px solid #e9ecef;
        }
        .stat-item:last-child { border-bottom: none; }
        .filter-stat {
            cursor: pointer;
            border-radius: 6px;
            margin: 2px 0;
            padding: 12px 8px;
            transition: all 0.2s ease;
            border: 1px solid transparent;
        }
        .filter-stat:hover {
            background-color: #f8f9fa;
            border-color: #007bff;
            transform: translateX(2px);
        }
        .filter-stat.active {
            background-color: #e3f2fd;
            border-color: #007bff;
            box-shadow: 0 2px 4px rgba(0,123,255,0.1);
        }
        .filter-stat.active .stat-label {
            color: #007bff;
            font-weight: 600;
        }
        .stat-label { 
            font-size: 12px; 
            color: #6c757d; 
            font-weight: 500;
        }
        .stat-value { 
            font-size: 16px; 
            font-weight: 600; 
            padding: 4px 8px;
            border-radius: 4px;
            min-width: 30px;
            text-align: center;
        }
        .stat-total { background: #e3f2fd; color: #1976d2; }
        .stat-completed { background: #e8f5e8; color: #2e7d32; }
        .stat-priority { background: #fff3e0; color: #f57c00; }
        .stat-overdue { background: #ffebee; color: #c62828; }
        .stat-later { background: #f3e5f5; color: #7b1fa2; }
        .filter-section {
            margin-bottom: 15px;
            padding-bottom: 15px;
            border-bottom: 1px solid #e9ecef;
        }
        .filter-title {
            font-size: 12px;
            font-weight: 600;
            color: #495057;
            margin-bottom: 10px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .employee-filters {
            display: flex;
            flex-direction: column;
            gap: 6px;
        }
        .employee-filter {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 6px 8px;
            background: white;
            border: 1px solid #dee2e6;
            border-radius: 4px;
            cursor: pointer;
            transition: all 0.2s ease;
            font-size: 12px;
        }
        .employee-filter:hover { background: #f1f3f4; }
        .employee-filter.active { 
            background: #e3f2fd; 
            border-color: #1976d2; 
            color: #1976d2;
        }
        .employee-filter input[type="checkbox"] { 
            margin: 0; 
            transform: scale(0.9);
        }
        .filter-buttons {
            display: flex;
            gap: 6px;
            margin-top: 10px;
        }
        .filter-btn {
            flex: 1;
            background: #6c757d;
            color: white;
            border: none;
            padding: 6px 8px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 10px;
            text-transform: uppercase;
            font-weight: 500;
            letter-spacing: 0.5px;
        }
        .filter-btn:hover { background: #5a6268; }
        .filter-btn.select-all { background: #28a745; }
        .filter-btn.select-all:hover { background: #218838; }
        .filter-btn.clear-all { background: #dc3545; }
        .filter-btn.clear-all:hover { background: #c82333; }
        .filter-btn.clear-filter { background: #007bff; }
        .filter-btn.clear-filter:hover { background: #0056b3; }
        .filter-btn.clear-filter { background: #007bff; }
        .filter-btn.clear-filter:hover { background: #0056b3; }
        .export-section {
            border-bottom: 1px solid #e9ecef;
            padding-bottom: 15px;
            margin-bottom: 15px;
        }
        .export-controls {
            display: flex;
            gap: 8px;
            justify-content: center;
        }
        .export-btn {
            background: #1976d2;
            color: white;
            border: none;
            padding: 6px 12px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 10px;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
            display: flex;
            align-items: center;
            gap: 4px;
        }
        .export-btn:hover { background: #1565c0; }
        .export-btn.pdf { background: #dc3545; }
        .export-btn.pdf:hover { background: #c82333; }
        .export-btn.word { background: #0d6efd; }
        .export-btn.word:hover { background: #0b5ed7; }
        .timeline-section {
            border-bottom: 1px solid #e9ecef;
            padding-bottom: 15px;
            margin-bottom: 15px;
        }
        .timeline-controls {
            margin-bottom: 10px;
        }
        .timeline-slider {
            width: 100%;
            height: 4px;
            border-radius: 2px;
            background: #dee2e6;
            outline: none;
            -webkit-appearance: none;
            margin-bottom: 8px;
        }
        .timeline-slider::-webkit-slider-thumb {
            appearance: none;
            width: 14px;
            height: 14px;
            border-radius: 50%;
            background: #1976d2;
            cursor: pointer;
        }
        .timeline-slider::-moz-range-thumb {
            width: 14px;
            height: 14px;
            border-radius: 50%;
            background: #1976d2;
            cursor: pointer;
            border: none;
        }
        .timeline-info {
            text-align: center;
            font-size: 11px;
            color: #6c757d;
            padding: 6px;
            background: white;
            border-radius: 4px;
            border: 1px solid #dee2e6;
        }
        .play-button {
            width: 100%;
            background: #28a745;
            color: white;
            border: none;
            padding: 8px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 11px;
            margin-bottom: 10px;
            text-transform: uppercase;
            font-weight: 500;
        }
        .play-button:hover { background: #218838; }
        .step-button { 
            width: 100%;
            background: #007bff; 
            color: white; 
            border: none; 
            padding: 8px; 
            border-radius: 4px; 
            cursor: pointer; 
            font-size: 11px; 
            font-weight: 500; 
            margin-bottom: 8px; 
        }
        .step-button:hover { background: #0056b3; }
        .step-button:disabled { background: #adb5bd; cursor: not-allowed; }
        .reset-button { 
            width: 100%;
            background: #6c757d; 
            color: white; 
            border: none; 
            padding: 8px; 
            border-radius: 4px; 
            cursor: pointer; 
            font-size: 11px; 
            font-weight: 500; 
            margin-bottom: 8px; 
        }
        .reset-button:hover { background: #545b62; }
        .reset-button:disabled { background: #adb5bd; cursor: not-allowed; }
        .employee-section {
            border-bottom: 1px solid #f1f3f4;
        }
        .employee-header {
            background: #f8f9fb;
            padding: 12px 15px;
            border-bottom: 1px solid #e9ecef;
            font-weight: 600;
            font-size: 12px;
            color: #495057;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .task-count {
            background: #dee2e6;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 10px;
            font-weight: 500;
        }
        .tasks-table {
            width: 100%;
            border-collapse: collapse;
        }
        .tasks-table th {
            background: #f8f9fb;
            padding: 8px 12px;
            text-align: left;
            font-weight: 600;
            font-size: 11px;
            color: #495057;
            border-bottom: 1px solid #dee2e6;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .tasks-table td {
            padding: 8px 12px;
            border-bottom: 1px solid #f1f3f4;
            font-size: 12px;
            vertical-align: middle;
        }
        .tasks-table tr:hover { background: #f8f9fa; }
        .progress-bar {
            width: 60px;
            height: 6px;
            background: #e9ecef;
            border-radius: 3px;
            overflow: hidden;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #28a745, #20c997);
            border-radius: 3px;
        }
        .priority-badge {
            padding: 2px 6px;
            border-radius: 8px;
            font-size: 9px;
            font-weight: 600;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .priority-1 { background: #ffebee; color: #c62828; }
        .priority-2 { background: #fff3e0; color: #f57c00; }
        .priority-3 { background: #fff9c4; color: #f9a825; }
        .priority-4 { background: #f3e5f5; color: #8e24aa; }
        .status-badge {
            padding: 2px 6px;
            border-radius: 8px;
            font-size: 9px;
            font-weight: 600;
            text-transform: uppercase;
        }
        .status-active { background: #e3f2fd; color: #1976d2; }
        .status-completed { background: #e8f5e8; color: #2e7d32; }
        .status-cancelled { background: #ffebee; color: #c62828; }
        .status-archived { background: #f5f5f5; color: #616161; }
        .report-badge {
            padding: 1px 4px;
            border-radius: 6px;
            font-size: 8px;
            font-weight: 500;
            margin: 0 1px;
        }
        .report-y { background: #e8f5e8; color: #2e7d32; }
        .report-n { background: #ffebee; color: #c62828; }
        .progress-evolution {
            margin-top: 8px;
            max-height: calc(100vh - 320px);
            overflow-y: auto;
            padding-right: 5px;
        }
        .evolution-card {
            background: white;
            border: 1px solid #e9ecef;
            padding: 6px;
            margin: 2px 0;
            border-radius: 3px;
            font-size: 10px;
        }
        .evolution-task {
            font-weight: 600;
            color: #495057;
            margin-bottom: 4px;
        }
        .evolution-bar {
            width: 100%;
            height: 4px;
            background: #e9ecef;
            border-radius: 2px;
            overflow: hidden;
            margin-top: 4px;
        }
        .evolution-fill {
            height: 100%;
            background: linear-gradient(90deg, #1976d2, #1565c0);
            border-radius: 2px;
            transition: width 0.3s ease;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Task Progress Dashboard</h1>
            <div class="date">$ReportDate</div>
        </div>
        
        <div class="main-content">
            <div class="stats-panel">
                <div class="filter-section">
                    <div class="filter-title">📋 Summary Filters</div>
                    <div class="stat-item filter-stat" onclick="filterBySummary('total')" data-filter="total">
                        <span class="stat-label">Total Tasks</span>
                        <span class="stat-value stat-total">$TotalTasks</span>
                    </div>
                    <div class="stat-item filter-stat" onclick="filterBySummary('completed')" data-filter="completed">
                        <span class="stat-label">Completed</span>
                        <span class="stat-value stat-completed">$CompletedTasks</span>
                    </div>
                    <div class="stat-item filter-stat" onclick="filterBySummary('high-priority')" data-filter="high-priority">
                        <span class="stat-label">High Priority</span>
                        <span class="stat-value stat-priority">$HighPriorityTasks</span>
                    </div>
                    <div class="stat-item filter-stat" onclick="filterBySummary('overdue')" data-filter="overdue">
                        <span class="stat-label">Overdue</span>
                        <span class="stat-value stat-overdue">$OverdueTasks</span>
                    </div>
                    <div class="stat-item filter-stat" onclick="filterBySummary('tasks-for-later')" data-filter="tasks-for-later">
                        <span class="stat-label">Tasks for Later</span>
                        <span class="stat-value stat-later">$TasksForLater</span>
                    </div>
                    <div class="filter-buttons">
                        <button class="filter-btn clear-filter" onclick="clearSummaryFilter()">Show All</button>
                    </div>
                </div>
                
                <div class="filter-section">
                    <div class="filter-title">👥 Filter Employees</div>
                    <div class="employee-filters" id="employeeFilters">
                        <!-- Populated by JavaScript -->
                    </div>
                    <div class="filter-buttons">
                        <button class="filter-btn select-all" onclick="selectAllEmployees()">All</button>
                        <button class="filter-btn clear-all" onclick="clearAllEmployees()">None</button>
                    </div>
                </div>
            </div>
            
            <div class="tasks-grid">
"@

    # Add compact employee sections
    foreach ($EmployeeGroup in $TasksByEmployee) {
        $EmployeeName = $EmployeeGroup.Name
        $EmployeeTasks = $EmployeeGroup.Group
        $TaskCount = $EmployeeTasks.Count
        
        $HTML += @"
                <div class="employee-section" data-employee="$EmployeeName">
                    <div class="employee-header">
                        <span>👤 $EmployeeName</span>
                        <span class="task-count">$TaskCount</span>
                    </div>
                    <table class="tasks-table">
                        <thead>
                            <tr>
                                <th style="width: 35%;">Task</th>
                                <th style="width: 10%;">Status</th>
                                <th style="width: 8%;">Priority</th>
                                <th style="width: 15%;">Progress</th>
                                <th style="width: 12%;">Start Date</th>
                                <th style="width: 12%;">ETA</th>
                                <th style="width: 8%;">Reports</th>
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
            
            $HTML += "                            <tr class=""task-item"" "
            $HTML += "data-status=""$TaskStatus"" "
            $HTML += "data-priority=""$($Task.Priority)"" "
            $HTML += "data-startdate=""$($Task.StartDate)"" "
            $HTML += "data-progress=""$($Task.Progress)"" "
            $HTML += "data-eta=""$($Task.ETA)"">`n"
            
            $HTML += @"
                                <td><strong>$($Task.'Task Description')</strong></td>
                                <td><span class="status-badge $StatusClass">$TaskStatus</span></td>
                                <td><span class="priority-badge $PriorityClass">P$($Task.Priority)</span></td>
                                <td>
                                    <div style="display: flex; align-items: center; gap: 6px;">
                                        <div class="progress-bar">
                                            <div class="progress-fill" style="width: $ProgressPercent%"></div>
                                        </div>
                                        <span style="font-size: 10px;">$($Task.Progress)</span>
                                    </div>
                                </td>
                                <td style="font-size: 11px;">$($Task.StartDate)</td>
                                <td style="font-size: 11px;">$($Task.ETA)</td>
                                <td>
                                    <span class="report-badge report-$($Task.ProgressReportSent.ToLower())">P</span>
                                    <span class="report-badge report-$($Task.FinalReportSent.ToLower())">F</span>
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
            
            <div class="timeline-panel">
                <div class="timeline-section">
                    <div class="filter-title">📈 Timeline</div>
                    <button class="play-button" onclick="playTimeline()" id="playButton">▶ Play Timeline</button>
                    <button class="step-button" onclick="stepForward()" id="stepButton">⏭ Next Step</button>
                    <button class="reset-button" onclick="resetTimeline()" id="resetButton">⏮ Start Over</button>
                    <div class="timeline-controls">
                        <input type="range" min="0" max="$(($HistoricalSnapshots.Count - 1))" value="$(($HistoricalSnapshots.Count - 1))" class="timeline-slider" id="timelineSlider" onchange="updateTimeline(this.value)">
                    </div>
                    <div class="timeline-info" id="timelineInfo">
                        <span>$ReportDate</span>
                    </div>
                </div>
                
                <div class="export-section">
                    <div class="filter-title">📄 Export</div>
                    <div class="export-controls">
                        <button class="export-btn pdf" onclick="exportToPDF()">
                            📄 PDF
                        </button>
                        <button class="export-btn word" onclick="exportToWord()">
                            📝 Word
                        </button>
                    </div>
                </div>
                
                <div class="progress-evolution" id="progressEvolution">
                    <div style="padding: 10px; text-align: center; color: #666;">
                        <h4>📊 Progress Evolution</h4>
                        <div id="evolutionContent">
                            <p>Select employees and use timeline controls to see progress evolution</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Simplified historical data - no complex JSON generation
        console.log('Loading simplified one-page report...');
        let historicalSnapshots = [
            {
                date: 'Today',
                tasks: []
            }
        ];
        console.log('Simplified historical data loaded');
        
        // Employee filtering variables
        let selectedEmployees = new Set();
        let allEmployees = [];
        let isPlaying = false;
        let playInterval;
        
        // Initialize employee filters - simplified approach
        function initializeEmployeeFilters() {
            console.log('initializeEmployeeFilters called');
            
            // Get employees from current employee sections on the page
            const employeeSections = document.querySelectorAll('.employee-section');
            const allEmployeesFromPage = new Set();
            
            employeeSections.forEach(section => {
                const employeeName = section.getAttribute('data-employee');
                if (employeeName) {
                    allEmployeesFromPage.add(employeeName);
                }
            });
            
            allEmployees = Array.from(allEmployeesFromPage).sort();
            selectedEmployees = new Set(allEmployees);
            
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
        
        // Filter employee sections
        function filterEmployeeSections() {
            const employeeSections = document.querySelectorAll('.employee-section');
            employeeSections.forEach(section => {
                const employeeName = section.querySelector('.employee-header span').textContent.replace('👤 ', '');
                if (selectedEmployees.has(employeeName)) {
                    section.style.display = 'block';
                } else {
                    section.style.display = 'none';
                }
            });
        }
        
        // Update timeline
        function updateTimeline(index) {
            // Update timeline step based on slider
            timelineStep = parseInt(index) || 0;
            
            // Update timeline info
            const timelineInfo = document.getElementById('timelineInfo');
            if (timelineInfo) {
                if (timelineStep === 0) {
                    timelineInfo.innerHTML = '<span>📅 Today - Current Status</span>';
                } else {
                    timelineInfo.innerHTML = '<span>📅 Timeline Step ' + timelineStep + ' - Projected Status</span>';
                }
            }
            
            // Get evolution div
            const evolutionDiv = document.getElementById('progressEvolution');
            if (!evolutionDiv) return;
            
            let content = '<div style="font-size: 11px; padding: 10px; overflow-x: auto; max-height: 400px; overflow-y: auto;">';
            
            if (timelineStep === 0) {
                content += '<h5 style="margin: 10px 0 5px 0; color: #007bff;">📈 Current Task Status</h5>';
                
                if (selectedEmployees.size === 0) {
                    content += '<div style="color: #666; text-align: center; padding: 20px;">No employees selected.<br>Use checkboxes above to select employees.</div>';
                } else {
                    selectedEmployees.forEach(employeeName => {
                        const employeeSection = document.querySelector('[data-employee="' + employeeName + '"]');
                        if (employeeSection) {
                            const visibleTasks = Array.from(employeeSection.querySelectorAll('.task-item'))
                                .filter(task => task.style.display !== 'none');
                            
                            if (visibleTasks.length > 0) {
                                content += '<div style="margin: 8px 0; padding: 8px; background: #f8f9fa; border-radius: 6px; border-left: 3px solid #007bff; min-width: 300px;">';
                                content += '<div style="font-weight: 600; color: #007bff; margin-bottom: 4px;">👤 ' + employeeName + ' (' + visibleTasks.length + ' tasks)</div>';
                                
                                // Show ALL tasks, not just 4
                                visibleTasks.forEach(task => {
                                    const status = task.getAttribute('data-status') || '';
                                    const progress = task.getAttribute('data-progress') || '0';
                                    const taskName = task.querySelector('td:first-child strong').textContent;
                                    const priority = task.getAttribute('data-priority') || '';
                                    
                                    let statusColor = status === 'Completed' ? '#28a745' : '#007bff';
                                    let priorityText = priority === '1' ? '🔴' : priority === '2' ? '🟡' : '🟢';
                                    let progressNum = parseInt(progress) || 0;
                                    
                                    content += '<div style="margin: 3px 0; padding: 3px 0; border-bottom: 1px solid #e9ecef; font-size: 10px;">';
                                    content += '<div style="display: flex; justify-content: space-between; align-items: center; white-space: nowrap;">';
                                    content += '<span style="overflow: hidden; text-overflow: ellipsis; max-width: 250px;">' + priorityText + ' ' + taskName + '</span>';
                                    content += '<span style="color: ' + statusColor + '; font-weight: 600; margin-left: 10px;">' + progress + '%</span>';
                                    content += '</div>';
                                    
                                    // Mini progress bar
                                    content += '<div style="width: 100%; height: 3px; background: #e9ecef; border-radius: 2px; margin-top: 2px;">';
                                    content += '<div style="width: ' + progressNum + '%; height: 100%; background: ' + statusColor + '; border-radius: 2px;"></div>';
                                    content += '</div>';
                                    content += '</div>';
                                });
                                
                                content += '</div>';
                            }
                        }
                    });
                }
            } else {
                content += '<h5 style="margin: 10px 0 5px 0; color: #28a745;">📈 Timeline Step ' + timelineStep + ' of ' + maxTimelineSteps + '</h5>';
                
                if (selectedEmployees.size === 0) {
                    content += '<div style="color: #666; text-align: center; padding: 20px;">No employees selected.<br>Use checkboxes above to select employees.</div>';
                } else {
                    selectedEmployees.forEach(employeeName => {
                        const employeeSection = document.querySelector('[data-employee="' + employeeName + '"]');
                        if (employeeSection) {
                            const visibleTasks = Array.from(employeeSection.querySelectorAll('.task-item'))
                                .filter(task => task.style.display !== 'none');
                            
                            if (visibleTasks.length > 0) {
                                let borderColor = timelineStep === 1 ? '#17a2b8' : timelineStep === 2 ? '#28a745' : timelineStep === 3 ? '#ffc107' : timelineStep === 4 ? '#fd7e14' : '#6f42c1';
                                content += '<div style="margin: 8px 0; padding: 8px; background: #f0f8ff; border-radius: 6px; border-left: 3px solid ' + borderColor + '; min-width: 300px;">';
                                content += '<div style="font-weight: 600; color: ' + borderColor + '; margin-bottom: 4px;">🔮 ' + employeeName + ' - Step ' + timelineStep + ' Progress (' + visibleTasks.length + ' tasks)</div>';
                                
                                // Show ALL tasks, not just 4
                                visibleTasks.forEach(task => {
                                    const status = task.getAttribute('data-status') || '';
                                    const actualProgress = parseInt(task.getAttribute('data-progress') || '0');
                                    const taskName = task.querySelector('td:first-child strong').textContent;
                                    const priority = task.getAttribute('data-priority') || '';
                                    
                                    // Progressive increase based on step
                                    let projectedProgress = Math.min(actualProgress + (timelineStep * 15), 100);
                                    if (status === 'Completed') projectedProgress = 100;
                                    
                                    let statusColor = projectedProgress >= 100 ? '#28a745' : borderColor;
                                    let priorityText = priority === '1' ? '🔴' : priority === '2' ? '🟡' : '🟢';
                                    
                                    content += '<div style="margin: 3px 0; padding: 3px 0; border-bottom: 1px solid #e9ecef; font-size: 10px;">';
                                    content += '<div style="display: flex; justify-content: space-between; align-items: center; white-space: nowrap;">';
                                    content += '<span style="overflow: hidden; text-overflow: ellipsis; max-width: 250px;">' + priorityText + ' ' + taskName + '</span>';
                                    content += '<span style="color: ' + statusColor + '; font-weight: 600; margin-left: 10px;">' + projectedProgress + '%</span>';
                                    content += '</div>';
                                    
                                    // Progress bar
                                    content += '<div style="width: 100%; height: 4px; background: #e9ecef; border-radius: 2px; margin-top: 2px;">';
                                    content += '<div style="width: ' + projectedProgress + '%; height: 100%; background: ' + statusColor + '; border-radius: 2px;"></div>';
                                    content += '</div>';
                                    content += '</div>';
                                });
                                
                                content += '</div>';
                            }
                        }
                    });
                    
                    content += '<div style="margin-top: 10px; text-align: center; color: #666; font-size: 10px;">⏩ Timeline Step ' + timelineStep + ' - Projected Progress</div>';
                }
            }
            
            content += '</div>';
            evolutionDiv.innerHTML = content;
        }
        
        // Add slider change event handler
        function initializeTimelineSlider() {
            const slider = document.getElementById('timelineSlider');
            if (slider) {
                slider.min = 0;
                slider.max = maxTimelineSteps;
                slider.value = 0;
                slider.oninput = function() {
                    updateTimeline(this.value);
                };
            }
        }
        
        // Play timeline
        function playTimeline() {
            const button = document.getElementById('playButton');
            
            if (isPlaying) {
                clearInterval(playInterval);
                isPlaying = false;
                button.textContent = '▶ Play Timeline';
            } else {
                isPlaying = true;
                button.textContent = '⏸ Pause';
                
                // Create animated progress simulation
                let animationStep = 0;
                const evolutionDiv = document.getElementById('progressEvolution');
                
                playInterval = setInterval(() => {
                    if (animationStep >= 8) {
                        clearInterval(playInterval);
                        isPlaying = false;
                        button.textContent = '▶ Play Timeline';
                        updateTimeline(0); // Show final content
                        return;
                    }
                    
                    if (evolutionDiv) {
                        let content = '<div style="font-size: 11px; padding: 10px;">';
                        content += '<h5 style="margin: 10px 0 5px 0; color: #007bff;">📈 Progress Animation - Step ' + (animationStep + 1) + '</h5>';
                        
                        if (selectedEmployees.size === 0) {
                            content += '<div style="color: #666; text-align: center; padding: 20px;">Select employees to see animated progress</div>';
                        } else {
                            selectedEmployees.forEach(employeeName => {
                                const employeeSection = document.querySelector('[data-employee="' + employeeName + '"]');
                                if (employeeSection) {
                                    const visibleTasks = Array.from(employeeSection.querySelectorAll('.task-item'))
                                        .filter(task => task.style.display !== 'none');
                                    
                                    if (visibleTasks.length > 0) {
                            content += '<div style="margin: 8px 0; padding: 8px; background: #f8f9fa; border-radius: 6px; border-left: 3px solid #007bff; min-width: 300px;">';
                            content += '<div style="font-weight: 600; color: #007bff; margin-bottom: 4px;">👤 ' + employeeName + ' (' + visibleTasks.length + ' tasks)</div>';
                            
                            // Show ALL tasks during animation
                            visibleTasks.forEach((task, index) => {
                                const status = task.getAttribute('data-status') || '';
                                const actualProgress = parseInt(task.getAttribute('data-progress') || '0');
                                const taskName = task.querySelector('td:first-child strong').textContent;
                                const priority = task.getAttribute('data-priority') || '';
                                
                                // Animate progress based on step
                                let animatedProgress = Math.min(actualProgress + (animationStep * 8), 100);
                                if (status === 'Completed') animatedProgress = 100;
                                
                                let statusColor = animatedProgress >= 100 ? '#28a745' : '#007bff';
                                let priorityText = priority === '1' ? '🔴' : priority === '2' ? '🟡' : '🟢';
                                
                                content += '<div style="margin: 3px 0; padding: 3px 0; border-bottom: 1px solid #e9ecef; font-size: 10px;">';
                                content += '<div style="display: flex; justify-content: space-between; align-items: center; white-space: nowrap;">';
                                content += '<span style="overflow: hidden; text-overflow: ellipsis; max-width: 250px;">' + priorityText + ' ' + taskName + '</span>';
                                content += '<span style="color: ' + statusColor + '; font-weight: 600; margin-left: 10px;">' + animatedProgress + '%</span>';
                                content += '</div>';
                                
                                // Animated progress bar
                                content += '<div style="width: 100%; height: 4px; background: #e9ecef; border-radius: 2px; margin-top: 2px;">';
                                content += '<div style="width: ' + animatedProgress + '%; height: 100%; background: ' + statusColor + '; border-radius: 2px; transition: width 0.5s ease;"></div>';
                                content += '</div>';
                                content += '</div>';
                            });                                        if (visibleTasks.length > 3) {
                                            content += '<div style="font-size: 9px; color: #666; margin-top: 5px; text-align: center;">... and ' + (visibleTasks.length - 3) + ' more tasks</div>';
                                        }
                                        
                                        content += '</div>';
                                    }
                                }
                            });
                        }
                        
                        content += '<div style="margin-top: 15px; text-align: center; color: #666; font-size: 10px;">⏰ Simulating progress evolution...</div>';
                        content += '</div>';
                        evolutionDiv.innerHTML = content;
                    }
                    animationStep++;
                }, 800);
            }
        }
        
        // Timeline state tracking
        let timelineStep = 0;
        let maxTimelineSteps = 5;
        
        // Step forward timeline - persistent version with slider
        function stepForward() {
            const playButton = document.getElementById('playButton');
            const slider = document.getElementById('timelineSlider');
            
            if (isPlaying) {
                clearInterval(playInterval);
                isPlaying = false;
                if (playButton) playButton.textContent = '▶ Play Timeline';
            }
            
            // Advance timeline step
            timelineStep = Math.min(timelineStep + 1, maxTimelineSteps);
            
            // Update slider position
            if (slider) {
                slider.value = timelineStep;
            }
            
            // Call updateTimeline to show the content
            updateTimeline(timelineStep);
        }
        
        function showCurrentStatus(content) {
            const evolutionDiv = document.getElementById('progressEvolution');
            if (selectedEmployees.size === 0) {
                content += '<div style="color: #666; text-align: center; padding: 20px;">No employees selected.<br>Use checkboxes above to select employees.</div>';
            } else {
                selectedEmployees.forEach(employeeName => {
                    const employeeSection = document.querySelector('[data-employee="' + employeeName + '"]');
                    if (employeeSection) {
                        const visibleTasks = Array.from(employeeSection.querySelectorAll('.task-item'))
                            .filter(task => task.style.display !== 'none');
                        
                        if (visibleTasks.length > 0) {
                            content += '<div style="margin: 8px 0; padding: 8px; background: #f8f9fa; border-radius: 6px; border-left: 3px solid #007bff;">';
                            content += '<div style="font-weight: 600; color: #007bff; margin-bottom: 4px;">� ' + employeeName + ' (' + visibleTasks.length + ' tasks)</div>';
                            
                            visibleTasks.slice(0, 4).forEach(task => {
                                const status = task.getAttribute('data-status') || '';
                                const progress = task.getAttribute('data-progress') || '0';
                                const taskName = task.querySelector('td:first-child strong').textContent;
                                const priority = task.getAttribute('data-priority') || '';
                                
                                let statusColor = status === 'Completed' ? '#28a745' : '#007bff';
                                let priorityText = priority === '1' ? '🔴' : priority === '2' ? '🟡' : '🟢';
                                let progressNum = parseInt(progress) || 0;
                                
                                content += '<div style="margin: 3px 0; padding: 3px 0; border-bottom: 1px solid #e9ecef; font-size: 10px;">';
                                content += '<div style="display: flex; justify-content: space-between; align-items: center;">';
                                content += '<span>' + priorityText + ' ' + (taskName.length > 30 ? taskName.substring(0, 30) + '...' : taskName) + '</span>';
                                content += '<span style="color: ' + statusColor + '; font-weight: 600;">' + progress + '%</span>';
                                content += '</div>';
                                
                                // Mini progress bar
                                content += '<div style="width: 100%; height: 3px; background: #e9ecef; border-radius: 2px; margin-top: 2px;">';
                                content += '<div style="width: ' + progressNum + '%; height: 100%; background: ' + statusColor + '; border-radius: 2px;"></div>';
                                content += '</div>';
                                content += '</div>';
                            });
                            
                            if (visibleTasks.length > 4) {
                                content += '<div style="font-size: 9px; color: #666; margin-top: 5px; text-align: center;">... and ' + (visibleTasks.length - 4) + ' more tasks</div>';
                            }
                            
                            content += '</div>';
                        }
                    }
                });
            }
            content += '</div>';
        }
        
        function showProjectedStatus(content, step) {
            if (selectedEmployees.size === 0) {
                content += '<div style="color: #666; text-align: center; padding: 20px;">No employees selected.<br>Use checkboxes above to select employees.</div>';
            } else {
                selectedEmployees.forEach(employeeName => {
                    const employeeSection = document.querySelector('[data-employee="' + employeeName + '"]');
                    if (employeeSection) {
                        const visibleTasks = Array.from(employeeSection.querySelectorAll('.task-item'))
                            .filter(task => task.style.display !== 'none');
                        
                        if (visibleTasks.length > 0) {
                            let borderColor = step === 1 ? '#17a2b8' : step === 2 ? '#28a745' : step === 3 ? '#ffc107' : step === 4 ? '#fd7e14' : '#6f42c1';
                            content += '<div style="margin: 8px 0; padding: 8px; background: #f0f8ff; border-radius: 6px; border-left: 3px solid ' + borderColor + ';">';
                            content += '<div style="font-weight: 600; color: ' + borderColor + '; margin-bottom: 4px;">🔮 ' + employeeName + ' - Step ' + step + ' Progress (' + visibleTasks.length + ' tasks)</div>';
                            
                            visibleTasks.slice(0, 4).forEach(task => {
                                const status = task.getAttribute('data-status') || '';
                                const actualProgress = parseInt(task.getAttribute('data-progress') || '0');
                                const taskName = task.querySelector('td:first-child strong').textContent;
                                const priority = task.getAttribute('data-priority') || '';
                                
                                // Progressive increase based on step
                                let projectedProgress = Math.min(actualProgress + (step * 15), 100);
                                if (status === 'Completed') projectedProgress = 100;
                                
                                let statusColor = projectedProgress >= 100 ? '#28a745' : borderColor;
                                let priorityText = priority === '1' ? '🔴' : priority === '2' ? '🟡' : '🟢';
                                
                                content += '<div style="margin: 3px 0; padding: 3px 0; border-bottom: 1px solid #e9ecef; font-size: 10px;">';
                                content += '<div style="display: flex; justify-content: space-between; align-items: center;">';
                                content += '<span>' + priorityText + ' ' + (taskName.length > 30 ? taskName.substring(0, 30) + '...' : taskName) + '</span>';
                                content += '<span style="color: ' + statusColor + '; font-weight: 600;">' + projectedProgress + '%</span>';
                                content += '</div>';
                                
                                // Progress bar
                                content += '<div style="width: 100%; height: 4px; background: #e9ecef; border-radius: 2px; margin-top: 2px;">';
                                content += '<div style="width: ' + projectedProgress + '%; height: 100%; background: ' + statusColor + '; border-radius: 2px;"></div>';
                                content += '</div>';
                                content += '</div>';
                            });
                            
                            if (visibleTasks.length > 4) {
                                content += '<div style="font-size: 9px; color: #666; margin-top: 5px; text-align: center;">... and ' + (visibleTasks.length - 4) + ' more tasks</div>';
                            }
                            
                            content += '</div>';
                        }
                    }
                });
            }
            
            content += '<div style="margin-top: 10px; text-align: center; color: #666; font-size: 10px;">⏩ Timeline Step ' + step + ' - Projected Progress</div>';
            content += '</div>';
        }
        
        // Reset timeline to beginning - simplified version
        function resetTimeline() {
            const playButton = document.getElementById('playButton');
            const slider = document.getElementById('timelineSlider');
            
            if (isPlaying) {
                clearInterval(playInterval);
                isPlaying = false;
                if (playButton) playButton.textContent = '▶ Play Timeline';
            }
            
            // Reset timeline step and slider
            timelineStep = 0;
            if (slider) {
                slider.value = 0;
            }
            
            // Show reset animation
            const evolutionDiv = document.getElementById('progressEvolution');
            if (evolutionDiv) {
                evolutionDiv.innerHTML = '<div style="text-align: center; color: #dc3545; padding: 30px;"><div style="font-size: 18px;">🔄</div><div style="margin-top: 10px;">Resetting timeline...</div></div>';
                
                setTimeout(() => {
                    updateTimeline(0);
                }, 1000);
            }
        }
        
        // Summary filter functionality
        let currentSummaryFilter = null;
        
        function filterBySummary(filterType) {
            console.log('filterBySummary called with:', filterType);
            
            // Clear any existing active filter styles
            document.querySelectorAll('.filter-stat').forEach(item => {
                item.classList.remove('active');
            });
            
            // Set new active filter
            const clickedElement = document.querySelector('[data-filter="' + filterType + '"]');
            if (clickedElement) {
                clickedElement.classList.add('active');
                console.log('Added active class to:', clickedElement);
            } else {
                console.error('Could not find element with data-filter:', filterType);
            }
            
            currentSummaryFilter = filterType;
            
            // Filter and display tasks based on the selected summary type
            const allEmployeeSections = document.querySelectorAll('.employee-section');
            console.log('Found employee sections:', allEmployeeSections.length);
            
            allEmployeeSections.forEach(section => {
                const employeeName = section.getAttribute('data-employee');
                const taskElements = section.querySelectorAll('.task-item');
                console.log('Processing ' + employeeName + ' with ' + taskElements.length + ' tasks');
                let hasVisibleTasks = false;
                
                taskElements.forEach(taskElement => {
                    // Use simple data attributes instead of complex JSON parsing
                    const status = taskElement.getAttribute('data-status') || '';
                    const priority = taskElement.getAttribute('data-priority') || '';
                    const startDate = taskElement.getAttribute('data-startdate') || '';
                    const progress = taskElement.getAttribute('data-progress') || '';
                    
                    let shouldShow = false;
                    
                    switch(filterType) {
                        case 'total':
                            shouldShow = status !== 'Completed';
                            break;
                        case 'completed':
                            shouldShow = status === 'Completed' || progress === '100%';
                            break;
                        case 'high-priority':
                            shouldShow = priority === '1' && status !== 'Completed';
                            break;
                        case 'overdue':
                            const eta = taskElement.getAttribute('data-eta') || '';
                            shouldShow = isTaskOverdue({ETA: eta, Status: status}) && status !== 'Completed';
                            break;
                        case 'tasks-for-later':
                            shouldShow = !startDate || startDate === '';
                            break;
                        default:
                            shouldShow = true;
                    }
                    
                    if (shouldShow) {
                        taskElement.style.display = 'table-row'; // Fixed: use table-row for proper table display
                        hasVisibleTasks = true;
                    } else {
                        taskElement.style.display = 'none';
                    }
                });
                
                // Show/hide entire employee section based on whether it has visible tasks
                section.style.display = hasVisibleTasks ? 'block' : 'none';
            });
            
            console.log('Filtering completed for:', filterType);
        }
        
        function clearSummaryFilter() {
            // Clear active filter styles
            document.querySelectorAll('.filter-stat').forEach(item => {
                item.classList.remove('active');
            });
            
            currentSummaryFilter = null;
            
            // Show all tasks and employee sections
            const allEmployeeSections = document.querySelectorAll('.employee-section');
            allEmployeeSections.forEach(section => {
                section.style.display = 'block';
                const taskElements = section.querySelectorAll('.task-item');
                taskElements.forEach(taskElement => {
                    taskElement.style.display = 'table-row'; // Fixed: use table-row instead of block
                });
            });
            
            console.log('Summary filter cleared');
        }
        
        function isTaskOverdue(task) {
            if (!task.ETA || task.ETA === '' || task.Status === 'Completed') {
                return false;
            }
            
            try {
                const dateFormats = ['dd/MM/yyyy', 'd/M/yyyy', 'dd/M/yyyy', 'd/MM/yyyy'];
                let etaDate = null;
                
                for (let format of dateFormats) {
                    try {
                        const parts = task.ETA.split('/');
                        if (parts.length === 3) {
                            const day = parseInt(parts[0]);
                            const month = parseInt(parts[1]) - 1; // JavaScript months are 0-based
                            const year = parseInt(parts[2]);
                            etaDate = new Date(year, month, day);
                            break;
                        }
                    } catch (e) {
                        continue;
                    }
                }
                
                return etaDate && etaDate < new Date();
            } catch (e) {
                return false;
            }
        }
        
        // Make functions globally available
        window.toggleEmployee = toggleEmployee;
        window.selectAllEmployees = selectAllEmployees;
        window.clearAllEmployees = clearAllEmployees;
        window.filterBySummary = filterBySummary;
        window.clearSummaryFilter = clearSummaryFilter;
        window.playTimeline = playTimeline;
        window.stepForward = stepForward;
        window.resetTimeline = resetTimeline;
        window.exportToPDF = exportToPDF;
        window.exportToWord = exportToWord;
        
        // Initialize everything when DOM is ready
        function initializeOnePageReport() {
            console.log('Initializing one-page report...');
            console.log('All employees:', allEmployees);
            
            try {
                initializeEmployeeFilters();
                console.log('Employee filters initialized');
                
                initializeTimelineSlider();
                console.log('Timeline slider initialized');
                
                updateTimeline(0);
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
                
            } catch (error) {
                console.error('Initialization error:', error);
            }
        }
        
        // Try multiple initialization methods
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initializeOnePageReport);
        } else {
            // DOM already loaded
            initializeOnePageReport();
        }
        
        // Fallback initialization
        window.addEventListener('load', function() {
            console.log('Window load event, checking one-page initialization...');
            setTimeout(initializeOnePageReport, 100);
        });
        
        // Export functions for one-page report
        function exportToPDF() {
            try {
                // Simple PDF export using browser print
                window.print();
            } catch (error) {
                console.error('PDF export error:', error);
                alert('PDF export failed. Please use Ctrl+P or Cmd+P to print.');
            }
        }
        
        function exportToWord() {
            try {
                alert('Word export: Use browser menu File > Save As > Web Page Complete');
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
    
    Write-Host "`n✅ One-Page Banking Report Generated Successfully!" -ForegroundColor Green
    Write-Host "📄 File: $ReportFileName" -ForegroundColor Cyan
    Write-Host "📊 Compact Dashboard: $TotalTasks Tasks | $CompletedTasks Completed | $HighPriorityTasks High Priority | $OverdueTasks Overdue" -ForegroundColor White
    
    # Try to open the report in default browser
    try {
        if ($IsMacOS -or (Get-Command "open" -ErrorAction SilentlyContinue)) {
            Start-Process "open" $ReportFileName
            Write-Host "🌐 One-page report opened in your default browser!" -ForegroundColor Yellow
        } else {
            Write-Host "💡 Open '$ReportFileName' in your browser to view the compact dashboard" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "💡 Open '$ReportFileName' in your browser to view the compact dashboard" -ForegroundColor Yellow
    }
}

# Function is available for dot-sourcing
# Note: Export-ModuleMember is only needed when used as a proper PowerShell module