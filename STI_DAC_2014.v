module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       pixel_finish, pixel_dataout, pixel_addr,
	       pixel_wr);

input		clk, reset;
input		load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input		pi_fill;
output reg so_data, so_valid;

output reg pixel_finish, pixel_wr;
output reg [7:0] pixel_addr;
output reg [7:0] pixel_dataout;

//==============================================================================

reg [2:0] cur_state, next_state;
reg [4:0] pi_index; // maximum 32 bit
reg [4:0] pi_index_term; // ex: 16-bit -> 15，處理so_data 的 output時，index的termination point
reg msb; 
reg [31:0] pi_reg; // so_data output的暫存
reg [0:31] pixel_reg; // 由左到右，照著pi_reg output的順序來存，之後用來write mem的，因為pi_reg可能由左到右output，也可能由右到左
reg [4:0] target_state; // 如果長度是8-bit，就為0，24-bit，就為2
reg [2:0] state; // 用來控制要把pixel_dataout 存 pixel_reg的哪個部分
reg set1; // 收到新的LOAD後，第一次進cur_state 1 用來先把pixel_reg存好的控制訊號 為1後，每次進cur_state 0才會操作write mem
reg set2; // 用來控制pixel_addr 第一次不用 + 1(一開始是0)，之後每次要write時加一
reg set3; // 用來產生間格，因為不能連續write mem，pixel_wr升起並write後，一定要先讓pixel_wr變0，之後才能再write，所以這是控制每次write完要停在同個state，然後set3為1時可以切換state(這裡的state不是cur_state，而是要write mem用的state)

always @(posedge clk or posedge reset) begin
	if(reset)
		cur_state <= 0;
	else
		cur_state <= next_state;
end

always @(*) begin
	case (cur_state)
		0: begin
			if(load) begin
				next_state <= 1;
			end
			else if(pi_end) begin
				next_state <= 2;
			end
			else begin
				next_state <= 0;
			end
		end
		1: begin
			if(pi_index == pi_index_term) 
				next_state <= 0;	
			else 
				next_state <= 1;
		end
		2: begin
			next_state <= 3;
		end
		default: begin
			next_state <= 2;
		end
	endcase
end

