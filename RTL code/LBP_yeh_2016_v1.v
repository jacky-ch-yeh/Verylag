
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

wire [13:0] gray_addr, lbp_addr;
reg [7:0] lbp_data;
reg gray_req, lbp_valid, finish;

localparam Idle = 3'd0;
localparam Read_In_9 = 3'd1;
localparam LBP_Cal = 3'd2;
localparam Modify_Map = 3'd3;
localparam Read_In_3 = 3'd4;

reg [2:0] cur_state, next_state;
reg [6:0] x, y;
reg [7:0] lbp_map[7:0], lbp_central;
reg [2:0] count;
reg [3:0] x_t, y_t;
wire [13:0] one_dim_addr;

assign one_dim_addr = {y + y_t, x + x_t}; 
assign gray_addr = one_dim_addr;
assign lbp_addr = one_dim_addr;

//====================================================================
always @(*) begin
    next_state = cur_state;
    case (cur_state)
        Idle: if (gray_ready) next_state = Read_In_9;
        Read_In_9: if (x_t == 4'd2 && y_t == 4'd2) next_state = LBP_Cal;
        LBP_Cal: if (count == 3'd7) next_state = Modify_Map;
        Read_In_3: if (y_t == 4'd2) next_state = LBP_Cal;
        default: begin
            if (x == 7'd125) 
                next_state = Read_In_9;
            else 
                next_state = Read_In_3;
        end
    endcase
end

always @(posedge clk or posedge reset) 
begin
    
    if(reset)
    begin
        gray_req <= 0;
        lbp_valid <= 0;
        finish <= 0;
        x <= 7'd0;
        y <= 7'd0;
        x_t <= 4'd0;
        y_t <= 4'd0;
        count <= 3'd0;
    end
    else 
    begin
        case (cur_state)
            Idle: begin
                gray_req <= (gray_ready) ? 1 : 0;
            end
            Read_In_9: begin
                if (x_t == 4'd1 && y_t == 4'd1) begin
                    lbp_central <= gray_data;
                    count <= count;
                end
                else begin
                    lbp_map[count] <= gray_data;
                    count <= count + 3'd1;
                end

                if (x_t == 4'd2 && y_t == 4'd2) begin
                    x_t <= 4'd1;
                    y_t <= 4'd1;
                    lbp_data <= 8'd0;
                end
                else begin
                    if (x_t == 4'd2) begin
                        x_t <= 4'd0;
                        y_t <= y_t + 4'd1;
                    end
                    else begin
                        x_t <= x_t + 4'd1;
                    end
                end
            end
            LBP_Cal: begin
                lbp_data <= lbp_data + ((lbp_map[count] >= lbp_central) ? 8'd1 <<< count : 8'd0);
                count <= count + 3'd1;
                lbp_valid <= (count == 3'd7) ? 1 : 0;
            end
            Read_In_3: begin 
                if (y_t == 4'd2) begin
                    x_t <= 4'd1;
                    y_t <= 4'd1;
                    lbp_map[7] <= gray_data;
                    lbp_data <= 8'd0;
                end
                else begin
                    y_t <= y_t + 4'd1;
                    if(y_t == 4'd0) 
                        lbp_map[2] <= gray_data;
                    else 
                        lbp_map[4] <= gray_data;
                end
            end
            default: begin // Modify_Map
                if (x == 7'd125 && y == 7'd125) begin
                    finish <= 1;
                end
                else if (x == 7'd125) begin
                    x <= 7'd0;
                    y <= y + 7'd1;
                    x_t <= 4'd0;
                    y_t <= 4'd0;
                end
                else begin
                    x <= x + 7'd1;
                    x_t <= 4'd2;
                    y_t <= 4'd0;
                end
                lbp_valid <= 0;
                lbp_map[0] <= lbp_map[1];
                lbp_map[1] <= lbp_map[2];
                lbp_map[3] <= lbp_central;
                lbp_central <= lbp_map[4];
                lbp_map[5] <= lbp_map[6];
                lbp_map[6] <= lbp_map[7];
            end
        endcase
    end

end

always @(posedge clk or posedge reset) begin
    if(reset) cur_state <= 0;
    else cur_state <= next_state;
end
//====================================================================
endmodule
