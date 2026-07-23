---
id: aws-s3-exfil-cloudtrail
title: Detect S3 bulk exfil (CloudTrail data events + access logs)
detection: splunk-cloudtrail
event_ids: []
attack:
  tactic: TA0009
  techniques: [T1530]
source: CloudTrail S3 data events; S3 server access logs
pair: aws-s3-mass-exfil
---

The invariant is *volume from one principal*: a burst of `GetObject` (or a
`CopyObject` whose destination bucket is outside the account) far above that
identity's baseline, usually preceded by a `ListObjects`/`ListBucket` sweep. Alert
on the per-principal object-read count over a short window, weighting a first-time
principal↔bucket pairing, a new source IP/role, and CopyObject to an unknown-account
`bucket`. Defend structurally with least-privilege bucket policies, VPC endpoint
restrictions, and Object Lock on the crown-jewel buckets.

> Caveat: `GetObject`/`ListObjects` are S3 **data events** — *not* logged by
> CloudTrail unless S3 data-event logging is enabled for the bucket (management
> events won't carry them). Where data events are off, fall back to **S3 server
> access logs** / CloudWatch `BytesDownloaded`. `CopyObject` to an external bucket
> is visible via data events on the *source* bucket.

CloudTrail telemetry (Splunk `aws:cloudtrail` / Athena / Sentinel
`AWSCloudTrail`), companion-only — `PURPLE-TEAM.md` is on-prem Windows.

```spl
index=aws sourcetype=aws:cloudtrail eventSource=s3.amazonaws.com (eventName=GetObject OR eventName=CopyObject)
| eval actor=coalesce('userIdentity.userName','userIdentity.arn','userIdentity.principalId')
| bucket _time span=5m
| stats count as reads, dc(requestParameters.key) as objects, values(requestParameters.bucketName) as buckets by _time, actor, sourceIPAddress
| where reads>100
| sort - reads
```
