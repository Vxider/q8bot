/*
  Q8bot CM5-NANO-B + 5V/5A 2-cell battery-pack task-module mount

  This is a stacked backpack module:
  - lower layer: off-the-shelf 2-cell 5V/5A battery pack, marked 24 x 34 x 66 mm
  - upper layer: Waveshare CM5-NANO-B carrier + Raspberry Pi CM5 above the pack
  - the CM5-NANO-B is mounted face-down, so the 40-pin GPIO header faces the
    battery pack; extra clearance is reserved for that header and wiring

  Orientation: X is robot length, Y is robot width, Z is height. The camera
  holder is at +X/front, following the Pi Zero mount style.

  Print orientation: base plate flat on bed.
  Suggested material: PETG or tough PLA.
*/

$fn = 36;
eps = 0.12;

// -------------------- User parameters --------------------
plate_len = 104;
plate_w = 52;
plate_t = 2.8;
corner_r = 3.5;

// Magnetic attachment to the Q8bot body. Defaults assume common 8 x 2 mm round
// magnets glued into blind pockets from the underside. The 2.8 mm plate leaves
// about 0.7 mm of printed skin above a 2.1 mm deep pocket.
magnet_d = 8.2;
magnet_depth = 2.1;
magnet_x_spacing = 70;
magnet_y_spacing = 32;
locator_rib_len = 52;
locator_rib_w = 2.0;
locator_rib_h = 1.0;
locator_rib_y_spacing = 24;

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

// Off-the-shelf 2-cell 5V/5A battery pack from the user's reference image.
// The pack is retained by a shallow tray and strap slots instead of screw
// holes, because the pack is shrink-wrapped.
pack_len = 66;
pack_w = 34;
pack_h = 24;
pack_clearance = 1.0;
pack_offset_x = -2;
pack_offset_y = 0;
pack_tray_lip_h = 4.0;
pack_tray_lip_t = 2.0;
pack_floor_t = 1.4;
strap_slot_len = 28;
strap_slot_w = 4.0;
strap_slot_x_spacing = 34;
strap_slot_y = 0;

// Clearance above the pack for the face-down CM5-NANO-B 40-pin header and its
// wiring. Increase this if you use a tall keyed IDC plug.
gpio_header_clearance = 11.0;
cm5_bottom_air_gap = 2.0;

// Waveshare CM5-NANO-B carrier. The board is clamped by printed bars instead
// of board holes. Dimensions from Waveshare: 56 x 41 mm.
cm5_len = 56;
cm5_w = 41;
cm5_tray_clearance = 0.5;
cm5_tray_lip_h = 1.6;
cm5_tray_lip_t = 1.2;
cm5_layer_h = pack_h + gpio_header_clearance + cm5_bottom_air_gap;
cm5_offset_x = -3;      // keep the smaller compute module near center without post clash
cm5_offset_y = 0;
cm5_board_t = 1.6;

// Four outside posts are used with M2.5 screws and small washers/printed tabs
// to clamp the board corners. This avoids walls or fixed bars along the NANO-B
// edges, where connectors are located.
cm5_post_x_spacing = cm5_len + 4;
cm5_post_y_spacing = cm5_w + 4;
cm5_post_screw_d = 2.75;   // M2.5 clearance
cm5_post_od = 6.0;

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
ribbon_slot_w = 22;
ribbon_slot_l = 8;
ribbon_channel_h = 70;

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

    // Blind pockets for underside magnets. The cut starts below the plate and
    // stops before the top face, leaving a thin printed skin above each magnet.
    for (x = [-magnet_x_spacing / 2, magnet_x_spacing / 2],
         y = [-magnet_y_spacing / 2, magnet_y_spacing / 2]) {
      translate([x, y, -plate_t / 2 + magnet_depth / 2 - eps])
        cylinder(h = magnet_depth + 2 * eps, r = magnet_d / 2, center = true);
    }

    if (antenna_enabled) {
      translate([antenna_x, antenna_y, plate_t / 2 + antenna_tab_raise])
        cylinder(h = antenna_tab_t + 0.8, r = antenna_hole_d / 2, center = true);
    }
  }
}

module battery_pack_tray() {
  tray_outer_len = pack_len + 2 * (pack_clearance + pack_tray_lip_t);
  tray_outer_w = pack_w + 2 * (pack_clearance + pack_tray_lip_t);

  union() {
    // Long-side low lips locate the shrink-wrapped pack. Leave the short ends
    // open for the pack wires and connector options.
    for (y = [-1, 1]) {
      translate([pack_offset_x,
                 pack_offset_y + y * (pack_w / 2 + pack_clearance + pack_tray_lip_t / 2),
                 plate_t / 2 + pack_tray_lip_h / 2 - eps])
        cube([pack_len + 2 * pack_clearance, pack_tray_lip_t, pack_tray_lip_h + 2 * eps], center = true);
    }

