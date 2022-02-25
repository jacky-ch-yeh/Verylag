module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output valid;
output is_inside;

reg valid;
reg is_inside;

reg [9:0] obj_x, obj_y;
reg [9:0] fence_x[5:0], fence_y[5:0];
reg [2:0] i;
reg [2:0] state;
reg signed [10:0] mul1, mul2;
reg signed [20:0] mul3;

assign mul3 = mul1 * mul2;

always @(posedge clk or posedge reset) 
begin

    if(reset)
    begin
        valid <= 0;
        is_inside <= 0;
        i <= 3'd0;
        state <= 3'd0;
    end
    else
    begin
        case (state)
            3'd0: begin
                obj_x <= X;
                obj_y <= Y;
                i <= 3'd0;
                state <= 3'd1;
            end
            3'd1: begin
                fence_x[i] <= X;
                fence_y[i] <= Y;

                if(i == 3'd5) begin
                    i <= 3'd0;
                    state <= 3'd2;
                end
                else begin
                    i <= i + 3'd1;
                    state <= state;
                end
            end
            3'd2: begin

            end
            default: begin

            end
        endcase
    end

end

endmodule

