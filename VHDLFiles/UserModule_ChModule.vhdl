--UserModule_ChModule.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserModule / Ch Module
--
--ver20071207 Takayuki Yuasa
--iBus clocking changed from Clock(AdcClock) to ReadClock(Clock50MHz)
--
--ver20081027 Takayuki Yuasa
--ver20071025 Takayuki Yuasa
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
entity UserModule_ChModule is
	generic(
		InitialAddress	: std_logic_vector(15 downto 0);
		FinalAddress	: std_logic_vector(15 downto 0);
		ChNumber			: std_logic_vector(2 downto 0)	:= (others=>'0')
	);
	port(
		--signals connected to BusController
		BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
		BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
		--evt mgr
		ChModule2EventMgr	: out Signal_ChModule2EventMgr;
		EventMgr2ChModule	: in Signal_EventMgr2ChModule;
		--adc signals
		AdcModule2Adc	: out	Signal_AdcModule2Adc;
		Adc2AdcModule	: in	Signal_Adc2AdcModule;
		--ch mgr(time, veto, ...)
		ChModule2ChMgr	: out	Signal_ChModule2ChMgr;
		ChMgr2ChModule	: in	Signal_ChMgr2ChModule;
		--debug
		Debug				: out std_logic_vector(7 downto 0);
		--clock and reset
		Clock				: in std_logic;
		ReadClock		: in std_logic;
		GlobalReset		: in std_logic
	);
