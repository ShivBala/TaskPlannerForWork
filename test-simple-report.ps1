# Minimal test version of the one-page report
function Test-OnePageReport {
    $Tasks = Import-Csv "./task_progress_data.csv"
    $ReportDate = Get-Date -Format "MMMM dd, yyyy 'at' HH:mm"
    $ReportFileName = "./reports/Test_OnePage_$(Get-Date -Format 'yyyy-MM-dd_HH-mm').html"
    
    # Simple statistics
    $ActiveTasks = $Tasks | Where-Object { -not $_.Status -or $_.Status -eq "Active" }
    $TotalTasks = $ActiveTasks.Count
    $CompletedTasks = ($Tasks | Where-Object { $_.Status -eq "Completed" -or $_.Progress -eq "100%" }).Count
    $HighPriorityTasks = ($ActiveTasks | Where-Object { $_.Priority -eq "1" }).Count
    $TasksForLater = ($Tasks | Where-Object { -not $_.StartDate -or $_.StartDate -eq "" }).Count
    
    $TasksByEmployee = $Tasks | Group-Object EmployeeName
    
    $HTML = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Task Progress Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 1400px; margin: 0 auto; background: white; border-radius: 12px; overflow: hidden; }
        .header { background: linear-gradient(135deg, #4a6741 0%, #6a8a5f 100%); color: white; padding: 20px; }
        .main-content { display: grid; grid-template-columns: 260px 1fr 360px; gap: 15px; padding: 15px; }
        .stats-panel { background: #f8f9fa; border-radius: 8px; padding: 15px; border: 1px solid #e9ecef; }
        .tasks-grid { background: #ffffff; border-radius: 8px; padding: 15px; border: 1px solid #e9ecef; overflow-y: auto; }
        .timeline-panel { background: #f8f9fa; border-radius: 8px; padding: 15px; border: 1px solid #e9ecef; }
        
        .filter-stat { cursor: pointer; border-radius: 6px; margin: 4px 0; padding: 12px 8px; transition: all 0.2s ease; border: 1px solid transparent; display: flex; justify-content: space-between; align-items: center; }
        .filter-stat:hover { background-color: #f0f8ff; border-color: #007bff; }
        .filter-stat.active { background-color: #e3f2fd; border-color: #007bff; box-shadow: 0 2px 4px rgba(0,123,255,0.1); }
        .filter-stat.active .stat-label { color: #007bff; font-weight: 600; }
        
        .stat-label { font-size: 12px; color: #6c757d; font-weight: 500; }
        .stat-value { font-size: 16px; font-weight: 600; padding: 4px 8px; border-radius: 4px; min-width: 30px; text-align: center; }
        .stat-total { background: #e3f2fd; color: #1976d2; }
        .stat-completed { background: #e8f5e8; color: #2e7d32; }
        .stat-priority { background: #fff3e0; color: #f57c00; }
        .stat-later { background: #f3e5f5; color: #7b1fa2; }
        
        .filter-btn { padding: 8px 16px; border: none; border-radius: 4px; cursor: pointer; margin: 4px; font-size: 12px; color: white; background: #6c757d; }
        .filter-btn:hover { background: #5a6268; }
        .filter-btn.clear-filter { background: #007bff; }
        .filter-btn.clear-filter:hover { background: #0056b3; }
        
        .employee-section { margin-bottom: 20px; }
        .employee-header { background: #007bff; color: white; padding: 10px; border-radius: 6px 6px 0 0; font-weight: 600; display: flex; justify-content: space-between; }
        .tasks-table { width: 100%; border-collapse: collapse; }
        .tasks-table th, .tasks-table td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; font-size: 11px; }
        .tasks-table th { background: #f8f9fa; font-weight: 600; }
        
        .task-item { }
        .task-item.hidden { display: none; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Test Task Progress Dashboard</h1>
            <div class="date">$ReportDate</div>
        </div>
        
        <div class="main-content">
            <div class="stats-panel">
                <h3>📋 Summary Filters</h3>
                <div class="filter-stat" onclick="filterBySummary('total')" data-filter="total">
                    <span class="stat-label">Total Tasks</span>
                    <span class="stat-value stat-total">$TotalTasks</span>
                </div>
                <div class="filter-stat" onclick="filterBySummary('completed')" data-filter="completed">
                    <span class="stat-label">Completed</span>
                    <span class="stat-value stat-completed">$CompletedTasks</span>
                </div>
                <div class="filter-stat" onclick="filterBySummary('high-priority')" data-filter="high-priority">
                    <span class="stat-label">High Priority</span>
                    <span class="stat-value stat-priority">$HighPriorityTasks</span>
                </div>
                <div class="filter-stat" onclick="filterBySummary('tasks-for-later')" data-filter="tasks-for-later">
                    <span class="stat-label">Tasks for Later</span>
                    <span class="stat-value stat-later">$TasksForLater</span>
                </div>
                <div style="margin-top: 15px;">
                    <button class="filter-btn clear-filter" onclick="clearSummaryFilter()">Show All</button>
                </div>
                
                <h3 style="margin-top: 20px;">👥 Employees</h3>
                <div id="employeeList">
                    <div>Peter: 5 tasks</div>
                    <div>Siva: 5 tasks</div>
                    <div>UA: 5 tasks</div>
                    <div>Vipul: 0 tasks</div>
                </div>
            </div>
            
            <div class="tasks-grid">
"@
    
    # Add employee sections
    foreach ($EmployeeGroup in $TasksByEmployee) {
        $EmployeeName = $EmployeeGroup.Name
        $EmployeeTasks = $EmployeeGroup.Group
        $TaskCount = $EmployeeTasks.Count
        
        $HTML += @"
                <div class="employee-section" data-employee="$EmployeeName">
                    <div class="employee-header">
                        <span>👤 $EmployeeName</span>
                        <span>$TaskCount tasks</span>
                    </div>
                    <table class="tasks-table">
"@
        
        foreach ($Task in $EmployeeTasks) {
            $TaskStatus = if ($Task.Status) { $Task.Status } else { "Active" }
            
            # Create simple data attributes
            $taskData = "data-status='$TaskStatus' data-priority='$($Task.Priority)' data-startdate='$($Task.StartDate)'"
            
            $HTML += @"
                        <tr class="task-item" $taskData>
                            <td><strong>$($Task.'Task Description')</strong></td>
                            <td>$TaskStatus</td>
                            <td>P$($Task.Priority)</td>
                            <td>$($Task.Progress)</td>
                            <td>$($Task.StartDate)</td>
                        </tr>
"@
        }
        
        $HTML += @"
                    </table>
                </div>
"@
    }
    
    $HTML += @"
            </div>
            
            <div class="timeline-panel">
                <h3>📈 Timeline</h3>
                <p>Timeline controls would go here</p>
                <div id="progressEvolution">
                    <div>Progress evolution content</div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        console.log('Test script loaded');
        
        function filterBySummary(filterType) {
            console.log('filterBySummary called:', filterType);
            
            // Clear active states
            document.querySelectorAll('.filter-stat').forEach(item => {
                item.classList.remove('active');
            });
            
            // Set active state
            const clickedElement = document.querySelector('[data-filter="' + filterType + '"]');
            if (clickedElement) {
                clickedElement.classList.add('active');
            }
            
            // Filter tasks
            const allTaskItems = document.querySelectorAll('.task-item');
            allTaskItems.forEach(item => {
                let shouldShow = true;
                
                const status = item.getAttribute('data-status') || '';
                const priority = item.getAttribute('data-priority') || '';
                const startDate = item.getAttribute('data-startdate') || '';
                
                switch(filterType) {
                    case 'total':
                        shouldShow = status !== 'Completed';
                        break;
                    case 'completed':
                        shouldShow = status === 'Completed';
                        break;
                    case 'high-priority':
                        shouldShow = priority === '1' && status !== 'Completed';
                        break;
                    case 'tasks-for-later':
                        shouldShow = !startDate || startDate === '';
                        break;
                }
                
                if (shouldShow) {
                    item.style.display = '';
                } else {
                    item.style.display = 'none';
                }
            });
            
            // Hide empty employee sections
            document.querySelectorAll('.employee-section').forEach(section => {
                const visibleTasks = Array.from(section.querySelectorAll('.task-item')).filter(item => item.style.display !== 'none');
                section.style.display = visibleTasks.length > 0 ? 'block' : 'none';
            });
        }
        
        function clearSummaryFilter() {
            console.log('clearSummaryFilter called');
            
            // Clear active states
            document.querySelectorAll('.filter-stat').forEach(item => {
                item.classList.remove('active');
            });
            
            // Show all tasks
            document.querySelectorAll('.task-item').forEach(item => {
                item.style.display = '';
            });
            
            // Show all employee sections
            document.querySelectorAll('.employee-section').forEach(section => {
                section.style.display = 'block';
            });
        }
        
        // Test that JavaScript is working
        document.addEventListener('DOMContentLoaded', function() {
            console.log('DOM loaded, script working');
        });
    </script>
</body>
</html>
"@
    
    $HTML | Out-File -FilePath $ReportFileName -Encoding UTF8
    Write-Host "✅ Test One-Page Report Generated: $ReportFileName" -ForegroundColor Green
    Start-Process $ReportFileName
}

# Run the test
Test-OnePageReport