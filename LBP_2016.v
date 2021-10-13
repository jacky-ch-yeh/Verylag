
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

reg [7:0] data[8:0];
reg [3:0] count;
reg [6:0] row, col; //for 3x3  
reg [7:0] LBP_reg;  //LBP operation result

reg [1:0] cur_state, next_state;
localparam LOAD = 0;
localparam LBP_OPERATION = 1;
localparam WRITE = 2;

always @(posedge clk or posedge reset) begin
  if(reset)
    cur_state <= LOAD;
  else
    cur_state <= next_state;
end

always @(*) begin
  case(cur_state)
    LOAD: begin
      if(count == 4'd9) 
        next_state <= LBP_OPERATION;
      else
        next_state <= LOAD;
    end
    LBP_OPERATION: begin
      if(count == 4'd9)
        next_state <= WRITE;
      else
        next_state <= LBP_OPERATION;
    end
    default: begin  //WRITE
      if(count == 4'd1)
        next_state <= LOAD;
      else
        next_state <= WRITE;
    end
  endcase
end

always @(posedge clk or posedge reset) 
begin
  if(reset) begin
    gray_req <= 1'd0;
    finish <= 1'd0;
    row <= 7'd0;
    col <= 7'd0;
    count <= 4'd0;
    lbp_data <= 8'd0;
    lbp_valid <= 1'd0;
    lbp_addr <= 14'd0;
    LBP_reg <= 8'd0;
  end
  else 
  begin
    case(cur_state)
      LOAD: 
      begin
          if(gray_ready == 1'd1) 
          begin
            if(count == 4'd0) begin
              count <= 4'd1;
              gray_addr <= ({7'd0,row} << 7) + {7'd0,col} + {10'd0,count};
              gray_req <= 1'd1;
            end
            else if(count >= 4'd1 && count <= 4'd2) begin 
              count <= count + 4'd1;
              gray_addr <= gray_addr + 14'd1;
              data[count-1] <= gray_data;
            end
            else if(count >= 4'd3 && count <= 4'd5) begin
              count <= count + 4'd1;
              gray_addr <= ({7'd0,row} << 7) + {7'd0,col} + {10'd0,count - 3} + 14'd128;
              data[count-1] <= gray_data;
            end
            else if(count >= 4'd6 && count <= 4'd8) begin
              count <= count + 4'd1;
              gray_addr <= ({7'd0,row} << 7) + {7'd0,col} + {10'd0,count - 6} + 14'd256;
              data[count-1] <= gray_data;
            end
            else begin  //count == 9
              count <= 4'd0;
              data[count-1] <= gray_data;
              gray_req <= 1'd0;
            end
          end
          else begin end
      end
      LBP_OPERATION: begin
        if(count == 4'd9) begin
          count <= 4'd0;
        end
        else if(count == 4'd4) begin
          count <= count + 4'd1;
        end
        else begin
          count <= count + 4'd1;
          if(count <= 3)
            LBP_reg <= LBP_reg + ((data[count] >= data[4]) ? (9'd1 << count) : 0);
          else
            LBP_reg <= LBP_reg + ((data[count] >= data[4]) ? (9'd1 << (count - 1)) : 0);
        end
      end
      default: begin
        if(count == 4'd1) begin
          lbp_valid <= 1'd0;
          count <= 4'd0;
        end
        else begin
          count <= count + 4'd1;
          lbp_valid <= 1'd1;
          lbp_addr <= ({7'd0,row} << 7) + {7'd0,col} + 14'd129;
          lbp_data <= LBP_reg;
          LBP_reg <= 8'd0;
          if(row == 7'd125 && col == 7'd125) begin
            finish <= 1'd1;
          end
          else if(col == 7'd125) begin
            col <= 7'd0;
            row <= row + 7'd1;
          end
          else begin
            col <= col + 7'd1;
          end
        end
      end
    endcase
  end  
end

//====================================================================
endmodule
