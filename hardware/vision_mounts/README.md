# Q8bot Vision Mounts

This folder contains a parameterized OpenSCAD mount for adding Raspberry Pi
Zero 2 W first-person vision to Q8bot without depending on the original CAD
files.

## Files

- `q8bot_pi_zero_2w_mount.scad`: low backpack mount for Raspberry Pi Zero 2 W
  with a front holder for Raspberry Pi Camera Module 3 / Camera Module 3 Wide.
- `q8bot_pi5_power_module_mount.scad`: stacked Raspberry Pi 5 task-module
  mount with a lower 89 x 41 mm dual-18650 UPS/charger board bay and upper Pi 5
  standoffs.
- `q8bot_cm5_nano_b_power_module_mount.scad`: stacked task-module mount for
  Waveshare CM5-NANO-B + Raspberry Pi CM5, using a shallow tray and clamp bars
  because the NANO-B carrier has no mounting holes.
- `q8bot_cm5_nano_b_5v5a_pack_mount.scad`: CM5-NANO-B task-module mount using
  an off-the-shelf 2-cell 5V/5A battery pack instead of the exposed 18650
  UPS/charger board.

## Intended Mounting

The design provides one attachment method:

- A flat underside intended for thin high-bond double-sided tape.

The current repository does not include editable Q8bot CAD/STL files, so the
defaults are conservative prototypes. Measure the real robot before printing a
final version.

## Recommended Print

Use this mount for a Pi Zero 2 W + Camera Module 3 / Camera Module 3 Wide setup.
It is intended as a removable low backpack, with the camera held on a short
front mast for first-person operation.

Install the mount so the configurable access window sits over the onboard XIAO
USB-C connector. The intent is to keep the XIAO USB reachable from above, then
use a short flexible USB OTG/data jumper from the Pi Zero USB data port to the
XIAO USB-C port.

Suggested print settings:

- Material: PETG or tough PLA
- Layer height: 0.16-0.20 mm
- Perimeters: 3
- Infill: 20-30%
- Supports: off for the base; enable only if your slicer flags the camera tabs

Recommended hardware:

- Thin high-bond double-sided tape for attaching the mount to Q8bot.
- M2.5 screws/standoffs for Raspberry Pi Zero 2 W.
- SMA bulkhead pigtail or antenna lead if you use the rear antenna tab. The
  default hole is 6.5 mm; set `antenna_hole_d = 3.2` for a small M3 tie point.

For the Pi 5 task module, use the separate `q8bot_pi5_power_module_mount.scad`
model. It is larger and taller than the Pi Zero backpack: the lower layer holds
the referenced 89 x 41 mm UPS/charger board with the component side from the
reference photo facing down, the board's 18650 battery side facing up, and the
Pi 5 above that battery layer. Keep the robot and task-module batteries
electrically separate for the first prototype; share only the charging input
and data ground unless you add a dedicated protected power path.

For the CM5-NANO-B task module, use `q8bot_cm5_nano_b_power_module_mount.scad`.
The lower UPS/charger board orientation is the same as the Pi 5 version, but
the upper computer layer is a 56 x 41 mm tray with screw-down clamp bars instead
of board standoffs. Add thin rubber or foam between the clamp bars and PCB
edges when assembling so vibration does not rub the carrier board.

For the 5V/5A battery-pack variant, use
`q8bot_cm5_nano_b_5v5a_pack_mount.scad`. It replaces the lower UPS board with a
shallow tray for the referenced 24 x 34 x 66 mm 2-cell pack, plus strap slots.
The CM5-NANO-B layer is raised to leave clearance for a face-down 40-pin GPIO
header between the carrier and the battery pack.

## Parameters To Adjust

Open the `.scad` file and tune these first:

- `xiao_usb_window_x`
- `xiao_usb_window_y`
- `xiao_usb_window_len`
- `xiao_usb_window_w`
- `pi_offset_x`
- `pi_offset_y`
- `cam_tilt_deg`
- `antenna_hole_d`

For Q8bot, keep the camera low and close to the body. A 10-15 degree upward
tilt is a good starting point for first-person operation.

## Export STL

With OpenSCAD installed:

```sh
openscad -o q8bot_pi_zero_2w_mount.stl q8bot_pi_zero_2w_mount.scad
```
