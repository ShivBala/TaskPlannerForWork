<#
.SYNOPSIS
    Shows task progress by initiative with HTML pie charts

.DESCRIPTION
    Generates an interactive HTML report showing:
    - Overall task status distribution (pie chart)
    - Per-person task status distribution (individual pie charts)
    
    Uses Chart.js for visualization
#>

function Get-LatestConfigFile {
    <#
    .SYNOPSIS
        Finds the latest project_config_*.csv file in Output folder
    #>
    $outputPath = Join-Path $PSScriptRoot "Output"
    
    if (-not (Test-Path $outputPath)) {
        Write-Host "❌ Output folder not found: $outputPath" -ForegroundColor Red
        return $null
    }
    
    $configFiles = Get-ChildItem -Path $outputPath -Filter "project_config_*.csv" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '_closed_' } |
        Sort-Object LastWriteTime -Descending
    
    if ($configFiles.Count -eq 0) {
        Write-Host "❌ No project_config files found in Output folder" -ForegroundColor Red
        Write-Host "   Please export config from html_console_v10.html first" -ForegroundColor Yellow
        return $null
    }
    
    return $configFiles[0].FullName
}

function Parse-ConfigSections {
    <#
    .SYNOPSIS
        Parses CSV sections for INITIATIVES and TICKETS using proper V9 CSV adapter
    #>
    param([string]$FilePath)
    
    # Import the V9 CSV adapter for proper CSV parsing
    . "$PSScriptRoot/v9_csv_adapter_v2.ps1"
    
    # Use the proper V9 config reader
    $config = Read-V9ConfigFile -FilePath $FilePath
    
    if ($null -eq $config) {
        Write-Host "❌ Failed to parse config file" -ForegroundColor Red
        return @{
            Initiatives = @()
            Tickets = @()
        }
    }
    
    # Extract initiatives
    $initiatives = @()
    if ($config.Initiatives) {
        $initiatives = $config.Initiatives
    }
    
    # Extract tickets
    $tickets = @()
    if ($config.Tickets) {
        $tickets = $config.Tickets
    }
    
    return @{
        Initiatives = $initiatives
        Tickets = $tickets
    }
}

function Show-InitiativeMenu {
    <#
    .SYNOPSIS
        Displays numbered list of initiatives and gets user selection
    #>
    param($Initiatives)
    
    if ($Initiatives.Count -eq 0) {
        Write-Host "❌ No initiatives found in config" -ForegroundColor Red
        return $null
    }
    
    Write-Host "`n📊 Available Initiatives:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Initiatives.Count; $i++) {
        $init = $Initiatives[$i]
        $startInfo = if ($init.StartDate) { " (start: $($init.StartDate))" } else { "" }
        Write-Host "  $($i + 1). $($init.Name)$startInfo" -ForegroundColor White
    }
    
    Write-Host "`nSelect initiative (1-$($Initiatives.Count)): " -NoNewline -ForegroundColor Yellow
    $selection = Read-Host
    
    if ($selection -match '^\d+$') {
        $index = [int]$selection - 1
        if ($index -ge 0 -and $index -lt $Initiatives.Count) {
            return $Initiatives[$index]
        }
    }
    
    Write-Host "❌ Invalid selection" -ForegroundColor Red
    return $null
}

