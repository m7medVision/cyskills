# Playwright Command Reference

Owned by [browser-automation](../SKILL.md); this reference is not a separate skill. Run scripts with Bun; use Node for CDP attach (`connectOverCDP` times out under Bun). Use the installed Playwright version's docs for exact options.

## Baseline Script

```javascript
// browse.js — run with: bun browse.js
import { chromium } from "playwright";

const APP_URL = process.env.APP_URL; // user-approved URL only
if (!APP_URL) throw new Error("Set APP_URL");

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage();
try {
  await page.goto(APP_URL);
  // ... interact ...
} finally {
  await browser.close(); // always close, even after failures
}
```

## Proxy and CDP

Launch Chromium behind an intercepting proxy and expose CDP so another tool such as the `js-reverse` skill can attach to the same browser:

```javascript
const browser = await chromium.launch({
  headless: true,
  args: [
    "--proxy-server=http://127.0.0.1:8080", // mitmdump (api-mitmproxy skill)
    "--proxy-bypass-list=<-loopback>",      // Chrome otherwise skips the proxy for localhost
    "--remote-debugging-port=9222",         // CDP endpoint for js-reverse
    "--ignore-certificate-errors",          // lab targets using the mitmproxy CA
  ],
});
```

- Attach with `chromium.connectOverCDP("http://127.0.0.1:9222")`, run under Node.
- The other skill only attaches; this skill still owns launch and teardown.
- This skill must be running first, or the attaching client has no browser to reach.

## Interaction

Locate from the real DOM; never guess selectors:

```javascript
await page.getByRole("button", { name: "Sign in" }).click();
await page.getByLabel("Username").fill("sample text");
await page.locator("#submit").click();
```

Take a fresh `snapshot`/inspection after navigation or DOM changes. Confirm consequential actions before submitting forms.

## Wait and Verify

```javascript
await page.getByText("Saved").waitFor();
await page.waitForURL("**/dashboard");
```

Prefer locator and URL waits over fixed delays. Network-idle waits may never finish on pages with polling or streaming.

## Evidence and Cleanup

Save screenshots only when requested, into an approved existing directory, with sensitive content excluded:

```javascript
await page.screenshot({ path: process.env.SCREENSHOT_PATH, fullPage: true });
```

Always close the owned browser, including on failure. Cookies and saved state may contain credentials; consult [the storage checklist](browser-persistence.md) without exposing their values in logs.
