-- SpaceWire Board
-- FPGA:xc3s1000-ft256
-- SDRAM Controller Address Multiplexer
-- DATE '2007-Nov-30
-- Ver0.0


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
---------------------------


entity spw_adrmpx is
port(
-- state Signals --
	clk				: in	std_logic;-- 48MHz or 96MHz
	xreset			: in	std_logic;-- Active Low
	spw_adr			: in	std_logic_vector(24 downto 0);
	mode_adr			: in	std_logic_vector(12 downto 0);
	mode_set			: in	std_logic;
	ap10			: in	std_logic;
	cae				: in	std_logic;
	cnt_ena			: in	std_logic;
	adr_load		: in	std_logic;
	bus_width		: in	std_logic;--0=8bit,1=16bit
--sdram MPX address
	o_sda			: out	std_logic_vector(12 downto 0);
	o_ba			: out	std_logic_vector(1 downto 0)

	);
end spw_adrmpx;


------------------------------------------------------------------------------
architecture mpx_address of spw_adrmpx is
------------------------------------------------------------------------------
--	constant	modeset				: std_logic_vector(10 downto 0) := "00000100000";

signal	mem_adrs		: std_logic_vector(24 downto 0);
signal	spw_clmadr		: std_logic_vector(9 downto 0);
signal	spw_rawadr		: std_logic_vector(12 downto 0);
signal	spw_bnkadr		: std_logic_vector(1 downto 0);
signal	sdram_adrs		: std_logic_vector(12 downto 0);
signal	sdram_bank		: std_logic_vector(1 downto 0);

BEGIN
--SpW address Register & Coulmn Counter
PROCESS (clk,xreset,adr_load,cnt_ena)
BEGIN
	IF (xreset = '0') THEN
											mem_adrs <= (OTHERS =>'0');
	ELSIF (clk'EVENT AND clk = '1') THEN
				IF	(adr_load = '1')	THEN
											mem_adrs <= spw_adr;
				ELSIF	( cnt_ena = '1')	THEN
											mem_adrs <= mem_adrs + '1';
				END IF;
	END IF;
END PROCESS;

	spw_clmadr <= ('0'& mem_adrs( 9 downto 1)) WHEN (bus_width='1') ELSE (mem_adrs(9 downto 0));
	spw_rawadr <= mem_adrs( 22 downto 10);
	spw_bnkadr <=  (mem_adrs( 24 downto 23)) WHEN(bus_width='1')  ELSE (mem_adrs(23 downto 22));


	sdram_adrs(0) <= mode_adr(0) WHEN (mode_set='1') ELSE spw_clmadr(0) WHEN (cae='1') ELSE spw_rawadr(0);
	sdram_adrs(1) <= mode_adr(1) WHEN (mode_set='1') ELSE spw_clmadr(1) WHEN (cae='1') ELSE spw_rawadr(1);
	sdram_adrs(2) <= mode_adr(2) WHEN (mode_set='1') ELSE spw_clmadr(2) WHEN (cae='1') ELSE spw_rawadr(2);
	sdram_adrs(3) <= mode_adr(3) WHEN (mode_set='1') ELSE spw_clmadr(3) WHEN (cae='1') ELSE spw_rawadr(3);
	sdram_adrs(4) <= mode_adr(4) WHEN (mode_set='1') ELSE spw_clmadr(4) WHEN (cae='1') ELSE spw_rawadr(4);
	sdram_adrs(5) <= mode_adr(5) WHEN (mode_set='1') ELSE spw_clmadr(5) WHEN (cae='1') ELSE spw_rawadr(5);
	sdram_adrs(6) <= mode_adr(6) WHEN (mode_set='1') ELSE spw_clmadr(6) WHEN (cae='1') ELSE spw_rawadr(6);
	sdram_adrs(7) <= mode_adr(7) WHEN (mode_set='1') ELSE spw_clmadr(7) WHEN (cae='1') ELSE spw_rawadr(7);
	sdram_adrs(8) <= mode_adr(8) WHEN (mode_set='1') ELSE spw_clmadr(8) WHEN (cae='1') ELSE spw_rawadr(8);
	sdram_adrs(9) <= mode_adr(9) WHEN (mode_set='1') ELSE spw_clmadr(9) WHEN (cae='1') ELSE spw_rawadr(9);
	sdram_adrs(10) <= mode_adr(10) WHEN (mode_set='1') ELSE ap10 WHEN (cae='1')  ELSE spw_rawadr(10);
	sdram_adrs(11) <= mode_adr(11) WHEN (mode_set='1') ELSE spw_rawadr(11);
	sdram_adrs(12) <= mode_adr(12) WHEN (mode_set='1') ELSE spw_rawadr(12);

	sdram_bank(0) <= '0'  WHEN (mode_set='1') ELSE spw_bnkadr(0);
	sdram_bank(1) <= '0'  WHEN (mode_set='1') ELSE spw_bnkadr(1);


	o_sda <= sdram_adrs;
	o_ba  <= sdram_bank;


END mpx_address;


