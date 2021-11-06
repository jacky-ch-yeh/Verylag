module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output reg IROM_rd;
output reg [5:0] IROM_A;
output reg IRAM_valid;
output reg [7:0] IRAM_D;
output reg [5:0] IRAM_A;
output reg busy;
output reg done;

reg [7:0] data_buf[63:0];
reg [2:0] x, y;
wire [5:0] one_dim_pos;
reg [9:0] comp_reg; // for buffering in MIN & MAX and calculating the sum in AVERAGE
reg canstore; 

reg [1:0] cur_state, next_state;
localparam PROCESS = 0;
localparam WAIT_CMD = 1;
localparam LOAD_DATA = 2;

reg [3:0] cmd_reg;
localparam WRITE = 0;
localparam SHIFT_UP = 1;
localparam SHIFT_DOWN = 2;
localparam SHIFT_LEFT = 3;
localparam SHIFT_RIGHT = 4;
localparam MAX = 5;
localparam MIN = 6;
localparam COMP2 = 12;
localparam COMP3 = 13;
localparam ASSIGN = 14;
localparam AVERAGE = 7;
localparam CTR_CLKWISE_ROT = 8;
localparam CLKWISE_ROT = 9;
localparam MIRROR_X = 10;
localparam MIRROR_Y = 11;

assign one_dim_pos = (y <<< 3) + x - 6'd9; // at the top left of the operation point

always @(posedge clk or posedge reset) 
begin
    if(reset) 
        cur_state <= LOAD_DATA;
    else
        cur_state <= next_state;
end

