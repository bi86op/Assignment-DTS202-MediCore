# MediCore Health Systems

**Incident Response Plan (IRP)**

**Document:** MediCore-IRP-v1.md  
**Version:** 1.0  
**Date:** 28 August 2026  
**Owner / Named Incident Lead:** Aurora Serban — Lead Cloud Security Architect  
**AWS Region:** Europe (London), eu-west-2  
**Classification:** Internal / Security & Compliance  
**Review cycle:** After every significant security incident and at least annually  

**Deployment-specific note:** This IRP is aligned with MediCore's
deployed AWS infrastructure. The five deployed CloudWatch alarm names,
metrics, namespaces, comparison operators and thresholds were verified
against evidence screenshot **A2-87** using the AWS CLI cloudwatch
describe-alarms output.

# 1. Purpose and Scope

This Incident Response Plan (IRP) defines how MediCore Health Systems
will prepare for, identify, contain, eradicate, recover from and learn
from security incidents affecting its clinical cloud environment. Its
purpose is to protect the confidentiality, integrity and availability of
MediCore's clinical information and supporting services, while providing
a consistent technical, management and regulatory response to suspected
or confirmed security incidents.

The plan follows the NCSC six-phase incident-response lifecycle and
applies specifically to MediCore's deployed AWS infrastructure:

- VPC in eu-west-2 using public, private application and restricted
  database subnets across three Availability Zones;

- internet-facing Application Load Balancer (ALB);

- Auto Scaling Group (ASG) with minimum 2, desired 2 and maximum 4
  application EC2 instances;

- medicore-bastion host used for controlled administrative SSH access;

- Amazon RDS for PostgreSQL, encrypted and not publicly accessible;

- current RDS configuration of Single-AZ with one-day automated backup
  retention, with Multi-AZ deployment and extended backup retention
  identified as production remediation requirements;

- private Amazon S3 clinical-data bucket with SSE-S3/AES-256 encryption
  and Block Public Access enabled;

- AWS CloudWatch metrics, alarms and bastion authentication logs;

- least-privilege IAM roles for Clinical Read Only, Clinical Write,
  Database Administrator, Monitoring Read Only and Backup Operator;

- HTTPS/TLS at the ALB and tier-to-tier Security Group restrictions.

The IRP supports MediCore's security-of-processing obligations under
**UK GDPR Article 32(1)(a)–(d)**. Specifically, **Article 32(1)(a)** is
supported by encryption controls, including encrypted Amazon RDS
storage, SSE-S3/AES-256 protection for the clinical-data bucket and
HTTPS/TLS for data in transit. **Article 32(1)(b)** is addressed through
controls supporting the ongoing confidentiality, integrity, availability
and resilience of processing systems and services, including
least-privilege IAM, Security Group restrictions, ALB health monitoring
and Auto Scaling. **Article 32(1)(c)** is addressed through the ability
to restore availability and access following an incident, including
clean application-instance rebuilds and Amazon RDS automated backup and
point-in-time recovery (PITR). **Article 32(1)(d)** is addressed through
the regular testing, assessment and evaluation of security measures,
including CloudWatch monitoring and alarm review, vulnerability scanning
and recovery testing.

For personal data breaches, this IRP supports **UK GDPR Article 33(1)**
by requiring MediCore to record **T+0 at the point at which it becomes
aware that a personal data breach has occurred** and, where the breach
is not unlikely to result in a risk to individuals' rights and freedoms,
to notify the Information Commissioner's Office (ICO) without undue
delay and, where feasible, no later than **72 hours after becoming aware
of the breach**. The notification process also addresses **Article
33(3)** by documenting the nature of the personal data breach, the
categories and approximate number of affected data subjects and personal
data records, Data Protection Officer contact details, the likely
consequences of the breach, and the measures taken or proposed to
address and mitigate its effects. Where a personal data breach is likely
to result in a high risk to affected individuals, the IRP also provides
for assessment and communication under **UK GDPR Article 34**.

The IRP is intended for use by MediCore technical staff, the Incident
Lead, senior management and the Data Protection Officer during the
management of suspected or confirmed security incidents. It should be
reviewed following any significant security incident or material
infrastructure change, and at least annually. Lessons learned from
incidents must be incorporated into the **B3 Security Risk Register**
and used to update relevant technical and organisational security
controls.

**2. Incident Roles, Escalation and Decision Authority**

Incident coordination must use **Microsoft Teams or direct phone for
urgent internal escalation, not ordinary email**, because email may be
unavailable or compromised during a security incident. All significant
decisions, actions and escalation times must be recorded in the incident
log maintained by the Incident Lead.

