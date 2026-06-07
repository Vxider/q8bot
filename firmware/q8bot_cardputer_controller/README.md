# Q8bot Cardputer Controller

Dedicated M5Stack Cardputer firmware for controlling Q8bot directly over ESP-NOW.
This firmware replaces the PC + ESP32C3 serial dongle flow with a handheld UI,
keyboard input, local gait generation, and telemetry display.

## UI

The Cardputer display is organized into two pages.

Control page:

- Header: connection state, active gait, torque state, robot battery.
- Left: movement pad for `W/A/S/D` plus `Q/E` partial forward turns.
- Right: action chips for `J` jump, `G` gait, `H` greet, `B` battery.
- Footer: current status and page switch hint.

Telemetry page:

- Battery percentage from the robot fuel gauge.
- Joint telemetry sample/pull status.
- Body attitude placeholder. The current Q8bot robot firmware does not expose
  roll/pitch/yaw because no IMU path is present in this repository yet.

## Key Map

| Key | Action |
| --- | --- |
| `W/A/S/D` | Move forward/left/back/right |
| `Q/E` | Forward with partial left/right turn |
| `J` | Jump |
| `G` | Switch gait |
| `R` | Gait reset / idle pose |
| `H` | Greet routine |
| `B` | Request battery level |
| `C` | Show range demo |
| `Z` | Toggle record next movement and sample joint telemetry |
| `X` | Pull recorded telemetry chunks |
| `T` | Toggle torque |
| `P` | Clear saved pairing and re-pair |
| `Tab` | Switch between control and telemetry pages |

The action set mirrors the existing Python UI documented by
`python-tools/docs/Instruction_Default.jpg` and
`python-tools/docs/Instruction_Joystick.jpg`.

## Gaits

The first version ports the TROT-family gaits from the Python controller:

- `TROT`
- `HIGH`
- `LOW`
- `FAST`

The firmware generates trajectories locally on the Cardputer using the same
inverse kinematics parameters as `python-tools/q8bot/operate.py`.

## Build

Open this directory in PlatformIO and build/upload the default environment:

```sh
pio run -e cardputer_permanent -t upload
```

The current shell used during development did not have `pio` installed, so this
firmware still needs a hardware build/upload pass against the local PlatformIO
installation before field use.

## Pairing

The firmware uses the same ESP-NOW message protocol as:

- `firmware/q8bot_controller`
- `firmware/q8bot_robot`

`cardputer_permanent` stores the paired robot MAC in NVS. Press `P` to clear it.
Use `cardputer_auto` if you want timeout-based re-pairing behavior.
