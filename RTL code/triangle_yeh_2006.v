module triangle (clk, reset, nt, xi, yi, busy, po, xo, yo);
  input clk, reset, nt;
  input [2:0] xi, yi;
  output busy, po;
  output [2:0] xo, yo;
  
  reg busy, po;
  reg [2:0] xo, yo;

  reg [2:0] cur_state, next_state;
  reg signed [3:0] X, Y, X_m, Y_m, X1, Y2, X3; // x2 is X_m, y3 is Y_m 
  reg signed [7:0] LHS, RHS;
  
  always @(posedge clk or posedge reset) begin
    if(reset) 
      cur_state <= 0;
    else
      cur_state <= next_state;
  end

  always @(*) begin
    case(cur_state)
      0: begin
        if(nt)
          next_state <= 1;
        else
          next_state <= 0;
      end
      1: begin
        next_state <= 2;
      end
      2: begin
        next_state <= 3;
      end
      3: begin
        next_state <= 4;
      end
      4: begin
        if(X == X_m && Y == Y_m) 
          next_state <= 0;
        else
          next_state <= 3;
      end
    endcase
  end

  always @(*) begin
    LHS <= (X - X_m) * (Y_m - Y2);
    RHS <= (X3 - X_m) * (Y - Y2);
  end

  always @(posedge clk or posedge reset) begin
    if(reset) begin
      po <= 1'd0;
      busy <= 1'd0;
      xo <= 3'd0;
      yo <= 3'd0;
    end
    else begin
      case(cur_state)
        0: begin
          X <= {1'd0, xi};
          X1 <= {1'd0, xi};
          Y <= {1'd0, yi};
        end
        1: begin
          X_m <= {1'd0, xi};
          Y2 <= {1'd0, yi};
          busy <= 1'd1;
        end
        2: begin
          X3 <= {1'd0, xi};
          Y_m <= {1'd0, yi};
        end
        3: begin
          if(LHS <= RHS)begin
            po <= 1'd1;
            xo <= X;
            yo <= Y;
          end
        end
        4: begin
          po <= 1'd0;
          if(X == X_m && Y == Y_m) begin
            busy <= 1'd0;
          end
          else if(X == X_m) begin
            Y <= Y + 4'd1;
            X <= X1;
          end
          else begin
            X <= X + 4'd1;
          end
        end
      endcase
    end
  end

endmodule
