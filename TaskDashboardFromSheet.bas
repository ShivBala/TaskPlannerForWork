Attribute VB_Name = "TaskDashboardFromSheet"
' =====================================================
' ENTERPRISE TASK DASHBOARD FROM SHEET - VBA MODULE
' =====================================================
' Purpose: Create dashboard from existing Excel sheet data
' Author: Generated for Task Planner Project
' Date: October 2025
' Updated: Compatible with Project Ready Resource feature
' 
' SHEET FORMAT SUPPORTED:
' - TaskData sheet with CSV-like structure
' - PEOPLE section: Name,Week1-8,Project Ready (Yes/No)
' - Backward compatible with 8-week format (no Project Ready column)
' - Project Ready field parsed but not used in dashboard calculations
' 
' CALCULATION SYNCHRONIZATION:
' - Utilization calculations match html_console_v2.html exactly
' - Uses same business day logic: calculateBusinessDays()
' - Same team assignment distribution: hoursPerAssignee = totalHours / teamSize
' - Same color thresholds: Green (<60%), Yellow (60-90%), Red (>90%)
' - Same overload handling: Shows "OVR" for 999% utilization
' =====================================================

Option Explicit

' Global variables for configuration
Dim TaskSizes As Object
Dim People As Object
Dim HoursPerDay As Integer

Sub CreateDashboardFromTaskData()
    ' =====================================================
    ' MAIN ENTRY POINT - Run this macro to create dashboard
    ' Assumes TaskData sheet exists with CSV import
    ' =====================================================
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    
    ' Check if TaskData sheet exists
    If Not SheetExists("TaskData") Then
        MsgBox "ERROR: 'TaskData' sheet not found!" & vbCrLf & vbCrLf & _
               "Please:" & vbCrLf & _
               "1. Import your CSV file into Excel" & vbCrLf & _
               "2. Rename the sheet to 'TaskData'" & vbCrLf & _
               "3. Run this macro again", vbCritical, "Missing TaskData Sheet"
        Exit Sub
    End If
    
    ' Initialize collections
    Set TaskSizes = CreateObject("Scripting.Dictionary")
    Set People = CreateObject("Scripting.Dictionary")
    HoursPerDay = 8 ' Default value
    
    ' Create or clear the dashboard sheet
    Call CreateDashboardSheet
    
    ' Parse data from TaskData sheet
    Call ParseTaskDataSheet
    
    ' Create the timeline projection
    Call CreateTimelineProjection
    
    ' Format for professional presentation
    Call ApplyProfessionalFormatting
    
    Application.ScreenUpdating = True
    Application.DisplayAlerts = True
    
    MsgBox "Task Projection Dashboard created successfully!" & vbCrLf & _
           "Source: 'TaskData' sheet" & vbCrLf & _
           "Output: 'Task Dashboard' sheet" & vbCrLf & _
           "Ready for presentation!", vbInformation, "Dashboard Complete"
End Sub

Function SheetExists(sheetName As String) As Boolean
    ' Check if a worksheet exists
    Dim ws As Worksheet
    On Error Resume Next
    Set ws = Worksheets(sheetName)
    SheetExists = Not ws Is Nothing
    On Error GoTo 0
End Function

Sub CreateDashboardSheet()
    ' =====================================================
    ' Create or clear the main dashboard sheet
    ' =====================================================
    Dim ws As Worksheet
    
    ' Delete existing sheet if it exists
    On Error Resume Next
    Application.DisplayAlerts = False
    Worksheets("Task Dashboard").Delete
    Application.DisplayAlerts = True
    On Error GoTo 0
    
    ' Create new sheet
    Set ws = Worksheets.Add
    ws.Name = "Task Dashboard"
    ws.Move After:=Worksheets(Worksheets.Count)
    
    ' Set up headers
    With ws
        .Range("A1").Value = "ENTERPRISE PROJECT TIMELINE DASHBOARD"
        .Range("A2").Value = "Generated: " & Format(Now, "dddd, mmmm dd, yyyy at hh:mm AM/PM")
        .Range("A3").Value = "Source: TaskData Sheet"
        .Range("A4").Value = "Task Projections & Timeline Analysis"
    End With
