# Copilot Support Ticket Triage — 2026-08-12

---

## Ticket 1
**Reporter:** Finance lead  
**Summary:** Copilot won't summarise the Q3 board pack in SharePoint. "It's right there, I can see it myself."

| Field | Detail |
|---|---|
| **Likely cause** | 1. Sensitivity label restriction — board packs are frequently labelled Confidential/Highly Confidential, which can block Copilot even when the file is visually accessible<br>2. Data indexing lag — recently uploaded or modified files may not yet be indexed by Microsoft Search<br>3. Permissions/access boundary — the user's direct access doesn't guarantee Copilot's service account scope includes that library |
| **Fastest check** | Check the sensitivity label applied to the file; if it carries a label that restricts Copilot processing, that is the answer. |
| **Is this actually a Copilot bug?** | No — the described behaviour is consistent with label-enforced content protection or an indexing gap. |

---

## Ticket 2
**Reporter:** New hire (started yesterday)  
**Summary:** Copilot in Outlook seems to know nothing about recent emails.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Data indexing lag — Microsoft 365 indexing for a brand-new account typically takes 24–72 hours before Copilot can reference mailbox content<br>2. License/client prerequisite issue — the Copilot licence may not yet be fully provisioned for a new account |
| **Fastest check** | Confirm the Copilot licence is assigned and active in the M365 admin centre for this user, then check the account creation timestamp against known indexing SLAs. |
| **Is this actually a Copilot bug?** | No — new-account indexing lag is the expected and documented behaviour. |

---

## Ticket 3
**Reporter:** HR manager  
**Summary:** Asked Copilot in Word to pull data from a sensitive salary review spreadsheet; got "I don't have access to that content."

| Field | Detail |
|---|---|
| **Likely cause** | 1. Sensitivity label restriction — salary review files are very likely labelled at a tier that explicitly prevents Copilot from processing them<br>2. Permissions/access boundary — the file may be stored in a restricted HR library where the manager has read rights but Copilot's indexing scope does not extend |
| **Fastest check** | Check the sensitivity label on the spreadsheet; if labelled Highly Confidential or equivalent with Copilot processing disabled, that is conclusive. |
| **Is this actually a Copilot bug?** | No — the error message itself ("I don't have access to that content") is the expected Copilot response when a label or permission boundary is enforced. |

---

## Ticket 4
**Reporter:** Sales rep  
**Summary:** Copilot in Teams can't find a client contract shared via a guest link from another org.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Guest/external sharing limitation — Copilot does not index content shared via anonymous or guest links from external tenants; only content homed in the user's own tenant is in scope<br>2. Permissions/access boundary — even if the file were accessible, cross-tenant content is outside Microsoft Search's index for this tenant |
| **Fastest check** | Confirm the file lives in an external tenant and was shared by guest link; Copilot has no access to external-tenant content by design. |
| **Is this actually a Copilot bug?** | No — this is a documented scope limitation; guest-linked external content is intentionally excluded from Copilot's index. |

---

## Ticket 5
**Reporter:** IT admin  
**Summary:** Copilot suddenly stopped working for the whole Finance team this morning; was fine yesterday.

| Field | Detail |
|---|---|
| **Likely cause** | 1. License/client prerequisite issue — a licence assignment change, policy update, or group membership change overnight could have revoked Copilot access for the Finance security group<br>2. Permissions/access boundary — a conditional access or DLP policy change may have blocked the Copilot service for this department<br>3. Genuine Copilot fault — wide-scope, sudden, team-level failures with no configuration change are the rare scenario where a service incident is plausible |
| **Fastest check** | Check the M365 admin centre for recent licence or group policy changes affecting the Finance team; simultaneously check the Microsoft 365 Service Health dashboard for any active Copilot incidents. |
| **Is this actually a Copilot bug?** | Unclear — the sudden, team-wide scope is unusual for a configuration issue but a licence/policy change is the more likely explanation; escalate to Microsoft if no admin change is found. |

---

## Ticket 6
**Reporter:** Manager  
**Summary:** Copilot found and summarised a file I don't remember ever opening, from a folder I forgot I had access to.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Permissions/access boundary — Copilot surfaces any content the user has legitimate permissions to access, including inherited or forgotten folder rights; this is working as designed |
| **Fastest check** | Verify in SharePoint/OneDrive that the manager does indeed have permissions to that folder (directly or via a group); if yes, no fault exists. |
| **Is this actually a Copilot bug?** | No — Copilot correctly indexes all content within the user's permission boundary. This is expected behaviour, not a fault; it may however surface a permissions hygiene concern to raise with the site owner. |

---

## Ticket 7
**Reporter:** Analyst  
**Summary:** Copilot gives generic answers; doesn't seem to use any internal SharePoint content at all.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Permissions/access boundary — the analyst may have very limited SharePoint permissions, leaving Copilot with little internal content to draw on<br>2. Data indexing lag — if the analyst's account or the SharePoint sites are newly set up, indexing may be incomplete<br>3. License/client prerequisite issue — verify the correct Copilot for Microsoft 365 licence (not a limited SKU) is assigned |
| **Fastest check** | Ask the analyst to open SharePoint in a browser and confirm they can browse and open internal site content; if they cannot, this is a permissions issue unrelated to Copilot. |
| **Is this actually a Copilot bug?** | No — generic responses with no internal grounding almost always indicate the user's index is empty due to permissions or an incomplete licence, not a Copilot fault. |

---

## Ticket 8
**Reporter:** Executive assistant  
**Summary:** Copilot in Outlook can't see a shared mailbox calendar managed on behalf of the director.

| Field | Detail |
|---|---|
| **Likely cause** | 1. Permissions/access boundary — Copilot for Outlook operates within the signed-in user's own mailbox context; delegated/shared mailbox content is a known scope limitation and is not included by default<br>2. License/client prerequisite issue — the shared mailbox itself does not hold a Copilot licence; Copilot cannot act on unlicensed mailboxes even with delegate access |
| **Fastest check** | Confirm whether the shared mailbox has its own Copilot licence assigned; if not, this is a documented limitation and not a bug. |
| **Is this actually a Copilot bug?** | No — Copilot's inability to access delegated/shared mailbox calendars is a known, documented constraint of the current product scope. |

---

*Triage completed: 2026-08-12 | Engineer: DWP IT*
