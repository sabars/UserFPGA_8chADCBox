LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

ENTITY UserFPGA_Template_TestBench_vhdl IS
END UserFPGA_Template_TestBench_vhdl;

ARCHITECTURE behavior OF UserFPGA_Template_TestBench_vhdl IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT UserFPGA
	PORT(
		Clock : IN std_logic;
		GlobalReset : IN std_logic;
		CMOSIn : IN std_logic_vector(7 downto 0);
		LVDSIn : IN std_logic_vector(11 downto 0);
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
		CMOSOut : OUT std_logic_vector(7 downto 0);
		LVDSOut : OUT std_logic_vector(11 downto 0);
		LEDs : OUT std_logic_vector(1 downto 0);
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
	SIGNAL GlobalReset :  std_logic := '0';
	SIGNAL eBus_Enable :  std_logic := '0';
	SIGNAL eBus_Write :  std_logic := '0';
	SIGNAL eBus_Read :  std_logic := '0';
	SIGNAL meBus_Grant :  std_logic := '0';
	SIGNAL meBus_Enable :  std_logic := '0';
	SIGNAL meBus_Done :  std_logic := '0';
	SIGNAL CMOSIn :  std_logic_vector(7 downto 0) := (others=>'0');
	SIGNAL LVDSIn :  std_logic_vector(11 downto 0) := (others=>'0');
	SIGNAL Switches :  std_logic_vector(3 downto 0) := (others=>'0');
	SIGNAL eBus_Address :  std_logic_vector(24 downto 0) := (others=>'0');
	SIGNAL eBus_DataIn :  std_logic_vector(15 downto 0) := (others=>'0');
	SIGNAL meBus_DataIn :  std_logic_vector(15 downto 0) := (others=>'0');
	SIGNAL Revision :  std_logic_vector(15 downto 0) := (others=>'0');

	--Outputs
	SIGNAL CMOSOut :  std_logic_vector(7 downto 0);
	SIGNAL LVDSOut :  std_logic_vector(11 downto 0);
	SIGNAL LEDs :  std_logic_vector(1 downto 0);
	SIGNAL eBus_Done :  std_logic;
	SIGNAL eBus_DataOut :  std_logic_vector(15 downto 0);
	SIGNAL meBus_Request :  std_logic;
	SIGNAL meBus_Address :  std_logic_vector(24 downto 0);
	SIGNAL meBus_Read :  std_logic;
	SIGNAL meBus_Write :  std_logic;
	SIGNAL meBus_DataOut :  std_logic_vector(15 downto 0);
	
	signal flag : std_logic := '0';
	
BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: UserFPGA PORT MAP(
		Clock => Clock,
		GlobalReset => GlobalReset,
		CMOSIn => CMOSIn,
		CMOSOut => CMOSOut,
		LVDSIn => LVDSIn,
		LVDSOut => LVDSOut,
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
		if (flag='0') then
			GlobalReset <= '0';
			flag <= '1';
		else
			GlobalReset <= '1';
		end if;
		
		-- Wait 100 ns for global reset to finish
		wait for 20 ns;
		Clock <= '1';
		wait for 20 ns;
		Clock <= '0';
	END PROCESS;

END;
