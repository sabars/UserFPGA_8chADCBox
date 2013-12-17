--UserModule_Library.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserModule / Library
--
--ver20071025 Takayuki Yuasa
--renamed from UserModule_ChModule_Library.vhdl
--to UserModule_Library.vhdl
--
--ver20081027 Takayuki Yuasa
--ver20071022 Takayuki Yuasa
--file created
--based on iBus_Library.vhdl (ver20071021)

---------------------------------------------------
--Declarations of Libraries
---------------------------------------------------
library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

---------------------------------------------------
--Package for UserModules
---------------------------------------------------
package UserModule_Library is
	
	---------------------------------------------------
	--Global variables
	---------------------------------------------------
	constant ClockFreq					:	Integer	:= 50; --50Mhz Clock
	constant Count10msec					:	Integer	:= 499999; --50000000cycle/s => 500000cycles/10ms
	constant Count100msec				:	Integer	:= 49999999; --50000000cycle/s => 500000cycles/10ms
	constant ADCResolution				:	Integer	:= 12; --12bit ADC
	constant ADCResolutionForFastVeto	:	Integer	:= 8;
	
	constant MaximumOfDelay				:	Integer	:= 32; --32clk delay
	constant DepthOfChModuleBufferFifo	:	Integer	:= 1024; --1024depth
	constant FifoDataWidth				:	Integer	:= 16; --fifo=16bit word
	constant MaximumOfProducerAndConsumerNodes	: Integer := 16;
	constant NumberOfProducerNodes	: Integer := 8;
	constant NumberOfConsumerNodes	: Integer := 2;
	
	constant HEADER_FLAG					: std_logic_vector(3 downto 0) := "0100";
	
	constant REGISTER_ALL_ONE			: std_logic_vector(15 downto 0) := x"ffff";
	constant REGISTER_ALL_ZERO			: std_logic_vector(15 downto 0) := x"0000";
	
	constant InitialAddressOf_Sdram_EventList	: std_logic_vector(31 downto 0) := x"00000000";
	constant FinalAddressOf_Sdram_EventList	: std_logic_vector(31 downto 0) := x"00fffffe";
	
	---------------------------------------------------
	--Signals: between ChMgr and InternalModule
	---------------------------------------------------
	constant WidthOfTriggerMode		:	Integer	:= 4; --max mode=2^4=16types
	constant WidthOfNumberOfSamples	:	Integer	:= 16; --max sample=2^16=65536
	constant WidthOfDepthOfDelay		:	Integer	:= 7; --max depth=2^7=128
	constant WidthOfSizeOfHeader		:	Integer	:= 4; --max depth=2^4=16words
	constant SizeOfHeader				:	Integer	:= 4; --stop word (1w) + real time (3w)
	constant WidthOfRealTime			:	Integer	:= 48; --max length(@50MHz)=65days
	constant WidthOfTriggerBus		:	Integer	:= 8; -- 8 lines

	--trigger mode
	constant Mode_1_StartingTh_NumberOfSamples	:	std_logic_vector(WidthOfTriggerMode-1 downto 0)	:= x"1";
	constant Mode_2_CommonGateIn_NumberOfSamples	:	std_logic_vector(WidthOfTriggerMode-1 downto 0)	:= x"2";
	constant Mode_3_StartingTh_NumberOfSamples_ClosingTh	:	std_logic_vector(WidthOfTriggerMode-1 downto 0)	:= x"3";
	constant Mode_4_Average4_StartingTh_NumberOfSamples	:	std_logic_vector(WidthOfTriggerMode-1 downto 0)	:= x"4";
	constant Mode_5_CPUTrigger	:	std_logic_vector(WidthOfTriggerMode-1 downto 0)	:= x"5";
	constant Mode_6_FastVetoTrigger	:	std_logic_vector(WidthOfTriggerMode-1 downto 0)	:= x"6";
	constant Mode_7_HitPatternTrigger	:	std_logic_vector(WidthOfTriggerMode-1 downto 0)	:= x"7";
	constant Mode_8_TriggerBusSelectedOR	:	std_logic_vector(WidthOfTriggerMode-1 downto 0)	:= x"8";
	constant Mode_9_TriggerBusSelectedAND	:	std_logic_vector(WidthOfTriggerMode-1 downto 0)	:= x"9";
	
	type Signal_ChModule2InternalModule is record
		--ADC Module
		AdcPowerDown		: std_logic;
		--Trigger Module
		TriggerMode			: std_logic_vector(WidthOfTriggerMode-1 downto 0);
		CommonGateIn		: std_logic;
		CPUTrigger			: std_logic;
		TriggerBus			: std_logic_vector(WidthOfTriggerBus-1 downto 0);
		TriggerBusMask		: std_logic_vector(WidthOfTriggerBus-1 downto 0);
		FastVetoTrigger				: std_logic;
		HitPatternTrigger	: std_logic;
		--
		DepthOfDelay		: std_logic_vector(WidthOfDepthOfDelay-1 downto 0);
		NumberOfSamples	: std_logic_vector(WidthOfNumberOfSamples-1 downto 0);
		ThresholdStarting	: std_logic_vector(ADCResolution-1 downto 0);
		ThresholdClosing	: std_logic_vector(ADCResolution-1 downto 0);
		--
		SizeOfHeader		: std_logic_vector(WidthOfSizeOfHeader-1 downto 0);
		--
		RealTime				: std_logic_vector(WidthOfRealTime-1 downto 0);
		Veto					: std_logic;
	end record;
	
	constant WidthOfDepthOfFIFO		:	Integer	:= 10; --max depth=1024
	type Signal_InternalModule2ChModule is record
		--
		TriggerOut			: std_logic;
		--To know the current usage of fifo
		DataCountOfFIFO	:	std_logic_vector(WidthOfDepthOfFIFO-1 downto 0);
	end record;

	---------------------------------------------------
	--Signals: between ADC and ChModule
	---------------------------------------------------
	--singou sen no namae ha, "Adc" toiu prefix no atoni,
	--AD chip no shingou sen mei wo tsunagete kaite aru.
	type Signal_Adc2ADCModule is record
		--
		AdcD			: std_logic_vector(ADCResolution-1 downto 0);
		AdcOTR		: std_logic;
	end record;
	
	type Signal_ADCModule2Adc is record
		--
		AdcClk		: std_logic;
		AdcPDWN		: std_logic;
		--control signals which are
		--already connected to GND/Vcc in circuit
