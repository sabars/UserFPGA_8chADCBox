--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:13:30 08/21/2010
-- Design Name:   
-- Module Name:   C:/spc/UserFPGA_8chADCBox/TestBench_UserModule_FastVetoModule.vhdl
-- Project Name:  UserFPGA_8chADCBox
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: UserModule_FastVetoModule
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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY TestBench_UserModule_FastVetoModule IS
END TestBench_UserModule_FastVetoModule;
 
ARCHITECTURE behavior OF TestBench_UserModule_FastVetoModule IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT UserModule_FastVetoModule
    PORT(
         AdcClock : IN  std_logic;
         AdcData : IN  std_logic_vector(7 downto 0);
         TriggerOut : OUT  std_logic;
         NumberOfSamplesToBeAveragedForBaseLine : IN  std_logic_vector(0 to 2);
         ThresholdDelta : IN  std_logic_vector(0 to 11);
         WaitDurationAfterTriggeringInUnitsOfClock : IN  std_logic_vector(0 to 9);
         Clock : IN  std_logic;
         GlobalReset : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal AdcClock : std_logic := '0';
   signal AdcData : std_logic_vector(7 downto 0) := (others => '0');
   signal NumberOfSamplesToBeAveragedForBaseLine : std_logic_vector(0 to 2) := (others => '0');
   signal ThresholdDelta : std_logic_vector(0 to 11) := (others => '0');
   signal WaitDurationAfterTriggeringInUnitsOfClock : std_logic_vector(0 to 9) := (others => '0');
   signal Clock : std_logic := '0';
   signal GlobalReset : std_logic := '0';

 	--Outputs
   signal TriggerOut : std_logic;

   -- Clock period definitions
   constant AdcClock_period : time := 10 ns;
   constant WaitDurationAfterTriggeringInUnitsOfClock_period : time := 10 ns;
   constant Clock_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: UserModule_FastVetoModule PORT MAP (
          AdcClock => AdcClock,
          AdcData => AdcData,
          TriggerOut => TriggerOut,
          NumberOfSamplesToBeAveragedForBaseLine => NumberOfSamplesToBeAveragedForBaseLine,
          ThresholdDelta => ThresholdDelta,
          WaitDurationAfterTriggeringInUnitsOfClock => WaitDurationAfterTriggeringInUnitsOfClock,
          Clock => Clock,
          GlobalReset => GlobalReset
        );

   -- Clock process definitions
   AdcClock_process :process
   begin
		AdcClock <= '0';
		wait for AdcClock_period/2;
		AdcClock <= '1';
		wait for AdcClock_period/2;
   end process;
 
   WaitDurationAfterTriggeringInUnitsOfClock_process :process
   begin
		WaitDurationAfterTriggeringInUnitsOfClock <= '0';
		wait for WaitDurationAfterTriggeringInUnitsOfClock_period/2;
		WaitDurationAfterTriggeringInUnitsOfClock <= '1';
		wait for WaitDurationAfterTriggeringInUnitsOfClock_period/2;
   end process;
 
   Clock_process :process
   begin
		Clock <= '0';
		wait for Clock_period/2;
		Clock <= '1';
		wait for Clock_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for AdcClock_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
