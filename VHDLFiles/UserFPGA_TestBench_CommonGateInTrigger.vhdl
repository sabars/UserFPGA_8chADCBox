--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:44:52 11/12/2008
-- Design Name:   
-- Module Name:   C:/spc/UserFPGA_8chADCBox/UserFPGA_TestBench_CommonGateInTrigger.vhdl
-- Project Name:  UserFPGA_8chADCBox
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: UserFPGA
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
library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.iBus_Library.all;
use work.iBus_AddressMap.all;
use work.UserModule_Library.all;

ENTITY UserFPGA_TestBench_CommonGateInTrigger IS
END UserFPGA_TestBench_CommonGateInTrigger;
 
ARCHITECTURE behavior OF UserFPGA_TestBench_CommonGateInTrigger IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT UserFPGA
    PORT(
         ClockIn : IN  std_logic;
         ClockOut : OUT  std_logic;
         ClockBack : IN  std_logic;
         Clock100MHz : IN  std_logic;
         AdcClockOut : OUT  std_logic;
         GlobalReset : IN  std_logic;
         GateIn_In : IN  std_logic;
         DIO_Out : OUT  std_logic_vector(7 downto 0);
         DIO_In : IN  std_logic_vector(3 downto 0);
			UserFPGA2Adc_vector	: out	Signal_UserFPGA2Adc_Vector(7 downto 0);
			Adc2UserFPGA_vector	: in	Signal_Adc2UserFPGA_Vector(7 downto 0);
         LEDs : OUT  std_logic_vector(3 downto 0);
         Switches : IN  std_logic_vector(3 downto 0);
         eBus_Enable : IN  std_logic;
         eBus_Done : OUT  std_logic;
         eBus_Address : IN  std_logic_vector(24 downto 0);
         eBus_DataIn : IN  std_logic_vector(15 downto 0);
         eBus_DataOut : OUT  std_logic_vector(15 downto 0);
         eBus_Write : IN  std_logic;
         eBus_Read : IN  std_logic;
         meBus_Request : OUT  std_logic;
         meBus_Grant : IN  std_logic;
         meBus_Enable : IN  std_logic;
         meBus_Done : IN  std_logic;
         meBus_Address : OUT  std_logic_vector(24 downto 0);
         meBus_Read : OUT  std_logic;
         meBus_Write : OUT  std_logic;
         meBus_DataIn : IN  std_logic_vector(15 downto 0);
         meBus_DataOut : OUT  std_logic_vector(15 downto 0);
         Sdram_cke : OUT  std_logic;
         Sdram_xdcs : OUT  std_logic;
         Sdram_xdras : OUT  std_logic;
         Sdram_xdcas : OUT  std_logic;
         Sdram_xdwe : OUT  std_logic;
         Sdram_ldqm : OUT  std_logic;
         Sdram_udqm : OUT  std_logic;
         Sdram_sda : OUT  std_logic_vector(12 downto 0);
         Sdram_ba : OUT  std_logic_vector(1 downto 0);
         Sdram_sdd : INOUT  std_logic_vector(15 downto 0);
         Revision : IN  std_logic_vector(15 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal ClockIn : std_logic := '0';
   signal ClockBack : std_logic := '0';
   signal Clock100MHz : std_logic := '0';
   signal GlobalReset : std_logic := '0';
   signal GateIn_In : std_logic := '0';
   signal DIO_In : std_logic_vector(3 downto 0) := (others => '0');
   signal Adc2UserFPGA_vector : Signal_Adc2UserFPGA_Vector(7 downto 0);
   signal Switches : std_logic_vector(3 downto 0) := (others => '0');
   signal eBus_Enable : std_logic := '0';
   signal eBus_Address : std_logic_vector(24 downto 0) := (others => '0');
   signal eBus_DataIn : std_logic_vector(15 downto 0) := (others => '0');
   signal eBus_Write : std_logic := '0';
   signal eBus_Read : std_logic := '0';
   signal meBus_Grant : std_logic := '0';
   signal meBus_Enable : std_logic := '0';
   signal meBus_Done : std_logic := '0';
   signal meBus_DataIn : std_logic_vector(15 downto 0) := (others => '0');
   signal Revision : std_logic_vector(15 downto 0) := (others => '0');

	--BiDirs
   signal Sdram_sdd : std_logic_vector(15 downto 0);

 	--Outputs
   signal ClockOut : std_logic;
   signal AdcClockOut : std_logic;
   signal DIO_Out : std_logic_vector(7 downto 0);
   signal UserFPGA2Adc_vector : Signal_UserFPGA2Adc_Vector(7 downto 0);
   signal LEDs : std_logic_vector(3 downto 0);
   signal eBus_Done : std_logic;
   signal eBus_DataOut : std_logic_vector(15 downto 0);
   signal meBus_Request : std_logic;
   signal meBus_Address : std_logic_vector(24 downto 0);
   signal meBus_Read : std_logic;
   signal meBus_Write : std_logic;
   signal meBus_DataOut : std_logic_vector(15 downto 0);
   signal Sdram_cke : std_logic;
   signal Sdram_xdcs : std_logic;
   signal Sdram_xdras : std_logic;
   signal Sdram_xdcas : std_logic;
   signal Sdram_xdwe : std_logic;
   signal Sdram_ldqm : std_logic;
   signal Sdram_udqm : std_logic;
   signal Sdram_sda : std_logic_vector(12 downto 0);
   signal Sdram_ba : std_logic_vector(1 downto 0);
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: UserFPGA PORT MAP (
          ClockIn => ClockIn,
          ClockOut => ClockOut,
          ClockBack => ClockBack,
          Clock100MHz => Clock100MHz,
          AdcClockOut => AdcClockOut,
          GlobalReset => GlobalReset,
          GateIn_In => GateIn_In,
          DIO_Out => DIO_Out,
          DIO_In => DIO_In,
          UserFPGA2Adc_vector => UserFPGA2Adc_vector,
          Adc2UserFPGA_vector => Adc2UserFPGA_vector,
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
          Sdram_cke => Sdram_cke,
          Sdram_xdcs => Sdram_xdcs,
          Sdram_xdras => Sdram_xdras,
          Sdram_xdcas => Sdram_xdcas,
          Sdram_xdwe => Sdram_xdwe,
          Sdram_ldqm => Sdram_ldqm,
          Sdram_udqm => Sdram_udqm,
          Sdram_sda => Sdram_sda,
          Sdram_ba => Sdram_ba,
          Sdram_sdd => Sdram_sdd,
          Revision => Revision
        );
 
   ClockIn_process :process
   begin
		ClockIn <= '0';
		wait for 10ns;
		ClockIn <= '1';
		wait for 10ns;
   end process;

	GlobalReset <= '1';
END;