--		AdcDCS		: std_logic;
--		AdcDFS		: std_logic;
--		AdcOEB		: std_logic;
--		AdcMUX_SELECT		: std_logic;
--		AdcSHARED_REF		: std_logic;
	end record;
	
	type Signal_ADCModule2ChModule is record
		AdcData		: std_logic_vector(ADCResolution-1 downto 0);
	end record;
	
	type Signal_Adc2ADCModule_Vector is array (INTEGER range <>) of Signal_Adc2ADCModule;
	type Signal_ADCModule2Adc_Vector is array (INTEGER range <>) of Signal_ADCModule2Adc;

	subtype Signal_Adc2UserFPGA_Vector is Signal_Adc2ADCModule_Vector;
	subtype Signal_UserFPGA2Adc_Vector is Signal_ADCModule2Adc_Vector;

	---------------------------------------------------
	--Signals: between ChModule and EventMgr, EventMgr and Consumer
	---------------------------------------------------
	type Signal_ChModule2EventMgr is record
		Data			: std_logic_vector(FifoDataWidth-1 downto 0);
		hasData		: std_logic;
	end record;

	type Signal_EventMgr2ChModule is record
		ReadEnable	: std_logic;
	end record;
	
	type Signal_ChModule2EventMgr_Vector is array (INTEGER range <>) of Signal_ChModule2EventMgr;
	type Signal_EventMgr2ChModule_Vector is array (INTEGER range <>) of Signal_EventMgr2ChModule;

	type Signal_Consumer2EventMgr is record
		Request		: std_logic;
		Done			: std_logic;
		ReadEnable	: std_logic;
	end record;
	
	type Signal_EventMgr2Consumer is record
		Data			: std_logic_vector(FifoDataWidth-1 downto 0);
		Grant			: std_logic;
	end record;

	type Signal_Consumer2EventMgr_Vector is array (INTEGER range <>) of Signal_Consumer2EventMgr;
	type Signal_EventMgr2Consumer_Vector is array (INTEGER range <>) of Signal_EventMgr2Consumer;

	---------------------------------------------------
	--Signals: between Timer and ChMgr
	---------------------------------------------------
	constant WidthOfLiveTime		:	Integer	:= 32;
		--livetime counter is counted up every 10ms
		--42949672.95 sec made count dekiru
	type Signal_LiveTimer2ChMgr is record
		Livetime			: std_logic_vector(WidthOfLiveTime-1 downto 0);
		Done				: std_logic;
	end record;
	type Signal_ChMgr2LiveTimer is record
		Veto				: std_logic;
		PresetLivetime	: std_logic_vector(WidthOfLiveTime-1 downto 0);
		Reset				: std_logic;
	end record;
	
	type Signal_LiveTimer2ChMgr_Vector is array (INTEGER range <>) of Signal_LiveTimer2ChMgr;
	type Signal_ChMgr2LiveTimer_Vector is array (INTEGER range <>) of Signal_ChMgr2LiveTimer;
	
	---------------------------------------------------
	--Signals: between Timer and ChMgr
	---------------------------------------------------
	constant WidthOfNumberOfEvent		:	Integer	:= 32;
		--2^32 event made count dekiru
	type Signal_EventCounter2ChMgr is record
		EventCounterVeto			: std_logic;
		NumberOfEvent	: std_logic_vector(WidthOfNumberOfEvent-1 downto 0);
	end record;
	type Signal_ChMgr2EventCounter is record
		Veto						: std_logic;
		Trigger					: std_logic;
		PresetNumberOfEvent	: std_logic_vector(WidthOfNumberOfEvent-1 downto 0);
		Reset						: std_logic;
	end record;
	
	type Signal_EventCounter2ChMgr_Vector is array (INTEGER range <>) of Signal_EventCounter2ChMgr;
	type Signal_ChMgr2EventCounter_Vector is array (INTEGER range <>) of Signal_ChMgr2EventCounter;
	
	
	---------------------------------------------------
	--Signals: between ChMgr and ChModules
	---------------------------------------------------
	type Signal_ChModule2ChMgr is record
		Veto				: std_logic;
		Trigger			: std_logic;
	end record;
	type Signal_ChMgr2ChModule is record
		Realtime			: std_logic_vector(WidthOfRealTime-1 downto 0);
		Livetime			: std_logic_vector(WidthOfLiveTime-1 downto 0);
		CommonGateIn	: std_logic;
		TriggerBus		: std_logic_vector(WidthOfTriggerBus-1 downto 0);
		Veto				: std_logic;
	end record;
	type Signal_ChModule2ChMgr_Vector is array (INTEGER range <>) of Signal_ChModule2ChMgr;
	type Signal_ChMgr2ChModule_Vector is array (INTEGER range <>) of Signal_ChMgr2ChModule;

	---------------------------------------------------
	--Signals: between Consumer and ConsumerMgr
	---------------------------------------------------
	type Signal_Consumer2ConsumerMgr is record
		EventReady	: std_logic;
		WriteEnable	: std_logic;
		Data			: std_logic_vector(FifoDataWidth-1 downto 0);
	end record;
	type Signal_ConsumerMgr2Consumer is record
		Grant					: std_logic;
		GateSize_FastGate	: std_logic_vector(15 downto 0);
		GateSize_SlowGate	: std_logic_vector(15 downto 0);
		EventPacket_NumberOfWaveform	: std_logic_vector(15 downto 0);
		NumberOf_BaselineSample	: std_logic_vector(15 downto 0);
	end record;
	type Signal_Consumer2ConsumerMgr_Vector is array (INTEGER range <>) of Signal_Consumer2ConsumerMgr;
	type Signal_ConsumerMgr2Consumer_Vector is array (INTEGER range <>) of Signal_ConsumerMgr2Consumer;
	
	---------------------------------------------------
	--Signals: temporal
	---------------------------------------------------
	type Data_Vector is array (INTEGER range <>) of std_logic_vector(15 downto 0);
	type Signal_std_logic_vector8 is array (INTEGER range <>) of std_logic_vector(7 downto 0);
	type ArrayOf_Signed8bitInteger is array (INTEGER range <>) of integer range -128 to 127;
	
end UserModule_Library;