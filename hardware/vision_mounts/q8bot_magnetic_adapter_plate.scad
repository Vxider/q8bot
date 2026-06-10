/*
  Q8bot robot-side magnetic adapter plate

  This thin plate is taped to the robot body and provides the matching magnetic
  targets for the CM5-NANO-B task-module mount. It avoids relying on the Q8bot
  plastic frame itself being magnetic or having solid material under every
  task-module magnet.

  Orientation: X is robot length, Y is robot width, Z is height.
  Print orientation: flat side on the bed.
*/

$fn = 48;
eps = 0.12;

// Keep this narrow enough for the robot body, but wide enough to cover the
// task-module magnet pattern.
adapter_len = 92;
adapter_w = 44;
adapter_t = 2.8;
corner_r = 3.0;

// Must match q8bot_cm5_nano_b_5v5a_pack_mount.scad.
magnet_d = 8.2;
magnet_depth = 2.1;
magnet_x_spacing = 70;
magnet_y_spacing = 32;

// Optional center clearance so USB/ribbon wires can still pass through between
// robot and task module.
center_window_len = 36;
center_window_w = 18;
front_cable_slot_x = 18;
front_cable_slot_len = 26;
front_cable_slot_w = 8;

// Shallow underside tape pockets leave a raised rim so tape thickness is easier
// to manage. Set tape_pocket_depth = 0 if you want a completely flat underside.
tape_pocket_depth = 0.35;
tape_pad_len = 34;
tape_pad_w = 12;
tape_pad_x_spacing = 44;

module rounded_box(size, r) {
  x = size[0];
  y = size[1];
  z = size[2];
  hull() {
    for (sx = [-1, 1], sy = [-1, 1]) {
      translate([sx * (x / 2 - r), sy * (y / 2 - r), 0])
        cylinder(h = z, r = r, center = true);
    }
  }
}

module slot(len, w, h) {
  hull() {
    translate([-len / 2 + w / 2, 0, 0])
      cylinder(h = h, r = w / 2, center = true);
    translate([ len / 2 - w / 2, 0, 0])
      cylinder(h = h, r = w / 2, center = true);
  }
}

module magnet_pockets_from_top() {
  for (x = [-magnet_x_spacing / 2, magnet_x_spacing / 2],
       y = [-magnet_y_spacing / 2, magnet_y_spacing / 2]) {
    translate([x, y, adapter_t / 2 - magnet_depth / 2 + eps])
      cylinder(h = magnet_depth + 2 * eps, r = magnet_d / 2, center = true);
  }
}

module underside_tape_pockets() {
  if (tape_pocket_depth > 0) {
    for (x = [-tape_pad_x_spacing / 2, tape_pad_x_spacing / 2]) {
      translate([x, 0, -adapter_t / 2 + tape_pocket_depth / 2 - eps])
        rounded_box([tape_pad_len, tape_pad_w, tape_pocket_depth + 2 * eps], 1.8);
    }
  }
}

module adapter_plate() {
  difference() {
    rounded_box([adapter_len, adapter_w, adapter_t], corner_r);

    // Matching top pockets for 8 x 2 mm magnets, steel disks, or washers.
    magnet_pockets_from_top();

    // Cable clearance roughly matches the task-module underside windows.
    translate([0, 0, 0])
      rounded_box([center_window_len, center_window_w, adapter_t + 0.6], 2.0);

    translate([front_cable_slot_x, 0, 0])
      slot(front_cable_slot_len, front_cable_slot_w, adapter_t + 0.6);

    underside_tape_pockets();
  }
}

adapter_plate();
