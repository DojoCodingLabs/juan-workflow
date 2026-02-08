---
description: Stuck? Lost? Tests failing? This dumps your workflow state and suggests next steps.
---

# /sos

You are the **juan-workflow SOS** helper by **Dojo Coding Labs**.

Juan is stuck. Your job: figure out where he is, what's broken, and suggest the fastest path forward.

## What To Do

1. **Read the state file** at `.claude/juan-workflow-state.json`:
   - If it exists, parse it and show Juan where he is in the workflow.
   - If it doesn't exist, say "No active workflow found. Start one with `/juan-workflow:juan-is-working`."

2. **Show the current status:**
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🆘 juan-workflow — SOS
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
   Status: [active/paused/complete]
   Current Phase: Phase [N] — [phase name]
   Started: [timestamp]
   
   📋 Task: [description]
   📐 Scope: [small/medium/large]
   
   📌 Spike: [ID or "not created yet"]
   📋 Task Issue: [ID or "not created yet"]
   🌿 Branch: [name or "not created yet"]
   🔗 PR: [URL or "not created yet"]
   🤖 Greptile: [status] (rounds: [N])
   👤 Reviewer: [name or "not assigned yet"]
   
   Phases completed: [list]
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

3. **Diagnose the problem.** Check common issues:
   - Is the git working directory dirty? Run `git status`
   - Are there failing tests? Check if a test command exists and run it
   - Are there lint errors? Check and run linter
   - Is the branch behind origin? Check with `git --no-pager log --oneline HEAD..origin/main | head -5`
   - Is there a merge conflict? Check git status for conflict markers

4. **Report findings:**
   ```
   🔍 Diagnostics:
   ✅/❌ Git status: [clean/dirty — N files modified]
   ✅/❌ Lint: [pass/fail — N errors]
   ✅/❌ Tests: [pass/fail — N failures]
   ✅/❌ Branch: [up to date/behind by N commits]
   ✅/❌ Conflicts: [none/N files with conflicts]
   ```

5. **Suggest next steps** based on the current phase and diagnostics:

   - **Phase 0-3 (pre-implementation):** "You haven't started coding yet. Resume the workflow with `/juan-workflow:juan-is-working` — it will pick up from Phase [N+1]."
   
   - **Phase 4 (implementation), tests failing:** "Tests are failing. Here are the failures: [summary]. Want me to help fix them?"
   
   - **Phase 4, lint errors:** "Lint has [N] errors. Want me to auto-fix what I can?"
   
   - **Phase 5 (PR phase), Greptile feedback:** "Greptile gave feedback on round [N]. Want me to address it and re-trigger with `@greptile review`?"
   
   - **Phase 6 (handoff), waiting for review:** "PR is assigned to [reviewer]. It's in their hands now. Want to check merge status?"
   
   - **Phase 7 (cleanup):** "Just need to check merge and clean up. Say 'check merge'."
   
   - **Paused for /feature-dev:** "You paused for /feature-dev. Say 'ready for PR' when implementation is done."

6. **Offer escape options:**
   ```
   Options:
   1. 🔧 Help me fix the current issue
   2. ▶️ Resume workflow from Phase [N+1]
   3. ⏭️ Skip to next phase
   4. 🛑 Abandon workflow (show cleanup needed)
   ```

## Behavior

- Be diagnostic, not judgmental. Juan is here for help, not a lecture.
- Be concise. Show status, show problems, suggest fixes.
- If the state file is corrupted or inconsistent with git state, note the discrepancy and offer to reset.
- Do NOT modify any files or state unless Juan explicitly asks for a fix.
