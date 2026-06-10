/*
  Q8bot Raspberry Pi 5 + dual-18650 UPS/charger board task-module mount

  This is a stacked backpack module:
  - lower layer: 89 x 41 mm UPS/charger board, component side from the reference
    photo facing down toward Q8bot, based on the user's reference photo marked
    89 mm outer length, 41 mm outer width, 83 x 37 mm hole spacing
  - middle clearance: two 18650 cells mounted on the board back side, facing up
  - upper layer: Raspberry Pi 5 above the batteries

  Orientation: X is robot length, Y is robot width, Z is height. The camera
  holder is at +X/front, following the Pi Zero mount style.

  Print orientation: base plate flat on bed.
  Suggested material: PETG or tough PLA.
*/

$fn = 36;
eps = 0.12;

// -------------------- User parameters --------------------
plate_len = 104;
plate_w = 64;
plate_t = 2.2;
corner_r = 3.5;

// Keep a flat underside for double-sided tape. These access windows are only
// for USB/ribbon routing and can be tuned after checking the real robot.
xiao_usb_window_x = -18;
xiao_usb_window_y = 0;
xiao_usb_window_len = 34;
xiao_usb_window_w = 20;

usb_route_slot_x = 11;
usb_route_slot_y = 0;
usb_route_slot_len = 34;
usb_route_slot_w = 10;

// Two 18650 cells sit on the back side of the UPS board, facing upward toward
// the Pi. Keep enough air above the power board so the cells and clips clear
// the Pi standoff layer.
cell_d = 18.6;
cell_len = 67.5;
cell_spacing_y = 20.0;
cell_clearance = 1.2;
cell_offset_x = 0;
cell_offset_y = 0;

// Lower UPS/charger board from reference image. The reference-photo side faces
// down, so this bottom clearance is for the USB-C, inductors, capacitors, and
// other components visible in the photo.
ups_len = 89;
ups_w = 41;
ups_hole_x = 83;
ups_hole_y = 37;
ups_hole_d = 3.2;       // M3 clearance
ups_component_clearance = 12.0;
ups_standoff_h = ups_component_clearance;
ups_standoff_od = 6.8;
ups_offset_x = 0;
ups_offset_y = 0;
ups_edge_rail_h = 2.2;
ups_edge_rail_t = 1.6;
ups_board_t = 1.6;
cell_top_clearance = 3.0;

// Raspberry Pi 5 board.
pi_len = 85;
pi_w = 56;
pi_hole_x = 58;
pi_hole_y = 49;
pi_hole_d = 2.75;       // M2.5 clearance
pi_standoff_od = 6.0;
pi_layer_h = ups_standoff_h + ups_board_t + cell_d + cell_clearance + cell_top_clearance;
pi_offset_x = 0;
pi_offset_y = 0;

// Small ledges under the Pi standoffs improve stiffness without enclosing the
// lower charger board.
pi_foot_len = 14;
pi_foot_w = 9;

// Front camera module holder, default for Raspberry Pi Camera Module 3.
cam_board_w = 25;
cam_board_h = 24;
cam_pocket_depth = 2.0;
cam_wall = 1.5;
cam_tilt_deg = 12;
cam_mast_h = 24;
cam_mast_x = plate_len / 2 - 4;
cam_screw_x = 21;
cam_screw_y = 12.5;
cam_screw_d = 2.2;      // clearance for M2
cam_web_w = 4.0;

ribbon_slot_x = cam_mast_x - 8;
ribbon_slot_w = 20;
ribbon_slot_l = 5;

// Rear antenna tab, vertical like the latest Pi Zero mount direction.
antenna_enabled = true;
antenna_tab_w = 16;
antenna_tab_len = 14;
antenna_tab_t = 3.0;
antenna_tab_raise = 24.0;
antenna_base_len = 30.0;
antenna_base_w = 18.0;
antenna_post_w = 3.2;
antenna_post_t = 4.2;
antenna_hole_d = 6.5;
antenna_x = -plate_len / 2 - 10;
antenna_y = 0;
antenna_post_y_spacing = 10.0;

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
    translate([-len / 2 + w / 2, 0, 0])
      cylinder(h = h, r = w / 2, center = true);
    translate([ len / 2 - w / 2, 0, 0])
      cylinder(h = h, r = w / 2, center = true);
  }
}

module base_plate() {
  difference() {
    union() {
      rounded_box([plate_len, plate_w, plate_t], corner_r);

      if (antenna_enabled) {
        translate([antenna_x + antenna_base_len / 2 - 1,
                   antenna_y,
                   0])
          rounded_box([antenna_base_len, antenna_base_w, plate_t], corner_r);

        for (y = [-antenna_post_y_spacing / 2, antenna_post_y_spacing / 2]) {
          translate([antenna_x, y, plate_t / 2 + antenna_tab_raise / 2 - eps])
            cube([antenna_post_t, antenna_post_w, antenna_tab_raise + 3 * eps], center = true);
        }

        translate([antenna_x, antenna_y, plate_t / 2 + antenna_tab_raise])
          rounded_box([antenna_tab_len, antenna_tab_w, antenna_tab_t], corner_r);
      }
    }

    translate([xiao_usb_window_x, xiao_usb_window_y, 0])
      rounded_box([xiao_usb_window_len, xiao_usb_window_w, plate_t + 0.5], 2);

    translate([usb_route_slot_x, usb_route_slot_y, 0])
      slot(usb_route_slot_len, usb_route_slot_w, plate_t + 0.5);

    translate([ribbon_slot_x, 0, 0])
      cube([ribbon_slot_l, ribbon_slot_w, plate_t + 0.5], center = true);

    if (antenna_enabled) {
      translate([antenna_x, antenna_y, plate_t / 2 + antenna_tab_raise])
        cylinder(h = antenna_tab_t + 0.8, r = antenna_hole_d / 2, center = true);
    }
  }
}

