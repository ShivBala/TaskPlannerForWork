# Excel Template Creator - Phase 2 (Cross-Platform Compatible)
# Creates Excel-compatible files and VBA code for timeline visualization

function New-ExcelTaskTemplate {
    [CmdletBinding()]
    param(
        [string]$OutputPath = "./ExcelTaskTemplate",
        [switch]$OpenAfterCreation
    )
    
    Write-Host "🎯 Creating Excel Template Framework - Phase 2..." -ForegroundColor Cyan
    Write-Host "   (Cross-Platform Compatible Version)" -ForegroundColor Yellow
    
    try {
        # Create template directory
        $templateDir = Join-Path (Get-Location) $OutputPath.TrimStart("./")
        if (Test-Path $templateDir) {
            Remove-Item $templateDir -Recurse -Force
        }
        New-Item -Path $templateDir -ItemType Directory -Force | Out-Null
        
        Write-Host "📁 Creating template structure in: $templateDir" -ForegroundColor Green
        
        # Create VBA Module Files
        $vbaDir = Join-Path $templateDir "VBA_Modules"
        New-Item -Path $vbaDir -ItemType Directory -Force | Out-Null
        
        # === VBA MODULE: TimelineController ===
        $timelineModule = @'
' Timeline Controller Module - Phase 2 Framework
' Handles timeline navigation and data loading

Option Explicit

' Global variables
Public CurrentSnapshotIndex As Integer
Public TotalSnapshots As Integer
Public IsTimelinePlaying As Boolean
Public TimelineTimer As Double

' Initialize the timeline system
Sub InitializeTimeline()
    CurrentSnapshotIndex = 1
    TotalSnapshots = 16
    IsTimelinePlaying = False
    
    ' Update display
    Range("TimelineDisplay").Value = "Snapshot " & CurrentSnapshotIndex & " of " & TotalSnapshots
    
    ' Load initial data
    Call LoadSnapshotData(CurrentSnapshotIndex)
    
    MsgBox "Timeline initialized! Ready for data import.", vbInformation, "Timeline Ready"
End Sub

' Load data for specific snapshot
Sub LoadSnapshotData(snapshotIndex As Integer)
    ' Framework for loading snapshot data
    ' Phase 3 will implement actual data loading
    
    Dim message As String
    message = "Loading Snapshot " & snapshotIndex & vbNewLine
    message = message & "This will be implemented in Phase 3"
    
    ' Update timeline display
    Range("TimelineDisplay").Value = "Snapshot " & snapshotIndex & " of " & TotalSnapshots
    
    ' Placeholder: Update task data range
    Call UpdateTaskDisplay(snapshotIndex)
End Sub

' Update the task display area (placeholder)
Sub UpdateTaskDisplay(snapshotIndex As Integer)
    Dim taskRange As Range
    Set taskRange = Range("TaskDataRange")
    
    ' Clear existing data
    taskRange.ClearContents
    
    ' Placeholder data for demonstration
    taskRange.Cells(1, 1).Value = "John Smith"
    taskRange.Cells(1, 2).Value = "Database Migration"
    taskRange.Cells(1, 3).Value = snapshotIndex * 5 & "%"
    taskRange.Cells(1, 4).Value = Now()
    
    taskRange.Cells(2, 1).Value = "Sarah Johnson"
    taskRange.Cells(2, 2).Value = "Frontend Redesign"
    taskRange.Cells(2, 3).Value = snapshotIndex * 6 & "%"
    taskRange.Cells(2, 4).Value = Now()
    
    taskRange.Cells(3, 1).Value = "Michael Chen"
    taskRange.Cells(3, 2).Value = "API Integration"
    taskRange.Cells(3, 3).Value = snapshotIndex * 4 & "%"
    taskRange.Cells(3, 4).Value = Now()
    
    taskRange.Cells(4, 1).Value = "Emily Davis"
    taskRange.Cells(4, 2).Value = "Testing Framework"
    taskRange.Cells(4, 3).Value = snapshotIndex * 7 & "%"
    taskRange.Cells(4, 4).Value = Now()
End Sub

' Navigation functions
Sub StepForward()
    If CurrentSnapshotIndex < TotalSnapshots Then
        CurrentSnapshotIndex = CurrentSnapshotIndex + 1
        Call LoadSnapshotData(CurrentSnapshotIndex)
    Else
        MsgBox "Already at the latest snapshot!", vbInformation
    End If
End Sub

Sub StepBackward()
    If CurrentSnapshotIndex > 1 Then
        CurrentSnapshotIndex = CurrentSnapshotIndex - 1
        Call LoadSnapshotData(CurrentSnapshotIndex)
    Else
        MsgBox "Already at the first snapshot!", vbInformation
    End If
End Sub

Sub GoToStart()
    CurrentSnapshotIndex = 1
    Call LoadSnapshotData(CurrentSnapshotIndex)
    MsgBox "Timeline reset to beginning.", vbInformation
End Sub

Sub GoToEnd()
    CurrentSnapshotIndex = TotalSnapshots
    Call LoadSnapshotData(CurrentSnapshotIndex)
    MsgBox "Timeline moved to latest snapshot.", vbInformation
End Sub

Sub ResetTimeline()
    Call GoToStart()
    IsTimelinePlaying = False
End Sub

' Play/Pause functionality (framework)
Sub TogglePlayPause()
    IsTimelinePlaying = Not IsTimelinePlaying
    
    If IsTimelinePlaying Then
        Call StartAutoPlay
        MsgBox "Timeline playing! Auto-advancing every 2 seconds...", vbInformation
    Else
        Call StopAutoPlay
        MsgBox "Timeline paused.", vbInformation
    End If
End Sub

' Auto-play functionality
Sub StartAutoPlay()
    If IsTimelinePlaying And CurrentSnapshotIndex < TotalSnapshots Then
        Application.OnTime Now + TimeValue("00:00:02"), "AutoAdvanceTimeline"
    End If
End Sub

Sub StopAutoPlay()
    ' Cancel any scheduled auto-advance
    On Error Resume Next
    Application.OnTime Now + TimeValue("00:00:02"), "AutoAdvanceTimeline", , False
    On Error GoTo 0
End Sub

Sub AutoAdvanceTimeline()
    If IsTimelinePlaying Then
        If CurrentSnapshotIndex < TotalSnapshots Then
            Call StepForward
            Call StartAutoPlay  ' Schedule next advance
        Else
            IsTimelinePlaying = False
            MsgBox "Timeline completed! Reached final snapshot.", vbInformation
        End If
    End If
End Sub

' Data import framework
Sub ImportTimelineData()
    Dim filePath As String
    filePath = Application.GetOpenFilename("CSV Files (*.csv),*.csv", , "Select Timeline Data File")
    
    If filePath <> "False" Then
        ' Framework for CSV import - Phase 3 implementation
        MsgBox "Data import framework ready!" & vbNewLine & _
               "Selected file: " & filePath & vbNewLine & _
               "Phase 3 will implement CSV import functionality.", vbInformation, "Import Ready"
    End If
End Sub

' Quick jump to specific snapshot
Sub GoToSnapshot()
    Dim inputSnapshot As String
    Dim targetSnapshot As Integer
    
    inputSnapshot = InputBox("Enter snapshot number (1-" & TotalSnapshots & "):", "Go To Snapshot", CurrentSnapshotIndex)
    
    If inputSnapshot <> "" Then
        targetSnapshot = CInt(inputSnapshot)
        If targetSnapshot >= 1 And targetSnapshot <= TotalSnapshots Then
            CurrentSnapshotIndex = targetSnapshot
            Call LoadSnapshotData(CurrentSnapshotIndex)
        Else
            MsgBox "Invalid snapshot number! Please enter a number between 1 and " & TotalSnapshots, vbExclamation
        End If
    End If
End Sub
'@
        
        $timelineModule | Out-File -FilePath (Join-Path $vbaDir "TimelineController.bas") -Encoding utf8
        
        # === VBA MODULE: ButtonHandlers ===
        $buttonModule = @'
' Button Event Handlers and User Interface
Option Explicit

' Initialize buttons and controls
Sub SetupDashboardControls()
    ' Set up keyboard shortcuts
    Application.OnKey "^+s", "TimelineController.StepForward"
    Application.OnKey "^+a", "TimelineController.StepBackward"  
    Application.OnKey "^+r", "TimelineController.ResetTimeline"
    Application.OnKey "^+i", "TimelineController.InitializeTimeline"
    Application.OnKey "^+p", "TimelineController.TogglePlayPause"
    Application.OnKey "^+g", "TimelineController.GoToSnapshot"
    Application.OnKey "^+l", "TimelineController.ImportTimelineData"
    
    MsgBox "Dashboard controls setup complete!" & vbNewLine & vbNewLine & _
           "Keyboard Shortcuts:" & vbNewLine & _
           "Ctrl+Shift+I = Initialize Timeline" & vbNewLine & _
           "Ctrl+Shift+S = Step Forward" & vbNewLine & _
           "Ctrl+Shift+A = Step Backward" & vbNewLine & _
           "Ctrl+Shift+R = Reset Timeline" & vbNewLine & _
           "Ctrl+Shift+P = Play/Pause" & vbNewLine & _
           "Ctrl+Shift+G = Go to Snapshot" & vbNewLine & _
           "Ctrl+Shift+L = Load Data", vbInformation, "Controls Ready"
End Sub

' Button click handlers (for when we add actual buttons)
Sub OnClick_StepForward()
    Call TimelineController.StepForward
End Sub

Sub OnClick_StepBackward()
    Call TimelineController.StepBackward
End Sub

Sub OnClick_PlayPause()
    Call TimelineController.TogglePlayPause
End Sub

Sub OnClick_Reset()
    Call TimelineController.ResetTimeline
End Sub

Sub OnClick_GoToStart()
    Call TimelineController.GoToStart
End Sub

Sub OnClick_GoToEnd()
    Call TimelineController.GoToEnd
End Sub

Sub OnClick_ImportData()
    Call TimelineController.ImportTimelineData
End Sub

Sub OnClick_GoToSnapshot()
    Call TimelineController.GoToSnapshot
End Sub

' Employee filter functionality
Sub OnChange_EmployeeFilter()
    Dim selectedEmployee As String
    selectedEmployee = Range("EmployeeFilter").Value
    
    ' Framework for employee filtering - Phase 3 implementation
    MsgBox "Employee filter changed to: " & selectedEmployee & vbNewLine & _
           "Filtering functionality will be implemented in Phase 3", vbInformation
End Sub
'@
        
        $buttonModule | Out-File -FilePath (Join-Path $vbaDir "ButtonHandlers.bas") -Encoding utf8
        
        # === VBA MODULE: ThisWorkbook ===
        $workbookModule = @'
' ThisWorkbook Module - Auto-initialization
Private Sub Workbook_Open()
    ' Auto-setup when workbook opens
    Call ButtonHandlers.SetupDashboardControls
    
    ' Initialize timeline
    Call TimelineController.InitializeTimeline
    
    ' Welcome message
    MsgBox "🎉 Welcome to Task Timeline Dashboard!" & vbNewLine & vbNewLine & _
           "📊 Phase 2 Framework Features:" & vbNewLine & _
           "• Timeline navigation structure" & vbNewLine & _
           "• VBA control framework" & vbNewLine & _
           "• Data import framework" & vbNewLine & _
           "• Keyboard shortcuts" & vbNewLine & vbNewLine & _
           "🚀 Ready for Phase 3 data implementation!" & vbNewLine & vbNewLine & _
           "Press Ctrl+Shift+I to reinitialize anytime", vbInformation, "Timeline Dashboard Ready"
End Sub

Private Sub Workbook_BeforeClose(Cancel As Boolean)
    ' Clean up keyboard shortcuts
    Application.OnKey "^+s"
    Application.OnKey "^+a"
    Application.OnKey "^+r"
    Application.OnKey "^+i"
    Application.OnKey "^+p"
    Application.OnKey "^+g"
    Application.OnKey "^+l"
End Sub
'@
        
        $workbookModule | Out-File -FilePath (Join-Path $vbaDir "ThisWorkbook.cls") -Encoding utf8
        
        # === CREATE DASHBOARD TEMPLATE CSV ===
        Write-Host "📊 Creating Dashboard template..." -ForegroundColor Green
        
        $dashboardTemplate = @'
"📊 Task Progress Timeline Dashboard",,,,,,,,,,,
"",,,,,,,,,,,
"🎮 Timeline Controls",,,,,,,,,,,
"",,,,,,,,,,,
"⏮️ Start Over","⏸️ Play/Pause","⏭️ Step Forward","🔄 Reset","📊 Go To Snapshot","📁 Load Data",,,,,,
"",,,,,,,,,,,
"📅 Timeline:","Snapshot 1 of 16",,,,,,,,,,
"",,,,,,,,,,,
"👥 Employee Filter:","All Employees",,,,,,,,,,
"",,,,,,,,,,,
"📋 Current Tasks",,,,,,,,,,,
"Employee","Task","Progress %","Last Updated",,,,,,,,
"John Smith","Database Migration","5%","2024-09-18 09:00:00",,,,,,,,
"Sarah Johnson","Frontend Redesign","6%","2024-09-18 09:00:00",,,,,,,,
"Michael Chen","API Integration","4%","2024-09-18 09:00:00",,,,,,,,
"Emily Davis","Testing Framework","7%","2024-09-18 09:00:00",,,,,,,,
"","","","",,,,,,,,
"","","","",,,,,,,,
"📈 Progress Overview",,,,,,,,,,,
"",,,,,,,,,,,
"Average Progress:","5.5%",,,,,,,,,,
"Tasks on Track:","4",,,,,,,,,,
"Behind Schedule:","0",,,,,,,,,,
"Completed:","0",,,,,,,,,,
'@
        
        $dashboardTemplate | Out-File -FilePath (Join-Path $templateDir "Dashboard_Template.csv") -Encoding utf8
        
        # === CREATE DATA TEMPLATE CSV ===
        $dataTemplate = @'
"📊 Data Import Area",,,,,
"",,,,,
"Instructions:",,,,,
"1. Import combined_timeline_data.csv to range A6:E1000",,,,,
"2. Or use VBA 'Load Data' button to auto-import",,,,,
"Employee","Task","Progress","Timestamp","Snapshot"
"","","","",""
'@
        
        $dataTemplate | Out-File -FilePath (Join-Path $templateDir "Data_Template.csv") -Encoding utf8
        
        # === CREATE CONFIG TEMPLATE CSV ===
        $configTemplate = @'
"⚙️ Configuration Settings",
"",
"Parameter","Value"
"DataFilePath","./ExcelExport/Data/combined_timeline_data.csv"
"AutoRefreshInterval","5000"
"MaxSnapshots","16"
"CurrentSnapshot","1"
"IsPlaying","FALSE"
"SelectedEmployee","All"
'@
        
        $configTemplate | Out-File -FilePath (Join-Path $templateDir "Config_Template.csv") -Encoding utf8
        
        # === CREATE SETUP INSTRUCTIONS ===
        Write-Host "📝 Creating setup instructions..." -ForegroundColor Green
        
        $instructions = @'
# 📊 Excel Task Timeline Dashboard - Phase 2 Setup

## 🚀 Quick Setup Instructions

### Option 1: Manual Setup (Recommended)
1. **Create New Excel Workbook**
   - Open Excel
   - Create new workbook
   - Save as "TaskTimelineDashboard.xlsm" (macro-enabled format)

2. **Set Up Worksheets**
   - Rename Sheet1 to "Dashboard" 
   - Add new sheet named "Data"
   - Add new sheet named "Config"

3. **Import Templates**
   - **Dashboard Sheet**: Import `Dashboard_Template.csv`
   - **Data Sheet**: Import `Data_Template.csv` 
   - **Config Sheet**: Import `Config_Template.csv`

4. **Add VBA Modules**
   - Press Alt+F11 to open VBA editor
   - Import the VBA modules:
     - `TimelineController.bas` → Insert as Standard Module
     - `ButtonHandlers.bas` → Insert as Standard Module  
     - `ThisWorkbook.cls` → Copy code into existing ThisWorkbook module

5. **Save and Test**
   - Save workbook (Ctrl+S)
   - Close and reopen to trigger auto-initialization
   - Test keyboard shortcuts (Ctrl+Shift+I to initialize)

### Option 2: Import Existing Data
1. Complete Option 1 setup first
2. In Data sheet, import your `combined_timeline_data.csv` starting at cell A6
3. Press Ctrl+Shift+I to initialize with your data

## 🎮 Keyboard Controls (Phase 2 Framework)
- **Ctrl+Shift+I** = Initialize Timeline
- **Ctrl+Shift+S** = Step Forward  
- **Ctrl+Shift+A** = Step Backward
- **Ctrl+Shift+R** = Reset Timeline
- **Ctrl+Shift+P** = Play/Pause (auto-advance)
- **Ctrl+Shift+G** = Go to Specific Snapshot
- **Ctrl+Shift+L** = Load Data File

## 📋 Phase 2 Features Included
✅ **VBA Framework Complete**
- Timeline navigation system
- Data loading framework  
- Auto-play functionality
- Keyboard shortcuts
- Employee filtering framework

✅ **Dashboard Structure**  
- Timeline controls layout
- Current tasks display
- Progress overview section
- Configuration management

✅ **Ready for Phase 3**
- CSV data import framework
- Real-time data binding preparation
- Chart integration framework
- Advanced filtering preparation

## 🔧 Troubleshooting
- **Macros disabled?** → Enable macros in Excel settings
- **VBA errors?** → Check module imports were successful  
- **No keyboard response?** → Press Ctrl+Shift+I to reinitialize
- **Data not loading?** → Verify CSV files are in correct location

## 🚀 Next Steps: Phase 3
Phase 3 will implement:
- Actual CSV data loading
- Real-time timeline data binding
- Advanced employee filtering
- Progress charts and visualization
- Data refresh functionality

---
**Phase 2 Complete! 🎉 Ready for Excel VBA development.**
'@
        
        $instructions | Out-File -FilePath (Join-Path $templateDir "SETUP_INSTRUCTIONS.md") -Encoding utf8
        
        # === CREATE PHASE 3 ROADMAP ===
        $roadmap = @'
# 🗺️ Phase 3 Roadmap - VBA Implementation

## 🎯 Phase 3 Goals
Transform the Phase 2 framework into a fully functional Excel timeline dashboard.

### 🔧 Core Implementation Tasks

#### 1. Data Loading Engine
- **CSV Import Function**: Read `combined_timeline_data.csv` into Excel
- **Data Parsing**: Handle timestamps, employee names, task progress
- **Data Validation**: Check data integrity and format  
- **Named Ranges**: Dynamic range management for data sets

#### 2. Timeline Data Binding  
- **Snapshot Filtering**: Filter data by timestamp/snapshot
- **Dynamic Updates**: Update dashboard when snapshot changes
- **Data Caching**: Store all snapshots for quick access
- **Progress Calculation**: Real-time progress percentage updates

#### 3. Employee Filtering System
- **Dropdown Creation**: Dynamic employee list from data
- **Filter Logic**: Show/hide tasks based on employee selection  
- **Multi-Select**: Allow multiple employee selection
- **Filter Reset**: Clear all filters functionality

#### 4. Visual Enhancements
- **Progress Bars**: Visual progress indicators
- **Color Coding**: Status-based cell coloring
- **Charts Integration**: Progress trends over time
- **Conditional Formatting**: Highlight overdue/completed tasks

#### 5. Advanced Features
- **Auto-Refresh**: Periodic data file checking
- **Export Functions**: Export filtered data to new files
- **Print Layouts**: Formatted reports for printing  
- **Settings Panel**: User preference management

## 🔄 Implementation Priority
1. **High Priority**: CSV import, timeline navigation, basic filtering
2. **Medium Priority**: Charts, visual enhancements, auto-refresh
3. **Low Priority**: Export functions, print layouts, advanced settings

## ⏱️ Estimated Timeline
- **Data Engine**: 2-3 days
- **Timeline Binding**: 1-2 days  
- **Employee Filtering**: 1 day
- **Visual Features**: 2-3 days
- **Testing & Polish**: 1-2 days

**Total Estimate**: 7-11 days for complete Phase 3

## 🧪 Testing Strategy
- **Unit Testing**: Each VBA function individually
- **Integration Testing**: Full workflow testing
- **Data Testing**: Various CSV formats and sizes
- **User Testing**: Keyboard shortcuts and UI interaction

---
**Ready to begin Phase 3 development!** 🚀
'@
        
        $roadmap | Out-File -FilePath (Join-Path $templateDir "PHASE_3_ROADMAP.md") -Encoding utf8
        
        # === SUMMARY AND COMPLETION ===
        Write-Host ""
        Write-Host "🎉 Excel Template Framework Created Successfully!" -ForegroundColor Green
        Write-Host "=============================================================" -ForegroundColor Cyan
        Write-Host "📁 Template Location: $templateDir" -ForegroundColor White
        Write-Host ""
        Write-Host "📦 Phase 2 Package Contents:" -ForegroundColor Yellow
        Write-Host "   📊 Dashboard_Template.csv    - Main dashboard layout" -ForegroundColor Green
        Write-Host "   📑 Data_Template.csv         - Data import structure" -ForegroundColor Green  
        Write-Host "   ⚙️  Config_Template.csv       - Configuration settings" -ForegroundColor Green
        Write-Host "   🎮 TimelineController.bas    - Core timeline VBA module" -ForegroundColor Green
        Write-Host "   🎯 ButtonHandlers.bas        - UI interaction handlers" -ForegroundColor Green
        Write-Host "   📋 ThisWorkbook.cls          - Auto-initialization code" -ForegroundColor Green
        Write-Host "   📝 SETUP_INSTRUCTIONS.md     - Complete setup guide" -ForegroundColor Green
        Write-Host "   🗺️  PHASE_3_ROADMAP.md       - Phase 3 development plan" -ForegroundColor Green
        Write-Host ""
        Write-Host "🎮 Framework Features (Phase 2):" -ForegroundColor Magenta
        Write-Host "   ✅ Complete VBA timeline navigation system" -ForegroundColor Green
        Write-Host "   ✅ Keyboard shortcuts (Ctrl+Shift combinations)" -ForegroundColor Green
        Write-Host "   ✅ Auto-play functionality framework" -ForegroundColor Green
        Write-Host "   ✅ Employee filtering framework" -ForegroundColor Green
        Write-Host "   ✅ Data import framework" -ForegroundColor Green
        Write-Host "   ✅ Dashboard layout structure" -ForegroundColor Green
        Write-Host "   ✅ Configuration management system" -ForegroundColor Green
        Write-Host ""
        Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
        Write-Host "   1. Open SETUP_INSTRUCTIONS.md for detailed setup" -ForegroundColor White
        Write-Host "   2. Create Excel workbook and import templates" -ForegroundColor White
        Write-Host "   3. Add VBA modules to enable functionality" -ForegroundColor White
        Write-Host "   4. Test keyboard shortcuts and navigation" -ForegroundColor White
        Write-Host "   5. Ready for Phase 3 implementation!" -ForegroundColor White
        Write-Host ""
        Write-Host "📖 Documentation:" -ForegroundColor Yellow
        Write-Host "   📝 Setup guide available in template folder" -ForegroundColor Green
        Write-Host "   🗺️  Phase 3 roadmap with implementation plan" -ForegroundColor Green
        Write-Host "   🎯 All VBA code commented and ready to use" -ForegroundColor Green
        Write-Host "=============================================================" -ForegroundColor Cyan
        
        # Open folder if requested
        if ($OpenAfterCreation) {
            Write-Host "📂 Opening template folder..." -ForegroundColor Yellow
            if ($IsMacOS) {
                Start-Process "open" -ArgumentList $templateDir
            } elseif ($IsWindows) {
                Start-Process "explorer" -ArgumentList $templateDir  
            }
        }
        
        return $true
        
    } catch {
        Write-Host "❌ Error creating Excel template: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Export the function (only when used as module)
if ($MyInvocation.MyCommand.ModuleName) {
    Export-ModuleMember -Function New-ExcelTaskTemplate
}

# If run directly, create template
if ($MyInvocation.InvocationName -ne '.') {
    Write-Host "🚀 Starting Excel Template Creation - Phase 2..." -ForegroundColor Cyan
    Write-Host "   (Cross-Platform Compatible Version)" -ForegroundColor Yellow
    Write-Host ""
    
    $success = New-ExcelTaskTemplate -OpenAfterCreation
    
    if ($success) {
        Write-Host "✅ Phase 2 Complete! Excel template framework ready." -ForegroundColor Green
        Write-Host "📖 Check SETUP_INSTRUCTIONS.md for next steps." -ForegroundColor Cyan
    } else {
        Write-Host "❌ Phase 2 failed. Check error messages above." -ForegroundColor Red
        exit 1
    }
}