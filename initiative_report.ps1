# Initiative Report Module
# Generates interactive HTML reports for tasks grouped by initiatives

function Show-InitiativeTaskReport {
    <#
    .SYNOPSIS
        Generates an interactive HTML report for tasks filtered by initiative(s)
    
    .DESCRIPTION
        Creates a detailed HTML page with:
        - All tasks for selected initiative(s)
        - Client-side filtering and search
        - CSV export functionality
        - Copy to clipboard feature
    
    .EXAMPLE
        Show-InitiativeTaskReport
    #>
    
    if ($null -eq $global:V9Config) {
        Write-Host "❌ Config not loaded" -ForegroundColor Red
        return
    }
    
    if ($null -eq $global:V9Config.Initiatives -or $global:V9Config.Initiatives.Count -eq 0) {
        Write-Host "❌ No initiatives found in configuration" -ForegroundColor Red
        return
    }
    
    if ($null -eq $global:V9Config.Tickets -or $global:V9Config.Tickets.Count -eq 0) {
        Write-Host "❌ No tasks found in configuration" -ForegroundColor Red
        return
    }
    
    # Display numbered list of initiatives
    Write-Host "`n📋 Available Initiatives:" -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor Gray
    
    # Build initiatives list with Today and General first
    $initiatives = @()
    
    # Always add Today first
    $todayCount = @($global:V9Config.Tickets | Where-Object { $_.Initiative -eq 'Today' }).Count
    $initiatives += [PSCustomObject]@{ Name = 'Today'; StartDate = $null; EndDate = $null }
    
    # Always add General second
    $generalCount = @($global:V9Config.Tickets | Where-Object { $_.Initiative -eq 'General' }).Count
    $initiatives += [PSCustomObject]@{ Name = 'General'; StartDate = $null; EndDate = $null }
    
    # Then add all defined initiatives from config
    $initiatives += @($global:V9Config.Initiatives)
    
    for ($i = 0; $i -lt $initiatives.Count; $i++) {
        $initiative = $initiatives[$i]
        $taskCount = @($global:V9Config.Tickets | Where-Object { $_.Initiative -eq $initiative.Name }).Count
        Write-Host ("{0,3}. {1} ({2} tasks)" -f ($i + 1), $initiative.Name, $taskCount) -ForegroundColor White
    }    Write-Host ("=" * 60) -ForegroundColor Gray
    Write-Host "`nEnter initiative numbers (comma or space separated, e.g., '1,3,5' or '1 3 5'):" -ForegroundColor Yellow
    Write-Host "Or enter 'all' to include all initiatives, or 'cancel' to abort:" -ForegroundColor Gray
    
    $input = Read-Host "Selection"
    
    if ([string]::IsNullOrWhiteSpace($input) -or $input -eq 'cancel') {
        Write-Host "❌ Cancelled" -ForegroundColor Yellow
        return
    }
    
    # Parse selection
    $selectedInitiatives = @()
    
    if ($input.ToLower() -eq 'all') {
        $selectedInitiatives = $initiatives | Select-Object -ExpandProperty Name
    } else {
        # Parse comma or space separated numbers
        $numbers = $input -replace '[,\s]+', ',' -split ',' | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
        
        foreach ($num in $numbers) {
            if ($num -ge 1 -and $num -le $initiatives.Count) {
                $selectedInitiatives += $initiatives[$num - 1].Name
            } else {
                Write-Host "⚠️  Warning: Invalid number $num (must be 1-$($initiatives.Count))" -ForegroundColor Yellow
            }
        }
    }
    
    if ($selectedInitiatives.Count -eq 0) {
        Write-Host "❌ No valid initiatives selected" -ForegroundColor Red
        return
    }
    
    Write-Host "`n✅ Selected $($selectedInitiatives.Count) initiative(s):" -ForegroundColor Green
    $selectedInitiatives | ForEach-Object { Write-Host "   • $_" -ForegroundColor White }
    
    # Filter tasks by selected initiatives
    $filteredTasks = $global:V9Config.Tickets | Where-Object { 
        $selectedInitiatives -contains $_.Initiative 
    }
    
    if ($filteredTasks.Count -eq 0) {
        Write-Host "`n⚠️  No tasks found for selected initiative(s)" -ForegroundColor Yellow
        return
    }
    
    Write-Host "`n📊 Found $($filteredTasks.Count) task(s). Generating report..." -ForegroundColor Cyan
    
    # Create "html reports" directory if it doesn't exist
    $reportsDir = Join-Path $PSScriptRoot "html reports"
    if (-not (Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    }
    
    # Generate HTML report
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $htmlPath = Join-Path $reportsDir "initiative_report_$timestamp.html"
    
    # Build HTML table rows directly (avoiding JSON embedding issues)
    $tableRowsHtml = ""
    foreach ($task in $filteredTasks) {
        $assignedTeam = if ($task.AssignedTeam -is [array]) {
            ($task.AssignedTeam -join '; ') -replace '"', '&quot;' -replace '<', '&lt;' -replace '>', '&gt;'
        } else {
            $task.AssignedTeam -replace '"', '&quot;' -replace '<', '&lt;' -replace '>', '&gt;'
        }
        
        $description = $task.Description -replace '"', '&quot;' -replace '<', '&lt;' -replace '>', '&gt;'
        $initiative = $task.Initiative -replace '"', '&quot;' -replace '<', '&lt;' -replace '>', '&gt;'
        $stakeholder = $task.Stakeholder -replace '"', '&quot;' -replace '<', '&lt;' -replace '>', '&gt;'
        $endDate = if ($task.EndDate) { $task.EndDate } else { "" }
        
        $priorityClass = "badge-" + $task.Priority.ToLower()
        $sizeClass = "badge-" + $task.Size.ToLower()
        $statusClass = "badge-" + ($task.Status -replace '\s+', '').ToLower()
        
        # Store data attributes for filtering
        $dataAttrs = "data-id=`"$($task.ID)`" data-desc=`"$description`" data-priority=`"$($task.Priority)`" data-size=`"$($task.Size)`" data-status=`"$($task.Status)`" data-initiative=`"$initiative`" data-stakeholder=`"$stakeholder`" data-team=`"$assignedTeam`""
        
        $tableRowsHtml += @"
                        <tr $dataAttrs>
                            <td>$($task.ID)</td>
                            <td>$description</td>
                            <td><span class="badge $priorityClass">$($task.Priority)</span></td>
                            <td><span class="badge $sizeClass">$($task.Size)</span></td>
                            <td><span class="badge $statusClass">$($task.Status)</span></td>
                            <td>$initiative</td>
                            <td>$stakeholder</td>
                            <td>$assignedTeam</td>
                            <td>$($task.StartDate)</td>
                            <td>$endDate</td>
                            <td>$($task.TaskType)</td>
                        </tr>

"@
    }
    
    # Build initiative list for display
    $initiativeList = ($selectedInitiatives | ForEach-Object { "<strong>$_</strong>" }) -join ', '
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Initiative Tasks Report - $(Get-Date -Format 'MMM dd, yyyy')</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #2d3748;
            background: #f7fafc;
            padding: 20px;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            border-radius: 8px;
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #1e3a5f 0%, #2c5282 100%);
            color: white;
            padding: 30px;
            border-bottom: 3px solid #1a365d;
        }
        .header h1 {
            font-size: 1.8em;
            font-weight: 600;
            margin-bottom: 8px;
        }
        .header .subtitle {
            font-size: 1em;
            opacity: 0.9;
            margin-top: 10px;
        }
        .header .date {
            font-size: 0.9em;
            opacity: 0.8;
            margin-top: 5px;
        }
        .controls {
            padding: 20px 30px;
            background: #f8fafc;
            border-bottom: 1px solid #e2e8f0;
            display: flex;
            gap: 15px;
            flex-wrap: wrap;
            align-items: center;
        }
        .search-box {
            flex: 1;
            min-width: 250px;
        }
        .search-box input {
            width: 100%;
            padding: 10px 15px;
            border: 2px solid #cbd5e0;
            border-radius: 4px;
            font-size: 0.95em;
            transition: border-color 0.2s;
        }
        .search-box input:focus {
            outline: none;
            border-color: #4299e1;
        }
        .filter-group {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        .filter-select {
            padding: 8px 12px;
            border: 2px solid #cbd5e0;
            border-radius: 4px;
            font-size: 0.9em;
            background: white;
            cursor: pointer;
            transition: border-color 0.2s;
        }
        .filter-select:focus {
            outline: none;
            border-color: #4299e1;
        }
        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 4px;
            font-size: 0.9em;
            font-weight: 600;
            cursor: pointer;
            transition: all 0.2s;
        }
        .btn-primary {
            background: #2c5282;
            color: white;
        }
        .btn-primary:hover {
            background: #1e3a5f;
        }
        .btn-secondary {
            background: #48bb78;
            color: white;
        }
        .btn-secondary:hover {
            background: #38a169;
        }
        .btn:active {
            transform: scale(0.98);
        }
        .stats {
            padding: 15px 30px;
            background: white;
            border-bottom: 1px solid #e2e8f0;
            display: flex;
            gap: 30px;
            flex-wrap: wrap;
        }
        .stat-item {
            font-size: 0.9em;
        }
        .stat-label {
            color: #718096;
            margin-right: 5px;
        }
        .stat-value {
            font-weight: 600;
            color: #2d3748;
        }
        .content {
            padding: 30px;
        }
        .table-container {
            overflow-x: auto;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.9em;
        }
        thead {
            background: #edf2f7;
            position: sticky;
            top: 0;
            z-index: 10;
        }
        th {
            text-align: left;
            padding: 12px;
            font-weight: 600;
            color: #2d3748;
            border-bottom: 2px solid #cbd5e0;
            white-space: nowrap;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #e2e8f0;
        }
        tbody tr {
            transition: background-color 0.2s;
        }
        tbody tr:hover {
            background: #f7fafc;
        }
        tbody tr.hidden {
            display: none;
        }
        .badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 0.8em;
            font-weight: 600;
            text-transform: uppercase;
        }
        .badge-p1 { background: #feb2b2; color: #742a2a; }
        .badge-p2 { background: #fbd38d; color: #744210; }
        .badge-p3 { background: #9ae6b4; color: #22543d; }
        .badge-xs, .badge-s, .badge-m { background: #cbd5e0; color: #2d3748; }
        .badge-l, .badge-xl, .badge-xxl { background: #a0aec0; color: #1a202c; }
        .badge-todo { background: #bee3f8; color: #2c5282; }
        .badge-inprogress { background: #fbd38d; color: #744210; }
        .badge-done { background: #9ae6b4; color: #22543d; }
        .no-results {
            text-align: center;
            padding: 60px 20px;
            color: #718096;
        }
        .no-results p {
            font-size: 1.2em;
            margin-bottom: 10px;
        }
        .feedback {
            position: fixed;
            top: 20px;
            right: 20px;
            background: #48bb78;
            color: white;
            padding: 15px 20px;
            border-radius: 4px;
            box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            font-weight: 600;
            opacity: 0;
            transition: opacity 0.3s;
            z-index: 1000;
        }
        .feedback.show {
            opacity: 1;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📋 Initiative Tasks Report</h1>
            <div class="subtitle">Initiatives: $initiativeList</div>
            <div class="date">Generated: $(Get-Date -Format 'MMMM dd, yyyy HH:mm')</div>
        </div>
        
        <div class="controls">
            <div class="search-box">
                <input type="text" id="searchInput" placeholder="🔍 Search tasks (ID, description, team, stakeholder...)">
            </div>
            <div class="filter-group">
                <select id="priorityFilter" class="filter-select">
                    <option value="">All Priorities</option>
                    <option value="P1">P1</option>
                    <option value="P2">P2</option>
                    <option value="P3">P3</option>
                </select>
                <select id="statusFilter" class="filter-select">
                    <option value="">All Statuses</option>
                    <option value="To Do">To Do</option>
                    <option value="In Progress">In Progress</option>
                    <option value="Done">Done</option>
                </select>
                <select id="sizeFilter" class="filter-select">
                    <option value="">All Sizes</option>
                    <option value="XS">XS</option>
                    <option value="S">S</option>
                    <option value="M">M</option>
                    <option value="L">L</option>
                    <option value="XL">XL</option>
                    <option value="XXL">XXL</option>
                </select>
            </div>
            <button class="btn btn-secondary" onclick="exportToCSV()">📥 Export CSV</button>
            <button class="btn btn-primary" onclick="copyToClipboard()">📋 Copy to Clipboard</button>
        </div>
        
        <div class="stats">
            <div class="stat-item">
                <span class="stat-label">Total Tasks:</span>
                <span class="stat-value" id="totalCount">$($filteredTasks.Count)</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Visible:</span>
                <span class="stat-value" id="visibleCount">$($filteredTasks.Count)</span>
            </div>
            <div class="stat-item">
                <span class="stat-label">Filtered:</span>
                <span class="stat-value" id="filteredCount">0</span>
            </div>
        </div>
        
        <div class="content">
            <div class="table-container">
                <table id="tasksTable">
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Description</th>
                            <th>Priority</th>
                            <th>Size</th>
                            <th>Status</th>
                            <th>Initiative</th>
                            <th>Stakeholder</th>
                            <th>Team</th>
                            <th>Start Date</th>
                            <th>End Date</th>
                            <th>Type</th>
                        </tr>
                    </thead>
                    <tbody id="tasksBody">
$tableRowsHtml
                    </tbody>
                </table>
            </div>
            <div id="noResults" class="no-results" style="display: none;">
                <p>No tasks match your filters</p>
                <p style="font-size: 0.9em;">Try adjusting your search or filter criteria</p>
            </div>
        </div>
    </div>
    
    <div id="feedback" class="feedback"></div>
    
    <script>
        console.log('Initiative Task Report loaded');
        
        // Apply all filters (rows are already rendered, just need to show/hide)
        function applyFilters() {
            const searchTerm = document.getElementById('searchInput').value.toLowerCase();
            const priorityFilter = document.getElementById('priorityFilter').value;
            const statusFilter = document.getElementById('statusFilter').value;
            const sizeFilter = document.getElementById('sizeFilter').value;
            
            const rows = document.querySelectorAll('#tasksBody tr');
            let visibleCount = 0;
            
            rows.forEach(row => {
                const id = row.dataset.id;
                const desc = row.dataset.desc || '';
                const priority = row.dataset.priority || '';
                const status = row.dataset.status || '';
                const size = row.dataset.size || '';
                const initiative = row.dataset.initiative || '';
                const stakeholder = row.dataset.stakeholder || '';
                const team = row.dataset.team || '';
                
                const searchableText = (id + ' ' + desc + ' ' + team + ' ' + stakeholder + ' ' + initiative).toLowerCase();
                
                const matchesSearch = !searchTerm || searchableText.includes(searchTerm);
                const matchesPriority = !priorityFilter || priority === priorityFilter;
                const matchesStatus = !statusFilter || status === statusFilter;
                const matchesSize = !sizeFilter || size === sizeFilter;
                
                const isVisible = matchesSearch && matchesPriority && matchesStatus && matchesSize;
                
                if (isVisible) {
                    row.classList.remove('hidden');
                    visibleCount++;
                } else {
                    row.classList.add('hidden');
                }
            });
            
            // Update stats
            document.getElementById('visibleCount').textContent = visibleCount;
            document.getElementById('filteredCount').textContent = rows.length - visibleCount;
            
            // Show/hide no results message
            const noResults = document.getElementById('noResults');
            const table = document.getElementById('tasksTable');
            if (visibleCount === 0) {
                noResults.style.display = 'block';
                table.style.display = 'none';
            } else {
                noResults.style.display = 'none';
                table.style.display = 'table';
            }
        }
        
        // Export to CSV
        function exportToCSV() {
            const allRows = document.querySelectorAll('#tasksBody tr');
            const visibleRows = Array.from(document.querySelectorAll('#tasksBody tr:not(.hidden)'));
            
            console.log('Export CSV - Total rows:', allRows.length);
            console.log('Export CSV - Visible rows:', visibleRows.length);
            console.log('Export CSV - First row:', visibleRows.length > 0 ? visibleRows[0] : 'none');
            
            if (visibleRows.length === 0) {
                showFeedback('No tasks to export', false);
                return;
            }
            
            const headers = ['ID', 'Description', 'Priority', 'Size', 'Status', 'Initiative', 
                           'Stakeholder', 'Team', 'Start Date', 'End Date', 'Type'];
            
            let csv = headers.join(',') + '\n';
            
            visibleRows.forEach(row => {
                const cells = row.querySelectorAll('td');
                console.log('Processing row - cells found:', cells.length);
                const values = Array.from(cells).map(cell => {
                    let text = cell.textContent.trim();
                    // Handle CSV escaping - quote fields that contain commas, quotes, or newlines
                    if (text.includes(',') || text.includes('"') || text.includes('\n')) {
                        text = '"' + text.replace(/"/g, '""') + '"';
                    }
                    return text;
                });
                csv += values.join(',') + '\n';
            });
            
            const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = 'initiative_tasks_' + new Date().toISOString().slice(0, 10) + '.csv';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            window.URL.revokeObjectURL(url);
            
            showFeedback('Exported ' + visibleRows.length + ' task(s) to CSV', true);
        }
        
        // Copy to clipboard
        function copyToClipboard() {
            const allRows = document.querySelectorAll('#tasksBody tr');
            const visibleRows = Array.from(document.querySelectorAll('#tasksBody tr:not(.hidden)'));
            
            console.log('Copy to clipboard - Total rows:', allRows.length);
            console.log('Copy to clipboard - Visible rows:', visibleRows.length);
            
            if (visibleRows.length === 0) {
                showFeedback('No tasks to copy', false);
                return;
            }
            
            const headers = ['ID', 'Description', 'Priority', 'Size', 'Status', 'Initiative', 
                           'Stakeholder', 'Team', 'Start Date', 'End Date', 'Type'];
            
            let text = headers.join('\t') + '\n';
            
            visibleRows.forEach(row => {
                const cells = row.querySelectorAll('td');
                const values = Array.from(cells).map(cell => cell.textContent.trim());
                text += values.join('\t') + '\n';
            });
            
            navigator.clipboard.writeText(text).then(() => {
                showFeedback('Copied ' + visibleRows.length + ' task(s) to clipboard', true);
            }).catch(err => {
                console.error('Failed to copy:', err);
                showFeedback('Failed to copy to clipboard', false);
            });
        }
        
        // Show feedback message
        function showFeedback(message, success) {
            const feedback = document.getElementById('feedback');
            feedback.textContent = message;
            feedback.style.background = success ? '#48bb78' : '#f56565';
            feedback.classList.add('show');
            setTimeout(() => {
                feedback.classList.remove('show');
            }, 3000);
        }
        
        // Event listeners
        document.getElementById('searchInput').addEventListener('input', applyFilters);
        document.getElementById('priorityFilter').addEventListener('change', applyFilters);
        document.getElementById('statusFilter').addEventListener('change', applyFilters);
        document.getElementById('sizeFilter').addEventListener('change', applyFilters);
        
        // Initial load
        applyFilters();
    </script>
</body>
</html>
"@
    
    # Write HTML file
    try {
        $html | Out-File -FilePath $htmlPath -Encoding UTF8 -Force
        Write-Host "✅ Report generated: $htmlPath" -ForegroundColor Green
        
        # Open in browser - use Invoke-Item which handles spaces properly
        try {
            Invoke-Item $htmlPath
            Write-Host "🌐 Opening in browser..." -ForegroundColor Cyan
        } catch {
            Write-Host "⚠️  Could not auto-open browser. Please open manually:" -ForegroundColor Yellow
            Write-Host "   $htmlPath" -ForegroundColor Gray
        }
    } catch {
        Write-Host "❌ Failed to generate report: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Note: Export-ModuleMember not needed when using dot-sourcing (. script.ps1)
