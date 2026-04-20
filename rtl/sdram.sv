//
// sdram
// Copyright (c) 2015-2019 Sorgelig
// Copyright (c) 2026 David Hunter
//
// Some parts of SDRAM code used from project:
// http://hamsterworks.co.nz/mediawiki/index.php/Simple_SDRAM_Controller
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version. 
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// TODO: Handle CAS_LATENCY == 3

module sdram
    #(parameter CLK_MHZ = 142.8571428)
(
    input             init,        // reset to initialize RAM
    input             clk,         // clock ~100MHz

    inout      [15:0] SDRAM_DQ,    // 16 bit bidirectional data bus
    output reg [12:0] SDRAM_A,     // 13 bit multiplexed address bus
    output            SDRAM_DQML,  // two byte masks
    output            SDRAM_DQMH,  // 
    output reg  [1:0] SDRAM_BA,    // two banks
    output            SDRAM_nCS,   // a single chip select
    output            SDRAM_nWE,   // write enable
    output            SDRAM_nRAS,  // row address select
    output            SDRAM_nCAS,  // columns address select
    output            SDRAM_CKE,   // clock enable
    //output            SDRAM_CLK,   // clock for chip

    input      [26:0] ch1_addr,    // 25 bit address for 8bit mode. addr[0] = 0 for 16bit mode for correct operations.
    output reg [31:0] ch1_dout,    // data output to cpu
    input      [31:0] ch1_din,     // data input from cpu
    input             ch1_req,     // request
    input             ch1_rnw,     // 1 - read, 0 - write
    input      [3:0]  ch1_be,
    output reg        ch1_ready,
    
    input      [26:0] ch2_addr,    // 25 bit address for 8bit mode. addr[0] = 0 for 16bit mode for correct operations.
    output reg [31:0] ch2_dout,    // data output to cpu
    input      [31:0] ch2_din,     // data input from cpu
    input             ch2_req,     // request
    input             ch2_rnw,     // 1 - read, 0 - write
    output reg        ch2_ready,

    input      [26:0] ch3_addr,
    output reg [31:0] ch3_dout,
    input      [31:0] ch3_din,
    input             ch3_req,
    input             ch3_rnw,
    output reg        ch3_ready
);

