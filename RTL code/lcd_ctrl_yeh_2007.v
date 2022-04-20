module lcd_ctrl(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
input           clk;
input           reset;
input   [7:0]   datain;
input   [2:0]   cmd;
input           cmd_valid;
output reg [7:0]   dataout;
output reg         output_valid;
output reg         busy;

reg [2:0] cur_state, next_state;
localparam WAIT = 3'd0;
localparam PROCESS = 3'd1;

reg [2:0] cmd_reg; 
localparam REFLASH = 3'd0;
localparam LOAD_DATA = 3'd1;
localparam SHIFT_RIGHT = 3'd2;
localparam SHIFT_LEFT = 3'd3;
localparam SHIFT_UP = 3'd4;
localparam SHIFT_DOWN = 3'd5;

reg [2:0] row, col, row_t, col_t;
reg [5:0] img_counter;
reg [7:0] img_buf [35:0];
reg [5:0] pos;

always @(posedge clk or posedge reset) begin
    if(reset) begin
        cur_state <= WAIT;
    end
    else begin
        cur_state <= next_state;
    end
end

always @(*) begin
    case (cur_state)
        WAIT: begin
            if(cmd_valid)
                next_state <= PROCESS;
            else
                next_state <= WAIT;  
        end
        default: begin // PROCESS
            if(img_counter == 6'd35) begin
                next_state <= WAIT;  
            end
            else if(cmd_reg == REFLASH && img_counter == 6'b010010) begin
                next_state <= WAIT;
            end
            else if(cmd_reg != LOAD_DATA && cmd_reg != REFLASH) begin
                next_state <= WAIT;
            end
            else begin
                next_state <= PROCESS;
            end
        end
    endcase
end

always @(*) begin
    row_t <= row + img_counter[5:3];
    col_t <= col + img_counter[2:0];
    pos <= (row_t <<< 1) + (row_t <<< 2) + col_t;  
end

always @(posedge clk or posedge reset) begin
    if(reset) begin
        row <= 3'd2;
        col <= 3'd2;
        img_counter <= 6'd0;
        cmd_reg <= LOAD_DATA;
        busy <= 1'd0;
        output_valid <= 1'd0;
        dataout <= 8'd0;
    end
    else begin
        if(cur_state == WAIT) begin
            if(cmd_valid) begin
                cmd_reg <= cmd;
                busy <= 1'd1;
            end
        end
        else begin // cur_state == PROCESS
            case(cmd_reg)
                REFLASH: begin
                    dataout <= img_buf[pos];
                    if(img_counter[5:3] == 3'd2 && img_counter[2:0] == 3'd2) begin
                        img_counter <= 6'd0;
                        output_valid <= 1'd0;
                        busy <= 1'd0;
                    end
                    else  begin
                        output_valid <= 1'd1;
                        if(img_counter[2:0] == 3'd2) begin
                            img_counter[2:0] <= 3'd0;
                            img_counter[5:3] <= img_counter[5:3] + 3'd1;
                        end
                        else begin
                            img_counter[2:0] <= img_counter[2:0] + 3'd1;
                        end
                    end
                end
                LOAD_DATA: begin
                    img_buf[img_counter] <= datain;
                    if(img_counter == 6'd35) begin
                        img_counter <= 6'd0;
                        busy <= 1'd0;
                    end
                    else begin        
                        img_counter <= img_counter + 1;
                    end
                end
                SHIFT_RIGHT: begin
                    busy <= 1'd0;
                    if(col <= 4) 
                        col <= col + 3'd1;
                    else
                        col <= col;
                end
                SHIFT_LEFT: begin
                    busy <= 1'd0;
                    if(col >= 1) 
                        col <= col - 3'd1;
                    else
                        col <= col;   
                end
                SHIFT_UP: begin
                    busy <= 1'd0;
                    if(row >= 1)
                        row <= row - 3'd1;
                    else
                        row <= row;  
                end
                default: begin
                    busy <= 1'd0;
                    if(row <= 4)
                        row <= row + 3'd1;
                    else
                        row <= row;    
                end
            endcase
        end
    end
end

endmodule
