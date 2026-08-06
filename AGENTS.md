# Agent instructions — Omarchy change ledger

This repository is a **field manual / change ledger**, not the Omarchy distro itself.

## Standing order: CHG + README on every issue

For **every** issue, investigation, or applied change the operator presents in this repo (or on hosts managed by this ledger):

1. **Do not wait to be asked** to document it.
2. Assign the **next free** `CHG-00N` (Session *N* ↔ `CHG-00N`; no gaps).
3. Update in the same turn as the fix (or immediately after it lands):
   - **[CHG log](README.md#chg-log)** row (date, title, host, status, home link)
   - **Home chapter** section (`## CHG-00N — …`) — append existing chapter if same topic; else open next chapter
   - **`docs/chg00N-*.md`** formal note (Summary · Config · Apply · Verify · Backout)
   - **Table of contents** primary-CHG links when appending a chapter
   - **Edition footer** (“Last applied CHG”)
   - **Roadmap** — renumber tentative IDs if they collide with the new free integer
4. Prefer backups `*.bak.chg00N.<timestamp>`.
5. User-space only: `~/.config/` + this repo. Never edit `~/.local/share/omarchy/`.
6. Every CHG ends with **Backout**. Destructive disk work must be labeled.

Full conventions: [Appendix A](README.md#appendix-a--conventions-for-the-next-chapter).

## Style

- Match existing CHG prose (tables, checklists, verify/backout).
- Cross-link supersessions (e.g. CHG-011 corrected CHG-009 refresh only).
- Hostnames: `83te` (Yoga docked), `p3oos` (desk tower).
