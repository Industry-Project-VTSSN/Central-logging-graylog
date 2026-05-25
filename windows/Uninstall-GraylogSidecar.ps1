<#
.SYNOPSIS
    Production-Hardened Uninstallation Script for Graylog Sidecar & Winlogbeat.
.DESCRIPTION
    Completely stops services, forcefully cuts orphan background process loops, 
    releases locked directory path environments, and sweeps out files cleanly.
#>

# --- ELEVATION CHECK ---
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "CRITICAL: This script must be run from an elevated PowerShell window (Run as Administrator)."
    Exit
}

$InstallDir = "C:\Program Files\Graylog"
Write-Host "[-] Commencing complete teardown of Graylog Sidecar framework..." -ForegroundColor Yellow

# --- STEP 1: DEREGISTER THE SERVICE CONTROL ENGINE ---
if (Get-Service -Name "Graylog Sidecar" -ErrorAction SilentlyContinue) {
    Write-Host "[*] Stopping active Graylog Sidecar service process handles..." -ForegroundColor Cyan
    Stop-Service -Name "Graylog Sidecar" -Force -ErrorAction SilentlyContinue
    
    Write-Host "[*] Deregistering service mappings from Service Control Manager..." -ForegroundColor Cyan
    if (Test-Path "$InstallDir\sidecar\graylog-sidecar.exe") {
        & "$InstallDir\sidecar\graylog-sidecar.exe" -service uninstall | Out-Null
    }
}

# --- STEP 2: FORCE PURGE LOCKS AND SUB-PROCESS DAEMONS ---
Write-Host "[*] Terminating any lingering background log runner files..." -ForegroundColor Cyan
Stop-Process -Name "winlogbeat" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "filebeat" -Force -ErrorAction SilentlyContinue
Stop-Process -Name "graylog-sidecar" -Force -ErrorAction SilentlyContinue

# Give Windows OS a 2-second buffer window to cleanly release background file locks
Start-Sleep -Seconds 2

# --- STEP 3: SYSTEM DIRECTORY PURGE ---
if (Test-Path $InstallDir) {
    Write-Host "[*] Purging target installation footprints from Program Files..." -ForegroundColor Cyan
    
    # CRITICAL AUTOMATION STEP: Fall backwards into the system root path context 
    # to guarantee the PowerShell session itself isn't locking the directory being deleted
    Set-Location -Path "C:\"
    
    # Force delete filesystem trees recursively
    Remove-Item -Recurse -Force $InstallDir -ErrorAction SilentlyContinue
}

# --- STEP 4: POST-DESTRUCTION INTEGRITY INSPECTION ---
$ServiceCheck = Get-Service -Name "Graylog Sidecar" -ErrorAction SilentlyContinue
$FolderCheck  = Test-Path $InstallDir

Write-Host "`n=======================================================" -ForegroundColor Green
Write-Host " TEARDOWN ACTIONS COMPLETE" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green

if (-not $ServiceCheck -and -not $FolderCheck) {
    Write-Host "Success: Framework fully scrubbed and system directories deleted cleanly!" -ForegroundColor Green
} else {
    Write-Host "Notice: Some locks require a system reboot to completely finish clearing from memory space." -ForegroundColor Yellow
}