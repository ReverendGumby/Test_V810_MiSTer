// True dual-port RAM, testbench version
// 
// Copyright (c) 2025 David Hunter
//
// This program is GPL licensed. See COPYING for the full license.

module dpram
  #(parameter int    addr_width = 8,
	parameter int    data_width = 8,
	parameter string mem_init_file = " ",
	parameter reg    disable_value = 1'b1
	)
   (
    input                       clock,
    input [addr_width-1:0]      address_a,
    input [data_width-1:0]      data_a = '0,
    input                       enable_a = '1,
    input                       wren_a = '0,
    output reg [data_width-1:0] q_a,
    input                       cs_a = '1,

    input [addr_width-1:0]      address_b = '0,
    input [data_width-1:0]      data_b = '0,
    input                       enable_b = '1,
    input                       wren_b = '0,
    output reg [data_width-1:0] q_b,
    input                       cs_b = '1
    );

reg [data_width-1:0] mem [0:(1<<addr_width)-1];
reg [data_width-1:0] q0, q1;

always @(posedge clock) if (enable_a) begin
    q0 <= mem[address_a];

    if (cs_a & wren_a) begin
        mem[address_a] <= data_a;
    end
end

always @(posedge clock) if (enable_b) begin
    q1 <= mem[address_b];

    if (cs_b & wren_b) begin
        mem[address_b] <= data_b;
    end
end

always @* begin
    q_a = cs_a ? q0 : {data_width{disable_value}};
    q_b = cs_b ? q1 : {data_width{disable_value}};
end

endmodule
