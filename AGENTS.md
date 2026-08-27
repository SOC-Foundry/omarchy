# Agents

This repo is a **CLI agent runbook** + change ledger for Omarchy user-space config.

## Standing order

For every issue / applied change:

1. Assign next free `CHG-00N` (Session *N* · no gaps).
2. Write a block in `README.md` with only:
   - **Objective** · **Challenge** · **Paths** · **Execute** · **Backout**
3. Add a **Changelog** row (date · host · status · risk · surfaces).
4. Backup: `*.bak.chg00N.<YYYYMMDD-HHMMSS>`
5. Optional: `docs/chg00N-*.md` + `scripts/chg00N-*` if needed.
6. Never edit `~/.local/share/omarchy/`.
7. High-risk disk work: label **High**; no casual reverse.
8. **Git writes are human-only.** Never `git add`, `git commit`, `git push`, `git merge`, `git rebase`. Read-only git is fine. Kyle stages, signs (1Password), and pushes. A 1Password deny is intentional — do not retry.

## Format (copy)

```markdown
## CHG-00N — Title

> `NN` · Status · date · host · Risk

| | |
|---|---|
| **Objective** | … |
| **Challenge** | … |
| **Paths** | … |

**Execute**

\`\`\`bash
# …
\`\`\`

**Backout**

\`\`\`bash
# …
\`\`\`
```

## Hosts

- `83te` — Yoga docked  
- `p3oos` — desk tower  
