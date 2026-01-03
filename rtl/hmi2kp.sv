// Convert HMI inputs to K-Port-connected device
//
// Copyright (c) 2026 David Hunter
//
// This program is GPL licensed. See COPYING for the full license.

import core_pkg::hmi_t;
import core_pkg::joypad_t;

module hmi2kp
   (
    input        RESn,
    input        CLK,

    input        hmi_t HMI,

    input [1:0]  KP_LATCH,
    input [1:0]  KP_CLK,
    input [1:0]  KP_RW,
    output [1:0] KP_DIN,
    input [1:0]  KP_DOUT
    );

logic [31:0]    kp_data [2];
logic [31:0]    sr [2];
logic [1:0]     kp_latch_d, kp_clk_d;

// Parallel data is active-high here, matching internal data port
// representation. It is converted to active-low during serialization.

task joypad_to_kp_data(input joypad_t jp, output [31:0] data);
    data[5:0] = jp.b[6:1];
    data[6] = jp.select;
    data[7] = jp.run;
    data[8] = jp.u;
    data[9] = jp.r;
    data[10] = jp.d;
    data[11] = jp.l;
    data[12] = jp.mode1;
    data[13] = '0;
    data[14] = jp.mode2;
    data[15] = '0;
    data[27:16] = '0;
    data[31:28] = 4'b1111;
endtask

always @(HMI) begin
    joypad_to_kp_data(HMI.jp1, kp_data[0]);
    joypad_to_kp_data(HMI.jp2, kp_data[1]);
end

always @(posedge CLK) begin
    kp_latch_d <= KP_LATCH;
    kp_clk_d <= KP_CLK;
end

wire [1:0] kp_latch_posedge = ~kp_latch_d & KP_LATCH;
wire [1:0] kp_clk_posedge = ~kp_clk_d & KP_CLK;

generate
    genvar i;
    for (i = 0; i < 2; i++) begin :ports
        always @(posedge CLK) begin
            if (~RESn) begin
                sr[i] <= '0;
            end
            else begin
                if (kp_latch_posedge[i])
                    sr[i] <= kp_data[i];
                else if (kp_clk_posedge[i])
                    sr[i] <= {1'b0, sr[i][31:1]};
            end
        end

        assign KP_DIN[i] = ~sr[i][0];
    end
endgenerate

endmodule
