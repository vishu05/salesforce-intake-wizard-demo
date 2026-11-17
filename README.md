# Salesforce Intake Wizard Demo

A multi-step **Lightning Web Component intake wizard** for service referrals — built from scratch with fictional data to demonstrate enterprise intake patterns: guided step-by-step data capture, participant management, reusable address forms, duplicate detection, and referral history.

> **Northstar Family Support Network** (fictional) receives service referrals from schools, clinics, and community partners. This demo replaces phone/email intake and spreadsheets with a guided Salesforce wizard.

![Salesforce](https://img.shields.io/badge/Salesforce-API%2067.0-00A1E0)
![Apex](https://img.shields.io/badge/Apex-LWC%20%7C%20Triggers-blue)
![Tests](https://img.shields.io/badge/Apex%20Tests-95%25%2B%20target-green)

## The Wizard — 5 Steps

| Step | Screen | Highlights |
|---|---|---|
| 1 | **Reporting Source** | Reporter name/org/role, contact method, reusable address block with mock address validation |
| 2 | **Primary Individual** | Name, DOB ↔ approximate-age auto-calculation, "name unknown" handling, **duplicate warning** |
| 3 | **Participants** | Add/remove participants with roles and relationships |
| 4 | **Request Details** | Request type, priority, services needed, narrative |
| 5 | **Attachments & Review** | File upload, read-only summary, prior-referral history table, Submit |

Cross-cutting: progress indicator, **Save Draft** at any step, per-step validation before advancing, status lifecycle `New → Draft → Submitted → In Review → Assigned / Returned for Edits`, and auto-numbered referrals (`REF-000123`) on submit. Fields lock after submission except for supervisors.

## Business Rules Demonstrated

1. **Step validation** — Step 1 requires reporter name + phone *or* email before advancing
2. **DOB ↔ Age** — DOB auto-calculates approximate age
3. **Duplicate detection** — Apex searches by last name + DOB and warns (non-blocking) on possible matches
4. **Referral history** — prior referrals for the same individual appear in Step 5
5. **Status lifecycle** — trigger-enforced transitions and read-only behaviour after submit
6. **Per-step transactional saves** — participant + address saved together in one Apex transaction with savepoints

## Data Model

```
Service_Intake__c            (the referral)
├── Intake_Participant__c    (Reporting Person / Primary Individual / Caregiver / Household Member / Witness)
└── Intake_Address__c        (Home / Mailing / Work addresses, validation status)
```
Attachments use standard `ContentDocumentLink` / Salesforce Files.

## Tech Stack

- **LWC** — parent `intakeWizard` shell + one child component per step, reusable `intakeAddressForm`, `intakeReferralHistory` datatable
- **Apex** — `IntakeWizardController` (`@AuraEnabled`, `with sharing`), `IntakeDuplicateService`, trigger-handler pattern, test-data factory
- **Tests** — Apex test classes (positive / negative / bulk / exception, `HttpCalloutMock`-style mocking for address validation), LWC Jest scaffold
- **DevOps** — SFDX project, GitHub Actions CI (PMD + LWC Jest), Prettier/ESLint, Husky pre-commit

## Getting Started

```bash
# 1. Authorize a Developer Edition / scratch org
sf org login web --alias intake-demo

# 2. Deploy the demo metadata
sf project deploy start --target-org intake-demo

# 3. (Optional) Open the org and add the Intake Wizard to a Lightning App page
sf org open --target-org intake-demo
```

Then create a `Service_Intake__c` record and launch the wizard from the app page.

## Project Structure

```
force-app/main/default/
├── objects/        Service_Intake__c, Intake_Participant__c, Intake_Address__c
├── classes/        IntakeWizardController, IntakeDuplicateService, handlers, tests
├── triggers/       ServiceIntakeTrigger
└── lwc/            intakeWizard + step components, intakeAddressForm, intakeReferralHistory
```

## Demo Walkthrough (3 minutes)

1. A school counselor submits a referral (Step 1, validate the address)
2. Enter the student on Step 2 — **the duplicate banner flags a referral from 3 months ago**, and Step 5 shows that history
3. Add a parent as a participant, upload a PDF, review, and **Submit** — a referral number is generated and fields lock

Sample seed data: Jamie Rivera (Lincoln Elementary, School Counselor) → Alex Morgan (mentoring + food assistance, High priority) → Taylor Morgan (Parent/Caregiver). All fictional.

## Disclaimer

This is a **portfolio demo built from scratch**. The organization, people, and data are fictional. It demonstrates design patterns only and contains no code, data, or configuration from any employer or client system.

## License

MIT — see [LICENSE](LICENSE).
