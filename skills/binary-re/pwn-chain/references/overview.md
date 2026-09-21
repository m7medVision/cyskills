
# From Vulnerability to Working Exploit (Pwn Chain)

## Scope

Use this skill when the task falls into one of the following scenarios:

1. **You have a binary + a known vulnerability point** — static analysis/audit/fuzzing has already found the overflow/UAF/double free, and you need to go from trigger to shell
2. **The CTF challenge works locally but not remotely** — remote environment differences break the script, and it needs stabilizing
3. **Binary exploitation of a real target** — in an SRC / red-team scenario, a memory corruption vulnerability has been identified and RCE must be constructed
4. **An ioctl bug in a Linux kernel driver** — triggered from user space, with the goal of privilege escalation to root

**Prerequisite**: you already know "where it breaks". This skill does not cover finding vulnerabilities (that's fuzzing / auditing), only "writing an exploit from the vulnerability point".

### Division of labor with other skills

| Scenario | Use |
|------|--------|
| Identify custom VM / anti-debug / complex obfuscation | `reverse-engineering/` |
| Open a binary from scratch for static analysis | `ida-reverse/` or `radare2/` |
| **Have a vulnerability point, write an exploit to land remotely** | **this skill** |
| Integrate the shell obtained from pwn into a full attack chain | `attack-chain/` (downstream) |

`reverse-engineering/` focuses on "understanding what the program does" (pattern recognition, protocol recovery, solving strange mechanisms in CTF challenges); this skill focuses on "turning an already-understood vulnerability into an executable attack". The two are often used together, but the division is clear.

## Core workflow

```text
Step 1: Confirm vulnerability type + protections
   ├─ checksec ./vuln (NX / Canary / PIE / RELRO / Fortify)
   ├─ file ./vuln  + readelf -d ./vuln
   ├─ Vulnerability classification: stack overflow / format string / heap (UAF/DF/OF) / integer / race / kernel
   └─ → Decide which references/ to follow

Step 2: Choose an exploitation strategy
   ├─ NX off + no ASLR → shellcode directly
   ├─ NX on + libc provided → ret2libc / one_gadget
   ├─ NX on + no libc provided → leak, then reverse-lookup with libc-database
   ├─ heap → technique matching the glibc version (tcache/fastbin/unsorted/large)
   └─ kernel → commit_creds / modprobe_path / core_pattern

Step 3: Prepare libc + gadget
   ├─ libc-database: ./find puts 0x6f0
   ├─ ROPgadget --binary ./libc.so.6 --only "pop|ret"
   ├─ one_gadget ./libc.so.6
   └─ Compute base: leak_addr - libc.sym['puts']

Step 4: Write a pwntools template (local process)
   ├─ context.binary = ELF('./vuln')
   ├─ p = process('./vuln')  /  p = gdb.debug('./vuln','b *main+xx')
   ├─ payload = cyclic(N) + p64(ret) + ...
   └─ p.interactive()

Step 5: Get it working locally
   ├─ Repeatedly attach + inspect registers + tune the offset
   ├─ Use pwndbg/GEF's vmmap / heap / bins / telescope
   └─ Once it works, switch to remote()

Step 6: Stabilize remotely
   ├─ libc offsets: reverse-lookup with libc-database from the leak, don't guess
   ├─ Stack alignment: 16-byte misalignment → movaps crash → add a ret gadget
   ├─ Remote network latency → recvuntil exact anchor string, no fuzzy sleep
   ├─ Remote buffering: sendlineafter is more reliable than sendline
   ├─ Heap spray success rate: increase spray count + leave padding chunks to prevent coalescing
   └─ Run many times: write a while True to verify a success rate ≥ 95%
```

## Typical scenarios

### Scenario 1: remote 64-bit binary (NX+PIE+canary, libc provided)

```text
Given: ./vuln (64-bit ELF, NX, PIE, canary) + ./libc.so.6 + nc host port
Vulnerability: read(buf, 0x200) but buf is only 0x40 bytes → stack overflow
Protections: canary blocks it, PIE randomizes .text

Strategy:
1. First leak the canary (stack/format string/partial read)
2. Then leak a libc function address (puts@got)
3. Compute the libc base with libc.address = leaked - libc.sym['puts']
4. one_gadget ./libc.so.6 to pick a magic gadget whose constraints can be satisfied
5. payload = padding + canary + saved_rbp + (pop_rdi + bin_sh + system) or one_gadget directly
6. Add a ret gadget to fix stack alignment (critical!)
```

For the full template see `stack-pwn.md`.

### Scenario 2: Linux kernel driver ioctl out-of-bounds write → get root

```text
Given: vmlinux + bzImage + initramfs.cpio.gz + custom vuln.ko
Vulnerability: in ioctl(0x1337, ptr), the copy_from_user length is controllable → kernel heap overflow (kmalloc-64 slab)
Protections: SMEP, SMAP, KASLR, KPTI

Strategy:
1. Modify the init script to get a root shell (CTF) or leak the KASLR base first before continuing (real target)
2. Leak the kernel base via /proc/kallsyms (may be restricted) or an uninitialized heap spray
3. Spray tty_struct / msg_msg / pipe_buffer in the kmalloc-64 slab
4. Overwrite the vtable pointer to point at user space → doesn't work (SMEP); instead use a stack pivot + kernel ROP
5. ROP chain: prepare_kernel_cred(0) → commit_creds → swapgs+iretq → user-space execve("/bin/sh")
6. Or more simply: overwrite modprobe_path with "/tmp/x", write a /tmp/x, then trigger modprobe
```

For the full template see `kernel-pwn.md`.

## On-Demand Bootstrap

### Tool dependencies

| Tool | Purpose | Installation |
|------|------|---------|
| pwntools | Exploit-writing framework | `pip install pwntools` |
| GEF | gdb enhancement (recommended for kernel + user space) | `git clone https://github.com/bata24/gef` (actively maintained fork) |
| pwndbg | gdb enhancement (best heap debugging experience) | `git clone https://github.com/pwndbg/pwndbg && ./setup.sh` |
| ROPgadget | Gadget search | `pip install ropgadget` |
| Ropper | Gadget search (alternative, supports more architectures) | `pip install ropper` |
| one_gadget | libc magic gadget finder | `gem install one_gadget` (requires ruby) |
| libc-database | libc fingerprint reverse-lookup | `git clone https://github.com/niklasb/libc-database && ./get` |
| qemu-system-x86_64 | Kernel challenge debugging | `apt install qemu-system-x86` |
| binwalk / cpio | initramfs unpacking | `apt install binwalk cpio` |
| patchelf | Switch libc versions | `apt install patchelf` |

### Bootstrap check script

```bash
# One-shot check + install core tools
for t in pwntools ropgadget ropper; do
  pip show $t >/dev/null 2>&1 || pip install $t
done

command -v one_gadget >/dev/null || gem install one_gadget

[ -d ~/tools/libc-database ] || git clone https://github.com/niklasb/libc-database ~/tools/libc-database
[ -d ~/tools/libc-database/db ] || (cd ~/tools/libc-database && ./get ubuntu debian)

[ -d ~/tools/pwndbg ] || (git clone https://github.com/pwndbg/pwndbg ~/tools/pwndbg && cd ~/tools/pwndbg && ./setup.sh)
```

### After automatic installation of the same tool fails twice

Stop retrying and output structured manual installation steps (pip mirror / gem mirror / domestic git mirror / apt mirror) for the user to confirm.

## Routing context

**Upstream entry**: `skills/SKILL.md` (master control), routing.md
**Trigger condition**: a binary + an identified vulnerability point, and an exploit needs to be written

**Upstream skills (use them first, then return to this skill)**:
- Don't yet understand what the binary does → `reverse-engineering/`
- Need detailed static analysis → `ida-reverse/`
- Quick reconnaissance to confirm architecture/protections → `radare2/`

**Downstream skills (after getting a shell)**:
- Integrate into a full attack chain (lateral movement, privilege escalation, persistence) → `attack-chain/`

**Submodule navigation**:
- Stack exploitation (ret2libc / ret2csu / one_gadget / stack alignment) → `stack-pwn.md`
- Heap exploitation (tcache / fastbin / unsorted / large bin / FILE struct) → `heap-pwn.md`
- Kernel pwn (kROP / SMEP-SMAP bypass / KASLR leak / modprobe_path) → `kernel-pwn.md`

## Notes

- **Don't call it done just because it works locally** — local libc / ASLR / network differ from the remote, so you must run 20+ times consecutively in remote mode to verify stability
- **The libc version must be confirmed** — reverse-lookup with leak + libc-database, don't assume it's Ubuntu 22.04's default libc
- **Stack alignment is a common 64-bit pitfall** — `movaps xmm0, [rsp]` faults when rsp isn't 16-byte aligned; fix it by adding an empty `ret` gadget
- **Heap exploitation is highly sensitive to the glibc version** — tcache was introduced in 2.27, safe-linking in 2.32, hooks were removed in 2.34; each version has a different exploitation path
- **Kernel pwn must first confirm the CPU flags** — whether the qemu boot parameters include +smep +smap +pku directly determines how the ROP chain is written
- **One KASLR leak is enough** — once you have one kernel address, all others are computed as offsets; don't leak repeatedly
