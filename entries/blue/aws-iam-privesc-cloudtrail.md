---
id: aws-iam-privesc-cloudtrail
title: Detect IAM privilege escalation (CloudTrail AttachUserPolicy / PassRole)
detection: splunk-cloudtrail
event_ids: []
attack:
  tactic: TA0004
  techniques: [T1098.003]
source: Rhino Security Labs (AWS IAM privesc paths), Pacu
pair: aws-iam-privesc-policy
---

Two invariants, because the attack has two shapes. The **self-grant** is an
`AttachUserPolicy` / `AttachRolePolicy` / `PutUserPolicy` whose actor is the same principal
as the target, or whose `policyArn` is a wildcard-admin policy — `AdministratorAccess` is the
obvious one, but `PowerUserAccess` and any customer policy with `"Action": "*"` land in the
same place, so match on the grant rather than the ARN string alone. `CreatePolicyVersion`
with `setAsDefault=true` is the same escalation wearing an update's clothes and is easy to
miss if you only watch Attach\*.

The **PassRole** shape never touches the actor's own identity: `iam:PassRole` shows up as
the `requestParameters.iamInstanceProfile` / `role` on a `RunInstances`, `CreateFunction`, or
`CreateJob` call, and the escalation completes when that resource's credentials are used.
Alert on a PassRole of a privileged role by a principal that does not normally launch
compute — then pivot to whether the passed role's credentials appear from a new source IP.

CloudTrail telemetry (Splunk `aws:cloudtrail` / Athena / Sentinel `AWSCloudTrail`),
companion-only — `PURPLE-TEAM.md` is on-prem Windows.

```spl
index=aws sourcetype=aws:cloudtrail
  eventName IN (AttachUserPolicy, AttachRolePolicy, AttachGroupPolicy, PutUserPolicy, CreatePolicyVersion)
| eval actor=coalesce('userIdentity.userName','userIdentity.arn','userIdentity.principalId')
| eval target=coalesce('requestParameters.userName','requestParameters.roleName','requestParameters.policyArn')
| where like('requestParameters.policyArn',"%AdministratorAccess%")
     OR like('requestParameters.policyArn',"%PowerUserAccess%")
     OR 'requestParameters.setAsDefault'="true"
     OR actor=target
| table _time, eventName, actor, target, requestParameters.policyArn, sourceIPAddress, userAgent
```
