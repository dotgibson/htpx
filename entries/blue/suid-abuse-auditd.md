---
id: suid-abuse-auditd
title: Detect SUID abuse (setuid-bit change + root shell under a real loginuid)
detection: splunk-spl
event_ids: []
attack:
  tactic: TA0004
  techniques: [T1548.001]
source: Linux auditd syscall telemetry; chmod setuid watch + loginuid-vs-euid gap
pair: suid-abuse-privesc
---

Two moments are catchable, and they are different events. **Planting** a SUID bit is a
`chmod`/`fchmodat` that sets mode `04000` — auditd sees the syscall, and a new
setuid-root file (especially a shell or interpreter) is high-signal because legitimate
SUID binaries are installed by packages, not `chmod`'d into existence at runtime.
**Abusing** an existing SUID binary produces the same fingerprint the sudo path does:
a root shell (`euid=0`) whose `auid` is still a real login user, because the setuid
transition, like sudo, never rewrites the loginuid. Watch both.

```conf
# /etc/audit/rules.d/suid-privesc.rules — load with `augenrules --load`
# perm changes by a real login user (the chmod u+s plant); the b64/b32 split matters.
# x86_64 / i386:
-a always,exit -F arch=b64 -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=4294967295 -F key=suid_change
-a always,exit -F arch=b32 -S chmod,fchmod,fchmodat -F auid>=1000 -F auid!=4294967295 -F key=suid_change
# arm64: DROP `chmod` from the b64 line — that syscall does not exist on aarch64 and
# auditctl fails the load rather than skipping it (see the arch note below).
-a always,exit -F arch=b64 -S fchmod,fchmodat -F auid>=1000 -F auid!=4294967295 -F key=suid_change
```

Linux auditd telemetry, companion-only — `PURPLE-TEAM.md` is on-prem Windows. The abuse
arm reuses `priv_exec` from `sudo-abuse-auditd` — the loginuid-vs-euid gap is one
invariant covering every escalation that leaves `auid` behind, sudo and SUID alike.

```spl
index=linux sourcetype=linux:audit key=suid_change
| stats values(exe) AS via values(name) AS target min(_time) AS first by auid, ses, host
| sort -first
```

**Name the syscalls per architecture.** `chmod` is a legacy syscall that the generic
table does not carry, so on **aarch64 it does not exist** — only `fchmod` and `fchmodat`
do. Naming it anyway is not a harmless no-op: `auditctl` resolves syscall names against
the arch in `-F arch=`, reports `Syscall name unknown: chmod`, and treats that as a
fatal parse error rather than skipping the line — so on arm64 the rules **after** it in
the merged `audit.rules` do not load either. Drop `chmod` there. It costs no coverage,
because `fchmodat` is the only path-based chmod arm64 has: every `chmod u+s` on that
architecture already arrives through it.

The watch is deliberately broad, but *not* because the bit cannot be tested. It can:
the setuid bit is a mode-argument predicate, and the mode sits at a **different argument
index per syscall** — `a1` for `chmod(path, mode)` and `fchmod(fd, mode)`, but `a2` for
`fchmodat(dirfd, pathname, mode, flags)`, where `a1` is the pathname pointer. So a
narrowed rule is four lines, one pair per index (`-F a1&04000` / `-F a2&04000`, and the
same for `02000` if you want setgid), not one. Write it as a single line across all
three syscalls and it ANDs a **pointer** against the bitmask on every `fchmodat` —
the rule then fires or not depending on where the path string happens to sit in memory.
The blue side ships the narrowed form (dotfiles-Defense `linux/suid_bit_set.yml`, which
carried exactly that single-line bug until it was split).

Broad is still the choice here, on its own merits: it catches the setuid bit being
*removed* and the rest of the perm changes a real user makes, which the narrowed form
throws away, and the triage narrows to the setuid case anyway: a mode that sets
`04000`, and a target that is a shell/interpreter or a file outside the baseline SUID
set (`find / -perm -4000` on a known-good host gives you that baseline). Do not tighten
the rule into silence — the same broad-catch, narrow-in-query shape the cron and systemd
watches use. For the abuse path, run `sudo-abuse-auditd`'s `priv_exec euid=0` query:
a root shell under a mortal `auid` is the outcome whether the vehicle was `sudo` or a
setuid binary, and the parent `exe` tells you which.
