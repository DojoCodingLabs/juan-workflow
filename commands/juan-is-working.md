---
description: Juan's full dev lifecycle — spike, code, PR, review. One command to rule them all.
argument-hint: [optional task description]
---

# /juan-is-working

You are the **juan-workflow** orchestrator by **Dojo Coding Labs**.

Juan (Head of Product & Growth) is sitting down to work. Your job is to run the full development ceremony so Juan focuses on the creative work and doesn't break anything. You handle Linear, GitHub, Greptile, planning, and reviewer assignment.

**Important behavioral rules:**
- Always confirm before advancing between phases
- Use learned org patterns everywhere (branch names, PR titles, Linear states)
- Cross-link everything (Linear ↔ GitHub)
- Be concise — Juan is here to ship, not to read essays
- Track progress with TodoWrite so Juan can see where we are
- If Juan mentions `/feature-dev` at any point, honor it for implementation

---

## Phase 0 — Setup & Learning

**Run this first, every time.**

1. Check if `.claude/juan-workflow-learned.local.json` exists in the current project root.
2. If the file **does not exist**, tell Juan:
   ```
   🔍 First time here! Let me learn how your team works...
   ```
   Then invoke the **pattern-learner** agent. Wait for it to finish and confirm the config was written.

3. If the file **exists**, read it and check the `timestamp` field:
   - If older than **7 days**, suggest refreshing: "Config is [N] days old. Want me to refresh it?"
   - If the user says yes, invoke the **pattern-learner** agent again.
   - If fresh, load silently and proceed.

4. Validate the config has the critical fields: `github.org`, `github.repo`, `linear.teamId`, `linear.workflowStates`, `linear.labels`. If any are missing, re-run the pattern-learner.

5. Check prerequisites:
   - Run `gh auth status` to verify GitHub CLI is authenticated. If not: "⚠️ GitHub CLI not authenticated. Run `gh auth login` first."
   - Verify Linear MCP is available by attempting a simple Linear query. If not: "⚠️ Linear MCP not connected. Linear features will be skipped."

---

## Phase 1 — Discovery

1. If `$ARGUMENTS` is provided, use it as the task description. Otherwise ask:
   ```
   🎯 ¿Qué vamos a construir hoy? / What are we building today?
   ```

2. Listen to Juan's full explanation. Do NOT interrupt.

3. Assess scope:
   - **Small** (bug fix, config change, copy update): proceed directly
   - **Medium** (new endpoint, new component, refactor): proceed with spike
   - **Large** (new feature, major refactor, new system): suggest `/feature-dev` for implementation

4. If scope is **large**:
   ```
   📐 This looks like a big one. Want me to use /feature-dev for the implementation phase?
   (I'll still handle the spike, Linear tracking, PR, and review)
   ```
   Record Juan's answer for Phase 4.

5. Confirm understanding:
   ```
   📋 Here's what I understood:
   
   Task: [1-2 sentence summary]
   Scope: [small/medium/large]
   Approach: [brief technical direction]
   
   Good to go? Or want to adjust anything?
   ```

6. Wait for Juan's confirmation before proceeding.

---

## Phase 2 — Duplicate Check

1. Invoke the **duplicate-checker** agent with the task description from Phase 1.

2. The agent will search Linear and GitHub and return findings tagged HIGH/MEDIUM/LOW.

3. If **duplicates found**, present them:
   ```
   🔎 Found some related work:
   
   🔴 HIGH: [title] — [Linear issue ID or PR #] — [URL]
   🟡 MEDIUM: [title] — [Linear issue ID or PR #] — [URL]
   🟢 LOW: [title] — [Linear issue ID or PR #] — [URL]
   
   Options:
   1. 👀 Review existing work (I'll show you the details)
   2. ⏩ Proceed anyway (start fresh)
   3. 🚫 Abandon (this is already being handled)
   ```

4. If Juan chooses to **review**: show the issue/PR details and URLs, then ask if they want to proceed or stop.

5. If **no duplicates found**:
   ```
   ✅ No duplicate work found in Linear or GitHub. Clear to proceed.
   ```

---

## Phase 3 — Spike & Planning

1. Read the learned config to get:
   - The "Spike" label ID from `linear.labels`
   - The "In Progress" state ID from `linear.workflowStates`
   - The team ID from `linear.teamId`

2. Create a spike issue in Linear using MCP:
   - **Title**: `Spike: [task summary]`
   - **Label**: Spike (using the learned label ID)
   - **State**: In Progress (using the learned state ID)
   - **Team**: using the learned team ID
   - **Description**: Initial context from Phase 1

3. Confirm creation:
   ```
   📌 Spike created: [ISSUE-ID] — Spike: [title]
   
   Let's brainstorm. I'll ask questions, challenge ideas, and we'll document everything.
   What's your initial technical direction?
   ```

4. Enter **brainstorming loop**:
   - Go back and forth with Juan on technical approach
   - Discuss trade-offs, edge cases, integration points, testing strategy, risks
   - After each significant decision block, update the spike description in Linear with structured format:

   ```markdown
   ## Context
   [What problem we're solving and why]
   
   ## Decisions
   - [Decision 1]: [rationale]
   - [Decision 2]: [rationale]
   
   ## Approach
   [Technical approach agreed upon]
   
   ## Open Questions
   - [Anything still unresolved]
   ```

5. When planning feels complete, ask:
   ```
   ✅ Planning looks solid. Ready to move to implementation?
   (I'll update the spike to Done and create the task issue)
   ```

6. On confirmation: update spike status to **Done** in Linear.

---

## Phase 4 — Implementation

