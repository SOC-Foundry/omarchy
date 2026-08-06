# CHG-010 — AUX desk headset in the chain

> `10` · **Ready** · 2026-08-05 · `83te`  
> Home: [Ch IV · 010](../README.md#chg-010--aux-desk-headset-in-the-chain) · [log](../README.md#chg-log) · [register](../README.md#chg-register)  
> Appends Ch IV (baseline [CHG-007](chg007-audio-precedence-qos.md))

---

## Summary

| Item | Detail |
|------|--------|
| Goal | Permanently-plugged desk **AUX 3.5mm** ranks after Lenovo USB-C and before built-in I/O |
| Order | P30i → Lenovo USB-C → **AUX** → built-in speakers/dmic → USB camera mic |
| Fix | sof pro-audio map: `pro-output-0` / `pro-input-1` are **Jack Out/In**, not speakers/dmic |
| Speakers / dmic | `pro-output-2` / `pro-input-10` at priority ~400 |
| AUX priority | ~1000 (between USB-C 1500 and built-in 400) |

## Device order

| Priority | Output | Input | `priority.session` |
|----------|--------|--------|--------------------|
| 1 | soundcore P30i | P30i HFP mic | 2500 |
| 2 | Lenovo USB-C | Lenovo mic | 1500 |
| 3 | AUX Jack Out (`pro-output-0`) | AUX Jack In (`pro-input-1`) | 1000 |
| 4 | Built-in speakers (`pro-output-2`) | Built-in dmic (`pro-input-10`) | 400 |
| last | — | USB camera mic | 50 |

## sof-soundwire map

| ALSA | Node | Physical |
|------|------|----------|
| `hw:sofsoundwire,0` | `pro-output-0` | AUX Jack Out |
| `hw:sofsoundwire,1` | `pro-input-1` | AUX Jack In |
| `hw:sofsoundwire,2` | `pro-output-2` | Built-in speakers |
| `hw:sofsoundwire,10` | `pro-input-10` | Built-in DMIC |

Jack sense (follower skips AUX when unplugged):

```fish
amixer -c sofsoundwire cget name='Headphone Jack'
amixer -c sofsoundwire cget name='Headset Mic Jack'
```

## Repo artifacts

| Path | Role |
|------|------|
| `config/wireplumber/wireplumber.conf.d/50-device-precedence.conf` | Priorities + nicks + enable/disable pro nodes |
| `bin/audio-precedence-follow` | Pick order + jack sense + EQ glue |
| `scripts/chg010-apply.sh` | Apply (`*.bak.chg010.*`) |
| `scripts/chg010-verify.fish` | Verify five-tier chain |
| `scripts/chg007-backout.sh` | Backout (prefers `*.bak.chg010.*`) |

## Apply / verify

```fish
bash scripts/chg010-apply.sh
fish scripts/chg010-verify.fish
~/.local/bin/audio-precedence-follow --print
```

## Backout

```fish
bash scripts/chg007-backout.sh          # full stack
bash scripts/chg007-backout.sh --soft   # EQ + watcher only
```

## Notes

Full checklist (“how to add another audio I/O”): **README Chapter IV → CHG-010**.  
Baseline stack design (EQ, services, backout detail): **CHG-007** / `docs/chg007-audio-precedence-qos.md`.
