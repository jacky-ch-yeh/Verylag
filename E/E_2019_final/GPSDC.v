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

reg [23:0] A1, A2, B1, B2;
reg [95:0] COS_DATA_pre;
reg [128:0] COS_A1_buf, COS_B1_buf;
reg [95:0] mul1, mul2;
wire [191:0] mul3;
reg [5:0] cur_state, next_state;

assign mul3 = mul1 * mul2;

always @(*) begin
    next_state = cur_state;
    case (cur_state)
        0: if (DEN) next_state = 1;
        1: if ({8'd0, A1, 16'd0} < COS_DATA[95:48]) next_state = 2;
        2: next_state = 3;
        3: next_state = 4;
        4: if (DEN) next_state = 5;
        5: if ({8'd0, B1, 16'd0} < COS_DATA[95:48]) next_state = 6;
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
                    A1 <= LAT_IN;
                    A2 <= LON_IN;
                    COS_ADDR <= 7'd0;
                end
                else begin
                    A1 <= A1;
                    A2 <= A2;
                end
            end 
            1: begin
                if({8'd0, A1, 16'd0} < COS_DATA[95:48]) begin // got our x1, y1
                    mul1 <= COS_DATA_pre[47:0]; // y0
                    mul2 <= COS_DATA[95:48] - COS_DATA_pre[95:48]; // x1 - x0
                    COS_ADDR <= COS_ADDR;
                end
                else begin
                    COS_DATA_pre <= COS_DATA; // x0, y0
                    COS_ADDR <= COS_ADDR + 7'd1;
                end
            end
            2: begin
                COS_A1_buf <= mul3[95:0];
                mul1 <= {8'd0, A1, 16'd0} - COS_DATA_pre[95:48]; // x - x0
                mul2 <= COS_DATA[47:0] - COS_DATA_pre[47:0]; // y1 - y0
            end
            3: begin
                // COSA1 = (y0 * (x1 - x0) + (x - x0) * (y1 - y0)) / (x1 - x0) 
                COS_A1_buf <= (COS_A1_buf + mul3[95:0]) / (COS_DATA[95:48] - COS_DATA_pre[95:48]);
            end
            4: begin
                COS_A1_buf <= COS_A1_buf[31:0]; // 32 float
                if(DEN) begin
                    B1 <= LAT_IN;
                    B2 <= LON_IN;
                    COS_ADDR <= 7'd0;
                end
                else begin
                    B1 <= B1;
                    B2 <= B2;
                end
            end
            5: begin
                if({8'd0, B1, 16'd0} < COS_DATA[95:48]) begin // got our x1, y1
                    mul1 <= COS_DATA_pre[47:0]; // y0
                    mul2 <= COS_DATA[95:48] - COS_DATA_pre[95:48]; // x1 - x0
                    COS_ADDR <= COS_ADDR;
                end
                else begin
                    COS_DATA_pre <= COS_DATA; 
                    COS_ADDR <= COS_ADDR + 7'd1;
                end
            end
            6: begin
                COS_B1_buf <= mul3[95:0];
                mul1 <= {8'd0, B1, 16'd0} - COS_DATA_pre[95:48]; // x - x0
                mul2 <= COS_DATA[47:0] - COS_DATA_pre[47:0]; // y1 - y0
            end
            7: begin
                // COSB1 = (y0 * (x1 - x0) + (x - x0) * (y1 - y0)) / (x1 - x0) 
                COS_B1_buf <= (COS_B1_buf + mul3[95:0]) / (COS_DATA[95:48] - COS_DATA_pre[95:48]); 
                mul1 <= (B2 > A2) ? {8'd0, B2, 16'd0} - {8'd0, A2, 16'd0} : {8'd0, A2, 16'd0} - {8'd0, B2, 16'd0};
                mul2 <= {16'd0, Rad, 16'd0};
            end
            8: begin
                COS_B1_buf <= COS_B1_buf[31:0]; // 32 float
                mul1 <= mul3[63:0] >> 1; // 64 float
                mul2 <= mul3[63:0] >> 1; // 64 float
            end
            9: begin
                mul1 <= mul3[127:64]; // 64 float
                mul2 <= {COS_B1_buf, 32'd0}; // 32 float
            end
            10: begin
                mul1 <= mul3[127:64]; // 64 float
                mul2 <= {COS_A1_buf, 32'd0}; // 32 float
            end
            11: begin
                a <= mul3[127:64];
                mul1 <= (B1 > A1) ? {8'd0, B1, 16'd0} - {8'd0, A1, 16'd0} : {8'd0, A1, 16'd0} - {8'd0, B1, 16'd0};
                mul2 <= {16'd0, Rad, 16'd0};
            end
            12: begin
                mul1 <= mul3[63:0] >> 1; // 64 float
                mul2 <= mul3[63:0] >> 1; // 64 float
            end
            13: begin
                Valid <= 1;
                a <= a + mul3[127:64];
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
