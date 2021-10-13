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
reg [2:0] row, col;
reg [5:0] one_degree_pos;
reg [6:0] pixel_counter;

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
localparam AVERAGE = 7;
localparam CTR_CLKWISE_ROT = 8;
localparam CLKWISE_ROT = 9;
localparam MIRROR_X = 10;
localparam MIRROR_Y = 11;

always @(posedge clk or posedge reset) 
begin
    if(reset) 
        cur_state <= LOAD_DATA;
    else
        cur_state <= next_state;
end

always @(*) 
begin
    case (cur_state)
        WAIT_CMD: begin
            if(cmd_valid)
                next_state <= PROCESS;
            else
                next_state <= WAIT_CMD; 
        end
        PROCESS: begin
            if(pixel_counter == 7'd65 && cmd_reg != WRITE) 
                next_state <= WAIT_CMD;
            else
                next_state <= PROCESS;    
        end
        default: begin  //LOAD_DATA
            if(pixel_counter == 7'd64) 
                next_state <= WAIT_CMD;
            else
                next_state <= LOAD_DATA;          
        end 
    endcase
end

always @(negedge clk or posedge reset) 
begin
    if(reset) begin
        row <= 4'd4;
        col <= 4'd4;
    end
    else 
    begin
        if(cur_state == PROCESS) 
        begin
            case(cmd_reg)
                WRITE: begin
                end
                SHIFT_UP: begin
                    if(row <= 4'd1)
                        row <= row;
                    else
                        row <= row - 4'd1; 
                end
                SHIFT_DOWN: begin
                    if(row >= 4'd7)
                        row <= row;
                    else
                        row <= row + 4'd1;  
                end
                SHIFT_LEFT: begin
                    if(col <= 4'd1)
                        col <= col;
                    else
                        col <= col - 4'd1; 
                end
                SHIFT_RIGHT: begin
                    if(col >= 4'd7)
                        col <= col;
                    else
                        col <= col + 4'd1; 
                end
                MAX: begin
                    if(data_buf[one_degree_pos] >= data_buf[one_degree_pos+1] && data_buf[one_degree_pos] >= data_buf[one_degree_pos+8] && data_buf[one_degree_pos] >= data_buf[one_degree_pos+9]) begin
                        data_buf[one_degree_pos+1] <= data_buf[one_degree_pos];
                        data_buf[one_degree_pos+8] <= data_buf[one_degree_pos];
                        data_buf[one_degree_pos+9] <= data_buf[one_degree_pos];
                    end
                    else if(data_buf[one_degree_pos+1] >= data_buf[one_degree_pos] && data_buf[one_degree_pos+1] >= data_buf[one_degree_pos+8] && data_buf[one_degree_pos+1] >= data_buf[one_degree_pos+9]) begin
                        data_buf[one_degree_pos] <= data_buf[one_degree_pos+1];
                        data_buf[one_degree_pos+8] <= data_buf[one_degree_pos+1];
                        data_buf[one_degree_pos+9] <= data_buf[one_degree_pos+1]; 
                    end
                    else if(data_buf[one_degree_pos+8] >= data_buf[one_degree_pos] && data_buf[one_degree_pos+8] >= data_buf[one_degree_pos+1] && data_buf[one_degree_pos+8] >= data_buf[one_degree_pos+9]) begin
                        data_buf[one_degree_pos] <= data_buf[one_degree_pos+8];
                        data_buf[one_degree_pos+1] <= data_buf[one_degree_pos+8];
                        data_buf[one_degree_pos+9] <= data_buf[one_degree_pos+8]; 
                    end 
                    else begin
                        data_buf[one_degree_pos] <= data_buf[one_degree_pos+9];
                        data_buf[one_degree_pos+1] <= data_buf[one_degree_pos+9];
                        data_buf[one_degree_pos+8] <= data_buf[one_degree_pos+9]; 
                    end
                end
                MIN: begin
                    if(data_buf[one_degree_pos] <= data_buf[one_degree_pos+1] && data_buf[one_degree_pos] <= data_buf[one_degree_pos+8] && data_buf[one_degree_pos] <= data_buf[one_degree_pos+9]) begin
                        data_buf[one_degree_pos+1] <= data_buf[one_degree_pos];
                        data_buf[one_degree_pos+8] <= data_buf[one_degree_pos];
                        data_buf[one_degree_pos+9] <= data_buf[one_degree_pos];
                    end
                    else if(data_buf[one_degree_pos+1] <= data_buf[one_degree_pos] && data_buf[one_degree_pos+1] <= data_buf[one_degree_pos+8] && data_buf[one_degree_pos+1] <= data_buf[one_degree_pos+9]) begin
                        data_buf[one_degree_pos] <= data_buf[one_degree_pos+1];
                        data_buf[one_degree_pos+8] <= data_buf[one_degree_pos+1];
                        data_buf[one_degree_pos+9] <= data_buf[one_degree_pos+1]; 
                    end
                    else if(data_buf[one_degree_pos+8] <= data_buf[one_degree_pos] && data_buf[one_degree_pos+8] <= data_buf[one_degree_pos+1] && data_buf[one_degree_pos+8] <= data_buf[one_degree_pos+9]) begin
                        data_buf[one_degree_pos] <= data_buf[one_degree_pos+8];
                        data_buf[one_degree_pos+1] <= data_buf[one_degree_pos+8];
                        data_buf[one_degree_pos+9] <= data_buf[one_degree_pos+8]; 
                    end 
                    else begin
                        data_buf[one_degree_pos] <= data_buf[one_degree_pos+9];
                        data_buf[one_degree_pos+1] <= data_buf[one_degree_pos+9];
                        data_buf[one_degree_pos+8] <= data_buf[one_degree_pos+9]; 
                    end 
                end
                AVERAGE: begin
                    data_buf[one_degree_pos] <= (({2'd0,data_buf[one_degree_pos]} + {2'd0,data_buf[one_degree_pos+1]} + {2'd0,data_buf[one_degree_pos+8]} + {2'd0,data_buf[one_degree_pos+9]})) >> 2;
                    data_buf[one_degree_pos+1] <= (({2'd0,data_buf[one_degree_pos]} + {2'd0,data_buf[one_degree_pos+1]} + {2'd0,data_buf[one_degree_pos+8]} + {2'd0,data_buf[one_degree_pos+9]})) >> 2;
                    data_buf[one_degree_pos+8] <= (({2'd0,data_buf[one_degree_pos]} + {2'd0,data_buf[one_degree_pos+1]} + {2'd0,data_buf[one_degree_pos+8]} + {2'd0,data_buf[one_degree_pos+9]})) >> 2;
                    data_buf[one_degree_pos+9] <= (({2'd0,data_buf[one_degree_pos]} + {2'd0,data_buf[one_degree_pos+1]} + {2'd0,data_buf[one_degree_pos+8]} + {2'd0,data_buf[one_degree_pos+9]})) >> 2;
                end
                CTR_CLKWISE_ROT: begin
                    data_buf[one_degree_pos] <= data_buf[one_degree_pos+1];
                    data_buf[one_degree_pos+1] <= data_buf[one_degree_pos+9];
                    data_buf[one_degree_pos+9] <= data_buf[one_degree_pos+8];
                    data_buf[one_degree_pos+8] <= data_buf[one_degree_pos];
                end
                CLKWISE_ROT: begin
                data_buf[one_degree_pos] <= data_buf[one_degree_pos+8];
                data_buf[one_degree_pos+8] <= data_buf[one_degree_pos+9];
                data_buf[one_degree_pos+9] <= data_buf[one_degree_pos+1]; 
                data_buf[one_degree_pos+1] <= data_buf[one_degree_pos];
                end
                MIRROR_X: begin
                    data_buf[one_degree_pos] <= data_buf[one_degree_pos+8];
                    data_buf[one_degree_pos+1] <= data_buf[one_degree_pos+9];
                    data_buf[one_degree_pos+8] <= data_buf[one_degree_pos];
                    data_buf[one_degree_pos+9] <= data_buf[one_degree_pos+1];
                end
                default: begin  //MIRROR_Y
                    data_buf[one_degree_pos] <= data_buf[one_degree_pos+1];
                    data_buf[one_degree_pos+1] <= data_buf[one_degree_pos];
                    data_buf[one_degree_pos+8] <= data_buf[one_degree_pos+9];
                    data_buf[one_degree_pos+9] <= data_buf[one_degree_pos+8];
                end 
            endcase        
        end
        else if(cur_state == LOAD_DATA) begin//LOAD_DATA
            if(pixel_counter >= 7'd2 && pixel_counter <= 7'd64)
                data_buf[IROM_A-1] <= IROM_Q;
            else begin end
        end
        else begin //WAIT_CMD
            if(pixel_counter == 7'd65)
                data_buf[IROM_A] <= IROM_Q;
            else begin end
        end
    end
end

always @(*) begin
    one_degree_pos <= ({3'd0,row} << 3) + col - 6'd9;
end

always @(posedge clk or posedge reset) 
begin
    if(reset) begin
        cmd_reg <= cmd;
        pixel_counter <= 7'd0;
        IRAM_A <= 6'd0;
        IRAM_valid <= 1'd0;
        IROM_rd <= 1'd1;
        busy <= 1'd1;
        done <= 1'd0;
    end 
    else begin
        case(cur_state)
            LOAD_DATA: begin
                if(IROM_rd == 1'd1) begin
                    if(pixel_counter == 7'd0) begin
                        IROM_A <= 6'd0;
                        pixel_counter <= 7'd1;
                    end
                    else if(pixel_counter >= 7'd1 && pixel_counter < 7'd64) begin
                        IROM_A <= IROM_A + 6'd1;
                        pixel_counter <= pixel_counter + 7'd1;
                    end
                    else if(pixel_counter == 7'd64) begin
                        IROM_rd <= 1'd0;
                        busy <= 1'd0;
                        pixel_counter <= pixel_counter + 7'd1;
                    end
                    else begin end
                end
                else begin end
            end
            PROCESS: begin
                case(cmd_reg) 
                    WRITE: begin
                        if(pixel_counter == 7'd0 || pixel_counter == 7'd65) begin
                            pixel_counter <= 7'd1;
                            IRAM_A <= 6'd0;
                            IRAM_D <= data_buf[0];
                            IRAM_valid <= 1'd1;
                            busy <= 1'd1;        
                        end
                        else if(pixel_counter == 7'd64) begin
                            pixel_counter <= 7'd0;
                            IRAM_A <= 6'd0;
                            IRAM_valid <= 1'd0;
                            busy <= 1'd0;
                            done <= 1'd1;
                        end
                        else begin
                            IRAM_A <= IRAM_A + 6'd1;
                            pixel_counter <= pixel_counter + 7'd1;
                            IRAM_D <= data_buf[pixel_counter];
                        end
                    end
                    default: begin 
                        busy <= 1'd0;
                    end                
                endcase
            end
            default: begin  //WAIT_CMD
                if(cmd_valid) begin
                    cmd_reg <= cmd;
                    busy <= 1'd1;
                end
                else begin end
            end
        endcase
    end   
end

endmodule



