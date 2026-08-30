# MediCore Health Systems — Incident Response Plan

**Document:** MediCore-IRP-v1.md  
**Version:** 1.0  
**Date:** 28 August 2026  
**Owner / Named Incident Lead:** Aurora Serban — Lead Cloud Security Architect  
**AWS Region:** Europe (London), `eu-west-2`  
**Classification:** Internal / Security & Compliance  
**Review cycle:** After every significant security incident and at least annually

**Deployment-specific note:** This IRP is aligned with MediCore's deployed AWS infrastructure. The five deployed CloudWatch alarm names, metrics, namespaces, comparison operators and thresholds were verified against evidence screenshot **A2-87** using the AWS CLI `cloudwatch describe-alarms` output.

---

## 1. Purpose and Scope

This Incident Response Plan (IRP) defines how MediCore Health Systems will prepare for, identify, contain, eradicate, recover from and learn from security incidents affecting its clinical cloud environment.

The plan follows the NCSC six-phase incident-response lifecycle and is grounded in MediCore's deployed AWS infrastructure:

- VPC in `eu-west-2` using public, private application and restricted database subnets across three Availability Zones;
- internet-facing Application Load Balancer (ALB);
- Auto Scaling Group (ASG) with minimum 2, desired 2 and maximum 4 application EC2 instances;
- `medicore-bastion` host used for controlled administrative SSH access;
- Amazon RDS for PostgreSQL, encrypted and not publicly accessible;
- academic RDS limitation: Single-AZ with one-day automated backup retention;
- private Amazon S3 clinical-data bucket with SSE-S3/AES-256 and Block Public Access enabled;
- AWS CloudWatch metrics, alarms and bastion authentication logs;
- least-privilege IAM roles for Clinical Read Only, Clinical Write, Database Administrator, Monitoring Read Only and Backup Operator;
- HTTPS/TLS at the ALB and tier-to-tier Security Group restrictions.

The plan supports UK GDPR Article 32 security-of-processing obligations, Article 33 personal-data-breach notification, Article 34 communication to affected individuals where high risk applies, and NHS DSPT-aligned security and incident-management practice.

No real patient data is stored in the academic environment. The incident scenarios nevertheless model the stated MediCore business context involving approximately 140,000 NHS patient records.

---

## 2. Incident Roles, Escalation and Decision Authority

Incident coordination must use **Microsoft Teams or direct phone for urgent internal escalation, not ordinary email**, because email may be unavailable or compromised during an incident.

| Role | Named person / owner | Primary channel | Response SLA | Decision authority |
|---|---|---|---:|---|
| Incident Lead | **Aurora Serban**, Lead Cloud Security Architect | Teams / phone | 15 minutes | Declare incident; coordinate technical response; authorise evidence preservation and containment |
| CTO | Chief Technology Officer | Teams / phone | 2 hours | Business continuity, major service decisions, NHS Trust executive communication |
| DPO | MediCore Data Protection Officer | Direct phone / Teams | 2 hours | Determine personal-data-breach risk; lead ICO and Article 34 decisions |
| Cloud / Infrastructure Engineer | On-call infrastructure engineer | Teams / phone | 15 minutes | Preserve logs, isolate resources, rebuild EC2, verify ALB/ASG health |
| Database Administrator | `db-admin` role holder | Teams / phone | 30 minutes | RDS containment, backup/PITR verification, restore and integrity checks |
| Monitoring Analyst | `monitoring-only` role holder | Teams | 15 minutes | CloudWatch investigation, timeline and alert correlation |
| Backup Operator | `backup-operator` role holder | Teams | 30 minutes | Backup verification and recovery support |
| NHS Trust contacts | Per contract | Secure approved channel | 48 hours or earlier if contract requires | Receive service/clinical impact and continuity updates |
| ICO Regulatory Contact | Information Commissioner's Office | ICO breach-reporting service | Within 72 hours where Article 33 threshold is met | Receive the Article 33 personal-data-breach notification submitted by the DPO |

