--UserModule_ChModule_ADC.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserModule / Ch Module / ADC Module
--
--ver20071022 Takayuki Yuasa
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
entity UserModule_ChModule_ADC is
	port(
		ChModule2InternalModule	: in		Signal_ChModule2InternalModule;
		--
		AdcModule2Adc	: out		Signal_AdcModule2Adc;
		Adc2AdcModule	: in		Signal_Adc2AdcModule;
		AdcModule2ChModule	: out	Signal_AdcModule2ChModule;
		--clock and reset
		Clock			:	in		std_logic;
		GlobalReset	:	in		std_logic
	);
end UserModule_ChModule_ADC;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_ChModule_ADC is

	---------------------------------------------------
	--Declarations of Components
	---------------------------------------------------

	---------------------------------------------------
	--Declarations of Signals
	---------------------------------------------------
	--Signals
	signal Trigger				: std_logic	:= '0';
	
	--Registers
	
	--Counters
	signal SampledNumber		: integer range 0 to WidthOfNumberOfSamples-1 := 0;
	
	--State Machines' State-variables
	
	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin	
	
	---------------------------------------------------
	--Instantiations of Components
	---------------------------------------------------

	---------------------------------------------------
	--Static relationships
	---------------------------------------------------
	--Power Down no tokiha, AdcClk mo stop shinaito,
	--DCS(duty cycle stabilizer) ga gosadou shite,
	--mou hitotsu no keitou ni yugami wo shoujiru.
	AdcModule2Adc.AdcClk <= '0' when ChModule2InternalModule.AdcPowerDown='1' else Clock;
	AdcModule2ChModule.AdcData <= Adc2AdcModule.AdcD;
	
	---------------------------------------------------
	--Dynamic Processes with Sensitivity List
	---------------------------------------------------
	
	--UserModule main state machine
	MainProcess : process (Clock, GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			--Power Down Mode
			if (ChModule2InternalModule.AdcPowerDown='1') then
				AdcModule2Adc.AdcPDWN <= '1';
			else
				AdcModule2Adc.AdcPDWN <= '0';
			end if;
		end if;
	end process;
	
end Behavioral;