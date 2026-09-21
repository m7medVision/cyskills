---
name: pwn-chain
description: "An end-to-end engineering methodology from reverse engineering to a working exploit. Use when: you have a binary + a vulnerability point + the target environment and need to write an exploit that reliably lands (not a script that only reproduces locally but crashes the moment it hits a remote). Covers three major tracks: stack overflow / heap exploitation / kernel pwn. Emphasizes the engineering gap between \"works locally in CTF → reliably lands against a real remote\": libc version mismatch, heap spray timing, SMEP/SMAP/KASLR, stack alignment, remote buffering. Core toolchain: pwntools + GEF/pwndbg + ROPgadget/Ropper + one_gadget + libc-database + qemu-system kernel debugging. Trigger keywords: pwn, stack overflow, heap overflow, ROP, ret2libc, ret2csu, one_gadget, libc-database, heap exploitation, tcache, fastbin, unsorted bin, kernel pwn, kROP, SMEP, SMAP, KASLR, modprobe_path, pwntools, GEF, pwndbg."
---

# From Vulnerability to Working Exploit (Pwn Chain)

## Workflow

1. Division of labor with other skills
2. Scenario 1: remote 64-bit binary (NX+PIE+canary, libc provided)
3. Scenario 2: Linux kernel driver ioctl out-of-bounds write → get root
4. Bootstrap check script
5. After automatic installation of the same tool fails twice

## References

- `references/heap-pwn.md`
- `references/kernel-pwn.md`
- `references/overview.md`
- `references/stack-pwn.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
