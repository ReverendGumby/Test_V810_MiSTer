// V810 Test Core
//
// Copyright (c) 2025-2026 David Hunter
//
// This program is GPL licensed. See COPYING for the full license.

`define GEN_VID_TIMING 1

import core_pkg::hmi_t;

module mycore
    #(parameter CLK_RAM_MHZ = 100.0)
(
	input         clk_sys,
    input         clk_ram,
	input         reset,
    input         pll_locked,
	
	input         pal,
	input         scandouble,

    input         ioctl_download,
    input [7:0]   ioctl_index,
    input         ioctl_wr,
    input [24:0]  ioctl_addr,
    input [15:0]  ioctl_dout,
    output reg    ioctl_wait = '0,

    input         hmi_t HMI,

	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output [1:0]  SDRAM_BA,
	inout [15:0]  SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

    output reg    ce_pix,

	output reg    HBlank,
	output reg    HSync,
	output reg    VBlank,
	output reg    VSync,

	output [7:0]  R,
	output [7:0]  G,
	output [7:0]  B
);

reg [26:0]      romwr_a;
reg [31:0]      romwr_d;
reg             romwr_req = 0;
wire            romwr_ack;

//////////////////////////////////////////////////////////////////////
// SDRAM controller

wire [26:0] sdram_ch1_addr;
wire [31:0] sdram_ch1_din, sdram_ch1_dout;
wire [3:0]  sdram_ch1_be;
wire        sdram_ch1_rnw, sdram_ch1_req, sdram_ch1_ready;
wire [26:0] sdram_ch2_addr;
wire [31:0] sdram_ch2_din, sdram_ch2_dout;
wire        sdram_ch2_rnw, sdram_ch2_req, sdram_ch2_ready;
wire [26:0] sdram_ch3_addr;
wire [31:0] sdram_ch3_din, sdram_ch3_dout;
wire        sdram_ch3_rnw, sdram_ch3_req, sdram_ch3_ready;

sdram #(.CLK_MHZ(CLK_RAM_MHZ)) sdram
(
	.*,

    .init(~pll_locked),
    .clk(clk_ram),

    .ch1_addr(sdram_ch1_addr),
    .ch1_dout(sdram_ch1_dout),
    .ch1_din(sdram_ch1_din),
    .ch1_req(sdram_ch1_req),
    .ch1_rnw(sdram_ch1_rnw),
    .ch1_be(sdram_ch1_be),
    .ch1_ready(sdram_ch1_ready),
    .ch2_addr(sdram_ch2_addr),
    .ch2_dout(sdram_ch2_dout),
    .ch2_din(sdram_ch2_din),
    .ch2_req(sdram_ch2_req),
    .ch2_rnw(sdram_ch2_rnw),
    .ch2_ready(sdram_ch2_ready),
    .ch3_addr(sdram_ch3_addr),
    .ch3_dout(sdram_ch3_dout),
    .ch3_din(sdram_ch3_din),
    .ch3_req(sdram_ch3_req),
    .ch3_rnw(sdram_ch3_rnw),
    .ch3_ready(sdram_ch3_ready)
);

//////////////////////////////////////////////////////////////////////
// Computer assembly

reg         cpu_ce;
reg         reset_cpu;
reg         cpu_resn;
wire        cpu_bcystn;
reg [31:0]  a;
wire        vid_pce;
wire [7:0]  vid_y;
wire [7:0]  vid_u;
wire [7:0]  vid_v;
wire        vid_vsn;
wire        vid_hsn;
wire        vid_vbl;
wire        vid_hbl;

wire [19:0] rom_a;
wire [15:0] rom_do;
wire        rom_cen;
wire        rom_readyn;

wire [20:0] ram_a;
wire [31:0] ram_di, ram_do;
wire        ram_cen;
wire        ram_wen;
wire [3:0]  ram_ben;
wire        ram_readyn;

wire [17:0] krama_a;
wire [15:0] krama_di, krama_do;
wire [1:0]  krama_be;
wire        krama_wr, krama_req, krama_ack;
wire [17:0] kramb_a;
wire [15:0] kramb_di, kramb_do;
wire [1:0]  kramb_be;
wire        kramb_wr, kramb_req, kramb_ack;

wire [26:0] ls_addr;
wire [31:0] ls_din, ls_dout;
wire        ls_we_req, ls_we_ack;
wire        ls_rd_req, ls_rd_ack;

wire clk_cpu = clk_sys;

initial cpu_ce = 0;

always @(posedge clk_cpu) begin
  cpu_ce <= ~cpu_ce;
  reset_cpu <= reset /*| &fc*/;
end

always @(posedge clk_cpu) if (cpu_ce) begin
  cpu_resn <= ~reset_cpu;
end

mach mach
  (
   .CLK(clk_cpu),
   .CE(cpu_ce),
   .RESn(cpu_resn),

   .CPU_BCYSTn(cpu_bcystn),

   .ROM_A(rom_a),
   .ROM_DO(rom_do),
   .ROM_CEn(rom_cen),
   .ROM_READYn(rom_readyn),

   .RAM_A(ram_a),
   .RAM_DI(ram_di),
   .RAM_DO(ram_do),
   .RAM_CEn(ram_cen),
   .RAM_WEn(ram_wen),
   .RAM_BEn(ram_ben),
   .RAM_READYn(ram_readyn),

   .HMI(HMI),

   .A(a),

   .VID_PCE(vid_pce),
   .VID_Y(vid_y),
   .VID_U(vid_u),
   .VID_V(vid_v),
   .VID_VSn(vid_vsn),
   .VID_HSn(vid_hsn),
   .VID_VBL(vid_vbl),
   .VID_HBL(vid_hbl)
   );

memif_sdram memif_sdram
  (
   .CPU_CLK(clk_cpu),
   .CPU_CE(cpu_ce),
   .CPU_RESn(cpu_resn),
   .CPU_BCYSTn(cpu_bcystn),

   .ROM_A(rom_a),
   .ROM_DO(rom_do),
   .ROM_CEn(rom_cen),
   .ROM_READYn(rom_readyn),

   .RAM_A(ram_a),
   .RAM_DI(ram_di),
   .RAM_DO(ram_do),
   .RAM_CEn(ram_cen),
   .RAM_WEn(ram_wen),
   .RAM_BEn(ram_ben),
   .RAM_READYn(ram_readyn),

   .SRAM_A('0),
   .SRAM_DI('0),
   .SRAM_DO(),
   .SRAM_CEn('1),
   .SRAM_WEn('1),
   .SRAM_READYn(),

   .BMP_A('0),
   .BMP_DI('0),
   .BMP_DO(),
   .BMP_CEn('1),
   .BMP_WEn('1),
   .BMP_READYn(),

   .KRAMA_A(krama_a),
   .KRAMA_DI(krama_di),
   .KRAMA_DO(krama_do),
   .KRAMA_BE(krama_be),
   .KRAMA_WR(krama_wr),
   .KRAMA_REQ(krama_req),
   .KRAMA_ACK(krama_ack),

   .KRAMB_A(kramb_a),
   .KRAMB_DI(kramb_di),
   .KRAMB_DO(kramb_do),
   .KRAMB_BE(kramb_be),
   .KRAMB_WR(kramb_wr),
   .KRAMB_REQ(kramb_req),
   .KRAMB_ACK(kramb_ack),

   .LS_ADDR(ls_addr),
   .LS_DIN(ls_din),
   .LS_WE_REQ(ls_we_req),
   .LS_WE_ACK(ls_we_ack),
   .LS_DOUT(ls_dout),
   .LS_RD_REQ(ls_rd_req),
   .LS_RD_ACK(ls_rd_ack),

   .SDRAM_CLK(clk_ram),
   .SDRAM_CH1_ADDR(sdram_ch1_addr),
   .SDRAM_CH1_DOUT(sdram_ch1_dout),
   .SDRAM_CH1_DIN(sdram_ch1_din),
   .SDRAM_CH1_REQ(sdram_ch1_req),
   .SDRAM_CH1_RNW(sdram_ch1_rnw),
   .SDRAM_CH1_BE(sdram_ch1_be),
   .SDRAM_CH1_READY(sdram_ch1_ready),
   .SDRAM_CH2_ADDR(sdram_ch2_addr),
   .SDRAM_CH2_DOUT(sdram_ch2_dout),
   .SDRAM_CH2_DIN(sdram_ch2_din),
   .SDRAM_CH2_REQ(sdram_ch2_req),
   .SDRAM_CH2_RNW(sdram_ch2_rnw),
   .SDRAM_CH2_READY(sdram_ch2_ready),
   .SDRAM_CH3_ADDR(sdram_ch3_addr),
   .SDRAM_CH3_DOUT(sdram_ch3_dout),
   .SDRAM_CH3_DIN(sdram_ch3_din),
   .SDRAM_CH3_REQ(sdram_ch3_req),
   .SDRAM_CH3_RNW(sdram_ch3_rnw),
   .SDRAM_CH3_READY(sdram_ch3_ready)
   );

assign ls_addr = romwr_a;
assign ls_din = romwr_d;
assign ls_we_req = romwr_req;
assign ls_rd_req = '0;
assign romwr_ack = ls_we_ack;

kram_source kas
   (
    .CLK(clk_cpu),
    .A(krama_a),
    .DI(krama_di),
    .DO(krama_do),
    .BE(krama_be),
    .WR(krama_wr),
    .REQ(krama_req),
    .ACK(krama_ack)
    );

kram_source kbs
   (
    .CLK(clk_cpu),
    .A(kramb_a),
    .DI(kramb_di),
    .DO(kramb_do),
    .BE(kramb_be),
    .WR(kramb_wr),
    .REQ(kramb_req),
    .ACK(kramb_ack)
    );

//////////////////////////////////////////////////////////////////////
// ROM loader

`include "memif_sdram_part.svh"

