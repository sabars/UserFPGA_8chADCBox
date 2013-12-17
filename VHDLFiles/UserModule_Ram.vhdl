--UserModule_Ram.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserModule / Ram
--
--ver20071023 Takayuki Yuasa
--file created
--based on UserModule_Template_with_BusIFLite.vhdl (ver20071021)

---------------------------------------------------
--Declarations of Libraries
---------------------------------------------------
library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.iBus_Library.all;
use work.iBus_AddressMap.all;
use work.UserModule_Library.all;

---------------------------------------------------
--Entity Declaration
---------------------------------------------------
entity UserModule_Ram is
	port(
		Address		: in std_logic_VECTOR(9 downto 0);
		DataIn		: in std_logic_VECTOR(15 downto 0);
		DataOut		: out std_logic_VECTOR(15 downto 0);
		WriteEnable	: in std_logic;
		Clock			: in std_logic
	);
end UserModule_Ram;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_Ram is

	---------------------------------------------------
	--Declarations of Components
	---------------------------------------------------
	component UserModule_Ram_Core
		port (
			addr: IN std_logic_VECTOR(9 downto 0);
			clk: IN std_logic;
			din: IN std_logic_VECTOR(15 downto 0);
			dout: OUT std_logic_VECTOR(15 downto 0);
			we: IN std_logic
		);
	end component;

	---------------------------------------------------
	--Declarations of Signals
	---------------------------------------------------
	--Signals
	
	--Registers

	--Counters
	
	--State Machines' State-variables
	
	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin	
	
	---------------------------------------------------
	--Instantiations of Components
	---------------------------------------------------
	ram_core : UserModule_Ram_Core
		port map(
			addr	=> Address,
			clk	=> Clock,
			din	=> DataIn,
			dout	=> DataOut,
			we		=> WriteEnable
		);

	---------------------------------------------------
	--Static relationships
	---------------------------------------------------
	
	---------------------------------------------------
	--Dynamic Processes with Sensitivity List
	---------------------------------------------------
	
end Behavioral;