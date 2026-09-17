
# RF / SDR Security Research

## 适用场景

- 无线遥控/传感器等非 Wi-Fi RF（授权）
- ADS-B/遥控等协议研究（合法接收）
- 与 wifi-wireless 分工：本 skill 偏 **SDR 通用 RF**；Wi-Fi 攻防走 R29

## 工作流

```text
□ 法规与许可确认
□ 只收：识别中心频率与调制
□ GNU Radio / URH 分析
□ 重放仅屏蔽室且书面允许
□ 结论侧重：是否可未授权控制 / 加固建议
```

## 工具链

| 工具 | 用途 |
|------|------|
| RTL-SDR / HackRF（合规） | 收发硬件 |
| URH / GNU Radio | 分析 |
| Inspectrum | 信号 |

## 参考

- `sdr-lab-rules.md`
- `the `wifi-wireless` skill` `the `ot-ics` skill` `the `hardware-security` skill`

## 路由上下文

**上游**: MASTER R38  
**MUST NOT**: 干扰公共通信、未授权发射
