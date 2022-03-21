
`timescale 1ns/10ps

module  CONV(
	input				clk,
	input				reset,
	output reg			busy,	
	input				ready,	
			
	output wire [11:0] 	iaddr,
	input [19:0] 		idata,	
	
	output reg	 		cwr,
	output wire [11:0] 	caddr_wr,
	output reg [19:0] 	cdata_wr,
	
	output reg 			crd,
	output wire [11:0] 	caddr_rd,
	input [19:0] 		cdata_rd,
	
	output reg [2:0] 	csel
	);

localparam Idle = 3'b000;
localparam Layer0 = 3'b001;
localparam Layer1 = 3'b011;
localparam Bias = 20'h01310;

reg [2:0] cur_state, next_state;
reg en;
reg signed [6:0] x, y;
reg signed [3:0] x_t, y_t;
wire [11:0] addr;
wire [9:0] addr_m;
reg signed [19:0] gray_val, kernel;
wire signed [39:0] conv;
reg signed [39:0] conv_reg;
wire signed [39:0] conv_biased;

assign addr = ((y + y_t) <<< 6) + (x + x_t);
assign iaddr = addr;
assign caddr_rd = addr;
assign addr_m = (y <<< 4) + (x >>> 1);
assign caddr_wr = (csel == Layer1) ? addr_m : addr;
assign conv = gray_val * kernel;
assign conv_biased = conv_reg + conv + {4'd0, Bias, 16'd0};

always @(*) begin
	next_state = cur_state;
	case (cur_state)
		3'd0: if (ready) next_state = 3'd1;
		3'd1: if (x_t == 4'd1 && y_t == 4'd1) next_state = 3'd2;
		3'd2: next_state = 3'd3;
		3'd3: next_state = (x == 7'd63 && y == 7'd63) ? 3'd4 : 3'd1;
		3'd4: if (x_t == 4'd1 && y_t == 4'd1) next_state = 3'd5;
		3'd5: next_state = 3'd6;
		default: next_state = 3'd4;
	endcase
end

always @(posedge clk or posedge reset) begin

	if (reset)
	begin
		busy <= 0;
		cwr <= 0;
		crd <= 0;
		csel <= Idle;
		cdata_wr <= 20'd0;
		x <= 7'd0;
		y <= 7'd0;
		x_t <= -4'd1;
		y_t <= -4'd1;
		conv_reg <= 40'd0;
		en <= 0;
	end
	else
	begin
		case (cur_state)
			3'd0: begin
				busy <= (ready) ? 1 : busy;
			end 
			3'd1: begin
				gray_val <= (x + x_t >= 0 && x + x_t <= 63 && y + y_t >= 0 && y + y_t <= 63) ? idata : 0;
				case ({x_t, y_t})
					{-4'd1, -4'd1}: kernel <= 20'h0A89E;
					{4'd0, -4'd1}: kernel <= 20'h092D5;
					{4'd1, -4'd1}: kernel <= 20'h06D43;
					{-4'd1, 4'd0}: kernel <= 20'h01004;
					{4'd0, 4'd0}: kernel <= 20'hF8F71;
					{4'd1, 4'd0}: kernel <= 20'hF6E54;
					{-4'd1, 4'd1}: kernel <= 20'hFA6D7;
					{4'd0, 4'd1}: kernel <= 20'hFC834;
					default: kernel <= 20'hFAC19;
				endcase

				en <= 1;
				conv_reg <= (en) ? conv_reg + conv : 40'd0;

				if (x_t == 4'd1 && y_t == 4'd1) begin
					x_t <= 4'd0;
					y_t <= 4'd0;
				end
				else if (x_t == 4'd1) begin
					x_t <= -4'd1;
					y_t <= y_t + 4'd1;
				end
				else begin
					x_t <= x_t + 4'd1;
				end
			end
			3'd2: begin
				cwr <= 1;
				csel <= Layer0;
				en <= 0;
				if (conv_biased <= 0)
					cdata_wr <= 20'd0;
				else
					cdata_wr <= (conv_biased[15]) ? conv_biased[32:16] + 1 : conv_biased[35:16];
			end
			3'd3: begin
				cwr <= 0;		
				if (x == 7'd63 && y == 7'd63) begin
					crd <= 1;
					csel <= Layer0;
					en <= 0;
					x <= 7'd0;
					y <= 7'd0;
					x_t <= 4'd0;
					y_t <= 4'd0;
				end
				else begin
					csel <= Idle;
					x_t <= -4'd1;
					y_t <= -4'd1;
					if (x == 7'd63) begin
						x <= 7'd0;
						y <= y + 7'd1;
					end
					else begin
						x <= x + 7'd1;
					end
				end
			end
			3'd4: begin
				en <= 1;
				if (!en) begin
					conv_reg <= cdata_rd;
				end
				else begin
					conv_reg <= (cdata_rd > conv_reg) ? cdata_rd : conv_reg;
				end

				if (x_t == 4'd1 && y_t == 4'd1) begin
					x_t <= 4'd0;
					y_t <= 4'd0;
					crd <= 0;
				end
				else if (x_t == 4'd1) begin
					x_t <= 4'd0;
					y_t <= 4'd1;
				end
				else begin
					x_t <= 4'd1;
				end
			end
			3'd5: begin
				csel <= Layer1;
				cwr <= 1;
				cdata_wr <= conv_reg[19:0];
			end
			default: begin
				csel <= Layer0;
				cwr <= 0;
				crd <= 1;
				en <= 0;

				if (x == 7'd62 && y == 7'd62) begin
					busy <= 0;
				end
				else if (x == 7'd62) begin
					x <= 7'd0;
					y <= y + 7'd2;
				end
				else begin
					x <= x + 7'd2;
				end
			end
		endcase
	end

end

always @(posedge clk or posedge reset) begin
	if (reset) cur_state <= 3'd0;
	else cur_state <= next_state;
end

endmodule