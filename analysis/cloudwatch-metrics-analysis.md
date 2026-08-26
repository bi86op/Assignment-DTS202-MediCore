# A6 – CloudWatch Metrics Analysis

## 1. Purpose

This analysis evaluates monitoring data collected from the MediCore AWS
environment using Amazon CloudWatch. The purpose is to examine infrastructure
performance, resource utilisation and security-related activity using
quantitative evidence exported from CloudWatch.

The analysis uses five CloudWatch datasets:

- EC2 Auto Scaling Group CPUUtilization
- RDS CPUUtilization
- RDS DatabaseConnections
- RDS FreeStorageSpace
- Custom FailedSSHLoginCount security metric

The monitoring period primarily covers 19–26 August 2026. The
FailedSSHLoginCount dataset covers a shorter period from 19–21 August 2026.

---

## 2. Methodology

CloudWatch metrics were exported as CSV files and analysed using descriptive
statistics. For each dataset, the number of available observations, mean,
median, minimum, maximum and standard deviation were examined.

CPU utilisation is expressed as a percentage. RDS FreeStorageSpace is
reported by CloudWatch in bytes and is also interpreted in approximate GB
for readability.

The datasets do not all use the same sampling interval. RDS metrics were
exported using a 60-second period, while the EC2 Auto Scaling Group CPU metric
and FailedSSHLoginCount use a 300-second period.

Only non-missing observations were included in the descriptive statistics.

---

## 3. Descriptive Statistics

| Metric | Valid observations | Mean | Median | Minimum | Maximum | Standard deviation |
|---|---:|---:|---:|---:|---:|---:|
| EC2/ASG CPUUtilization (%) | 507 | 0.164 | 0.135 | 0.001 | 2.858 | 0.194 |
| RDS CPUUtilization (%) | 10,077 | 3.827 | 3.808 | 2.558 | 52.617 | 0.842 |
| RDS DatabaseConnections | 10,078 | 0 | 0 | 0 | 0 | 0 |
| RDS FreeStorageSpace (bytes) | 10,078 | 18,337,283,239 | 18,318,692,352 | 18,318,389,248 | 18,385,829,888 | 30,050,982 |
| FailedSSHLoginCount | 59 | 0 | 0 | 0 | 0 | 0 |

---

## 4. EC2 Auto Scaling Group CPU Utilisation

The EC2 Auto Scaling Group metric relates to
`medicore-application-asg`.

CPU utilisation remained very low during the observations available in the
export. Mean utilisation was approximately 0.164%, with a median of 0.135%.
The maximum recorded value was approximately 2.858% on 26 August 2026 at
07:35 UTC.

The low mean and maximum indicate that the application-tier compute resources
were operating well below CPU capacity during the observed workload.

This should not automatically be interpreted as evidence that the production
environment is over-provisioned. The MediCore environment used for this
assessment represents a limited demonstration/test workload rather than a
full production healthcare workload. Production sizing would therefore
require monitoring under representative traffic and load conditions.

---

## 5. RDS CPU Utilisation

The RDS CPU dataset relates to the `medicore-postgresql` database instance.

RDS CPU utilisation was substantially more active than application-tier CPU
utilisation. Mean CPU utilisation was approximately 3.827%, with a median of
3.808%.

Most observations were close to the normal baseline. However, a significant
short-duration spike was recorded:

- Maximum CPUUtilization: 52.617%
- Timestamp: 23 August 2026 at 03:02 UTC
- Median CPUUtilization: 3.808%

Because the maximum is substantially higher than both the mean and median,
this observation represents a clear anomaly in the dataset rather than
sustained high CPU utilisation.

The CPU returned to its normal range rather than remaining at approximately
52%, suggesting a temporary workload or system activity rather than persistent
resource saturation.

The available metric alone does not identify the cause of the spike.
Additional evidence such as RDS logs, database activity or correlated
CloudWatch metrics would be required before attributing it to a specific
process.

---

## 6. RDS Database Connections

The DatabaseConnections metric recorded zero active database connections
throughout all 10,078 valid observations in the exported period.

Therefore:

- Mean: 0
- Median: 0
- Minimum: 0
- Maximum: 0

This indicates that CloudWatch did not record active client database
connections for this metric during the analysed period.

This result is consistent with a demonstration environment that was not
receiving a continuous application workload. However, the metric should not
be used to claim that the database was never operational, because other RDS
metrics, including CPU utilisation and FreeStorageSpace, continued to record
database-instance activity.

In a production MediCore environment, DatabaseConnections would be an
important operational metric because unexpected increases could indicate
application demand, connection-pool problems or abnormal database activity.

---

## 7. RDS Free Storage Space