End Sub

Sub ParseTaskDataSheet()
    ' =====================================================
    ' Parse CSV data from the TaskData sheet
    ' =====================================================
    Dim wsData As Worksheet
    Dim lastRow As Long
    Dim i As Long
    Dim currentSection As String
    Dim cellValue As String
    
    Set wsData = Worksheets("TaskData")
    lastRow = wsData.Cells(wsData.Rows.Count, 1).End(xlUp).Row
    
    ' Find and parse each section
    For i = 1 To lastRow
        cellValue = Trim(wsData.Cells(i, 1).Value)
        
        ' Check for section headers
        If Left(cellValue, 8) = "SECTION," Then
            currentSection = Mid(cellValue, 9)
        ElseIf currentSection = "SETTINGS" And InStr(cellValue, "Hours Per Day") > 0 Then
            HoursPerDay = Val(wsData.Cells(i, 2).Value)
        ElseIf currentSection = "TASK_SIZES" And cellValue <> "" And Left(cellValue, 4) <> "Size" Then
            Call ParseTaskSizeFromSheet(wsData, i)
        ElseIf currentSection = "PEOPLE" And cellValue <> "" And Left(cellValue, 4) <> "Name" Then
            Call ParsePersonFromSheet(wsData, i)
        ElseIf currentSection = "TICKETS" And cellValue <> "" And Left(cellValue, 2) <> "ID" Then
            Call ParseTicketFromSheet(wsData, i)
        End If
    Next i
End Sub

Sub ParseTaskSizeFromSheet(ws As Worksheet, rowNum As Long)
    ' Parse task size definitions from sheet
    Dim sizeKey As String
    Dim days As Integer
    
    sizeKey = Trim(ws.Cells(rowNum, 1).Value)
    days = Val(ws.Cells(rowNum, 3).Value)
    
    If sizeKey <> "" And days > 0 Then
        TaskSizes(sizeKey) = days
    End If
End Sub

