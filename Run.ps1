clear
Write-Host ">>> DANG KHOI CHAY VIETTOOLBOX TU GITHUB..." -ForegroundColor Cyan

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

$RepoZipUrl = "https://github.com/tuantran19912512/Windows-tool-box/archive/refs/heads/main.zip"
$ZipFile = "$env:TEMP\VietToolbox_Download.zip"
$ExtractPath = "$env:TEMP\VietToolbox_Temp"

if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue }
Invoke-WebRequest -Uri $RepoZipUrl -OutFile $ZipFile -UseBasicParsing
Expand-Archive -Path $ZipFile -DestinationPath $ExtractPath -Force

$MainScript = Get-ChildItem -Path "$ExtractPath\main.ps1" -Recurse | Select-Object -First 1

if ($MainScript) {
    Set-Location $MainScript.Directory.FullName
    $ToolProcess = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MainScript.FullName)`"" -PassThru
    
    Write-Host ">>> TOOL DANG CHAY. DUNG DONG CUA SO NAY DE TU DONG DON DEP..." -ForegroundColor Yellow
    $ToolProcess.WaitForExit()
    
    Set-Location $env:TEMP
    Remove-Item $ExtractPath -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $ZipFile -Force -ErrorAction SilentlyContinue
    Write-Host ">>> DA DON DEP SACH SE. TAM BIET!" -ForegroundColor Green
    Start-Sleep -Seconds 2
}