| **Role**                        | **Named person / owner**                         | **Primary channel**          | **Response SLA**                                                                                                                                                            | **Decision authority**                                                                           |
|---------------------------------|--------------------------------------------------|------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| Incident Lead                   | **Aurora Serban**, Lead Cloud Security Architect | Teams / phone                | Within 15 minutes of a security alert requiring investigation                                                                                                               | Declare incident; coordinate technical response; authorise evidence preservation and containment |
| CTO                             | Chief Technology Officer                         | Teams / phone                | Within 2 hours of incident declaration (T+2h for the ransomware scenario)                                                                                                   | Business continuity, major service decisions, NHS Trust executive communication                  |
| DPO                             | MediCore Data Protection Officer                 | Direct phone / Teams         | Within 2 hours of incident declaration (T+2h); risk assessment completed by T+8h                                                                                            | Determine personal-data-breach risk; lead ICO and Article 34 decisions                           |
| Cloud / Infrastructure Engineer | On-call infrastructure engineer                  | Teams / phone                | Within 15 minutes of Incident Lead instruction                                                                                                                              | Preserve logs, isolate resources, rebuild EC2, verify ALB/ASG health                             |
| Database Administrator          | db-admin role holder                             | Teams / phone                | Within 30 minutes of Incident Lead instruction                                                                                                                              | RDS containment, backup/PITR verification, restore and integrity checks                          |
| Monitoring Analyst              | monitoring-only role holder                      | Teams                        | Within 15 minutes of a CloudWatch security or availability alert                                                                                                            | CloudWatch investigation, timeline and alert correlation                                         |
| Backup Operator                 | backup-operator role holder                      | Teams                        | Within 30 minutes of Incident Lead instruction                                                                                                                              | Backup verification and recovery support                                                         |
| NHS Trust contacts              | Per contract                                     | Secure approved channel      | Initial communication by T+48h for the ransomware scenario, or earlier where clinical impact or contractual requirements require it; updates every 24 hours during recovery | Receive service/clinical impact and continuity updates                                           |
| ICO Regulatory Contact          | Information Commissioner's Office                | ICO breach-reporting service | Notification without undue delay and, where feasible, within 72 hours of T+0 where the Article 33 notification threshold is met                                             | Receive the Article 33 personal-data-breach notification submitted by the DPO                    |

**2.1 Escalation Chain**

A CloudWatch alert or other suspected security event is initially
assessed by the **Monitoring Analyst and Incident Lead**. Where
investigation indicates compromise, ransomware, unauthorised access,
loss of integrity or availability, or potential exposure of clinical
information, the Incident Lead classifies the incident and coordinates
the appropriate technical response.

For a suspected personal data breach, the **CTO and DPO must be notified
via Microsoft Teams or direct phone within T+2 hours of incident
declaration**. The DPO performs the personal-data-breach risk assessment
by **T+8 hours**. Where the UK GDPR Article 33(1) notification threshold
is met, an ICO notification containing the information required by
Article 33(3) is drafted by T+24 hours and submitted without undue delay
and, where feasible, no later than T+72 hours from T+0. If the
investigation is incomplete, the notification is submitted with the
available information, with outstanding details identified as
“investigation ongoing” and provided subsequently in accordance with
Article 33(4).

For the ransomware scenario used in this IRP, ransomware activity begins
on **28 August 2026 at 03:14** and encrypts approximately **47,000
patient records**. The time at which MediCore confirms that this event
constitutes a personal data breach is recorded separately as **T+0**. In
accordance with **UK GDPR Article 33(1)**, T+0 marks the start of the
72-hour period for notifying the Information Commissioner's Office
(ICO), where the breach is not unlikely to result in a risk to the
rights and freedoms of individuals. The 72-hour period therefore begins
when MediCore becomes aware of the personal data breach, rather than
automatically when the ransomware activity begins or when senior
management is subsequently informed.

**2.2 Severity Classification**

- **SEV-1 — Critical:** confirmed compromise of patient or clinical
  data; ransomware; widespread clinical-service outage; loss or
  corruption of RDS data; or confirmed privileged-account compromise.
  Immediate Incident Lead coordination and executive/DPO escalation are
  required.

- **SEV-2 — High:** credible unauthorised-access attempt; repeated
  security alerts supported by evidence of attempted compromise;
  ALB/application outage affecting clinical access; or a serious
  security misconfiguration requiring urgent containment.

- **SEV-3 — Medium:** isolated alarm with no confirmed compromise;
  degraded application or database performance; or a contained
  operational security issue requiring investigation.

- **SEV-4 — Low:** informational event, expected activity or false
  positive requiring review and documentation but no immediate
  containment.

The ransomware scenario affecting approximately **47,000 patient
records** is classified as a **SEV-1 Critical incident**.

**3. NCSC Six-Phase Incident Response Lifecycle**

The following sections apply the NCSC six-phase incident-response
lifecycle to MediCore Health Systems' deployed AWS clinical environment.
Each phase defines the actions, escalation requirements and recovery
procedures applicable to the specific AWS components and monitoring
controls evidenced in the MediCore deployment. The lifecycle consists of
Preparation, Identification, Containment, Eradication, Recovery and
Lessons Learned.

**3.1 Phase 1 – Preparation**

MediCore must maintain readiness before an incident occurs.

**3.1.1 Preventive and Detective Controls**

The deployed environment uses:

- Security Groups restricting:

\- Bastion SSH 22 to the authorised administrator IP;

\- application HTTP 80 to the ALB Security Group;

\- application SSH 22 to the Bastion Security Group;

\- PostgreSQL 5432 to the Application Security Group;

- RDS encryption at rest;

- S3 SSE-S3/AES-256 and Block Public Access;

- HTTPS/TLS at the ALB;

- five least-privilege IAM roles;

- ALB + ASG across three Availability Zones for application-tier
  resilience;

- CloudWatch alarms and bastion authentication logging;

- Trivy and Grype vulnerability scanning for the container image;

- GitHub version control for infrastructure, Docker, Kubernetes,
  analysis and compliance evidence.

  **3.1.2 Five Deployed CloudWatch Alerts**

The deployed architecture confirms the following five alarm names.

