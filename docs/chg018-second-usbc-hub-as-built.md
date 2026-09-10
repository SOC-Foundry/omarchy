# CHG-018 — Second USB-C hub as-built (83te)

Standing desk USB after [CHG-016](chg016-usbc-hub-power-cycle.md) (incident). No software. Hardware policy.

**Applied 2026-09-09.** Second hub = GenesysLogic on Yoga Type-C **port1**, own PSU. DVD stays off this hub until a dedicated power strip.

## Policy

| Rule | |
|------|--|
| Dedicated PSU | Ugreen **and** the second (Genesys) hub. Do not bus-power either. |
| No daisy-chain | Do not hang an Anker USB-C (or any extra hub) off Ugreen or the second hub. |
| Desk LAN | Anker 13-in-1 RTL8153 `enp0s13f0u3u1` only. Ugreen RJ-45 unused. |
| Second hub loads | Camera + Lenovo USB-C headset + Xbox pad. Not the Pioneer DVD until extra power. |

## As-built (2026-09-09)

Yoga PCH xHCI `00:14.0` · Type-C **port1**

```
usb 2-4   Genesys USB3.1 Hub  05e3:0626  5000M  (dedicated PSU)
  2-4.1   Ugreen RTL8153      0bda:8153  unused  SN DF1300E04C270960
usb 3-2   Genesys USB2.1 Hub  05e3:0610   480M
  3-2.3   Sonix camera+mic    0c45:636b  uvcvideo + snd-usb-audio
  3-2.4.1 Xbox One S pad      045e:02ea  xpad  js0
  3-2.4.3 Lenovo USB-C IEM    17ef:a05f  snd-usb-audio + hid
```

Anker Nano 13-in-1 stays Type-C **port0** (`usb 2-3` / `3-1`): desk LAN, Keychron, trackball.

## Parked

Pioneer BD-RW BDR-UD03 (Initio `13fd:0840`) — needs its own brick / custom strip. Direct Yoga attach still reported SCSI `3A/01` with a disc in the sled. Not a VLC/CSS issue.

## Related

- Incident: [CHG-016](chg016-usbc-hub-power-cycle.md)
- Audio failover on the Lenovo IEM: [CHG-017](chg017-three-tier-audio-failover.md)
