--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:13:52 08/23/2010
-- Design Name:   
-- Module Name:   C:/spc/UserFPGA_8chADCBox/TestBench_UserModule_ChModule_HitPatternModule.vhdl
-- Project Name:  UserFPGA_8chADCBox
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: UserModule_ChModule_HitPatternModule
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
USE ieee.numeric_std.ALL;


ENTITY TestBench_UserModule_ChModule_HitPatternModule IS
END TestBench_UserModule_ChModule_HitPatternModule;
 
ARCHITECTURE behavior OF TestBench_UserModule_ChModule_HitPatternModule IS 


component UserModule_Utility_ToIntegerFromSignedVector is
	generic(
		Width : integer := 8
	);
	port(
		Input : in std_logic_vector(Width-1 downto 0);
		Output : out integer range -2**(Width-1) to 2**(Width-1)-1
	);
end component;
component UserModule_Utility_ToIntegerFromUnsignedVector is
	generic(
		Width : integer := 8
	);
	port(
		Input : in std_logic_vector(Width-1 downto 0);
		Output : out integer  range 0 to 2**(Width)-1
	);
end component;

 	type Signal_std_logic_vector8 is array (INTEGER range <>) of std_logic_vector(7 downto 0); 
 

   --Inputs

	constant AdcResolution : integer := 8;
	constant Depth : integer := 8;
   signal AdcClock : std_logic := '0';
   signal AdcClock_previous : std_logic := '0';
   signal AdcData : integer range 0 to 4095;
	type ArrayOf_Signed8bitInteger is array (INTEGER range <>) of integer range -128 to 127;
   signal CoefficientArray : ArrayOf_Signed8bitInteger(Depth-1 downto 0);
   signal Threshold : integer range 0 to 4095;
   signal WaitDurationAfterTriggeringInUnitsOfClock : integer range 0 to 4095;
   signal Clock : std_logic := '0';
   signal GlobalReset : std_logic := '0';
		
 	--Outputs
   signal TriggerOut : std_logic;

   -- Clock period definitions
   constant Clock_period : time := 20 ns;
	constant MaxOfAdcClock_Counter : integer := 25;
	signal adcclock_counter : integer range 0 to MaxOfAdcClock_Counter := 0;
	
	
	constant WaveformDepth : integer := 23;
	type Type_AdcDataVector is array (INTEGER range <>) of integer range 0 to 4095;
	signal Waveform : Type_AdcDataVector(WaveformDepth-1 downto 0);
	signal index : integer range 0 to WaveformDepth := 0;
	
	signal Output_AsSigned : integer range -2048 to 2047;
	signal Output_AsUnsigned : integer range 0 to 4095;
------------------------	
	type states is (
		Initialize, Idle, CalculateFilteredValue, TriggeredState
	);
	signal state : states := Initialize;
	signal state_count : integer range 0 to 31 := 0;
	signal depth_count : integer range 0 to Depth := 0;
	signal blstate_count : integer range 0 to 31 := 0;
	
	constant MaxDepth : integer := 16;
	signal AdcDataVector : Type_AdcDataVector(MaxDepth-1 downto 0);
	
	signal WaitCounter : std_logic_vector(15 downto 0) := (others => '0');
	
	signal Triggered : std_logic := '0';

	signal Total : integer := 0;
	signal deltaTotal : integer := 0;
