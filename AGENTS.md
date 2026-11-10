# Agents

This repo is the **control** for a bare-metal Omarchy install: a change ledger plus the outcomes a new machine must meet. It replaces a golden image. `83te` (first host, ~2026-07) is generation 1 of the path, not the path for every later machine.

## Standing order

For every issue / applied change:

1. Assign next free `CHG-00N` (Session *N* · no gaps).
2. Update the README outcome, not a new roman-numeral chapter:
   - Add a **Generations** bullet when this is a new machine or image.
   - Add a row to that outcome's table: when · host · component · challenge · how it was overcome · CR.
   - Append the CHG under that outcome with **Objective** · **Challenge** · **Paths** · **Execute** · **Backout**, so the old procedure stays readable.
3. Add a **Changelog** row (date · host · status · risk · surfaces).
4. Backup: `*.bak.chg00N.<YYYYMMDD-HHMMSS>`
5. Optional: `docs/chg00N-*.md` + `scripts/chg00N-*` if needed.
6. Never edit `~/.local/share/omarchy/`.
7. High-risk disk work: label **High**; no casual reverse.
8. **Git writes are human-only.** Never `git add`, `git commit`, `git push`, `git merge`, `git rebase`. Read-only git is fine. Kyle stages, signs (1Password), and pushes. A 1Password deny is intentional — do not retry.
9. A CHG **Objective** is the outcome. **Execute** is history for that host and date. On a newer Omarchy or different hardware, meet the outcome with a new path and record the next CHG. Do not replay another host's hardware steps.
10. Before claiming a host matches the control, run `fish scripts/chg020-status.fish`. `GAP` is unfinished work. `FAIL` means something that should already hold is broken.

## Format (copy)

Outcome table row:

```markdown
| YYYY-MM-DD | `host` | component | what failed or changed | what we did | [NNN](#chg-00n--slug) |
```

Change record, filed under that outcome:

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
- `o7400` — Latitude 7400, undocked (no multi-monitor)  