<table>
<colgroup>
<col style="width: 18%" />
<col style="width: 21%" />
<col style="width: 10%" />
<col style="width: 14%" />
<col style="width: 14%" />
<col style="width: 7%" />
<col style="width: 13%" />
</colgroup>
<thead>
<tr class="header">
<th><strong>Alert</strong></th>
<th><strong>Metric / signal</strong></th>
<th><strong>Threshold</strong></th>
<th><strong>IRP trigger</strong></th>
<th><strong>Notify</strong></th>
<th><strong>SLA</strong></th>
<th><strong>Immediate action</strong></th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><p><strong>medicore-app-high-cpu</strong></p>
<p>(<strong>App High CPU</strong>)</p></td>
<td>CPUUtilization — AWS/EC2</td>
<td>≥ 80%</td>
<td>Phase 2 -Identification</td>
<td>Monitoring Analyst + Incident Lead</td>
<td>15 min</td>
<td>Correlate CPU rise with traffic, processes, ALB and ASG activity;
determine whether capacity pressure or malicious workload is
suspected.</td>
</tr>
<tr class="even">
<td><p><strong>medicore-app-status-check-failed</strong></p>
<p><strong>(App Status Check Failure)</strong></p></td>
<td>StatusCheckFailed — AWS/EC2</td>
<td><strong>≥ 1</strong></td>
<td>Phase 2; escalate to Phase 3 if instance is
unhealthy/compromised</td>
<td>Incident Lead + Cloud Infrastructure Engineer</td>
<td>15 min</td>
<td>Preserve evidence before changes; determine whether the instance is
unhealthy, compromised or requires clean replacement through the
ASG.</td>
</tr>
<tr class="odd">
<td><p><strong>medicore-alb-unhealthy-hosts</strong></p>
<p><strong>(ALB Unhealthy Hosts)</strong></p></td>
<td>UnHealthyHostCount — AWS/ApplicationELB</td>
<td><strong>≥ 1</strong></td>
<td>Phase 2 - Identification</td>
<td>Cloud Infrastructure Engineer + Incident Lead</td>
<td>15 min</td>
<td>Check target-group health, application availability and ASG
capacity; preserve relevant evidence before recovery action.</td>
</tr>
<tr class="even">
<td><p><strong>medicore-rds-high-cpu</strong></p>
<p><strong>(RDS High CPU)</strong></p></td>
<td>CPUUtilization — AWS/RDS</td>
<td><strong>≥ 80%</strong></td>
<td>Phase 2; SEV-1 if clinical availability or malicious activity is
suspected</td>
<td>DBA + Incident Lead</td>
<td>15 min</td>
<td>Review RDS metrics/connections, preserve logs, restrict compromised
credentials if required</td>
</tr>
<tr class="odd">
<td><p><strong>medicore-failed-ssh-login-attempts</strong></p>
<p><strong>(Failed SSH Attempts)</strong></p></td>
<td>FailedSSHLoginCount from Bastion Authentication log group</td>
<td><strong>≥ 3</strong></td>
<td>Phase 2 Security Identification</td>
<td>Incident Lead + Monitoring Analyst</td>
<td>5 min</td>
<td>Preserve bastion auth logs, identify source/time pattern, confirm no
successful unauthorised session, review credentials and SG
restriction</td>
</tr>
</tbody>
</table>

**Assignment evidence link:** A2-87 documents the five CloudWatch
alarms; A2-88–90 document Failed SSH monitoring. A6 uses EC2 CPU
utilisation and failed SSH attempts as monitoring-analysis evidence.

## **Critical Escalation Rule**

Where investigation of any of the five A2 monitoring alerts indicates
ransomware, unauthorised access, compromise of clinical data or another
suspected security incident, the Incident Lead will escalate the event
from Identification to the appropriate containment response. If
investigation confirms that a personal data breach has occurred, **T+0**
is recorded at the point MediCore becomes aware of that breach and the
**UK GDPR Article 33 72-hour notification period** begins.

**3.2 Phase 2 – Identification**

The purpose of the Identification phase is to determine whether a
CloudWatch alert or other suspected security event represents a genuine
security incident, establish its scope and severity, identify the
affected MediCore components, and determine whether personal data has
been compromised.

**3.2.1 Incident Identification and Validation**

A CloudWatch alarm does not automatically constitute a security incident
or personal data breach. The **Monitoring Analyst and Incident Lead**
must investigate the triggering event and determine whether it
represents:

- a false positive;

- an operational or availability incident;

- a security incident; or

- a personal data breach.

The investigation must correlate the relevant deployed CloudWatch alarm
and metric with available evidence from the affected MediCore
components. This includes **bastion authentication logs, EC2 and ALB
health and availability metrics, RDS metrics, recent IAM or Security
Group changes, application availability, and other relevant evidence
available within the deployed environment**.

 The five deployed CloudWatch alarms are interpreted as follows:

- medicore-app-high-cpu — investigate abnormal EC2 CPU utilisation and determine whether it results from legitimate workload, denial-of-service activity or malicious execution;
- medicore-app-status-check-failed — investigate application EC2 health and determine whether the failure is operational or associated with compromise;
- medicore-alb-unhealthy-hosts — investigate target health, application availability and ASG capacity to determine the cause of unhealthy application instances;
- medicore-rds-high-cpu — investigate abnormal RDS CPU utilisation, database availability and connection behaviour for evidence of malicious or unauthorised activity;
- medicore-failed-ssh-login-attempts — preserve and review bastion authentication evidence to determine the source, timing and pattern of repeated failed SSH authentication attempts.
  
