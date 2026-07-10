---
id: web-service-c2-beacon
title: Detect web-service C2 (non-browser process to SaaS API)
detection: splunk-spl
event_ids: [3]
attack:
  tactic: TA0011
  techniques: [T1102.002]
source: Sysmon Network Connection (Event ID 3) process attribution
pair: web-service-c2-telegram
---

The destination is trusted, so pivot off the *source process*, not the domain.
Sysmon Event ID 3 attributes each outbound connection to its `Image`; browsers,
Teams, and updaters talk to SaaS APIs — `powershell.exe`, `wscript.exe`, a random
binary in `%TEMP%`, or an Office child process beaconing to `api.telegram.org` /
`api.github.com` / `slack.com` on an interval does not. Allowlist the known
API-consumers per host and alert on the rest, weighting unsigned images and
user-writable paths.

```spl
index=sysmon EventCode=3 DestinationHostname IN ("api.telegram.org","*.slack.com","api.github.com","gist.githubusercontent.com")
| search NOT Image IN ("*\\chrome.exe","*\\msedge.exe","*\\firefox.exe","*\\Teams.exe")
| stats count, values(DestinationHostname) as dests by host, Image, User
| where count>3
```
