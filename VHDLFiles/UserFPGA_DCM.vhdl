--UserFPGA_DCM.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserFPGA / DCM
--
--ver20071205 Takayuki Yuasa
--file created
--based on UserModule_Template_with_BusIFLite.vhdl (ver20071021)

---------------------------------------------------
--Declarations of Libraries
---------------------------------------------------
library ieee,work,unisim;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.iBus_Library.all;
use work.iBus_AddressMap.all;
use work.UserModule_Library.all;

use unisim.vcomponents.all;

---------------------------------------------------
--Entity Declaration
---------------------------------------------------
entity UserFPGA_DCM is
	port(
		Locked						: OUT std_logic;
		--clock and reset
		Clock_50MHz_In				: in std_logic;
		Clock_50MHz_IBUFG_Out	: OUT std_logic;
		Clock_50MHz_Out			: out std_logic;
		Clock_100MHz_Out			: OUT std_logic;
		GlobalReset					: in	std_logic
	);
end UserFPGA_DCM;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserFPGA_DCM is

	---------------------------------------------------
	--Declarations of Components
	---------------------------------------------------
	COMPONENT UserFPGA_DCM_Core
		PORT(
			CLKIN_IN		: IN std_logic;
			RST_IN		: IN std_logic;          
			CLKFX_OUT	: OUT std_logic;
			CLKIN_IBUFG_OUT	: OUT std_logic;
			CLK0_OUT				: OUT std_logic;
			CLK2X_OUT			: OUT std_logic;
			LOCKED_OUT			: OUT std_logic
		);
	END COMPONENT;

	---------------------------------------------------
	--Declarations of Signals
	---------------------------------------------------
	--Signals
	signal reset		: std_logic   := '0';
	signal clk25m_wire : std_logic;
	signal clk50m_wire : std_logic;
	signal clk100m_wire : std_logic;
	signal clk100mb_wire : std_logic;
	signal clk120m_wire : std_logic;
	
	signal fpga_clk : std_logic;
	signal clk25meg : std_logic;
	signal clk50meg : std_logic;
	signal clk100meg : std_logic;
	signal clk100megb : std_logic;
	signal clk120meg : std_logic;
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
	Inst_UserFPGA_DCM_Core: UserFPGA_DCM_Core
		port map(
			CLKIN_IN		=> Clock_50MHz_In,
			RST_IN		=> reset,
			CLKFX_OUT	=> open,
			CLKIN_IBUFG_OUT	=> Clock_50MHz_IBUFG_Out,
			CLK0_OUT				=> Clock_50MHz_Out,
			CLK2X_OUT			=> Clock_100MHz_Out,
			LOCKED_OUT			=> Locked
		);

--
--	spw_clock : DCM
--		generic map (
--			CLKDV_DIVIDE => 2.0,		--  Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
--										--     7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
--			CLKFX_DIVIDE => 3,			--  Can be any interger from 1 to 32
--			CLKFX_MULTIPLY => 10,		--  Can be any integer from 1 to 32
--			CLKIN_DIVIDE_BY_2 => FALSE,	--  TRUE/FALSE to enable CLKIN divide by two feature
--			CLKIN_PERIOD => 20.0,		--  Specify period of input clock
--			CLKOUT_PHASE_SHIFT => "NONE",	--  Specify phase shift of NONE, FIXED or VARIABLE
--			CLK_FEEDBACK => "1X",			--  Specify clock feedback of NONE, 1X or 2X
--			DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", --  SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or
--											--     an integer from 0 to 15
--			DFS_FREQUENCY_MODE => "LOW",	--  HIGH or LOW frequency mode for frequency synthesis
--			DLL_FREQUENCY_MODE => "LOW",	--  HIGH or LOW frequency mode for DLL
--			DUTY_CYCLE_CORRECTION => TRUE,	--  Duty cycle correction, TRUE or FALSE
--			FACTORY_JF => X"C080",			--  FACTORY JF Values
--			PHASE_SHIFT => 0,				--  Amount of fixed phase shift from -255 to 255
--			STARTUP_WAIT => FALSE)			--  Delay configuration DONE until DCM LOCK, TRUE/FALSE
--		port map (
--			CLK0 => clk50m_wire,		-- 0 degree DCM CLK ouptput
--		--	CLK180 => CLK180,			-- 180 degree DCM CLK output
--		--	CLK270 => CLK270,			-- 270 degree DCM CLK output
--			CLK2X => clk100m_wire,		-- 2X DCM CLK output
--			CLK2X180 => clk100mb_wire,	-- 2X, 180 degree DCM CLK out
--		--	CLK90 => CLK90,				-- 90 degree DCM CLK output
--			CLKDV => clk25m_wire,		-- Divided DCM CLK out (CLKDV_DIVIDE)
--			CLKFX => clk120m_wire,		-- DCM CLK synthesis out (M/D)
--		--	CLKFX180 => clk100mb_wire,	-- 180 degree CLK synthesis out
--		--	LOCKED => LOCKED,			-- DCM LOCK status output
--		--	PSDONE => PSDONE,			-- Dynamic phase adjust done output
--		--	STATUS => STATUS,			-- 8-bit DCM status bits output
--			CLKFB => fpga_clk,			-- DCM clock feedback
--			CLKIN => Clock_50MHz_In				-- Clock input (from IBUFG, BUFG or DCM)
--		--	PSCLK => PSCLK,				-- Dynamic phase adjust clock input
--		--	PSEN => PSEN,				-- Dynamic phase adjust enable input
--		--	PSINCDEC => PSINCDEC,		-- Dynamic phase adjust increment/decrement
--		--	RST => reset				-- DCM asynchronous reset input
--		);
--	
--	clk25m_buf : BUFG port map (I => clk25m_wire, O => clk25meg);	-- not used
--	clk50m_buf : BUFG port map (I => clk50m_wire, O => fpga_clk);
--	clk100m_buf : BUFG port map (I => clk100m_wire, O => clk100meg);
--	clk100mb_buf : BUFG port map (I => clk100mb_wire, O => clk100megb);
--	clk120m_buf : BUFG port map (I => clk120m_wire, O => clk120meg);
--
--	Locked  <= '1';
--	Clock_50MHz_IBUFG_Out <= fpga_clk;
--	Clock_50MHz_Out <= fpga_clk;
--	Clock_100MHz_Out <= clk100meg;

	---------------------------------------------------
	--Static relationships
	---------------------------------------------------
	reset <= not GlobalReset;
	
	---------------------------------------------------
	--Dynamic Processes with Sensitivity List
	---------------------------------------------------
	
end Behavioral;