# CHG-016 — USB-C hub power-cycle (83te)

Read-only diagnosis. No config or package changes.

**Recovered 2026-09-08 ~19:22 PDT.** Root cause was power: an **Anker USB-C hub was daisy-chained downstream of both the Ugreen and the new hub**, and the new/Ugreen pair were not on dedicated PSUs. Operator put **Ugreen and the new hub on their own power**; storm stopped. Last `attempt power cycle` **19:22:18**; Genesys tree stable from **19:22:21** (devnums `2-4`=8, `3-2`=48 held).

Standing as-built (ports, loads, PSU rules, DVD parked): **[CHG-018](chg018-second-usbc-hub-as-built.md)**. This file is the incident log.

Host `83te` (Yoga 83TE). Hubs:

| Hub | Where | Ethernet | Power |
|-----|--------|----------|--------|
| **Anker Nano 13-in-1** (desk dock) | Type-C **port0** (`usb 2-3` / `usb 3-1`) | Yes — desk LAN `enp0s13f0u3u1` | Dock / PD |
| **Ugreen** (first hub) | Downstream of new hub USB3 `usb 2-4.1` RTL8153 SN `DF1300E04C270960` | Yes — **unused** (`enp0s13f0u4u1` DOWN, no carrier) | Dedicated PSU (as of 19:22) |
| **New hub** (was flapping) | Type-C **port1** (`usb 2-4` / `usb 3-2`), GenesysLogic `05e3:0626`/`05e3:0610` | **None** | Dedicated PSU (as of 19:22) |
| **Anker USB-C hub** (third) | Was daisy-chained off Ugreen **and** the new hub | n/a | Removed from that chain |

A VLI billboard `2109:0103` is still on `3-2.1.1` (camera nested hub). If that is leftover Anker USB-C on the camera’s extra port, unplug it.

## Verdict

- **No block I/O errors** this boot (before or after).
- **USB protocol storm 19:01–19:22:** `err = -71` (`EPROTO`) + nested-hub `attempt power cycle` ~every 2 s. Daisy-chain + no dedicated PSU.
- **After dedicated power:** no power-cycle, no `EPROTO`. One later disconnect was the DVD moving ports + headset plug-in, not a hub reset.

## Counts (since 19:01, sampled ~19:11)

| Signal | Count |
|--------|------:|
| `USB disconnect` | 1244+ |
| `attempt power cycle` | 554+ |
| `hub_ext_port_status failed (err = -71)` | 63+ |
| Genesys USB3.1 hub (`05e3:0626`) new | 315+ |
| Genesys USB2.1 hub (`05e3:0610`) new | 266+ |
| QinHeng nested hub (`1a86:8095`) new | 261+ |
| Sonix camera (`0c45:636b`) new | 259+ |
| Ugreen RTL8153 on new-hub USB3 (`0bda:8153` SN `DF1300E04C270960`) | 49 |
| `I/O error` | **0** |
| USB device number high water | **127** (wrap) |

Storm sampled ~19:11 while still looping.

## Topology after recovery (~19:25)

```
Yoga PCH xHCI 00:14.0
  usb 2-4  NEW hub / GenesysLogic USB3.1 Hub  05e3:0626   (dev 8, 5000M, dedicated PSU)
    2-4.1  Ugreen RTL8153 LAN                 0bda:8153   (unused, enp0s13f0u4u1 DOWN)
  usb 3-2  NEW hub / GenesysLogic USB2.1 Hub  05e3:0610   (dev 48)
    3-2.1  QinHeng USB Hub                    1a86:8095   (camera's hub)
      3-2.1.1  VLI USB 2.0 BILLBOARD          2109:0103   (leftover USB-C?)
      3-2.1.2  Sonix USB 2.0 Camera           0c45:636b   (/dev/video4-5 + snd Camera)
    3-2.3  Pioneer BD-RW BDR-UD03             13fd:0840   (/dev/sr0, Initio bridge)
    3-2.4  QinHeng USB Hub                    1a86:8095
      3-2.4.1  Xbox One Controller            045e:02ea   (xpad joystick)
      3-2.4.3  Lenovo USB-C headset           17ef:a05f   (snd Headp)

Anker dock (stable, other port):
  usb 2-3.1  Realtek RTL8153  →  enp0s13f0u3u1   (desk LAN, UP)
```

