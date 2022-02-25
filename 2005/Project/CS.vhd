Library IEEE;
use IEEE.std_Logic_1164.all;
use IEEE.numeric_std.all;
ENTITY CS IS
port (
Y		: out std_logic_vector (9 downto 0);
X		: in std_logic_vector (7 downto 0);
reset		: in std_logic;
clk		: in std_logic
		  );
END CS;
ARCHITECTURE CS_arc OF CS IS
BEGIN
END CS_arc;