### Severity

- **SEV-1 Critical:** confirmed compromise of patient/clinical data, ransomware, widespread service outage, loss/corruption of RDS data, or active privileged-account compromise.
- **SEV-2 High:** credible unauthorised access attempt, repeated security alarm with evidence of compromise, ALB/app outage affecting clinical access, or serious misconfiguration.
- **SEV-3 Medium:** isolated alarm with no confirmed compromise, degraded performance, or contained operational issue.
- **SEV-4 Low:** informational event or false positive requiring documentation only.

---

## 3. Preparation — NCSC Phase 1

MediCore must maintain readiness before an incident occurs.

### 3.1 Preventive and Detective Controls

The deployed environment uses:

- Security Groups restricting:
  - Bastion SSH 22 to the authorised administrator IP;
  - application HTTP 80 to the ALB Security Group;
  - application SSH 22 to the Bastion Security Group;
  - PostgreSQL 5432 to the Application Security Group;
- RDS encryption at rest;
- S3 SSE-S3/AES-256 and Block Public Access;
- HTTPS/TLS at the ALB;
- five least-privilege IAM roles;
- ALB + ASG across three Availability Zones for application-tier resilience;
- CloudWatch alarms and bastion authentication logging;
- Trivy and Grype vulnerability scanning for the container image;
- GitHub version control for infrastructure, Docker, Kubernetes, analysis and compliance evidence.

### 3.2 Five CloudWatch Alerts

The deployed architecture confirms the following five alarm names.

| Alert | Metric / signal | Threshold | IRP trigger | Notify | SLA | Immediate action |
|---|---|---|---|---|---:|---|
| **App High CPU** | EC2 `CPUUtilization` on application tier | **>= 80%** | Phase 2 Identification | Monitoring Analyst + Incident Lead | 15 min | Correlate CPU rise with traffic, processes, ALB and ASG activity; determine capacity issue vs malicious workload |
| **App Status Check Failure** | EC2 `StatusCheckFailed` | **>= 1** | Phase 2; escalate to Phase 3 if instance is unhealthy/compromised | Incident Lead + Infrastructure Engineer | 15 min | Preserve evidence, verify ASG replacement behaviour and isolate affected instance if compromise suspected |
| **ALB Unhealthy Hosts** | ALB `UnHealthyHostCount` | **>= 1** | Phase 2 | Infrastructure Engineer + Incident Lead | 15 min | Check target group, application health endpoint, ASG capacity and recent changes |
| **RDS High CPU** | RDS `CPUUtilization` | **>= 80%** | Phase 2; SEV-1/2 if clinical availability or malicious queries suspected | DBA + Incident Lead | 15 min | Review RDS metrics/connections, preserve logs, restrict compromised credentials if required |
| **Failed SSH Attempts** | `FailedSSHLoginCount` from Bastion Authentication log group | **>= 3** | Phase 2 Security Identification | Incident Lead + Monitoring Analyst | 5 min | Preserve bastion auth logs, identify source/time pattern, confirm no successful unauthorised session, review credentials and SG restriction |

**Assignment evidence link:** A2-87 documents the five CloudWatch alarms; A2-88–90 document Failed SSH monitoring. A6 uses EC2 CPU utilisation and failed SSH attempts as monitoring-analysis evidence.

---

### Critical Escalation Rule

Where investigation of any of the five A2 monitoring alerts indicates ransomware, unauthorised access, compromise of clinical data or another suspected security incident, the Incident Lead will escalate the event from Identification to the appropriate containment response. If investigation confirms that a personal data breach has occurred, **T+0** is recorded at the point MediCore becomes aware of that breach and the **UK GDPR Article 33 72-hour notification period** begins.

## 4. Identification — NCSC Phase 2

### 4.1 When an Incident Starts

An alert is not automatically a personal-data breach. The Incident Lead must determine whether the event represents:

1. a false positive;
2. an operational incident;
3. a security incident; or
4. a **personal data breach**.