## Topology during storm (19:01–19:22)

```
Yoga PCH xHCI 00:14.0
  usb 2-4  NEW hub / GenesysLogic USB3.1 Hub  05e3:0626   (4 ports, no RJ-45)
    2-4.1  Ugreen RTL8153 LAN                 0bda:8153   (first hub, unused)
  usb 3-2  NEW hub / GenesysLogic USB2.1 Hub  05e3:0610   (4 ports)
    3-2.1  QinHeng USB Hub                    1a86:8095
      3-2.1.2  Sonix USB 2.0 Camera           0c45:636b
      3-2.1-port4  ← kernel "attempt power cycle"
    3-2.4  QinHeng USB Hub                    1a86:8095
      3-2.4.1  Xbox Controller                045e:02ea  (Actions)
      3-2.4-port3  ← kernel "attempt power cycle"

Anker dock (stable, other port):
  usb 2-3.1  Realtek RTL8153  →  enp0s13f0u3u1   (desk LAN)
```

**Seen briefly on the new hub:** camera, Xbox pad (`045e:02ea`). **Not seen:** Lenovo USB-C headset (`17ef:a05f`), USB-storage / UAS / `sr0` (DVD). Headset *was* on `usb 3-2` at boot (direct to the laptop port) until the new hub replaced it.

## Failure pattern (every cycle)

1. Hub + nested QinHeng hub + camera appear.
2. `usb 3-2.1-port4: attempt power cycle` then `usb 3-2-port4: attempt power cycle`.
3. `hub 2-4:1.0: hub_ext_port_status failed (err = -71)`.
4. Entire Genesys tree disconnects; USB address increments; repeat.

Tripwire is nested-hub ports that never finish reset: `3-2.1-port4` and `3-2.4-port3` (DVD / headset / extra current). Camera and Xbox pad do complete a descriptor read, then the parent Genesys hub dies.

## USB-C role fight on port1

`/sys/class/typec/port1` while the hub is in:

- `data_role` stuck **`[device]`** (laptop UFP). Host xHCI still tries to enumerate anyway.
- `power_role` flips **sink ↔ source** on a sub-second poll.
- `power_operation_mode` flips **`usb_power_delivery` ↔ `3.0A`** (5 V / 3 A, 15 W).

Port0 (Anker dock) stays `power_role=[sink] data_role=[host] power_operation_mode=usb_power_delivery` — healthy.

A bus-powered or weakly-PSU hub plus camera + DVD + headset + pad + a daisy-chained Ugreen exceeds 15 W. DVD spindles alone often want ~5 V / 1 A.

## Isolation (operator) — done

1. Pull the **Anker USB-C hub** out from downstream of Ugreen and the new hub. Do not daisy-chain hubs.
2. Dedicated PSU on **Ugreen** and on the **new hub**.
3. Optional: unplug leftover VLI billboard on the camera hub (`3-2.1.1`).

Watch:

```bash
journalctl -k -f | grep -E 'usb (2-4|3-2)|err = -71|power cycle|I/O error'
```

## Software

None applied. No udev quirk, no `usbcore.autosuspend`, no kernel cmdline. Hardware / power / port-role first.

No udev on `0bda:8153`. Anker dock LAN is the live desk NIC. Ugreen’s NIC is a different hub; unplug that chain rather than blacklisting the VID/PID.

## Backout

Unplug the new hub. Anker dock, Keychron, trackball, built-in camera are on other buses and were not in the flap.
