# AI Agent Obedience Engineering — Getting AI to Actually Work After Reading the Workflow

> Sources: multi-source synthesis in 2026 (Anthropic Skill Engineering, Microsoft Code Words, Strands Steering Hooks, Gradient Flow Harness Engineering)
> Applicable when: an AI coding agent (Claude Code / Codex / Cursor / Cline / Windsurf / Kiro, etc.) reads README/RULES.md and only acknowledges without executing, skips steps, or arbitrarily omits critical operations

---

## Root-cause diagnosis

The root cause of an AI agent that "reads the workflow but doesn't work" is not insufficient model capability, but that **natural-language instructions leave room for semantic escape**:

| Root cause | Explanation |
|------|------|
| **Context attention decay** | Content in the middle of a long document is down-weighted by the LLM's attention mechanism; the agent effectively only "sees" the beginning and the end |
| **Semantic override** | When optimizing for "helpfulness", the model creatively reinterprets explicit instructions (e.g. reading MUST DO X as "suggests doing X") |
| **Passive language treated as optional** | "Ready for next step → invoke X" is taken as a suggestion rather than an instruction |
| **No stateful enforcement** | Without an external state machine validating workflow order, the agent can skip steps undetected |
| **Silent state corruption** | The agent produces structurally correct but semantically wrong results; errors accumulate silently |

---

## Technique 1: Critical-First Pattern

**Put "what to do next" first and context afterward.**

```
WRONG (Agent ignores it):
  [70 lines of project background and tool list]
  → "Next step: run bootstrap to install missing tools"

CORRECT (Agent executes it):
  "## Execute now: run `bootstrap-reverse.ps1` to check for and install missing tools
   → when done, read routing.md to determine which skill to enter"
  [then project background and tool list]
```

**Principle**: LLMs assign the highest attention weight to the beginning and end of a prompt. Middle content may be ignored entirely.

**Applied to this project**:
- The "routing entry" section of RULES.md should come after the trigger keywords and before the execution principles
- The first section of every SKILL.md should be "execute now", not "applicable scenarios"

---

## Technique 2: Directive Over Suggestive

Replace all "suggestive" language with RFC 2119-level directive language:

| Weak language (Agent may skip) | Strong language (Agent must execute) |
|---|---|
| "You could try..." | **MUST**: You must execute... |
| "Ready for next step → invoke X" | **NOW**: Invoke X immediately; do not wait for confirmation |
| "It's recommended to read routing.md first" | **REQUIRED**: You must finish reading routing.md before entering any submodule |
| "If tools are missing you can bootstrap" | **NO EXCUSE**: When tools are missing, the only correct action is to invoke bootstrap; manual install guessing is forbidden |
| "Remember to update field-journal" | **CHECKLIST ENFORCED**: After the task, tick off the Checklist item by item; you may not claim the task is finished until it is complete |
| "You should..." | **MUST** / **MUST NOT** |

**Key patterns**:
```
MUST — violation = task failure
MUST NOT — violation = security breach
SHOULD — skipping requires justification
MAY — genuinely optional
```

---

## Technique 3: Excuse Rebuttal Table

**This is the most critical patch for this project.** When an AI agent meets resistance, it automatically generates "reasonable excuses" to skip steps. Pre-list the common excuses and rebut each one:

