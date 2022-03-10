module TPA(clk, reset_n, 
	   SCL, SDA, 
	   cfg_req, cfg_rdy, cfg_cmd, cfg_addr, cfg_wdata, cfg_rdata);
input 		clk; 
input 		reset_n;
// Two-Wire Protocol slave interface 
input 		SCL;  
inout		SDA;

// Register Protocal Master interface 
input		cfg_req;
output		cfg_rdy;
input		cfg_cmd;
input	[7:0]	cfg_addr;
input	[15:0]	cfg_wdata;
output	[15:0]  cfg_rdata;

reg	[15:0] Register_Spaces	[0:255];
reg cfg_rdy;
reg [15:0] cfg_rdata;

localparam Idle = 4'd0;
localparam RIM_Write = 4'd1;
localparam RIM_Read = 4'd2;
localparam TWM_Write_A = 4'd4;
localparam TWM_Write_D = 4'd5;
localparam TWM_Read_A = 4'd6;
localparam TWM_Read_D_0 = 4'd7;
localparam TWM_Read_D_1 = 4'd8;
localparam TWM_Read_D_2 = 4'd9;

reg SDA_reg;
reg [7:0] TWM_A;
reg [3:0] cnt;
reg [3:0] cur_state, next_state;

assign SDA = (cur_state >= 4'd7 && cur_state <= 4'd9) ? SDA_reg : 1'bz;

always @(posedge clk or negedge reset_n) 
begin

	if(!reset_n)
	begin
		cfg_rdy <= 0;
		cfg_rdata <= 16'hzz;
		cnt <= 4'd0;
		TWM_A <= 8'hzz;
		SDA_reg <= 1'bz;
	end
	else
	begin

		case (cur_state)
			Idle: begin
				cfg_rdy <= 0;
				cfg_rdata <= 16'hzz;
				cnt <= 4'd0;
				TWM_A <= 8'hzz;
				SDA_reg <= 1'bz;
			end
			RIM_Write: begin
				cfg_rdy <= 1;
				Register_Spaces[cfg_addr] <= cfg_wdata;
			end
			RIM_Read: begin
				cfg_rdy <= 1;
				cfg_rdata <= Register_Spaces[cfg_addr];
			end
			TWM_Write_A: begin
				cfg_rdy <= 0;
				cnt <= (cnt == 4'd7) ? 4'd0 : cnt + 4'd1;
				TWM_A[cnt] <= SDA;
			end
			TWM_Write_D: begin
				cnt <= (cnt == 4'd15) ? 4'd0 : cnt + 4'd1;
				Register_Spaces[TWM_A][cnt] <= SDA;
			end
			TWM_Read_A: begin
				cfg_rdy <= 0;
				cnt <= (cnt == 4'd7) ? 4'd0 : cnt + 4'd1;
				TWM_A[cnt] <= SDA;
			end
			TWM_Read_D_0: begin
				cnt <= (cnt == 4'd2) ? 4'd0 : cnt + 4'd1;
				if (cnt == 4'd1) SDA_reg <= 1;
				else if (cnt == 4'd2) SDA_reg <= 0;
				else SDA_reg <= 1'bz;
			end
			TWM_Read_D_1: begin
				cnt <= (cnt == 4'd15) ? 4'd0 : cnt + 4'd1;
				SDA_reg <= Register_Spaces[TWM_A][cnt];
			end
			TWM_Read_D_2: begin
				SDA_reg <= 1;
			end
			default: begin // 3 : do nothing
			end
		endcase

	end

end
/* FSM */
always @(*) begin
	next_state = cur_state;
	case (cur_state)
		4'd0: begin
			if(cfg_req) next_state = (cfg_cmd) ? 1 : 2;
			else if(!SDA) next_state = 3;
		end
		4'd3: next_state = (SDA) ? 4 : 6;
		4'd4: if(cnt == 4'd7) next_state = 5;
		4'd5: if(cnt == 4'd15) next_state = 0;
		4'd6: if(cnt == 4'd7) next_state = 7;
		4'd7: if(cnt == 4'd2) next_state = 8;
		4'd8: if(cnt == 4'd15) next_state = 9;
		4'd9: next_state = 0;
		default: begin // 1 and 2
			if(!SDA) next_state = 3;
			else if(cfg_rdy) next_state = 0;
		end
	endcase
end

always @(posedge clk or negedge reset_n) begin
	if(!reset_n) cur_state <= 4'd0;
	else cur_state <= next_state;
end


endmodule