The Incident Lead records the affected AWS resources, alarm or detection source, suspected attack vector, evidence available, initial scope, severity classification and actions authorised.

 
**3.2.2 Ransomware Scenario and Incident Classification**

For the scenario assessed in this IRP, ransomware activity begins on 28 August 2026 at 03:14 and encrypts approximately 47,000 MediCore patient records.
The Incident Lead correlates the relevant CloudWatch alarms, authentication evidence and affected application/database behaviour to establish the nature and scope of the incident. Because the incident involves ransomware affecting clinical patient information and may affect the confidentiality, integrity and availability of Special Category health data, it is classified as a SEV-1 Critical security incident.
The incident immediately proceeds to Phase 3 - Containment, subject to the requirement that forensic evidence is preserved before containment changes are made wherever safely possible.

**3.2.3 T+0 — Start of the UK GDPR Article 33 Notification Period**

The ransomware activity time of 03:14 on 28 August 2026 is not automatically T+0.
For this IRP, T+0 is the point at which MediCore becomes aware that a personal data breach has occurred. Once the investigation confirms that the ransomware incident constitutes a personal data breach, the Incident Lead records that confirmed awareness time as T+0.
In accordance with UK GDPR Article 33(1), T+0 starts the 72-hour period for notifying the Information Commissioner's Office (ICO), where the personal data breach is not unlikely to result in a risk to the rights and freedoms of individuals. The notification period therefore begins when MediCore becomes aware of the personal data breach, not when senior management is subsequently informed.
At T+0, the Incident Lead records:
- date and time of confirmed breach awareness;
- detection source and CloudWatch alarm(s) involved;
- affected MediCore AWS resources;
- incident type and suspected attack vector;
- categories of personal data potentially affected;
- approximate number of affected data subjects and personal data
  records;
- confidentiality, integrity and availability impact;
- current containment status;
- severity classification;
- person making the breach determination; and
- calculated **T+72 ICO notification deadline**.

**3.2.4 Immediate Escalation Following Identification**

Following confirmation of a suspected or actual personal data breach,
the Incident Lead must notify the **CTO and DPO via Microsoft Teams or
direct phone within T+2 hours**.

The escalation must include the incident type, affected AWS components,
approximate number and categories of patient records affected, current
clinical/service impact, evidence preserved, immediate containment
actions proposed or taken, and the calculated Article 33 notification
deadline.

The DPO must complete the initial personal-data-breach risk assessment
by **T+8 hours**, classifying the regulatory risk as **HIGH, MEDIUM or
LOW** and determining whether the **UK GDPR Article 33(1)** notification
threshold is met.

**3.3 Phase 3 - Containment**

The purpose of containment is to prevent further compromise, protect
clinical service availability and stop the incident spreading while
preserving the evidence required for forensic investigation and
regulatory review.

**3.3.1 Evidence Preservation**

**Critical forensic rule: all available logs and forensic evidence must
be preserved before any containment action wherever safely possible.
Configuration changes, instance termination, credential revocation or
rotation, and recovery actions may alter or destroy evidence needed to
establish the attack path, scope and breach timeline.**

Before isolation or remediation, the Incident Lead and Cloud /
Infrastructure Engineer must:

1.  record the incident timestamp, T+0 where established, and the
    CloudWatch alarm(s) involved;

2.  export or preserve relevant CloudWatch metrics, alarm state and
    available logs;

3.  preserve medicore-bastion authentication logs and
    FailedSSHLoginCount evidence;

4.  record the affected EC2 instance IDs, ALB/target-group state and
    relevant RDS identifiers;

5.  record the current Security Group and routing configuration;

6.  record recent relevant IAM, Security Group and infrastructure
    changes;

7.  preserve relevant application and database evidence available for
    the incident;

8.  where practical and appropriate, create an EBS snapshot or forensic
    copy of an affected EC2 volume before rebuild;

9.  restrict access to preserved evidence to authorised
    incident-response personnel; and

10. record who collected each item of evidence, when it was collected
    and where it is securely retained.

Only after the required evidence has been preserved should technical
containment begin, unless delaying containment would create an
unacceptable risk to clinical services or further patient-data
compromise. Any emergency action taken before full evidence preservation
must be documented by the Incident Lead.

**3.3.2 Short-Term Containment**

Containment actions depend on the affected MediCore component.

**Compromised application EC2 instance**

- remove or isolate the affected instance from normal service without
  destroying preserved evidence;

- restrict network access using the relevant Security Group;

- prevent the suspected compromised instance from serving traffic
  through the ALB;

- allow the ASG and remaining known-healthy instances to maintain
  service where possible; and

- do not reuse the suspected compromised instance.

**Compromised bastion / repeated SSH activity**

- preserve the bastion authentication logs first;

- confirm that SSH port 22 remains restricted to the authorised
  administrative source;

- revoke or rotate suspected credentials only after the relevant
  authentication evidence has been preserved;

- review the source and pattern of the failed authentication attempts;
  and

- block confirmed unauthorised access paths using the approved access
  controls.

**Suspected RDS compromise or ransomware impact**

- preserve available RDS metrics, connection information and relevant
  database evidence;

- prevent compromised application or IAM credentials from continuing to
  access the database;

- do not overwrite the affected database with a restore until the
  required evidence and an appropriate recovery point have been
  identified; and

- restrict database access to the application tier and authorised
  administrative functions.

