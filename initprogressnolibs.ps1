<#
.SYNOPSIS
    Shows task progress by initiative with HTML reports (no external libraries)

.DESCRIPTION
    Generates an interactive HTML report showing:
    - Overall task status distribution (CSS-based bar charts)
    - Per-person task breakdown (individual bar charts)
    
    Uses only pure HTML/CSS - no external JavaScript libraries required
    Safe for workplace environments with strict security policies
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

function Generate-ProgressReportNoLibs {
    <#
    .SYNOPSIS
        Generates HTML report with CSS bar charts (no external libraries)
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
    
    # Color mapping for task statuses (banking theme)
    function Get-StatusColor {
        param([string]$Status)
        
        $colorMap = @{
            'to do' = '#7BA3C7'           # Muted slate blue
            'in progress' = '#D4AF37'     # Muted gold
            'completed' = '#5F9E6E'       # Forest green
            'done' = '#5F9E6E'            # Forest green
            'blocked' = '#C85A54'         # Muted red
            'paused' = '#9B7EBD'          # Muted purple
            'closed' = '#8B9BA3'          # Blue-gray
            'unknown' = '#B8B8B8'         # Medium gray
        }
        
        $statusLower = $Status.ToLower().Trim()
        if ($colorMap.ContainsKey($statusLower)) {
            return $colorMap[$statusLower]
        }
        return '#B8B8B8'  # Default gray
    }
    
    # Generate overall status bars HTML
    $totalTasks = $Tasks.Count
    $overallBarsHtml = ""
    foreach ($status in ($statusCounts.Keys | Sort-Object)) {
        $count = $statusCounts[$status]
        $percentage = [math]::Round(($count / $totalTasks) * 100, 1)
        $color = Get-StatusColor -Status $status
        
        $overallBarsHtml += @"
                    <div class="bar-row">
                        <div class="bar-label">$status</div>
                        <div class="bar-container">
                            <div class="bar-fill" style="width: $percentage%; background-color: $color;">
                                <span class="bar-text">$count tasks ($percentage%)</span>
                            </div>
                        </div>
                    </div>
"@
    }
    
    # Generate per-person charts HTML
    $personChartsHtml = ""
    foreach ($person in ($personData.Keys | Sort-Object)) {
        $personStats = $personData[$person]
        $personTotal = ($personStats.Values | Measure-Object -Sum).Sum
        
        $personBarsHtml = ""
        foreach ($status in ($personStats.Keys | Sort-Object)) {
            $count = $personStats[$status]
            $percentage = [math]::Round(($count / $personTotal) * 100, 1)
            $color = Get-StatusColor -Status $status
            
            $personBarsHtml += @"
                        <div class="bar-row">
                            <div class="bar-label-small">$status</div>
                            <div class="bar-container-small">
                                <div class="bar-fill" style="width: $percentage%; background-color: $color;">
                                    <span class="bar-text-small">$count ($percentage%)</span>
                                </div>
                            </div>
                        </div>
"@
        }
        
        $personChartsHtml += @"
                <div class="person-card">
                    <div class="person-header">
                        <h3>$person</h3>
                        <span class="task-count">$personTotal tasks</span>
                    </div>
                    <div class="person-bars">
$personBarsHtml
                    </div>
                </div>
"@
    }
    
    # Generate complete HTML
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Task Progress - $InitiativeName</title>
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
        
        .no-libs-badge {
            display: inline-block;
            background: rgba(255, 255, 255, 0.2);
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 0.75em;
            margin-top: 8px;
            font-weight: 500;
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
            max-width: 800px;
            margin: 0 auto 48px;
            padding: 24px;
            background: white;
            border-radius: 6px;
            border: 1px solid #D5DBE0;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        
        .bar-row {
            display: flex;
            align-items: center;
            margin-bottom: 16px;
            gap: 12px;
        }
        
        .bar-label {
            min-width: 120px;
            font-weight: 500;
            color: #2C3E50;
            font-size: 0.9em;
        }
        
        .bar-label-small {
            min-width: 100px;
            font-weight: 500;
            color: #2C3E50;
            font-size: 0.85em;
        }
        
        .bar-container {
            flex: 1;
            height: 40px;
            background: #F0F2F5;
            border-radius: 4px;
            overflow: hidden;
            position: relative;
        }
        
        .bar-container-small {
            flex: 1;
            height: 32px;
            background: #F0F2F5;
            border-radius: 4px;
            overflow: hidden;
            position: relative;
        }
        
        .bar-fill {
            height: 100%;
            display: flex;
            align-items: center;
            padding: 0 12px;
            transition: width 0.8s ease-in-out;
            position: relative;
        }
        
        .bar-text {
            color: white;
            font-weight: 600;
            font-size: 0.85em;
            text-shadow: 0 1px 2px rgba(0,0,0,0.2);
            white-space: nowrap;
        }
        
        .bar-text-small {
            color: white;
            font-weight: 600;
            font-size: 0.75em;
            text-shadow: 0 1px 2px rgba(0,0,0,0.2);
            white-space: nowrap;
        }
        
        .person-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(400px, 1fr));
            gap: 24px;
            margin-top: 32px;
        }
        
        .person-card {
            background: white;
            padding: 20px;
            border-radius: 6px;
            border: 1px solid #D5DBE0;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
        }
        
        .person-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 16px;
            padding-bottom: 12px;
            border-bottom: 2px solid #E8ECEF;
        }
        
        .person-header h3 {
            font-size: 1.1em;
            color: #2C3E50;
            font-weight: 600;
        }
        
        .task-count {
            font-size: 0.85em;
            color: #5A6C7D;
            font-weight: 500;
            background: #F0F2F5;
            padding: 4px 12px;
            border-radius: 12px;
        }
        
        .person-bars {
            display: flex;
            flex-direction: column;
            gap: 12px;
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
        
        .footer-note {
            margin-top: 8px;
            font-size: 0.9em;
            color: #7A8C9D;
        }
        
        .footer-note strong {
            color: #2C5F7C;
        }
        
        @media print {
            body {
                background: white;
                padding: 0;
            }
            
            .container {
                box-shadow: none;
            }
            
            .no-libs-badge {
                display: none;
            }
        }
        
        /* Animation on page load */
        @keyframes slideIn {
            from {
                opacity: 0;
                transform: translateY(20px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
        
        .overall-chart, .person-card {
            animation: slideIn 0.5s ease-out;
        }
        
        .person-card:nth-child(1) { animation-delay: 0.1s; }
        .person-card:nth-child(2) { animation-delay: 0.2s; }
        .person-card:nth-child(3) { animation-delay: 0.3s; }
        .person-card:nth-child(4) { animation-delay: 0.4s; }
        .person-card:nth-child(5) { animation-delay: 0.5s; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>📊 Task Progress: $InitiativeName</h1>
            <p>Initiative Progress Report - Generated $(Get-Date -Format 'MMMM dd, yyyy HH:mm')</p>
            <div class="no-libs-badge">🔒 No External Libraries - Workplace Safe</div>
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
$overallBarsHtml
            </div>
            
            <h2 class="section-title">Per-Person Task Breakdown</h2>
            <div class="person-grid">
$personChartsHtml
            </div>
        </div>
        
        <div class="footer">
            <p><strong>Task Progress Report</strong> | Generated from V10 Configuration</p>
            <p>Initiative: $InitiativeName | Total Tasks: $($Tasks.Count)</p>
            <p class="footer-note"><strong>Security Note:</strong> This report uses only pure HTML/CSS - no external JavaScript libraries required</p>
        </div>
    </div>
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
    $htmlPath = Join-Path $reportsDir "taskprogress_nolibs_${safeName}_${timestamp}.html"
    
    $html | Set-Content -Path $htmlPath -Encoding UTF8
    
    return $htmlPath
}

function Show-InitiativeProgressNoLibs {
    <#
    .SYNOPSIS
        Main function - shows initiative progress report (no external libraries)
    #>
    
    Write-Host "`n📊 Initiative Task Progress Report (No External Libraries)" -ForegroundColor Cyan
    Write-Host "🔒 Workplace Safe - Pure HTML/CSS only" -ForegroundColor Green
    
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
    Write-Host "`n🔨 Generating HTML report with CSS bar charts..." -ForegroundColor Cyan
    Write-Host "   ✓ No external JavaScript libraries" -ForegroundColor Green
    Write-Host "   ✓ Pure HTML/CSS visualization" -ForegroundColor Green
    
    $htmlPath = Generate-ProgressReportNoLibs -InitiativeName $selectedInitiative.Name -Tasks $initiativeTasks
    
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
Export-ModuleMember -Function Show-InitiativeProgressNoLibs
