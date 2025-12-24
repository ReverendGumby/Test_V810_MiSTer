// File huc6270.vhd translated with vhd2vl 3.0 VHDL to Verilog RTL translator
// vhd2vl settings:
//  * Verilog Module Declaration Style: 2001

// vhd2vl is Free (libre) Software:
//   Copyright (C) 2001-2023 Vincenzo Liguori - Ocean Logic Pty Ltd
//     http://www.ocean-logic.com
//   Modifications Copyright (C) 2006 Mark Gonzales - PMC Sierra Inc
//   Modifications (C) 2010 Shankar Giri
//   Modifications Copyright (C) 2002-2023 Larry Doolittle
//     http://doolittle.icarus.com/~larry/vhd2vl/
//   Modifications (C) 2017 Rodrigo A. Melo
//   Modifications Copyright (c) 2025 David Hunter
//
//   vhd2vl comes with ABSOLUTELY NO WARRANTY.  Always check the resulting
//   Verilog for correctness, ideally with a formal verification tool.
//
//   You are welcome to redistribute vhd2vl under certain conditions.
//   See the license (GPLv2) file included with the source for details.

// File source: https://github.com/MiSTer-devel/TurboGrafx16_MiSTer/blob/72be3244f34571fb7876517bf7eec9f960b8fe03/rtl/huc6270.vhd

/* verilator lint_off PINMISSING */

module huc6270 (
    input             CLK,
    input             RST_N,
    input             CLR_MEM,
    input             CPU_CE,
    input             BYTEWORD, // 16-bit data = 0; 8-bit data = 1
    input [1:0]       A, // if 16-bit data, A(0) probably = 0 and should be ignored in any case
    input [15:0]      DI,
    output reg [15:0] DO,
    input             CS_N,
    input             WR_N,
    input             RD_N,
    output            BUSY_N,
    output            IRQ_N,
    input             DCK_CE,
    input             DCK_CE_F,
    input             HSYNC_F,
    input             HSYNC_R,
    input             VSYNC_F,
    input             VSYNC_R,
    output reg [8:0]  VD,
    output            BORDER,
    output [1:0]      GRID,
    input             SP64,
    output reg [15:0] RAM_A,
    input [15:0]      RAM_DI,
    output reg [15:0] RAM_DO,
    output reg        RAM_WE,
    input             BG_EN,
    input             SPR_EN,

    output [1:0]      IW_DBG,
    output [1:0]      VM_DBG,
    output            CM_DBG,
    output [2:0]      SCREEN_DBG,
    output [15:0]     SOUR_DBG,
    output [15:0]     DESR_DBG,
    output [15:0]     LENR_DBG,
    output [9:0]      SPR_X_DBG,
    output [9:0]      SPR_Y_DBG,
    output [10:0]     SPR_PC_DBG,
    output            SPR_CG_DBG,
    output [3:0]      SPR_PAL_DBG,
    output            SPR_PRIO_DBG,
    output            SPR_CGX_DBG,
    output [1:0]      SPR_CGY_DBG,
    output            SPR_HF_DBG,
    output            SPR_VF_DBG,
    output [6:0]      HSW_END_POS_DBG,
    output [6:0]      HDS_END_POS_DBG,
    output [6:0]      HDISP_END_POS_DBG,
    output [4:0]      HSW_DBG,
    output [6:0]      HDS_DBG,
    output [6:0]      HDE_DBG,
    output [9:0]      VDS_END_POS_DBG,
    output [9:0]      VDISP_END_POS_DBG,
    output [9:0]      VDE_END_POS_DBG
);

// 16-bit data = 0; 8-bit data = 1
// if 16-bit data, A(0) probably = 0 and should be ignored in any case

//registers
reg [15:0] REGS[0:31];

`define MAWR        REGS[0]
`define MARR        REGS[1]
`define VWR         REGS[2]
`define RCR         REGS[6][9:0]
`define BXR         REGS[7][9:0]
`define BYR         REGS[8][8:0]
`define HSR_HSW     REGS[10][4:0]
`define HSR_HDS     REGS[10][14:8]
`define HDR_HDW     REGS[11][6:0]
`define HDR_HDE     REGS[11][14:8]
`define VPR_VSW     REGS[12][4:0]
`define VPR_VDS     REGS[12][15:8]
`define VDR_VDW     REGS[13][8:0]
`define VCR_VCR     REGS[14][7:0]
`define DCR_DSC     REGS[15][0]
`define DCR_DVC     REGS[15][1]
`define DCR_SID     REGS[15][2]
`define DCR_DID     REGS[15][3]
`define DCR_DSR     REGS[15][4]
`define SOUR        REGS[16]
`define DESR        REGS[17]
`define LENR        REGS[18]
`define DVSSR       REGS[19]
`define CR_IE_CC    REGS[5][0]
`define CR_IE_OC    REGS[5][1]
`define CR_IE_RC    REGS[5][2]
`define CR_IE_VC    REGS[5][3]
`define CR_SB       REGS[5][6]
`define CR_BB       REGS[5][7]
`define CR_IW       REGS[5][12:11]
`define MWR_VM      REGS[9][1:0]
`define MWR_SM      REGS[9][3:2]
`define MWR_SCREEN  REGS[9][6:4]
`define MWR_CM      REGS[9][7]

//internal registers
reg [4:0] AR;
reg [15:0] VRR;
reg [1:0] VM;
reg [1:0] SM;
reg [2:0] SCREEN;
reg CM;
reg BB;
reg SB;

//I/O 
reg IRQ_DMA;
reg IRQ_COL;
reg IRQ_OVF;
reg IRQ_RCR;
reg IRQ_DMAS;
reg IRQ_VBL;
reg IO_BYRL_SET;
reg IO_BYRH_SET;
reg IO_BYRL_WR; reg IO_BYRH_WR;
reg CPU_BUSY;
reg CPU_BUSY_CLEAR;
reg CPURD_PEND;
reg CPUWR_PEND;
reg CPURD_PEND2;
reg CPUWR_PEND2;
reg CPURD_EXEC;
reg CPUWR_EXEC;
reg [15:0] CPU_VRAM_ADDR;
reg [15:0] CPU_VRAM_DATA;
reg DMA_PEND;
reg DMA_WR;
reg [15:0] DMA_BUF;
reg DMA_EXEC;
reg DMAS_PEND;
reg DMAS_EXEC;
reg [7:0] DMAS_SAT_ADDR;
reg [15:0] DMAS_VRAM_ADDR;
wire DMAS_SAT_WE;
reg BXR_SET;
reg BYRL_SET;
reg BYRH_SET;
reg VDISP_OLD;
reg RD_N_OLD;
reg [6:0] SR_LATCH;

//H/V counters
reg [2:0] DOT_CNT;
reg [6:0] TILE_CNT;
reg [9:0] DISP_CNT;
reg DISP_CNT_INC;
wire DISP_BREAK;
reg DISP_BREAK_EN;
reg DISP_BREAK_LATCH;
reg TILE_ZERO;
reg [2:0] DOTS_REMAIN;
reg [9:0] RC_CNT;
reg BURST;
wire [6:0] HSW_END_POS;
wire [6:0] HDS_END_POS;
wire [6:0] HDISP_END_POS;
wire [6:0] HDE_END_POS;
wire [9:0] VDS_END_POS;
wire [9:0] VDISP_END_POS;
wire [9:0] VDE_END_POS;
wire [9:0] VSW_END_POS;
reg [4:0] HSW;
reg [6:0] HDS;
reg [6:0] HDW;
reg [6:0] HDE;
reg [4:0] VSW;
reg [7:0] VDS;
reg [8:0] VDW;
reg [7:0] VDE;
reg [0:0] RES7M;
wire HDISP;
reg VDISP;

//rendering
parameter [3:0]
  CPU = 0,
  BAT = 1,
  CG0 = 2,
  CG1 = 3,
  SG0 = 4,
  SG1 = 5,
  SG2 = 6,
  SG3 = 7,
  NOP = 8;

reg [3:0] SLOT;
reg [7:0] DISP;
reg [7:0] BORD;
reg [7:0] GRID_BG;
reg [7:0] GRID_SP;
reg [9:0] BG_X;
reg [9:0] OFS_X;
reg [8:0] OFS_Y;
reg [9:0] BG_OUT_X;
reg BG_FETCH;
reg BG_OUT;
reg [11:0] BG_BAT_CC;
reg [3:0] BG_BAT_COL;
reg [7:0] BG_CH0;
reg [7:0] BG_CH1;
reg [15:0] BG_SR0;
reg [15:0] BG_SR1;
reg [15:0] BG_SR2;
reg [15:0] BG_SR3;

reg [3:0] BG_SRC[0:1];

