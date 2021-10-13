
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
        /* LBP operation */
        if(data_buf[i] > data_buf[4]) begin
          case (i)
            0: lbp_data <= lbp_data + 1;
            1: lbp_data <= lbp_data + 2;
            2: lbp_data <= lbp_data + 4;
            3: lbp_data <= lbp_data + 8;
            5: lbp_data <= lbp_data + 16;
            6: lbp_data <= lbp_data + 32;
            7: lbp_data <= lbp_data + 64;
            8: lbp_data <= lbp_data + 128;
            default: 
          endcase
        end
        else begin
          lbp_data <= lbp_data;
        end

        if(i == 3) begin
          i <= 5;
        end
        else begin
          i <= i + 1;
        end

        if(i == 8) begin
          i <= 2; 
          lbp_valid <= 1;
          lbp_addr <= addr;
          state <= 3;
        end
        else begin
          state <= 2;
        end
      end
      3: begin
        lbp_valid <= 0;
        lbp_data <= 8'd0;
        if(row == 126 && col == 126) begin
          finish <= 1;
        end
        else begin
          if(col == 126) begin
            col <= 1;
            row <= row + 1;
            dr <= -1;
            dc <= -1;
            state <= 0;
          end
          else begin
            col <= col + 1;
            /* only need to update data_buf[2, 5, 8] */
            dr <= -1;
            dc <= 1;
            data_buf[0] <= data_buf[1];
            data_buf[3] <= data_buf[4];
            data_buf[6] <= data_buf[7];
            data_buf[1] <= data_buf[2];
            data_buf[4] <= data_buf[5];
            data_buf[7] <= data_buf[8];
            state <= 4;
          end
        end
      end
      4: begin
        gray_req <= 1;
        gray_addr <= addr;
        dr <= dr + 1;
        state <= 5;
      end 
      5: begin
        gray_addr <= addr;
        data_buf[i] <= gray_data;
        i <= i + 3;
        if(dr == 1) begin
          dr <= 0;
          dc <= 0;
          state <= 2;
        end
        else begin
          dr <= dr + 1;
          state <= 5;
        end
      end
      default: begin
        
      end 
    endcase
  end
end

//====================================================================
endmodule