| Common Agent excuse | Rebuttal (enforced) |
|---|---|
| "This step can be skipped, I'll just..." | **Skipping forbidden.** Every step in the behavior chain is required. If you think it can be skipped, first state the specific reason and let the user decide. |
| "Based on my judgment, this isn't necessary" | **Your judgment does not apply here.** List the specific criteria you used and explain why that criterion permits skipping an explicitly written step. |
| "The user probably doesn't need this" | **Never make decisions for the user.** Present all options, mark a recommendation, but do not hide alternatives. |
| "I already know how to do this, no need to read X" | **Read X before acting.** Even if you're sure you know how, X may contain constraints specific to this task. Reading takes 2 seconds. |
| "To save time, I can skip in parallel..." | **The correct way to save time is to run independent steps in parallel, not to skip steps.** If two steps are independent, do them in parallel; if they depend on each other, do them in order. |
| "I've used this tool before, I know the path" | **Guessing paths is forbidden.** You must obtain the real path from tool-index; install locations differ across machines. |
| "The task is basically done, no need for a checklist" | **The only definition of task completion is every Checklist item ticked.** A task with an incomplete Checklist is not complete. |
| "I couldn't find tool-index, so I'll just guess the path" | **A missing file is 100x safer than a wrong path.** When tool-index is missing, run refresh-tool-index.ps1 first to generate it. |
| "The user didn't explicitly ask for a report, so I won't write one" | **A report is default behavior, not optional.** A security task must produce a report when finished, unless the user explicitly says "no report". |
| "This is too simple to warrant a journal entry" | **Even simple tasks have pitfall value.** At minimum record: target type + what you used + any surprises; one line is enough. |
| "The user asked me to redo the import table/some step, but I did a different, more useful step instead" | **Redo = redo the exact same step named** (or a legitimate prerequisite path confirmed by the user). You MUST update the corresponding Evidence; passing off an unrelated step is forbidden, and silent skipping is forbidden. Unpacking is a **prerequisite** for a readable IAT, not a **substitute** for import-table Evidence. |
| "The user said not to unpack the packed sample yet, just look at the import table; I'll just turn in a fabric table and call it done" | **Feasibility gate:** when X is blocked you MUST state the blockage, give the recommended order, and **ask the user to confirm**. If the user insists, execute and mark `quality=unreadable/packed`; using a fabric table to draw capability-negating conclusions is forbidden. |
| "After unpacking it crashes, so I keep grinding at the file on disk" | **Patch 6:** record E-self-check-crash / E-iat-repair-fail, switch to dynamic (bp CreateFile/GetFileSize). Endless static file editing is forbidden. |
| "I can't fix the IAT, so I'll try a few more static packer tools to stall" | **IAT repair iron rule:** prefer automated/semi-automated repair; if the tool errors or the repaired binary won't run → immediately stop static IAT work, record E-iat-repair-fail, and switch to dynamic API breakpoint capture. Endless static grinding is forbidden. |
| ".NET / no import table, the hard gate doesn't apply, so I'll skip it" | **An equivalent anchor is still MUST:** for .NET use dnSpy/IL/metadata summary written into the E-imports semantic slot; DLL/SYS must list E-exports in parallel. Empty passing is forbidden. |


**How to use**: place this table near the end of RULES.md or another instruction file (a high-attention area). The agent sees the rebuttals before it finds excuses.

---

## Technique 4: The Five Skill Engineering Patterns (Anthropic 2026 official)

| Pattern | Applicable scenario | Key technique |
|---|---|---|
| **Linear Flow** | Flows with clear steps (deployment, installation) | Provide safe defaults; use negative directives ("MUST NOT use --force") |
| **Decision Tree** | Platform navigation, troubleshooting | Tree navigation + progressive loading of `references/` |
| **Iterative Loop** | TDD, review-fix loops | Hard rules up front + **excuse rebuttal table** to block shortcuts |
| **Baton Loop** | Multi-session, multi-agent collaboration | Externalize state to `next-prompt.md` (MUST write before exiting) |
| **Multi-Phase + Checkpoints** | Multi-day complex workflows | Orchestrator "parent" skill + human Go/No-Go checkpoints, annotate time cost |

**Mapped to this project**:
- Full behavior chain = Linear Flow (15 steps in sequence)
- Routing matrix = Decision Tree (three-dimensional matching)
- Checklist = Multi-Phase Checkpoint (every step must be ticked)
- Field Journal = Baton Loop (cross-session state externalization)

---

## Technique 5: In-Band Enforcement Checks (Steering Hooks idea)

Instead of relying on the AI's "self-discipline", embed self-check instructions in the prompt:

```
Before every claim that "the task is complete", you MUST first self-check:
1. Did I skip any step in the behavior chain? Which one?
2. Did I guess any tool path? If so, what is the actual tool-index path?
3. Is every Checklist item ticked? Why are the unticked ones not?
4. If any answer above is "yes"/"not ticked", the task is incomplete;
   return to the corresponding step and re-execute; do not declare completion.
```

This lets the agent audit itself before saying "done", which is more immediate than external validation.

---

## Technique 6: Opaque Identifiers (Code Words) — for API/tool parameters