The investigation must correlate CloudWatch alarm time, bastion authentication logs, EC2/RDS/ALB metrics, recent IAM or Security Group changes, application availability and any evidence of unauthorised access or encryption.

### 4.2 Start of the 72-Hour Clock

For this IRP, **T+0 is the point at which MediCore becomes aware that a personal data breach has occurred**, not the time when senior management is later informed.

At T+0 the Incident Lead records:

- UTC timestamp and detection source;
- affected AWS resources;
- alarm(s) triggered;
- suspected attack vector;
- categories of data potentially affected;
- approximate number of data subjects / records;
- availability, confidentiality and integrity impact;
- current containment status;
- person making the determination.

### 4.3 Ransomware Scenario for Deliverable C

Scenario: ransomware is identified at **03:14** and encrypts **47,000 MediCore patient records**.

This is immediately treated as **SEV-1 Critical** because Special Category health data and clinical availability/integrity are affected.

The 72-hour Article 33 timeline begins at the point MediCore becomes aware that the encryption constitutes a personal data breach.

---

## 5. Containment — NCSC Phase 3

 **Critical forensic rule: preserve evidence before making containment changes wherever safely possible.** Configuration changes, instance termination, credential revocation or log rotation can destroy evidence needed to establish the attack path and breach scope.

### 5.1 Evidence Preservation — FIRST

Before isolation:

1. record the incident timestamp and CloudWatch alarms;
2. export/preserve relevant CloudWatch metrics and logs;
3. preserve Bastion Authentication logs and `FailedSSHLoginCount` evidence;
4. record affected EC2 instance IDs, ASG/target-group state, RDS identifiers and relevant IAM identities;
5. preserve current Security Group and route configuration;
6. record recent IAM, Security Group and infrastructure changes;
7. where practical, create an EBS snapshot / forensic copy of an affected EC2 volume before rebuild;
8. restrict access to evidence to the incident-response team and record who collected it.

### 5.2 Short-Term Containment

Depending on the affected resource:

**Compromised application EC2**
- remove/isolate the affected instance from normal service without destroying evidence;
- restrict network access using the relevant Security Group;
- allow the ALB/ASG to maintain service using healthy instances;
- do not reuse suspected compromised credentials.

**Compromised bastion / SSH activity**
- preserve authentication logs;
- confirm port 22 remains restricted to the authorised administrator IP;
- revoke/rotate exposed credentials or keys after preservation;
- block unauthorised access paths.

**Suspected RDS compromise / ransomware**
- preserve database logs/metrics and connection evidence;
- stop compromised application/IAM credentials from reaching the database;
- do not overwrite the affected database with a restore until the required evidence and recovery point have been identified.

**S3 exposure**
- confirm Block Public Access;
- remove unintended policies/ACLs only after recording the exposed configuration;
- preserve access/audit evidence available for the incident.

### 5.3 Business Continuity

The ALB and ASG should keep the application tier available using healthy instances where safe. If continued service risks further corruption of clinical data, the CTO and Incident Lead may authorise controlled service restriction and invoke NHS Trust contingency arrangements.

---

## 6. Eradication — NCSC Phase 4

The objective is to remove the attacker's persistence and the root cause rather than simply restart affected services.

### 6.1 Determine Root Cause

Investigate:

- phishing or stolen credentials — B3 **R08**;
- inappropriate/compromised application access — **R02**;
- RDS loss/corruption — **R03**;
- Security Group/routing misconfiguration — **R04**;
- EC2/AZ failure — **R05**;
- S3 exposure — **R06**;
- administrator configuration error — **R07**;
- repeated failed SSH attempts — **R01**.

### 6.2 Rebuild the Application Tier

For the deployed MediCore Auto Scaling Group architecture, the clean-rebuild mechanism is replacement of the compromised web/application EC2 instance from the **known-clean AMI referenced by the launch template**, rather than restoration or continued use of the compromised instance in place.

For a compromised web/application EC2 instance:

