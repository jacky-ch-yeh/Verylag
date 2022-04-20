module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);
input clk;
input reset;
input [7:0] IROM_Q;
input [2:0] cmd;
input cmd_valid;
output reg IROM_EN;
output reg [5:0] IROM_A;
output reg IRB_RW;
output reg [7:0] IRB_D;
output reg [5:0] IRB_A;
output reg busy;
output reg done;

reg [3:0] cur_state, next_state;
localparam WAIT = 4'd0;
localparam PROCESS = 4'd1;
localparam INITIAL = 4'd2;
localparam LOAD = 4'd3;
localparam LOAD_L = 4'd4;

reg [7:0] img_buf[63:0];
reg [2:0] X, Y;
reg [8:0] out_pos;
reg [9:0] average;
reg setwr;

reg [2:0] cmd_reg;
localparam WRITE = 3'd0;
localparam SHIFT_UP = 3'd1;
localparam SHIFT_DOWN = 3'd2;
localparam SHIFT_LEFT = 3'd3;
localparam SHIFT_RIGHT = 3'd4;
localparam AVERAGE = 3'd5;
localparam MIRROR_X = 3'd6;
localparam MIRROR_Y = 3'd7;

always @(posedge clk or posedge reset) begin
    if(reset)
        cur_state <= INITIAL;
    else
        cur_state <= next_state;
end

always @(*) begin
    case (cur_state)
        INITIAL: begin
            next_state <= LOAD;
        end 
        LOAD: begin
            if(IROM_A == 6'd63)
                next_state <= 4'd5;
            else
                next_state <= LOAD; 
        end
        4'd5: begin
            next_state <= WAIT;
        end
        WAIT: begin
            if(cmd_valid)
                next_state <= PROCESS;
            else
                next_state <= WAIT;
        end
        default: begin
            if(cmd_reg == WRITE && done != 1'd1)
                next_state <= PROCESS;
            else
                next_state <= WAIT;
        end
    endcase
end

always @(*) begin
    out_pos <= ({3'd0, Y} <<< 3) + X - 9;
    average <= ({2'd0, img_buf[out_pos]} + {2'd0, img_buf[out_pos + 1]} + {2'd0, img_buf[out_pos + 8]} + {2'd0, img_buf[out_pos + 9]}) >>> 2;
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        busy <= 1'd1;
        IROM_EN <= 1'd0;
        done <= 1'd0;
        IRB_RW <= 1'd1;
        X <= 3'd4;
        Y <= 3'd4;
        setwr <= 1'd0;
    end
    else begin
        case(cur_state)
            INITIAL: begin
                IROM_A <= 6'd0;
            end
            LOAD: begin
                if(IROM_A < 6'd63) begin
                    IROM_A <= IROM_A + 6'd1;
                end
                else begin 
                    IROM_A <= IROM_A;
                end
                if(IROM_A >= 6'd1) begin
                    img_buf[IROM_A - 6'd1] <= IROM_Q;
                end
                else begin end
            end
            4'd5: begin
                img_buf[IROM_A] <= IROM_Q;
                IROM_EN <= 1'd1;
                busy <= 1'd0;
            end
            WAIT: begin
                if(cmd_valid) begin
                    busy <= 1'd1;
                    cmd_reg <= cmd;
                end
                else begin end
            end
            PROCESS: begin
                case(cmd_reg)
                    WRITE: begin
                        if(IRB_A == 6'd63) begin
                            busy <= 1'd0;
                            done <= 1'd1;
                            IRB_RW <= 1'd1;
                            setwr <= 1'd0;
                        end
                        else if(!setwr) begin
                            IRB_RW <= 1'd0;
                            IRB_A <= 6'd0;
                            IRB_D <= img_buf[0];
                            setwr <= 1'd1;
                        end
                        else begin
                            IRB_D <= img_buf[IRB_A + 1];
                            IRB_A <= IRB_A + 6'd1;
                        end
                    end
                    SHIFT_UP: begin
                        busy <= 1'd0;
                        if(Y > 1)
                            Y <= Y - 3'd1;
                        else
                            Y <= Y;
                    end
                    SHIFT_DOWN: begin
                        busy <= 1'd0;
                        if(Y < 7)
                            Y <= Y + 3'd1;
                        else
                            Y <= Y;
                    end
                    SHIFT_LEFT: begin
                        busy <= 1'd0;
                        if(X > 1)
                            X <= X - 3'd1;
                        else
                            X <= X;
                    end
                    SHIFT_RIGHT: begin
                        busy <= 1'd0;
                        if(X < 7)
                            X <= X + 3'd1;
                        else
                            X <= X;
                    end
                    AVERAGE: begin
                        busy <= 1'd0;
                        img_buf[out_pos] <= average;
                        img_buf[out_pos + 1] <= average;
                        img_buf[out_pos + 8] <= average;
                        img_buf[out_pos + 9] <= average;
                    end
                    MIRROR_X: begin
                        busy <= 1'd0;
                        img_buf[out_pos] <= img_buf[out_pos + 8];
                        img_buf[out_pos + 8] <= img_buf[out_pos];
                        img_buf[out_pos + 1] <= img_buf[out_pos + 9]; 
                        img_buf[out_pos + 9] <= img_buf[out_pos + 1]; 
                    end
                    MIRROR_Y: begin
                        busy <= 1'd0;
                        img_buf[out_pos] <= img_buf[out_pos + 1];
                        img_buf[out_pos + 1] <= img_buf[out_pos];
                        img_buf[out_pos + 8] <= img_buf[out_pos + 9]; 
                        img_buf[out_pos + 9] <= img_buf[out_pos + 8]; 
                    end
                endcase
            end
        endcase
    end
end

endmodule