module ups_standoffs_and_rails() {
  union() {
    for (x = [-ups_hole_x / 2, ups_hole_x / 2],
         y = [-ups_hole_y / 2, ups_hole_y / 2]) {
      translate([x + ups_offset_x,
                 y + ups_offset_y,
                 plate_t / 2 + ups_standoff_h / 2 - eps])
        difference() {
          cylinder(h = ups_standoff_h + 2 * eps, r = ups_standoff_od / 2, center = true);
          cylinder(h = ups_standoff_h + 0.6 + 2 * eps, r = ups_hole_d / 2, center = true);
        }
    }

    // Low rails locate the lower power board during assembly but keep the USB-C
    // and pads reachable from the sides.
    for (y = [-1, 1]) {
      translate([ups_offset_x,
                 y * (ups_w / 2 + ups_edge_rail_t / 2 + 0.5) + ups_offset_y,
                 plate_t / 2 + ups_edge_rail_h / 2 - eps])
        cube([ups_len - 12, ups_edge_rail_t, ups_edge_rail_h + 2 * eps], center = true);
    }
  }
}

module pi5_standoffs() {
  for (x = [-pi_hole_x / 2, pi_hole_x / 2],
       y = [-pi_hole_y / 2, pi_hole_y / 2]) {
    translate([x + pi_offset_x, y + pi_offset_y, plate_t / 2 + 0.7])
      rounded_box([pi_foot_len, pi_foot_w, 1.4], 2);

    translate([x + pi_offset_x,
               y + pi_offset_y,
               plate_t / 2 + pi_layer_h / 2 - eps])
      difference() {
        cylinder(h = pi_layer_h + 2 * eps, r = pi_standoff_od / 2, center = true);
        cylinder(h = pi_layer_h + 0.8 + 2 * eps, r = pi_hole_d / 2, center = true);
      }
  }
}

module side_lattice() {
  // Two longitudinal ribs make the tall Pi layer less wobbly without boxing in
  // the charger board heat sources.
  rib_h = pi_layer_h - 5;
  rib_t = 2.0;
  rib_len = 72;
  for (y = [-1, 1]) {
    translate([0,
               y * (pi_w / 2 + rib_t / 2 + 1.0),
               plate_t / 2 + rib_h / 2 - eps])
      cube([rib_len, rib_t, rib_h + 2 * eps], center = true);
  }
}

module camera_holder() {
  outer_w = cam_board_w + 2 * cam_wall;
  outer_h = cam_board_h + 2 * cam_wall;

  difference() {
    union() {
      translate([0, 0, outer_h / 2])
        cube([outer_w, cam_wall, outer_h], center = true);
      for (x = [-1, 1]) {
        translate([x * (cam_board_w / 2 + cam_wall / 2), -cam_pocket_depth / 2, outer_h / 2])
          cube([cam_wall, cam_pocket_depth + cam_wall, outer_h], center = true);
      }
      translate([0, -cam_pocket_depth / 2, cam_wall / 2])
        cube([outer_w, cam_pocket_depth + cam_wall, cam_wall], center = true);
    }

    translate([0, -cam_wall / 2, outer_h / 2])
      cylinder(h = cam_wall + 0.6, r = 5.5, center = true);

    for (x = [-cam_screw_x / 2, cam_screw_x / 2],
         z = [outer_h / 2 - cam_screw_y / 2, outer_h / 2 + cam_screw_y / 2]) {
      translate([x, -cam_pocket_depth / 2, z])
        rotate([90, 0, 0])
          cylinder(h = cam_pocket_depth + 2 * cam_wall + 1.2, r = cam_screw_d / 2, center = true);
    }

    translate([0, -cam_wall / 2, cam_wall + 3])
      cube([15, cam_wall + 0.6, 6], center = true);
  }
}

function outer_w_for_camera() = cam_board_w + 2 * cam_wall;

module front_mast() {
  mast_x = cam_mast_x;
  union() {
    translate([mast_x, 0, plate_t / 2 + (cam_mast_h + 5) / 2 - eps])
      cube([3.2, cam_board_w + 2 * cam_wall, cam_mast_h + 5 + 2 * eps], center = true);

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

module pi5_power_module_mount() {
  union() {
    base_plate();
    ups_standoffs_and_rails();
    pi5_standoffs();
    side_lattice();
    front_mast();
  }
}

pi5_power_module_mount();
