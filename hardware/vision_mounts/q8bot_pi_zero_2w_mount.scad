/*
  Q8bot Raspberry Pi Zero 2 W + Camera Module 3 Wide backpack mount

  The Pi rides low and lengthwise on top of Q8bot. The camera is held on a
  small front mast with a flexible ribbon pass-through. This is intentionally
  a removable backpack for double-sided tape mounting.

  Orientation: Q8bot's onboard XIAO USB-C is exposed on the outward/top electronics
  face. The mount leaves a configurable access window over that connector so a
  short USB jumper can run from the Pi Zero USB data port to the XIAO.

  Print orientation: backpack plate flat on bed.
  Suggested material: PETG or tough PLA.
*/

$fn = 36;
eps = 0.12;

// -------------------- User parameters --------------------
plate_len = 84;
plate_w = 38;
plate_t = 1.8;
corner_r = 3;

// XIAO USB-C access window on the Q8bot electronics face.
// Tune these after measuring your assembled robot.
xiao_usb_window_x = -17;
xiao_usb_window_y = -8;
xiao_usb_window_len = 24;
xiao_usb_window_w = 12;

// Raised rear antenna mount for an external Wi-Fi antenna pigtail. The default
// hole fits many SMA bulkhead connectors; reduce to 3.2 for a small M3 tie point.
antenna_tab_w = 16;
antenna_tab_len = 14;
antenna_tab_t = 3.0;
antenna_tab_overlap = 2.0;
antenna_tab_raise = 20.0;
antenna_tail_y_spacing = 10.0;
antenna_base_len = 22.0;
antenna_base_w = 18.0;
antenna_post_w = 3.0;
antenna_post_t = 4.0;
antenna_hole_d = 6.5;
antenna_hole_x = -plate_len / 2 - 10;
antenna_hole_y = 0;

// Raspberry Pi Zero 2 W board.
pi_len = 65;
pi_w = 30;
pi_hole_x = 58;
pi_hole_y = 23;
pi_hole_d = 2.75;       // M2.5 clearance
pi_standoff_h = 4.5;
pi_standoff_od = 5.2;
pi_offset_x = -2;       // keep Pi low and slightly back from the camera mast
pi_offset_y = 0.0;

// Clearance/strain relief for a short Pi USB OTG -> XIAO USB-C cable.
usb_exit_slot_len = 12;
usb_exit_slot_w = 6;
usb_exit_x = xiao_usb_window_x + xiao_usb_window_len / 2 + usb_exit_slot_len / 2 + 2;
usb_exit_y = xiao_usb_window_y;

// Front camera module holder, default for Raspberry Pi Camera Module 3.
cam_board_w = 25;
cam_board_h = 24;
cam_pocket_depth = 2.0;
cam_wall = 1.5;
cam_tilt_deg = 15;
cam_mast_h = 19;
cam_mast_x = plate_len / 2 - 3;
cam_screw_x = 21;
cam_screw_y = 12.5;
cam_screw_d = 2.2;      // clearance for M2
cam_backbone_t = 2.0;
cam_web_w = 4.0;

ribbon_slot_x = cam_mast_x - 5;
ribbon_slot_w = 18;
ribbon_slot_l = 4;

// -------------------- Helpers --------------------
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
    translate([-len / 2 + w / 2, 0, 0]) cylinder(h = h, r = w / 2, center = true);
    translate([ len / 2 - w / 2, 0, 0]) cylinder(h = h, r = w / 2, center = true);
  }
}