**Suspected S3 exposure**

- preserve available access and configuration evidence;

- confirm that S3 Block Public Access remains enabled;

- record any unintended policy or ACL configuration before correcting
  it;

- remove confirmed unintended public access only after the relevant
  configuration has been recorded; and

- review the relevant IAM permissions associated with the exposure.

**3.3.3 Business Continuity During Containment**

The **ALB and ASG** should maintain application availability through
remaining known-healthy application instances wherever possible. If
clinical-service availability is materially affected, the Incident Lead
and CTO authorise the appropriate business-continuity response and the
three NHS Trust contacts are informed in accordance with the stakeholder
communication timeline.

Containment is complete only when the immediate spread of the incident
has been stopped, affected resources are controlled, required forensic
evidence has been preserved and the Incident Lead authorises progression
to eradication.

**3.4 Phase 4 - Eradication**

The purpose of eradication is to remove the attacker's persistence,
eliminate the identified root cause and return affected components to a
known-trusted configuration rather than simply restarting compromised
resources.

**3.4.1 Determine the Root Cause**

The Incident Lead and technical response team investigate the evidence
collected during Identification and Containment and map the confirmed
cause to the relevant B3 Security Risk Register entry. Potential causes
include:

- repeated failed SSH attempts or unauthorised administrative access -
  **R01**;

- compromised or inappropriate application access - **R02**;

- RDS data loss, corruption or ransomware impact - **R03**;

- Security Group or routing misconfiguration - **R04**;

- EC2 or Availability Zone failure contributing to service disruption -
  **R05**;

- unintended S3 exposure - **R06**;

- administrative configuration error - **R07**; and

- phishing or credential disclosure - **R08**.

The root cause, affected assets, attack vector, compromised credentials
and exploited configuration must be documented in the incident record
before the environment is returned to normal operation.

**3.4.2 Clean Rebuild of the Application Tier**

For MediCore's deployed **ALB/Auto Scaling Group architecture**, a
compromised web/application EC2 instance must not be cleaned and
returned directly to production. The recovery approach is to replace it
with a new instance created from the **known-clean AMI referenced by the
ASG Launch Template**.

For a compromised application EC2 instance:

1.  confirm that the required forensic evidence has been preserved;

2.  remove the compromised instance from service;

3.  identify and remediate the initial attack vector or vulnerable
    configuration;

4.  patch or update the source image and Launch Template configuration
    where required;

5.  rebuild the application instance from the known-clean AMI referenced
    by the Launch Template;

6.  build and scan the application container using **Trivy and Grype**;

7.  confirm **zero CRITICAL vulnerabilities** before release;

8.  deploy the replacement through the **Auto Scaling Group**;

9.  verify that the replacement target becomes healthy behind the
    **Application Load Balancer**; and

10. rotate any credentials or secrets potentially exposed during the
    incident.

The compromised EC2 instance must not be reused as the recovery source.

**3.4.3 Remove Configuration and Access Weaknesses**

Where the incident involves Security Groups, IAM or administrative
configuration:

- compare Security Group rules against the approved three-tier
  architecture;

- restore tier-to-tier restrictions;

- confirm application SSH access is permitted only through the
  bastion-controlled path;

- confirm PostgreSQL port 5432 remains restricted to the application
  tier;

- confirm RDS remains non-public;

- confirm the restricted database subnets have no direct Internet route;

- review relevant IAM permissions against least privilege;

- remove or rotate compromised credentials and access paths; and

- document each emergency change in the incident record.

Eradication is complete only when the identified attack vector has been
removed, compromised resources have been replaced or remediated, exposed
credentials have been addressed and no known attacker persistence
remains.

**3.5 Phase 5 - Recovery**

The purpose of recovery is to restore MediCore's clinical services to a
trusted operational state while preventing reinfection or restoration of
compromised data.

**3.5.1 Application Recovery**

Before normal application traffic is restored:

1.  confirm the required ASG application instances are running;

2.  confirm the replacement EC2 targets pass ALB health checks;

3.  test the application endpoint and /health behaviour;

4.  confirm expected HTTPS/TLS access;

5.  monitor medicore-app-high-cpu, medicore-app-status-check-failed and
    medicore-alb-unhealthy-hosts for signs of recurring compromise or
    instability; and

6.  restore normal service only after the Incident Lead approves the
    technical validation.

**3.5.2 RDS Recovery**

The deployed MediCore database uses:

- encrypted Amazon RDS for PostgreSQL;

- automated backups;

- Point-in-Time Recovery (PITR);

- **Single-AZ** deployment; and

- **one-day automated backup retention**.

Where ransomware or corruption affects the database, the recovery
procedure is to:

1.  identify the most recent clean recovery point immediately before the
    malicious encryption or corruption;

2.  preserve the required evidence from the affected database before
    restoration;

3.  initiate the appropriate RDS restore/PITR operation to a trusted
    recovery state;

4.  validate database integrity and application connectivity;

5.  confirm the database Security Group continues to permit PostgreSQL
    5432 only from the authorised application tier;

6.  connect the recovered database to the application only after
    validation;

7.  monitor RDS CPU utilisation, database connections and application
    behaviour following restoration; and

8.  record the achieved recovery time, selected recovery point and any
    identified data-loss interval.

The current **Single-AZ configuration and one-day backup retention are
known limitations associated with B3 Risk R03**. Production remediation
is to implement **Multi-AZ RDS** and increase automated backup retention
to **at least seven days**, together with regular restore/PITR testing.

