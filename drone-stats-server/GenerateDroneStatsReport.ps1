# GenerateReport.ps1
# Собирает все файлы проекта DroneStats и создаёт отчёт на рабочем столе

$projectPath = Get-Location
$reportPath = Join-Path $env:USERPROFILE "Desktop\DroneStatsReport.txt"

# Удаляем старый отчёт, если есть
if (Test-Path $reportPath) { Remove-Item $reportPath }

function Write-Report($line) {
    Add-Content -Path $reportPath -Value $line
}

Write-Report "============================================================"
Write-Report "OTCHET O PROEKTE Drone Logic Controller Stats Server"
Write-Report "============================================================"
Write-Report ""

Write-Report "Путь к проекту: $projectPath"
Write-Report "Дата: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Report ""

# 1. Структура папок (дерево)
Write-Report "=== STRUKTURA PROEKTA (TREE) ==="
Write-Report ""
$treeOutput = cmd /c "tree /F `"$projectPath`" 2>nul" 2>$null
if ($treeOutput) {
    Write-Report $treeOutput
} else {
    Write-Report "(Не удалось выполнить 'tree', вывожу список файлов вручную:)"
    Get-ChildItem -Path $projectPath -Recurse -File | ForEach-Object { $_.FullName.Replace($projectPath, ".") } | Sort-Object | Write-Report
}
Write-Report ""

# 2. Содержимое всех файлов (кроме бинарных)
Write-Report "=== SODERZHIMOE FAILOV ==="
Write-Report ""

$includeExtensions = @(".java", ".xml", ".properties", ".html", ".css", ".js", ".json", ".md", ".txt", ".gradle", ".kt")
$excludeDirs = @("target", ".idea", ".git", "node_modules", "out", "build")

Get-ChildItem -Path $projectPath -Recurse -File | Where-Object {
    $ext = $_.Extension.ToLower()
    $included = $includeExtensions -contains $ext
    $excluded = $false
    foreach ($dir in $excludeDirs) {
        if ($_.FullName -like "*\$dir\*") { $excluded = $true; break }
    }
    $included -and (-not $excluded)
} | ForEach-Object {
    $relPath = $_.FullName.Replace($projectPath, ".").Replace("\", "/")
    Write-Report ""
    Write-Report "------------------- $relPath -------------------"
    Write-Report ""
    try {
        $content = Get-Content -Path $_.FullName -Raw -ErrorAction Stop
        if ($content.Length -gt 0) {
            Write-Report $content
        } else {
            Write-Report "(Файл пуст)"
        }
    } catch {
        Write-Report "ОШИБКА ЧТЕНИЯ: $_"
    }
    Write-Report ""
}

# 3. Попытка скомпилировать Maven (если есть pom.xml)
$pomPath = Join-Path $projectPath "pom.xml"
if (Test-Path $pomPath) {
    Write-Report ""
    Write-Report "=== POPYTKA SBORKI MAVEN (mvn compile) ==="
    Write-Report ""
    $mvnOutput = & mvn compile 2>&1 | Out-String
    Write-Report $mvnOutput
    Write-Report ""
} else {
    Write-Report "=== FAIL POM.XML NE NAIDEN ==="
}

Write-Report "============================================================"
Write-Report "OTCHET ZAVERShEN. FAIL SOZDAN: $reportPath"

Write-Host "Готово! Отчёт сохранён: $reportPath" -ForegroundColor Green