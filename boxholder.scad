/* 
Licensed Creative Commons Attribution-ShareAlike 4.0 International

Parametric Box Holder for openGrid: created by maddocker. https://github.com/maddocker
Inspired by https://makerworld.com/en/models/1925937-tp-link-tl-sg108-holder-for-opengrid?from=search#profileId-2099870

Snap for openGrid: created by mitufy. https://github.com/mitufy
Inspired by BlackjackDuck's work here: https://github.com/AndyLevesque/QuackWorks
and Jan's work here: https://github.com/jp-embedded/opengrid

The openGrid system is created by David D. https://www.printables.com/model/1214361-opengrid-walldesk-mounting-framework-and-ecosystem
*/

include <BOSL2/std.scad>
include <BOSL2/rounding.scad>

Device_Length = 105.5; // [20:0.1:280]
Device_Width = 105.5; // [20:0.1:280]
Device_Height = 25.0; // [10:0.1:100]
// Thickness of bracket supporting the device. (Adjust higher if more strength needed)
Wall_Depth = 2.4; //0.1
// Coverage of device sides is equal to this width minus depth. Adjust higher if more strength needed, but make sure any ports or extrusions are not in the way.
Wall_Width = 8; // [4:0.1:14]
// Round/fillet the bottom inside corners of each wall. This adds strength, but can be decreased to zero if you need a true corner for the bottom edges of your device (and consider increasing wall depth in an increment or two of your printer's nozzle diameter).
Inside_Corner_Rounding = 2; //0.1

/* [Fine-Tuning] */
Base_Thickness = 2.6; //0.1
Outside_Corner_Rounding = 2; //0.1
Device_Tolerance = 0.4; //0.1
// Gap around the base platform; gives room between grid tiles.
Base_Clearance = 0.2; //0.1

/* [openGrid Settings] */
Tile_Size = 28;
Snap_Thickness = 6.8; //[6.8:Standard - 6.8mm, 4:Lite - 4mm, 3.4:Lite Basic - 3.4mm]

/* [Snap Body Settings] */
snap_body_width = 24.8;

//Offset connector head/threads position in x and y. This does not affect Self-Expanding Snaps.
snap_center_position_offset = [0, 0]; //0.1

snap_corner_edge_height = 1.5;
snap_body_top_corner_extrude = 1.1;
snap_body_bottom_corner_extrude = 0.6;

/* [Snap Nub Settings] */
basic_nub_width = 10.8;
basic_nub_height_standard = 2; //0.1
basic_nub_height_lite = 1.8;
basic_nub_depth = 0.4;
basic_nub_top_width = 6.8;
basic_nub_top_angle = 35;
basic_nub_bottom_angle = 35;
basic_nub_fillet_radius = 15;

nub_offset_to_top = 1.4; //0.1

/* [Snap Cut Settings] */
back_cut_length = 12.4;
back_cut_thickness = 0.6;
back_cut_offset_to_top = 0.6;
back_cut_offset_to_edge = 0.7;

side_cut_thickness = 0.4; //0.1
side_cut_depth = 0.8; //0.1
side_cut_offset_to_top = 0.8; //0.1

/* [Hidden] */
$fa = 0.1;
$fs = 0.1;
eps = 0.005;

snap_body_corner_outer_diagonal = 2.7 + 1 / sqrt(2);
snap_body_corner_chamfer = snap_body_corner_outer_diagonal * sqrt(2);

//nub paramters
basic_nub_height =
  Snap_Thickness == 6.8 ? basic_nub_height_standard
  : basic_nub_height_lite;

corner_anchors = [FRONT + LEFT, FRONT + RIGHT, BACK + LEFT, BACK + RIGHT];
side_anchors = [FRONT, LEFT, RIGHT, BACK];

module snap_shape(anchor = CENTER, spin = 0, orient = UP) {
  attachable(anchor, spin, orient, size=[snap_body_width, snap_body_width, Snap_Thickness]) {
    cuboid([snap_body_width, snap_body_width, Snap_Thickness], chamfer=snap_body_corner_chamfer, edges="Z");
    children();
  }
}

module snap_corner() {
  down(Snap_Thickness / 2 - snap_corner_edge_height / 2) {
    for (i = corner_anchors) {
      attach(i, BOTTOM, shiftout=-snap_body_corner_outer_diagonal - eps)
        prismoid(size1=[snap_body_corner_chamfer * sqrt(2), snap_corner_edge_height], xang=45, yang=[90, 45], h=snap_body_top_corner_extrude);
    }
  }
}

module snap_cut() {
  back_cut_rounding = back_cut_thickness / 2;
  for (i = side_anchors) {
    up(back_cut_offset_to_top)
      attach(i, FRONT, inside=true, shiftout=-back_cut_offset_to_edge)
        cuboid([back_cut_length, back_cut_thickness, Snap_Thickness], rounding=back_cut_rounding, edges="Z", $fn=64);
    up(side_cut_offset_to_top)
      attach(i, FRONT, align=BOTTOM, inside=true)
        cuboid([back_cut_length, side_cut_depth, side_cut_thickness]);
  }
}
module snap_nub() {
  basic_nub_size1 = [basic_nub_width, basic_nub_height];
  basic_nub_size2 = [basic_nub_top_width, undef];

