# Security policy

## Supported versions

Security fixes are applied to the latest release. Administrators should deploy the newest signed and approved package after testing it in their environment.

## Reporting a vulnerability

Do not publish exploitable details, signing material, internal package URLs, or fleet information in a public issue. Before publishing the repository, replace this paragraph with your organization’s private security contact or GitHub Security Advisory instructions.

Include the affected version, macOS version, impact, reproduction steps, and any suggested mitigation. Never include real employee data or credentials.

## Deployment security

- Sign production apps and packages with stable Developer ID identities.
- Verify package signatures and, for URL deployment, configure the expected Team ID.
- Distribute packages through JAMF or an authenticated HTTPS endpoint.
- Do not run project build scripts with `sudo`.
- Review Apple Shortcut contents before distributing or importing them.