end UserModule_ChModule;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_ChModule is

	---------------------------------------------------
	--Declarations of Components
	---------------------------------------------------
	--BusIF used for BusProcess(Bus Read/Write Process)
	component iBus_BusIFLite
		generic(
			InitialAddress	:	std_logic_vector(15 downto 0);
			FinalAddress	:	std_logic_vector(15 downto 0)
		);
		port(
			--connected to BusController
			BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
			BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
			
			--Connected to UserModule
			--UserModule master signal
			SendAddress			:	in 	std_logic_vector(15 downto 0);
			SendData				:	in 	std_logic_vector(15 downto 0);
			SendGo				:	in		std_logic;
			SendDone				:	out	std_logic;
			
			ReadAddress			:	in		std_logic_vector(15 downto 0);
			ReadData				:	out	std_logic_vector(15 downto 0);
			ReadGo				:	in		std_logic;
			ReadDone				:	out	std_logic;
			
			--UserModule target signal
			beReadAddress		:	out 	std_logic_vector(15 downto 0);
			beRead				:	out	std_logic;
			beReadData			:	in		std_logic_vector(15 downto 0);
			beReadDone			:	in		std_logic;
			
			beWrittenAddress		:	out 	std_logic_vector(15 downto 0);
			beWritten				:	out	std_logic;
			beWrittenData			:	out	std_logic_vector(15 downto 0);
			beWrittenDone			:	in		std_logic;
	
			Clock					:	in		std_logic;
			GlobalReset			:	in		std_logic
		);
	end component;

	component UserModule_ChModule_ADC
		port(
			ChModule2InternalModule	: in		Signal_ChModule2InternalModule;
			--
			AdcModule2Adc	: out	Signal_AdcModule2Adc;
			Adc2AdcModule	: in	Signal_Adc2AdcModule;
			AdcModule2ChModule	: out	Signal_AdcModule2ChModule;
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;
	
	component UserModule_ChModule_Trigger
		port(
			ChModule2InternalModule	:	in		Signal_ChModule2InternalModule;
			--
			AdcDataIn		:	in		std_logic_vector(ADCResolution-1 downto 0);
			--
			TriggerOut		:	out	std_logic;
			Veto		:	out	std_logic;
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;

	component UserModule_ChModule_Delay
		port(
			ChModule2InternalModule	:	in		Signal_ChModule2InternalModule;
			--
			AdcDataIn		:	in		std_logic_vector(ADCResolution-1 downto 0);
			AdcDataOut		:	out	std_logic_vector(ADCResolution-1 downto 0);
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;

	component UserModule_ChModule_Buffer
		generic(
			ChNumber			: std_logic_vector(2 downto 0)
		);
		port(
			ChModule2InternalModule	: in		Signal_ChModule2InternalModule;
			AdcDataIn		: in		std_logic_vector(AdcResolution-1 downto 0);
			DataOut			: out		std_logic_vector(FifoDataWidth-1 downto 0);
			--control
			TriggerIn		: in		std_logic;
			BufferNoGood	: out		std_logic;
			NoRoomForMoreEvent	: out		std_logic;
			BufferEmpty		: out		std_logic;
			hasEvent			: out		std_logic;
			--read out control signals
			ReadEnable		: in		std_logic;
			--clock and reset
			Clock				: in	std_logic;
			ReadClock		: in	std_logic;
			GlobalReset		: in	std_logic
		);
	end component;
	
	component UserModule_ChModule_FastVetoModule is
		port(
			AdcClock		:	in		std_logic;
			AdcData		:	in		std_logic_vector(ADCResolutionForFastVeto-1 downto 0);
			TriggerOut	:	out	std_logic;
			--parameters
			ThresholdDelta	:	in		std_logic_vector(15 downto 0); --in terms of ch
			WaitDurationAfterTriggeringInUnitsOfClock	:	in	std_logic_vector(15 downto 0);
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;
	
	component UserModule_ChModule_DigitalFilterTriggerModule is
		generic(
			Depth : integer range 0 to 16
		);
		port(
			--Input
			AdcClock		:	in		std_logic;
			AdcData		:	in integer range 0 to 4095;
			--Parameters
			CoefficientArray : in ArrayOf_Signed8bitInteger(Depth-1 downto 0); --singed 8bits
			Threshold	:	in		integer range 0 to 4095;
			Width	:	in	integer range 0 to 4095;
			--Output
			TriggerOut	:	out	std_logic;
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;
	
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



	---------------------------------------------------
	--Declarations of Signals
	---------------------------------------------------
	--Signals
	signal ChModule2InternalModule	: Signal_ChModule2InternalModule;
	signal InternalModule2ChModule	: Signal_InternalModule2ChModule;
	signal ADCModule2ChModule		: Signal_AdcModule2ChModule;
	
	signal delayed_AdcData	: std_logic_vector(AdcResolution-1 downto 0);
	signal BufferEmpty		: std_logic	:= '0';
	
	signal BufferNoGood			: std_logic	:= '0';
	signal NoRoomForMoreEvent	: std_logic	:= '0';
	signal hasEvent				: std_logic	:= '0';
	
	signal Trigger					: std_logic	:= '0';
	signal TriggerModuleVeto	: std_logic	:= '0';
	signal Veto_internal			: std_logic	:= '0';

	--Registers
	signal TriggerModeRegister			:	std_logic_vector(15 downto 0)	:= (others => '0');
	signal TriggerBusMaskRegister		:	std_logic_vector(15 downto 0)	:= (others => '0');
	signal NumberOfSamplesRegister	:	std_logic_vector(15 downto 0)	:= (others => '0');
	signal ThresholdStartingRegister	:	std_logic_vector(15 downto 0)	:= (others => '0');
	signal ThresholdClosingRegister	:	std_logic_vector(15 downto 0)	:= (others => '0');
	signal AdcPowerDownModeRegister	:	std_logic_vector(15 downto 0)	:= (others => '1');
	signal DepthOfDelayRegister		:	std_logic_vector(15 downto 0)	:= (others => '0');
	
	constant BA	:	std_logic_vector(15 downto 0) := InitialAddress; --Base Address
	constant AddressOf_TriggerModeRegister			:	std_logic_vector(15 downto 0) := BA+x"0002";
	constant AddressOf_NumberOfSamplesRegister	:	std_logic_vector(15 downto 0) := BA+x"0004";
	constant AddressOf_ThresholdStartingRegister	:	std_logic_vector(15 downto 0) := BA+x"0006";
	constant AddressOf_ThresholdClosingRegister	:	std_logic_vector(15 downto 0) := BA+x"0008";
	constant AddressOf_AdcPowerDownModeRegister	:	std_logic_vector(15 downto 0) := BA+x"000a";
	constant AddressOf_DepthOfDelayRegister		:	std_logic_vector(15 downto 0) := BA+x"000c";
	constant AddressOf_LivetimeRegisterL			:	std_logic_vector(15 downto 0) := BA+x"000e";
	constant AddressOf_LivetimeRegisterH			:	std_logic_vector(15 downto 0) := BA+x"0010";
	constant AddressOf_CurrentAdcDataRegister		:	std_logic_vector(15 downto 0) := BA+x"0012";
	constant AddressOf_CPUTrigger						:	std_logic_vector(15 downto 0) := BA+x"0014";
	
	constant AddressOf_DigitalFilterTrigger_ThresholdDeltaRegister						:	std_logic_vector(15 downto 0) := BA+x"0018";
	constant AddressOf_DigitalFilterTrigger_WidthRegister						:	std_logic_vector(15 downto 0) := BA+x"001a";
	constant AddressOf_DigitalFilterTrigger_HitPattern_FilterCoefficientSelectorRegister :	std_logic_vector(15 downto 0) := BA+x"0020";

	constant AddressOf_TriggerBusMaskRegister			:	std_logic_vector(15 downto 0) := BA+x"0024";
	
	--iBus_BusIFLite signals
	--Signals used in iBus process
	signal SendAddress			: std_logic_vector(15 downto 0);
	signal SendData				: std_logic_vector(15 downto 0);
	signal SendGo					: std_logic;
	signal SendDone				: std_logic;
	
	signal ReadAddress			: std_logic_vector(15 downto 0);
	signal ReadData				: std_logic_vector(15 downto 0);
	signal ReadGo					: std_logic;
	signal ReadDone				: std_logic;
	
	--UserModule target signal
	signal beReadAddress		: std_logic_vector(15 downto 0);
	signal beRead				: std_logic;
	signal beReadData			: std_logic_vector(15 downto 0);
	signal beReadDone			: std_logic;
	
	signal beWrittenAddress		: std_logic_vector(15 downto 0);
	signal beWritten				: std_logic;
	signal beWrittenData			: std_logic_vector(15 downto 0);
	signal beWrittenDone			: std_logic;
	
	--Registers
	
	--Counters
	
	--DigitalFilteringTrigger Module
	signal AdcData_Integer_AsUnsignedVector : integer range 0 to 4095 := 0;
	constant DigitalFilterTriggerModule_FastVeto_FilterDepth : integer := 8;
	constant DigitalFilterTriggerModule_HitPattern_FilterDepth : integer := 16;
	signal DigitalFilterTriggerModule_ThresholdDelta_Integer : integer range 0 to 4095 := 0;
	signal DigitalFilterTriggerModule_WaitDuration_Integer : integer range 0 to 4095 := 0;
	signal DigitalFilterTriggerModule_ThresholdDeltaRegister : std_logic_vector(15 downto 0) := x"0010";
	signal DigitalFilterTriggerModule_Width : std_logic_vector(15 downto 0) := x"0010";
	
	signal CoefficientArray_FastVeto : ArrayOf_Signed8bitInteger(DigitalFilterTriggerModule_FastVeto_FilterDepth-1 downto 0); --singed 8bits
	signal CoefficientArray_HitPattern : ArrayOf_Signed8bitInteger(DigitalFilterTriggerModule_HitPattern_FilterDepth-1 downto 0); --singed 8bits
	signal CoefficientArray_HitPattern_Type0 : ArrayOf_Signed8bitInteger(DigitalFilterTriggerModule_HitPattern_FilterDepth-1 downto 0); --singed 8bits
	signal CoefficientArray_HitPattern_Type1 : ArrayOf_Signed8bitInteger(DigitalFilterTriggerModule_HitPattern_FilterDepth-1 downto 0); --singed 8bits
	signal CoefficientArray_HitPattern_Type2 : ArrayOf_Signed8bitInteger(DigitalFilterTriggerModule_HitPattern_FilterDepth-1 downto 0); --singed 8bits
	signal CoefficientArray_HitPattern_Type3 : ArrayOf_Signed8bitInteger(DigitalFilterTriggerModule_HitPattern_FilterDepth-1 downto 0); --singed 8bits
	signal CoefficientArray_HitPattern_Selector : std_logic_vector(7 downto 0) := (others => '0');
	signal FastVeto_TriggerOut	:	std_logic := '0';
	signal HitPattern_TriggerOut : std_logic := '0';	

	--State Machines' State-variables
	type iBus_beWritten_StateMachine_State is
		(Initialize,	Idle,	WaitDone);
	signal iBus_beWritten_state : iBus_beWritten_StateMachine_State := Initialize;

	type iBus_beRead_StateMachine_State is
		(Initialize,	Idle,	WaitDone);
	signal iBus_beRead_state : iBus_beRead_StateMachine_State := Initialize;
	
--	type UserModule_StateMachine_State is
--		(Initialize);
--	signal UserModule_state : UserModule_StateMachine_State := Initialize;
	
	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin	
	
	---------------------------------------------------
	--Static relationships
	---------------------------------------------------
	--distribute realtime
	ChModule2InternalModule.Realtime
		<= ChMgr2ChModule.RealTime;
	--distribute veto
	Veto_internal
		<= '1' when InternalModule2ChModule.TriggerOut='1'
			or BufferNoGood='1' or AdcPowerDownModeRegister(0)='1' else '0';
	ChModule2InternalModule.Veto <= Veto_internal or ChMgr2ChModule.Veto;
	--dist trigger
	ChModule2InternalModule.TriggerMode <= TriggerModeRegister(WidthOfTriggerMode-1 downto 0);
	--dist trigger lines
	ChModule2InternalModule.TriggerBus <= ChMgr2ChModule.TriggerBus;
	--dist trigger bus mask
	ChModule2InternalModule.TriggerBusMask <= TriggerBusMaskRegister(WidthOfTriggerBus-1 downto 0);
	--dist common gate in
	ChModule2InternalModule.CommonGateIn <= ChMgr2ChModule.CommonGateIn;
	--dist adc power mode
	ChModule2InternalModule.AdcPowerDown <= AdcPowerDownModeRegister(0);
	--dist sample number
	ChModule2InternalModule.NumberOfSamples <= NumberOfSamplesRegister(WidthOfNumberOfSamples-1 downto 0);
	--dist threshold
	ChModule2InternalModule.ThresholdStarting <= ThresholdStartingRegister(ADCResolution-1 downto 0);
	ChModule2InternalModule.ThresholdClosing <= ThresholdClosingRegister(ADCResolution-1 downto 0);
	--dist depth of delay
	ChModule2InternalModule.DepthOfDelay <= DepthOfDelayRegister(WidthOfDepthOfDelay-1 downto 0);
	--dist size of header
	ChModule2InternalModule.SizeOfHeader <= conv_std_logic_vector(SizeOfHeader,WidthOfSizeOfHeader);
	--return veto signal to ch mgr
	ChModule2ChMgr.Veto <= Veto_internal or TriggerModuleVeto;
	--distribute FastVeto (APD+BGO Trigger)
	ChModule2InternalModule.FastVetoTrigger <= FastVeto_TriggerOut;
	--distribute HitPattern (APD+BGO Trigger)
	ChModule2InternalModule.HitPatternTrigger <= HitPattern_TriggerOut;
	
	--to EventMgr
	ChModule2EventMgr.hasData <= hasEvent;
	
	--debug
	Debug(0) <= ChModule2InternalModule.FastVetoTrigger;
	Debug(1) <= ChModule2InternalModule.HitPatternTrigger;
	
	---------------------------------------------------
	--Dynamic Processes with Sensitivity List
	---------------------------------------------------
--	--UserModule main state machine
--	MainProcess : process (Clock, GlobalReset)
--	begin
--		--is this process invoked with GlobalReset?
--		if (GlobalReset='0') then
--		--is this process invoked with Clock Event?
--		elsif (Clock'Event and Clock='1') then
--			case UserModule_state is
--				when Initialize =>
--				when others =>
--					UserModule_state <= Initialize;
--			end case;
--		end if;
--	end process;
	
	--processes beWritten access from BusIF
	--usually, set register value according to beWritten data
	iBus_beWritten_Process : process (ReadClock,GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			--Initialize StateMachine's state
			iBus_beWritten_state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (ReadClock'Event and ReadClock='1') then
			case iBus_beWritten_state is
				when Initialize =>
					ChModule2InternalModule.CPUTrigger <= '0';
					--move to next state
					iBus_beWritten_state <= Idle;
				when Idle =>
					if (beWritten='1') then
--						case beWrittenAddress is
--							when AddressOf_TriggerModeRegister =>
--								TriggerModeRegister(WidthOfTriggerMode-1 downto 0) <= beWrittenData(WidthOfTriggerMode-1 downto 0);
--							when AddressOf_NumberOfSamplesRegister =>
--								NumberOfSamplesRegister(WidthOfNumberOfSamples-1 downto 0) <= beWrittenData(WidthOfNumberOfSamples-1 downto 0);
--							when AddressOf_ThresholdStartingRegister =>
--								ThresholdStartingRegister(ADCResolution-1 downto 0) <= beWrittenData(ADCResolution-1 downto 0);
--							when AddressOf_ThresholdClosingRegister =>
--								ThresholdClosingRegister(ADCResolution-1 downto 0) <= beWrittenData(ADCResolution-1 downto 0);
--							when AddressOf_AdcPowerDownModeRegister =>
--								AdcPowerDownModeRegister(0) <= beWrittenData(0);
--							when AddressOf_DepthOfDelayRegister =>
--								DepthOfDelayRegister(WidthOfDepthOfDelay-1 downto 0) <= beWrittenData(WidthOfDepthOfDelay-1 downto 0);
--							when AddressOf_CPUTrigger =>
--								ChModule2InternalModule.CPUTrigger <= '1';
--							when others =>
--						end case;

						if (beWrittenAddress=AddressOf_TriggerModeRegister) then
								TriggerModeRegister(WidthOfTriggerMode-1 downto 0) <= beWrittenData(WidthOfTriggerMode-1 downto 0);
						elsif (beWrittenAddress=AddressOf_TriggerBusMaskRegister) then
								TriggerBusMaskRegister(WidthOfTriggerBus-1 downto 0) <= beWrittenData(WidthOfTriggerBus-1 downto 0);
						elsif (beWrittenAddress=AddressOf_NumberOfSamplesRegister) then
								NumberOfSamplesRegister(WidthOfNumberOfSamples-1 downto 0) <= beWrittenData(WidthOfNumberOfSamples-1 downto 0);
						elsif (beWrittenAddress=AddressOf_ThresholdStartingRegister) then
								ThresholdStartingRegister(ADCResolution-1 downto 0) <= beWrittenData(ADCResolution-1 downto 0);
						elsif (beWrittenAddress=AddressOf_ThresholdClosingRegister) then
								ThresholdClosingRegister(ADCResolution-1 downto 0) <= beWrittenData(ADCResolution-1 downto 0);
						elsif (beWrittenAddress=AddressOf_AdcPowerDownModeRegister) then
								AdcPowerDownModeRegister(0) <= beWrittenData(0);
						elsif (beWrittenAddress=AddressOf_DepthOfDelayRegister) then
								DepthOfDelayRegister(WidthOfDepthOfDelay-1 downto 0) <= beWrittenData(WidthOfDepthOfDelay-1 downto 0);
						elsif (beWrittenAddress=AddressOf_CPUTrigger) then
								ChModule2InternalModule.CPUTrigger <= '1';
						elsif (beWrittenAddress=AddressOf_DigitalFilterTrigger_ThresholdDeltaRegister) then
								DigitalFilterTriggerModule_ThresholdDeltaRegister <= beWrittenData;
						elsif (beWrittenAddress=AddressOf_DigitalFilterTrigger_WidthRegister) then
								DigitalFilterTriggerModule_Width <= beWrittenData;
						elsif (beWrittenAddress=AddressOf_DigitalFilterTrigger_HitPattern_FilterCoefficientSelectorRegister) then
								CoefficientArray_HitPattern_Selector <= beWrittenData(7 downto 0);
						end if;

						--tell completion of the "beRead" process to iBus_BusIF
						beWrittenDone <= '1';
						--move to next state
						iBus_beWritten_state  <= WaitDone;
					else
						--ordinary "Idle" state
						ChModule2InternalModule.CPUTrigger <= '0';
					end if;
				when WaitDone =>
					--wait until the "beRead" process completes
					if (beWritten='0') then
						beWrittenDone <= '0';
						--move to next state
						iBus_beWritten_state  <= Idle;
					end if;
				when others =>
					--move to next state
					iBus_beWritten_state  <= Initialize;
			end case;
		end if;
	end process;


	--processes beRead access from BusIF
	--usually, return register value according to beRead-Address
	iBus_beRead_Process : process (ReadClock,GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			--Initialize StateMachine's state
			iBus_beRead_state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (ReadClock'Event and ReadClock='1') then
			case iBus_beRead_state is
				when Initialize =>
					--move to next state
					iBus_beRead_state <= Idle;
				when Idle =>
					if (beRead='1') then
--						case beReadAddress is
--							when AddressOf_TriggerModeRegister =>
--								beReadData <= TriggerModeRegister;
--							when AddressOf_NumberOfSamplesRegister =>
--								beReadData <= NumberOfSamplesRegister;
--							when AddressOf_ThresholdStartingRegister =>
--								beReadData <= ThresholdStartingRegister;
--							when AddressOf_ThresholdClosingRegister =>
--								beReadData <= ThresholdClosingRegister;
--							when AddressOf_AdcPowerDownModeRegister =>
--								beReadData <= AdcPowerDownModeRegister;
--							when AddressOf_DepthOfDelayRegister =>
--								beReadData <= DepthOfDelayRegister;
--							when AddressOf_LivetimeRegisterL =>
--								beReadData <= ChMgr2ChModule.Livetime(15 downto 0);
--							when AddressOf_LivetimeRegisterH =>
--								beReadData <= ChMgr2ChModule.Livetime(31 downto 16);
--							when AddressOf_CurrentAdcDataRegister =>
--								beReadData(15 downto 12) <= "0000";
--								beReadData(AdcResolution-1 downto 0) <= Adc2AdcModule.AdcD;
--							when others =>
--								--sonzai shina address heno yomikomi datta tokiha
--								--0xabcd toiu tekitou na value wo kaeshite oku kotoni shitearu
--								beReadData <= x"abcd";
--						end case;

						if (beReadAddress=AddressOf_TriggerModeRegister) then
								beReadData <= TriggerModeRegister;
						elsif (beReadAddress=AddressOf_TriggerBusMaskRegister) then
								beReadData <= TriggerBusMaskRegister;
						elsif (beReadAddress=AddressOf_NumberOfSamplesRegister) then
								beReadData <= NumberOfSamplesRegister;
						elsif (beReadAddress=AddressOf_ThresholdStartingRegister) then
								beReadData <= ThresholdStartingRegister;
						elsif (beReadAddress=AddressOf_ThresholdClosingRegister) then
								beReadData <= ThresholdClosingRegister;
						elsif (beReadAddress=AddressOf_AdcPowerDownModeRegister) then
								beReadData <= AdcPowerDownModeRegister;
						elsif (beReadAddress=AddressOf_DepthOfDelayRegister) then
								beReadData <= DepthOfDelayRegister;
						elsif (beReadAddress=AddressOf_LivetimeRegisterL) then
								beReadData <= ChMgr2ChModule.Livetime(15 downto 0);
						elsif (beReadAddress=AddressOf_LivetimeRegisterH) then
								beReadData <= ChMgr2ChModule.Livetime(31 downto 16);
						elsif (beReadAddress=AddressOf_CurrentAdcDataRegister) then
								beReadData(15 downto 12) <= "0000";
								beReadData(AdcResolution-1 downto 0) <= Adc2AdcModule.AdcD;
						elsif (beReadAddress=AddressOf_DigitalFilterTrigger_ThresholdDeltaRegister) then
								beReadData <= DigitalFilterTriggerModule_ThresholdDeltaRegister;
						elsif (beReadAddress=AddressOf_DigitalFilterTrigger_WidthRegister) then
								beReadData <= DigitalFilterTriggerModule_Width;
						elsif (beReadAddress=AddressOf_DigitalFilterTrigger_HitPattern_FilterCoefficientSelectorRegister) then
								beReadData <= x"00" & CoefficientArray_HitPattern_Selector;
						else
								--sonzai shina address heno yomikomi datta tokiha
								--0xabcd toiu tekitou na value wo kaeshite oku kotoni shitearu
								beReadData <= x"abcd";
						end if;

						--tell completion of the "beRead" process to iBus_BusIF
						beReadDone <= '1';
						--move to next state
						iBus_beRead_state  <= WaitDone;
					end if;
				when WaitDone =>
					--wait until the "beRead" process completes
					if (beRead='0') then
						beReadDone <= '0';
						--move to next state
						iBus_beRead_state  <= Idle;
					end if;
				when others =>
					--move to next state
					iBus_beRead_state  <= Initialize;
			end case;
		end if;
	end process;
	
	---------------------------------------------------
	--Instantiations of Components
	---------------------------------------------------
	--Instantiation of iBus_BusIF
	BusIF : iBus_BusIFLite
		generic map(
			InitialAddress		=>	InitialAddress,
			FinalAddress		=>	FinalAddress
		)
		port map(
			--connected to BusController
			BusIF2BusController	=>	BusIF2BusController,
			BusController2BusIF	=>	BusController2BusIF,
			--Connected to UserModule
			--UserModule master signal
			SendAddress => SendAddress,
			SendData => SendData,
			SendGo => SendGo,
			SendDone => SendDone,
			
			ReadAddress =>ReadAddress,
			ReadData => ReadData,
			ReadGo => ReadGo,
			ReadDone => ReadDone,
			
			--UserModule target signal
			beReadAddress => beReadAddress,
			beRead => beRead,
			beReadData => beReadData,
			beReadDone => beReadDone,
			
			beWrittenAddress => beWrittenAddress,
			beWritten => beWritten,
			beWrittenData => beWrittenData,
			beWrittenDone => beWrittenDone,

			Clock			=>	ReadClock,
			GlobalReset	=> GlobalReset
		);

	inst_AdcModule : UserModule_ChModule_ADC
		port map(
			--signals connected to BusController
			ChModule2InternalModule	=> ChModule2InternalModule,
			--
			Adc2AdcModule	=> Adc2AdcModule,
			AdcModule2Adc	=> AdcModule2Adc,
			AdcModule2ChModule	=> AdcModule2ChModule,
			--clock and reset
			Clock	=> Clock,
			GlobalReset	=> GlobalReset
		);


	------------------------------------------
	--DigitalFilterTrigger-related modules
	------------------------------------------
	inst_UserModule_Utility_ToIntegerFromUnsignedVector0 : UserModule_Utility_ToIntegerFromUnsignedVector
		generic map(Width => 8)
		port map(
			Input => AdcModule2ChModule.AdcData(11 downto 4),
			Output => AdcData_Integer_AsUnsignedVector
		);

	inst_UserModule_Utility_ToIntegerFromUnsignedVector1 : UserModule_Utility_ToIntegerFromUnsignedVector
		generic map(Width => 16)
		port map(
			Input => DigitalFilterTriggerModule_ThresholdDeltaRegister,
			Output => DigitalFilterTriggerModule_ThresholdDelta_Integer
		);

	inst_UserModule_Utility_ToIntegerFromUnsignedVector2 : UserModule_Utility_ToIntegerFromUnsignedVector
		generic map(Width => 16)
		port map(
			Input => DigitalFilterTriggerModule_Width,
			Output => DigitalFilterTriggerModule_WaitDuration_Integer
		);
		
	------------------------------------------
	--DigitalFilterTrigger : FastVeto
	------------------------------------------
	CoefficientArray_FastVeto(0) <= -1;
	CoefficientArray_FastVeto(1) <= -1;
	CoefficientArray_FastVeto(2) <= -1;
	CoefficientArray_FastVeto(3) <= -1;
	CoefficientArray_FastVeto(4) <= 1;
	CoefficientArray_FastVeto(5) <= 1;
	CoefficientArray_FastVeto(6) <= 1;
	CoefficientArray_FastVeto(7) <= 1;

	inst_FastVetoModule : UserModule_ChModule_DigitalFilterTriggerModule
		generic map(
			Depth => DigitalFilterTriggerModule_FastVeto_FilterDepth
		)
		port map(
			--Input
			AdcClock		=> Clock,
			AdcData		=> AdcData_Integer_AsUnsignedVector,
			--Parameters
			CoefficientArray => CoefficientArray_FastVeto,
			Threshold	=> DigitalFilterTriggerModule_ThresholdDelta_Integer,
			Width	=> DigitalFilterTriggerModule_WaitDuration_Integer,
			--Output
			TriggerOut	=> FastVeto_TriggerOut,
			--clock and reset
			Clock			=> ReadClock,
			GlobalReset	=> GlobalReset
		);	
	
	------------------------------------------
	--DigitalFilterTrigger : FastVeto
	------------------------------------------
	CoefficientArray_HitPattern_Type0(0) <= -1;
	CoefficientArray_HitPattern_Type0(1) <= -1;
	CoefficientArray_HitPattern_Type0(2) <= -1;
	CoefficientArray_HitPattern_Type0(3) <= -1;
	CoefficientArray_HitPattern_Type0(4) <= 1;
	CoefficientArray_HitPattern_Type0(5) <= 1;
	CoefficientArray_HitPattern_Type0(6) <= 1;
	CoefficientArray_HitPattern_Type0(7) <= 1;
	CoefficientArray_HitPattern_Type0(8) <= 0;
	CoefficientArray_HitPattern_Type0(9) <= 0;
	CoefficientArray_HitPattern_Type0(10) <= 0;
	CoefficientArray_HitPattern_Type0(11) <= 0;
	CoefficientArray_HitPattern_Type0(12) <= 0;
	CoefficientArray_HitPattern_Type0(13) <= 0;
	CoefficientArray_HitPattern_Type0(14) <= 0;
	CoefficientArray_HitPattern_Type0(15) <= 0;	
	
	CoefficientArray_HitPattern_Type1(0) <= -1;
	CoefficientArray_HitPattern_Type1(1) <= -1;
	CoefficientArray_HitPattern_Type1(2) <= -1;
	CoefficientArray_HitPattern_Type1(3) <= -1;
	CoefficientArray_HitPattern_Type1(4) <= 0;
	CoefficientArray_HitPattern_Type1(5) <= 0;
	CoefficientArray_HitPattern_Type1(6) <= 0;
	CoefficientArray_HitPattern_Type1(7) <= 1;
	CoefficientArray_HitPattern_Type1(8) <= 1;
	CoefficientArray_HitPattern_Type1(9) <= 1;
	CoefficientArray_HitPattern_Type1(10) <= 1;
	CoefficientArray_HitPattern_Type1(11) <= 0;
	CoefficientArray_HitPattern_Type1(12) <= 0;
	CoefficientArray_HitPattern_Type1(13) <= 0;
	CoefficientArray_HitPattern_Type1(14) <= 0;
	CoefficientArray_HitPattern_Type1(15) <= 0;	

	CoefficientArray_HitPattern_Type2(0) <= -1;
	CoefficientArray_HitPattern_Type2(1) <= -1;
	CoefficientArray_HitPattern_Type2(2) <= -1;
	CoefficientArray_HitPattern_Type2(3) <= -1;
	CoefficientArray_HitPattern_Type2(4) <= -1;
	CoefficientArray_HitPattern_Type2(5) <= -1;
	CoefficientArray_HitPattern_Type2(6) <= 0;
	CoefficientArray_HitPattern_Type2(7) <= 0;
	CoefficientArray_HitPattern_Type2(8) <= 0;
	CoefficientArray_HitPattern_Type2(9) <= 0;
	CoefficientArray_HitPattern_Type2(10) <= 1;
	CoefficientArray_HitPattern_Type2(11) <= 1;
	CoefficientArray_HitPattern_Type2(12) <= 1;
	CoefficientArray_HitPattern_Type2(13) <= 1;
	CoefficientArray_HitPattern_Type2(14) <= 1;
	CoefficientArray_HitPattern_Type2(15) <= 1;	

	CoefficientArray_HitPattern <= 
		CoefficientArray_HitPattern_Type1 when CoefficientArray_HitPattern_Selector=x"01" else
		CoefficientArray_HitPattern_Type2 when CoefficientArray_HitPattern_Selector=x"02" else
		CoefficientArray_HitPattern_Type3 when CoefficientArray_HitPattern_Selector=x"03" else
		CoefficientArray_HitPattern_Type0; --default filter is the same as that of FastVeto
		
	inst_HitPatternModule : UserModule_ChModule_DigitalFilterTriggerModule
		generic map(
			Depth => DigitalFilterTriggerModule_HitPattern_FilterDepth
		)
		port map(
			--Input
			AdcClock		=> Clock,
			AdcData		=> AdcData_Integer_AsUnsignedVector,
			--Parameters
			CoefficientArray => CoefficientArray_HitPattern,
			Threshold	=> DigitalFilterTriggerModule_ThresholdDelta_Integer,
			Width	=> DigitalFilterTriggerModule_WaitDuration_Integer,
			--Output
			TriggerOut	=> HitPattern_TriggerOut,
			--clock and reset
			Clock			=> ReadClock,
			GlobalReset	=> GlobalReset
		);

	inst_TriggerModule : UserModule_ChModule_Trigger
		port map(
			ChModule2InternalModule	=> ChModule2InternalModule,
			--
			AdcDataIn	=> AdcModule2ChModule.AdcData,
			--
			TriggerOut	=> Trigger,
			Veto			=> TriggerModuleVeto,
			--clock and reset
			Clock	=> Clock,
			GlobalReset	=> GlobalReset
		);
	
	ChModule2ChMgr.Trigger <= Trigger;
	InternalModule2ChModule.TriggerOut <= Trigger;
	
	inst_DelayModule : UserModule_ChModule_Delay
		port map(
			ChModule2InternalModule	=> ChModule2InternalModule,
			--
			AdcDataIn		=> AdcModule2ChModule.AdcData,
			AdcDataOut		=> delayed_AdcData,
			--clock and reset
			Clock	=> Clock,
			GlobalReset	=> GlobalReset
		);

	inst_BufferModule : UserModule_ChModule_Buffer
		generic map(
			ChNumber	=> ChNumber
		)
		port map(
			ChModule2InternalModule	=> ChModule2InternalModule,
			AdcDataIn		=> delayed_AdcData,
			DataOut			=> ChModule2EventMgr.Data,
			--control
			TriggerIn		=> InternalModule2ChModule.TriggerOut,
			BufferNoGood	=> BufferNoGood,
			NoRoomForMoreEvent	=> NoRoomForMoreEvent,
			BufferEmpty		=> BufferEmpty,
			hasEvent			=> hasEvent,
			--read out control signals
			ReadEnable		=> EventMgr2ChModule.ReadEnable, 
			--clock and reset
			Clock	=> Clock,
			ReadClock	=> ReadClock,
			GlobalReset	=> GlobalReset
		);

end Behavioral;