always @(posedge clk or posedge reset) begin
	if(reset) begin
		so_valid <= 1'd0;
		so_data <= 1'd0;
		pixel_finish <= 1'd0;
		pixel_wr <= 1'd0;
		pixel_addr <= 8'd0;
		pixel_dataout <= 8'd0;
		pi_reg <= 32'd0;
		pixel_reg <= 32'd0;
		pi_index <= 5'd0;
		set1 <= 1'd0;
		set2 <= 1'd0; 
		set3 <= 1'd0;
		state <= 3'd0;
	end
	else begin
		case (cur_state)
			0: begin
				msb <= pi_msb; // 1 -> addition, 0 -> subtraction
				so_valid <= 1'd0;
				pixel_wr <= 1'd0;
				set1 <= 1'd0;
				set3 <= 1'd0;
				state <= 3'd0;
				if(load) begin
					case (pi_length)
						2'b00: begin // 8-bit
							target_state <= 5'd0;
							if(pi_msb) begin
								pi_index <= 5'd7;
								pi_index_term <= 5'd0;
							end
							else begin
								pi_index <= 5'd0;
								pi_index_term <= 5'd7;
							end
							if(pi_low) begin
								pi_reg[7:0] <= pi_data[15:8];
							end
							else begin
								pi_reg[7:0] <= pi_data[7:0];
							end
						end
						2'b01: begin // 16-bit
							target_state <= 5'd1;
							if(pi_msb) begin
								pi_index <= 5'd15;
								pi_index_term <= 5'd0;
							end
							else begin
								pi_index <= 5'd0;
								pi_index_term <= 5'd15;
							end
							pi_reg <= pi_data;
						end
						2'b10:begin //24-bit
							target_state <= 5'd2;
							if(pi_msb) begin
								pi_index <= 5'd23;
								pi_index_term <= 5'd0;
							end
							else begin
								pi_index <= 5'd0;
								pi_index_term <= 5'd23;
							end
							if(pi_fill) begin
								pi_reg <= {8'd0, pi_data, 8'd0};
							end
							else begin
								pi_reg <= {16'd0, pi_data};
							end
						end
						2'b11: begin // 32-bit
							target_state <= 5'd3;
							if(pi_msb) begin
								pi_index <= 5'd31;
								pi_index_term <= 5'd0;
							end
							else begin
								pi_index <= 32'd0;
								pi_index_term <= 32'd31;
							end
							if(pi_fill) begin
								pi_reg <= {pi_data, 16'd0};
							end
							else begin
								pi_reg <= {16'd0, pi_data};
							end
						end
					endcase
				end
				else begin end
			end
			1: begin
				so_valid <= 1'd1;
				so_data <= pi_reg[pi_index];
				if(pi_index == pi_index_term) begin
				end
				else begin
					if(msb) begin
						pi_index <= pi_index - 5'd1;
					end 
					else begin
						pi_index <= pi_index + 5'd1;
					end
				end
				if(msb) begin
					case(target_state)
						3'd0: begin 
							pixel_reg <= {pi_reg[7:0], 24'd0};
						end
						3'd1: begin 
							pixel_reg <= {pi_reg[15:0], 16'd0};
						end
						3'd2: begin 
							pixel_reg <= {pi_reg[23:0], 8'd0};
						end
						3'd3: begin 
							pixel_reg <= pi_reg[31:0];
						end
					endcase
					set1 <= 1'd1; // 一開始先 set pixel_reg
				end
				else begin // reverse
					pixel_reg <= {pi_reg[0], pi_reg[1], pi_reg[2], pi_reg[3], pi_reg[4], pi_reg[5], pi_reg[6], pi_reg[7], pi_reg[8], pi_reg[9], pi_reg[10], pi_reg[11], pi_reg[12], pi_reg[13], pi_reg[14], pi_reg[15], pi_reg[16], pi_reg[17], pi_reg[18], pi_reg[19], pi_reg[20], pi_reg[21], pi_reg[22], pi_reg[23], pi_reg[24], pi_reg[25], pi_reg[26], pi_reg[27], pi_reg[28], pi_reg[29], pi_reg[30], pi_reg[31]};
					set1 <= 1'd1;
				end
				if(set1) begin // set1 == 1 代表pixel_reg set好了
					if(state == target_state + 1) begin
						pixel_wr <= 1'd0;
					end
					else begin
						case(state)
							3'd0: begin
								pixel_dataout <= pixel_reg[0:7];
								if(!set3) begin
									state <= 3'd0;
									pixel_wr <= 1'd1;
									set3 <= 1'd1;
									set2 <= 1'd1;
									if(set2) begin
										pixel_addr <= pixel_addr + 8'd1;
									end
									else begin end
								end
								else if(state == target_state + 1) begin
									pixel_wr <= 1'd0;
								end
								else begin
									pixel_wr <= 1'd0;
									set3 <= 1'd0;
									state <= 3'd1;
								end
							end
							3'd1: begin
								pixel_dataout <= pixel_reg[7:15];
								if(!set3) begin
									state <= 3'd1;
									pixel_wr <= 1'd1;
									set3 <= 1'd1;
									pixel_addr <= pixel_addr + 8'd1;
								end
								else if(state == target_state + 1) begin
									pixel_wr <= 1'd0;
								end
								else begin
									pixel_wr <= 1'd0;
									set3 <= 1'd0;
									state <= 3'd2;
								end
							end
							3'd2: begin
								pixel_dataout <= pixel_reg[16:23];
								if(!set3) begin
									state <= 3'd2;
									pixel_wr <= 1'd1;
									set3 <= 1'd1;
									pixel_addr <= pixel_addr + 8'd1;
								end
								else if(state == target_state + 1) begin
									pixel_wr <= 1'd0;
								end
								else begin
									pixel_wr <= 1'd0;
									set3 <= 1'd0;
									state <= 3'd3;
								end
							end
							3'd3: begin
								pixel_dataout <= pixel_reg[24:31];
								if(!set3) begin
									state <= 3'd3;
									pixel_wr <= 1'd1;
									set3 <= 1'd1;
									pixel_addr <= pixel_addr + 8'd1;
								end
								else begin
									pixel_wr <= 1'd0;
									set3 <= 1'd0;
									state <= 3'd4;
								end
							end
							3'd4: begin
							end
						endcase
					end
				end
				else begin end
			end
			/* 未滿255個byte 剩下補0 */
			2: begin
				if(pixel_addr < 8'd255) begin
					pixel_wr <= 1'd1;
					pixel_addr <= pixel_addr + 32'd1;
					pixel_dataout <= 8'd0;
				end
				else begin
					pixel_wr <= 1'd0;
					pixel_finish <= 1'd1;
				end
			end
			default: begin
				pixel_wr <= 1'd0;
			end
		endcase
	end
end

endmodule
