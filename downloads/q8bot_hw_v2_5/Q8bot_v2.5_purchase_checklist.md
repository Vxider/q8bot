# Q8bot v2.5 Purchase Checklist

This checklist is based on the official `hw-v2.5` release package and assumes
you will order the bare PCB and solder the board yourself.

## Core Off-The-Shelf Parts

| Item | Qty | Notes |
|---|---:|---|
| ROBOTIS DYNAMIXEL XL330-M077-T | 8 | Motors include the M2 self-tapping screws used for assembly. |
| 692ZZ bearing, 2 x 6 x 3 mm | 12 | Buy extras; they are cheap and easy to lose. |
| 14500 protected Li-ion cell, KeepPower P1450C2 or equivalent | 2 | Regular AA batteries will not work. Buy more pairs if you want hot swapping. |
| 14500-compatible Li-ion charger | 1 | Needed unless you already have one. |
| Seeed Studio XIAO ESP32C3 | 2 | One on the robot PCB, one as the ESP-NOW controller/dongle. |
| Keystone 1087-1 battery clip | 2 | Battery clip, one polarity. |
| Keystone 1087-2 battery clip | 2 | Battery clip, opposite polarity. |

## PCB Manufacturing

| Item | Qty | Notes |
|---|---:|---|
| Q8bot v2.5 bare PCB | 1+ | FR-4, 2 layers, 1.6 mm, 1 oz copper. Order extras if hand soldering. |
| Top/bottom stencil | 1 set | Strongly recommended for hand reflow. |

## PCB Components

| Ref | Qty | Part / Value | Package | Notes |
|---|---:|---|---|---|
| R8 | 1 | 22 ohm, 1%, 0603 | 0603 | Generic resistor OK. |
| R1 | 1 | 200 ohm, 1%, 0603 | 0603 | Generic resistor OK. |
| R2, R3, R4, R6, R7 | 5 | 10K, 1%, 0603 | 0603 | Generic resistor OK. |
| R5, R9 | 2 | 1K, 1%, 0603 | 0603 | Generic resistor OK. |
| C1 | 1 | 0.1uF, >=25V, X5R/X7R | 0603 | Generic capacitor OK. |
| C2, C3, C7, C8 | 4 | 10uF, >=25V, X5R/X7R | 0805 | Generic capacitor OK. |
| C5 | 1 | 1uF, >=25V, X5R/X7R | 0603 | Generic capacitor OK. |
| C6 | 1 | 10nF, >=25V, X5R/X7R | 0603 | Generic capacitor OK. |
| C4, C9 | 2 | 47uF, 16V aluminum/polymer capacitor | SMD can | Original: Wurth 865080342006. |
| D1 | 1 | Red LED | 0603 | Generic red LED OK, check polarity. |
| D2 | 1 | Schottky diode, 20V 1A | SOD-323 | Original: NSR0320MW2T1G. |
| Q1, Q2 | 2 | P-channel MOSFET, 12V 9A | 6-MCPH | Original: MCH6351-TL-W. |
| S1 | 1 | SPDT slide switch | SMD switch | Original: E-Switch EG1215AA. |
| U2 | 1 | SN74LVC2G241DCUR buffer | VSSOP-8 | Check orientation. |
| U3, U5 | 2 | TPS610333DRLR boost converter | SOT583 | Fine-pitch; stencil/hot air recommended. |
| U4 | 1 | MAX17043G+T fuel gauge | 8-TDFN | Optional; robot can run without it if unavailable. |
| L1, L2 | 2 | 0.47uH high-current inductor | 1616 | Original: Coilcraft XGL4020-471MEC. |
| U1 | 1 | Seeed Studio XIAO ESP32C3, no headers | Module | Solder orientation is important; USB/buttons face outward/down per official note. |
| J1-J8 | 8 | 1x3 2.54mm receptacle strip | Through-hole | DYNAMIXEL connectors. Direction/side matters. |
| J9 | 1 | JST SH 4-pin SMD header | JST SH | Original: BM04B-SRSS-TBT(LF)(SN). |
| BT1, BT2 | 2 | Battery clip footprints | DNP in BOM | Use Keystone clips listed above, installed with frame. |

## 3D Printed Parts

Choose either the FDM or MJF STL set from the official release.

| Part | Qty |
|---|---:|
| Frame | 2 |
| Lower leg left | 4 |
| Lower leg right | 4 |
| Upper leg short | 4 |
| Upper leg tall | 4 |

FDM files are in:

`downloads/q8bot_hw_v2_5/hw-v2.5/CAD/Q8_V2.5_FDM/`

MJF files are in:

`downloads/q8bot_hw_v2_5/hw-v2.5/CAD/Q8_V2.5_MJF/`

## Tools And Consumables

| Item | Notes |
|---|---|
| PH-0 or JIS-1 screwdriver | Needed for Dynamixel screws. |
| Soldering iron, solder, flux | Required for hand assembly. |
| Hot plate or hot air station | Strongly recommended for SMD assembly. |
| Solder paste | Use with stencil for U3/U5/U4 and passives. |
| Fine tweezers | Required for 0603 and fine-pitch parts. |
| USB-C cable | Firmware upload and debug. |
| Masking tape | Useful during Dynamixel shell removal. |

## Optional Debug Tools

| Item | Notes |
|---|---|
| ROBOTIS U2D2 + U2D2 Power Hub | Helpful for configuring/debugging Dynamixel motors. |
| Extra XIAO ESP32C3 or ESP-NOW dongle PCB | Useful if you want a dedicated controller. |

## Hand-Soldering Notes

- Order extra 0603 passives; losing parts during hand assembly is normal.
- Consider leaving `U4` MAX17043 unpopulated if it is hard to source. It only
  provides battery percentage reporting.
- Verify `U1`, `J1-J8`, `D1`, `D2`, `Q1/Q2`, `U2`, `U3/U5`, and `U4` orientation
  before reflow.
- For J1-J8, the official notes say the silkscreen marking side is where the
  components should be placed and solder joints are on the opposite side.
