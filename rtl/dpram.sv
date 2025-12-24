// True dual-port RAM
// 
// Translated from TurboGrafx16_MiSTer/rtl/dpram.vhd
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

reg [data_width-1:0] q0, q1;

always @* begin
    q_a = cs_a ? q0 : {data_width{disable_value}};
    q_b = cs_b ? q1 : {data_width{disable_value}};
end

altsyncram
   #(
    .address_reg_b("CLOCK1"),
    .clock_enable_input_a("NORMAL"),
    .clock_enable_input_b("NORMAL"),
    .clock_enable_output_a("BYPASS"),
    .clock_enable_output_b("BYPASS"),
    .indata_reg_b("CLOCK1"),
    .intended_device_family("Cyclone V"),
    .lpm_type("altsyncram"),
    .numwords_a((1 << addr_width)),
    .numwords_b((1 << addr_width)),
    .operation_mode("BIDIR_DUAL_PORT"),
    .outdata_aclr_a("NONE"),
    .outdata_aclr_b("NONE"),
    .outdata_reg_a("UNREGISTERED"),
    .outdata_reg_b("UNREGISTERED"),
    .power_up_uninitialized("FALSE"),
    .read_during_write_mode_port_a("NEW_DATA_NO_NBE_READ"),
    .read_during_write_mode_port_b("NEW_DATA_NO_NBE_READ"),
    .init_file(mem_init_file), 
    .widthad_a(addr_width),
    .widthad_b(addr_width),
    .width_a(data_width),
    .width_b(data_width),
    .width_byteena_a(1),
    .width_byteena_b(1),
    .wrcontrol_wraddress_reg_b("CLOCK1")
    )
   altsyncram_component
   (
	.address_a(address_a),
	.address_b(address_b),
	.clock0(clock),
	.clock1(clock),
	.clocken0(enable_a),
	.clocken1(enable_b),
	.data_a(data_a),
	.data_b(data_b),
	.wren_a(wren_a & cs_a),
	.wren_b(wren_b & cs_b),
	.q_a(q0),
	.q_b(q1)
	);

endmodule