reg         romwr_active = 0;
reg         romwr_a1;

always @(posedge clk_sys) begin
	reg old_download;

	old_download <= ioctl_download;

    if (~ioctl_download) begin
        romwr_active <= 0;
    end
	if(~old_download && ioctl_download) begin
        romwr_active <= 1;
        romwr_a1 <= 0;
        case (ioctl_index[5:0])
            6'd0, 6'd1: romwr_a <= ROM_BASE_A;
            default: romwr_active <= 0;
        endcase
	end
	else begin
		if(ioctl_wr & romwr_active) begin
            if (romwr_a1) begin
			    ioctl_wait <= 1;
			    romwr_req <= ~romwr_req;
            end
            romwr_d <= {ioctl_dout, romwr_d[31:16]};
            romwr_a1 <= ~romwr_a1;
		end else if(ioctl_wait && (romwr_req == romwr_ack)) begin
			ioctl_wait <= 0;
			romwr_a <= romwr_a + 27'd4;
		end
	end
end

//////////////////////////////////////////////////////////////////////
// Video output

`ifdef GEN_VID_TIMING

reg   [9:0] hc;
reg   [9:0] vc;
reg   [7:0] fc;
reg [23:0]  pix;

always @(posedge clk_sys) begin
	if(scandouble) ce_pix <= 1;
		else ce_pix <= ~ce_pix;

	if(reset) begin
		hc <= 0;
		vc <= 0;
        fc <= 0;
	end
	else if(ce_pix) begin
		if(hc == 637) begin
			hc <= 0;
			if(vc == (pal ? (scandouble ? 623 : 311) : (scandouble ? 523 : 261))) begin 
				vc <= 0;
				fc <= fc + 1'd1;
			end else begin
				vc <= vc + 1'd1;
			end
		end else begin
			hc <= hc + 1'd1;
		end
	end
end

always @(posedge clk_sys) begin
	if (hc == 529) HBlank <= 1;
		else if (hc == 0) HBlank <= 0;

	if (hc == 544) begin
		HSync <= 1;

		if(pal) begin
			if(vc == (scandouble ? 609 : 304)) VSync <= 1;
				else if (vc == (scandouble ? 617 : 308)) VSync <= 0;

			if(vc == (scandouble ? 601 : 300)) VBlank <= 1;
				else if (vc == 0) VBlank <= 0;
		end
		else begin
			if(vc == (scandouble ? 490 : 245)) VSync <= 1;
				else if (vc == (scandouble ? 496 : 248)) VSync <= 0;

			if(vc == (scandouble ? 480 : 240)) VBlank <= 1;
				else if (vc == 0) VBlank <= 0;
		end
	end
	
	if (hc == 590) HSync <= 0;
end

always @(posedge clk_sys) begin
    pix[23:16] <= a[31:24];
    pix[15:8]  <= a[15:8];
    pix[7:0]   <= a[7:0];
end

assign R = pix[23:16];
assign G = pix[15:8];
assign B = pix[7:0];

`else // GEN_VID_TIMING

