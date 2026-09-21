
# Hardware / Embedded Interface Security

## When to use

- UART / JTAG / SWD debug port discovery
- Boot logs, root shell, boot interruption
- Combined with teardown to extract Flash
- Feasibility assessment of secure boot/encrypted Flash (non-destructive first)

## Workflow

```text
□ Disassemble the authorized device; photograph and mark test points
□ Find GND/VCC/TX/RX with a multimeter; logic levels 1.8/3.3/5V
□ USB-TTL read-only logs; record the baud rate
□ JTAG: enumerate IDCODE; assess whether it is locked
□ Extract the image → hand off to firmware-pentest / ghidra
```

## Toolchain

| Tool | Purpose |
|------|---------|
| USB-TTL / logic analyzer | UART |
| J-Link / CMSIS-DAP | Debugging |
| bus pirate / flipper (lab) | Multi-protocol |
| binwalk / flashrom | Extraction |

## References

- `debug-interface-triage.md`
- `the `firmware-pentest` skill` `the `ot-ics` skill`

## Routing context

**Upstream**: MASTER R34  
**MUST NOT**: unauthorized teardown/damage of others' devices
