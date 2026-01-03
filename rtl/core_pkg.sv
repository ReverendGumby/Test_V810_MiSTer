// Core - common definitions
//
// Copyright (c) 2026 David Hunter
//
// This program is GPL licensed. See COPYING for the full license.

package core_pkg;

// Joypad controller inputs
typedef struct packed {
    bit l, r, u, d;             // directions
    bit [6:1] b;                // numbered buttons
    bit select, run;            // named buttons
    bit mode1, mode2;           // switches: A=0, B=1
} joypad_t;

// Human-Machine Interface inputs
typedef struct packed {
    // Joypad controllers
    joypad_t jp1, jp2;
} hmi_t;

endpackage