1. preserve forensic evidence;
2. remove the compromised instance from service;
3. identify and remediate the initial vector;
4. patch/update the source image and launch-template configuration where required;
5. rebuild from the known-clean AMI referenced by the launch template rather than trusting the compromised instance;
6. build and scan the application container with **Trivy and Grype**;
7. confirm **CRITICAL vulnerabilities = 0** before release;
8. redeploy through the Auto Scaling Group;
9. verify the replacement target becomes healthy behind the ALB;
10. rotate any credentials potentially exposed during the incident.

### 6.3 Correct Configuration Errors

For R04/R07-type incidents:

- compare Security Groups against the intended architecture;
- restore SG-to-SG restrictions;
- confirm RDS remains not publicly accessible;
- confirm restricted DB subnets have no direct Internet route;
- review IAM permissions against least privilege;
- document every emergency change and obtain retrospective approval.

---

## 7. Recovery — NCSC Phase 5

Recovery returns MediCore to a trusted operational state while avoiding reinfection or restoration of corrupted data.

### 7.1 Application Recovery

1. confirm clean ASG instances are running;
2. confirm ALB target health;
3. test the application endpoint and `/health` behaviour;
4. confirm expected HTTPS/TLS access;
5. monitor CPU, status-check and unhealthy-host alarms closely after restoration;
6. re-enable normal traffic only when the Incident Lead approves.

### 7.2 RDS Recovery

The academic deployment has:

- encrypted RDS PostgreSQL;
- automated backups;
- Point-in-Time Restore (PITR);
- **Single-AZ** deployment;
- **one-day backup retention**.

Recovery procedure:

1. identify a clean recovery point immediately before malicious encryption/corruption;
2. preserve evidence from the affected database;
3. initiate RDS restore / PITR to a new trusted database instance where feasible;
4. validate database integrity and application connectivity;
5. confirm `db-sg` still permits PostgreSQL 5432 only from `app-sg`;
6. switch the application to the recovered database only after validation;
7. monitor RDS CPU, connections and application behaviour;
8. record achieved recovery time and any data-loss interval.

**Production remediation:** the current one-day retention and Single-AZ design are known limitations under B3 R03. Production should use Multi-AZ RDS and at least seven days of automated backup retention.

### 7.3 S3 Recovery

- verify Block Public Access remains enabled;
- verify SSE-S3/AES-256;
- restore affected objects only from trusted backups/versions available to the organisation;
- revalidate bucket policy and IAM permissions.

### 7.4 Recovery Exit Criteria

The incident may move to Lessons Learned only when:

- no active attacker access remains;
- compromised credentials are revoked/rotated;
- clean application capacity is available;
- database integrity is validated;
- expected Security Group restrictions are restored;
- critical monitoring is functioning;
- the DPO has the information required for regulatory decisions;
- clinical/business owners accept service restoration.

---

## 8. ICO 72-Hour Notification Chain

Where the breach is likely to result in a risk to individuals' rights and freedoms, MediCore as Data Controller follows this chain:

| Time | Responsible role | Channel | Required action / information |
|---|---|---|---|
| **T+0** | Incident Lead | Incident record + Teams | Personal-data breach identified; 72-hour clock starts; record nature, scope, affected components and evidence |
| **T+2h** | Incident Lead | Teams / direct phone | Notify CTO and DPO; provide initial scope, affected records/data, clinical impact and containment status |
| **T+8h** | DPO | Teams / incident record | Complete documented risk assessment: HIGH / MEDIUM / LOW; decide Article 33 and possible Article 34 applicability |
| **T+24h** | DPO | ICO reporting service — draft | Prepare ICO notification using known facts; explicitly mark unknown facts as investigation ongoing |
| **T+48h** | CTO | Approved secure NHS Trust channel | Notify affected NHS Trust contacts of clinical/service impact, contingency, recovery status and next update |
| **By T+72h** | DPO | ICO reporting service | Submit Article 33 notification if threshold is met, even if investigation remains incomplete; provide supplementary information later |
| **Without undue delay where high risk** | DPO + CTO | Approved patient communication route | Article 34 communication to affected individuals unless an applicable exception is documented |

