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

  reg done, M_RW, F_CLE, F_ALE, F_REN, F_WEN;
  reg [6:0] M_A;
  reg [7:0] M_D_reg, F_IO_reg;
  reg [3:0] state;
  reg [7:0] cnt;

  assign F_IO = F_IO_reg;
  assign M_D = M_D_reg;

  always @(posedge clk or posedge rst)
  begin
    if(rst)    
    begin
      done <= 0;
      F_CLE <= 1;
      F_ALE <= 0;
      F_REN <= 1;
      F_WEN <= 0;
      F_IO_reg <= 8'hff;

      M_RW <= 1;
      M_A <= 7'd0;
      M_D_reg <= 8'hzz;

      cnt <= 0;
      state <= 0;
    end
    else 
    begin
      if(state < 5) begin
        F_WEN <= ~F_WEN;
        F_REN <= 1;
      end
      else begin
        F_WEN <= 1;
        F_REN <= ~F_REN;
      end

      case (state)
        0: begin
          if(cnt == 1) begin
            F_IO_reg <= 8'hzz;
            done <= 0;
            state <= 1;
          end
          else begin
            done <= 1;
            cnt <= cnt + 1;
            state <= state;
          end
        end
        1: begin
          done <= 0;
          if(cmd[32]) begin // Read Flash, Write Memory
            F_CLE <= 1;
            F_ALE <= 0;
            // F_WEN <= 1;
            // F_REN <= 1;
            F_IO_reg <= {7'd0, cmd[22]}; // Flash Address A8
            state <= 2;
          end
          else begin // Write Flash, Read Memory
            F_CLE <= 0;
            F_ALE <= 0;
            M_RW <= 1;
            M_A <= cmd[13:7];
            M_D_reg <= 8'hzz;
            state <= 7;
          end
        end
        2: begin
          F_IO_reg <= cmd[21:14]; // Flash Address A0 ~ A7
          state <= 3;
        end
        3: begin
          F_CLE <= 0;
          F_IO_reg <= cmd[30:23]; // Flash Address A9 ~ A16
          state <= 4;
        end
        4: begin
          F_IO_reg <= {7'd0, cmd[31]};
          state <= 5;
        end
        5: begin
          F_ALE <= 0;
          if(F_REN) begin
            
          end
        end
        default: begin

        end
      endcase
    end
  end

endmodule
