# CHG-017 — Three-tier audio failover (83te)

**Applied 2026-09-09.** Operator design: soundcore P30i → Lenovo USB-C → built-in speakers/dmic.

Keeps the CHG-010 sof-soundwire PCM map (`pro-output-2` / `pro-input-10` are the laptop). Drops AUX 3.5mm (`pro-output-0` / `pro-input-1`) from automatic failover so unplugging USB-C does not land on the jack.

| Priority | Output | Input |
|----------|--------|--------|
| 2500 | soundcore P30i (A2DP) | P30i HFP mic (only if headset profile) |
| 1500 | Lenovo USB-C | Lenovo USB-C mic |
| 400 | Built-in speakers | Built-in dmic |
| 50 | — | USB camera mic |

Jack nodes are `node.disabled`. Camera stays last.
