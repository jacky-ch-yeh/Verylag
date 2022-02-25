module DT(
	input 			clk, 
	input			reset,
	output	reg		done ,
	output	reg		sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	input		[15:0]	sti_di,
	output	reg		res_wr ,
	output	reg		res_rd ,
	output	reg 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	input		[7:0]	res_di
	);

reg [5:0] cur_state, next_state;
reg [3:0] index;
reg sig;
reg [6:0] x, y;
reg [7:0] min;

wire [13:0] mul;
assign mul = y * 128 + x; 

always @(posedge clk or negedge reset) begin
	if(!reset) begin
		cur_state <= 1'd0;
	end
	else begin
		cur_state <= next_state;
	end
end

always @(*) begin
	case (cur_state)
		0: begin
			if(res_addr == 14'd16383)
				next_state <= 3;
			else
				next_state <= 1;
		end
		1: begin
			// if(res_addr == 14'd16383)
			// 	next_state <= 3;
			if(index == 0)
				next_state <= 2;
			else
				next_state <= 1;
		end
		2: begin
			next_state <= 0;
		end
		3: begin
			if(y == 7'd127 && x == 7'd127)
				next_state <= 11;
			else
				next_state <= 4;
		end
		4: begin
			if(res_di == 8'd0)
				next_state <= 3;
			else
				next_state <= 5;
		end
		5: begin
			next_state <= 6;
		end
		6: begin
			next_state <= 7;
		end
		7: begin
			next_state <= 8;
		end
		8: begin
			next_state <= 9;
		end
		9: begin
			next_state <= 3;
		end
		10: begin
			if(y == 7'd0 && x == 7'd0)
				next_state <= 17;
			else
				next_state <= 11;
		end
		11: begin
			if(res_di == 8'd0)
				next_state <= 10;
			else
				next_state <= 12;
		end
		12: begin
			next_state <= 13;
		end
		13: begin
			next_state <= 14;
		end
		14: begin
			next_state <= 15;
		end
		15: begin
			next_state <= 16;
		end
		default: begin
			next_state <= 10;
		end
	endcase
end

/* state 0 ~ 2 : Initialize the image pixels */
/* state 3 ~ 9 : Forward pass */
/* state 10 ~ 16 : Backward pass */

always @(posedge clk or negedge reset) begin
	if(!reset) begin
		sti_rd <= 1'd0;
		res_wr <= 1'd0;
		res_rd <= 1'd0;
		sti_addr <= 10'd0;
		res_addr <= 14'd0;
		res_do <= 8'd0;
		done <= 1'd0;
		index <= 4'd15;
		sig <= 1'd0;
		x <= 7'd0;
		y <= 7'd0;
	end
	else begin
		case (cur_state)
			0: begin
				sti_rd <= 1'd1;
				sig <= 1'd1;
				if(sig) 
					sti_addr <= sti_addr + 10'd1; 
				else
					sti_addr <= 10'd0;
			end
			1: begin
				sti_rd <= 1'd0;
				res_wr <= 1'd1;
				res_addr <= ({4'd0, sti_addr} <<< 4) + 4'd15 - index; // from left to right
				res_do <= sti_di[index];
				if(index == 0)begin
					index <= 4'd15;
				end
				else begin
					index <= index - 4'd1;
				end
			end
			2: begin
				res_wr <= 1'd0;
			end
			3: begin
				res_rd <= 1'd1;
				res_addr <= mul;
			end
			4: begin
				/* update x & y */
				if(y == 7'd127 && x == 7'd127) begin
				end	
				else if(x == 7'd127) begin
					x <= 7'd0;
					y <= y + 7'd1;
				end	
				else begin
					x <= x + 7'd1;
				end
				/* judge if it is object */	
				if(res_di == 8'd0) begin
					res_rd <= 1'd0;		
				end
				else begin
					res_addr <= res_addr - 14'd1; // address at W
				end
			end
			5: begin
				res_addr <= res_addr - 14'd128; // address at NW
				min <= res_di;
			end
			6: begin
				res_addr <= res_addr + 14'd1; // address at N
				if(res_di < min)
					min <= res_di;
				else
					min <= min;
			end
			7: begin
				res_addr <= res_addr + 14'd1; // address at NE
				if(res_di < min)
					min <= res_di;
				else
					min <= min;
			end
			8: begin
				res_rd <= 1'd0;
				res_wr <= 1'd1;
				res_addr <=  res_addr + 14'd127; // (+ 128 - 1), address back to target
				if(res_di < min)
					res_do <= res_di + 14'd1;
				else
					res_do <= min + 14'd1;
			end
			9: begin
				res_wr <= 1'd0;
			end
			10: begin
				res_rd <= 1'd1;
				res_addr <= mul;
			end
			11: begin
				/* update x & y */
				if(y == 7'd0 && x == 7'd0) begin
				end	
				else if(x == 7'd0) begin
					x <= 7'd127;
					y <= y - 7'd1;
				end	
				else begin
					x <= x - 7'd1;
				end
				/* judge if it is object */	
				if(res_di == 8'd0) begin
					res_rd <= 1'd0;		
				end
				else begin
					min <= res_di;
					res_addr <= res_addr + 14'd1; // address at E
				end
			end
			12: begin
				res_addr <= res_addr + 14'd128; // address at SE
				if(res_di + 8'd1 < min)
					min <= res_di + 8'd1;
				else
					min <= min;
			end
			13: begin
				res_addr <= res_addr - 14'd1; // address at S
				if(res_di + 8'd1 < min)
					min <= res_di + 8'd1;
				else
					min <= min;
			end
			14: begin
				res_addr <= res_addr - 14'd1; // address at SW
				if(res_di + 8'd1 < min)
					min <= res_di + 8'd1;
				else
					min <= min;
			end
			15: begin
				res_rd <= 1'd0;
				res_wr <= 1'd1;
				res_addr <=  res_addr - 14'd127; // address back to target
				if(res_di + 14'd1 < min)
					res_do <= res_di + 14'd1;
				else
					res_do <= min;
			end
			16: begin
				res_wr <= 1'd0;
			end
			// 17: begin
			// 	done <= 1'd1;
			// end
			default: begin
				done <= 1'd1;
			end
		endcase
	end
end

endmodule
