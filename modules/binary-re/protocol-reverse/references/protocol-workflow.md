# Protocol reverse quick reference

> Applies to: `protocol-reverse` skill · 2026-07-18

## Common layout patterns

| Pattern | Characteristics | Hint |
|------|------|------|
| Fixed-length header+body | Length in the first 2/4 bytes | Check whether it includes the header length |
| Magic number | Fixed `0xDEAD` etc. | Helps resynchronize the stream |
| TLV | Repeating type-length-value | The type enum is the message dictionary |
| Protobuf | Field number varint | `protoc --decode_raw` |
| Encrypted frame | High entropy, no plaintext URL | Look for the nonce/IV neighborhood first |

## Minimal Python skeleton

```python
import struct
def parse_frame(buf: bytes):
    magic, length, msg_type = struct.unpack_from(">IHI", buf, 0)
    body = buf[10:10+length]
    return {"magic": magic, "type": msg_type, "body": body}
```

## Extract TCP payload from PCAP

```bash
tshark -r cap.pcap -Y "tcp.port==4433" -T fields -e tcp.payload | head
```
