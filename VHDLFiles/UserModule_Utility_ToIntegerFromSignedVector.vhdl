library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;

entity UserModule_Utility_ToIntegerFromSignedVector is
	generic(
		Width : integer := 8
	);
	port(
		Input : in std_logic_vector(Width-1 downto 0);
		Output : out integer range -2**(Width-1) to 2**(Width-1)-1
	);
end UserModule_Utility_ToIntegerFromSignedVector;

architecture Behavioral of UserModule_Utility_ToIntegerFromSignedVector is

begin
	Output <= conv_integer(Input);
end Behavioral;

