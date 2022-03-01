module geofence ( clk,reset,X,Y,valid,is_inside);
input clk;
input reset;
input [9:0] X;
input [9:0] Y;
output valid;
output is_inside;

reg valid;
reg is_inside;

reg [2:0] i, j;
reg [3:0] state;
reg signed [10:0] obj_x, obj_y;
reg signed [10:0] fence_x[5:0], fence_y[5:0];
reg signed [10:0] a, b, c, d;
reg signed [20:0] tmp;
wire signed [20:0] out;

assign out = (a - b) * (c - d);

always @(posedge clk or posedge reset) 
begin

    if(reset)
    begin
        valid <= 0;
        is_inside <= 0;
        i <= 3'd0;
        j <= 3'dz;
        state <= 4'd0;
    end
    else
    begin
        case (state)
            4'd0: begin
                obj_x <= X;
                obj_y <= Y;
                i <= 3'd0;
                state <= 4'd1;
            end
            4'd1: begin
                fence_x[i] <= X;
                fence_y[i] <= Y;

                if(i == 3'd5) begin
                    i <= 3'd1;
                    j <= 3'd5;
                    state <= 4'd2;
                end
                else begin
                    i <= i + 3'd1;
                    state <= state;
                end
            end
            4'd2: begin
                a <= fence_x[i];
                b <= fence_x[0];
                c <= fence_y[i + 3'd1];
                d <= fence_y[0];
                state <= 4'd3;
            end
            4'd3: begin
                tmp <= out;
                a <= fence_x[i + 3'd1];
                b <= fence_x[0];
                c <= fence_y[i];
                d <= fence_y[0];
                state <= 4'd4;
            end
            4'd4: begin
                /* swap */
                if((tmp - out) >= 0) begin
                    fence_x[i] <= fence_x[i + 3'd1];
                    fence_x[i + 3'd1] <= fence_x[i];
                    fence_y[i] <= fence_y[i + 3'd1];
                    fence_y[i + 3'd1] <= fence_y[i];
                end
                else begin
                    fence_x[i] <= fence_x[i];
                    fence_y[i] <= fence_y[i];
                end
                /* update index */
                if(i == j - 3'd1) begin
                    if(j == 3'd2) begin
                        i <= 3'd0;
                        j <= 3'd5;
                        state <= 4'd5;
                    end
                    else begin
                        i <= 3'd1;
                        j <= j - 3'd1;
                        state <= 4'd2;
                    end
                end
                else begin
                    i <= i + 3'd1;
                    state <= 4'd2;
                end
            end
            4'd5: begin
                a <= fence_x[i];
                b <= obj_x;
                c <= fence_y[i + 3'd1];
                d <= fence_y[i];
                state <= 4'd6;
            end
            4'd6: begin
                tmp <= out;
                a <= fence_x[i + 3'd1];
                b <= fence_x[i];
                c <= fence_y[i];
                d <= obj_y;
                state <= 4'd7;
            end
            4'd7: begin
                if((tmp - out) >= 0) begin
                    i <= 3'dz;
                    valid <= 1;
                    is_inside <= 0;
                    state <= 4'd8;
                end
                else begin
                    if(i == j - 3'd1) begin
                        if(j == 3'd1) begin
                            i <= 3'dz;
                            j <= 3'dz;
                            valid <= 1;
                            is_inside <= 1;
                            state <= 4'd8;
                        end
                        else begin
                            i <= 3'd0;
                            j <= j - 3'd1;
                            state <= 4'd5;
                        end
                    end
                    else begin
                        i <= i + 3'd1;
                        state <= 4'd5;
                    end
                end
            end
            default: begin
                valid <= 0;
                is_inside <= 1'dz;
                state <= 4'd0;
            end
        endcase
    end

end

endmodule