**3.5.3 S3 Recovery**

Where S3 clinical data or configuration is affected:

- verify that **Block Public Access** is enabled;

- verify **SSE-S3/AES-256 encryption** remains enabled;

- restore affected objects only from trusted backups or versions where
  such recovery data is available;

- revalidate bucket policies, ACLs and IAM permissions; and

- verify that no unintended public access remains.

**3.5.4 Recovery Exit Criteria**

Recovery is complete only when:

- no known active attacker access or persistence remains;

- compromised credentials have been revoked or rotated;

- replacement application instances are healthy behind the ALB;

- database integrity and connectivity have been validated;

- Security Group and IAM restrictions have been verified;

- required clinical services are available;

- CloudWatch monitoring shows no evidence of recurring compromise; and

- the Incident Lead and CTO approve return to normal operation.

The three NHS Trust contacts must receive recovery updates in accordance
with the communication plan, including the current clinical impact,
service availability, contingency arrangements and the next scheduled
update.

**3.6 Phase 6 - Lessons Learned**

The purpose of the Lessons Learned phase is to identify why the incident
occurred, assess whether MediCore's technical and organisational
controls operated as intended, and convert the findings into measurable
security improvements.

A formal post-incident review should be led by the Incident Lead and
include the CTO, DPO and relevant technical role holders. The review
must examine:

- detection and alert effectiveness;

- accuracy and speed of incident classification;

- evidence preservation;

- containment and eradication effectiveness;

- application and RDS recovery performance;

- effectiveness of the escalation and stakeholder communication process;

- whether the Article 33 timeline and regulatory decisions were
  correctly recorded;

- clinical-service and NHS Trust impact; and

- any control, configuration or process failures identified during the
  incident.

**3.6.1 Update the B3 Security Risk Register**

Every risk affected or revealed by the incident must be updated in the
**B3 Security Risk Register**. For each affected Risk ID, the Incident
Lead records:

1.  the incident evidence and confirmed root cause;

2.  whether the existing likelihood or impact assessment remains
    appropriate;

3.  the revised likelihood and impact where required;

4.  the resulting risk rating;

5.  whether the existing controls operated effectively;

6.  additional mitigation or corrective controls required;

7.  the control owner;

8.  the target implementation date; and

9.  the evidence required to demonstrate that the improvement has been
    implemented and tested.

For the ransomware scenario, the post-incident review produces the
following priority improvements:

**Improvement 1 — Strengthen database resilience and recovery**

- **B3 Risk updated:** R03 - RDS data loss/corruption.

- **Finding:** Single-AZ RDS and one-day backup retention restrict
  resilience and the available recovery window during ransomware or
  data-corruption incidents.

- **Control improvement:** implement Multi-AZ RDS, increase automated
  backup retention to at least seven days and perform scheduled
  restore/PITR testing.

- **Compliance mapping:** **UK GDPR Article 32(1)(c)** — ability to
  restore availability and access to personal data in a timely manner;
  **Article 32(1)(d)** — regular testing, assessment and evaluation of
  security measures; and the relevant NHS DSPT continuity and recovery
  requirements identified in MediCore's compliance mapping.

**Improvement 2 — Strengthen infrastructure privileged change control**

- **B3 Risks updated:** R04 - Security Group/routing misconfiguration;
  R07 - administrative configuration error.

- **Finding:** Emergency or incorrect IAM, Security Group or routing
  changes could expose clinical resources or interfere with containment
  and recovery.

- **Control improvement:** require peer review for security-sensitive
  IAM, Security Group and routing changes; maintain a change record;
  periodically review deployed rules against the approved architecture;
  and retain least-privilege access.

- **Compliance mapping:** **UK GDPR Article 32(1)(b)** - ongoing
  confidentiality, integrity, availability and resilience of processing
  systems and services; **Article 32(1)(d)** - regular assessment and
  evaluation of security measures; and the relevant NHS DSPT governance
  and access-control requirements identified in MediCore's compliance
  mapping.

**Improvement 3 — Reduce credential-compromise risk**

- **B3 Risk updated:** R08 - phishing/credential disclosure; the
  improvement also supports R01 - failed SSH attempts and R02 -
  unauthorised application access.

- **Finding:** Compromised credentials can provide an initial access
  path for ransomware or unauthorised access to clinical systems.

- **Control improvement:** implement recurring phishing-awareness
  exercises, rapid suspicious-message reporting, credential-rotation
  procedures, periodic review of least-privilege role assignments and
  stronger authentication controls where available.

- **Compliance mapping:** **UK GDPR Article 32(1)(b)** - ongoing
  confidentiality, integrity and resilience of processing systems and
  services; and the relevant NHS DSPT staff-security, awareness and
  access-control requirements identified in MediCore's compliance
  mapping.

**3.6.2 IRP and Control Review**

Following the post-incident review:

- this IRP must be updated where response procedures or escalation
  arrangements were ineffective;

- CloudWatch alarm thresholds and response SLAs must be reviewed against
  incident evidence;

- affected B3 Risk Register entries must be updated and re-approved;

- recovery procedures must be retested after corrective changes;

- relevant security evidence must be retained for compliance review; and

- lessons learned must be communicated to the appropriate MediCore
  technical, management and governance stakeholders.

The Incident Lead records completion of the post-incident actions and
ensures that unresolved corrective actions remain tracked until formally
closed.

**4. ICO 72-Hour Notification Chain**

