Attribute VB_Name = "TaskDashboardFromSheet"
' =====================================================
' TASK DASHBOARD FROM EXISTING SHEET - VBA MODULE
' =====================================================
' Purpose: Create dashboard from CSV data already imported to "TaskData" sheet
' Author: Generated for Task Planner Project
' Date: October 2025
' Assumes: CSV data already imported to sheet named "TaskData"
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
        MsgBox "❌ ERROR: 'TaskData' sheet not found!" & vbCrLf & vbCrLf & _
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
    
    MsgBox "✅ Task Projection Dashboard created successfully!" & vbCrLf & _
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
    ' Parse person availability data from sheet
    Dim personName As String
    Dim availability(7) As Integer
    Dim i As Integer
    
    personName = Trim(ws.Cells(rowNum, 1).Value)
    personName = Replace(personName, """", "") ' Remove quotes if present
    
    ' Get 8 weeks of availability (columns 2-9)
    For i = 0 To 7
        availability(i) = Val(ws.Cells(rowNum, i + 2).Value)
    Next i
    
    If personName <> "" Then
        People(personName) = availability
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
    ' Create 8-week timeline projection with visual bars
    ' =====================================================
    Dim ws As Worksheet
    Dim lastRow As Long
    Dim timelineStartCol As Integer
    Dim timelineStartDate As Date
    Dim i As Long, j As Integer
    Dim taskStart As Date, taskEnd As Date
    Dim weekDate As Date
    
    Set ws = Worksheets("Task Dashboard")
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).Row
    
    If lastRow < 7 Then Exit Sub ' No tasks to process
    
    ' Set up timeline headers (starting from column J)
    timelineStartCol = 10
    timelineStartDate = GetNextMonday(Date)
    
    ' Create column headers
    ws.Cells(6, 1).Value = "ID"
    ws.Cells(6, 2).Value = "Task Description"
    ws.Cells(6, 3).Value = "Priority"
    ws.Cells(6, 4).Value = "Size"
    ws.Cells(6, 5).Value = "Start Date"
    ws.Cells(6, 6).Value = "End Date"
    ws.Cells(6, 7).Value = "Duration"
    ws.Cells(6, 8).Value = "Assigned Team"
    ws.Cells(6, 9).Value = "Timeline (8 Weeks)"
    
    ' Create week headers
    For j = 0 To 7
        weekDate = timelineStartDate + (j * 7)
        ws.Cells(5, timelineStartCol + j).Value = "Week " & (j + 1)
        ws.Cells(6, timelineStartCol + j).Value = Format(weekDate, "mm/dd")
    Next j
    
    ' Create timeline bars for each task
    For i = 7 To lastRow
        If ws.Cells(i, 1).Value <> "" Then
            taskStart = ws.Cells(i, 5).Value
            taskEnd = ws.Cells(i, 6).Value
            Call CreateTimelineBar(ws, i, taskStart, taskEnd, timelineStartDate, timelineStartCol)
        End If
    Next i
End Sub

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
        MsgBox "❌ TaskData sheet not found!", vbCritical
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