function Generate-ProgressReport {
    <#
    .SYNOPSIS
        Generates HTML report with pie charts for task status distribution
    #>
    param(
        [string]$InitiativeName,
        $Tasks
    )
    
    if ($Tasks.Count -eq 0) {
        Write-Host "❌ No tasks found for initiative: $InitiativeName" -ForegroundColor Yellow
        return $null
    }
    
    # Calculate overall status distribution
    $statusCounts = @{}
    $Tasks | ForEach-Object {
        $status = if ([string]::IsNullOrWhiteSpace($_.Status)) { "Unknown" } else { $_.Status }
        if (-not $statusCounts.ContainsKey($status)) {
            $statusCounts[$status] = 0
        }
        $statusCounts[$status]++
    }
    
    # Calculate per-person status distribution
    $personData = @{}
    $Tasks | ForEach-Object {
        # V9 adapter returns AssignedTeam as an array (already split by semicolon)
        $assignees = @()
        
        if ($_.AssignedTeam -is [array]) {
            # Filter out empty/whitespace entries
            $assignees = $_.AssignedTeam | Where-Object { ![string]::IsNullOrWhiteSpace($_) }
        } elseif (![string]::IsNullOrWhiteSpace($_.AssignedTeam)) {
            # Fallback: if it's a string, wrap it in an array
            $assignees = @($_.AssignedTeam.Trim())
        }
        
        # If no assignees, assign to "Unassigned"
        if ($assignees.Count -eq 0) {
            $assignees = @("Unassigned")
        }
        
        foreach ($person in $assignees) {
            if (-not $personData.ContainsKey($person)) {
                $personData[$person] = @{}
            }
            
            $status = if ([string]::IsNullOrWhiteSpace($_.Status)) { "Unknown" } else { $_.Status }
            if (-not $personData[$person].ContainsKey($status)) {
                $personData[$person][$status] = 0
            }
            $personData[$person][$status]++
        }
    }
    
    # Color mapping for task statuses (case-insensitive)
    # Banking theme: Professional, muted, sophisticated colors
    function Get-StatusColor {
        param([string]$Status)
        
        $colorMap = @{
            'to do' = '#7BA3C7'           # Muted slate blue
            'in progress' = '#D4AF37'     # Muted gold
            'completed' = '#5F9E6E'       # Forest green (trust/growth)
            'done' = '#5F9E6E'            # Forest green (trust/growth)
            'blocked' = '#C85A54'         # Muted red (not bright)
            'paused' = '#9B7EBD'          # Muted purple
            'closed' = '#8B9BA3'          # Blue-gray (professional)
            'unknown' = '#B8B8B8'         # Medium gray
        }
        
        $statusLower = $Status.ToLower().Trim()
        if ($colorMap.ContainsKey($statusLower)) {
            return $colorMap[$statusLower]
        }
        return '#B8B8B8'  # Default gray
    }
    
    # Generate status labels and data for overall chart
    $overallLabels = $statusCounts.Keys | ForEach-Object { "'$_'" }
    $overallData = $statusCounts.Values
    $overallColors = $statusCounts.Keys | ForEach-Object { 
        $color = Get-StatusColor -Status $_
        "'$color'"
    }
    
    # Generate per-person chart configs
    $personCharts = ""
    $personIndex = 0
    foreach ($person in $personData.Keys | Sort-Object) {
        $personStats = $personData[$person]
        $personLabels = $personStats.Keys | ForEach-Object { "'$_'" }
        $personDataValues = $personStats.Values
        $personColors = $personStats.Keys | ForEach-Object {
            $color = Get-StatusColor -Status $_
            "'$color'"
        }
        
        $totalTasks = ($personDataValues | Measure-Object -Sum).Sum
        
        $personCharts += @"
        <div class="person-chart">
            <h3>$person <span class="task-count">($totalTasks tasks)</span></h3>
            <canvas id="personChart$personIndex"></canvas>
        </div>
"@
        
        $personIndex++
    }
    
    # Generate JavaScript for person charts
    $personChartsJS = ""
    $personIndex = 0
    foreach ($person in $personData.Keys | Sort-Object) {
        $personStats = $personData[$person]
        $personLabels = ($personStats.Keys | ForEach-Object { "'$_'" }) -join ','
        $personDataValues = ($personStats.Values) -join ','
        $personColors = ($personStats.Keys | ForEach-Object {
            $color = Get-StatusColor -Status $_
            "'$color'"
        }) -join ','
        
        $personChartsJS += @"
        new Chart(document.getElementById('personChart$personIndex'), {
            type: 'pie',
            data: {
                labels: [$personLabels],
                datasets: [{
                    data: [$personDataValues],
                    backgroundColor: [$personColors],
                    borderWidth: 2,
                    borderColor: '#fff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        position: 'bottom',
                        labels: {
                            boxWidth: 15,
                            font: { size: 11 }
                        }
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                const label = context.label || '';
                                const value = context.parsed || 0;
                                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                const percentage = ((value / total) * 100).toFixed(1);
                                return label + ': ' + value + ' (' + percentage + '%)';
                            }
                        }
                    }
                }
            }
        });

