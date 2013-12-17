library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity UserModule_Utility_ToIntegerFromUnsignedVector is
	generic(
		Width : integer := 8
	);
	port(
		Input : in std_logic_vector(Width-1 downto 0);
		Output : out integer  range 0 to 2**(Width)-1
	);
end UserModule_Utility_ToIntegerFromUnsignedVector;

architecture Behavioral of UserModule_Utility_ToIntegerFromUnsignedVector is

begin
	Output <= conv_integer(Input);
end Behavioral;