module base_plate() {
  difference() {
    union() {
      rounded_box([plate_len, plate_w, plate_t], corner_r);

      translate([antenna_hole_x, antenna_hole_y, plate_t / 2 + antenna_tab_raise])
        rounded_box([antenna_tab_len, antenna_tab_w, antenna_tab_t], corner_r);

      translate([antenna_hole_x + antenna_tab_len / 2 - antenna_tab_overlap / 2,
                 antenna_hole_y,
                 0])
        rounded_box([antenna_base_len, antenna_base_w, plate_t], corner_r);

      for (y = [-antenna_tail_y_spacing / 2, antenna_tail_y_spacing / 2]) {
        translate([antenna_hole_x, y, plate_t / 2 + antenna_tab_raise / 2])
          cube([antenna_post_t, antenna_post_w, antenna_tab_raise + eps], center = true);
      }
    }

    // External antenna bulkhead/pass-through hole.
    translate([antenna_hole_x, antenna_hole_y, plate_t / 2 + antenna_tab_raise])
      cylinder(h = antenna_tab_t + 0.8, r = antenna_hole_d / 2, center = true);

    // Camera ribbon pass-through near the front.
    translate([ribbon_slot_x, 0, 0])
      cube([ribbon_slot_l, ribbon_slot_w, plate_t + 0.4], center = true);

    // XIAO USB-C access window. Keep this open so the onboard XIAO USB port
    // remains reachable from above after the Pi backpack is installed.
    translate([xiao_usb_window_x, xiao_usb_window_y, 0])
      rounded_box([xiao_usb_window_len, xiao_usb_window_w, plate_t + 0.4], 2);

    // Pi-to-XIAO USB cable pass-through/strain relief route.
    translate([usb_exit_x, usb_exit_y, 0])
      cube([usb_exit_slot_len, usb_exit_slot_w, plate_t + 0.4], center = true);

  }
}

module pi_standoffs() {
  for (x = [-pi_hole_x / 2, pi_hole_x / 2],
       y = [-pi_hole_y / 2, pi_hole_y / 2]) {
    translate([x + pi_offset_x, y + pi_offset_y, plate_t / 2 + pi_standoff_h / 2 - eps])
      difference() {
        cylinder(h = pi_standoff_h + 2 * eps, r = pi_standoff_od / 2, center = true);
        cylinder(h = pi_standoff_h + 0.4 + 2 * eps, r = pi_hole_d / 2, center = true);
      }
  }
}

module camera_holder() {
  outer_w = cam_board_w + 2 * cam_wall;
  outer_h = cam_board_h + 2 * cam_wall;

  difference() {
    union() {
      // Back plate and shallow side pocket.
      translate([0, 0, outer_h / 2])
        cube([outer_w, cam_wall, outer_h], center = true);
      for (x = [-1, 1]) {
        translate([x * (cam_board_w / 2 + cam_wall / 2), -cam_pocket_depth / 2, outer_h / 2])
          cube([cam_wall, cam_pocket_depth + cam_wall, outer_h], center = true);
      }
      translate([0, -cam_pocket_depth / 2, cam_wall / 2])
        cube([outer_w, cam_pocket_depth + cam_wall, cam_wall], center = true);
    }

    // Lens opening.
    translate([0, -cam_wall / 2, outer_h / 2])
      cylinder(h = cam_wall + 0.6, r = 5.5, center = true);

    // Camera board screw holes.
    for (x = [-cam_screw_x / 2, cam_screw_x / 2],
         z = [outer_h / 2 - cam_screw_y / 2, outer_h / 2 + cam_screw_y / 2]) {
      translate([x, -cam_pocket_depth / 2, z])
        rotate([90, 0, 0])
          cylinder(h = cam_pocket_depth + 2 * cam_wall + 1.2, r = cam_screw_d / 2, center = true);
    }

    // Ribbon relief.
    translate([0, -cam_wall / 2, cam_wall + 3])
      cube([15, cam_wall + 0.6, 6], center = true);
  }
}

module front_mast() {
  mast_x = cam_mast_x;
  union() {
    // One connected mast avoids separate shell export and gives better stiffness.
    translate([mast_x, 0, plate_t / 2 + (cam_mast_h + 5) / 2 - eps])
      cube([3, cam_board_w + 2 * cam_wall, cam_mast_h + 5 + 2 * eps], center = true);

    // Split webs tie the tilted camera holder back into the mast while leaving
    // the middle open for the camera ribbon and Pi-side clearance.
    for (y = [-1, 1]) {
      translate([mast_x - 1.8,
                 y * (outer_w_for_camera() / 2 - cam_web_w / 2),
                 plate_t + cam_mast_h - 1.5])
        rotate([cam_tilt_deg, 0, 90])
          cube([cam_web_w, 2.2, 5.0], center = true);
    }

    translate([mast_x, 0, plate_t + cam_mast_h])
      rotate([cam_tilt_deg, 0, 90])
        camera_holder();
  }
}

function outer_w_for_camera() = cam_board_w + 2 * cam_wall;

module pi_zero_mount() {
  union() {
    base_plate();
    pi_standoffs();
    front_mast();
  }
}

pi_zero_mount();
