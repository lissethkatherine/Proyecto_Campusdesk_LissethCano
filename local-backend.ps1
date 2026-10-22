<#
.SYNOPSIS
    CAMPUSDESK - Backend en modo desarrollo (Windows PowerShell)
.DESCRIPTION
    Levanta PostgreSQL y Redis en Docker y arranca Spring Boot FUERA de Docker,
    leyendo las variables del archivo .env
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\local-backend.ps1
#>

$ErrorActionPreference = "Stop"
Set-Location -Path $PSScriptRoot

if (-not (Test-Path ".env")) {
    Write-Host "ERROR: falta el archivo .env. Ejecute:  Copy-Item .env.example .env  y complete los valores." -ForegroundColor Red
    exit 1
}

# Carga cada linea CLAVE=VALOR del .env como variable de entorno del proceso
Get-Content ".env" | ForEach-Object {
    $line = $_.Trim()
    if ($line -eq "" -or $line.StartsWith("#")) { return }
    $idx = $line.IndexOf("=")
    if ($idx -lt 1) { return }
    $name = $line.Substring(0, $idx).Trim()
    $value = $line.Substring($idx + 1).Trim()
    [Environment]::SetEnvironmentVariable($name, $value, "Process")
}

function Get-EnvOr([string]$name, [string]$default) {
    $v = [Environment]::GetEnvironmentVariable($name, "Process")
    if ([string]::IsNullOrEmpty($v)) { return $default } else { return $v }
}

function Require-Env([string]$name) {
    $v = [Environment]::GetEnvironmentVariable($name, "Process")
    if ([string]::IsNullOrEmpty($v)) {
        Write-Host "ERROR: defina $name en el archivo .env" -ForegroundColor Red
        exit 1
    }
    return $v
}

# Fuera de Docker el backend usa los puertos publicados en tu equipo
$dbPort = Get-EnvOr "DB_PORT" "5436"
$dbName = Get-EnvOr "POSTGRES_DB" "sistema_gestion_usuarios"
$env:DB_URL = "jdbc:postgresql://localhost:$dbPort/$dbName"
$env:DB_USERNAME = Get-EnvOr "POSTGRES_USER" "admin"
$env:DB_PASSWORD = Require-Env "POSTGRES_PASSWORD"
$env:REDIS_HOST = "localhost"
$env:REDIS_PORT = Get-EnvOr "REDIS_HOST_PORT" "6385"
$env:REDIS_PASSWORD = Require-Env "REDIS_PASSWORD"
$env:JWT_SECRET = Require-Env "JWT_SECRET"
$env:SERVER_PORT = Get-EnvOr "BACKEND_PORT" "8056"

Write-Host "-> Levantando PostgreSQL y Redis (esperando a que esten saludables)..." -ForegroundColor Cyan
docker compose up -d --wait campusdesk-db campusdesk-redis
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: no se pudieron iniciar PostgreSQL/Redis. Verifique que Docker Desktop este en ejecucion." -ForegroundColor Red
    exit 1
}

Write-Host "-> Iniciando Spring Boot en http://localhost:$($env:SERVER_PORT)  (Ctrl+C para detener)" -ForegroundColor Cyan
Set-Location "spring-security-user-role-management"
& .\gradlew.bat bootRun