FreeStorageSpace remained relatively stable but showed a measurable reduction
during the monitoring period.

The maximum available free storage recorded was:

18,385,829,888 bytes (approximately 18.386 GB)

The minimum was:

18,318,389,248 bytes (approximately 18.318 GB)

The difference between the maximum and minimum is approximately:

67.4 MB

The CloudWatch graph shows a reduction around 21 August followed by a
relatively stable level for the remainder of the monitoring period.

This represents only a small reduction in available storage and does not
indicate an immediate capacity issue. Nevertheless, FreeStorageSpace is an
important metric for long-term capacity management. In a production
healthcare system, a continuing downward trend should be monitored and
appropriate thresholds should be configured so that remediation can occur
before storage exhaustion affects database availability.

---

## 8. Failed SSH Login Monitoring

`FailedSSHLoginCount` is a custom CloudWatch metric within the
`MediCore/Security` namespace.

There were 59 valid observations in the exported dataset, and every recorded
value was zero.

Therefore, no failed SSH login events were recorded by this custom metric
during the observations available between 19 and 21 August 2026.

This provides evidence that the security monitoring mechanism was available
and reporting zero for the sampled observations. It does not prove that no
unauthorised access attempts occurred through any other attack vector.

The metric should therefore be considered one component of a wider monitoring
strategy rather than a complete intrusion-detection mechanism.

---

## 9. Trend and Anomaly Analysis

The most significant anomaly identified in the collected CloudWatch data was
the RDS CPUUtilization spike of approximately 52.617% on 23 August 2026 at
03:02 UTC. This was substantially above the normal RDS CPU baseline of
approximately 3–4%.

No comparable sustained increase was identified in the application Auto
Scaling Group CPU data.

A second observable trend was the reduction in RDS FreeStorageSpace of
approximately 67.4 MB. After the reduction, available storage remained
relatively stable.

DatabaseConnections remained at zero throughout its dataset, while all valid
FailedSSHLoginCount observations were also zero.

Overall, the monitored environment shows low application CPU utilisation,
low baseline database CPU utilisation, stable database storage and no failed
SSH login events within the observations recorded by the custom security
metric.

---

## 10. Operational Interpretation

The CloudWatch evidence demonstrates that the MediCore architecture can be
monitored across several operational areas:

- application compute utilisation through EC2/Auto Scaling metrics;
- database performance through RDS CPUUtilization;
- database usage through DatabaseConnections;
- database capacity through FreeStorageSpace;
- security activity through the custom FailedSSHLoginCount metric.

The RDS CPU anomaly demonstrates why continuous monitoring and alerting are
important. Although the recorded spike did not reach sustained resource
saturation, similar behaviour in a production environment should be
investigated if it becomes frequent or is associated with degraded service.

Storage monitoring is also important because healthcare systems can accumulate
data continuously. Capacity trends should therefore be reviewed over longer
periods rather than relying on a single short monitoring window.

---

## 11. Limitations

Several limitations apply to this analysis.

First, the datasets cover a relatively short monitoring period and therefore
cannot demonstrate long-term production behaviour or seasonal workload
patterns.

Second, the datasets have different sampling periods and different numbers of
valid observations. RDS metrics use a 60-second period, while the EC2/ASG CPU
metric and FailedSSHLoginCount use a 300-second period.

The EC2 CPU CSV contains 507 valid CPU observations within the exported time
range rather than a continuous five-minute series across the entire period.

The FailedSSHLoginCount export contains 59 valid observations and covers only
approximately 19–21 August. Missing CloudWatch datapoints were excluded from
the statistical calculations and were not treated as zero.

DatabaseConnections recorded zero throughout the analysed period. This limits
the conclusions that can be drawn about database behaviour under active
application traffic.

Finally, CloudWatch metrics can identify unusual behaviour but do not
necessarily identify its root cause. For example, the RDS CPU spike can be
identified quantitatively, but determining its cause would require correlation
with additional evidence such as database logs, application logs or other
CloudWatch metrics.

---

## 12. Conclusion

The CloudWatch analysis provides quantitative evidence of the operational
state of the MediCore AWS environment during the monitoring period.

Application-tier CPU utilisation was low, while the RDS database maintained a
low CPU baseline with one clear short-duration anomaly. RDS storage remained
largely stable despite a small reduction in available capacity.
DatabaseConnections remained at zero, and the custom FailedSSHLoginCount
metric recorded no failed SSH login events within its available observations.

The results demonstrate the value of combining performance, capacity and
security metrics rather than relying on a single indicator. For a production
MediCore deployment, the same monitoring approach should be maintained over
longer periods and combined with appropriate alarms, log analysis and
incident-response procedures.
