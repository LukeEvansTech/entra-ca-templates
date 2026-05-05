#Requires -Modules Pester, Maester

BeforeDiscovery {
    $script:tag = @('ConditionalAccess', 'Entra')
}

Describe 'entra-ca-templates — policies present in tenant' -Tag $script:tag {

    BeforeAll {
        $script:expectedPolicies = @(
            '[entra-ca-templates] Block legacy authentication',
            '[entra-ca-templates] MFA for all directory-role admins'
        )
        $script:tenantPolicies = (Invoke-MgGraphRequest -Method GET -Uri '/v1.0/identity/conditionalAccess/policies').value
    }

    It "policy '<_>' exists" -ForEach $expectedPolicies {
        $policy = $tenantPolicies | Where-Object { $_.displayName -eq $_ }
        $policy | Should -Not -BeNullOrEmpty -Because "the deploy helper should have created '$_'."
    }

    Context 'Block legacy authentication' {
        It 'is enabled and blocks the right client app types' {
            $p = $tenantPolicies | Where-Object { $_.displayName -eq '[entra-ca-templates] Block legacy authentication' }
            $p.state | Should -BeIn @('enabled', 'enabledForReportingButNotEnforced') -Because 'A disabled block-legacy-auth policy provides zero protection.'
            $p.conditions.clientAppTypes | Should -Contain 'exchangeActiveSync'
            $p.conditions.clientAppTypes | Should -Contain 'other'
        }
    }
}