reg [7:0] BG_COLOR[0:7];
reg [15:0] BG_RAM_ADDR;
reg SPR_FETCH;
reg SPR_FETCH_EN;
reg [15:0] SPR_CH0;
reg [15:0] SPR_CH1;
reg [15:0] SPR_CH2;
wire [15:0] SPR_CH3;
reg [15:0] SPR_RAM_ADDR;

typedef struct packed {
    reg [9:0] X;
    reg [9:0] Y;
    reg [10:0] PC;
    reg CG;
    reg [3:0] PAL;
    reg PRIO;
    reg CGX;
    reg [1:0] CGY;
    reg HF;
    reg VF;
    reg SPR0;
    reg TOP;
    reg BOTTOM;
} Sprite_r;

Sprite_r SPR_CACHE[0:63];
Sprite_r SPR;
reg SPR_EVAL;
reg [7:0] SPR_EVAL_X;
reg SPR_EVAL_DONE;
reg SPR_EVAL_FULL;
reg [6:0] SPR_EVAL_CNT;
reg SPR_FIND;
reg [9:0] SPR_Y;
reg [9:0] SPR_X;
reg [10:0] SPR_PC;
reg SPR_CG;
reg [6:0] SPR_FETCH_CNT;
reg SPR_FETCH_DONE;
reg SPR_FETCH_W;
reg [9:0] SPR_OUT_X;
wire SPR_CE;
wire [31:0] SPR_MAX;
reg [2:0] FETCH_DOT;
reg FETCH_CE;
wire [2:0] FDOT_CNT;
reg [9:0] SPR_TILE_X;
reg [15:0] SPR_TILE_P0;
reg [15:0] SPR_TILE_P1;
reg [15:0] SPR_TILE_P2;
reg [15:0] SPR_TILE_P3;
reg SPR_TILE_HF;
reg [3:0] SPR_TILE_PAL;
reg SPR_TILE_PRIO;
reg SPR_TILE_SPR0;
reg SPR_TILE_LEFT;
reg SPR_TILE_RIGTH;
reg SPR_TILE_TOP;
reg SPR_TILE_BOTTOM;
reg SPR_TILE_SAVE;
reg [559:0] SPR_TILE_PIX_SET;
reg [559:0] SPR_TILE_SPR0_SET;
reg [559:0] SPR_TILE_FRAME;

reg [8:0] SPR_LINE_ADDR[0:1];
reg [8:0] SPR_LINE_D[0:1];
wire [8:0] SPR_LINE_Q[0:1];
reg [1:0] SPR_LINE_WE;
reg SPR_LINE_CLR;

