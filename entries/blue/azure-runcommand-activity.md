---
id: azure-runcommand-activity
title: Detect Azure VM Run Command (Activity Log, runCommand action)
detection: kql-azure-activity
event_ids: []
attack:
  tactic: TA0002
  techniques: [T1651]
source: MITRE ATT&CK T1651; APT29 Azure Run Command / AOBO
pair: azure-vm-runcommand
---

The invariant is **control-plane execution against a guest**, and the query has to catch
*both* paths the paired red uses: keying only on `runCommand/action` misses the managed
`runCommands` write, which is the stealthier one — the same too-narrow-for-its-own-red
failure the corpus already corrected in `kerberoasting-4769`. So match on the substring,
not an exact operation string. (`OperationNameValue` is emitted **uppercased** in practice,
which is why `has` — case-insensitive — is used rather than `==` against a mixed-case
literal.)

```kql
AzureActivity
| where OperationNameValue has "runcommand"
| where ActivityStatusValue in ("Start", "Started", "Succeeded", "Success")
| summarize ops = make_set(OperationNameValue), vms = dcount(_ResourceId),
            targets = make_set(_ResourceId, 20), n = count()
          by bin(TimeGenerated, 1h), Caller, CallerIpAddress
| order by vms desc
```

Triage on: a `Caller` that has never issued Run Command before, a service principal rather
than a human, fan-out across many distinct `_ResourceId` VMs in one window, and a
`CallerIpAddress` outside the admin egress set.

Second arm, independent of any log window: the managed path leaves the `runCommands` child
resource behind, so a `Microsoft.Compute/virtualMachines/runCommands` sitting on a VM
nobody deployed one to is a standing artifact — sweep resource inventory for it directly,
because the attacker who un-invokes still leaves the child resource until it is explicitly
deleted.

Unlike the Key Vault half of this plane, the Activity Log is **on by default** with 90 days
of platform retention, so there is no telemetry-off caveat — the one prerequisite is a
diagnostic setting exporting the subscription's Activity Log to the workspace you query in
KQL.

Azure Activity Log telemetry (KQL / Sentinel), companion-only — `PURPLE-TEAM.md` is on-prem
Windows.
