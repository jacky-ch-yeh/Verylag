library verilog;
use verilog.vl_types.all;
entity ISE is
    port(
        clk             : in     vl_logic;
        reset           : in     vl_logic;
        image_in_index  : in     vl_logic_vector(4 downto 0);
        pixel_in        : in     vl_logic_vector(23 downto 0);
        busy            : out    vl_logic;
        out_valid       : out    vl_logic;
        color_index     : out    vl_logic_vector(1 downto 0);
        image_out_index : out    vl_logic_vector(4 downto 0)
    );
end ISE;