  basic_nub_yang = [basic_nub_top_angle, basic_nub_bottom_angle];

  for (i = side_anchors) {
    up(nub_offset_to_top) attach(i, BOTTOM, align=BOTTOM, shiftout=-eps)
        diff("nub_fillet") {
          prismoid(size1=basic_nub_size1, size2=basic_nub_size2, yang=basic_nub_yang, h=basic_nub_depth)
            tag("nub_fillet") edge_mask([TOP + LEFT, TOP + RIGHT])
                rounding_edge_mask(l=8, r=basic_nub_fillet_radius, $fn=64);
        }
  }
  //cut off excess nub parts
  down(eps / 2) tag("remove") attach(TOP, TOP) cuboid(30);
}

module snap() {
  up(Snap_Thickness)
  yrot(180)
  difference() {
    {
      diff(remove="remove") {
        snap_shape(anchor=BOTTOM) {
          snap_corner();
          snap_nub();
          snap_cut();
        }
      }
    }
  }
}

module base() {
  hull() {
    up(Snap_Thickness + Base_Thickness) {
      cuboid([Tile_Size - Base_Clearance, Tile_Size - Base_Clearance, Base_Clearance], rounding=Outside_Corner_Rounding, edges="Z", anchor=BOTTOM);
    }
    up(Snap_Thickness) {
      linear_extrude(height = Base_Clearance) {
        projection() {
          snap();
        }
      }
    }
  }
}

module wall() {
  x_pos = (Device_Length / 2) - (Wall_Width / 2) + Device_Tolerance + Wall_Depth;
  y_pos = (Device_Width / 2) - (Wall_Width / 2) + Device_Tolerance + Wall_Depth;
  translate([x_pos, y_pos, Snap_Thickness + Base_Thickness + Base_Clearance]) {
    diff()
    cuboid(
      [Wall_Width, Wall_Width, Device_Height + Device_Tolerance],
      rounding=-Inside_Corner_Rounding,
      edges=[BOTTOM+FRONT, BOTTOM+LEFT, TOP+FRONT, TOP+LEFT],
      anchor=BOTTOM
    )
    edge_profile(BACK+RIGHT)
    mask2d_roundover(Outside_Corner_Rounding);
  }
}

module cap() {
  x_pos = (Device_Length * 3 / 8) + Wall_Depth + Device_Tolerance;
  y_pos = (Device_Width * 3 / 8) + Wall_Depth + Device_Tolerance;
  translate([x_pos, y_pos, Snap_Thickness + Base_Thickness + Base_Clearance + Device_Height + Device_Tolerance]) {
    cuboid(
      [Device_Length / 4, Device_Width / 4, Wall_Depth],
      rounding=Outside_Corner_Rounding,
      edges="Z",
      anchor=BOTTOM
    );
  }
}

module single_bracket() {
  union() {
    wall();
    cap();
  }
}

module xmirror_copy() {
  children();
  mirror([1, 0, 0]) {
    children();
  }
}

module ymirror_copy() {
  children();
  mirror([0, 1, 0]) {
    children();
  }
}

module all_brackets() {
  ymirror_copy() {
    xmirror_copy() {
      single_bracket();
    }
  }
}

module device() {
  up(Snap_Thickness + Base_Thickness + Base_Clearance) {
    cuboid(
      [Device_Length + Device_Tolerance, Device_Width + Device_Tolerance, Device_Height + Device_Tolerance],
      rounding=Inside_Corner_Rounding,
      edges=[BOTTOM, "Z"],
      anchor=BOTTOM
    );
  }
}

module grid(x_length, y_length) {
  // Draw all grid tiles within dimensions, but only corners as solid parts
  // After drawing, shift grid to center on origin
  translate([-(x_length * Tile_Size) / 2, -(y_length * Tile_Size) / 2, 0]) {
    for (x = [0 : x_length - 1]) {
      for (y = [0 : y_length - 1]) {
        translate([(x * Tile_Size) + (Tile_Size / 2), (y * Tile_Size) + (Tile_Size / 2), 0]) {
          if (
            (x == 0 || x == x_length - 1) &&
            (y == 0 || y == y_length - 1)
          ) {
            union() {
              snap();
              base();
            }
          }
          else {
            %union() {
              snap();
              base();
            }
          }
        }
      }
    }
  }
}

// Subtract inner space to make L-shape of bracket, snug to device
difference() {
  union() {
    all_brackets();
    grid(
      ceil((Device_Length + (Wall_Depth * 2) + (Base_Clearance * 2)) / Tile_Size),
      ceil((Device_Width + (Wall_Depth * 2) + (Base_Clearance * 2)) / Tile_Size)
    );
  }
  #device();
}