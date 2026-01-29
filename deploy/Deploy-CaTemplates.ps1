#Requires -Version 7.4
#Requires -Modules @{ ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '2.10.0' }

<#
.SYNOPSIS
    Deploy all Conditional Access policy templates in a folder via Microsoft Graph.

.DESCRIPTION
    Reads every *.json file in the supplied folder, treats each as a Conditional Access policy
    payload, and creates or updates the matching policy by displayName.

    Connect to Microsoft Graph first:
        Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess'

.PARAMETER Path
    Folder containing CA template *.json files. Defaults to ./templates relative to script.

.EXAMPLE
    ./deploy/Deploy-CaTemplates.ps1 -Path ./templates -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Path = (Join-Path $PSScriptRoot '..' 'templates')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$context = Get-MgContext -ErrorAction SilentlyContinue
if (-not $context) {
    throw 'Not connected to Microsoft Graph. Run Connect-MgGraph -Scopes Policy.ReadWrite.ConditionalAccess first.'
}

$resolved = Resolve-Path $Path
$templates = Get-ChildItem -Path $resolved -Filter '*.json' -File
if ($templates.Count -eq 0) {
    Write-Warning "No JSON templates found in $resolved"
    return
}

# Cache existing policies (one Graph call) so we can match by displayName
$existing = Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies'

foreach ($t in $templates) {
    $payload = Get-Content -LiteralPath $t.FullName -Raw | ConvertFrom-Json -AsHashtable
    $name    = $payload.displayName

    $match = $existing.value | Where-Object { $_.displayName -eq $name } | Select-Object -First 1

    if ($match) {
        if ($PSCmdlet.ShouldProcess($name, 'Update Conditional Access policy')) {
            Invoke-MgGraphRequest -Method PATCH -Uri "/v1.0/identity/conditionalAccess/policies/$($match.id)" -Body $payload | Out-Null
            Write-Host "Updated: $name" -ForegroundColor Yellow
        }
    } else {
        if ($PSCmdlet.ShouldProcess($name, 'Create Conditional Access policy')) {
            Invoke-MgGraphRequest -Method POST -Uri '/v1.0/identity/conditionalAccess/policies' -Body $payload | Out-Null
            Write-Host "Created: $name" -ForegroundColor Green
        }
    }
}
