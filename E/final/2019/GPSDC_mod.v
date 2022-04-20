`timescale 1ns/10ps
module GPSDC(clk, reset_n, DEN, LON_IN, LAT_IN, COS_ADDR, COS_DATA, ASIN_ADDR, ASIN_DATA, Valid, a, D);
input              clk;
input              reset_n;
input              DEN;
input      [23:0]  LON_IN;
input      [23:0]  LAT_IN;
input      [95:0]  COS_DATA;
output     [6:0]   COS_ADDR;
input      [127:0] ASIN_DATA;
output     [5:0]   ASIN_ADDR;
output             Valid;
output     [39:0]  D;
output     [63:0]  a;

reg [6:0] COS_ADDR;
reg [5:0] ASIN_ADDR;
reg Valid;
reg [39:0] D;
reg [63:0] a;

localparam Rad = 16'h477;

reg [23:0] LAT_A, LON_A, LAT_B, LON_B; // 8, 16
reg [47:0] COS_DATA_PRE_X, COS_DATA_PRE_Y; // 16, 32
reg [95:0] COS_A, COS_B; // 32, 64
reg [96:0] mul1, mul2, p, q;
wire [192:0] mul3, div;
reg [5:0] cur_state, next_state;

assign mul3 = mul1 * mul2;
assign div = q / p;

always @(*) begin
    next_state = cur_state;
    case (cur_state)
        0: if (DEN) next_state = 1;
        1: if ({8'd0, LAT_A, 16'd0} < COS_DATA[95:48]) next_state = 2;
        2: next_state = 3;
        3: next_state = 4;
        4: if (DEN) next_state = 5;
        5: if ({8'd0, LAT_B, 16'd0} < COS_DATA[95:48]) next_state = 6;
        6: next_state = 7;
        7: next_state = 8;
        8: next_state = 9;
        9: next_state = 10;
        10: next_state = 11;
        11: next_state = 12;
        12: next_state = 13;
        13: next_state = 0;
        default: begin end
    endcase
end

always @(posedge clk or negedge reset_n) 
begin

    if(!reset_n)
    begin
        COS_ADDR <= 7'dz;
        ASIN_ADDR <= 7'dz;
        Valid <= 0;
        D <= 40'd0;
        a <= 64'd0;
    end
    else 
    begin
        case (cur_state)
            0: begin
                Valid <= 0;
                if(DEN) begin
                    LAT_A <= LAT_IN;
                    LON_A <= LON_IN;
                    COS_ADDR <= 7'd0;
                end
                else begin
                    LAT_A <= LAT_A;
                    LON_A <= LON_A;
                end
            end 
            1: begin
                if({8'd0, LAT_A, 16'd0} <= COS_DATA[95:48]) begin // find our x1 ?
                    mul1 <= COS_DATA_PRE_Y; // y0 : 16, 32
                    mul2 <= COS_DATA[95:48] - COS_DATA_PRE_X; // (x1 - x0) : 16, 32
                    COS_ADDR <= COS_ADDR;
                end
                else begin
                    COS_DATA_PRE_X <= COS_DATA[95:48]; // store x0
                    COS_DATA_PRE_Y <= COS_DATA[47:0]; // store y0
                    COS_ADDR <= COS_ADDR + 7'd1;
                end
            end
            2: begin
                q <= mul3[95:0]; // y0 * (x1 - x0) : 32, 64
                mul1 <= {8'd0, LAT_A, 16'd0} - COS_DATA_PRE_X; // (x - x0) : 16, 32
                mul2 <= COS_DATA[47:0] - COS_DATA_PRE_Y; // (y1 - y0) : 16, 32
            end
            3: begin
                q <= q + mul3[95:0]; // q = y0 * (x1 - x0) + (x - x0) * (y1 - y0) : 32, 64
                p <= {16'd0, COS_DATA[95:48] - COS_DATA_PRE_X, 32'd0}; // p = x1 - x0 : 16, 32
            end
            4: begin
                COS_A <= div[95:0]; // 32, 64
                if(DEN) begin
                    LAT_B <= LAT_IN;
                    LON_B <= LON_IN;
                    COS_ADDR <= 7'd0;
                end
                else begin
                    LAT_B <= LAT_B;
                    LON_B <= LON_B;
                end
            end
            5: begin
                if({8'd0, LAT_B, 16'd0} <= COS_DATA[95:48]) begin // find our x1 ?
                    mul1 <= COS_DATA_PRE_Y; // y0 : 16, 32
                    mul2 <= COS_DATA[95:48] - COS_DATA_PRE_X; // (x1 - x0) : 16, 32
                    COS_ADDR <= COS_ADDR;
                end
                else begin
                    COS_DATA_PRE_X <= COS_DATA[95:48]; // store x0
                    COS_DATA_PRE_Y <= COS_DATA[47:0]; // store y0
                    COS_ADDR <= COS_ADDR + 7'd1;
                end
            end
            6: begin
                q <= mul3[95:0]; // y0 * (x1 - x0) : 32, 64
                mul1 <= {8'd0, LAT_B, 16'd0} - COS_DATA_PRE_X; // (x - x0) : 16, 32
                mul2 <= COS_DATA[47:0] - COS_DATA_PRE_Y; // (y1 - y0) : 16, 32
            end
            7: begin
                q <= q + mul3[95:0]; // q = y0 * (x1 - x0) + (x - x0) * (y1 - y0) : 32, 64
                p <= {16'd0, COS_DATA[95:48] - COS_DATA_PRE_X, 32'd0}; // p = x1 - x0 : 16, 32
                mul1 <= (LON_B > LON_A) ? {8'd0, LON_B, 16'd0} - {8'd0, LON_A, 16'd0} : {8'd0, LON_A, 16'd0} - {8'd0, LON_B, 16'd0}; // lambda B - lambda A : 16, 32
                mul2 <= {16'd0, Rad, 16'd0}; // rad : 16, 32
            end
            8: begin
                COS_B <= div[95:0]; // 32, 64
                mul1 <= mul3[95:0] >>> 1; // (lambda B - lambda A) * rad / 2 : 32, 64
                mul2 <= mul3[95:0] >>> 1; // ~
            end
            9: begin
                mul1 <= mul3[135:40]; // RHS sine square : 8, 88
                mul2 <= {COS_B[71:0], 24'd0}; // 8, 88
            end
            10: begin
                mul1 <= mul3[183:88]; // cosine B * RHS sine square : 8, 88
                mul2 <= {COS_A[71:0], 24'd0}; // 8, 88
            end
            11: begin
                COS_A <= mul3[175:88]; // , 88
                mul1 <= (LAT_B > LAT_A) ? {8'd0, LAT_B, 16'd0} - {8'd0, LAT_A, 16'd0} : {8'd0, LAT_A, 16'd0} - {8'd0, LAT_B, 16'd0}; // 16, 32
                mul2 <= {16'd0, Rad, 16'd0}; // 16, 32
            end
            12: begin
                mul1 <= mul3[95:0] >>> 1; // (lambda B - lambda A) * rad / 2 : 32, 64
                mul2 <= mul3[95:0] >>> 1; // ~
            end
            13: begin
                Valid <= 1;
                a <= (COS_A + mul3[127:40]) >>> 24;
            end
            default: begin
            end
        endcase
    end

end

always @(posedge clk or negedge reset_n) begin
    if(!reset_n) cur_state <= 0;
    else cur_state <= next_state;
end

endmodule
