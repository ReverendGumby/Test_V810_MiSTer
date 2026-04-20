// SDRAM controller bank submodule
//
// Copyright (c) 2026 David Hunter
//
// This program is GPL licensed. See COPYING for the full license.

module sdram_bank
    #(parameter CLK_MHZ = 142.8571428)
(
    input         clk,
    input         init,
    input         REQ,
    input         RNW,
    input [26:0]  ADDR,
    input [31:0]  DIN,
    input [3:0]   BE,
    output [3:0]  CREQ,
    output [3:0]  DREQ,
    output [3:0]  ST,
    input         PAUSE,
    input         BBSSEL,
    output [12:0] R_A,
    output [2:0]  R_CMD,
    output [15:0] R_DQOUT,
    output        R_DQOE
);

`include "sdram_defs.svh"

reg         rq, rqc; // access request
reg         rnw; // read / not write
reg [12:0]  row; // row address
reg [9:0]   col; // column address
reg [31:0]  din; // data to write
reg [3:0]   be; // byte enables
reg [3:0]   st, stn; // bank current status
reg [3:0]   wcnt, wcntn; // wait counter
reg [3:0]   creq; // cmd bus cycle request bitmap
reg [3:0]   dreq; // data bus cycle request bitmap
reg [12:0]  r_a;
reg [2:0]   r_cmd;
reg [15:0]  r_dqout;
reg         r_dqoe;

always @(posedge clk) begin
    rnw <= RNW;
    row <= addr_to_row(ADDR);
    col <= addr_to_col(ADDR);
    din <= DIN;
    be <= BE;
end

initial
    rq = 0;
always @(posedge clk) begin
    if (init)
        rq <= 0;
    else
        rq <= (rq & ~rqc) | REQ;
end

// Bank start trigger and request clear
always @* begin
    rqc = BBSSEL && ~PAUSE && rq && (st == BAST_IDLE);
end

// Bank bus cycle request bitmap generator
always @* begin
    creq = 0;
    dreq = 0;

    case (st)
        BAST_IDLE: begin
            if (~PAUSE && rq) begin
                creq = 4'b1;
            end
        end
        BAST_ACT_WAIT:
            if (wcnt == 0) begin
                creq = (1<<BURST_LENGTH)-1;
                dreq = (1<<BURST_LENGTH)-1 << (rnw ? 2 : 0);
            end
        default: ;
    endcase
end

// Bank FSM
always @* begin
    stn = st;
    wcntn = wcnt;

    if (wcnt != 0)
        wcntn = wcnt - 1'd1;

    case (st)
        BAST_IDLE: if (BBSSEL) begin
            if (rqc) begin
                stn = BAST_ACT;
            end
        end
        BAST_ACT: begin
            stn = BAST_ACT_WAIT;
            wcntn = 4'(TRCD_MIN - 2);
        end
        BAST_ACT_WAIT: if (BBSSEL) begin
            if (wcnt == 0) begin
                stn = rnw ? BAST_R_CMD : BAST_W_CMD;
            end
        end
        BAST_R_CMD: begin
            stn = BAST_R_DQM;
        end
        BAST_R_DQM: begin
            stn = BAST_R;
            wcntn = BURST_LENGTH - 1;
        end
        BAST_R:
            if (wcnt == 0) begin
                stn = BAST_PRE;
                wcntn = 4'(TRP_MIN-(BURST_LENGTH-1)) - 2;
            end
        BAST_W_CMD: begin
            stn = BAST_W_CMD_2;
        end
        BAST_W_CMD_2: begin
            stn = BAST_W_REC;
            wcntn = 4'(TWR_MIN - 1);
        end
        BAST_W_REC:
            if (wcnt == 0) begin
                stn = BAST_PRE;
                wcntn = 4'(TRP_MIN - 2);
            end
        BAST_PRE:
            if (wcnt == 0) begin
                stn = BAST_IDLE;
            end
    endcase

    if (init)
        stn = BAST_IDLE;
end

initial begin
    st = BAST_IDLE;
    wcnt = 0;
end

always @(posedge clk) begin
    st <= stn;
    wcnt <= wcntn;
end

always @(posedge clk) begin
    r_a <= '0;
    r_a[12:11] <= 2'b11; // DQM
    r_cmd <= CMD_NOP;
    r_dqout <= '0;
    r_dqoe <= '0;

    case (stn)
        BAST_ACT: begin
            r_a    <= row;
            r_cmd    <= CMD_ACTIVE;
        end
        BAST_R_CMD: begin
            r_a[12:11] <= 0; // DQM for 1st beat
            r_a[10]    <= 1; // auto-precharge
            r_a[9:0]   <= col;
            r_cmd <= CMD_READ;
        end
        BAST_R_DQM: begin
            r_a[12:11] <= 0; // DQM for 2nd beat
        end
        BAST_W_CMD: begin
            r_a[12:11] <= ~be[1:0]; // DQM for 1st beat
            r_a[10]    <= 0; // no auto-precharge
            r_a[9:0]   <= col;
            r_cmd <= CMD_WRITE;
            r_dqout   <= din[15:0];
            r_dqoe    <= 1;
        end
        BAST_W_CMD_2: begin
            r_a[12:11] <= ~be[3:2]; // DQM for 2nd beat
            r_a[10]    <= 1; // auto-precharge
            r_a[9:0]   <= col;
            r_a[0]     <= 1;
            r_cmd        <= CMD_WRITE;
            r_dqout          <= din[31:16];
            r_dqoe           <= 1;
        end
        default: ;
    endcase
end

assign CREQ = creq;
assign DREQ = dreq;
assign ST = st;
assign R_A = r_a;
assign R_CMD = r_cmd;
assign R_DQOUT = r_dqout;
assign R_DQOE = r_dqoe;

endmodule
