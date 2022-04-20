module LCD_CTRL(clk, reset, datain, cmd, cmd_valid, dataout, output_valid, busy);
   input clk;
   input reset;
   input [7:0] datain;
   input [2:0] cmd;
   input cmd_valid;
   output reg [7:0] dataout;
   output reg output_valid;
   output reg busy;

   reg [2:0] cur_state, next_state;
   localparam WAIT = 3'd0;
   localparam PROCESS = 3'd1;

   reg [2:0] cmd_reg;
   localparam LOAD_DATA = 3'd0;
   localparam ZOOM_IN = 3'd1;
   localparam ZOOM_FIT = 3'd2;
   localparam SHIFT_RIGHT = 3'd3;
   localparam SHIFT_LEFT = 3'd4;
   localparam SHIFT_UP = 3'd5;
   localparam SHIFT_DOWN = 3'd6;

   reg mode;
   localparam FIT = 0;
   localparam IN = 1;

   reg [3:0] x, y, x_t, y_t;
   reg [6:0] outpos;
   localparam XC = 4'd6;
   localparam YC = 4'd5;

   reg [7:0] img_buf [107:0];
   reg [6:0] img_counter;

   always @(posedge clk or posedge reset) begin
      if(reset)
         cur_state <= WAIT;
      else
         cur_state <= next_state;
   end

   always @(*) begin
      case(cur_state)
         WAIT: begin
            if(cmd_valid)
               next_state <= PROCESS;
            else
               next_state <= WAIT;
         end
         default: begin
            if((cmd_reg == ZOOM_FIT && x_t == 4'd10 && y_t == 4'd7) || (cmd_reg == ZOOM_IN && img_counter[5:3] == 3'd3 && img_counter[2:0] == 3'd3))
               next_state <= WAIT;
            else
               next_state <= PROCESS;
         end
      endcase
   end

   always @(*) begin
      case(cmd_reg)
         ZOOM_FIT: begin
            outpos <= {1'd0, y_t} * 5'd12 + {1'd0, x_t};
         end
         default: begin
            outpos <= {1'd0, y - 4'd2 + img_counter[2:0]} * 5'd12 + {1'd0, x - 4'd2 + img_counter[5:3]};
         end
      endcase
      // if(cmd_reg == ZOOM_FIT) begin // pos for ZOOM_FIT mode
      //    outpos <= {1'd0, y_t} * 5'd12 + {1'd0, x_t};
      // end
      // else begin end
      // if(cmd_reg == ZOOM_IN) begin // pos for ZOOM_IN mode
      //    outpos <= {1'd0, y - 4'd2 + img_counter[2:0]} * 5'd12 + {1'd0, x - 4'd2 + img_counter[5:3]};
      // end
      // else begin end
   end

   always @(posedge clk or posedge reset) begin
      if(reset) begin
         dataout <= 8'd0;
         output_valid <= 1'd0;
         busy <= 1'd0;
         x <= XC;
         y <= YC;
         x_t <= 4'd1;
         y_t <= 4'd1;
         img_counter <= 7'd0;
      end
      else begin
         case(cur_state)
            WAIT: begin
               if(cmd_valid) begin
                  busy <= 1'd1;
                  output_valid <= 1'd0;
                  cmd_reg <= cmd;
                  if(mode == FIT && cmd == ZOOM_IN) begin
                     x <= 4'd6;
                     y <= 4'd5;
                  end
               end
            end
            PROCESS: begin
               case(cmd_reg)
                  LOAD_DATA: begin
                     img_buf[img_counter] <= datain;
                     if(img_counter == 7'd107) begin
                        mode <= FIT;
                        cmd_reg <= ZOOM_FIT;
                        x_t <= 4'd1;
                        y_t <= 4'd1;
                        img_counter <= 7'd0;
                     end
                     else begin
                        img_counter <= img_counter + 7'd1;
                     end
                  end
                  ZOOM_IN: begin
                     mode <= IN;
                     /* Output */
                     dataout <= img_buf[outpos];
                     /* img_counter[5:3] stands for the offset of x */
                     /* img_counter[2:0] stands for the offset of y */
                     if(img_counter[5:3] == 3'd3 && img_counter[2:0] == 3'd3) begin
                        img_counter <= 7'd0;
                        busy <= 1'd0;
                     end
                     else begin
                        output_valid <= 1'd1;
                        if(img_counter[5:3] == 3'd3) begin
                           img_counter[5:3] <= 3'd0;
                           img_counter[2:0] <= img_counter[2:0] + 3'd1;
                        end
                        else begin
                           img_counter[5:3] <= img_counter[5:3] + 3'd1;
                        end 
                     end
                  end
                  ZOOM_FIT: begin
                     mode <= FIT;
                     /* Output */
                     dataout <= img_buf[outpos];
                     /* x_t & y_t are only used in calculating position in ZOOM_FIT mode */
                     if(x_t == 4'd10 && y_t == 4'd7) begin
                        busy <= 1'd0;
                        x_t <= 4'd1;
                        y_t <= 4'd1;
                     end
                     else begin
                        output_valid <= 1'd1;
                        if(x_t == 4'd10) begin
                           x_t <= 4'd1;
                           y_t <= y_t + 4'd2;
                        end
                        else begin
                           x_t <= x_t + 4'd3;
                        end
                     end
                  end
                  /* Only in ZOOM_IN mode can shift cmd be valid */
                  /* Otherwise just ouput */
                  SHIFT_RIGHT: begin
                     if(mode == IN) begin
                        cmd_reg <= ZOOM_IN;
                        if(x <= 4'd9) 
                           x <= x + 4'd1;
                        else 
                           x <= x;
                     end
                     else begin
                        cmd_reg <= ZOOM_FIT;
                     end
                  end
                  SHIFT_LEFT: begin
                     if(mode == IN) begin
                        cmd_reg <= ZOOM_IN;
                        if(x >= 4'd3)
                           x <= x - 4'd1;
                        else
                           x <= x;
                     end
                     else begin
                        cmd_reg <= ZOOM_FIT;
                     end
                  end
                  SHIFT_UP: begin
                     if(mode == IN) begin
                        cmd_reg <= ZOOM_IN;
                        if(y >= 4'd3)
                           y <= y - 4'd1;
                        else
                           y <= y;
                     end
                     else begin
                        cmd_reg <= ZOOM_FIT;
                     end
                  end
                  default: begin
                     if(mode == IN) begin
                        cmd_reg <= ZOOM_IN;
                        if(y <= 4'd6)
                           y <= y + 4'd1;
                        else
                           y <= y;
                     end
                     else begin
                        cmd_reg <= ZOOM_FIT;
                     end
                  end
               endcase
            end
         endcase
      end
   end

endmodule