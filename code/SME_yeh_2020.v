module SME(clk,reset,chardata,isstring,ispattern,valid,match,match_index);
input clk;
input reset;
input [7:0] chardata;
input isstring;
input ispattern;
output match;
output [4:0] match_index;
output valid;
reg match;
reg [4:0] match_index;
reg valid;

localparam HEAD = 8'h5E;
localparam DOLLAR = 8'h24;
localparam SPACE = 8'h20;
localparam DOT = 8'h2E;

reg state;
reg [7:0] string[31:0]; // 32 characters
reg [7:0] pattern[7:0]; // 8 characters
reg [4:0] spaces[31:0]; 
reg [4:0] spa_idx, spa_max;
reg [4:0] str_idx, str_head, str_max;
reg is_str_reset;
reg [2:0] pat_idx, pat_max;
reg [1:0] mode;

always@(posedge clk or posedge reset)
begin

    if(reset) begin
        match <= 0;
        match_index <= 5'd0;
        valid <= 0;

        str_idx <= 5'd0;
        pat_idx <= 3'd0;
        spa_idx <= 5'd0;
        str_max <= 5'd0;
        pat_max <= 3'd0;
        spa_max <= 5'd0;
        str_head <= 5'd0;
        mode <= 2'd0;
        is_str_reset <= 0;
        state <= 0;
    end
    else begin
        case(state)
            0: 
            begin
                if(isstring) 
                begin
                    string[str_idx] <= chardata;
                    str_idx <= str_idx + 5'd1;

                    if(chardata == SPACE) begin
                        spaces[spa_idx] <= str_idx;
                        spa_idx <= spa_idx + 5'd1;
                    end
                    else begin
                        spa_idx <= spa_idx;
                    end
                    is_str_reset <= 1;
                end
                else if(ispattern) 
                begin
                    if (chardata == HEAD) begin
                        mode[1] <= 1;
                    end
                    else if (chardata == DOLLAR) begin
                        mode[0] <= 1;
                    end
                    else begin
                        pattern[pat_idx] <= chardata;
                        pat_idx <= pat_idx + 3'd1;
                    end
                end
                else 
                begin
                    pat_idx <= 3'd0;
                    str_idx <= 5'd0;
                    spa_idx <= 5'd0;
                    str_max <= (is_str_reset) ? (str_idx - 5'd1) : str_max;
                    pat_max <= pat_idx - 3'd1;
                    spa_max <= (is_str_reset) ? (spa_idx - 5'd1) : spa_max;
                    is_str_reset <= 0;
                    state <= 1;
                end
                valid <= 0;
                match <= 0;
            end
            1: 
            begin
                case(mode)
                    2'b00: 
                    begin
                        if((string[str_head + str_idx] == pattern[pat_idx]) || (pattern[pat_idx] == DOT)) 
                        begin
                            if(pat_idx == pat_max) begin
                                valid <= 1;
                                match <= 1;
                                match_index <= str_head;
                                str_idx <= 5'd0;
                                pat_idx <= 3'd0;
                                str_head <= 5'd0;
                                mode <= 2'd0;
                                state <= 0;
                            end
                            else begin
                                str_idx <= str_idx + 5'd1;
                                pat_idx <= (pat_idx == pat_max) ? 3'd0 : (pat_idx + 3'd1);
                            end
                        end
                        else 
                        begin
                            str_head <= str_head + 5'd1;
                            str_idx <= 5'd0;
                            pat_idx <= 3'd0;
                        end

                        if((str_head == str_max) && (pat_idx < pat_max)) begin
                            valid <= 1;
                            match <= 0;
                            match_index <= 5'dx;
                            str_idx <= 5'd0;
                            pat_idx <= 3'd0;
                            str_head <= 5'd0;
                            mode <= 2'd0;
                            state <= 0;
                        end
                        else begin 
                        end
                    end
                    2'b01: begin
                        if((string[str_head + str_idx] == pattern[pat_idx]) || (pattern[pat_idx] == DOT)) 
                        begin
                            if(pat_idx == pat_max) 
                            begin
                                if(string[str_head + str_idx + 5'd1] == SPACE || str_head + str_idx == str_max) begin
                                    valid <= 1;
                                    match <= 1;
                                    match_index <= str_head;
                                    str_idx <= 5'd0;
                                    pat_idx <= 3'd0;
                                    str_head <= 5'd0;
                                    mode <= 2'd0;
                                    state <= 0;
                                end
                                else begin
                                    pat_idx <= 3'd0;
                                    str_head <= str_head + 5'd1;
                                    str_idx <= 5'd0;
                                end
                            end
                            else begin
                                pat_idx <= (pat_idx == pat_max) ? 3'd0 : (pat_idx + 3'd1);
                                str_idx <= str_idx + 5'd1;
                            end
                        end
                        else 
                        begin
                            str_head <= str_head + 5'd1;
                            str_idx <= 5'd0;
                            pat_idx <= 5'd0;
                        end

                        if((str_head == str_max) && (pat_idx < pat_max)) begin
                            valid <= 1;
                            match <= 0;
                            match_index <= 5'dx;
                            str_idx <= 5'd0;
                            pat_idx <= 3'd0;
                            str_head <= 5'd0;
                            mode <= 2'd0;
                            state <= 0;
                        end
                        else begin 
                        end
                    end
                    2'b10: begin
                        if((string[str_head + str_idx] == pattern[pat_idx]) || (pattern[pat_idx] == DOT)) 
                        begin
                            if(pat_idx == pat_max) begin
                                valid <= 1;
                                match <= 1;
                                match_index <= str_head;
                                str_idx <= 5'd0;
                                pat_idx <= 3'd0;
                                spa_idx <= 5'd0;
                                str_head <= 5'd0;
                                mode <= 2'd0;
                                state <= 0;
                            end
                            else begin
                                pat_idx <= (pat_idx == pat_max) ? 3'd0 : (pat_idx + 3'd1);
                                str_idx <= str_idx + 5'd1;
                            end
                        end
                        else 
                        begin
                            pat_idx <= 3'd0;
                            str_idx <= 5'd0;
                            if(spa_idx <= spa_max) begin
                                str_head <= ((spaces[spa_idx] + 5'd1) <= str_max) ? (spaces[spa_idx] + 5'd1) : spaces[spa_idx];
                                spa_idx <= spa_idx + 5'd1;
                            end
                            else begin
                                valid <= 1;
                                match <= 0;
                                match_index <= 5'dx;
                                spa_idx <= 5'd0;
                                str_head <= 5'd0;
                                mode <= 2'd0;
                                state <= 0;
                            end
                        end                    
                    end
                    default: 
                    begin
                        if((string[str_head + str_idx] == pattern[pat_idx]) || (pattern[pat_idx] == DOT)) 
                        begin
                            if((pat_idx == pat_max)) 
                            begin
                                if((string[str_head + str_idx + 5'd1] == SPACE) || (str_head + str_idx == str_max)) 
                                begin
                                    valid <= 1;
                                    match <= 1;
                                    match_index <= str_head;
                                    str_idx <= 5'd0;
                                    pat_idx <= 3'd0;
                                    spa_idx <= 5'd0;
                                    str_head <= 5'd0;
                                    mode <= 2'd0;
                                    state <= 0;
                                end
                                else 
                                begin
                                    pat_idx <= 3'd0;
                                    str_idx <= 5'd0;
                                    if(spa_idx <= spa_max) begin
                                        str_head <= ((spaces[spa_idx] + 5'd1) <= str_max) ? (spaces[spa_idx] + 5'd1) : spaces[spa_idx];
                                        spa_idx <= spa_idx + 5'd1;
                                    end
                                    else begin
                                        valid <= 1;
                                        match <= 0;
                                        match_index <= 5'dx;
                                        spa_idx <= 5'd0;
                                        str_head <= 5'd0;
                                        mode <= 2'd0;
                                        state <= 0;
                                    end
                                end
                            end
                            else begin
                                pat_idx <= (pat_idx == pat_max) ? 3'd0 : (pat_idx + 3'd1);
                                str_idx <= str_idx + 5'd1;
                            end
                        end
                        else begin
                            str_idx <= 5'd0;
                            pat_idx <= 3'd0;
                            if(spa_idx <= spa_max) begin
                                str_head <= ((spaces[spa_idx] + 5'd1) <= str_max) ? (spaces[spa_idx] + 5'd1) : spaces[spa_idx];
                                spa_idx <= spa_idx + 5'd1;
                            end
                            else begin
                                valid <= 1;
                                match <= 0;
                                match_index <= 5'dx;
                                spa_idx <= 5'd0;
                                str_head <= 5'd0;
                                mode <= 2'd0;
                                state <= 0;
                            end
                        end 
                    end
                endcase
            end
        endcase
    end

end

endmodule
