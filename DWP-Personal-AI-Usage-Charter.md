# Personal AI Usage Charter (DWP Desktop/Endpoint Engineer)
Version 1.0 | Date: 03 Aug 2026

## Purpose
I use public AI assistants to improve speed and quality of endpoint engineering work, while protecting DWP data, users, and services. AI output is a draft assistant, not an authority. I remain accountable for every action I take.

## 1. Appropriate DWP Tasks for Public AI Help
I will use public AI for low-risk, non-sensitive desktop/endpoint work such as:
- Drafting PowerShell or batch script skeletons for generic tasks (for example: service checks, log rotation, file cleanup patterns).
- Creating detection/remediation logic templates for endpoint tooling using dummy values.
- Generating troubleshooting checklists for common Windows issues (boot, profile, driver, patch, VPN client, printer, disk space).
- Drafting communications: user advisories, maintenance notices, incident update wording.
- Explaining commands, logs, error codes, registry paths, and policy behavior at a general level.
- Producing test plans, rollback plans, and validation checklists for endpoint changes.
- Refactoring my own non-sensitive scripts for readability, comments, and error handling.

## 2. Tasks That Are Not Appropriate
I will not use public AI for:
- Any work containing claimant, customer, or colleague personal data.
- Any production incident content that includes sensitive operational details.
- Security architecture, vulnerabilities, exploit paths, or defensive control specifics not already public.
- Full environment exports, endpoint inventories, internal network details, or device identifiers tied to people.
- Decision-making that requires DWP policy interpretation without human review.
- Final approval of scripts, patches, GPO/Intune baselines, or system changes.

## 3. Data-Handling Rule (PII and Credentials)
My hard rule: if data could identify a person, access a system, or reveal internal posture, it does not go into a public AI tool.

I will never paste:
- Names, addresses, NI numbers, DOB, phone, personal email, case references, ticket text with user details.
- Usernames, passwords, API keys, tokens, certificates, private keys, MFA secrets, recovery codes.
- Real hostnames, internal IP ranges, tenant IDs, serial numbers mapped to users, or full logs with identifiers.

If context is needed, I will:
- Replace real values with synthetic placeholders.
- Minimize to the smallest safe excerpt.
- Redact before prompt, and re-check redaction before submit.
- Stop and escalate if unsure whether data is safe.

## 4. Personal Generate-Then-Verify Rule (Scripts and System Changes)
For any AI-generated script or change, I will follow this sequence every time:
1. Generate: Ask AI for a draft with comments, assumptions, and rollback steps.
2. Review: Read every line myself; remove unsafe commands; confirm paths, scopes, and permissions.
3. Validate safely: Test in a lab/test OU/ring first, using sample data and least privilege.
4. Dry run first: Use safe modes where possible (for example simulation/what-if behavior).
5. Peer and policy check: Get human review for medium/high-impact changes.
6. Deploy gradually: Pilot to a small device cohort before broad rollout.
7. Verify outcome: Confirm success criteria, logs, user impact, and no security regressions.
8. Record: Document prompt intent, edits made, test evidence, approval, and rollback status.

## Personal Commitment
I will use public AI to accelerate drafting, not to outsource judgment. If in doubt: do not paste, do not run, and ask for review.