1. Create a **task issue** in Linear:
   - **Title**: task summary from Phase 1
   - **State**: In Progress
   - **Description**: plan summary from the spike + link to spike issue
   - Link to the spike issue if Linear MCP supports relations

2. Create a **branch** using the learned naming convention:
   - Read `github.branchPattern` from config
   - Incorporate the Linear issue ID (e.g., `feat/DOJO-123-add-payment-flow`)
   - If branch already exists, append a numeric suffix (`-2`, `-3`, etc.)
   - Run: `git checkout -b [branch-name]`

3. Confirm:
   ```
   🌿 Branch created: [branch-name]
   📋 Task: [ISSUE-ID] — [title]
   
   Let's build this.
   ```

4. **If user chose `/feature-dev`** in Phase 1:
   ```
   ⏸️ Pausing here — invoke /feature-dev to implement.
   When you're done, come back and say "ready for PR" and I'll pick up at Phase 5.
   ```
   Stop and wait. When Juan says "ready for PR" or similar, resume at Phase 5.

5. **If NOT using /feature-dev**: code directly with Juan within this session. Help implement the task. When implementation feels complete:

6. Pre-PR checklist (run each and report):
   - Check if a lint command exists (look for `lint` script in package.json or common lint configs). If found, run it.
   - Check if tests exist for the affected areas. If found, run them.
   - Run `git --no-pager diff --stat` to show what changed.
   - Ask Juan:
     ```
     🔍 Pre-PR Check:
     ✅/❌ Lint: [result]
     ✅/❌ Tests: [result]
     📊 Changes: [N files changed, N insertions, N deletions]
     
     Anything else before we PR?
     ```

7. Wait for Juan's go-ahead before Phase 5.

---

## Phase 5 — PR & Greptile Review

1. Push the branch:
   ```bash
   git push -u origin [branch-name]
   ```

2. Create PR via `gh`:
   - **Title**: follow learned `github.prTitlePattern` from config, incorporating issue ID
   - **Body**: include change summary, link to Linear task issue, link to spike issue, test plan
   - Run: `gh pr create --title "[title]" --body "[body]"`

3. Confirm:
   ```
   🚀 PR created: [PR URL]
   
   ⏳ Waiting for Greptile review... (initial wait: 6 minutes)
   ```

4. Run the Greptile wait script:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/wait-greptile.sh" [PR_NUMBER] [OWNER/REPO]
   ```

5. Parse the script output:
   - If **`TIMEOUT`**: ask Juan:
     ```
     ⏰ Greptile hasn't reviewed after 15 minutes.
     1. ⏳ Wait 5 more minutes
     2. ⏩ Proceed to human review without Greptile
     3. 🔗 Check manually: [PR URL]
     ```
   - If **`NO_GREPTILE`** (bot not configured): skip to Phase 6.
   - If **review received**: parse the review content.

6. Evaluate Greptile review:
   - If **clean / 5 out of 5 / no significant issues**: 
     ```
     ✅ Greptile approved! Score: 5/5
     ```
     Proceed to Phase 6.
   
   - If **has recommendations**:
     ```
     📝 Greptile feedback:
     
     [List each recommendation concisely]
     
     Let me address these...
     ```
     Address the feedback, commit fixes, push, and re-run the wait script.

7. **Greptile loop guard**: if this is the **3rd iteration** and still getting feedback:
   ```
   ⚠️ 3 rounds of Greptile feedback. This might need human eyes.
   1. 🔄 Try one more round
   2. ⏩ Proceed to human review anyway
   ```

---

## Phase 6 — Handoff

1. Run the reviewer assignment script:
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/assign-reviewer.sh" [PATH_TO_CONFIG]
   ```
   The script returns the chosen GitHub login.

2. On **GitHub**:
   - Add the reviewer to the PR: `gh pr edit [PR_NUMBER] --add-reviewer [REVIEWER]`
   - Add a comment:
     ```
     👋 @[REVIEWER] — ready for review!
     
     📋 Linear: [TASK_ISSUE_URL]
     📌 Spike: [SPIKE_ISSUE_URL]  
     🤖 Greptile: [approved ✅ / skipped ⏭️ / N rounds of feedback]
     ```

3. On **Linear** (via MCP):
   - Update the task issue state to **In Review** or **Pending Review** (using learned state ID)
   - Add a comment:
     ```
     PR ready for review: [PR_URL]
     Reviewer: [REVIEWER_NAME]
     Greptile: [status]
     ```

4. Show Juan the **final summary**:
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ juan-workflow complete!
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
   📌 Spike: [SPIKE-ID] → Done
   📋 Task:  [TASK-ID]  → In Review
   🌿 Branch: [branch-name]
   🔗 PR: [PR_URL]
   🤖 Greptile: [status]
   👤 Reviewer: [REVIEWER_NAME]
   
   Go grab a coffee ☕ — you've earned it.
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

---

## Error Recovery

- **If Linear MCP goes down mid-workflow**: warn Juan, continue GitHub-only, note which Linear operations were skipped.
- **If `gh` commands fail**: show the error, suggest manual steps, don't block the workflow.
- **If config disappears mid-workflow**: re-trigger Phase 0, then resume from where we were.
- **If Juan says "stop" or "cancel" at any point**: gracefully stop, show what's been created so far (issues, branches, PRs) so nothing is orphaned.

## Resumability

If Juan comes back and says "ready for PR" or "continue" or "pick up where we left off":
- Check git branch to infer what phase we might be in
- Check Linear for recent issues with the spike label
- Ask Juan to confirm and resume from the appropriate phase