"@
        
        $personIndex++
    }
    
    # Generate HTML
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Task Progress - $InitiativeName</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, 'Arial', sans-serif;
            background: #E8ECEF;
            padding: 20px;
            min-height: 100vh;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
            background: white;
            border-radius: 6px;
            box-shadow: 0 2px 12px rgba(0,0,0,0.08);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #2C5F7C 0%, #34495E 100%);
            color: white;
            padding: 24px 32px;
            border-bottom: 3px solid #1C3D52;
        }
        .header h1 {
            font-size: 1.8em;
            font-weight: 600;
            margin-bottom: 8px;
            letter-spacing: -0.5px;
        }
        .header p {
            font-size: 0.9em;
            opacity: 0.92;
            font-weight: 300;
        }
        .content {
            padding: 32px;
            background: #FAFBFC;
        }
        .stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 16px;
            margin-bottom: 32px;
        }
        .stat-card {
            background: white;
            border-left: 3px solid #5A7A8F;
            padding: 16px 20px;
            border-radius: 4px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.06);
        }
        .stat-value {
            font-size: 2em;
            font-weight: 700;
            color: #2C5F7C;
            margin-bottom: 4px;
            line-height: 1;
        }
        .stat-label {
            font-size: 0.75em;
            color: #5A6C7D;
            font-weight: 500;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .section-title {
            font-size: 1.4em;
            font-weight: 600;
            color: #2C3E50;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 2px solid #D5DBE0;
        }
        .overall-chart {
            max-width: 600px;
            margin: 0 auto 48px;
            padding: 24px;
            background: white;
            border-radius: 6px;
            border: 1px solid #D5DBE0;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        .person-charts {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 24px;
            margin-top: 32px;
        }
        .person-chart {
            background: white;
            padding: 20px;
            border-radius: 6px;
            border: 1px solid #D5DBE0;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        .person-chart h3 {
            font-size: 1.1em;
            color: #2C3E50;
            margin-bottom: 12px;
            font-weight: 600;
        }
        .task-count {
            font-size: 0.85em;
            color: #5A6C7D;
            font-weight: 400;
        }
        .footer {
            margin-top: 32px;
            padding: 16px 32px;
            background: #F4F6F8;
            text-align: center;
            color: #5A6C7D;
            font-size: 0.85em;
            border-top: 1px solid #D5DBE0;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Task Progress: $InitiativeName</h1>
            <p>Initiative Progress Report - Generated $(Get-Date -Format 'MMMM dd, yyyy HH:mm')</p>
        </div>
        
        <div class="content">
            <div class="stats">
                <div class="stat-card">
                    <div class="stat-value">$($Tasks.Count)</div>
                    <div class="stat-label">Total Tasks</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">$($personData.Keys.Count)</div>
                    <div class="stat-label">Team Members</div>
                </div>
                <div class="stat-card">
                    <div class="stat-value">$($statusCounts.Keys.Count)</div>
                    <div class="stat-label">Unique Statuses</div>
                </div>
            </div>
            
            <h2 class="section-title">Overall Task Status Distribution</h2>
            <div class="overall-chart">
                <canvas id="overallChart"></canvas>
            </div>
            
            <h2 class="section-title">Per-Person Task Breakdown</h2>
            <div class="person-charts">
$personCharts
            </div>
        </div>
        
        <div class="footer">
            <p><strong>Task Progress Report</strong> | Generated from V10 Configuration</p>
            <p>Initiative: $InitiativeName | Total Tasks: $($Tasks.Count)</p>
        </div>
    </div>
    
    <script>
        // Overall chart
        new Chart(document.getElementById('overallChart'), {
            type: 'pie',
            data: {
                labels: [$($overallLabels -join ',')],
                datasets: [{
                    data: [$($overallData -join ',')],
                    backgroundColor: [$($overallColors -join ',')],
                    borderWidth: 2,
                    borderColor: '#fff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        position: 'right',
                        labels: {
                            boxWidth: 20,
                            font: { size: 13 }
                        }
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                const label = context.label || '';
                                const value = context.parsed || 0;
                                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                                const percentage = ((value / total) * 100).toFixed(1);
                                return label + ': ' + value + ' (' + percentage + '%)';
                            }
                        }
                    }
                }
            }
        });
        
        // Person charts
