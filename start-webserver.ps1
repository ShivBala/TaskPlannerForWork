# Simple PowerShell Web Server for HTML Task Tracker
# Run this script in PowerShell to serve the HTML files

param(
    [int]$Port = 8080,
    [string]$Directory = $PSScriptRoot
)

Write-Host "🌐 Starting simple web server..." -ForegroundColor Green
Write-Host "📁 Serving directory: $Directory" -ForegroundColor Yellow
Write-Host "🔗 Server will be available at: http://localhost:$Port" -ForegroundColor Cyan
Write-Host "📄 Direct link to scheduler: http://localhost:$Port/Project_Scheduler_Stand_Alone_Console.html" -ForegroundColor Cyan
Write-Host ""
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Red
Write-Host ""

# Create HTTP listener
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")
$listener.Start()

Write-Host "✅ Server started successfully!" -ForegroundColor Green
Write-Host ""

try {
    while ($listener.IsListening) {
        # Wait for a request
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # Get the requested file path
        $requestedPath = $request.Url.LocalPath
        if ($requestedPath -eq "/") {
            $requestedPath = "/Project_Scheduler_Stand_Alone_Console.html"
        }
        
        $filePath = Join-Path $Directory $requestedPath.TrimStart('/')
        
        Write-Host "📥 Request: $($request.HttpMethod) $requestedPath" -ForegroundColor Gray
        
        try {
            if (Test-Path $filePath -PathType Leaf) {
                # File exists, serve it
                $content = [System.IO.File]::ReadAllBytes($filePath)
                
                # Set content type based on file extension
                $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
                switch ($extension) {
                    ".html" { $response.ContentType = "text/html; charset=utf-8" }
                    ".css"  { $response.ContentType = "text/css" }
                    ".js"   { $response.ContentType = "application/javascript" }
                    ".json" { $response.ContentType = "application/json" }
                    ".png"  { $response.ContentType = "image/png" }
                    ".jpg"  { $response.ContentType = "image/jpeg" }
                    ".ico"  { $response.ContentType = "image/x-icon" }
                    default { $response.ContentType = "application/octet-stream" }
                }
                
                $response.StatusCode = 200
                $response.OutputStream.Write($content, 0, $content.Length)
                Write-Host "✅ Served: $filePath" -ForegroundColor Green
            }
            else {
                # File not found
                $response.StatusCode = 404
                $errorHtml = @"
<!DOCTYPE html>
<html><head><title>404 - Not Found</title></head>
<body style='font-family: Arial; text-align: center; margin-top: 50px;'>
<h1>404 - File Not Found</h1>
<p>The requested file <code>$requestedPath</code> was not found.</p>
<p><a href='/Project_Scheduler_Stand_Alone_Console.html'>Go to Task Scheduler</a></p>
</body></html>
"@
                $errorBytes = [System.Text.Encoding]::UTF8.GetBytes($errorHtml)
                $response.ContentType = "text/html; charset=utf-8"
                $response.OutputStream.Write($errorBytes, 0, $errorBytes.Length)
                Write-Host "❌ File not found: $filePath" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "❌ Error serving file: $($_.Exception.Message)" -ForegroundColor Red
            $response.StatusCode = 500
        }
        finally {
            $response.Close()
        }
    }
}
catch {
    Write-Host "❌ Server error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    $listener.Stop()
    Write-Host "🛑 Server stopped." -ForegroundColor Yellow
}