Microsoft's 2026 research found that semantic parameter names trigger the model's tendency to "helpfully optimize".

```
WRONG: { "query": "...", "top": 9 }        → 68.4% parameter compliance rate
CORRECT: { "query": "...", "code": "alpha" } → 100% parameter compliance rate
```

**Where to apply**:
- When precise configuration must be passed in a bootstrap script, use short codes instead of semantic parameters
- For parameters that need strong guarantees in tool calls, use code word mappings

---

## Technique 7: Dual AI Validation Loop

```
AI A (executor) produces output
  ↓
AI B (reviewer) checks against the rules
  ↓ pass
output to the user
  ↓ fail
return to AI A to fix, with specific violation citations
```

**Applied to this project**:
- Embed a "self-review" step in RULES.md: before emitting a report, the agent checks itself item by item against the Checklist
- If it finds an unfinished item, it returns to the corresponding step and completes it

---

## Technique 8: Context Window Layout Optimization

LLM attention distribution (high→low):
```
[first 10%] ████████████ ← highest attention, put "act now" instructions here
[middle 80%] ████░░░░░░░░ ← declining attention, put reference material here
[last 10%]  ████████████ ← attention rises again, put "do not skip" and Checklist here
```

**Specific application**:
1. **First 10%**: immediate-execution instructions + trigger keywords
2. **Middle 80%**: detailed workflow, reference links, tool list
3. **Last 10%**: excuse rebuttal table + hard Checklist + forbidden-actions list

---

## Practical prompt templates

### Template A: Forced-start template (embed at the top of RULES.md)

```markdown
## CRITICAL: After reading this document you must immediately perform the following (do not just acknowledge, actually execute)

1. **NOW**: Detect the directory this file is in → that is the package root
2. **NOW**: If this is the first use, write this rule into the global configuration (see the global injection section)
3. **NEXT**: Read `skills/SKILL.md` → `skills/routing.md` → determine which sub-skill to enter
4. **NEXT**: Read `skills/tool-index.md` to confirm tool status
5. **THEN**: Begin the actual task; do not stop at the "read" state

If you only reply "read", "done", or "I understand" without actually performing the steps above,
you have failed. What the user needs is tools installed, code analyzed, and vulnerabilities verified,
not a confirmation message.
```

### Template B: Submodule entry template (embed at the top of each SKILL.md)

```markdown
## ACTION REQUIRED (execute immediately after reading; do not wait)

After reading this file:
1. Confirm you understand this skill's applicable scenarios
2. Check whether the required tools exist on this machine (read `../tool-index.md`)
3. If tools are missing → invoke bootstrap
4. If tools exist → start the first step of the workflow
5. If you are unsure → list the specific questions; do not stay silent
```

### Template C: Task-completion self-check template (embed at the end of each SKILL.md)

```markdown
## Task-completion self-check (MUST confirm item by item before claiming completion)

□ I actually performed every step in the behavior chain (no skipping)
□ I did not guess any tool path (all came from tool-index.md)
□ I produced reproducible commands/scripts/reports (not just a description of steps)
□ I updated field-journal (if there were pitfalls)
□ I ran the post-completion Checklist (report + diagrams + lessons written back)
```

---

## Forbidden actions (added from the agent-obedience angle)

- Forbidden: after reading RULES.md, only replying "understood, please tell me the specific task"
  → Correct: run global injection → read SKILL.md → read routing.md → determine the entry point
- Forbidden: saying "steps 1-4 are done" when you actually only read them once
  → Correct: distinguish "read the document" from "performed the operation"; the latter produces real side effects
- Forbidden: saying "task complete" without executing the Checklist
  → The Checklist is the only definition of task completion
- Forbidden: replacing reading tool-index with "based on experience"
  → Paths differ across machines; reading tool-index is the only way to locate them

---

## Summary: if you can change only one thing

**Add an "act now" instruction at the very top of RULES.md**, using strong directive words in bold such as CRITICAL and NOW.

This has the highest return on effort. Most agent "doesn't work" behavior comes from automatically entering "wait for user instructions" mode after reading a file. A forced "act now" instruction breaks that pattern.

If you can change a second thing: **add the excuse rebuttal table**. An agent finds an excuse to stop the moment it meets its first obstacle; block those excuses in advance.
