# entra-ca-templates

Microsoft Entra Conditional Access policies as code, plus a Microsoft Graph PowerShell helper to deploy them, plus bundled [Maester](https://maester.dev) tests that verify they are present and in the expected state.

The templates target the small set of CA policies most tenants either already have or should have:

- Block legacy authentication.
- Require MFA for all directory roles (admin protection).
- Require compliant device for high-impact apps.
- Sign-in risk and user-risk responses.
- Session controls for browser access from unmanaged devices.

Each policy ships in `disabled` state by default — review and adjust assignments, then re-enable.

## Status

Early — public seed of an ongoing project. Templates are valid Microsoft Graph payloads but should be reviewed before deployment.

## Layout

```text
templates/        Conditional Access policy JSON, one file per policy.
deploy/           PowerShell helper to deploy templates via Microsoft Graph.
tests/            Maester tests verifying each policy is present and configured.
```

## Quick start

```powershell
Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess'

# Review a single template
Get-Content ./templates/01-block-legacy-auth.json | ConvertFrom-Json

# Deploy all templates (idempotent — updates existing policies by displayName)
./deploy/Deploy-CaTemplates.ps1 -Path ./templates

# Verify with Maester
Connect-Maester
Invoke-Maester -Path ./tests
```

## Templates

| File                                  | Policy                                      |
| ------------------------------------- | ------------------------------------------- |
| `templates/01-block-legacy-auth.json` | Block legacy authentication for all users.  |
| `templates/02-mfa-for-admins.json`    | Require MFA for all directory-role members. |

## Contributing

PRs welcome. Adding a template should also add a Maester test that verifies it. See [CONTRIBUTING](.github/CONTRIBUTING.md).

## Licence

[MIT](LICENSE).