---

## 9. ICO Notification Template — Ransomware Scenario

**Controller:** MediCore Health Systems  
**Incident:** Ransomware affecting clinical patient records  
**Detection / awareness time:** 03:14 [incident date]  
**Regulatory status:** Initial Article 33 notification — investigation ongoing where stated

### Nature of the personal data breach

At 03:14, MediCore identified ransomware activity affecting its clinical cloud environment. The incident resulted in the encryption and temporary unavailability and/or loss of integrity of approximately **47,000 patient records**. The affected information includes health information and is therefore **Special Category personal data under UK GDPR Article 9**.

### Categories and approximate number of data subjects / records

- Data subjects: patients whose records are held within the affected clinical dataset.
- Approximate records affected: **47,000**.
- Categories may include NHS-identifying information and clinical/health information.
- The investigation is continuing to establish whether confidentiality was also compromised through unauthorised data access or exfiltration.

### Likely consequences

Potential consequences include:

- temporary loss of availability of clinical information;
- possible corruption or alteration of information used for patient care;
- risk of inappropriate disclosure if the attacker accessed or exfiltrated records;
- disruption to clinical workflows and NHS Trust services;
- distress and privacy harm to affected patients.

### Measures taken or proposed

MediCore has:

- activated this Incident Response Plan;
- preserved CloudWatch and authentication evidence before containment actions;
- isolated affected resources and restricted suspected compromised access;
- engaged the Incident Lead, CTO and DPO;
- begun root-cause and ransomware-scope investigation;
- begun clean rebuild of affected application resources;
- identified RDS backup / PITR recovery options;
- begun validation of restored clinical data before service reintroduction;
- initiated credential review and rotation where exposure is suspected;
- begun assessment of whether Article 34 direct communication to affected individuals is required.

**Further information:** Investigation ongoing. MediCore will provide supplementary information to the ICO as material facts are confirmed.

**DPO contact:** [Insert MediCore DPO contact details before production use]

---

## 10. Stakeholder Communications

### 10.1 T+2h — Incident Lead to CTO

**Subject: SEV-1 MediCore ransomware incident — executive authorisation required**

At 03:14 we identified ransomware affecting approximately 47,000 MediCore patient records, creating a potential Special Category personal-data breach and starting the Article 33 72-hour assessment timeline. Evidence preservation and technical containment are in progress, with application and database recovery being assessed. Please authorise SEV-1 business-continuity actions and NHS Trust contingency coordination while the DPO completes the regulatory risk assessment.

### 10.2 T+24h — DPO to ICO

10.2 T+24h — DPO to ICO

Article 33 notification draft

Organisation / Controller: MediCore Health Systems
DPO: MediCore Data Protection Officer
Incident: Ransomware affecting clinical patient records
Awareness time: 03:14 [incident date]

MediCore Health Systems identified ransomware affecting its AWS-hosted clinical environment. Approximately 47,000 patient records have been encrypted, causing loss of availability and potential loss of integrity; the affected information includes clinical/health information and is therefore Special Category personal data under UK GDPR Article 9.

Categories and approximate number affected: approximately 47,000 patient records, potentially including NHS-identifying information and clinical/health information. Investigation is ongoing to determine whether confidentiality was also compromised through unauthorised access or exfiltration.

Likely consequences: temporary loss of access to clinical information, possible corruption of information used for patient care, disruption to NHS Trust services, and potential confidentiality and privacy harm if records were accessed or exfiltrated.

Measures taken: MediCore preserved available monitoring and authentication evidence before containment, isolated affected resources, restricted suspected compromised access, initiated clean application-tier rebuild and RDS recovery assessment, began credential review/rotation, and commenced assessment of whether Article 34 communication to affected individuals is required.

Current status: Investigation ongoing. Confirmed supplementary information will be provided to the ICO as it becomes available.

### 10.3 T+48h — CTO to NHS Trust Contacts

