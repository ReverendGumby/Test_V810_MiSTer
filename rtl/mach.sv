// Computer assembly
//
// Copyright (c) 2025 David Hunter
//
// This program is GPL licensed. See COPYING for the full license.

/* verilator lint_off PINMISSING */

module mach
  (
   input         CLK,
   input         CE,
   input         RESn,

   output        CPU_BCYSTn,

   output [19:0] ROM_A,
   input [15:0]  ROM_DO,
   output        ROM_CEn,
   input         ROM_READYn,

   output [20:0] RAM_A,
   output [31:0] RAM_DI,
   input [31:0]  RAM_DO,
   output        RAM_CEn,
   output        RAM_WEn,
   output [3:0]  RAM_BEn,
   input         RAM_READYn,

   output [31:0] A,
   output [8:0]  VDC0_VD,
   output [8:0]  VDC1_VD
   );

wire [31:0]     cpu_a;
logic [31:0]    cpu_d_i;
wire [31:0]     cpu_d_o;
wire [3:0]      cpu_ben;
wire [1:0]      cpu_st;
wire            cpu_dan;
wire            cpu_mrqn;
wire            cpu_rw;
wire            cpu_bcystn;
wire            cpu_readyn;
wire            cpu_szrqn;
logic           cpu_int;
logic [3:0]     cpu_intvn;
logic           cpu_nmin;

logic           rom_cen;
logic [15:0]    rom_do;
logic           rom_readyn;

logic           ram_cen;
wire [31:0]     ram_do;
logic           ram_readyn;

logic           io_cen;
logic [15:0]    io_do;
wire [3:0]      io_int;

logic           unk_cen;

logic           huc6261_csn;
logic [15:0]    huc6261_do;

logic           vdc0_csn;
logic           vdc0_busyn;
logic           vdc0_irqn;
logic [15:0]    vdc0_do;
logic [8:0]     vdc0_vd;

wire [15:0]     vram0_a;
wire [15:0]     vram0_di, vram0_do;
wire            vram0_we;

logic           vdc1_csn;
logic           vdc1_busyn;
logic           vdc1_irqn;
logic [15:0]    vdc1_do;
logic [8:0]     vdc1_vd;

wire [15:0]     vram1_a;
wire [15:0]     vram1_di, vram1_do;
wire            vram1_we;

logic           ga_wrn, ga_rdn;
logic           ga_csn;
logic [15:0]    ga_do;

logic           pce, pce_negedge;
logic           hs_posedge, hs_negedge;
logic           vs_posedge, vs_negedge;

v810 cpu
    (
     .RESn(RESn),
     .CLK(CLK),
     .CE(CE),

     .A(cpu_a),
     .D_I(cpu_d_i),
     .D_O(cpu_d_o),
     .BEn(cpu_ben),
     .ST(cpu_st),
     .DAn(cpu_dan),
     .MRQn(cpu_mrqn),
     .RW(cpu_rw),
     .BCYSTn(cpu_bcystn),
     .READYn(cpu_readyn),
     .SZRQn(cpu_szrqn),

     .INT(cpu_int),
     .INTVn(cpu_intvn),
     .NMIn(cpu_nmin)
     );

assign io_int[0] = '0; //huc6273_int;
assign io_int[1] = ~vdc1_irqn;
assign io_int[2] = '0; //huc6272_int;
assign io_int[3] = ~vdc0_irqn;

fx_ga ga
    (
     .RESn(RESn),
     .CLK(CLK),
     .CE(CE),

     .A(cpu_a),
     .DI(cpu_d_o[15:0]),
     .DO(ga_do),
     .ST(cpu_st),
     .DAn(cpu_dan),
     .MRQn(cpu_mrqn),
     .RW(cpu_rw),
     .BCYSTn(cpu_bcystn),
     .READYn(cpu_readyn),
     .SZRQn(cpu_szrqn),

     .ROM_CEn(rom_cen),
     .RAM_CEn(ram_cen),
     .IO_CEn(io_cen),

     .FX_GA_CSn(ga_csn),
     .HUC6261_CSn(huc6261_csn),
     .VDC0_CSn(vdc0_csn),
     .VDC1_CSn(vdc1_csn),

     .ROM_READYn(rom_readyn),
     .RAM_READYn(ram_readyn),

     .WRn(ga_wrn),
     .RDn(ga_rdn),
     .VDC0_BUSYn(vdc0_busyn),
     .VDC1_BUSYn(vdc1_busyn),

     .DINT(io_int),

     .CINT(cpu_int),
     .CINTVn(cpu_intvn),
     .CNMIn(cpu_nmin)
     );

