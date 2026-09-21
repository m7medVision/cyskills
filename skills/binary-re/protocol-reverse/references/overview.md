
# Protocol Reverse Engineering

## Applicable scenarios

- Custom TCP/UDP binary protocols
- Protobuf / gRPC / FlatBuffers / MessagePack
- WebSocket / MQTT / proprietary RPC
- Recovering fields and state machines from PCAP / PCAPNG
- Client-server validation, sequence numbers, encrypted frame headers

## Not covered by this skill

| Case | Where to go |
|------|------|
| Only HTTP parameter signing / JS encryption | `js-reverse/` |
| Only TLS certificate issues | `pentest-core/` or a browser proxy |
| Deep-diving a firmware protocol stack + emulation | `firmware-pentest/`, then come back to this skill |

## Workflow

### Phase 1 — Collection and Triage

```text
□ Get samples: PCAP / proxy export / client logs / binary
□ Mark direction: C→S / S→C; are there handshakes, heartbeats, reconnects
□ Fixed header? Magic number? Length field? TLV? Fixed length?
□ Is it compressed (zlib/gzip/lz4) or encrypted (AES/ChaCha in-frame)?
□ tshark -r cap.pcap -T fields -e frame.number -e ip.src -e tcp.payload
```

### Phase 2 — Frame Layout Recovery

```text
□ Align multiple messages of the same kind, find invariant bytes / auto-incrementing sequence numbers
□ Length field: big-endian/little-endian, includes header/does not include header
□ Checks: CRC16/32, checksum, HMAC location
□ Draw the state machine: Connect → Auth → Ready → Request/Response → Close
□ Tools: Wireshark custom dissector draft / ImHex / 010 Editor template / Kaitai Struct
```

### Phase 3 — Serialization and Encryption

```text
□ Protobuf: .proto recovery (blackboxprotobuf / pbtk / protoc --decode_raw)
□ gRPC: HTTP/2 headers + protobuf body
□ Encryption: find key derivation (client so/dll/JS) → combine ida-reverse / js-reverse / apk-reverse
□ Replay: only within the authorized scope; harmless fields first, then sensitive operations
```

### Phase 4 — Deliverables

```text
MUST produce:
- Message type table (name / opcode / fields)
- At least 1 reproducible decode command or script
- Evidence: raw hex excerpt + decode result (redacted)
```

## Toolchain

| Tool | Required | Purpose | Bootstrap |
|------|------|------|------|
| tshark / Wireshark | Strongly recommended | PCAP parsing | Manual / winget |
| Python3 | Yes | Decoding scripts | System |
| blackboxprotobuf | Optional | Unknown protobuf | pip |
| ImHex / 010 | Optional | Structure templates | Manual |
| IDA / r2 / Ghidra | As needed | Client serialization functions | See corresponding skill |

## References

- `protocol-workflow.md` — Frame layout and Protobuf quick reference
- Related: `the `ida-reverse` skill` `the `js-reverse` skill` `the `firmware-pentest` skill` `the `pentest-core` skill`

## Routing context

**Upstream**: `MASTER-ROUTING` R21 · routing.md  
**Downstream**: Need client algorithms → `ida-reverse`/`js-reverse`; need replay exploitation → `pentest-core`/`pentest-core`  
**Siblings**: `malware-analysis` (C2 protocols), `digital-forensics` (traffic forensics)