reg [8:0] SPR_COLOR[0:7];
wire [7:0] SAT_ADDR;
wire [15:0] SAT_Q;
reg [7:0] CLR_A;
reg CLR_WE;

  always @(posedge CLK, posedge RST_N) begin
    if(RST_N == 1'b0) begin
      DOT_CNT <= {3{1'b0}};
      TILE_CNT <= {7{1'b0}};
      DOTS_REMAIN <= {3{1'b0}};
      HSW <= {5{1'b0}};
      HDW <= 7'b0011111;
      HDS <= {7{1'b0}};
      HDE <= {7{1'b0}};
      CM <= 1'b0;
      RES7M <= 1'b0;
    end else begin
      FETCH_CE <=  ~FETCH_CE;
      if(FETCH_CE == 1'b1) begin
        FETCH_DOT <= FETCH_DOT + 1;
      end
      if(SPR_FETCH == 1'b0) begin
        FETCH_CE <= 1'b0;
        FETCH_DOT <= {3{1'b0}};
      end
      if(DCK_CE == 1'b1) begin
        DOT_CNT <= DOT_CNT + 1;
        if(DOT_CNT == 7) begin
          TILE_CNT <= TILE_CNT + 1;
          TILE_ZERO <= 1'b0;
        end
        if((TILE_CNT == HDE_END_POS && DOT_CNT == 7) || HSYNC_F == 1'b1) begin
          DOT_CNT <= {3{1'b0}};
          TILE_CNT <= {7{1'b0}};
          DOTS_REMAIN <= DOT_CNT;
          if(HSYNC_F == 1'b1) begin
            HSW <= 5'b00011;
            TILE_ZERO <= 1'b1;
          end
          else begin
            HSW <= `HSR_HSW;
          end
          HDS <= `HSR_HDS;
          HDW <= `HDR_HDW;
          HDE <= `HDR_HDE;
          RES7M <= 1'b0;
          CM <= `MWR_CM;
        end
      end
      if(DCK_CE == 1'b0 && HSYNC_F == 1'b1) begin
        RES7M <= 1'b1;
      end
    end
  end

  assign FDOT_CNT = SP64 == 1'b0 ? DOT_CNT : FETCH_DOT;
  assign SPR_CE = SP64 == 1'b0 ? DCK_CE : FETCH_CE;
  assign SPR_MAX = SP64 == 1'b0 ? 15 : 63;
  assign HSW_END_POS = {2'b00,HSW} + ({6'b000000,RES7M});
  assign HDS_END_POS = ({2'b00,HSW}) + ({6'b000000,RES7M}) + 1 + (HDS);
  assign HDISP_END_POS = ({2'b00,HSW}) + ({6'b000000,RES7M}) + 1 + (HDS) + 1 + (HDW);
  assign HDE_END_POS = ({2'b00,HSW}) + ({6'b000000,RES7M}) + 1 + (HDS) + 1 + (HDW) + 1 + (HDE);
  assign VSW_END_POS = {5'b00000,VSW};
  assign VDS_END_POS = ({5'b00000,VSW}) + 1 + ({2'b00,VDS}) + 1;
  assign VDISP_END_POS = ({5'b00000,VSW}) + 1 + ({2'b00,VDS}) + 2 + ({1'b0,VDW});
  assign VDE_END_POS = ({5'b00000,VSW}) + 1 + ({2'b00,VDS}) + 2 + ({1'b0,VDW}) + 1 + ({2'b00,VDE}) - 1;
  assign DISP_BREAK = DISP_CNT_INC == 1'b1 && HSYNC_F == 1'b1 ? 1'b1 : 1'b0;
  always @(posedge CLK, posedge RST_N) begin : P7
    reg RC_CNT_UPDATED;

    if(RST_N == 1'b0) begin
      DISP_CNT <= {10{1'b0}};
      DISP_CNT_INC <= 1'b0;
      VDISP <= 1'b0;
      BURST <= 1'b1;
      BG_FETCH <= 1'b0;
      BG_OUT <= 1'b0;
      RC_CNT <= {2'b00,8'h40};
      RC_CNT_UPDATED = 1'b0;
      VSW <= {5{1'b0}};
      VDS <= {8{1'b0}};
      VDW <= {9{1'b0}};
      VDE <= {8{1'b0}};
      VM <= {2{1'b0}};
      SM <= {2{1'b0}};
      SCREEN <= {3{1'b0}};
      BB <= 1'b0;
      SB <= 1'b0;
    end else begin
      if(DCK_CE == 1'b1) begin
        if(VSYNC_F == 1'b1) begin
          VDISP <= 1'b0;
          DISP_CNT <= {10{1'b0}};
          VSW <= `VPR_VSW;
          VDS <= `VPR_VDS;
          VDW <= `VDR_VDW;
          VDE <= `VCR_VCR;
          VM <= `MWR_VM;
          SM <= `MWR_SM;
          SCREEN <= `MWR_SCREEN;
        end
        else begin
          if(DOT_CNT == 7) begin
            DISP_BREAK_LATCH <= 1'b0;
          end
          if(TILE_CNT == HSW_END_POS && DOT_CNT == 7) begin
            DISP_CNT_INC <= 1'b1;
            DISP_BREAK_EN <= 1'b1;
          end
          if(TILE_CNT == HDISP_END_POS && DOT_CNT == 7) begin
            DISP_BREAK_EN <= 1'b0;
          end
          if(DISP_BREAK == 1'b1) begin //(TILE_CNT = HDE_END_POS and DOT_CNT = 7 and DISP_CNT_INC = '1') or 
            DISP_CNT <= DISP_CNT + 1;
            DISP_CNT_INC <= 1'b0;
            if(DISP_CNT == VSW_END_POS) begin
              BURST <=  ~(`CR_SB | `CR_BB);
            end
            if(DISP_CNT == VDS_END_POS) begin
              VDISP <= 1'b1;
            end
            if(DISP_CNT == VDISP_END_POS) begin
              VDISP <= 1'b0;
            end
            if(DISP_CNT == VDE_END_POS) begin
              DISP_CNT <= {10{1'b0}};
              VSW <= `VPR_VSW;
              VDS <= `VPR_VDS;
              VDW <= `VDR_VDW;
              VDE <= `VCR_VCR;
              VM <= `MWR_VM;
              SM <= `MWR_SM;
              SCREEN <= `MWR_SCREEN;
            end
            DISP_BREAK_LATCH <= DISP_BREAK_EN;
            DISP_BREAK_EN <= 1'b0;
          end
        end
        if(TILE_CNT == (HDS_END_POS - 2) && DOT_CNT == 7 && DISP_CNT > VDS_END_POS && DISP_CNT <= VDISP_END_POS) begin
          BG_FETCH <= 1'b1;
        end
        else if((TILE_CNT == HDISP_END_POS && DOT_CNT == 7) || (TILE_CNT == 0 && DOT_CNT == 7 && DISP_BREAK_LATCH == 1'b1)) begin
          BG_FETCH <= 1'b0;
        end
        if(TILE_CNT == HDS_END_POS && DOT_CNT == 7 && DISP_CNT > VDS_END_POS && DISP_CNT <= VDISP_END_POS) begin
          BG_OUT <= 1'b1;
        end
        else if((TILE_CNT == HDISP_END_POS && DOT_CNT == 7) || (TILE_CNT == 0 && DOT_CNT == 7 && DISP_BREAK_LATCH == 1'b1)) begin
          BG_OUT <= 1'b0;
        end
        if((TILE_CNT == HDISP_END_POS && DOT_CNT == 7) || (DISP_BREAK == 1'b1 && RC_CNT_UPDATED == 1'b0)) begin
          if(DISP_CNT == (VDS_END_POS - 1)) begin
            RC_CNT <= {2'b00,8'h40};
          end
          else begin
            RC_CNT <= RC_CNT + 1;
          end
        end
        if(DISP_BREAK == 1'b1) begin
          RC_CNT_UPDATED = 1'b0;
        end
        if(TILE_CNT == HDISP_END_POS && DOT_CNT == 7) begin
          RC_CNT_UPDATED = 1'b1;
        end
        if(TILE_CNT == (HDS_END_POS - 3) && DOT_CNT == 6) begin
          BB <= `CR_BB;
          SB <= `CR_SB;
        end
      end
    end
  end

  always @(DOT_CNT, FDOT_CNT, DOTS_REMAIN, TILE_ZERO, TILE_CNT, BURST, DMAS_EXEC, DMA_EXEC, BG_FETCH, SPR_FETCH, SPR_FETCH_EN, VM, CM, SM, SPR, BB, SP64) begin
    if(TILE_ZERO == 1'b1 && DOT_CNT <= DOTS_REMAIN && SP64 == 1'b0) begin
      //first several cycles in HSYNC are empty, i.e. without access the memory, N=dots%8
      SLOT <= NOP;
    end
    else if(DMAS_EXEC == 1'b1) begin
      case(DOT_CNT[1:0])
      2'b00 : begin
        SLOT <= NOP;
      end
      2'b01 : begin
        SLOT <= NOP;
      end
      2'b10 : begin
        SLOT <= NOP;
      end
      default : begin
        SLOT <= CPU;
      end
      endcase
    end
    else if(DMA_EXEC == 1'b1) begin
      case(DOT_CNT[1:0])
      2'b00 : begin
        SLOT <= CPU;
      end
      2'b01 : begin
        SLOT <= NOP;
      end
      2'b10 : begin
        SLOT <= CPU;
      end
      default : begin
        SLOT <= NOP;
      end
      endcase
    end
    else if(BG_FETCH == 1'b1) begin
      if(BB == 1'b0) begin
        //| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
        //|  CPU  |  CPU  |  CPU  |  CPU  |
        case(DOT_CNT[1:0])
        2'b00 : begin
          SLOT <= CPU;
        end
        2'b01 : begin
          SLOT <= NOP;
        end
        2'b10 : begin
          SLOT <= CPU;
        end
        default : begin
          SLOT <= NOP;
        end
        endcase
      end
      else begin
        case(VM)
        2'b00 : begin
          case(DOT_CNT[2:0])
          3'b000 : begin
            SLOT <= CPU;
          end
          3'b001 : begin
            SLOT <= BAT;
          end
          3'b010 : begin
            SLOT <= CPU;
          end
          3'b011 : begin
            SLOT <= NOP;
          end
          3'b100 : begin
            SLOT <= CPU;
          end
          3'b101 : begin
            SLOT <= CG0;
          end
          3'b110 : begin
            SLOT <= CPU;
          end
          default : begin
            SLOT <= CG1;
          end
          endcase
        end
        2'b01,2'b10 : begin
          case(DOT_CNT[2:0])
          3'b000 : begin
            SLOT <= NOP;
          end
          3'b001 : begin
            SLOT <= BAT;
          end
          3'b010 : begin
            SLOT <= NOP;
          end
          3'b011 : begin
            SLOT <= CPU;
          end
          3'b100 : begin
            SLOT <= NOP;
          end
          3'b101 : begin
            SLOT <= CG0;
          end
          3'b110 : begin
            SLOT <= NOP;
          end
          default : begin
            SLOT <= CG1;
          end
          endcase
        end
        default : begin
          case(DOT_CNT[2:0])
          3'b000 : begin
            SLOT <= NOP;
          end
          3'b001 : begin
            SLOT <= NOP;
          end
          3'b010 : begin
            SLOT <= NOP;
          end
          3'b011 : begin
            SLOT <= BAT;
          end
          3'b100 : begin
            SLOT <= NOP;
          end
          3'b101 : begin
            SLOT <= NOP;
          end
          3'b110 : begin
            SLOT <= NOP;
          end
          default : begin
            if(CM == 1'b0) begin
              SLOT <= CG0;
            end
            else begin
              SLOT <= CG1;
            end
          end
          endcase
        end
        endcase
      end
    end
    else if(SPR_FETCH == 1'b1) begin
      if(SPR_FETCH_EN == 1'b0) begin
        //if there are no partially or fully sprites in the row for fetching, 
        //then the cycles are replaced by CPU slots
        //| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
        //|  CPU  |  CPU  |  CPU  |  CPU  |
        case(DOT_CNT[1:0])
        2'b00 : begin
          SLOT <= CPU;
        end
        2'b01 : begin
          SLOT <= NOP;
        end
        2'b10 : begin
          SLOT <= CPU;
        end
        default : begin
          SLOT <= NOP;
        end
        endcase
      end
      else begin
        case(SM)
        2'b00 : begin
          //| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
          //|SG0|SG1|SG2|SG3|SG0|SG1|SG2|SG3|
          case(FDOT_CNT[1:0])
          2'b00 : begin
            SLOT <= SG0;
          end
          2'b01 : begin
            SLOT <= SG1;
          end
          2'b10 : begin
            SLOT <= SG2;
          end
          default : begin
            SLOT <= SG3;
          end
          endcase
        end
        2'b01 : begin
          //| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
          //|  SG0  |  SG1  |  SG0  |  SG1  |
          //| (SG2) | (SG3) | (SG2) | (SG3) |
          case(FDOT_CNT[1:0])
          2'b01 : begin
            if(SPR.CG == 1'b0) begin
              SLOT <= SG0;
            end
            else begin
              SLOT <= SG2;
            end
          end
          2'b11 : begin
            if(SPR.CG == 1'b0) begin
              SLOT <= SG1;
            end
            else begin
              SLOT <= SG3;
            end
          end
          default : begin
            SLOT <= NOP;
          end
          endcase
        end
        2'b10 : begin
          //| 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
          //|  SG0  |  SG1  |  SG2  |  SG3  |
          case(FDOT_CNT[1:0])
          2'b01 : begin
            if(FDOT_CNT[2] == 1'b0) begin
              SLOT <= SG0;
            end
            else begin
              SLOT <= SG2;
            end
          end
          2'b11 : begin
            if(FDOT_CNT[2] == 1'b0) begin
              SLOT <= SG1;
            end
            else begin
              SLOT <= SG3;
            end
          end
          default : begin
            SLOT <= NOP;
          end
          endcase
        end
        default : begin
          case(FDOT_CNT[1:0])
          2'b11 : begin
            case({TILE_CNT[0], FDOT_CNT[2]}) /// unsigned(TILE_CNT(0 downto 0)&FDOT_CNT(2 downto 2))
            2'b00 : begin
              SLOT <= SG0;
            end
            2'b01 : begin
              SLOT <= SG1;
            end
            2'b10 : begin
              SLOT <= SG2;
            end
            default : begin
              SLOT <= SG3;
            end
            endcase
          end
          default : begin
            SLOT <= NOP;
          end
          endcase
        end
        endcase
      end
    end
    else begin
      case(DOT_CNT[1:0])
      2'b00 : begin
        SLOT <= CPU;
      end
      2'b01 : begin
        SLOT <= NOP;
      end
      2'b10 : begin
        SLOT <= CPU;
      end
      default : begin
        SLOT <= NOP;
      end
      endcase
    end
  end

  //BG
  always @(SLOT, BG_X, OFS_Y, OFS_X, SCREEN, BG_BAT_CC) begin : P6
    reg [9:0] BG_OFS_X;
    reg [8:0] BG_OFS_Y;

    BG_OFS_X = BG_X + OFS_X;
    if(SCREEN[2] == 1'b0) begin
      BG_OFS_Y = {1'b0,OFS_Y[7:0]};
    end
    else begin
      BG_OFS_Y = OFS_Y;
    end
    case(SLOT)
    BAT : begin
      case(SCREEN[1:0])
      2'b00 : begin
        BG_RAM_ADDR <= {5'b00000,BG_OFS_Y[8:3],BG_OFS_X[7:3]};
      end
      2'b01 : begin
        BG_RAM_ADDR <= {4'b0000,BG_OFS_Y[8:3],BG_OFS_X[8:3]};
      end
      default : begin
        BG_RAM_ADDR <= {3'b000,BG_OFS_Y[8:3],BG_OFS_X[9:3]};
      end
      endcase
    end
    CG0 : begin
      BG_RAM_ADDR <= {BG_BAT_CC,1'b0,BG_OFS_Y[2:0]};
    end
    CG1 : begin
      BG_RAM_ADDR <= {BG_BAT_CC,1'b1,BG_OFS_Y[2:0]};
    end
    default : begin
      BG_RAM_ADDR <= {16{1'b0}};
    end
    endcase
  end

  always @(posedge CLK, posedge RST_N) begin : P5
    reg [8:0] NEW_OFS_Y;

    if(RST_N == 1'b0) begin
      BG_X <= {10{1'b0}};
      OFS_X <= {10{1'b0}};
      OFS_Y <= {9{1'b0}};
      BG_BAT_CC <= {12{1'b0}};
      BG_BAT_COL <= {4{1'b0}};
      BG_CH0 <= {8{1'b0}};
      BG_CH1 <= {8{1'b0}};
      BG_SR0 <= {16{1'b0}};
      BG_SR1 <= {16{1'b0}};
      BG_SR2 <= {16{1'b0}};
      BG_SR3 <= {16{1'b0}};
      BG_SRC[0] <= {4{1'b0}};
      BG_SRC[1] <= {4{1'b0}};
    end else begin
      if(DCK_CE == 1'b1) begin
        case(SLOT)
        BAT : begin
          BG_BAT_CC <= RAM_DI[11:0];
          BG_BAT_COL <= RAM_DI[15:12];
        end
        CG0 : begin
          BG_CH0 <= RAM_DI[7:0];
          BG_CH1 <= RAM_DI[15:8];
        end
        CG1 : begin
        end
        default : begin
        end
        endcase
        if(SLOT == CG1 || (SLOT == CG0 && VM == 2'b11)) begin
          if(SLOT == CG0 && VM == 2'b11) begin
            BG_SR0 <= {BG_SR0[7:0],RAM_DI[7:0]};
            BG_SR1 <= {BG_SR1[7:0],RAM_DI[15:8]};
            BG_SR2 <= {16{1'b0}};
            BG_SR3 <= {16{1'b0}};
          end
          else if(SLOT == CG1 && VM == 2'b11) begin
            BG_SR0 <= {16{1'b0}};
            BG_SR1 <= {16{1'b0}};
            BG_SR2 <= {BG_SR2[7:0],RAM_DI[7:0]};
            BG_SR3 <= {BG_SR3[7:0],RAM_DI[15:8]};
          end
          else begin
            BG_SR0 <= {BG_SR0[7:0],BG_CH0};
            BG_SR1 <= {BG_SR1[7:0],BG_CH1};
            BG_SR2 <= {BG_SR2[7:0],RAM_DI[7:0]};
            BG_SR3 <= {BG_SR3[7:0],RAM_DI[15:8]};
          end
          BG_SRC[1] <= BG_SRC[0];
          BG_SRC[0] <= BG_BAT_COL;
          BG_X <= BG_X + 8;
        end
        if(TILE_CNT == (HDS_END_POS - 2) && DOT_CNT == 7) begin
          BG_X <= {10{1'b0}};
        end
        if(TILE_CNT == (HDS_END_POS - 3) && DOT_CNT == 7 && DISP_CNT == (VDS_END_POS + 1)) begin
          OFS_Y <= `BYR;
        end
        else if(TILE_CNT == (HDS_END_POS - 3) && DOT_CNT == 7) begin
          if(BYRL_SET == 1'b1 || BYRH_SET == 1'b1) begin
            NEW_OFS_Y = `BYR;
          end
          else begin
            NEW_OFS_Y = OFS_Y;
          end
          OFS_Y <= NEW_OFS_Y + 1;
        end
        if(BXR_SET == 1'b1) begin
          OFS_X <= `BXR;
        end
      end
    end
  end

  //Sprites
  assign DMAS_SAT_WE = DMAS_EXEC == 1'b1 && SLOT == CPU ? DCK_CE : 1'b0;
  assign SAT_ADDR = CLR_WE == 1'b0 ? SPR_EVAL_X : CLR_A;

  dpram #(8, 16) SAT
  (
   .clock(CLK),
   .data_a(RAM_DI),
   .address_a(DMAS_SAT_ADDR),
   .wren_a(DMAS_SAT_WE),
   .address_b(SAT_ADDR),
   .data_b('0),
   .wren_b(CLR_WE),
   .q_b(SAT_Q)
   );

  always @(posedge CLK) begin
      CLR_A <= CLR_A + 1;
      CLR_WE <= CLR_MEM;
  end

  assign SPR = SPR_CACHE[SPR_FETCH_CNT[5:0]];

  always @(SLOT, RC_CNT, SPR, SPR_FETCH_W) begin : P4
    reg [5:0] SPR_OFS_Y;
    reg [5:0] SPR_LINE;
    reg [2:0] SPR_TILE_N;

    SPR_OFS_Y = RC_CNT[5:0] - (SPR.Y[5:0]) - 1;
    SPR_LINE = SPR_OFS_Y ^ {6{SPR.VF}};
    if(SPR.CGX == 1'b0) begin
      SPR_TILE_N[0] = SPR.PC[1];
    end
    else begin
      SPR_TILE_N[0] = SPR_FETCH_W ^ SPR.HF;
    end
    case(SPR.CGY)
    2'b00 : begin
      SPR_TILE_N[2:1] = SPR.PC[3:2];
    end
    2'b01 : begin
      SPR_TILE_N[2:1] = {SPR.PC[3],SPR_LINE[4]};
    end
    default : begin
      SPR_TILE_N[2:1] = {SPR_LINE[5],SPR_LINE[4]};
    end
    endcase
    case(SLOT)
    SG0 : begin
      SPR_RAM_ADDR <= {SPR.PC[10:4],SPR_TILE_N,2'b00,SPR_LINE[3:0]};
    end
    SG1 : begin
      SPR_RAM_ADDR <= {SPR.PC[10:4],SPR_TILE_N,2'b01,SPR_LINE[3:0]};
    end
    SG2 : begin
      SPR_RAM_ADDR <= {SPR.PC[10:4],SPR_TILE_N,2'b10,SPR_LINE[3:0]};
    end
    SG3 : begin
      SPR_RAM_ADDR <= {SPR.PC[10:4],SPR_TILE_N,2'b11,SPR_LINE[3:0]};
    end
    default : begin
      SPR_RAM_ADDR <= {16{1'b0}};
    end
    endcase
  end

  always @(posedge CLK, posedge RST_N) begin : P3
    reg [5:0] SPR_H;

    if(RST_N == 1'b0) begin
      SPR_EVAL <= 1'b0;
      SPR_EVAL_X <= {8{1'b0}};
      SPR_EVAL_DONE <= 1'b0;
      SPR_EVAL_FULL <= 1'b0;
      SPR_EVAL_CNT <= {7{1'b0}};
      SPR_FIND <= 1'b0;
      for (int i = 0; i < 64; i++)
        SPR_CACHE[i] <= '0;
      SPR_Y <= {10{1'b0}};
      SPR_X <= {10{1'b0}};
      SPR_PC <= {11{1'b0}};
      SPR_CG <= 1'b0;
      SPR_FETCH <= 1'b0;
      SPR_FETCH_EN <= 1'b0;
      SPR_FETCH_W <= 1'b0;
      SPR_FETCH_DONE <= 1'b0;
      SPR_CH0 <= {16{1'b0}};
      SPR_CH1 <= {16{1'b0}};
      SPR_CH2 <= {16{1'b0}};
      //SPR_CH3 <= (others=>'0');
      SPR_TILE_X <= {10{1'b0}};
      SPR_TILE_P0 <= {16{1'b0}};
      SPR_TILE_P1 <= {16{1'b0}};
      SPR_TILE_P2 <= {16{1'b0}};
      SPR_TILE_P3 <= {16{1'b0}};
      SPR_TILE_HF <= 1'b0;
      SPR_TILE_PAL <= {4{1'b0}};
      SPR_TILE_PRIO <= 1'b0;
      SPR_TILE_SPR0 <= 1'b0;
      SPR_TILE_SAVE <= 1'b0;
      IRQ_OVF <= 1'b0;
    end else begin
      SPR_TILE_SAVE <= 1'b0;
      if(DCK_CE == 1'b1) begin
        if(TILE_CNT == HDS_END_POS && DOT_CNT == 3 && DISP_CNT >= VDS_END_POS && DISP_CNT < VDISP_END_POS) begin
          SPR_EVAL <= 1'b1;
          SPR_EVAL_X <= {8{1'b0}};
          SPR_EVAL_CNT <= {7{1'b0}};
          SPR_EVAL_DONE <= 1'b0;
          SPR_EVAL_FULL <= 1'b0;
          SPR_FIND <= 1'b0;
        end
        else if((DOT_CNT == 7 && TILE_CNT == HDISP_END_POS) || (DOT_CNT == 7 && TILE_CNT == 0 && DISP_BREAK_LATCH == 1'b1)) begin
          SPR_EVAL <= 1'b0;
        end
        if(((DOT_CNT == 7 && TILE_CNT == HDISP_END_POS && DISP_CNT >= VDS_END_POS && DISP_CNT < VDISP_END_POS) || (DOT_CNT == 7 && TILE_CNT == 0 && DISP_BREAK_LATCH == 1'b1 && DISP_CNT > VDS_END_POS && DISP_CNT <= VDISP_END_POS)) && SPR_FETCH == 1'b0) begin
          SPR_FETCH <= 1'b1;
          SPR_FETCH_EN <= `CR_SB & SPR_FIND;
          SPR_FETCH_CNT <= {7{1'b0}};
          SPR_FETCH_W <= 1'b0;
          SPR_FETCH_DONE <= 1'b0;
        end
        else if(TILE_CNT == (HDS_END_POS - 2) && DOT_CNT == 7) begin
          SPR_FETCH <= 1'b0;
        end
        if(SPR_EVAL == 1'b1) begin
          if(SPR_EVAL_DONE == 1'b0) begin
            case(SPR_EVAL_X[1:0])
            2'b00 : begin
              SPR_Y <= SAT_Q[9:0];
            end
            2'b01 : begin
              SPR_X <= SAT_Q[9:0];
            end
            2'b10 : begin
              SPR_CG <= SAT_Q[0];
              SPR_PC <= SAT_Q[10:0];
            end
            default : begin
              SPR_H = {SAT_Q[13],SAT_Q[13] | SAT_Q[12],4'b1111};
              if(RC_CNT >= (SPR_Y) && RC_CNT <= ((SPR_Y) + 10'(SPR_H))) begin
                SPR_FIND <= 1'b1;
                if(SPR_EVAL_FULL == 1'b0) begin
                  //SPR_CACHE[SPR_EVAL_CNT[5:0]].X <= SPR_X;
                  //SPR_CACHE[SPR_EVAL_CNT[5:0]].Y <= SPR_Y;
                  //SPR_CACHE[SPR_EVAL_CNT[5:0]].PC <= SPR_PC;
                  //SPR_CACHE[SPR_EVAL_CNT[5:0]].CG <= SPR_CG;
                  //SPR_CACHE[SPR_EVAL_CNT[5:0]].PAL <= SAT_Q[3:0];
                  //SPR_CACHE[SPR_EVAL_CNT[5:0]].PRIO <= SAT_Q[7];
                  //SPR_CACHE[SPR_EVAL_CNT[5:0]].CGX <= SAT_Q[8];
                  //SPR_CACHE[SPR_EVAL_CNT[5:0]].CGY <= SAT_Q[13:12];
                  //SPR_CACHE[SPR_EVAL_CNT[5:0]].HF <= SAT_Q[11];
                  //SPR_CACHE[SPR_EVAL_CNT[5:0]].VF <= SAT_Q[15];
                  //if(SPR_EVAL_X[7:2] == 6'b000000) begin
                  //  SPR_CACHE[SPR_EVAL_CNT[5:0]].SPR0 <= 1'b1;
                  //end
                  //else begin
                  //  SPR_CACHE[SPR_EVAL_CNT[5:0]].SPR0 <= 1'b0;
                  //end
                  //if(RC_CNT == SPR_Y) begin
                  //  SPR_CACHE[SPR_EVAL_CNT[5:0]].TOP <= 1'b1;
                  //end
                  //else begin
                  //  SPR_CACHE[SPR_EVAL_CNT[5:0]].TOP <= 1'b0;
                  //end
                  //if(RC_CNT == (SPR_Y + SPR_H)) begin
                  //  SPR_CACHE[SPR_EVAL_CNT[5:0]].BOTTOM <= 1'b1;
                  //end
                  //else begin
                  //  SPR_CACHE[SPR_EVAL_CNT[5:0]].BOTTOM <= 1'b0;
                  //end
                  //SPR_EVAL_CNT <= SPR_EVAL_CNT + 1;
                  //if(SPR_EVAL_CNT == SPR_MAX) begin
                  //  SPR_EVAL_FULL <= 1'b1;
                  //end
                  Sprite_r spr_cache_rhs;
                  spr_cache_rhs.X = SPR_X;
                  spr_cache_rhs.Y = SPR_Y;
                  spr_cache_rhs.PC = SPR_PC;
                  spr_cache_rhs.CG = SPR_CG;
                  spr_cache_rhs.PAL = SAT_Q[3:0];
                  spr_cache_rhs.PRIO = SAT_Q[7];
                  spr_cache_rhs.CGX = SAT_Q[8];
                  spr_cache_rhs.CGY = SAT_Q[13:12];
                  spr_cache_rhs.HF = SAT_Q[11];
                  spr_cache_rhs.VF = SAT_Q[15];
                  spr_cache_rhs.SPR0 = SPR_EVAL_X[7:2] == 6'b000000;
                  spr_cache_rhs.TOP = RC_CNT == SPR_Y;
                  spr_cache_rhs.BOTTOM = RC_CNT == (SPR_Y + 10'(SPR_H));
                  SPR_CACHE[SPR_EVAL_CNT[5:0]] <= spr_cache_rhs;
                end
                else begin
                  if(`CR_IE_OC == 1'b1) begin
                    IRQ_OVF <= 1'b1;
                  end
                end
              end
            end
            endcase
            SPR_EVAL_X <= SPR_EVAL_X + 1;
            if(SPR_EVAL_X == 8'hFF) begin
              SPR_EVAL_DONE <= 1'b1;
            end
          end
        end
      end
      if(SPR_CE == 1'b1) begin
        if(SPR_FETCH == 1'b1) begin
          if(SPR_FETCH_DONE == 1'b0 && SPR_FIND == 1'b1) begin
            case(SLOT)
            SG0 : begin
              SPR_CH0 <= RAM_DI;
            end
            SG1 : begin
              SPR_CH1 <= RAM_DI;
            end
            SG2 : begin
              SPR_CH2 <= RAM_DI;
            end
            SG3 : begin
              //SPR_CH3 <= RAM_DI;
            end
            default : begin
            end
            endcase
            if((SM == 2'b01 && SPR.CG == 1'b0 && SLOT == SG1) || SLOT == SG3) begin
              SPR_FETCH_W <= 1'b1;
              if(SPR_FETCH_W == SPR.CGX) begin
                SPR_FETCH_W <= 1'b0;
                if(SPR_FETCH_CNT == (SPR_EVAL_CNT - 1)) begin
                  SPR_FETCH_DONE <= 1'b1;
                  SPR_FETCH_EN <= 1'b0;
                end
                else begin
                  SPR_FETCH_CNT <= SPR_FETCH_CNT + 1;
                end
              end
              if((SM == 2'b01 && SPR.PC[0] == 1'b1)) begin
                // when it's 4-color mode
                // then if bit 0 of SATB sprint pattern address = '1', then switch SG0/SG1 slot to SG2/SG3						
                SPR_TILE_P0 <= SPR_CH2;
                SPR_TILE_P1 <= RAM_DI;
                SPR_TILE_P2 <= {16{1'b0}};
                SPR_TILE_P3 <= {16{1'b0}};
              end
              else if(SM == 2'b01 && SPR.CG == 1'b0) begin
                SPR_TILE_P0 <= SPR_CH0;
                SPR_TILE_P1 <= RAM_DI;
                SPR_TILE_P2 <= {16{1'b0}};
                SPR_TILE_P3 <= {16{1'b0}};
              end
              else if(SM == 2'b01 && SPR.CG == 1'b1) begin
                SPR_TILE_P0 <= {16{1'b0}};
                SPR_TILE_P1 <= {16{1'b0}};
                SPR_TILE_P2 <= SPR_CH2;
                SPR_TILE_P3 <= RAM_DI;
              end
              else begin
                SPR_TILE_P0 <= SPR_CH0;
                SPR_TILE_P1 <= SPR_CH1;
                SPR_TILE_P2 <= SPR_CH2;
                SPR_TILE_P3 <= RAM_DI;
              end
              SPR_TILE_X <= (SPR.X) - 10'd32 + 10'({SPR_FETCH_W,4'b0000});
              SPR_TILE_HF <= SPR.HF;
              SPR_TILE_PAL <= SPR.PAL;
              SPR_TILE_PRIO <= SPR.PRIO;
              SPR_TILE_SPR0 <= SPR.SPR0;
              SPR_TILE_SAVE <= 1'b1;
              SPR_TILE_LEFT <=  ~SPR.CGX |  ~SPR_FETCH_W;
              SPR_TILE_RIGTH <=  ~SPR.CGX | SPR_FETCH_W;
              SPR_TILE_TOP <= SPR.TOP;
              SPR_TILE_BOTTOM <= SPR.BOTTOM;
            end
          end
        end
      end
      if(CS_N == 1'b0 && RD_N == 1'b0 && CPU_CE == 1'b1 && A[1] == 1'b0 && (BYTEWORD == 1'b0 || A[0] == 1'b0)) begin
        IRQ_OVF <= 1'b0;
      end
    end
  end

  always @(posedge CLK, posedge RST_N) begin : P2
    reg [3:0] COLOR;
    reg [9:0] SPR_LINE_X;
    reg [3:0] N;
    reg [3:0] SPR_TILE_PIX;

    if(RST_N == 1'b0) begin
      SPR_TILE_PIX = {4{1'b0}};
      SPR_LINE_WE <= {2{1'b0}};
      SPR_TILE_PIX_SET <= {560{1'b0}};
      SPR_TILE_SPR0_SET <= {560{1'b0}};
      SPR_OUT_X <= {10{1'b0}};
      SPR_LINE_CLR <= 1'b0;
      IRQ_COL <= 1'b0;
    end else begin
      SPR_LINE_WE <= {2{1'b0}};
      if(SPR_TILE_SAVE == 1'b1 || SPR_TILE_PIX != 0) begin
        for (int i=0; i <= 1; i = i + 1) begin
          N = SPR_TILE_PIX ^ ~{4{SPR_TILE_HF}};
          COLOR = {SPR_TILE_P3[N],SPR_TILE_P2[N],SPR_TILE_P1[N],SPR_TILE_P0[N]};
          SPR_LINE_X = SPR_TILE_X + 10'(SPR_TILE_PIX);
          if(SPR_LINE_X[9:8] != 2'b11 && COLOR != 4'b0000) begin
            if(SPR_TILE_PIX_SET[SPR_LINE_X] == 1'b0) begin
              SPR_LINE_D[SPR_LINE_X[0:0]] <= {SPR_TILE_PRIO,SPR_TILE_PAL,COLOR};
              SPR_LINE_ADDR[SPR_LINE_X[0:0]] <= SPR_LINE_X[9:1];
              SPR_LINE_WE[SPR_LINE_X[0:0]] <= 1'b1;
              SPR_TILE_PIX_SET[SPR_LINE_X] <= 1'b1;
              SPR_TILE_SPR0_SET[SPR_LINE_X] <= SPR_TILE_SPR0;
            end
            if(SPR_TILE_SPR0_SET[SPR_LINE_X] == 1'b1) begin
              if(`CR_IE_CC == 1'b1) begin
                IRQ_COL <= 1'b1;
              end
            end
          end
          if((SPR_TILE_PIX == 0 && SPR_TILE_LEFT == 1'b1) || (SPR_TILE_PIX == 15 && SPR_TILE_RIGTH == 1'b1) || SPR_TILE_TOP == 1'b1 || SPR_TILE_BOTTOM == 1'b1) begin
            SPR_TILE_FRAME[SPR_LINE_X] <= 1'b1;
          end
          SPR_TILE_PIX = SPR_TILE_PIX + 1;
        end
      end
      if(DCK_CE == 1'b1) begin
        if(TILE_CNT == HDS_END_POS && DOT_CNT == 7) begin
          SPR_OUT_X <= {10{1'b0}};
          SPR_LINE_CLR <= 1'b1;
        end
        else if((TILE_CNT == HDISP_END_POS && DOT_CNT == 7) || (DOT_CNT == 7 && TILE_CNT == 0 && DISP_BREAK_LATCH == 1'b1)) begin
          SPR_LINE_CLR <= 1'b0;
        end
        if(SPR_LINE_CLR == 1'b1) begin
          SPR_TILE_PIX_SET[SPR_OUT_X] <= 1'b0;
          SPR_TILE_SPR0_SET[SPR_OUT_X] <= 1'b0;
          SPR_TILE_FRAME[SPR_OUT_X] <= 1'b0;
          SPR_OUT_X <= SPR_OUT_X + 1;
        end
      end
      if(CS_N == 1'b0 && RD_N == 1'b0 && CPU_CE == 1'b1 && A[1] == 1'b0 && (BYTEWORD == 1'b0 || A[0] == 1'b0)) begin
        IRQ_COL <= 1'b0;
      end
    end
  end

  
  dpram #(9,9) SPR_LINE_BUF0
  (
   .clock(CLK),

   .address_a(SPR_LINE_ADDR[0]),
   .data_a(SPR_LINE_D[0]),
   .wren_a(SPR_LINE_WE[0]),

   .address_b(SPR_OUT_X[9:1]),
   .wren_b(SPR_LINE_CLR & DCK_CE & ~SPR_OUT_X[0]),
   .q_b(SPR_LINE_Q[0])
   );

  dpram #(9,9) SPR_LINE_BUF1
  (
   .clock(CLK),

   .address_a(SPR_LINE_ADDR[1]),
   .data_a(SPR_LINE_D[1]),
   .wren_a(SPR_LINE_WE[1]),

   .address_b(SPR_OUT_X[9:1]),
   .wren_b(SPR_LINE_CLR & DCK_CE & SPR_OUT_X[0]),
   .q_b(SPR_LINE_Q[1])
   );

  always @(posedge CLK, posedge RST_N) begin : P1
    reg [3:0] PX;
    reg [2:0] GX, GY;

    if(RST_N == 1'b0) begin
      BG_OUT_X <= {10{1'b0}};
      for (int i = 0; i < 8; i++) begin
        BG_COLOR[i] <= {8{1'b0}};
        SPR_COLOR[i] <= {9{1'b0}};
      end
      DISP <= {8{1'b0}};
      BORD <= {8{1'b1}};
      GRID_BG <= {8{1'b0}};
      GRID_SP <= {8{1'b0}};
    end else begin
      if(DCK_CE == 1'b1) begin
        BG_COLOR[7] <= {8{1'b0}};
        SPR_COLOR[7] <= {9{1'b0}};
        DISP[7] <= 1'b0;
        BORD[7] <= 1'b1;
        GRID_BG[7] <= 1'b0;
        GRID_SP[7] <= 1'b0;
        if(HSYNC_F == 1'b1) begin
          BG_OUT_X <= {10{1'b0}};
        end
        else if(BG_OUT == 1'b1 && VDISP == 1'b1) begin
          PX =  ~(({1'b0,BG_OUT_X[2:0]}) + ({1'b0,OFS_X[2:0]}));
          BG_COLOR[7] <= {BG_SRC[PX[3:3]],BG_SR3[PX[3:0]],BG_SR2[PX[3:0]],BG_SR1[PX[3:0]],BG_SR0[PX[3:0]]};
          SPR_COLOR[7] <= SPR_LINE_Q[SPR_OUT_X[0:0]];
          DISP[7] <=  ~BURST;
          BORD[7] <= 1'b0;
          GX = BG_OUT_X[2:0] + (OFS_X[2:0]);
          GY = OFS_Y[2:0];
          if(GX == 7 || GY == 7) begin
            GRID_BG[7] <= 1'b1;
          end
          if(SPR_TILE_FRAME[BG_OUT_X] == 1'b1) begin
            GRID_SP[7] <= 1'b1;
          end
          BG_OUT_X <= BG_OUT_X + 1;
        end
        for (int i=0; i <= 6; i = i + 1) begin
          BG_COLOR[i] <= BG_COLOR[i + 1];
          SPR_COLOR[i] <= SPR_COLOR[i + 1];
          DISP[i] <= DISP[i + 1];
          BORD[i] <= BORD[i + 1];
          GRID_BG[i] <= GRID_BG[i + 1];
          GRID_SP[i] <= GRID_SP[i + 1];
        end
      end
    end
  end

  assign BORDER = BORD[0];
  assign GRID = {GRID_SP[0],GRID_BG[0]};
  always @(BG_OUT, DISP, BG_COLOR[0], SPR_COLOR[0], BB, SB, BG_EN, SPR_EN) begin
    if(DISP[0] == 1'b0) begin
      VD <= {1'b1,8'h00};
    end
    else if(SPR_COLOR[0][3:0] != 4'b0000 && SPR_COLOR[0][8] == 1'b1 && SB == 1'b1 && SPR_EN == 1'b1) begin
      VD <= {1'b1,SPR_COLOR[0][7:0]};
    end
    else if(BG_COLOR[0][3:0] != 4'b0000 && BB == 1'b1 && BG_EN == 1'b1) begin
      VD <= {1'b0,BG_COLOR[0]};
    end
    else if(SPR_COLOR[0][3:0] != 4'b0000 && SPR_COLOR[0][8] == 1'b0 && SB == 1'b1 && SPR_EN == 1'b1) begin
      VD <= {1'b1,SPR_COLOR[0][7:0]};
    end
    else begin
      VD <= {1'b0,8'h00};
    end
  end

  always @(posedge CLK, posedge RST_N) begin
    if(RST_N == 1'b0) begin
      AR <= {5{1'b0}};
      for (int i = 0; i < 32; i++)
        REGS[i] <= {16{1'b0}};
      CPURD_PEND <= 1'b0;
      CPUWR_PEND <= 1'b0;
      CPURD_PEND2 <= 1'b0;
      CPUWR_PEND2 <= 1'b0;
      DMA_PEND <= 1'b0;
      DMAS_PEND <= 1'b0;
      DMAS_SAT_ADDR <= {8{1'b0}};
      DMAS_VRAM_ADDR <= {16{1'b0}};
      CPU_BUSY <= 1'b0;
      IRQ_DMA <= 1'b0;
      IRQ_RCR <= 1'b0;
      IRQ_DMAS <= 1'b0;
      IRQ_VBL <= 1'b0;
      IO_BYRL_SET <= 1'b0;
      IO_BYRH_SET <= 1'b0;
      CPURD_EXEC <= 1'b0;
      CPUWR_EXEC <= 1'b0;
      DMA_EXEC <= 1'b0;
      DMAS_EXEC <= 1'b0;
      DMA_WR <= 1'b0;
      BYRL_SET <= 1'b0;
      BYRH_SET <= 1'b0;
      VDISP_OLD <= 1'b0;
    end else begin
      IO_BYRL_WR <= 1'b0;
      IO_BYRH_WR <= 1'b0;
      if(CS_N == 1'b0 && WR_N == 1'b0 && CPU_CE == 1'b1) begin
        case(A[1])
        1'b0 : begin
          if((BYTEWORD == 1'b0 || A[0] == 1'b0)) begin
            // if 16-bit access or 8-bit access to "00"
            AR <= DI[4:0];
          end
        end
        1'b1 : begin
          case(AR)
          5'b00000 : begin
            if(BYTEWORD == 1'b0) begin
              REGS[0][15:0] <= DI[15:0];
            end
            else if(A[0] == 1'b0) begin
              REGS[0][7:0] <= DI[7:0];
            end
            else begin
              REGS[0][15:8] <= DI[7:0];
            end
          end
          5'b00001 : begin
            if(CPU_BUSY == 1'b0) begin
              if(BYTEWORD == 1'b0) begin
                REGS[1][15:0] <= DI[15:0];
                CPURD_PEND <= 1'b1;
                CPU_BUSY <= 1'b1;
              end
              else if(A[0] == 1'b0) begin
                REGS[1][7:0] <= DI[7:0];
              end
              else begin
                REGS[1][15:8] <= DI[7:0];
                CPURD_PEND <= 1'b1;
                CPU_BUSY <= 1'b1;
              end
            end
          end
          5'b00010 : begin
            if(CPU_BUSY == 1'b0) begin
              if(BYTEWORD == 1'b0) begin
                REGS[2][15:0] <= DI[15:0];
                CPUWR_PEND <= 1'b1;
                CPU_BUSY <= 1'b1;
              end
              else if(A[0] == 1'b0) begin
                REGS[2][7:0] <= DI[7:0];
              end
              else begin
                REGS[2][15:8] <= DI[7:0];
                CPUWR_PEND <= 1'b1;
                CPU_BUSY <= 1'b1;
              end
            end
          end
          5'b01000 : begin
            if(BYTEWORD == 1'b0) begin
              IO_BYRL_WR <= 1'b1;
              IO_BYRH_WR <= 1'b1;
            end
            else if(A[0] == 1'b0) begin
              IO_BYRL_WR <= 1'b1;
            end
            else begin
              IO_BYRH_WR <= 1'b1;
            end
          end
          5'b10010 : begin
            if((BYTEWORD == 1'b0 || A[0] == 1'b1)) begin
              // if 16-bit access or 8-bit access to "11"
              DMA_PEND <= 1'b1;
            end
          end
          5'b10011 : begin
            if((BYTEWORD == 1'b0 || A[0] == 1'b1)) begin
              // if 16-bit access or 8-bit access to "11"
              DMAS_PEND <= 1'b1;
            end
          end
          default : begin
          end
          endcase
          if(AR >= 5'b00011) begin
            if(BYTEWORD == 1'b0) begin
              REGS[AR][15:0] <= DI[15:0];
            end
            else if(A[0] == 1'b0) begin
              REGS[AR][7:0] <= DI[7:0];
            end
            else begin
              REGS[AR][15:8] <= DI[7:0];
            end
          end
        end
        default : begin
        end
        endcase
      end
      else if(CS_N == 1'b0 && RD_N == 1'b0 && CPU_CE == 1'b1) begin
        case(A[1])
        1'b0 : begin
          if((BYTEWORD == 1'b0 || A[0] == 1'b0)) begin
            // if 16-bit access or 8-bit access to "00"
            if(SR_LATCH[5] == 1'b1) begin
              IRQ_VBL <= 1'b0;
            end
            if(SR_LATCH[4] == 1'b1) begin
              IRQ_DMA <= 1'b0;
            end
            if(SR_LATCH[3] == 1'b1) begin
              IRQ_DMAS <= 1'b0;
            end
            if(SR_LATCH[2] == 1'b1) begin
              IRQ_RCR <= 1'b0;
            end
          end
        end
        1'b1 : begin
          if((BYTEWORD == 1'b0 || A[0] == 1'b1)) begin
            // if 16-bit access or 8-bit access to "11"
            if(AR == {1'b0,4'h2}) begin
              CPURD_PEND <= 1'b1;
              CPU_BUSY <= 1'b1;
            end
          end
        end
        default : begin
        end
        endcase
      end
      if(IO_BYRL_WR == 1'b1) begin
        IO_BYRL_SET <= 1'b1;
      end
      if(IO_BYRH_WR == 1'b1) begin
        IO_BYRH_SET <= 1'b1;
      end
      if(DCK_CE == 1'b1) begin
        if(DOT_CNT[0] == 1'b1) begin
          if(CPUWR_PEND == 1'b1) begin
            CPUWR_PEND <= 1'b0;
            CPUWR_PEND2 <= 1'b1;
          end
          else if(CPUWR_PEND2 == 1'b1) begin
            CPUWR_PEND2 <= 1'b0;
            CPU_VRAM_ADDR <= `MAWR;
            CPU_VRAM_DATA <= `VWR;
            case(`CR_IW)
            2'b00 : begin
              `MAWR <= (`MAWR) + 1;
            end
            2'b01 : begin
              `MAWR <= (`MAWR) + 32;
            end
            2'b10 : begin
              `MAWR <= (`MAWR) + 64;
            end
            default : begin
              `MAWR <= (`MAWR) + 128;
            end
            endcase
            CPUWR_EXEC <= 1'b1;
          end
          if(CPURD_PEND == 1'b1) begin
            CPURD_PEND <= 1'b0;
            CPURD_PEND2 <= 1'b1;
          end
          else if(CPURD_PEND2 == 1'b1) begin
            CPURD_PEND2 <= 1'b0;
            CPU_VRAM_ADDR <= `MARR;
            case(`CR_IW)
            2'b00 : begin
              `MARR <= (`MARR) + 1;
            end
            2'b01 : begin
              `MARR <= (`MARR) + 32;
            end
            2'b10 : begin
              `MARR <= (`MARR) + 64;
            end
            default : begin
              `MARR <= (`MARR) + 128;
            end
            endcase
            CPURD_EXEC <= 1'b1;
          end
        end
        if(DMA_PEND == 1'b1 && (BURST == 1'b1 || VDISP == 1'b0)) begin
          DMA_PEND <= 1'b0;
          DMA_EXEC <= 1'b1;
        end
        else if(DMA_EXEC == 1'b1 && BURST == 1'b0 && VDISP == 1'b1) begin
          DMA_EXEC <= 1'b0;
        end
        if(SLOT == CPU) begin
          if(DMAS_EXEC == 1'b1) begin
            DMAS_SAT_ADDR <= (DMAS_SAT_ADDR) + 1;
            DMAS_VRAM_ADDR <= (DMAS_VRAM_ADDR) + 1;
            if(DMAS_SAT_ADDR == 8'hFF) begin
              DMAS_EXEC <= 1'b0;
              if(`DCR_DSC == 1'b1) begin
                IRQ_DMAS <= 1'b1;
              end
            end
          end
          else if(DMA_EXEC == 1'b1) begin
            if(DMA_WR == 1'b0) begin
              DMA_BUF <= RAM_DI;
              DMA_WR <= 1'b1;
            end
            else begin
              if(`DCR_SID == 1'b0) begin
                `SOUR <= (`SOUR) + 1;
              end
              else begin
                `SOUR <= (`SOUR) - 1;
              end
              if(`DCR_DID == 1'b0) begin
                `DESR <= (`DESR) + 1;
              end
              else begin
                `DESR <= (`DESR) - 1;
              end
              `LENR <= (`LENR) - 1;
              if(`LENR == 16'h0000) begin
                DMA_EXEC <= 1'b0;
                if(`DCR_DVC == 1'b1) begin
                  IRQ_DMA <= 1'b1;
                end
              end
              DMA_WR <= 1'b0;
            end
          end
          else if(CPUWR_EXEC == 1'b1) begin
            CPUWR_EXEC <= 1'b0;
            CPU_BUSY_CLEAR <= 1'b1;
          end
          else if(CPURD_EXEC == 1'b1) begin
            CPURD_EXEC <= 1'b0;
            VRR <= RAM_DI;
            CPU_BUSY_CLEAR <= 1'b1;
          end
        end
        if(CPU_BUSY_CLEAR == 1'b1) begin
          CPU_BUSY_CLEAR <= 1'b0;
          CPU_BUSY <= 1'b0;
        end
        if(TILE_CNT == (HDS_END_POS - 2) && DOT_CNT == 7) begin
          VDISP_OLD <= VDISP;
          if(VDISP == 1'b0 && VDISP_OLD == 1'b1) begin
            if(`CR_IE_VC == 1'b1) begin
              IRQ_VBL <= 1'b1;
            end
            if(`DCR_DSR == 1'b1 || DMAS_PEND == 1'b1) begin
              DMAS_PEND <= 1'b0;
              DMAS_VRAM_ADDR <= `DVSSR;
              DMAS_SAT_ADDR <= {8{1'b0}};
              DMAS_EXEC <= 1'b1;
            end
          end
        end
        if(TILE_CNT == HDISP_END_POS && DOT_CNT == 1 && RC_CNT == (`RCR) && `CR_IE_RC == 1'b1) begin
          IRQ_RCR <= 1'b1;
        end
        if(TILE_CNT == (HDS_END_POS - 3) && DOT_CNT == 7) begin
          BXR_SET <= 1'b1;
        end
        else begin
          BXR_SET <= 1'b0;
        end
        if(TILE_CNT == (HDS_END_POS - 3) && DOT_CNT == 7) begin
          BYRL_SET <= 1'b0;
          BYRH_SET <= 1'b0;
        end
      end
      if(DCK_CE_F == 1'b1) begin
        //sync BYRx latches to dot clock
        if(IO_BYRL_SET == 1'b1) begin
          IO_BYRL_SET <= 1'b0;
          BYRL_SET <= 1'b1;
        end
        if(IO_BYRH_SET == 1'b1) begin
          IO_BYRH_SET <= 1'b0;
          BYRH_SET <= 1'b1;
        end
      end
    end
  end

  always @(posedge CLK, posedge RST_N) begin
    if(RST_N == 1'b0) begin
      SR_LATCH <= {7{1'b0}};
      RD_N_OLD <= 1'b1;
    end else begin
      RD_N_OLD <= RD_N;
      if(RD_N == 1'b0 && RD_N_OLD == 1'b1) begin
        SR_LATCH <= {CPU_BUSY,IRQ_VBL,IRQ_DMA,IRQ_DMAS,IRQ_RCR,IRQ_OVF,IRQ_COL};
      end
    end
  end

  always @(A, BYTEWORD, SR_LATCH, VRR) begin
    DO <= 16'h0000;
    case(A[1])
    1'b0 : begin
      DO <= {9'b000000000,SR_LATCH};
    end
    1'b1 : begin
      DO <= VRR[15:0];
      if((BYTEWORD == 1'b1 && A[0] == 1'b1)) begin
        DO <= {8'b00000000,VRR[15:8]};
      end
    end
    default : begin
    end
    endcase
  end

  assign IRQ_N =  ~(IRQ_COL | IRQ_OVF | IRQ_RCR | IRQ_DMAS | IRQ_DMA | IRQ_VBL);
  assign BUSY_N = CPU_BUSY == 1'b1 && CS_N == 1'b0 && (RD_N == 1'b0 || WR_N == 1'b0) && A[1] == 1'b1 && (AR == 5'b00010 || AR == 5'b00001 || AR == 5'b00000) ? 1'b0 : 1'b1;
  always @(SLOT, BG_RAM_ADDR, SPR_RAM_ADDR, DCK_CE, DMAS_VRAM_ADDR, DMAS_EXEC, DMA_EXEC, DMA_WR, `SOUR, `DESR, DMA_BUF, CPUWR_EXEC, CPU_VRAM_ADDR, CPU_VRAM_DATA) begin
    RAM_DO <= 16'h0000;
    RAM_WE <= 1'b0;
    case(SLOT)
    BAT,CG0,CG1 : begin
      RAM_A <= BG_RAM_ADDR;
    end
    SG0,SG1,SG2,SG3 : begin
      RAM_A <= SPR_RAM_ADDR;
    end
    CPU : begin
      if(DMAS_EXEC == 1'b1) begin
        RAM_A <= DMAS_VRAM_ADDR;
      end
      else if(DMA_EXEC == 1'b1) begin
        if(DMA_WR == 1'b0) begin
          RAM_A <= `SOUR;
        end
        else begin
          RAM_A <= `DESR;
          RAM_DO <= DMA_BUF;
          RAM_WE <= DCK_CE;
        end
      end
      else if(CPUWR_EXEC == 1'b1) begin
        RAM_A <= CPU_VRAM_ADDR;
        RAM_DO <= CPU_VRAM_DATA;
        RAM_WE <= DCK_CE;
      end
      else begin
        RAM_A <= CPU_VRAM_ADDR;
      end
    end
    default : begin
      RAM_A <= 16'h0000;
    end
    endcase
  end

  assign IW_DBG = `CR_IW;
  assign VM_DBG = VM;
  assign CM_DBG = CM;
  assign SCREEN_DBG = SCREEN;
  assign SOUR_DBG = `SOUR;
  assign DESR_DBG = `DESR;
  assign LENR_DBG = `LENR;
  assign SPR_X_DBG = SPR.X;
  assign SPR_Y_DBG = SPR.Y;
  assign SPR_PC_DBG = SPR.PC;
  assign SPR_CG_DBG = SPR.CG;
  assign SPR_PAL_DBG = SPR.PAL;
  assign SPR_PRIO_DBG = SPR.PRIO;
  assign SPR_CGX_DBG = SPR.CGX;
  assign SPR_CGY_DBG = SPR.CGY;
  assign SPR_HF_DBG = SPR.HF;
  assign SPR_VF_DBG = SPR.VF;
  assign HSW_END_POS_DBG = HSW_END_POS;
  assign HDS_END_POS_DBG = HDS_END_POS;
  assign HDISP_END_POS_DBG = HDISP_END_POS;
  assign HSW_DBG = HSW;
  assign HDS_DBG = HDS;
  assign HDE_DBG = HDE;
  assign VDS_END_POS_DBG = VDS_END_POS;
  assign VDISP_END_POS_DBG = VDISP_END_POS;
  assign VDE_END_POS_DBG = VDE_END_POS;

endmodule