assign ce_pix = vid_pce;
assign R = vid_u;
assign G = vid_y;
assign B = vid_v;
assign HBlank = vid_hbl;
assign VBlank = vid_vbl;
assign HSync = ~vid_hsn;
assign VSync = ~vid_vsn;

`endif

endmodule

//////////////////////////////////////////////////////////////////////

module kram_source
   (
    input             CLK,
    output reg [18:1] A,
    input [15:0]      DI,
    output reg [15:0] DO,
    output reg [1:0]  BE,
    output reg        WR,
    output reg        REQ,
    input             ACK
    );

initial begin
    A = '0;
    DO = '0;
    BE = '1;
    WR = '1;
    REQ = '0;
end

logic [3:0] ccnt = '0;
wire trg = ccnt == 4'd9;

always @(posedge CLK) begin
    if (trg)
        ccnt <= '0;
    else
        ccnt <= ccnt + 1'd1;
end

logic [8:0] hcnt = 0, vcnt = 0;
always @(posedge CLK) if (trg) begin
    if (hcnt == 272) begin
        hcnt <= 0;
        if (vcnt == 262)
            vcnt <= 0;
        else
            vcnt <= vcnt + 1'd1;
    end
    else
        hcnt <= hcnt + 1'd1;
end

wire de = (hcnt >= 9'd16) & (vcnt >= 9'd30);

always @(posedge CLK) begin
    if (~REQ & trg & de) begin
        REQ <= '1;
        if (WR) begin
            WR <= '0;
        end
        else begin
            WR <= '1;
            DO <= ~DI;
            A <= A + 1'd1;
        end
    end
    else if (REQ & ACK)
        REQ <= '0;
end

endmodule
