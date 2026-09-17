
# Source Code Security Audit

## 适用场景

- 白盒审计、PR/差分安全审查
- Semgrep / CodeQL / Bandit / gosec 等 SAST
- 危险 API、注入点、鉴权缺失、加密误用
- 与 `supply-chain-security/` 分工：本 skill 偏**自有代码逻辑**，供应链偏依赖与管道

## 工作流

### 1. 范围与威胁模型

```text
□ 信任边界：用户输入、文件、反序列化、SSRF、鉴权中间件
□ 高价值资产：鉴权、支付、管理端、密钥处理
```

### 2. 自动扫描

```bash
semgrep --config auto .
# 或项目规则包
semgrep --config p/owasp-top-ten .
```

### 3. 人工验证（MUST）

```text
□ 每个 SAST 命中：可达性？可利用性？误报？
□ 鉴权：IDOR/越权、缺校验、错误的多租户隔离
□ 注入：SQL/命令/模板/LDAP
□ 加密：硬编码密钥、ECB、自定义 crypto
```

### 4. 产出

```text
Finding：位置 + 数据流 + PoC + 修复建议
可选 ATT&CK / CWE 编号
```

## 工具链

| 工具 | 语言/场景 |
|------|-----------|
| Semgrep | 多语言快速规则 |
| CodeQL | 深数据流（GitHub） |
| Bandit | Python |
| gosec / staticcheck | Go |
| SpotBugs / FindSecBugs | Java |

## 参考

- `sast-review-checklist.md`
- `the `supply-chain-security` skill` `the `api-security` skill` `the `llm-security` skill`（Agent 代码）

## 路由上下文

**上游**: MASTER R26  
**角色**: `ops/role-map.md` cae  
**下游**: 依赖漏洞 → supply-chain；运行时验证 → pentest-tools
