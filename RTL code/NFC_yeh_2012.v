`timescale 1ns/100ps
module NFC(clk, rst, done, F_IO_A, F_CLE_A, F_ALE_A, F_REN_A, F_WEN_A, F_RB_A, F_IO_B, F_CLE_B, F_ALE_B, F_REN_B, F_WEN_B, F_RB_B);

input        clk;
input        rst;
output       done;
inout  [7:0] F_IO_A;
output       F_CLE_A;
output       F_ALE_A;
output       F_REN_A;
output       F_WEN_A;
input        F_RB_A;
inout  [7:0] F_IO_B;
output       F_CLE_B;
output       F_ALE_B;
output       F_REN_B;
output       F_WEN_B;
input        F_RB_B;

reg F_CLE_A, F_ALE_A, F_REN_A, F_WEN_A, done;
reg F_CLE_B, F_ALE_B, F_REN_B, F_WEN_B;

reg [1:0] state;
reg [7:0] F_IO_A_reg, F_IO_B_reg;
reg [6:0] cnt;

assign F_IO_A = (state < 2'd2) ? F_IO_A_reg : 8'hzz;
assign F_IO_B = F_IO_B_reg;

always @(posedge clk or posedge rst) begin
    if(rst) 
    begin
        done <= 0;
        F_CLE_A <= 1;
        F_ALE_A <= 0;
        F_REN_A <= 1;
        F_WEN_A <= 0;

        F_CLE_B <= 1;
        F_ALE_B <= 0;
        F_REN_B <= 1;
        F_WEN_B <= 0;

        state <= 2'd0;
        F_IO_A_reg <= 8'hFF;
        F_IO_B_reg <= 8'hFF;
        cnt <= 7'd0;
    end
    else 
    begin
        if(state == 2'd2) begin
            F_REN_A <= ~F_REN_A;
            F_WEN_A <= 1;
        end
        else begin
            F_WEN_A <= ~F_WEN_A;
            F_REN_A <= 1;
        end

        F_WEN_B <= (cnt == 7'd8 || cnt >= 7'd77) ? 1 : ~F_WEN_B;
        F_REN_B <= 1;

        if(F_RB_A && F_RB_B)
        begin
            F_IO_A_reg <= 8'h00;
            F_ALE_A <= (cnt >= 7'd2 && cnt < 7'd8) ? 1 : 0;
            F_CLE_A <= (cnt < 7'd2) ? 1 : 0;

            F_IO_B_reg <= (state < 2'd2) ? ((cnt >= 7'd0 && cnt < 7'd2) ? 8'h80 : 8'h00) : ((cnt < 7'd76) ? F_IO_A : 8'h10);
            F_ALE_B <= (cnt >= 7'd2 && cnt < 7'd8) ? 1 : 0;
            F_CLE_B <= (cnt < 7'd2 || (cnt >= 7'd76 && cnt < 7'd78)) ? 1 : 0;

            cnt <= cnt + 9'd1;
            state <= (cnt < 8) ? 2'd1 : 2'd2;
            done <= (cnt < 7'd77) ? 0 : 1;
        end
        else
        begin
            state <= state;
        end
    end
end
  
endmodule
