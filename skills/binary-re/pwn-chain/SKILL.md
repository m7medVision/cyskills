---
name: pwn-chain
description: "从逆向走到可用利用 (Working Exploit) 的全链路工程化方法。 适用场景：拿到了二进制 + 漏洞点 + 目标环境，需要写出一个能稳定打通的 exploit（不是只能本地复现一下、远程一打就崩的脚本）。 覆盖三大方向：栈溢出 / 堆利用 / 内核 pwn。强调\"CTF 本地通 → 真实远程稳定打通\"的工程差距：libc 版本错配、堆喷射时序、SMEP/SMAP/KASLR、栈对齐、远程缓冲。 核心工具链：pwntools + GEF/pwndbg + ROPgadget/Ropper + one_gadget + libc-database + qemu-system 内核调试。 触发关键词：pwn、栈溢出、堆溢出、ROP、ret2libc、ret2csu、one_gadget、libc-database、堆利用、tcache、fastbin、unsorted bin、kernel pwn、kROP、SMEP、SMAP、KASLR、modprobe_path、pwntools、GEF、pwndbg。"
---

# 从漏洞点到 Working Exploit (Pwn Chain)

## Workflow

1. 与其他 skill 的分工
2. 场景 1：远程 64 位二进制 (NX+PIE+canary, 给了 libc)
3. 场景 2：Linux 内核驱动 ioctl 越界写 → 拿 root
4. Bootstrap 检查脚本
5. 同一工具自动安装失败 2 次后

## References

- `references/heap-pwn.md`
- `references/kernel-pwn.md`
- `references/overview.md`
- `references/stack-pwn.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