    // Four small end stops prevent sliding without blocking cable exits.
    for (x = [-1, 1], y = [-1, 1]) {
      translate([pack_offset_x + x * (pack_len / 2 + pack_clearance + pack_tray_lip_t / 2),
                 pack_offset_y + y * (pack_w / 2 - 5),
                 plate_t / 2 + pack_tray_lip_h / 2 - eps])
        cube([pack_tray_lip_t, 10, pack_tray_lip_h + 2 * eps], center = true);
    }
  }
}

module magnetic_locator_ribs() {
  for (y = [-locator_rib_y_spacing / 2, locator_rib_y_spacing / 2]) {
    translate([0, y, -plate_t / 2 - locator_rib_h / 2 + 0.25])
      cube([locator_rib_len, locator_rib_w, locator_rib_h + 0.5], center = true);
  }
}

module cm5_support_posts() {
  post_h = cm5_layer_h + cm5_board_t + 3.0;

  for (x = [-cm5_post_x_spacing / 2, cm5_post_x_spacing / 2],
       y = [-cm5_post_y_spacing / 2, cm5_post_y_spacing / 2]) {
    translate([x + cm5_offset_x,
               y + cm5_offset_y,
               plate_t / 2 + post_h / 2 - eps])
      difference() {
        cylinder(h = post_h + 2 * eps, r = cm5_post_od / 2, center = true);
        cylinder(h = post_h + 0.8 + 2 * eps, r = cm5_post_screw_d / 2, center = true);
      }
  }
}

module cm5_tray() {
  tray_z = plate_t / 2 + cm5_layer_h;
  outer_len = cm5_len + 2 * (cm5_tray_clearance + cm5_tray_lip_t);
  outer_w = cm5_w + 2 * (cm5_tray_clearance + cm5_tray_lip_t);
  pad_len = 9;
  pad_w = 8;
  corner_l = 6;

  union() {
    // Open corner pads let the carrier drop in from above; no continuous tray
    // wall blocks assembly or connector access.
    for (x = [-1, 1], y = [-1, 1]) {
      translate([cm5_offset_x + x * (outer_len / 2 - pad_len / 2),
                 cm5_offset_y + y * (outer_w / 2 - pad_w / 2),
                 tray_z - 0.55])
        rounded_box([pad_len, pad_w, 1.1], 1.5);

      // L-shaped corner locator: one short segment on each side of the corner.
      translate([cm5_offset_x + x * (cm5_len / 2 + cm5_tray_clearance + cm5_tray_lip_t / 2),
                 cm5_offset_y + y * (cm5_w / 2 + cm5_tray_clearance - corner_l / 2),
                 tray_z + cm5_tray_lip_h / 2 - eps])
        cube([cm5_tray_lip_t, corner_l, cm5_tray_lip_h + 2 * eps], center = true);

      translate([cm5_offset_x + x * (cm5_len / 2 + cm5_tray_clearance - corner_l / 2),
                 cm5_offset_y + y * (cm5_w / 2 + cm5_tray_clearance + cm5_tray_lip_t / 2),
                 tray_z + cm5_tray_lip_h / 2 - eps])
        cube([corner_l, cm5_tray_lip_t, cm5_tray_lip_h + 2 * eps], center = true);
    }

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

    // Camera ribbon exit at the lower edge of the holder. Cut through the
    // back plate and bottom lip so the FFC can actually pass out of the holder.
    translate([0, -cam_pocket_depth / 2, cam_wall + 4])
      cube([17, cam_pocket_depth + 2 * cam_wall + 1.0, 8], center = true);
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

module cm5_nano_b_power_module_mount() {
  difference() {
    union() {
      base_plate();
      magnetic_locator_ribs();
      battery_pack_tray();
      cm5_support_posts();
      cm5_tray();
      front_mast();
    }

    // Full-height ribbon pass-through. The base plate already has this cut,
    // but the front mast root can visually close it, so cut the assembled
    // module as well.
    translate([ribbon_slot_x, 0, -2 + ribbon_channel_h / 2])
      cube([ribbon_slot_l, ribbon_slot_w, ribbon_channel_h + 2 * eps], center = true);

    // Strap slots for a thin hook-and-loop strap or zip tie around the
    // shrink-wrapped battery pack.
    for (x = [-strap_slot_x_spacing / 2, strap_slot_x_spacing / 2]) {
      translate([pack_offset_x + x, strap_slot_y, plate_t / 2])
        slot(strap_slot_len, strap_slot_w, plate_t + pack_floor_t + 0.8);
    }
  }
}

cm5_nano_b_power_module_mount();
