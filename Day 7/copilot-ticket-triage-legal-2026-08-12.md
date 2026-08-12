# Copilot Incident Triage — Legal Team — 2026-08-12

---

## Ticket 1
**Reporter:** Paralegal  
**Summary:** Asked Copilot to summarise a client NDA in SharePoint; got "I don't have access to that content." File is in a folder she has never opened before.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Permissions/access boundary - Copilot can only use content the user can currently access; if she is not on the folder ACL/group, denial is expected<br>2. Sensitivity label/policy restriction - file may permit manual read access in some contexts but block Copilot processing<br>3. Index scope gap - if the site/library is new or recently permissioned, search index may not yet reflect usable access |
| **Fastest check** | Confirm the user's effective permission on the exact file path in SharePoint (including inherited group membership), then check file sensitivity label and policy settings. |
| **Is this a Copilot product bug?** | No, most likely expected permission or policy enforcement. |
| **Initial incident category** | M365 Copilot / SharePoint content access boundary (configuration or governance). |
| **Initial priority** | P3 (single user, no broad outage signal). |

---

## Ticket 2
**Reporter:** New associate (first week)  
**Summary:** Copilot in Outlook cannot find case emails needed for context.

| Field | Detail |
|---|---|
| **Likely cause** | 1. New account indexing lag - Outlook and Microsoft Search grounding can take 24-72 hours after mailbox/content onboarding<br>2. Licensing/provisioning delay - Copilot license or service plan not fully provisioned yet<br>3. Mailbox scope mismatch - expected case emails may be in shared mailbox/delegated locations outside current Copilot scope |
| **Fastest check** | Validate Copilot license assignment/provisioning status and account start date, then verify where the target case emails actually live (personal mailbox vs shared/delegated). |
| **Is this a Copilot product bug?** | Unlikely; most often onboarding/indexing or mailbox-scope limitation. |
| **Initial incident category** | M365 Copilot / Outlook grounding and mailbox scope. |
| **Initial priority** | P3 (single user onboarding impact). |

---

## Ticket 3
**Reporter:** Partner  
**Summary:** Copilot surfaced and summarised a draft settlement from a matter the partner is not assigned to.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Over-permissioned access path - user has direct or inherited rights via SharePoint group, M365 group, or broad legal library permissions<br>2. Legacy ACL drift - historical/legal-team inheritance grants were never narrowed when matter boundaries changed |
| **Fastest check** | Run effective access on the surfaced file/folder and trace permission inheritance and group membership chain for the partner account. |
| **Is this a Copilot product bug?** | No, unless effective access shows no entitlement. Copilot generally mirrors existing permissions. |
| **Initial incident category** | Data exposure risk / permission hygiene (not primarily Copilot fault). |
| **Initial priority** | P1 security/privacy (potential matter-confidentiality breach). |
| **Immediate containment** | Remove unintended access from affected library/group, preserve audit evidence, notify Legal data owner and Security. |

---

## Ticket 4
**Reporter:** Legal ops manager  
**Summary:** All 40 users in Legal lost Copilot access this morning; working last week.

| Field | Detail |
|---|---|
| **Likely cause** | 1. License assignment removal or group-based licensing change affecting Legal cohort<br>2. Conditional Access or service policy change blocking Copilot workloads<br>3. Tenant or regional Microsoft 365 service incident |
| **Fastest check** | Check recent changes to Legal licensing group/policy objects and confirm current assignment count; in parallel check Microsoft 365 Service Health for active Copilot advisories/incidents. |
| **Is this a Copilot product bug?** | Unknown at triage. Team-wide sudden loss requires incident handling until config vs service cause is confirmed. |
| **Initial incident category** | Service degradation / access outage (M365 Copilot). |
| **Initial priority** | P2 (department-wide productivity outage). |
| **Escalation trigger** | If no admin-side change is found within initial triage window, escalate to Microsoft support with timestamped evidence. |

---

## Ticket 5
**Reporter:** Contract specialist  
**Summary:** Copilot gives vague, generic answers about contract template clauses; appears not to read template library documents.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Limited SharePoint permissions - user cannot access enough template library content for grounding<br>2. Index freshness gap - template library updates are not fully indexed yet<br>3. Prompt ambiguity - broad prompts lead to generic output when retrieval confidence is low |
| **Fastest check** | Confirm user can directly open the expected template documents in SharePoint and test a targeted prompt naming a specific document and clause. |
| **Is this a Copilot product bug?** | Usually no; typically permissions/indexing/prompting quality. |
| **Initial incident category** | Retrieval quality / knowledge grounding (M365 Copilot + SharePoint). |
| **Initial priority** | P3 (single user quality issue, no outage). |

---

## Cross-ticket Triage Actions (Recommended)
1. Pull a single evidence pack per ticket: user UPN, timestamp, client app, prompt used, expected source file/path, actual Copilot response.
2. Run access validation on involved SharePoint libraries with effective permissions and inheritance trace.
3. Validate Legal Copilot license assignment and recent group/policy changes within the last 24 hours.
4. Review Microsoft 365 Service Health and advisories for Copilot/Exchange/SharePoint dependencies.
5. Flag Ticket 3 as security-sensitive and track under incident response workflow.

---

*Triage completed: 2026-08-12 | Engineer: DWP IT*