**Subject: MediCore security incident — clinical service update**

MediCore is responding to a ransomware incident affecting part of the clinical environment, with approximately 47,000 patient records under investigation. The application and database recovery process is using clean application instances and validated RDS recovery data; clinical teams should continue the agreed contingency process during any period of reduced availability. We will provide the next confirmed impact and recovery update within 24 hours, or sooner if there is a material change.

---

## 11. Lessons Learned — NCSC Phase 6

A formal post-incident review must take place after service stabilisation. Findings must update the B3 Risk Register and this IRP.

Following the post-incident review, the Incident Lead will update each affected B3 Risk Register entry to reflect the confirmed root cause, revised likelihood and impact, resulting risk rating, effectiveness of existing controls, additional mitigation actions, control owner, target date and new incident evidence.

### Improvement 1 — Strengthen RDS resilience

- **B3 Risk:** R03 — RDS loss/corruption.
- **Finding:** Single-AZ and one-day backup retention increase recovery risk after ransomware or corruption.
- **Improvement:** production Multi-AZ RDS; automated backup retention of at least seven days; scheduled restore/PITR testing.
- **Compliance link:** UK GDPR Art. 32(1)(c) — ability to restore availability and access following an incident; Art. 32(1)(d) — regular testing/evaluation.

### Improvement 2 — Strengthen privileged change control

- **B3 Risks:** R04 — Security Group/routing misconfiguration; R07 — administrator configuration error.
- **Finding:** a mistaken or malicious privileged change could expose clinical resources or weaken containment.
- **Improvement:** peer review for privileged IAM/SG changes, documented change record, least-privilege administration and periodic configuration review.
- **Compliance link:** UK GDPR Art. 32(1)(b) confidentiality/integrity; NHS DSPT staff-security / governance requirements reflected in B3.

### Improvement 3 — Reduce credential-compromise risk

- **B3 Risk:** R08 — phishing/credential disclosure; also supports R01 and R02.
- **Finding:** ransomware frequently depends on compromised credentials or initial unauthorised access.
- **Improvement:** recurring phishing awareness exercises, rapid suspicious-message reporting, credential rotation procedures, review of least-privilege role assignments and stronger authentication controls where available.
- **Compliance link:** UK GDPR Art. 32(1)(b); DSPT training and awareness controls identified in the B3/B6 work.

### Post-Incident Review Outputs

The Incident Lead must record:

- incident chronology;
- alerts that fired and alerts that did not;
- detection-to-containment time;
- clinical/service downtime;
- recovery point and recovery time;
- confirmed number/categories of records affected;
- ICO/NHS/patient communications;
- root cause;
- controls that failed or succeeded;
- updated B3 risk scores;
- assigned remediation owners and due dates;
- IRP version update.

---

## 12. Evidence and Accountability

The following assignment evidence supports this IRP:

- **A2-87:** five CloudWatch alarms and verified thresholds — ALB unhealthy hosts >= 1, App CPU >= 80%, App status check failed >= 1, Failed SSH login attempts >= 3, RDS CPU >= 80%;
- **A2-88:** Failed SSH Login Security Alarm;
- **A2-89:** Failed SSH CloudWatch metric filter;
- **A2-90:** Bastion authentication log retention;
- **A2-91–93 / A2-110–119:** encryption and HTTPS/TLS evidence;
- **A3-108 / A3-112–124:** ALB, ASG, multi-AZ application resilience and EC2 failure/recovery;
- **A1-60 / A1-65 / A1-67 / A3-125–127:** RDS backup, PITR and resilience evidence;
- **A4 vulnerability evidence:** Trivy and Grype before/after remediation;
- **A6:** EC2 CPU and failed-SSH monitoring analysis;
- **B3:** R01–R08 security risks;
- **B5:** UK GDPR Article 32(1)(b), 32(1)(c), 32(1)(d) and Article 33 — security, resilience, recovery, regular testing, and 72-hour personal data breach notification compliance mapping
