`timescale 1ns/100ps
module FC(clk, rst, cmd, done, M_RW, M_A, M_D, F_IO, F_CLE, F_ALE, F_REN, F_WEN, F_RB);

  input clk;
  input rst;
  input [32:0] cmd;
  output done;
  output M_RW;
  output [6:0] M_A;
  inout  [7:0] M_D;
  inout  [7:0] F_IO;
  output F_CLE;
  output F_ALE;
  output F_REN;
  output F_WEN;
  input  F_RB;

  reg [6:0] M_A;
  reg done, M_RW, F_CLE, F_ALE, F_REN, F_WEN;
  reg [7:0] M_D_reg, F_IO_reg;
  reg [3:0] cur, next;

  assign F_IO = (1) ? F_IO_reg : 8'hzz;
  assign M_D = (1) ? M_D_reg : 8'hzz;

  always @(posedge clk or posedge rst) begin
    if(rst) cur <= 0;
    else cur <= next;
  end

  always @(*) begin
    next = cur;
    case (cur)
      0: begin
        if(F_WEN) next = 1;
      end 
      1: begin
        next = (cmd[32]) ? 2 : 7;
      end
      default: begin
      end
    endcase
  end

  always @(posedge clk) 
  begin

    if(rst) begin
      F_REN <= 1;
      F_WEN <= 0;
    end
    else begin
      F_WEN <= ~F_WEN;
    end

    case(cur)
      0: begin
        if(rst) begin
          done <= 0;
          M_RW <= 1;
          M_D_reg <= 8'hzz;
          F_CLE <= 1;
          F_ALE <= 0;
          F_IO_reg <= 8'hff;
        end 
        else begin
          done <= ~done;
        end
      end
      1: begin
        F_IO_reg <= 8'hzz;
        if(cmd[32]) begin // Read Flash, Write Memory

        end
        else begin // Read Memory, Write Flash
          M_RW <= 1;
          M_A <= cmd[13:7];
          M_D_reg <= 8'hzz;
        end
      end
      2: begin

      end
      default: begin

      end
      7: begin

      end
    endcase

  end

endmodule
