---
name: browser-automation
description: "统一自动化入口。覆盖浏览器自动化（Playwright）和 Windows 桌面应用自动化（OpenReverse）。 浏览器场景：打开网页、点击、填表、爬取、截图、自动化登录、渗透页面交互。 桌面场景：操作 IDA/x64dbg 等 GUI 工具、Windows UI Automation、视觉驱动交互、桌面应用网络抓包。 触发关键词：浏览器自动化、桌面自动化、打开网页、填表、爬取、截图、自动化登录、Playwright、agent-browser、headless、OpenReverse、UIA、CUA、桌面操作、Windows 自动化。"
---

# 自动化操作 (Desktop & Browser Automation)

## Workflow

1. 浏览器场景（Playwright / agent-browser）
2. 桌面应用场景（OpenReverse）
3. 与其他工具的分工
4. 核心工作流
5. 命令参考
6. 交互模式选择
7. 网络观察模式
8. 安装与配置
9. 常见组合
10. 逆向场景示例
11. 自动化能力边界
12. 自举触发
13. OpenReverse 手动安装引导

## References

- `references/browser-persistence.md`
- `references/overview.md`
- `references/playwright-cheatsheet.md`

## Before you start

- Confirm authorization scope via `step-cyskills` (`scope.md`); do not act outside it.
- Verify tools first; `step-cyskills` preflight reports missing tools with distro install commands.
