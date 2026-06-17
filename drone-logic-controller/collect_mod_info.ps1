# collect_mod_info_fixed.ps1
$modPath = Get-Location
Write-Host "Collecting mod info from: $modPath"

# Header
$output = "=== Mod Information ===`n"
$output += "Path: $modPath`n"
$output += "Collection time: $(Get-Date)`n`n"

# List all .lua and .json files with sizes
$files = Get-ChildItem -Path $modPath -Recurse -Include *.lua, *.json | Sort-Object FullName
$output += "--- File list (size in bytes) ---`n"
foreach ($file in $files) {
    $output += "$($file.FullName) - $($file.Length) bytes`n"
}
$output += "`n"

# Content of each file
foreach ($file in $files) {
    $output += "--- $($file.FullName) ---`n"
    $content = Get-Content $file.FullName -Raw
    if ($content) {
        $output += $content + "`n`n"
    } else {
        $output += "(empty file)`n`n"
    }
}

# Try to find the log file
$logPaths = @(
    "D:\GOG Games\Factorio_2.0.55\factorio-current.log",
    "$env:APPDATA\Factorio\factorio-current.log"
)
$logContent = ""
foreach ($log in $logPaths) {
    if (Test-Path $log) {
        $logContent = Get-Content $log -Raw
        $output += "--- Error log: $log ---`n$logContent`n"
        break
    }
}

# Save to desktop
$desktop = [Environment]::GetFolderPath("Desktop")
$outFile = Join-Path $desktop "mod_info_$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$output | Out-File -FilePath $outFile -Encoding utf8
Write-Host "Info saved to: $outFile"