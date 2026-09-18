# Browser Setup and Ownership

[browser-automation](../SKILL.md) is the sole entry for general browser use. Other skills supply their analysis goals and consume results; browser setup, navigation, interaction, session lifecycle, and screenshots belong here.

## Driver

Use Playwright with Chromium, driven by Bun. Do not install or launch a second browser driver (agent-browser, Selenium, Puppeteer) just because another skill mentions one.

## Arch Linux / BlackArch Setup

Check the existing installation first:

```bash
bunx playwright --version
```

If missing, request approval before installing:

```bash
bun add playwright
bunx playwright install chromium
```

On Arch, install missing system libraries as normal Arch packages (`pacman`/`AUR`), not with Debian dependency-install flags. Check browser startup separately; an installed package alone does not prove the browser is ready.

The legacy `scripts/setup.ps1` is unsupported on Arch; do not run it.

## Composition

Other skills attach to the browser this skill owns; they never launch their own driver.

- `api-mitmproxy` — route the browser through `mitmdump` with `--proxy-server`; see [commands](playwright-cheatsheet.md).
- `js-reverse` — expose the same browser with `--remote-debugging-port` (`--browserUrl http://127.0.0.1:9222` in the MCP config) so it observes and captures JS without a competing driver.

## Ownership

- Keep one dedicated browser instance per task; reuse it rather than launching competing drivers.
- Do not import personal profiles or saved authentication without permission.
- Other skills must delegate general browser actions here rather than duplicate commands.
- Extension artifact analysis and JavaScript code analysis remain separate specialties.
- Consult [commands](playwright-cheatsheet.md) for interaction and [storage](browser-persistence.md) for state inspection.

Source: [Playwright upstream](https://playwright.dev/docs/intro).
