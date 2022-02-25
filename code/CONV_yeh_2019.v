
`timescale 1ns/10ps

module  CONV(
	input		clk,
	input		reset,
	output reg busy,	
	input		ready,	
			
	output reg [11:0] iaddr,
	input signed [19:0] idata,	
	
	output reg cwr,
	output reg [11:0] caddr_wr,
	output reg  [19:0] cdata_wr,
	
	output reg crd,
	output reg [11:0] caddr_rd,
	input signed [19:0] cdata_rd,
	
	output reg [2:0] csel
	);

reg [4:0] cur_state, next_state;
reg signed [6:0] row, col;
reg signed [2:0] rofs, cofs;
wire signed [11:0] mul_addr;
assign mul_addr = ((row + rofs) <<< 6) + (col + cofs);

reg signed [39:0] conv;
reg signed [19:0] kernel [3:0];

localparam signed BIAS = 20'h01310; //4int 16dec

always @(posedge clk or posedge reset) begin
	if(reset) begin
		cur_state <= 0;	
	end
	else begin
		cur_state <= next_state;
	end
end

always @(*) begin
	case(cur_state)
		0: begin
			if(row + rofs < 0 || row + rofs > 63 || col + cofs < 0 || col + cofs > 63) begin // zero pad
				next_state <= 3;
			end
			else begin 
				next_state <= 1;
			end
		end
		1: begin
			next_state <= 2;
		end
		2: begin
			next_state <= 3;
		end
		3: begin
			if(rofs == 2 && cofs == 2) begin // one gray pixel are done (3x3)
				next_state <= 4;
			end	
			else begin
				next_state <= 0;
			end
		end
		4: begin
			next_state <= 5;	
		end
		5: begin
			if(row == 62 && col == 62) begin // all gray pixel are done
				next_state <= 6;
			end
			else begin
				next_state <= 0;
			end	
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
			next_state <= 10;
		end
		10: begin
			next_state <= 11;
		end
		11: begin
			next_state <= 12;
		end
		12: begin
			next_state <= 13;
		end
		default: begin
			if(row == 62 && col == 62) begin
				next_state <= 14;
			end
			else begin
				next_state <= 6;
			end
		end
	endcase
end

always @(posedge clk or posedge reset) 
begin
	if (reset) begin
		busy <= 0;
		csel <= 3'b000;
		caddr_rd <= 0;
		crd <= 0;
		cdata_wr <= 0;
		caddr_wr <= 0;
		cwr <= 0;
		iaddr <= 0;

		row <= -1;
		col <= -1;
		rofs <= 0;
		cofs <= 0;
		conv <= 0;
	end
	else 
	begin
		case (cur_state) 
			0: begin 
				csel <= 3'b000;
				cwr <= 0;
				busy <= 1;
			end
			1: begin // decide the # of grayscale pixel
				iaddr <= mul_addr;
				case((rofs * 3 + cofs))
					0: kernel[0] <= 20'h0A89E;
					1: kernel[0] <= 20'h092D5;
					2: kernel[0] <= 20'h06D43;
					3: kernel[0] <= 20'h01004;
					4: kernel[0] <= 20'hF8F71;
					5: kernel[0] <= 20'hF6E54;
					6: kernel[0] <= 20'hFA6D7;
					7: kernel[0] <= 20'hFC834;
					default: kernel[0] <= 20'hFAC19;
				endcase
			end
			2: begin // calculate convolution
				conv <= conv + idata * kernel[0];
			end
			3: begin // update offset
				if(rofs == 2 && cofs == 2) begin
					rofs <= 0;
					cofs <= 0;
				end
				else if(cofs == 2) begin
					cofs <= 0;
					rofs <= rofs + 1;
				end
				else begin
					cofs <= cofs + 1;
				end
			end
			4: begin // add BIAS
				conv <= {conv[39:36], conv[35:16] + BIAS, conv[15:0]};
			end
			5: begin // write conv result into mem 0 with ReLU and update row & col
				conv <= 0; // Reset conv
				csel <= 3'b001;
				cwr <= 1;
				caddr_wr <= (row + 1) * 64 + col + 1;
				if(conv[35] == 1) begin //ReLU
					cdata_wr <= 0;
				end
				else begin
					cdata_wr <= {conv[35:16]} + ((conv[15] == 1) ? 1 : 0);
				end
				if(row == 62 && col == 62) begin
					row <= 0;
					col <= 0;
				end
				else if(col == 62) begin
					col <= -1;
					row <= row + 1;
				end
				else begin
					col <= col + 1;
				end
			end
			/* start max pooling */
			6: begin // ask for the left-top
				cwr <= 0;
				crd <= 1;
				csel <= 3'b001;
				caddr_rd <= mul_addr;
				cofs <= cofs + 1;
				// busy <= 0; // test mem 0
			end
			7: begin // ask for the right-top
				kernel[0] <= cdata_rd;
				caddr_rd <= mul_addr;
				cofs <= 0;
				rofs <= rofs + 1;	
			end // ask for the left-bot
			8: begin
				kernel[1] <= cdata_rd;
				caddr_rd <= mul_addr;
				cofs <= cofs + 1;
			end
			9: begin // ask for the right-bot
				kernel[2] <= cdata_rd;
				caddr_rd <= mul_addr;
				/* reset offset */
				rofs <= 0;
				cofs <= 0;
			end
			10: begin // bubble sort from kernel 0 to 3, kernel here means the data being max pooled
				crd <= 0;
				kernel[3] <= cdata_rd;
				if(kernel[0] > kernel[1]) begin
					kernel[0] <= kernel[1];
					kernel[1] <= kernel[0];
				end
				else begin
					kernel[0] <= kernel[0];
					kernel[1] <= kernel[1];
				end
			end
			11: begin
				if(kernel[1] > kernel[2]) begin
					kernel[1] <= kernel[2];
					kernel[2] <= kernel[1];
				end
				else begin
					kernel[1] <= kernel[1];
					kernel[2] <= kernel[2];
				end
			end
			12: begin // now kernel 3 is the maximum
				if(kernel[2] > kernel[3]) begin
					kernel[2] <= kernel[3];
					kernel[3] <= kernel[2];
				end
				else begin
					kernel[2] <= kernel[2];
					kernel[3] <= kernel[3];
				end
			end
			13: begin // write mem 1 and update row & col
				cwr <= 1;
				csel <= 3'b011;	
				caddr_wr <= (row >>> 1) * 32 + (col >>> 1);
				cdata_wr <= kernel[3];
				if(row == 62 && col == 62) begin
					row <= 0;
					col <= 0;
				end
				else if(col == 62) begin
					col <= 0;
					row <= row + 2;
				end
				else begin
					col <= col + 2;
				end
			end
			default: begin // complete
				cwr <= 0;
				busy <= 0;
			end
		endcase
	end
end

endmodule




