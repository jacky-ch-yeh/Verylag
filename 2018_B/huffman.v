module huffman ( clk, reset, gray_valid, gray_data, CNT_valid, CNT1, CNT2, CNT3, CNT4, CNT5, CNT6,
code_valid, HC1, HC2, HC3, HC4, HC5, HC6, M1, M2, M3, M4, M5, M6);

input clk;
input reset;
input gray_valid;
input [7:0] gray_data;
output CNT_valid;
output [7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
output code_valid;
output [7:0] HC1, HC2, HC3, HC4, HC5, HC6;
output [7:0] M1, M2, M3, M4, M5, M6;

reg CNT_valid, code_valid;
reg [7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
reg [7:0] HC1, HC2, HC3, HC4, HC5, HC6;
reg [7:0] M1, M2, M3, M4, M5, M6;

reg [3:0] state;
reg [2:0] i1, i2, i3, i4, i5, i6; // count for assigning huffman code (HC1, HC2, ...)
reg [2:0] icomp;
reg [3:0] i, j;
reg [13:0] symbol[5:0]; // [7:0] for # of CNT, [13:8] for membership bit (000001 means symbol A1)

always @(posedge clk or posedge reset) 
begin

    if(reset)
    begin
        CNT_valid <= 0;
        code_valid <= 0;
        CNT1 <= 8'd0;
        CNT2 <= 8'd0;
        CNT3 <= 8'd0;
        CNT4 <= 8'd0;
        CNT5 <= 8'd0;
        CNT6 <= 8'd0;
        HC1 <= 8'd0;
        HC2 <= 8'd0;
        HC3 <= 8'd0;
        HC4 <= 8'd0;
        HC5 <= 8'd0;
        HC6 <= 8'd0;
        M1 <= 8'd0;
        M2 <= 8'd0;
        M3 <= 8'd0;
        M4 <= 8'd0;
        M5 <= 8'd0;
        M6 <= 8'd0;

        i <= 4'd0;
        icomp <= 3'd4;
        i1 <= 3'd0;
        i2 <= 3'd0;
        i3 <= 3'd0;
        i4 <= 3'd0;
        i5 <= 3'd0;
        i6 <= 3'd0;
        state <= 0;
    end
    else 
    begin
        case (state)
            0: begin // count for different gray scales
                if(i < 2) begin
                    i <= i + 4'd1;
                end
                else begin
                    state <= (gray_valid) ? state : 1;
                    case(gray_data)
                        8'h01: CNT1 <= CNT1 + 8'd1;
                        8'h02: CNT2 <= CNT2 + 8'd1;
                        8'h03: CNT3 <= CNT3 + 8'd1;
                        8'h04: CNT4 <= CNT4 + 8'd1;
                        8'h05: CNT5 <= CNT5 + 8'd1;
                        8'h06: CNT6 <= CNT6 + 8'd1;
                        default: CNT6 <= CNT6;
                    endcase
                end
            end
            1: begin // initialization
                CNT_valid <= 1;
                i <= 4'd0;
                j <= 4'd5;
                symbol[0] <= {6'b000001, CNT1};
                symbol[1] <= {6'b000010, CNT2};
                symbol[2] <= {6'b000100, CNT3};
                symbol[3] <= {6'b001000, CNT4};
                symbol[4] <= {6'b010000, CNT5};
                symbol[5] <= {6'b100000, CNT6};
                state <= 2;
            end
            2: begin // Bubble Sort
                CNT_valid <= 0;
                /* swap */
                if(symbol[i][7:0] < symbol[i + 4'd1][7:0]) begin
                    symbol[i] <= symbol[i + 4'd1];
                    symbol[i + 4'd1] <= symbol[i];
                end
                else begin
                    symbol[i] <= symbol[i];
                    symbol[i + 4'd1] <= symbol[i + 4'd1];
                end
                /* update index */
                if(i == j - 4'd1) begin
                    if(j == 4'd1) begin
                        i <= 4'd13;
                        state <= 3;
                    end
                    else begin
                        i <= 4'd0;
                        j <= j - 4'd1;
                    end 
                end
                else begin
                    i <= i + 4'd1;
                end
            end
            3: begin // encoding and combining
                if(symbol[icomp][i] || symbol[icomp + 3'd1][i]) 
                begin
                    case(i - 4'd7)
                        4'd1: begin
                            i1 <= i1 + 3'd1;
                            HC1[i1] <= (symbol[icomp][i]) ? 0 : 1;
                            M1[i1] <= 1;
                        end
                        4'd2: begin
                            i2 <= i2 + 3'd1;
                            HC2[i2] <= (symbol[icomp][i]) ? 0 : 1;
                            M2[i2] <= 1;
                        end
                        4'd3: begin
                            i3 <= i3 + 3'd1;
                            HC3[i3] <= (symbol[icomp][i]) ? 0 : 1;
                            M3[i3] <= 1;
                        end
                        4'd4: begin
                            i4 <= i4 + 3'd1;
                            HC4[i4] <= (symbol[icomp][i]) ? 0 : 1;
                            M4[i4] <= 1;
                        end
                        4'd5: begin
                            i5 <= i5 + 3'd1;
                            HC5[i5] <= (symbol[icomp][i]) ? 0 : 1;
                            M5[i5] <= 1;
                        end
                        default: begin
                            i6 <= i6 + 3'd1;
                            HC6[i6] <= (symbol[icomp][i]) ? 0 : 1;
                            M6[i6] <= 1;
                        end
                    endcase
                end
                else begin end

                if(i == 4'd8) begin
                    i <= 4'd0;
                    j <= icomp;
                    symbol[icomp] <= symbol[icomp] + symbol[icomp + 3'd1];
                    icomp <= icomp - 3'd1;

                    if(icomp == 0) begin
                        state <= 4;
                        code_valid <= 1;
                    end
                    else begin
                        state <= 2;
                    end
                end
                else begin
                    i <= i - 4'd1;
                    state <= state;
                end
            end
            default: begin
                code_valid <= 0;
            end
        endcase
    end

end
  
endmodule