Where a confirmed personal data breach is not unlikely to result in a
risk to the rights and freedoms of individuals, MediCore follows the
notification chain below in accordance with UK GDPR Article 33.

For this IRP, T+0 is the point at which MediCore becomes aware that a
personal data breach has occurred. The ransomware activity at 03:14 on
28 August 2026 is therefore recorded separately from T+0. The Article 33
72-hour notification period begins at confirmed breach awareness, not
automatically when the ransomware activity begins and not when senior
management is subsequently informed.

<table>
<colgroup>
<col style="width: 24%" />
<col style="width: 24%" />
<col style="width: 25%" />
<col style="width: 25%" />
</colgroup>
<thead>
<tr class="header">
<th><strong>Time</strong></th>
<th><strong>Responsible Role</strong></th>
<th><strong>Communication channel</strong></th>
<th><strong>Required action / information</strong></th>
</tr>
</thead>
<tbody>
<tr class="odd">
<td><strong>T+0</strong></td>
<td><strong>Incident Lead</strong></td>
<td>Incident record / Microsoft Teams</td>
<td>Record confirmed personal data breach awareness and start the
72-hour clock. Record breach nature, affected AWS components, categories
and approximate number of affected records/data subjects, evidence
available, clinical impact and current containment status.</td>
</tr>
<tr class="even">
<td><strong>T+2h</strong></td>
<td><strong>Incident Lead</strong></td>
<td>Microsoft Teams / direct phone</td>
<td>Notify the <strong>CTO and DPO</strong>. Provide incident type,
affected components, approximately 47,000 affected patient records,
clinical/service impact, evidence preserved, containment status and
calculated T+72 deadline.</td>
</tr>
<tr class="odd">
<td><strong>T+8h</strong></td>
<td><strong>DPO</strong></td>
<td><table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<tbody>
</tbody>
</table>
<table>
<colgroup>
<col style="width: 100%" />
</colgroup>
<thead>
<tr class="header">
<td>Microsoft Teams / incident record</td>
</tr>
</thead>
<tbody>
</tbody>
</table></td>
<td>Complete and document the personal-data-breach risk assessment as
<strong>HIGH, MEDIUM or LOW</strong> and determine whether the Article
33 notification threshold is met and whether Article 34 must also be
considered.</td>
</tr>
<tr class="even">
<td><strong>T+24h</strong></td>
<td><strong>DPO</strong></td>
<td>ICO breach-reporting service</td>
<td>Prepare the ICO notification using confirmed information available
at that time. Include the Article 33(3) information and clearly identify
unavailable facts as <strong>“investigation ongoing.”</strong></td>
</tr>
<tr class="odd">
<td><strong>T+48h</strong></td>
<td><strong>CTO</strong></td>
<td>Approved secure NHS Trust communication channel</td>
<td>Inform the three affected NHS Trust contacts of clinical/service
impact, current service availability, contingency arrangements, recovery
status and the timing of the next update.</td>
</tr>
<tr class="even">
<td><strong>By T+72h</strong></td>
<td><strong>DPO</strong></td>
<td>ICO breach-reporting service</td>
<td>Submit the Article 33 notification where the notification threshold
is met, even where the investigation remains incomplete. Further
information is supplied subsequently where required.</td>
</tr>
<tr class="odd">
<td>Without undue delay where Article 34(1) high-risk threshold is
met</td>
<td><strong>DPO + CTO</strong></td>
<td>Approved patient communication route</td>
<td>Assess and, where required, communicate the breach to affected
individuals under UK GDPR Article 34, unless an applicable exception is
documented.</td>
</tr>
</tbody>
</table>

**4.1 Article 33 Notification Requirements**

The DPO must ensure that the notification contains, as a minimum, the
information required by UK GDPR Article 33(3):

- the nature of the personal data breach, including where possible the
  categories and approximate number of data subjects and personal data
  records concerned;

- the name and contact details of the DPO or other contact point;

- the likely consequences of the personal data breach; and

- the measures taken or proposed to address the breach, including
  measures intended to mitigate its possible adverse effects.

Where all information cannot be provided at the same time, MediCore will
provide the available information without undue further delay and
provide additional information in phases in accordance with Article
33(4).

**5. ICO Notification Template — Ransomware Scenario**

Organisation / Data Controller: MediCore Health Systems  
Data Protection Officer: MediCore Data Protection Officer  
Incident: Ransomware affecting clinical patient records  
Ransomware activity time: 03:14, 28 August 2026  
T+0 / confirmed breach awareness: \[to be recorded when MediCore
confirms the personal data breach\]  
Regulatory status: Initial UK GDPR Article 33 notification -
investigation ongoing where stated

**5.1 Nature of the Personal Data Breach**

At 03:14 on 28 August 2026, ransomware activity began within MediCore
Health Systems' clinical cloud environment and encrypted approximately
47,000 patient records.

The incident has affected the availability and integrity of clinical
information. MediCore's investigation is continuing to determine whether
the incident also resulted in unauthorised access to or exfiltration of
personal data.

The affected information includes patient health information and
therefore constitutes Special Category personal data under UK GDPR
Article 9.

**5.2 Categories and Approximate Number of Data Subjects / Records**

The affected data subjects are patients whose records are held within
the affected MediCore clinical dataset.

Approximate number of personal data records affected: 47,000.

The affected information includes clinical/health information and may
include NHS-identifying information associated with those records. The
precise categories and scope of any confidentiality impact remain under
investigation.

