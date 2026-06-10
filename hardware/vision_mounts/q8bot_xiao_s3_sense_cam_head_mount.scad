/*
  Q8bot XIAO ESP32S3 Sense front-face camera bracket

  This lightweight bracket is a front-face camera plate for the XIAO ESP32S3
  Sense module, with a slight downward camera tilt.

  The robot-facing side is flat for double-sided tape. The whole printed plate
  is wedge-shaped, with one side thin and the other side thick, so the Sense
  module clips onto a tilted front face.

  Orientation: X is robot length, +X is forward, Y is width, Z is up.
  Print orientation: back plate flat on bed.
*/

$fn = 48;
eps = 0.12;

// -------------------- User parameters --------------------
bracket_w = 28;
bracket_h = 32;
bracket_t_min = 2.0;
bracket_t_max = 6.0;
corner_r = 2.4;

// XIAO ESP32S3 Sense published assembled size is about 21 x 17.8 x 15 mm. The
// printed bracket supports the back side only; the camera/front side faces out.
sense_len = 21.0;
sense_w = 17.8;
sense_outline_clearance = 0.8;

// Optional low side lips only help locate the module while tape cures; they do
// not cover the camera side.
locating_lip_t = 1.2;
locating_lip_h = 2.0;
locating_lip_len = 18.0;

// Cable relief for the Sense board and antenna pigtails.
cable_slot_w = 10;
cable_slot_h = 5;
cable_slot_z = -8;

module front_face_bracket() {
  difference() {
    union() {
      wedge_plate();
    }

    // Cable pass-through below the Sense footprint.
    translate([0, 0, cable_slot_z])
      cube([bracket_t_max + 2.0, cable_slot_w, cable_slot_h], center = true);
  }
}

function front_x_at_z(z) =
  bracket_t_min + (z + bracket_h / 2) / bracket_h * (bracket_t_max - bracket_t_min);

module wedge_plate() {
  // Back face is flat at X=0. Front face gets thicker toward +Z, tilting the
  // Sense module downward when installed on a vertical robot face.
  polyhedron(
    points=[
      [0, -bracket_w / 2, -bracket_h / 2],
      [0,  bracket_w / 2, -bracket_h / 2],
      [0,  bracket_w / 2,  bracket_h / 2],
      [0, -bracket_w / 2,  bracket_h / 2],
      [front_x_at_z(-bracket_h / 2), -bracket_w / 2, -bracket_h / 2],
      [front_x_at_z(-bracket_h / 2),  bracket_w / 2, -bracket_h / 2],
      [front_x_at_z( bracket_h / 2),  bracket_w / 2,  bracket_h / 2],
      [front_x_at_z( bracket_h / 2), -bracket_w / 2,  bracket_h / 2]
    ],
    faces=[
      [0, 1, 2, 3],
      [4, 7, 6, 5],
      [0, 4, 5, 1],
      [1, 5, 6, 2],
      [2, 6, 7, 3],
      [3, 7, 4, 0]
    ]
  );
}

front_face_bracket();
