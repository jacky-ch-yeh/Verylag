module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output busy;
output valid;
output [7:0] candidate;
reg busy;
reg valid;
reg [7:0] candidate;

reg [3:0] state;
reg in_A, in_B;
reg [3:0] X, Y;
reg [8:0] sum_of_squares;
reg signed [3:0] diff;
wire [7:0] square;
assign square = diff * diff;

always @(posedge clk or posedge rst) begin  
  if(rst) begin
    busy <= 1'd0;
    valid <= 1'd0;
    candidate <= 8'd0;
    sum_of_squares <= 9'd0;
    in_A <= 1'd0;
    in_B <= 1'd0;
    X <= 4'd1;
    Y <= 4'd1;
    state <= 0;
  end
  else begin
    case(state)
      0: begin
        if(en) begin
          busy <= 1'd1;
          state <= 1;
        end
        else begin 
          valid <= 1'd0;
          busy <= 1'd0;
          candidate <= 8'd0;
          state <= 0;
        end
      end
      1: begin
        diff <= X - central[23:20];
        state <= 2;
      end
      2: begin
        sum_of_squares <= sum_of_squares + square;
        diff <= Y - central[19:16];
        state <= 3;
      end
      3: begin
        sum_of_squares <= sum_of_squares + square;
        diff <= radius[11:8];
        state <= 4;
      end
      4: begin
        sum_of_squares <= 9'd0;
        if(sum_of_squares <= square) begin
          in_A <= 1;
        end
        else begin 
          in_A <= 0;
        end
        diff <= X - central[15:12];
        state <= 5;
      end
      5: begin
        sum_of_squares <= sum_of_squares + square;
        diff <= Y - central[11:8];
        state <= 6;
      end
      6: begin
        sum_of_squares <= sum_of_squares + square;
        diff <= radius[7:4];
        state <= 7;
      end
      7: begin
        sum_of_squares <= 9'd0;
        if(sum_of_squares <= square) begin
          in_B <= 1;
        end
        else begin
          in_B <= 0;
        end
        state <= 8;
      end
      8: begin
        case (mode)
          2'b00: begin
            candidate <= candidate + in_A;
          end
          2'b01: begin
            candidate <= candidate + (in_A & in_B);
          end 
          default: begin
            candidate <= candidate + (in_A ^ in_B);
          end 
        endcase
        in_A <= 0;
        in_B <= 0;
        state <= 9;
      end
      default: begin
        if(X == 4'd8 && Y == 4'd8) begin
          X <= 4'd1;
          Y <= 4'd1;
          valid <= 1;
          state <= 0;
        end
        else begin
          state <= 1;
          if(X == 4'd8) begin
            X <= 4'd1;
            Y <= Y + 4'd1;
          end
          else begin
            X <= X + 4'd1;
          end
        end
      end
    endcase
  end
end

endmodule