$personChartsJS
    </script>
</body>
</html>
"@
    
    # Save HTML to reports folder
    $reportsDir = Join-Path $PSScriptRoot "html reports"
    if (-not (Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $safeName = $InitiativeName -replace '[^\w\s-]', '' -replace '\s+', '_'
    $htmlPath = Join-Path $reportsDir "taskprogress_${safeName}_${timestamp}.html"
    
    $html | Set-Content -Path $htmlPath -Encoding UTF8
    
    return $htmlPath
}

function Show-InitiativeProgress {
    <#
    .SYNOPSIS
        Main function - shows initiative progress report
    #>
    
    Write-Host "`n📊 Initiative Task Progress Report" -ForegroundColor Cyan
    
    # 1. Find latest config file
    $configPath = Get-LatestConfigFile
    if ($null -eq $configPath) {
        return
    }
    
    Write-Host "✅ Loaded config: $(Split-Path $configPath -Leaf)" -ForegroundColor Green
    
    # 2. Parse config
    $config = Parse-ConfigSections -FilePath $configPath
    
    if ($config.Initiatives.Count -eq 0) {
        Write-Host "❌ No initiatives found in config" -ForegroundColor Red
        return
    }
    
    # 3. Show initiative menu
    $selectedInitiative = Show-InitiativeMenu -Initiatives $config.Initiatives
    
    if ($null -eq $selectedInitiative) {
        return
    }
    
    Write-Host "✅ Selected: $($selectedInitiative.Name)" -ForegroundColor Green
    
    # 4. Filter tasks by initiative
    $initiativeTasks = $config.Tickets | Where-Object { $_.Initiative -eq $selectedInitiative.Name }
    
    if ($initiativeTasks.Count -eq 0) {
        Write-Host "⚠️  No tasks found for initiative: $($selectedInitiative.Name)" -ForegroundColor Yellow
        return
    }
    
    Write-Host "📋 Found $($initiativeTasks.Count) tasks" -ForegroundColor Cyan
    
    # 5. Generate HTML report
    Write-Host "`n🔨 Generating HTML report with pie charts..." -ForegroundColor Cyan
    
    $htmlPath = Generate-ProgressReport -InitiativeName $selectedInitiative.Name -Tasks $initiativeTasks
    
    if ($null -eq $htmlPath) {
        return
    }
    
    Write-Host "✅ Report generated: $htmlPath" -ForegroundColor Green
    
    # 6. Open in browser
    Write-Host "`n🌐 Opening report in browser..." -ForegroundColor Cyan
    
    try {
        if ($IsMacOS) {
            Start-Process "open" -ArgumentList "`"$htmlPath`""
        } elseif ($IsLinux) {
            Start-Process "xdg-open" -ArgumentList "`"$htmlPath`""
        } else {
            Start-Process "`"$htmlPath`""
        }
        Write-Host "✅ Report opened successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to open report: $_" -ForegroundColor Red
        Write-Host "   Please open manually: $htmlPath" -ForegroundColor Yellow
    }
}

# Export function
Export-ModuleMember -Function Show-InitiativeProgress