------------------------
BEGIN
	inst_UserModule_Utility_ToIntegerFromSignedVector : UserModule_Utility_ToIntegerFromSignedVector
		generic map(
			Width =>8
		)
		port map(
			Input => "11111111",
			Output => Output_AsSigned
		);

	inst_UserModule_Utility_ToIntegerFromUnsignedVector : UserModule_Utility_ToIntegerFromUnsignedVector
		generic map(
			Width =>8
		)
		port map(
			Input => "11111111",
			Output => Output_AsUnsigned
		);



	--input waveform
	Waveform(0) <= 0;
	Waveform(1) <= 0;
	Waveform(2) <= 0;
	Waveform(3) <= 205;
	Waveform(4) <= 241;
	Waveform(5) <= 246;
	Waveform(6) <= 245;
	Waveform(7) <= 243;
	Waveform(8) <= 241;
	Waveform(9) <= 238;
	Waveform(10) <= 236;
	Waveform(11) <= 233;
	Waveform(12) <= 231;
	Waveform(13) <= 229;
	Waveform(14) <= 227;
	Waveform(15) <= 224;
	Waveform(16) <= 222;
	Waveform(17) <= 220;
	Waveform(18) <= 218;
	Waveform(19) <= 215;
	Waveform(20) <= 213;
	Waveform(21) <= 211;
	Waveform(22) <= 209;

	--FIR coefficients
	CoefficientArray(0) <= -1;
	CoefficientArray(1) <= -1;
	CoefficientArray(2) <= -1;
	CoefficientArray(3) <= -1;
	CoefficientArray(4) <= 1;
	CoefficientArray(5) <= 1;
	CoefficientArray(6) <= 1;
	CoefficientArray(7) <= 1;

		
	GlobalReset <= '1';
 
   Clock_process :process
   begin
		Clock <= '0';
		wait for Clock_period/2;
		Clock <= '1';
		wait for Clock_period/2;
   end process; 
 
	Threshold <= 200;
	WaitDurationAfterTriggeringInUnitsOfClock <= 100;
	
   -- Stimulus process
   stim_proc: process(clock)
   begin		
		if(clock'event and clock='1')then
			AdcClock_previous <= AdcClock;
			if(AdcClock_previous='0' and AdcClock='1')then
				if(index=WaveformDepth)then
					--end
				else
					AdcData <= Waveform(index);
					index <= index + 1;
				end if;
			end if;
		
			if(adcclock_counter=MaxOfAdcClock_Counter)then
				adcclock_counter <= 0;
				AdcClock <= not AdcClock;
			else
				adcclock_counter <= adcclock_counter + 1;
			end if;
		end if;
   end process;
-----------------------
	TriggerOut <= Triggered;
	
	process (Clock, GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			AdcClock_previous <= AdcClock;
			case state is
				when Initialize =>
					state <= Idle;
				when Idle =>
					Triggered <= '0';
					WaitCounter <= (others => '0');
					if(AdcClock_previous='0' and AdcClock='1')then
						state_count <= 0;
						depth_count <= 0;
						Total <= 0;
						state <= CalculateFilteredValue;
					end if;
				when CalculateFilteredValue =>
					if(state_count=0)then
						if(depth_count=Depth)then
							if(Threshold<Total)then
								Triggered <= '1';
								state <= TriggeredState;
							else
								state <= Idle;
							end if;
						else
							Total <= Total + conv_integer(conv_std_logic_vector(AdcDataVector(Depth-1-depth_count),16)*conv_std_logic_vector(conv_integer(CoefficientArray(depth_count)),8));
							deltaTotal <= conv_integer(conv_std_logic_vector(AdcDataVector(depth_count),16)*conv_std_logic_vector(conv_integer(CoefficientArray(depth_count)),8));
							depth_count <= depth_count + 1;
						end if;
					end if;
				when TriggeredState =>
					if(WaitCounter=WaitDurationAfterTriggeringInUnitsOfClock)then
						WaitCounter <= (others => '0');
						Triggered <= '0';
						state_count <= 0;
						state <= Idle;
					else
						WaitCounter <= WaitCounter + 1;
					end if;
			end case;
			
			if(AdcClock_previous='1' and AdcClock='0')then
				--shift AdcDataVector
				AdcDataVector(15) <= AdcDataVector(14);
				AdcDataVector(14) <= AdcDataVector(13);
				AdcDataVector(13) <= AdcDataVector(12);
				AdcDataVector(12) <= AdcDataVector(11);
				AdcDataVector(11) <= AdcDataVector(10);
				AdcDataVector(10) <= AdcDataVector(9);
				AdcDataVector(9) <= AdcDataVector(8);
				AdcDataVector(8) <= AdcDataVector(7);
				AdcDataVector(7) <= AdcDataVector(6);
				AdcDataVector(6) <= AdcDataVector(5);
				AdcDataVector(5) <= AdcDataVector(4);
				AdcDataVector(4) <= AdcDataVector(3);
				AdcDataVector(3) <= AdcDataVector(2);
				AdcDataVector(2) <= AdcDataVector(1);
				AdcDataVector(1) <= AdcDataVector(0);
				AdcDataVector(0) <= AdcData;
				--AdcDataVector(0) <= conv_integer((not AdcData) + 1); --2's complement
			end if;
		end if;
	end process;

END;
