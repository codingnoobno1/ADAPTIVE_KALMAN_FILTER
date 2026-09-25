[CmdletBinding()]
param([ValidateSet('none','flutter','maui')][string]$Dashboard = 'flutter')
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot 'build-all.ps1')
& (Join-Path $PSScriptRoot 'run-all.ps1') -Dashboard $Dashboard

