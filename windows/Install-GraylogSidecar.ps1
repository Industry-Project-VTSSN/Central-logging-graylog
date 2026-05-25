<#
.SYNOPSIS
    Environment-Aware Production Deployment Script for Graylog Sidecar.
#>

# --- STEP 0: PARSE EXTERNAL .ENV CONFIGURATION ---
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$EnvFile = Join-Path $ScriptPath ".env"

if (-not (Test-Path $EnvFile)) {
    Write-Error "CRITICAL: Missing configuration environment asset (.env) at $EnvFile"
    Exit
}

# Native PowerShell .env parser loop
Get-Content $EnvFile | Where-Object { $_ -match '=' -and $_ -notmatch '^#' } | ForEach-Object {
    $Key, $Value = $_ -split '=', 2
    Set-Variable -Name $Key.Trim() -Value $Value.Trim() -Force
}

# Map variables from the parsed .env environment context
$GraylogServerUrl = $GRAYLOG_SERVER_URL
$GraylogApiToken  = $GRAYLOG_API_TOKEN
$SidecarTag       = $GRAYLOG_TAGS

# DYNAMIC HOSTNAME: Automatically grabs the host server name natively (e.g., SQL-PROD-01)
$NodeName         = $env:COMPUTERNAME

# --- SYSTEM ENDPOINT VERIFICATION ---
$SidecarExeUrl    = "https://github.com/Graylog2/collector-sidecar/releases/download/1.5.3/graylog_sidecar_installer_1.5.3-1.exe"
$WinlogbeatZipUrl = "https://artifacts.elastic.co/downloads/beats/winlogbeat/winlogbeat-oss-7.12.1-windows-x86_64.zip"

# --- ELEVATION CHECK ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "CRITICAL: This script must be run from an elevated PowerShell window (Run as Administrator)."
    Exit
}

# --- STEP 1: FORCE CLOSE PROCESSES & BREAK FILE LOCKS ---
Write-Host "[-] Terminating active engines and clearing file system locks..." -ForegroundColor Cyan
Stop-Service -Name "Graylog Sidecar" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "winlogbeat" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "filebeat" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "graylog-sidecar" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2  

$InstallDir = "C:\Program Files\Graylog\sidecar"
Remove-Item -Recurse -Force "C:\Program Files\Graylog" -ErrorAction SilentlyContinue

$WinlogbeatDir = "$InstallDir\winlogbeat"
New-Item -ItemType Directory -Force -Path $WinlogbeatDir | Out-Null
New-Item -ItemType Directory -Force -Path "$InstallDir\logs" | Out-Null

# --- STEP 2: DOWNLOAD & EXTRACT WINLOGBEAT OSS ---
Write-Host "[+] Fetching Winlogbeat log collection engine..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $WinlogbeatZipUrl -OutFile "$env:TEMP\winlogbeat.zip" -UseBasicParsing
Expand-Archive -Path "$env:TEMP\winlogbeat.zip" -DestinationPath "$env:TEMP\winlogbeat_extracted" -Force
Move-Item -Path "$env:TEMP\winlogbeat_extracted\winlogbeat-7.12.1-windows-x86_64\*" -Destination "$WinlogbeatDir\" -Force
Remove-Item -Recurse -Force "$env:TEMP\winlogbeat.zip", "$env:TEMP\winlogbeat_extracted"

# --- STEP 3: AUTOMATED INLINE SIDECAR DOWNLOAD ENGINE ---
Write-Host "[+] Enforcing network TLS 1.2 routing session parameters..." -ForegroundColor Cyan
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$LocalInstaller = Join-Path $ScriptPath "graylog_sidecar_installer_1.5.3-1.exe"
Remove-Item -Force $LocalInstaller -ErrorAction SilentlyContinue

Write-Host "[+] Downloading Graylog Sidecar setup package from GitHub CDN..." -ForegroundColor Cyan
try {
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($SidecarExeUrl, $LocalInstaller)
} catch {
    Write-Warning "PowerShell web client blocked by local security policy. Dropping back to trusted curl context..."
    & curl.exe -L -o $LocalInstaller $SidecarExeUrl
}

if (-not (Test-Path $LocalInstaller) -or (Get-Item $LocalInstaller).Length -lt 1000) {
    Write-Error "CRITICAL: Download aborted by network firewall."
    Exit
}

Write-Host "[+] Stripping local security Mark-of-the-Web zone restrictions..." -ForegroundColor Green
Unblock-File -Path $LocalInstaller

Write-Host "[+] Deploying background installation matrix silently..." -ForegroundColor Cyan
Start-Process -FilePath $LocalInstaller -ArgumentList "/S" -Wait
Remove-Item -Force $LocalInstaller -ErrorAction SilentlyContinue

# --- STEP 4: GENERATE HARDENED SIDECAR CONFIGURATION MATRIX ---
Write-Host "[+] Injecting updated configuration profile settings for node: $NodeName..." -ForegroundColor Cyan
$SidecarConfigBlock = @"
server_url: "$GraylogServerUrl"
server_api_token: "$GraylogApiToken"
node_id: "file:C:\\Program Files\\Graylog\\sidecar\\node-id"
node_name: "$NodeName"
update_interval: 10
tls_skip_verify: true
send_status: true
list_log_files: []
collector_binaries_accesslist:
  - "C:\\Program Files\\Graylog\\sidecar\\winlogbeat\\winlogbeat.exe"
  - "C:\\Program Files\\Graylog\\sidecar\\winlogbeat.exe"
log_path: "C:\\Program Files\\Graylog\\sidecar\\logs"
log_rotate_max_file_size: 2097152
log_rotate_keep_files: 10
tags:
  - $SidecarTag
"@

Set-Content -Path "$InstallDir\sidecar.yml" -Value $SidecarConfigBlock -Force

# --- STEP 5: AUTOMATE PATH ALIGNMENT & SERVICE HOOKS ---
Write-Host "[+] Aligning path variations and initializing SCM hooks..." -ForegroundColor Cyan
$RealBinary = "$InstallDir\graylog-sidecar.exe"

if (Test-Path "$WinlogbeatDir\winlogbeat.exe") {
    Copy-Item -Path "$WinlogbeatDir\winlogbeat.exe" -Destination "$InstallDir\winlogbeat.exe" -Force
}

if (Test-Path $RealBinary) {
    if (-not (Get-Service -Name "Graylog Sidecar" -ErrorAction SilentlyContinue)) {
        & $RealBinary -service install
    }
    Start-Service -Name "Graylog Sidecar"
} else {
    Write-Error "CRITICAL ERROR: Failed to unpack internal core binaries."
    Exit
}

Write-Host "`n=======================================================" -ForegroundColor Green
Write-Host " AUTOMATED DEPLOYMENT SUCCESSFUL ON: $NodeName" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Get-Service -Name "Graylog Sidecar"