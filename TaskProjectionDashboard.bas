Attribute VB_Name = "TaskProjectionDashboard"
' =====================================================
' ENTERPRISE TASK PROJECTION DASHBOARD - VBA MODULE
' =====================================================
' Purpose: Import CSV data and create professional timeline projections
' Author: Generated for Task Planner Project
' Date: October 2025
' =====================================================

Option Explicit

' Global variables for configuration
Dim TaskSizes As Object
Dim People As Object
Dim HoursPerDay As Integer

Sub InitializeTaskProjectionDashboard()
    ' =====================================================
    ' MAIN ENTRY POINT - Run this macro to start
    ' =====================================================
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    
    ' Initialize collections
    Set TaskSizes = CreateObject("Scripting.Dictionary")
    Set People = CreateObject("Scripting.Dictionary")
    HoursPerDay = 8 ' Default value
    
    ' Create or clear the dashboard sheet
    Call CreateDashboardSheet
    
    ' Import and process data
    Call ImportCSVData
    
    ' Create the timeline projection
    Call CreateTimelineProjection
    
    ' Format for professional presentation
    Call ApplyProfessionalFormatting
    
    Application.ScreenUpdating = True
    Application.DisplayAlerts = True
    
    MsgBox "✅ Task Projection Dashboard created successfully!" & vbCrLf & _
           "Sheet: 'Task Dashboard'" & vbCrLf & _
           "Ready for presentation!", vbInformation, "Dashboard Complete"
End Sub

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
        .Range("A4").Value = "Task Projections & Timeline Analysis"
    End With
End Sub

Sub ImportCSVData()
    ' =====================================================
    ' Import and parse CSV data from Task Planner export
    ' =====================================================
    Dim filePath As String
    Dim fileContent As String
    Dim lines As Variant
    Dim i As Long
    Dim currentSection As String
    
    ' Prompt user to select CSV file
    filePath = Application.GetOpenFilename("CSV Files (*.csv), *.csv", , "Select Task Planner Export File")
    
    If filePath = "False" Then
        MsgBox "❌ No file selected. Operation cancelled.", vbExclamation
        Exit Sub
    End If
    
    ' Read file content
    Open filePath For Input As #1
    fileContent = Input$(LOF(1), 1)
    Close #1
    
    ' Split into lines
    lines = Split(fileContent, vbCrLf)
    
    ' Parse sections
    For i = 0 To UBound(lines)
        If Left(lines(i), 8) = "SECTION," Then
            currentSection = Mid(lines(i), 9)
        ElseIf currentSection = "SETTINGS" And InStr(lines(i), "Hours Per Day") > 0 Then
            HoursPerDay = Val(Split(lines(i), ",")(1))
        ElseIf currentSection = "TASK_SIZES" And i > 0 And lines(i) <> "" And Left(lines(i), 4) <> "Size" Then
            Call ParseTaskSize(lines(i))
        ElseIf currentSection = "PEOPLE" And i > 0 And lines(i) <> "" And Left(lines(i), 4) <> "Name" Then
            Call ParsePerson(lines(i))
        ElseIf currentSection = "TICKETS" And i > 0 And lines(i) <> "" And Left(lines(i), 2) <> "ID" Then
            Call ParseTicket(lines(i), i - GetSectionStartRow("TICKETS", lines))
        End If
    Next i
End Sub

Function GetSectionStartRow(sectionName As String, lines As Variant) As Long
    ' Helper function to find section start
    Dim i As Long
    For i = 0 To UBound(lines)
        If lines(i) = "SECTION," & sectionName Then
            GetSectionStartRow = i + 2 ' Skip section header and column headers
            Exit Function
        End If
    Next i
    GetSectionStartRow = 0
End Function

Sub ParseTaskSize(line As String)
    ' Parse task size definitions
    Dim parts As Variant
    parts = Split(line, ",")
    If UBound(parts) >= 2 Then
        TaskSizes(parts(0)) = Val(parts(2)) ' Store days for each size
    End If
End Sub

