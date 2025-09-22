# One-Page Banking Report Generator for Task Progress Tracking
# Professional, compact design suitable for banking environments

function Generate-OnePageReport {
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
    }
    
    $ReportFileName = Join-Path $ReportsFolder "OnePage_Task_Report_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').html"
    
    # Load historical data for compact timeline
    $HistoryFolder = "./history"
    $HistoricalSnapshots = @()
    
    if (Test-Path $HistoryFolder) {
        $HistoryFiles = Get-ChildItem $HistoryFolder -Filter "*.csv" | Sort-Object Name | Select-Object -Last 3
        foreach ($HistoryFile in $HistoryFiles) {
            try {
                $HistoryData = Import-Csv $HistoryFile.FullName
                $Timestamp = $HistoryFile.Name.Split('_')[0..1] -join '_'
                $ParsedDate = [DateTime]::ParseExact($Timestamp, "yyyy-MM-dd_HH-mm-ss", $null)
                
                $HistoricalSnapshots += @{
                    Date = $ParsedDate
                    DateString = $ParsedDate.ToString("MMM dd")
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
        $_.ETA -and $_.ETA -ne "" -and $_.Status -ne "Completed" -and 
        [DateTime]::ParseExact($_.ETA, "dd/MM/yyyy", $null) -lt (Get-Date)
    }
    $OverdueTasks = $OverdueTasksList.Count
    
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
                    <div class="filter-title">📋 Summary</div>
                    <div class="stat-item">
                        <span class="stat-label">Total Tasks</span>
                        <span class="stat-value stat-total">$TotalTasks</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-label">Completed</span>
                        <span class="stat-value stat-completed">$CompletedTasks</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-label">High Priority</span>
                        <span class="stat-value stat-priority">$HighPriorityTasks</span>
                    </div>
                    <div class="stat-item">
                        <span class="stat-label">Overdue</span>
                        <span class="stat-value stat-overdue">$OverdueTasks</span>
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
                <div class="employee-section">
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
            
            $HTML += @"
                            <tr>
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
                    <!-- Progress evolution populated by JavaScript -->
                </div>
            </div>
        </div>
    </div>
    
    <script>
        // Historical data for timeline
        console.log('Loading one-page historical snapshots...');
        let historicalSnapshots;
        try {
            historicalSnapshots = [
"@

    # Add JavaScript data for historical snapshots (compact version)
    for ($i = 0; $i -lt $HistoricalSnapshots.Count; $i++) {
        $snapshot = $HistoricalSnapshots[$i]
        
        # Ensure all tasks have Status field for consistency
        $normalizedTasks = @()
        foreach ($task in $snapshot.Tasks) {
            $taskObj = [PSCustomObject]@{
                EmployeeName = $task.EmployeeName
                TaskDescription = $task.'Task Description'
                Priority = $task.Priority
                Progress = $task.Progress
                Status = if ($task.Status) { $task.Status } else { "Active" }
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
            console.log('One-page historical snapshots loaded successfully:', historicalSnapshots.length, 'snapshots');
        } catch (error) {
            console.error('Error loading one-page historical snapshots:', error);
            historicalSnapshots = [];
        }
        
        // Employee filtering variables
        let selectedEmployees = new Set();
        let allEmployees = [];
        let isPlaying = false;
        let playInterval;
        
        // Initialize employee filters
        function initializeEmployeeFilters() {
            // Collect employees from all historical snapshots, not just current
            const allEmployeesFromHistory = new Set();
            historicalSnapshots.forEach(snapshot => {
                snapshot.tasks.forEach(task => {
                    allEmployeesFromHistory.add(task.EmployeeName);
                });
            });
            
            allEmployees = Array.from(allEmployeesFromHistory).sort();
            selectedEmployees = new Set(allEmployees);
            
            const filtersContainer = document.getElementById('employeeFilters');
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
            const snapshot = historicalSnapshots[index];
            document.getElementById('timelineInfo').innerHTML = "<span>📅 " + snapshot.date + "</span>";
            
            const evolutionDiv = document.getElementById('progressEvolution');
            evolutionDiv.innerHTML = '';
            
            // Group tasks by employee and show progress
            const tasksByEmployee = {};
            snapshot.tasks.forEach(task => {
                if (!tasksByEmployee[task.EmployeeName]) {
                    tasksByEmployee[task.EmployeeName] = [];
                }
                tasksByEmployee[task.EmployeeName].push(task);
            });
            
            // Process employees in alphabetical order for consistent display
            const sortedEmployeeNames = Object.keys(tasksByEmployee).sort();
            sortedEmployeeNames.forEach(employeeName => {
                if (!selectedEmployees.has(employeeName)) return;
                
                // Create employee section with clear separation
                const employeeSection = document.createElement('div');
                employeeSection.style.marginBottom = '6px';
                employeeSection.style.border = '1px solid #e9ecef';
                employeeSection.style.borderRadius = '3px';
                employeeSection.style.padding = '6px';
                employeeSection.style.backgroundColor = '#f8f9fa';
                
                const employeeDiv = document.createElement('div');
                employeeDiv.style.fontSize = '10px';
                employeeDiv.style.fontWeight = '600';
                employeeDiv.style.color = '#495057';
                employeeDiv.style.marginBottom = '4px';
                employeeDiv.textContent = '👤 ' + employeeName + ' (' + tasksByEmployee[employeeName].length + ')';
                employeeSection.appendChild(employeeDiv);
                
                tasksByEmployee[employeeName].forEach(task => {
                    const progressPercent = parseInt(task.Progress?.replace('%', '') || '0');
                    const taskDiv = document.createElement('div');
                    taskDiv.className = 'evolution-card';
                    
                    const taskTitle = document.createElement('div');
                    taskTitle.className = 'evolution-task';
                    taskTitle.textContent = task.TaskDescription;
                    
                    const progressInfo = document.createElement('div');
                    progressInfo.style.display = 'flex';
                    progressInfo.style.justifyContent = 'space-between';
                    progressInfo.style.alignItems = 'center';
                    progressInfo.style.fontSize = '9px';
                    progressInfo.style.color = '#6c757d';
                    progressInfo.innerHTML = 
                        '<span>Priority: ' + task.Priority + ' | Status: ' + task.Status + '</span>' +
                        '<span style="font-weight: 600;">' + (task.Progress || '0%') + '</span>';
                    
                    const progressBar = document.createElement('div');
                    progressBar.className = 'evolution-bar';
                    
                    const progressFill = document.createElement('div');
                    progressFill.className = 'evolution-fill';
                    progressFill.style.width = progressPercent + '%';
                    
                    progressBar.appendChild(progressFill);
                    taskDiv.appendChild(taskTitle);
                    taskDiv.appendChild(progressInfo);
                    taskDiv.appendChild(progressBar);
                    employeeSection.appendChild(taskDiv);
                });
                
                // Add the complete employee section to the evolution div
                evolutionDiv.appendChild(employeeSection);
            });
        }
        
        // Play timeline
        function playTimeline() {
            const button = document.getElementById('playButton');
            const slider = document.getElementById('timelineSlider');
            
            if (isPlaying) {
                clearInterval(playInterval);
                isPlaying = false;
                button.textContent = '▶ Play Timeline';
            } else {
                isPlaying = true;
                button.textContent = '⏸ Pause';
                slider.value = 0;
                
                playInterval = setInterval(() => {
                    const currentValue = parseInt(slider.value);
                    if (currentValue >= historicalSnapshots.length - 1) {
                        clearInterval(playInterval);
                        isPlaying = false;
                        button.textContent = '▶ Play Timeline';
                        return;
                    }
                    
                    slider.value = currentValue + 1;
                    updateTimeline(slider.value);
                }, 1200);
                
                updateTimeline(0);
            }
        }
        
        // Make functions globally available
        window.toggleEmployee = toggleEmployee;
        window.selectAllEmployees = selectAllEmployees;
        window.clearAllEmployees = clearAllEmployees;
        window.playTimeline = playTimeline;
        window.exportToPDF = exportToPDF;
        window.exportToWord = exportToWord;
        
        // Initialize everything when DOM is ready
        function initializeOnePageReport() {
            console.log('Initializing one-page report...');
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