always @(*) begin
    case(cur_state)
        LOAD_DATA: begin
            if(IROM_A == 6'd63)
                next_state <= PROCESS;
            else
                next_state <= LOAD_DATA;
        end
        default: begin // PROCESS
            next_state <= PROCESS;
        end
    endcase
end

always @(posedge clk or posedge reset)
begin
    if(reset) 
    begin
        IROM_rd <= 1'd1;
        IROM_A <= 6'd0;
        IRAM_valid <= 1'd0;
        IRAM_D <= 8'd0;
        IRAM_A <= 6'd0;
        busy <= 1'd1;
        done <= 1'd0;
        x <= 4;
        y <= 4;
        canstore <= 0;
    end
    else 
    begin
        case(cur_state)
            LOAD_DATA: begin
                if(IROM_A == 6'd63) begin
                    IROM_rd <= 0;
                    busy <= 0;
                end
                else begin
                    IROM_rd <= 1;
                    busy <= 1;
                end
                if(canstore) begin
                    data_buf[IROM_A] <= IROM_Q;
                    IROM_A <= IROM_A + 1;
                end
                else begin
                    canstore <= 1;
                end
            end
            default: begin // PROCESS
                if(cmd_valid) begin
                    cmd_reg <= cmd;
                    busy <= 1;
                    comp_reg <= data_buf[one_dim_pos];
                    canstore <= 0;
                end
                else
                begin
                    case (cmd_reg)
                        WRITE: begin
                            if(IRAM_A == 6'd63) begin
                                busy <= 0;
                                IRAM_valid <= 0;
                                done <= 1;
                            end
                            else begin
                                IRAM_valid <= 1;
                                canstore <= 1;
                                if(canstore) begin
                                    IRAM_A <= IRAM_A + 1;
                                    IRAM_D <= data_buf[IRAM_A + 1];
                                end
                                else begin
                                    IRAM_A <= 0;
                                    IRAM_D <= data_buf[0];
                                end
                            end
                        end 
                        SHIFT_UP: begin
                            busy <= 0;
                            if(y == 1)
                                y <= 1;
                            else
                                y <= y - 1;
                        end
                        SHIFT_DOWN: begin
                            busy <= 0;
                            if(y == 7)
                                y <= 7;
                            else
                                y <= y + 1;
                        end
                        SHIFT_LEFT: begin
                            busy <= 0;
                            if(x == 1)
                                x <= 1;
                            else
                                x <= x - 1;
                        end
                        SHIFT_RIGHT: begin
                            busy <= 0;
                            if(x == 7)
                                x <= 7;
                            else
                                x <= x + 1;
                        end     
                        AVERAGE: begin
                        if(canstore) begin
                                busy <= 0;
                                data_buf[one_dim_pos] <= comp_reg;
                                data_buf[one_dim_pos + 1] <= comp_reg;
                                data_buf[one_dim_pos + 8] <= comp_reg;
                                data_buf[one_dim_pos + 9] <= comp_reg;
                        end 
                        else begin
                            comp_reg <= (data_buf[one_dim_pos] + data_buf[one_dim_pos + 1] + data_buf[one_dim_pos + 8] + data_buf[one_dim_pos + 9]) >>> 2;
                            canstore <= 1;
                        end
                        end
                        CTR_CLKWISE_ROT: begin
                            busy <= 0;
                            data_buf[one_dim_pos] <= data_buf[one_dim_pos + 1];
                            data_buf[one_dim_pos + 1] <= data_buf[one_dim_pos + 9];
                            data_buf[one_dim_pos + 9] <= data_buf[one_dim_pos + 8];
                            data_buf[one_dim_pos + 8] <= data_buf[one_dim_pos];
                        end
                        CLKWISE_ROT: begin
                            busy <= 0;
                            data_buf[one_dim_pos] <= data_buf[one_dim_pos + 8];
                            data_buf[one_dim_pos + 1] <= data_buf[one_dim_pos];
                            data_buf[one_dim_pos + 9] <= data_buf[one_dim_pos + 1];
                            data_buf[one_dim_pos + 8] <= data_buf[one_dim_pos + 9];
                        end
                        MIRROR_X: begin
                            busy <= 0;
                            data_buf[one_dim_pos] <= data_buf[one_dim_pos + 8];
                            data_buf[one_dim_pos + 1] <= data_buf[one_dim_pos + 9];
                            data_buf[one_dim_pos + 9] <= data_buf[one_dim_pos + 1];
                            data_buf[one_dim_pos + 8] <= data_buf[one_dim_pos];
                        end
                        MIRROR_Y: begin
                            busy <= 0;
                            data_buf[one_dim_pos] <= data_buf[one_dim_pos + 1];
                            data_buf[one_dim_pos + 1] <= data_buf[one_dim_pos];
                            data_buf[one_dim_pos + 9] <= data_buf[one_dim_pos + 8];
                            data_buf[one_dim_pos + 8] <= data_buf[one_dim_pos + 9];
                        end
                        // MAX: begin
                        //     /* combined in default */
                        // end
                        COMP2: begin
                            cmd_reg <= COMP3;
                            if(canstore) begin // MAX
                                comp_reg <= (comp_reg > data_buf[one_dim_pos + 8]) ? comp_reg : data_buf[one_dim_pos + 8];
                            end
                            else begin // MIN
                                comp_reg <= (comp_reg < data_buf[one_dim_pos + 8]) ? comp_reg : data_buf[one_dim_pos + 8];
                            end
                        end
                        COMP3: begin
                            cmd_reg <= ASSIGN;
                            if(canstore) begin // MAX
                                comp_reg <= (comp_reg > data_buf[one_dim_pos + 9]) ? comp_reg : data_buf[one_dim_pos + 9];
                            end
                            else begin // MIN
                                comp_reg <= (comp_reg < data_buf[one_dim_pos + 9]) ? comp_reg : data_buf[one_dim_pos + 9];
                            end
                        end
                        ASSIGN: begin
                            data_buf[one_dim_pos] <= comp_reg;
                            data_buf[one_dim_pos + 1] <= comp_reg;
                            data_buf[one_dim_pos + 8] <= comp_reg;
                            data_buf[one_dim_pos + 9] <= comp_reg;
                            busy <= 0;
                        end
                        default: begin // MAX and MIN (COMP1)
                            cmd_reg <= COMP2;
                            if(cmd_reg == MAX) begin // MAX
                                comp_reg <= (comp_reg > data_buf[one_dim_pos + 1]) ? comp_reg : data_buf[one_dim_pos + 1];
                                canstore <= 1;
                            end
                            else begin // MIN
                                comp_reg <= (comp_reg < data_buf[one_dim_pos + 1]) ? comp_reg : data_buf[one_dim_pos + 1];
                                canstore <= 0;
                            end
                        end
                    endcase
                end
            end
        endcase
    end
end

endmodule
