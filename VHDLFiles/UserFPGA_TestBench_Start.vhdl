LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

ENTITY UserFPGA_TestBench_Start_vhdl IS
END UserFPGA_TestBench_Start_vhdl;

ARCHITECTURE behavior OF UserFPGA_TestBench_Start_vhdl IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT UserFPGA
	PORT(
		ClockIn : IN std_logic;
		ClockOut: OUT std_logic;
		GlobalReset : IN std_logic;
		ExtIn : IN std_logic_vector(1 downto 0);
		EX_D_IN : IN std_logic_vector(6 downto 0);
		FA_OTR : IN std_logic;
		FA_D : IN std_logic_vector(13 downto 0);
		Switches : IN std_logic_vector(3 downto 0);
		eBus_Enable : IN std_logic;
		eBus_Address : IN std_logic_vector(24 downto 0);
		eBus_DataIn : IN std_logic_vector(15 downto 0);
		eBus_Write : IN std_logic;
		eBus_Read : IN std_logic;
		meBus_Grant : IN std_logic;
		meBus_Enable : IN std_logic;
		meBus_Done : IN std_logic;
		meBus_DataIn : IN std_logic_vector(15 downto 0);
		Revision : IN std_logic_vector(15 downto 0);          
		ExtOut : OUT std_logic_vector(1 downto 0);
		EX_D_OUT : OUT std_logic_vector(10 downto 0);
		EX_T_OUT : OUT std_logic_vector(3 downto 0);
		MPX : OUT std_logic_vector(1 downto 0);
		MPX_EN : OUT std_logic;
		FA_CLK : OUT std_logic;
		LEDs : OUT std_logic_vector(3 downto 0);
		eBus_Done : OUT std_logic;
		eBus_DataOut : OUT std_logic_vector(15 downto 0);
		meBus_Request : OUT std_logic;
		meBus_Address : OUT std_logic_vector(24 downto 0);
		meBus_Read : OUT std_logic;
		meBus_Write : OUT std_logic;
		meBus_DataOut : OUT std_logic_vector(15 downto 0)
		);
	END COMPONENT;

	--Inputs
	SIGNAL Clock :  std_logic := '0';
	SIGNAL ClockIn :  std_logic := '0';
	SIGNAL GlobalReset :  std_logic := '0';
	SIGNAL FA_OTR :  std_logic := '0';
	SIGNAL eBus_Enable :  std_logic := '0';
	SIGNAL eBus_Write :  std_logic := '0';
	SIGNAL eBus_Read :  std_logic := '0';
	SIGNAL meBus_Grant :  std_logic := '0';
	SIGNAL meBus_Enable :  std_logic := '0';
	SIGNAL meBus_Done :  std_logic := '0';
	SIGNAL ExtIn :  std_logic_vector(1 downto 0) := (others=>'0');
	SIGNAL EX_D_IN :  std_logic_vector(6 downto 0) := (others=>'0');
	SIGNAL FA_D :  std_logic_vector(13 downto 0) := (others=>'0');
	SIGNAL Switches :  std_logic_vector(3 downto 0) := (others=>'0');
	SIGNAL eBus_Address :  std_logic_vector(24 downto 0) := (others=>'0');
	SIGNAL eBus_DataIn :  std_logic_vector(15 downto 0) := (others=>'0');
	SIGNAL meBus_DataIn :  std_logic_vector(15 downto 0) := (others=>'0');
	SIGNAL Revision :  std_logic_vector(15 downto 0) := (others=>'0');

	--Outputs
	SIGNAL ClockOut :  std_logic;
	SIGNAL ExtOut :  std_logic_vector(1 downto 0);
	SIGNAL EX_D_OUT :  std_logic_vector(10 downto 0);
	SIGNAL EX_T_OUT :  std_logic_vector(3 downto 0);
	SIGNAL MPX :  std_logic_vector(1 downto 0);
	SIGNAL MPX_EN :  std_logic;
	SIGNAL FA_CLK :  std_logic;
	SIGNAL LEDs :  std_logic_vector(3 downto 0);
	SIGNAL eBus_Done :  std_logic;
	SIGNAL eBus_DataOut :  std_logic_vector(15 downto 0);
	SIGNAL meBus_Request :  std_logic;
	SIGNAL meBus_Address :  std_logic_vector(24 downto 0);
	SIGNAL meBus_Read :  std_logic;
	SIGNAL meBus_Write :  std_logic;
	SIGNAL meBus_DataOut :  std_logic_vector(15 downto 0);

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: UserFPGA PORT MAP(
		ClockIn => Clock,
		ClockOut => ClockOut,
		GlobalReset => GlobalReset,
		ExtOut => ExtOut,
		ExtIn => ExtIn,
		EX_D_OUT => EX_D_OUT,
		EX_D_IN => EX_D_IN,
		EX_T_OUT => EX_T_OUT,
		MPX => MPX,
		MPX_EN => MPX_EN,
		FA_OTR => FA_OTR,
		FA_D => FA_D,
		FA_CLK => FA_CLK,
		LEDs => LEDs,
		Switches => Switches,
		eBus_Enable => eBus_Enable,
		eBus_Done => eBus_Done,
		eBus_Address => eBus_Address,
		eBus_DataIn => eBus_DataIn,
		eBus_DataOut => eBus_DataOut,
		eBus_Write => eBus_Write,
		eBus_Read => eBus_Read,
		meBus_Request => meBus_Request,
		meBus_Grant => meBus_Grant,
		meBus_Enable => meBus_Enable,
		meBus_Done => meBus_Done,
		meBus_Address => meBus_Address,
		meBus_Read => meBus_Read,
		meBus_Write => meBus_Write,
		meBus_DataIn => meBus_DataIn,
		meBus_DataOut => meBus_DataOut,
		Revision => Revision
	);

	tb : PROCESS
	BEGIN
		-- Wait 100 ns for global reset to finish
		wait for 20 ns;
		Clock <= '1';
		wait for 20 ns;
		Clock <= '0';
	END PROCESS;

	GlobalReset <= '1';
	meBus_Grant <= '1';
END;