huc6261 huc6261
    (
     .RESn(RESn),
     .CLK(CLK),
     .CE(CE),            // TODO: Divide .CE by 5 for 5MHz pixel clock

     .CSn(huc6261_csn),
     .WRn(ga_wrn),
     .RDn(ga_rdn),
     .A2(cpu_a[2]),
     .DI(cpu_d_o[15:0]),
     .DO(huc6261_do),

     .PCE(pce),
     .PCE_NEGEDGE(pce_negedge),
     .HSYNC_POSEDGE(hs_posedge),
     .HSYNC_NEGEDGE(hs_negedge),
     .VSYNC_POSEDGE(vs_posedge),
     .VSYNC_NEGEDGE(vs_negedge)
     );

huc6270 vdc0
    (
     .CLK(CLK),
     .RST_N(RESn),
     .CLR_MEM('0),
     .CPU_CE(CE),

     .BYTEWORD('0),
     .A({cpu_a[2], 1'b0}),
     .DI(cpu_d_o[15:0]),
     .DO(vdc0_do),
     .CS_N(vdc0_csn),
     .WR_N(ga_wrn),
     .RD_N(ga_rdn),
     .BUSY_N(vdc0_busyn),
     .IRQ_N(vdc0_irqn),

     .DCK_CE(pce),
     .DCK_CE_F(pce_negedge),
     .HSYNC_F(hs_negedge),
     .HSYNC_R(hs_posedge),
     .VSYNC_F(vs_negedge),
     .VSYNC_R(vs_posedge),
     .VD(vdc0_vd),
     .BORDER(),
     .GRID(),
     .SP64('0),

     .RAM_A(vram0_a),
     .RAM_DI(vram0_di),
     .RAM_DO(vram0_do),
     .RAM_WE(vram0_we),

     .BG_EN('1),
     .SPR_EN('1)
     );

dpram #(.addr_width(15), .data_width(16), .disable_value(0)) vram0
    (
     .clock(CLK),
     .address_a(vram0_a[14:0]),
     .data_a(vram0_do),
     .cs_a(~vram0_a[15]),
     .wren_a(vram0_we),
     .q_a(vram0_di)
     );

huc6270 vdc1
    (
     .CLK(CLK),
     .RST_N(RESn),
     .CLR_MEM('0),
     .CPU_CE(CE),

     .BYTEWORD('0),
     .A({cpu_a[2], 1'b0}),
     .DI(cpu_d_o[15:0]),
     .DO(vdc1_do),
     .CS_N(vdc1_csn),
     .WR_N(ga_wrn),
     .RD_N(ga_rdn),
     .BUSY_N(vdc1_busyn),
     .IRQ_N(vdc1_irqn),

     .DCK_CE(pce),
     .DCK_CE_F(pce_negedge),
     .HSYNC_F(hs_negedge),
     .HSYNC_R(hs_posedge),
     .VSYNC_F(vs_negedge),
     .VSYNC_R(vs_posedge),
     .VD(vdc1_vd),
     .BORDER(),
     .GRID(),
     .SP64('0),

     .RAM_A(vram1_a),
     .RAM_DI(vram1_di),
     .RAM_DO(vram1_do),
     .RAM_WE(vram1_we),

     .BG_EN('1),
     .SPR_EN('1)
     );

dpram #(.addr_width(15), .data_width(16), .disable_value(0)) vram1
    (
     .clock(CLK),
     .address_a(vram1_a[14:0]),
     .data_a(vram1_do),
     .cs_a(~vram1_a[15]),
     .wren_a(vram1_we),
     .q_a(vram1_di)
     );

always @* begin
    if (~rom_cen)
        cpu_d_i = {16'b0, rom_do};
    else if (~ram_cen)
        cpu_d_i = ram_do;
    else if (~io_cen)
        cpu_d_i = {16'b0, io_do};
    else
        cpu_d_i = '0;
end

always @* begin
    if (~huc6261_csn)
        io_do = huc6261_do;
    else if (~vdc0_csn)
        io_do = vdc0_do;
    else if (~vdc1_csn)
        io_do = vdc1_do;
    else if (~ga_csn)
        io_do = ga_do;
    else
        io_do = '0;
end

assign rom_do = ROM_DO;
assign rom_readyn = rom_cen | ROM_READYn;

assign ram_do = RAM_DO;
assign ram_readyn = ram_cen | RAM_READYn;

assign CPU_BCYSTn = cpu_bcystn;

assign ROM_CEn = rom_cen;
assign ROM_A = cpu_a[19:0];

assign RAM_CEn = ram_cen;
assign RAM_A = cpu_a[20:0];
assign RAM_DI = cpu_d_o;
assign RAM_WEn = cpu_rw;
assign RAM_BEn = cpu_ben;

assign A = cpu_a;
assign VDC0_VD = vdc0_vd;
assign VDC1_VD = vdc1_vd;

always @(posedge CLK) if (1 && CE) begin
    if (~io_cen & ~cpu_dan)
        $display("%x %s %x", A, (cpu_rw ? "R" : "w"),
                 (cpu_rw ? cpu_d_i[15:0] : cpu_d_o[15:0]));
end

always @cpu_int
    $display("!! cpu_int=%x", cpu_int);

endmodule