`include "sdram_defs.svh"

localparam BURST_CODE          = (BURST_LENGTH == 8) ? 3'b011 : (BURST_LENGTH == 4) ? 3'b010 : (BURST_LENGTH == 2) ? 3'b001 : 3'b000;  // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE         = 1'b0;     // 0=sequential, 1=interleaved
localparam CAS_LATENCY         = 3'd2;     // 2 for < 100MHz, 3 for >100MHz
localparam OP_MODE             = 2'b00;    // only 00 (standard operation) allowed
localparam NO_WRITE_BURST      = 1'b1;     // 0= write burst enabled, 1=only single access write
localparam MODE                = {3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_CODE};

localparam sdram_startup_cycles= 14'd12100;// 100us, plus a little more, @ 100MHz
localparam cycles_per_refresh  = 14'(ns_to_cyc(int'(64e6 / 8192))-1);  // 64ms / 8192 refresh cycles
localparam startup_refresh_max = 14'b11111111111111;
localparam startup_mode_cnt    = startup_refresh_max - 7;
localparam startup_ref2_cnt    = 14'(startup_mode_cnt - TRC_MIN);
localparam startup_ref1_cnt    = 14'(startup_ref2_cnt - TRC_MIN);
localparam startup_pchg_cnt    = 14'(startup_ref1_cnt - TRP_MIN);

reg [13:0] refresh_count = startup_refresh_max - sdram_startup_cycles;
reg  [3:0] refresh_wait;
reg  [2:0] command;
reg [15:0] dqout;
reg        dqoe = 0;

reg [3:0]  bast [4]; // bank current status
// bacreq, badreq are bitmaps of future bus cycles required, LSB first
reg [3:0]  bacreq [4]; // cmd bus cycle request bitmap
reg [3:0]  badreq [4]; // data bus cycle request bitmap
reg [12:0] bar_a [4];
reg [2:0]  bar_cmd [4];
reg [15:0] bar_dqout [4];
reg        bar_dqoe [4];


// Bus Bank Scheduler
reg [3:0]  bbsst; // state
reg [1:0]  bbsba; // current bank
reg [1:0]  bbsba_d; // last bank
reg [3:0]  bbscact; // cmd bus cycle activity bitmap
reg [3:0]  bbsdact; // data bus cycle activity bitmap
reg        bbsschn; // bank was newly scheduled
reg [1:0]  bbsschban; // the newly scheduled bank
reg [3:0]  bbsschv; // schedule filled
reg [1:0]  bbsschba [4]; // bank schedule

wire [1:0] bbsschba0 = bbsschba[0];
wire [1:0] bbsschba1 = bbsschba[1];
wire [1:0] bbsschba2 = bbsschba[2];
wire [1:0] bbsschba3 = bbsschba[3];

localparam STATE_STARTUP = 0;
localparam STATE_WAIT    = 1;
localparam STATE_RW1     = 2;
localparam STATE_RW2     = 3;
localparam STATE_ACTIVE  = 4;
localparam STATE_REFRESH = 5;

reg  [3:0] state = STATE_STARTUP;

wire bapause = state != STATE_ACTIVE || refresh_count > cycles_per_refresh;
wire baidle = (bast[0] == BAST_IDLE && bast[1] == BAST_IDLE &&
               bast[2] == BAST_IDLE && bast[3] == BAST_IDLE);

// Bank submodules
sdram_bank #(CLK_MHZ) ba0
   (
    .clk(clk),
    .init(init),
    .REQ(ch1_req),
    .RNW(ch1_rnw),
    .ADDR(ch1_addr),
    .DIN(ch1_din),
    .BE(ch1_be),
    .CREQ(bacreq[0]),
    .DREQ(badreq[0]),
    .ST(bast[0]),
    .PAUSE(bapause),
    .BBSSEL(bbsba == 4'd0),
    .R_A(bar_a[0]),
    .R_CMD(bar_cmd[0]),
    .R_DQOUT(bar_dqout[0]),
    .R_DQOE(bar_dqoe[0])
    );

sdram_bank #(CLK_MHZ) ba1
   (
    .clk(clk),
    .init(init),
    .REQ(ch2_req),
    .RNW(ch2_rnw),
    .ADDR(ch2_addr),
    .DIN(ch2_din),
    .BE(4'b0011),
    .CREQ(bacreq[1]),
    .DREQ(badreq[1]),
    .ST(bast[1]),
    .PAUSE(bapause),
    .BBSSEL(bbsba == 4'd1),
    .R_A(bar_a[1]),
    .R_CMD(bar_cmd[1]),
    .R_DQOUT(bar_dqout[1]),
    .R_DQOE(bar_dqoe[1])
    );

sdram_bank #(CLK_MHZ) ba2
   (
    .clk(clk),
    .init(init),
    .REQ(ch3_req),
    .RNW(ch3_rnw),
    .ADDR(ch3_addr),
    .DIN(ch3_din),
    .BE(4'b0011),
    .CREQ(bacreq[2]),
    .DREQ(badreq[2]),
    .ST(bast[2]),
    .PAUSE(bapause),
    .BBSSEL(bbsba == 4'd2),
    .R_A(bar_a[2]),
    .R_CMD(bar_cmd[2]),
    .R_DQOUT(bar_dqout[2]),
    .R_DQOE(bar_dqoe[2])
    );

sdram_bank #(CLK_MHZ) ba3
   (
    .clk(clk),
    .init(init),
    .REQ('0),
    .RNW('0),
    .ADDR('0),
    .DIN('0),
    .BE('0),
    .CREQ(bacreq[3]),
    .DREQ(badreq[3]),
    .ST(bast[3]),
    .PAUSE(bapause),
    .BBSSEL(bbsba == 4'd3),
    .R_A(bar_a[3]),
    .R_CMD(bar_cmd[3]),
    .R_DQOUT(bar_dqout[3]),
    .R_DQOE(bar_dqoe[3])
    );

// Bus bank scheduler
always @* begin
    bbsba = bbsba_d;
    bbsschn = 0;
    bbsschban = 0;

    if (bbsschv[0]) begin
        // Select previously scheduled bank
        bbsba = bbsschba[0];
    end
    else begin
        // Nothing scheduled yet. Any volunteers?
        for (int b = 3; b >= 0; b--) begin
            if (bbsschn == 0) begin
                bbsschban = b[1:0];

                if (|(bacreq[b] | badreq[b]) &
                    ~|(bacreq[b] & bbscact) & ~|(badreq[b] & bbsdact))
                    bbsschn = 1;
            end
        end
        if (bbsschn)
            // Select newly scheduled bank
            bbsba = bbsschban;
    end
end

initial
    bbsba_d = 0;

always @(posedge clk) begin
    bbsba_d <= bbsba;

    for (int i = 0; i < $size(bbsschv); i++) begin
        if (i < $size(bbsschv) - 1) begin
            bbsschv[i] <= bbsschv[i+1];
            bbsschba[i] <= bbsschba[i+1];
        end
        else begin
            bbsschv[i] <= 0;
            bbsschba[i] <= 0;
        end

        if (bbsschn & bacreq[bbsschban][i]) begin
            bbsschv[i] <= 1;
            bbsschba[i] <= bbsschban;
        end
    end
end

assign bbsst = bast[bbsba];

always @(posedge clk) begin
    bbscact <= {1'b0, bbscact[$left(bbscact):1]} | bacreq[bbsba];
    bbsdact <= {1'b0, bbsdact[$left(bbsdact):1]} | badreq[bbsba];
end

initial begin
    ch1_ready = 0;
    ch2_ready = 0;
    ch3_ready = 0;
end

always @(posedge clk) begin
    reg [CAS_LATENCY+BURST_LENGTH:0] data_ready_delay1, data_ready_delay2, data_ready_delay3;

    ch1_ready <= 0;
    ch2_ready <= 0;
    ch3_ready <= 0;
   
    refresh_count <= refresh_count+1'b1;

    data_ready_delay1 <= data_ready_delay1>>1;
    data_ready_delay2 <= data_ready_delay2>>1;
    data_ready_delay3 <= data_ready_delay3>>1;

    if(data_ready_delay1[1]) ch1_dout[15:00] <= SDRAM_DQ;
    if(data_ready_delay1[0]) ch1_dout[31:16] <= SDRAM_DQ;
    if(data_ready_delay1[0]) ch1_ready <= 1;

    if(data_ready_delay2[1]) ch2_dout[15:00] <= SDRAM_DQ;
    if(data_ready_delay2[0]) ch2_dout[31:16] <= SDRAM_DQ;
    if(data_ready_delay2[0]) ch2_ready <= 1;

    if(data_ready_delay3[1]) ch3_dout[15:00] <= SDRAM_DQ;
    if(data_ready_delay3[0]) ch3_dout[31:16] <= SDRAM_DQ;
    if(data_ready_delay3[0]) ch3_ready <= 1;

    dqoe <= 0;

    command <= CMD_NOP;
    SDRAM_A[12:11] <= 2'b11; // DQM
    case (state)
        STATE_STARTUP: begin
            SDRAM_A[10:0] <= 0;
            SDRAM_BA      <= 0;

            // All the commands during the startup are NOPS, except these
            if (refresh_count == startup_pchg_cnt) begin
                // ensure all rows are closed
                command     <= CMD_PRECHARGE;
                SDRAM_A[10] <= 1;  // all banks
                SDRAM_BA    <= 2'b00;
            end
            if (refresh_count == startup_ref1_cnt) begin
                // these refreshes need to be at least tRC apart
                command     <= CMD_AUTO_REFRESH;
            end
            if (refresh_count == startup_ref2_cnt) begin
                command     <= CMD_AUTO_REFRESH;
            end
            if (refresh_count == startup_pchg_cnt) begin
                // Now load the mode register
                command     <= CMD_LOAD_MODE;
                SDRAM_A     <= MODE;
            end

            if (refresh_count == 0) begin
                state   <= STATE_ACTIVE;
                refresh_count <= 0;
            end
        end

        STATE_REFRESH: begin
            // mask possible refresh to reduce colliding.
            if (refresh_wait == 4'(TRC_MIN)) begin
                // Start the refresh cycle.
                command  <= CMD_AUTO_REFRESH;
                refresh_count <= refresh_count - cycles_per_refresh + 1'd1;
                refresh_wait <= refresh_wait - 1'd1;
            end
            else begin
                refresh_wait <= refresh_wait - 1'd1;
                if (refresh_wait - 1'd1 == 0)
                    state <= STATE_ACTIVE;
            end
        end

        STATE_ACTIVE: begin
            SDRAM_BA <= bbsba;
            SDRAM_A <= bar_a[bbsba];
            command <= bar_cmd[bbsba];
            dqout <= bar_dqout[bbsba];
            dqoe <= bar_dqoe[bbsba];

            case (bbsst)
                BAST_IDLE:
                    if (baidle && refresh_count > cycles_per_refresh) begin
                        // Priority is to issue a refresh if one is outstanding
                        state <= STATE_REFRESH;
                        refresh_wait <= 4'(TRC_MIN);
                    end
                BAST_R_CMD: begin
                    if(bbsba == 0)      data_ready_delay1[CAS_LATENCY+BURST_LENGTH-1] <= 1;
                    else if(bbsba == 1) data_ready_delay2[CAS_LATENCY+BURST_LENGTH-1] <= 1;
                    else                data_ready_delay3[CAS_LATENCY+BURST_LENGTH-1] <= 1;
                end
                BAST_W_CMD_2: begin
                    if(bbsba == 0)      ch1_ready <= 1;
                    else if(bbsba == 1) ch2_ready <= 1;
                    else                ch3_ready <= 1;
                end
                default: ;
            endcase
        end
    endcase

    if (init) begin
        state <= STATE_STARTUP;
        refresh_count <= startup_refresh_max - sdram_startup_cycles;
    end
end

assign SDRAM_DQ   = dqoe ? dqout : 'Z;
assign SDRAM_nCS  = 0;
assign SDRAM_nRAS = command[2];
assign SDRAM_nCAS = command[1];
assign SDRAM_nWE  = command[0];
assign SDRAM_CKE  = 1;
assign {SDRAM_DQMH,SDRAM_DQML} = SDRAM_A[12:11];

//altddio_out
//#(
//  .extend_oe_disable("OFF"),
//  .intended_device_family("Cyclone V"),
//  .invert_output("OFF"),
//  .lpm_hint("UNUSED"),
//  .lpm_type("altddio_out"),
//  .oe_reg("UNREGISTERED"),
//  .power_up_high("OFF"),
//  .width(1)
//)
//sdramclk_ddr
//(
//  .datain_h(1'b0),
//  .datain_l(1'b1),
//  .outclock(clk),
//  .dataout(SDRAM_CLK),
//  .aclr(1'b0),
//  .aset(1'b0),
//  .oe(1'b1),
//  .outclocken(1'b1),
//  .sclr(1'b0),
//  .sset(1'b0)
//);

endmodule

`include "sdram_bank.sv"
