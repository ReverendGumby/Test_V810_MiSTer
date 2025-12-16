// Computer assembly
//
// Copyright (c) 2025 David Hunter
//
// This program is GPL licensed. See COPYING for the full license.

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

   output [31:0] A
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

logic           huc6270_0_csn;
logic           huc6270_0_int;
logic [15:0]    huc6270_0_do;

logic           huc6270_1_csn;
logic           huc6270_1_int;
logic [15:0]    huc6270_1_do;

logic           ga_wrn, ga_rdn;
logic           ga_csn;
logic [15:0]    ga_do;

logic           pce;
logic [8:0]     huc6261_row, huc6261_col;

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
assign io_int[1] = huc6270_1_int;
assign io_int[2] = '0; //huc6272_int;
assign io_int[3] = huc6270_0_int;

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
     .HUC6270_0_CSn(huc6270_0_csn),
     .HUC6270_1_CSn(huc6270_1_csn),

     .ROM_READYn(rom_readyn),
     .RAM_READYn(ram_readyn),

     .WRn(ga_wrn),
     .RDn(ga_rdn),

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
     .ROW(huc6261_row),
     .COL(huc6261_col)
     );

huc6270 huc6270_0
    (
     .RESn(RESn),
     .CLK(CLK),
     .CE(CE),

     .CSn(huc6270_0_csn),
     .WRn(ga_wrn),
     .RDn(ga_rdn),
     .A2(cpu_a[2]),
     .DI(cpu_d_o[15:0]),
     .DO(huc6270_0_do),

     .INT(huc6270_0_int),

     .PCE(pce),
     .ROW(huc6261_row),
     .COL(huc6261_col)
     );

huc6270 huc6270_1
    (
     .RESn(RESn),
     .CLK(CLK),
     .CE(CE),

     .CSn(huc6270_1_csn),
     .WRn(ga_wrn),
     .RDn(ga_rdn),
     .A2(cpu_a[2]),
     .DI(cpu_d_o[15:0]),
     .DO(huc6270_1_do),

     .INT(huc6270_1_int),

     .PCE(pce),
     .ROW(huc6261_row),
     .COL(huc6261_col)
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
    else if (~huc6270_0_csn)
        io_do = huc6270_0_do;
    else if (~huc6270_1_csn)
        io_do = huc6270_1_do;
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

always @(posedge CLK) if (1 && CE) begin
    if (~io_cen & ~cpu_dan)
        $display("%x %s %x", A, (cpu_rw ? "R" : "w"),
                 (cpu_rw ? cpu_d_i[15:0] : cpu_d_o[15:0]));
end

always @cpu_int
    $display("!! cpu_int=%x", cpu_int);

endmodule