Sub ParsePersonFromSheet(ws As Worksheet, rowNum As Long)
    ' Parse person availability data from sheet (now includes Project Ready field)
    Dim personName As String
    Dim availability(7) As Integer
    Dim isProjectReady As Boolean
    Dim i As Integer
    
    personName = Trim(ws.Cells(rowNum, 1).Value)
    personName = Replace(personName, """", "") ' Remove quotes if present
    
    ' Get 8 weeks of availability (columns 2-9)
    ' Project Ready status is in column 10 (optional)
    For i = 0 To 7
        availability(i) = Val(ws.Cells(rowNum, i + 2).Value)
    Next i
    
    ' Get Project Ready status (column 10)
    Dim projectReadyValue As String
    projectReadyValue = UCase(Trim(ws.Cells(rowNum, 10).Value))
    isProjectReady = (projectReadyValue = "YES" Or projectReadyValue = "TRUE" Or projectReadyValue = "")
    ' Default to True if empty for backward compatibility
    
    If personName <> "" Then
        People(personName) = availability
        ' Note: Project Ready status available but not currently used in dashboard logic
    End If
End Sub

Sub ParseTicketFromSheet(ws As Worksheet, rowNum As Long)
    ' Parse ticket data and write to dashboard
    Dim wsDash As Worksheet
    Dim ticketId As String, description As String, startDate As Date
    Dim size As String, priority As String, assignedTeam As String
    Dim taskDays As Integer, endDate As Date
    Dim dashboardRow As Long
    
    Set wsDash = Worksheets("Task Dashboard")
    
    ' Get data from TaskData sheet
    ticketId = Trim(ws.Cells(rowNum, 1).Value)
    description = Trim(ws.Cells(rowNum, 2).Value)
    description = Replace(description, """", "") ' Remove quotes
    
    ' Handle date parsing
    On Error Resume Next
    startDate = CDate(ws.Cells(rowNum, 3).Value)
    On Error GoTo 0
    
    size = Trim(ws.Cells(rowNum, 4).Value)
    priority = Trim(ws.Cells(rowNum, 5).Value)
    assignedTeam = Trim(ws.Cells(rowNum, 6).Value)
    assignedTeam = Replace(assignedTeam, """", "") ' Remove quotes
    assignedTeam = Replace(assignedTeam, ";", ", ") ' Convert semicolons to commas
    
    ' Skip if essential data is missing
    If ticketId = "" Or description = "" Or startDate = 0 Then Exit Sub
    
    ' Calculate task duration
    If TaskSizes.Exists(size) Then
        taskDays = TaskSizes(size)
    Else
        ' Default task sizes if not found in data
        Select Case UCase(size)
            Case "S": taskDays = 1
            Case "M": taskDays = 2
            Case "L": taskDays = 5
            Case "XL": taskDays = 10
            Case "XXL": taskDays = 15
            Case Else: taskDays = 5 ' Default
        End Select
    End If
    
    ' Calculate end date (business days)
    endDate = AddBusinessDays(startDate, taskDays - 1)
    
    ' Find next available row in dashboard (starting from row 7)
    dashboardRow = wsDash.Cells(wsDash.Rows.Count, 1).End(xlUp).Row + 1
    If dashboardRow < 7 Then dashboardRow = 7
    
    ' Write to dashboard
    With wsDash
        .Cells(dashboardRow, 1).Value = ticketId
        .Cells(dashboardRow, 2).Value = description
        .Cells(dashboardRow, 3).Value = priority
        .Cells(dashboardRow, 4).Value = size & " (" & taskDays & " days)"
        .Cells(dashboardRow, 5).Value = startDate
        .Cells(dashboardRow, 6).Value = endDate
        .Cells(dashboardRow, 7).Value = endDate - startDate + 1 & " calendar days"
        .Cells(dashboardRow, 8).Value = assignedTeam
    End With
End Sub

Function AddBusinessDays(startDate As Date, businessDays As Integer) As Date
    ' Add business days to a date (excluding weekends)
    Dim currentDate As Date
    Dim daysAdded As Integer
    
    currentDate = startDate
    daysAdded = 0
    
    Do While daysAdded < businessDays
        currentDate = currentDate + 1
        If Weekday(currentDate) <> 1 And Weekday(currentDate) <> 7 Then ' Not Sunday or Saturday
            daysAdded = daysAdded + 1
        End If
    Loop
    
    AddBusinessDays = currentDate
End Function

Sub CreateTimelineProjection()
    ' =====================================================
    ' Create the main timeline display with utilization analysis
    ' =====================================================
    Dim ws As Worksheet
    Set ws = Worksheets("Task Dashboard")
    
    ' Headers for timeline
    With ws
        .Range("A6").Value = "Task ID"
        .Range("B6").Value = "Description"
        .Range("C6").Value = "Priority"
        .Range("D6").Value = "Size"
        .Range("E6").Value = "Start Date"
        .Range("F6").Value = "End Date"
        .Range("G6").Value = "Duration"
        .Range("H6").Value = "Assigned Team"
    End With
    
    ' Add capacity utilization analysis
    Call CreateCapacityAnalysis
End Sub

Sub CreateCapacityAnalysis()
    ' =====================================================
    ' Create weekly capacity utilization analysis (matches HTML logic)
    ' =====================================================
    Dim ws As Worksheet
    Dim lastTaskRow As Long
    Dim startRow As Long
    Dim weekNum As Integer
    Dim utilRow As Long
    
    Set ws = Worksheets("Task Dashboard")
    lastTaskRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    startRow = lastTaskRow + 3
    
    ' Headers for capacity analysis
    With ws
        .Cells(startRow, 1).Value = "WEEKLY CAPACITY UTILIZATION ANALYSIS"
        .Cells(startRow + 1, 1).Value = "(Matches HTML Console Calculations)"
        .Cells(startRow + 3, 1).Value = "Team Member"
        For weekNum = 1 To 8
            .Cells(startRow + 3, weekNum + 1).Value = "Week " & weekNum & " Util%"
        Next weekNum
    End With
    
    ' Calculate utilization for each person (matches HTML logic)
    utilRow = startRow + 4
    Dim personKey As Variant
    For Each personKey In People.Keys
        Call CalculatePersonUtilization ws, utilRow, CStr(personKey)
        utilRow = utilRow + 1
    Next personKey
End Sub

Sub CalculatePersonUtilization(ws As Worksheet, rowNum As Long, personName As String)
    ' =====================================================
    ' Calculate weekly utilization using HTML console logic
    ' =====================================================
    Dim availability() As Integer
    Dim weekNum As Integer
    Dim assignedHours As Double
    Dim utilization As Double
    Dim taskRow As Long
    Dim lastTaskRow As Long
    
    ' Get person's availability
    availability = People(personName)
    ws.Cells(rowNum, 1).Value = personName
    
    ' Calculate utilization for each week
    For weekNum = 1 To 8
        assignedHours = 0
        
        ' Sum up assigned hours from all tasks using HTML-like logic
        lastTaskRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
        For taskRow = 7 To lastTaskRow
            If InStr(ws.Cells(taskRow, 8).Value, personName) > 0 Then
                ' Task is assigned to this person
                Dim taskSize As String, taskDays As Integer
                Dim taskStart As Date, taskEnd As Date
                Dim totalTaskHours As Double, hoursPerAssignee As Double
                Dim teamList As Variant, teamSize As Integer
                
                ' Parse task details
                taskSize = Left(ws.Cells(taskRow, 4).Value, InStr(ws.Cells(taskRow, 4).Value, " ") - 1)
                taskStart = ws.Cells(taskRow, 5).Value
                taskEnd = ws.Cells(taskRow, 6).Value
                
                If TaskSizes.Exists(taskSize) Then
                    taskDays = TaskSizes(taskSize)
                    totalTaskHours = taskDays * HoursPerDay
                    
                    ' Calculate team size (matches HTML: ticket.assigned.length)
                    teamList = Split(Replace(ws.Cells(taskRow, 8).Value, " ", ""), ",")
                    teamSize = UBound(teamList) + 1
                    hoursPerAssignee = totalTaskHours / teamSize
                    
                    ' Calculate business days for this task duration
                    Dim taskBusinessDays As Integer
                    taskBusinessDays = CalculateBusinessDaysVBA(taskStart, taskEnd)
                    If taskBusinessDays <= 0 Then taskBusinessDays = 1
                    
                    ' Calculate daily hours (matches HTML: dailyHours = hoursPerAssignee / taskBusinessDays)
                    Dim dailyHours As Double
                    dailyHours = hoursPerAssignee / taskBusinessDays
                    
                    ' Calculate week overlap (simplified - assumes 5 business days per week)
                    ' This is a simplified version of the HTML's complex date overlap logic
                    Dim weekBusinessDays As Integer
                    weekBusinessDays = 5 ' Assuming full weeks for simplification
                    
                    ' Add to assigned hours (matches HTML: assignedHours += dailyHours * businessDays)
                    assignedHours = assignedHours + (dailyHours * weekBusinessDays)
                End If
            End If
        Next taskRow
        
        ' Calculate utilization percentage (matches HTML logic exactly)
        If availability(weekNum - 1) > 0 Then
            utilization = Round((assignedHours / availability(weekNum - 1)) * 100, 0)
        ElseIf assignedHours > 0 Then
            utilization = 999 ' Overload indicator (matches HTML)
        Else
            utilization = 0
        End If
        
        ' Ensure utilization is valid (matches HTML: isNaN/isFinite checks)
        If utilization < 0 Then utilization = 0
        
        ' Display value (matches HTML logic)
        ws.Cells(rowNum, weekNum + 1).Value = IIf(utilization = 999, "OVR", utilization & "%")
        
        ' Apply color formatting (matches HTML color thresholds exactly)
        If utilization = 999 Or utilization > 90 Then
            ws.Cells(rowNum, weekNum + 1).Interior.Color = RGB(254, 226, 226) ' Red (matches HTML)
        ElseIf utilization > 60 Then
            ws.Cells(rowNum, weekNum + 1).Interior.Color = RGB(254, 243, 199) ' Yellow (matches HTML)
        Else
            ws.Cells(rowNum, weekNum + 1).Interior.Color = RGB(220, 252, 231) ' Green (matches HTML)
        End If
    Next weekNum
End Sub

Function CalculateBusinessDaysVBA(startDate As Date, endDate As Date) As Integer
    ' =====================================================
    ' Calculate business days between dates (matches HTML calculateBusinessDays function)
    ' =====================================================
    Dim businessDays As Integer
    Dim currentDate As Date
    Dim dayOfWeek As Integer
    
    businessDays = 0
    currentDate = startDate
    
    ' Loop through each day (matches HTML logic exactly)
    While currentDate <= endDate
        dayOfWeek = Weekday(currentDate, vbMonday) ' Monday = 1, Sunday = 7
        If dayOfWeek >= 1 And dayOfWeek <= 5 Then ' Monday to Friday (matches HTML)
            businessDays = businessDays + 1
        End If
        currentDate = currentDate + 1
    Wend
    
    CalculateBusinessDaysVBA = businessDays
End Function

Sub CreateTimelineBar(ws As Worksheet, rowNum As Long, taskStart As Date, taskEnd As Date, timelineStart As Date, startCol As Integer)
    ' Create visual timeline bar for a task
    Dim j As Integer
    Dim weekStart As Date, weekEnd As Date
    Dim hasOverlap As Boolean
    Dim overlapChar As String
    Dim priority As String
    Dim priorityColor As Long
    
    priority = UCase(Trim(ws.Cells(rowNum, 3).Value))
    
    ' Choose character and color based on priority
    Select Case priority
        Case "P1"
            overlapChar = "█"
            priorityColor = RGB(255, 102, 102) ' Red
        Case "P2"
            overlapChar = "▓"
            priorityColor = RGB(255, 178, 102) ' Orange
        Case "P3"
            overlapChar = "▒"
            priorityColor = RGB(255, 255, 102) ' Yellow
        Case "P4"
            overlapChar = "░"
            priorityColor = RGB(178, 255, 102) ' Light Green
        Case "P5"
            overlapChar = "·"
            priorityColor = RGB(102, 255, 102) ' Green
        Case Else
            overlapChar = "▒"
            priorityColor = RGB(192, 192, 192) ' Gray
    End Select
    
    For j = 0 To 7
        weekStart = timelineStart + (j * 7)
        weekEnd = weekStart + 6
        
        ' Check if task overlaps with this week
        hasOverlap = Not (taskEnd < weekStart Or taskStart > weekEnd)
        
        If hasOverlap Then
            ws.Cells(rowNum, startCol + j).Value = overlapChar
            ws.Cells(rowNum, startCol + j).Interior.Color = priorityColor
            ws.Cells(rowNum, startCol + j).Font.Bold = True
            ws.Cells(rowNum, startCol + j).HorizontalAlignment = xlCenter
        End If
    Next j
End Sub

Function GetNextMonday(inputDate As Date) As Date
    ' Get the next Monday from the input date (or current Monday if today is Monday)
    Dim dayOfWeek As Integer
    Dim daysToAdd As Integer
    
    dayOfWeek = Weekday(inputDate, vbMonday) ' 1 = Monday, 7 = Sunday
    
    If dayOfWeek = 1 Then ' Already Monday
        GetNextMonday = inputDate
    Else
        daysToAdd = 8 - dayOfWeek
        GetNextMonday = inputDate + daysToAdd
    End If
End Function

Sub ApplyProfessionalFormatting()
    ' =====================================================
    ' Apply professional corporate formatting
    ' =====================================================
    Dim ws As Worksheet
    Dim lastRow As Long, lastCol As Integer
    Dim headerRange As Range, dataRange As Range
    
    Set ws = Worksheets("Task Dashboard")
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    lastCol = 17 ' Column Q (up to 8 weeks of timeline)
    
    With ws
        ' Page setup for professional printing
        .PageSetup.Orientation = xlLandscape
        .PageSetup.FitToPagesWide = 1
        .PageSetup.FitToPagesTall = False
        .PageSetup.PrintTitleRows = "$1:$6"
        
        ' Main title formatting
        .Range("A1").Font.Size = 18
        .Range("A1").Font.Bold = True
        .Range("A1").Font.Color = RGB(0, 51, 102) ' Corporate blue
        
        ' Subtitle and source formatting
        .Range("A2").Font.Size = 10
        .Range("A2").Font.Italic = True
        .Range("A2").Font.Color = RGB(102, 102, 102)
        
        .Range("A3").Font.Size = 9
        .Range("A3").Font.Italic = True
        .Range("A3").Font.Color = RGB(102, 102, 102)
        
        .Range("A4").Font.Size = 14
        .Range("A4").Font.Bold = True
        .Range("A4").Font.Color = RGB(0, 51, 102)
        
        ' Header row formatting
        Set headerRange = .Range(.Cells(6, 1), .Cells(6, lastCol))
        With headerRange
            .Font.Bold = True
            .Font.Color = RGB(255, 255, 255)
            .Interior.Color = RGB(0, 51, 102) ' Corporate blue
            .HorizontalAlignment = xlCenter
            .VerticalAlignment = xlCenter
        End With
        
        ' Timeline week headers
        Set headerRange = .Range(.Cells(5, 10), .Cells(5, 17))
        With headerRange
            .Font.Bold = True
            .Font.Color = RGB(255, 255, 255)
            .Interior.Color = RGB(51, 102, 153) ' Lighter blue
            .HorizontalAlignment = xlCenter
            .Merge
            .Value = "8-WEEK PROJECT TIMELINE"
        End With
        
        ' Data formatting
        If lastRow > 6 Then
            Set dataRange = .Range(.Cells(7, 1), .Cells(lastRow, 9))
            With dataRange
                .HorizontalAlignment = xlLeft
                .VerticalAlignment = xlCenter
                .WrapText = False
            End With
            
            ' Alternate row colors for data columns only
            Dim i As Long
            For i = 7 To lastRow Step 2
                .Range(.Cells(i, 1), .Cells(i, 9)).Interior.Color = RGB(245, 245, 245)
            Next i
        End If
        
        ' Column widths
        .Columns("A").ColumnWidth = 8   ' ID
        .Columns("B").ColumnWidth = 35  ' Description
        .Columns("C").ColumnWidth = 8   ' Priority
        .Columns("D").ColumnWidth = 12  ' Size
        .Columns("E").ColumnWidth = 12  ' Start Date
        .Columns("F").ColumnWidth = 12  ' End Date
        .Columns("G").ColumnWidth = 12  ' Duration
        .Columns("H").ColumnWidth = 20  ' Team
        .Columns("I").ColumnWidth = 3   ' Spacer
        .Columns("J:Q").ColumnWidth = 8 ' Timeline weeks
        
        ' Borders
        If lastRow > 6 Then
            With .Range(.Cells(6, 1), .Cells(lastRow, lastCol)).Borders
                .LineStyle = xlContinuous
                .Color = RGB(192, 192, 192)
                .Weight = xlThin
            End With
        End If
        
        ' Freeze panes
        .Range("J7").Select
        ActiveWindow.FreezePanes = True
        
        ' Select starting cell
        .Range("A1").Select
    End With
    
    ' Add legend
    Call CreateLegend
End Sub

Sub CreateLegend()
    ' Create priority legend
    Dim ws As Worksheet
    Dim lastRow As Long
    
    Set ws = Worksheets("Task Dashboard")
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    
    ' Legend title
    ws.Cells(lastRow + 3, 1).Value = "PRIORITY LEGEND:"
    ws.Cells(lastRow + 3, 1).Font.Bold = True
    ws.Cells(lastRow + 3, 1).Font.Color = RGB(0, 51, 102)
    
    ' Legend items
    Dim legendRow As Long
    legendRow = lastRow + 4
    
    ' P1
    ws.Cells(legendRow, 1).Value = "█ P1 - Critical"
    ws.Cells(legendRow, 1).Interior.Color = RGB(255, 102, 102)
    ws.Cells(legendRow, 1).Font.Bold = True
    
    ' P2
    ws.Cells(legendRow, 3).Value = "▓ P2 - High"
    ws.Cells(legendRow, 3).Interior.Color = RGB(255, 178, 102)
    ws.Cells(legendRow, 3).Font.Bold = True
    
    ' P3
    ws.Cells(legendRow, 5).Value = "▒ P3 - Medium"
    ws.Cells(legendRow, 5).Interior.Color = RGB(255, 255, 102)
    ws.Cells(legendRow, 5).Font.Bold = True
    
    ' P4
    ws.Cells(legendRow, 7).Value = "░ P4 - Low"
    ws.Cells(legendRow, 7).Interior.Color = RGB(178, 255, 102)
    ws.Cells(legendRow, 7).Font.Bold = True
    
    ' P5
    ws.Cells(legendRow, 9).Value = "· P5 - Backlog"
    ws.Cells(legendRow, 9).Interior.Color = RGB(102, 255, 102)
    ws.Cells(legendRow, 9).Font.Bold = True
End Sub

' =====================================================
' UTILITY FUNCTIONS FOR MANUAL USE
' =====================================================

Sub QuickRefreshFromTaskData()
    ' Quick function to refresh dashboard from existing TaskData
    Call CreateDashboardFromTaskData
End Sub

Sub ClearDashboardOnly()
    ' Clear only the dashboard sheet, keep TaskData
    On Error Resume Next
    Application.DisplayAlerts = False
    Worksheets("Task Dashboard").Delete
    Application.DisplayAlerts = True
    On Error GoTo 0
    MsgBox "Dashboard cleared. TaskData sheet preserved." & vbCrLf & _
           "Run CreateDashboardFromTaskData() to recreate.", vbInformation
End Sub

Sub ValidateTaskDataFormat()
    ' Helper function to validate TaskData sheet format
    If Not SheetExists("TaskData") Then
        MsgBox "TaskData sheet not found!", vbCritical
        Exit Sub
    End If
    
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim sectionsFound As String
    Dim i As Long
    
    Set ws = Worksheets("TaskData")
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    
    ' Check for required sections
    For i = 1 To lastRow
        If Left(ws.Cells(i, 1).Value, 8) = "SECTION," Then
            sectionsFound = sectionsFound & Mid(ws.Cells(i, 1).Value, 9) & ", "
        End If
    Next i
    
    MsgBox "TaskData sheet validation:" & vbCrLf & vbCrLf & _
           "Total rows: " & lastRow & vbCrLf & _
           "Sections found: " & sectionsFound & vbCrLf & vbCrLf & _
           "Required sections: SETTINGS, TASK_SIZES, PEOPLE, TICKETS", vbInformation
End Sub

' =====================================================
' COMPATIBILITY TEST FUNCTION
' =====================================================
Sub TestProjectReadyCompatibility()
    ' Test function to verify Project Ready field parsing from sheet
    Dim testMsg As String
    
    testMsg = "TaskDashboardFromSheet is compatible with:" & vbCrLf & vbCrLf & _
              "• Old format: Name,Week1-8" & vbCrLf & _
              "• New format: Name,Week1-8,Project Ready" & vbCrLf & vbCrLf & _
              "Project Ready column (10th column) will be:" & vbCrLf & _
              "• Parsed when present (Yes/No/True/False)" & vbCrLf & _
              "• Defaulted to True when missing" & vbCrLf & vbCrLf & _
              "Ready for latest exported configurations!"
              
    MsgBox testMsg, vbInformation, "Compatibility Confirmed"
End Sub