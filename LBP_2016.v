
`timescale 1ns/10ps
module LBP ( clk, reset, gray_addr, gray_req, gray_ready, gray_data, lbp_addr, lbp_valid, lbp_data, finish);
input   	clk;
input   	reset;
output  [13:0] 	gray_addr;
output         	gray_req;
input   	gray_ready;
input   [7:0] 	gray_data;
output  [13:0] 	lbp_addr;
output  	lbp_valid;
output  [7:0] 	lbp_data;
output  	finish;
//====================================================================
reg  [13:0] 	gray_addr;
reg         	gray_req;
reg [13:0] lbp_addr;
reg lbp_valid;
reg [7:0] lbp_data;
reg finish;

reg [3:0] state;
reg signed [8:0] data_buf [8:0];
reg signed [7:0] row, col;  
reg signed [2:0] dr, dc; // offset for row and col
reg [3:0] i; // index for data_buf[]
wire [13:0] addr;
assign addr = ((row + dr) <<< 7) + (col + dc);

reg sig0, sig1, sig2, sig3, sig5, sig6, sig7, sig8; 

always @(posedge clk or posedge reset) begin
  if(reset) begin
    gray_addr <= 14'd0;
    gray_req <= 1'd0;
    lbp_addr <= 14'd0;
    lbp_valid <= 1'd0;
    lbp_data <= 8'd0;
    finish <= 1'd0;
    /*****************/
    state <= 0;
    row <= 7'd1;
    col <= 7'd1;
    dr <= -1;
    dc <= -1;
    i <= 0;
  end
  else begin
    case (state)
      0: begin
        if(gray_ready) begin
          gray_req <= 1;
          gray_addr <= addr;
          dc <= dc + 1;
          state <= 1;
        end
        else begin
          state <= 0;
        end 
      end
      1: begin
        data_buf[i] <= gray_data;
        i <= i + 1;
        gray_addr <= addr;
        if(dr == 1 && dc == 1) begin
          dr <= 0;
          dc <= 0;
          i <= 0;
          state <= 2;
        end
        else begin
          if(dc == 1) begin
            dc <= -1;
            dr <= dr + 1;
          end
          else begin
            dc <= dc + 1;
          end
          state <= 1;
        end
      end
      2: begin
        gray_req <= 0;
        data_buf[8] <= gray_data;
        i <= 2; 
        state <= 3;
        /* LBP operation */
        sig0 <= (data_buf[0] >= data_buf[4]) ? 1 : 0;
        sig1 <= (data_buf[1] >= data_buf[4]) ? 1 : 0;
        sig2 <= (data_buf[2] >= data_buf[4]) ? 1 : 0;
        sig3 <= (data_buf[3] >= data_buf[4]) ? 1 : 0;
        sig5 <= (data_buf[5] >= data_buf[4]) ? 1 : 0;
        sig6 <= (data_buf[6] >= data_buf[4]) ? 1 : 0;
        sig7 <= (data_buf[7] >= data_buf[4]) ? 1 : 0;
        sig8 <= (gray_data >= data_buf[4]) ? 1 : 0;
      end
      3: begin
        lbp_valid <= 1;
        lbp_addr <= addr;
        lbp_data <= 1 * sig0 + 2 * sig1 + 4 * sig2 + 8 * sig3 + 16 * sig5 + 32 * sig6 + 64 * sig7 + 128 * sig8;
        /* update row and col*/
        if(row == 126 && col == 126) begin
          finish <= 1;
        end
        else begin
          /* at the boundary, request 9 pixels is needed */
          if(col == 126) begin
            col <= 1;
            row <= row + 1;
            dr <= -1;
            dc <= -1;
            i <= 0;
            state <= 0;
          end
          else begin
            col <= col + 1;
            /* only need to update data_buf[2, 5, 8] */
            dr <= -1;
            dc <= 1;
            state <= 4;
          end
        end
      end
      4: begin
        gray_req <= 1;
        gray_addr <= addr;
        dr <= dr + 1;
        data_buf[0] <= data_buf[1];
        data_buf[3] <= data_buf[4];
        data_buf[6] <= data_buf[7];
        data_buf[1] <= data_buf[2];
        data_buf[4] <= data_buf[5];
        data_buf[7] <= data_buf[8];
        state <= 5;
      end 
      default: begin
        gray_addr <= addr;
        data_buf[i] <= gray_data;
        i <= i + 3;
        if(dr == 1) begin
          dr <= 0;
          dc <= 0;
          i <= 0;
          state <= 2;
        end
        else begin
          dr <= dr + 1;
          state <= 5;
        end
      end 
    endcase
  end
end

//====================================================================
endmodule