**5.3 Likely Consequences**

Potential consequences include:

- temporary loss of availability of clinical information;

- possible corruption or alteration of information used for patient
  care;

- disruption to clinical workflows and services provided to MediCore's
  three NHS Trust customers;

- risk of inappropriate disclosure if investigation confirms
  unauthorised access or exfiltration; and

- potential distress, privacy harm or other adverse effects to affected
  patients.

**5.4 Measures Taken or Proposed**

MediCore has:

- activated the Incident Response Plan and classified the ransomware
  incident as SEV-1 Critical;

- preserved relevant CloudWatch, bastion authentication, application and
  database evidence before containment actions wherever safely possible;

- isolated affected resources and restricted suspected compromised
  access;

- engaged the Incident Lead, CTO, DPO and relevant technical responders;

- commenced root-cause and ransomware-scope investigation;

- initiated clean rebuild of affected application EC2 resources using
  the known-clean AMI referenced by the ASG Launch Template;

- assessed Amazon RDS automated backup and PITR recovery options;

- begun validation of restored clinical data before service
  reintroduction;

- initiated review and rotation of potentially compromised credentials;
  and

- commenced assessment of whether direct communication to affected
  individuals is required under UK GDPR Article 34.

**Current status**: Investigation ongoing. MediCore will provide
supplementary information to the ICO as material facts are confirmed.

**6. Stakeholder Communications**

**6.1 T+2h — Incident Lead to CTO**

Subject: SEV-1 MediCore ransomware incident - executive authorisation
required

Dear CTO,

At 03:14 on 28 August 2026, ransomware activity affecting MediCore's
clinical environment resulted in the encryption of approximately 47,000
patient records and was subsequently confirmed as a SEV-1 security
incident following investigation of CloudWatch monitoring and the
affected application and database behaviour. Under UK GDPR Article 33,
the 72-hour notification period started when MediCore confirmed the
personal data breach, meaning the ICO must be notified within 72 hours
of that point. Relevant forensic evidence is being preserved before
containment; please authorise recovery of the application tier using the
approved Launch Template and Auto Scaling Group, assessment and
restoration of RDS using the configured backup/PITR procedures, and
coordination with the affected NHS Trusts while the forensic
investigation continues.

Regards,  
Aurora Serban  
Incident Lead  
MediCore Health Systems

**6.2 T+24h — DPO to ICO (ICO Notification)**

Subject: UK GDPR Article 33 Personal Data Breach Notification - MediCore
Health Systems

**Organisation / Data Controller:** MediCore Health Systems  
**Data Protection Officer:** MediCore DPO  
**Ransomware activity:** 03:14, 28 August 2026  
**Personal data breach confirmed:** \[date and time to be recorded\]  
**Status:** T+24h Draft — Investigation Ongoing

**Nature of the Breach**

At 03:14 on 28 August 2026, a ransomware attack affected MediCore's
clinical environment in AWS London (eu-west-2), encrypting approximately
47,000 patient records. The incident has affected the availability and
integrity of clinical information, while investigation is ongoing to
determine whether any personal data was accessed or exfiltrated.

The affected records contain patient health information, which is
Special Category personal data under UK GDPR Article 9.

**Data and Individuals Affected**

The breach affects approximately 47,000 patient records containing
clinical and health information. The exact number of individual patients
affected and the full categories of personal data involved are still
under investigation.

**Likely Consequences**

The incident may cause temporary loss of access to clinical records,
disruption to MediCore and partner NHS Trust services, and potential
privacy or confidentiality harm if unauthorised access or exfiltration
is confirmed.

**Measures Taken**

MediCore has activated its SEV-1 Incident Response Plan, preserved
relevant CloudWatch, authentication, application and database evidence
before containment, and started forensic investigation and containment.
Recovery of the application tier is being undertaken using the approved
Launch Template and Auto Scaling Group, while RDS backup and PITR
options are being assessed for database recovery and potentially
compromised credentials are being reviewed.

The CTO and DPO have been notified, and MediCore is coordinating with
affected NHS Trusts regarding clinical impact and business continuity.

**DPO Contact**

**Data Protection Officer, MediCore Health Systems**  
\[DPO contact details\]

**Current Status**

The investigation remains ongoing. Any information not available at the
time of the initial notification will be provided to the ICO without
undue further delay in accordance with UK GDPR Article 33(4).

**6.3 T+48h — CTO to NHS Trust Contacts**

Subject: MediCore security incident - clinical service update

Dear NHS Trust Colleagues,

MediCore Health Systems is responding to a ransomware incident affecting
part of our clinical environment. Approximately 47,000 patient records
have been encrypted, resulting in temporary disruption to clinical
information services; there is currently no confirmed evidence of data
exfiltration, but the forensic investigation remains ongoing.

Service availability has been affected since 03:14 on 28 August
2026, and the time for full restoration is not yet confirmed.
Recovery of the application and database services is underway using
clean application instances and validated RDS recovery data, with
integrity and security checks required before normal service is
restored.

MediCore is managing its regulatory notification obligations in
accordance with UK GDPR Article 33. Until services are fully restored,
affected clinical teams should continue to follow their established
business continuity and contingency procedures.

The next update on clinical impact and recovery will be provided within
24 hours, or sooner if there is a significant change.

Thank you for your continued cooperation.

Yours faithfully,  
Chief Technology Officer  
MediCore Health Systems



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

## Evidence and Accountability

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