Sub ParsePerson(line As String)
    ' Parse person availability data
    Dim parts As Variant
    Dim personName As String
    Dim availability As Variant
    Dim i As Integer
    
    parts = Split(line, ",")
    If UBound(parts) >= 8 Then
        personName = Replace(parts(0), """", "")
        ReDim availability(7)
        For i = 1 To 8
            availability(i - 1) = Val(parts(i))
        Next i
        People(personName) = availability
    End If
End Sub

Sub ParseTicket(line As String, rowNum As Long)
    ' Parse ticket data and write to dashboard
    Dim ws As Worksheet
    Dim parts As Variant
    Dim ticketId As String, description As String, startDate As Date
    Dim size As String, priority As String, assignedTeam As String
    Dim taskDays As Integer, endDate As Date
    Dim timelineRow As Long
    
    Set ws = Worksheets("Task Dashboard")
    parts = SplitCSVLine(line)
    
    If UBound(parts) >= 5 Then
        ticketId = parts(0)
        description = Replace(parts(1), """", "")
        startDate = CDate(parts(2))
        size = parts(3)
        priority = parts(4)
        assignedTeam = Replace(parts(5), """", "")
        
        ' Calculate task duration
        If TaskSizes.Exists(size) Then
            taskDays = TaskSizes(size)
        Else
            taskDays = 5 ' Default
        End If
        
        ' Calculate end date (business days)
        endDate = AddBusinessDays(startDate, taskDays - 1)
        
        ' Write to dashboard (starting from row 7)
        timelineRow = 7 + rowNum
        With ws
            .Cells(timelineRow, 1).Value = ticketId
            .Cells(timelineRow, 2).Value = description
            .Cells(timelineRow, 3).Value = priority
            .Cells(timelineRow, 4).Value = size & " (" & taskDays & " days)"
            .Cells(timelineRow, 5).Value = startDate
            .Cells(timelineRow, 6).Value = endDate
            .Cells(timelineRow, 7).Value = endDate - startDate + 1 & " calendar days"
            .Cells(timelineRow, 8).Value = Replace(assignedTeam, ";", ", ")
        End With
    End If
End Sub

Function SplitCSVLine(line As String) As Variant
    ' Advanced CSV parsing to handle quoted strings with commas
    Dim result() As String
    Dim i As Long, j As Long
    Dim inQuotes As Boolean
    Dim currentField As String
    Dim char As String
    
    ReDim result(0)
    inQuotes = False
    currentField = ""
    
    For i = 1 To Len(line)
        char = Mid(line, i, 1)
        
        If char = """" Then
            inQuotes = Not inQuotes
        ElseIf char = "," And Not inQuotes Then
            ReDim Preserve result(UBound(result) + 1)
            result(UBound(result) - 1) = currentField
            currentField = ""
        Else
            currentField = currentField & char
        End If
    Next i
    
    ' Add the last field
    ReDim Preserve result(UBound(result) + 1)
    result(UBound(result) - 1) = currentField
    
    SplitCSVLine = result
End Function

Function AddBusinessDays(startDate As Date, businessDays As Integer) As Date
    ' Add business days to a date (excluding weekends)
    Dim currentDate As Date
    Dim daysAdded As Integer
    
    currentDate = startDate
    daysAdded = 0
    
    While daysAdded < businessDays
        currentDate = currentDate + 1
        If Weekday(currentDate) <> 1 And Weekday(currentDate) <> 7 Then ' Not Sunday or Saturday
            daysAdded = daysAdded + 1
        End If
    Wend
    
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
    
    priority = ws.Cells(rowNum, 3).Value
    
    ' Choose character based on priority
    Select Case priority
        Case "P1": overlapChar = "█"
        Case "P2": overlapChar = "▓"
        Case "P3": overlapChar = "▒"
        Case "P4": overlapChar = "░"
        Case "P5": overlapChar = "·"
        Case Else: overlapChar = "▒"
    End Select
    
    For j = 0 To 7
        weekStart = timelineStart + (j * 7)
        weekEnd = weekStart + 6
        
        ' Check if task overlaps with this week
        hasOverlap = Not (taskEnd < weekStart Or taskStart > weekEnd)
        
        If hasOverlap Then
            ws.Cells(rowNum, startCol + j).Value = overlapChar
            ' Color coding based on priority
            Select Case priority
                Case "P1": ws.Cells(rowNum, startCol + j).Interior.Color = RGB(255, 102, 102) ' Red
                Case "P2": ws.Cells(rowNum, startCol + j).Interior.Color = RGB(255, 178, 102) ' Orange
                Case "P3": ws.Cells(rowNum, startCol + j).Interior.Color = RGB(255, 255, 102) ' Yellow
                Case "P4": ws.Cells(rowNum, startCol + j).Interior.Color = RGB(178, 255, 102) ' Light Green
                Case "P5": ws.Cells(rowNum, startCol + j).Interior.Color = RGB(102, 255, 102) ' Green
            End Select
        End If
    Next j
End Sub

Function GetNextMonday(inputDate As Date) As Date
    ' Get the next Monday from the input date
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
        
        ' Subtitle formatting
        .Range("A2").Font.Size = 10
        .Range("A2").Font.Italic = True
        .Range("A2").Font.Color = RGB(102, 102, 102)
        
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
            Set dataRange = .Range(.Cells(7, 1), .Cells(lastRow, lastCol))
            With dataRange
                .HorizontalAlignment = xlLeft
                .VerticalAlignment = xlCenter
                .WrapText = False
            End With
            
            ' Alternate row colors
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

Sub ClearDashboard()
    ' Quick function to clear and reset dashboard
    On Error Resume Next
    Application.DisplayAlerts = False
    Worksheets("Task Dashboard").Delete
    Application.DisplayAlerts = True
    On Error GoTo 0
    MsgBox "Dashboard cleared. Run InitializeTaskProjectionDashboard() to recreate.", vbInformation
End Sub

Sub RefreshDashboard()
    ' Refresh dashboard with latest data
    Call InitializeTaskProjectionDashboard
End Sub