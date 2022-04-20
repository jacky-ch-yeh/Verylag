library verilog;
use verilog.vl_types.all;
entity test is
    generic(
        IMAGE_NUM       : integer := 32;
        IMAGE_SIZE      : integer := 128
    );
    attribute mti_svvh_generic_type : integer;
    attribute mti_svvh_generic_type of IMAGE_NUM : constant is 1;
    attribute mti_svvh_generic_type of IMAGE_SIZE : constant is 1;
end test;
