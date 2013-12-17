--UserFPGA.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--
--ver 20071021 Takayuki Yuasa
--SpaceWire ADC Box

---------------------------------------------------
--Declarations of Libraries
---------------------------------------------------
library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.iBus_Library.all;
use work.iBus_AddressMap.all;
use work.UserModule_Library.all;

library unisim;
use unisim.Vcomponents.ALL;

---------------------------------------------------
--Entity Declaration
---------------------------------------------------
entity UserFPGA is
	port (
		ClockIn		:	in		std_logic;
		ClockOut		:	out	std_logic;
		ClockBack	:	in		std_logic;
		Clock100MHz	:	in		std_logic;
		AdcClockOut	:	out	std_logic;
		LockedIn		:	in		std_logic;
		GlobalReset	:	in		std_logic;
		
		GateIn_In	:	in		std_logic;
		DIO_Out		:	out	std_logic_vector(7 downto 0);
		DIO_In		:	in		std_logic_vector(3 downto 0);

		UserFPGA2Adc_vector	: out	Signal_UserFPGA2Adc_Vector(7 downto 0);
		Adc2UserFPGA_vector	: in	Signal_Adc2UserFPGA_Vector(7 downto 0);
		
		LEDs			:	out	std_logic_vector (3 downto 0); 
		Switches		:	in		std_logic_vector (3 downto 0);
		
		eBus_Enable		: in std_logic; 
		eBus_Done		: out std_logic;
		eBus_Address	: in std_logic_vector (24 downto 0);
		eBus_DataIn		: in std_logic_vector (15 downto 0); 
		eBus_DataOut	: out std_logic_vector (15 downto 0); 
		eBus_Write		: in std_logic; 
		eBus_Read		: in std_logic;
		meBus_Request	: out std_logic;
		meBus_Grant		: in std_logic;
		meBus_Enable	: in std_logic;
		meBus_Done		: in std_logic;
		meBus_Address	: out std_logic_vector(24 downto 0);
		meBus_Read		: out std_logic;
		meBus_Write		: out std_logic;
		meBus_DataIn	: in std_logic_vector (15 downto 0); 
		meBus_DataOut	: out std_logic_vector (15 downto 0); 

		Sdram_cke		: out std_logic;
		Sdram_xdcs		: out std_logic;
		Sdram_xdras		: out std_logic;
		Sdram_xdcas		: out std_logic;
		Sdram_xdwe		: out std_logic;
		Sdram_ldqm		: out std_logic;
		Sdram_udqm		: out std_logic;
		Sdram_sda		: out std_logic_vector (12 downto 0);
		Sdram_ba			: out std_logic_vector (1 downto 0);
		Sdram_sdd		: inout std_logic_vector (15 downto 0);

		Revision			: in std_logic_vector (15 downto 0) 
	);
end UserFPGA;


---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserFPGA is

	---------------------------------------------------
	--Declarations of Components
	---------------------------------------------------

	COMPONENT UserModule_ClockGenerator_Core
		PORT(
			CLKIN_IN		: IN std_logic;
			RST_IN		: IN std_logic;          
			CLKDV_OUT	: OUT std_logic;
			CLKFX_OUT	: OUT std_logic;
			CLKIN_IBUFG_OUT	: OUT std_logic;
			CLK0_OUT		: OUT std_logic;
			LOCKED_OUT	: OUT std_logic
		);
	END COMPONENT;
	
	--iBus BusController
	component iBus_BusController
		generic(
			NumberOfNodes	:	Integer range 0 to 128
		);
		port(
			--connected to BusIFs
			BusIF2BusController	:	in	iBus_Signals_BusIF2BusController_Vector(NumberOfNodes-1 downto 0);
			BusController2BusIF	:	out	iBus_Signals_BusController2BusIF_Vector(NumberOfNodes-1 downto 0);
			Clock					:	in		std_logic;
			GlobalReset			:	in		std_logic
		);
	end component;
	
	--e2iConnector
	component iBus_e2iConnector
		generic(
			InitialAddress	:	std_logic_vector(15 downto 0);
			FinalAddress	:	std_logic_vector(15 downto 0)
		);
		port(
			--connected to BusController
			BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
			BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
			eBus_Enable			: in std_logic; 
			eBus_Done			: out std_logic;
			eBus_Address		: in std_logic_vector (24 downto 0);
			eBus_DataIn			: in std_logic_vector (15 downto 0); 
			eBus_DataOut		: out std_logic_vector (15 downto 0); 
			eBus_Write			: in std_logic; 
			eBus_Read			: in std_logic;
			meBus_Request		: out std_logic;
			meBus_Enable		: in std_logic;
			meBus_Grant			: in std_logic;
			meBus_Done			: in std_logic;
			meBus_Address		: out std_logic_vector(24 downto 0);
			meBus_Read			: out std_logic;
			meBus_Write			: out std_logic;
			meBus_DataIn		: in std_logic_vector (15 downto 0); 
			meBus_DataOut		: out std_logic_vector (15 downto 0); 
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;
	
	--Template_Lite
	component UserModule_Template_with_BusIFLite
		generic(
			InitialAddress	:	std_logic_vector(15 downto 0);
			FinalAddress	:	std_logic_vector(15 downto 0)
		);
		port(
			--signals connected to BusController
			BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
			BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
			--other signals
			OutputSignal	:	out	std_logic_vector(15 downto 0);
			InputSignal		:	in		std_logic_vector(15 downto 0);
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;

	--Template
	component UserModule_Template_with_BusIF
		generic(
			InitialAddress	:	std_logic_vector(15 downto 0);
			FinalAddress	:	std_logic_vector(15 downto 0)
		);
		port(
			--signals connected to BusController
			BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
			BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
			--other signals
			OutputSignal	:	out	std_logic_vector(15 downto 0);
			InputSignal		:	in		std_logic_vector(15 downto 0);
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;
	
	component UserModule_ChMgr
		generic(
			InitialAddress	: std_logic_vector(15 downto 0);
			FinalAddress	: std_logic_vector(15 downto 0)
		);
		port(
			--signals connected to BusController
			BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
			BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
			--ch mgr(time, veto, ...)
			ChMgr2ChModule_vector	: out	Signal_ChMgr2ChModule_Vector(NumberOfProducerNodes-1 downto 0);
			ChModule2ChMgr_vector	: in	Signal_ChModule2ChMgr_Vector(NumberOfProducerNodes-1 downto 0);
			--control
			CommonGateIn	: in std_logic;
			--clock and reset
			Clock				: in std_logic;
			Clock100MHz		: in	std_logic;
			AdcClockOut		: out std_logic;
			GlobalReset		: in std_logic;
			ResetOut			: out std_logic -- 0=reset, 1=no reset
		);
	end component;
	
	component UserModule_ChModule
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
	end component;

	component UserModule_ConsumerMgr
		generic(
			InitialAddress	: std_logic_vector(15 downto 0);
			FinalAddress	: std_logic_vector(15 downto 0)
		);
		port(
			--signals connected to BusController
			BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
			BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
			--signals connected to ConsumerModule
			Consumer2ConsumerMgr_vector	: in	Signal_Consumer2ConsumerMgr_Vector(NumberOfConsumerNodes-1 downto 0);
			ConsumerMgr2Consumer_vector	: out	Signal_ConsumerMgr2Consumer_Vector(NumberOfConsumerNodes-1 downto 0);
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;

	component UserModule_ConsumerModule_Calculator_MaxValue_PSD_simple
		generic(
			ConsumerNumber	: integer range 0 to NumberOfConsumerNodes-1	:=0
		);
		port(
			EventMgr2Consumer	: in		Signal_EventMgr2Consumer;
			Consumer2EventMgr	: out		Signal_Consumer2EventMgr;
			--
			Consumer2ConsumerMgr	: out	Signal_Consumer2ConsumerMgr;
			ConsumerMgr2Consumer	: in	Signal_ConsumerMgr2Consumer;
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;

	component UserModule_ConsumerModule_Calculator_MaxValue_PSD
		generic(
			ConsumerNumber	: integer range 0 to NumberOfConsumerNodes-1	:=0
		);
		port(
			EventMgr2Consumer	: in		Signal_EventMgr2Consumer;
			Consumer2EventMgr	: out		Signal_Consumer2EventMgr;
			--
			Consumer2ConsumerMgr	: out	Signal_Consumer2ConsumerMgr;
			ConsumerMgr2Consumer	: in	Signal_ConsumerMgr2Consumer;
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;
	
	component UserModule_ConsumerModule_Calculator_MaxValue
		generic(
			ConsumerNumber	: integer range 0 to NumberOfConsumerNodes-1	:=0
		);
		port(
			EventMgr2Consumer	: in		Signal_EventMgr2Consumer;
			Consumer2EventMgr	: out		Signal_Consumer2EventMgr;
			--
			Consumer2ConsumerMgr	: out	Signal_Consumer2ConsumerMgr;
			ConsumerMgr2Consumer	: in	Signal_ConsumerMgr2Consumer;
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;

	component UserModule_EventMgrModule
		port(
			ChModule2EventMgr_vector	: in Signal_ChModule2EventMgr_Vector(NumberOfProducerNodes-1 downto 0);
			EventMgr2ChModule_vector	: out Signal_EventMgr2ChModule_Vector(NumberOfProducerNodes-1 downto 0);
			Consumer2EventMgr_vector	: in Signal_Consumer2EventMgr_Vector(NumberOfConsumerNodes-1 downto 0);
			EventMgr2Consumer_vector	: out Signal_EventMgr2Consumer_Vector(NumberOfConsumerNodes-1 downto 0);
			--clock and reset
			Clock				: in	std_logic;
			GlobalReset		: in	std_logic
		);
	end component;
	
	--for simulation
	component UserModule_Simulation_Commander
		generic(
			InitialAddress	:	std_logic_vector(15 downto 0);
			FinalAddress	:	std_logic_vector(15 downto 0)
		);
		port(
			--signals connected to BusController
			BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
			BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
			--other signals
			Start	:	in	std_logic;
			ADC	:	out std_logic_vector(AdcResolution-1 downto 0);
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;
	
	--for simulation
	component UserModule_simulator
		generic(
			InitialAddress	:	std_logic_vector(15 downto 0);
			FinalAddress	:	std_logic_vector(15 downto 0)
		);
		port(
			--signals connected to BusController
			BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
			BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
			--status input
			GoOrNoGo	:	in	std_logic;
			CommonGate : out std_logic;
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;

	component UserModule_LED
		generic(
			InitialAddress	:	std_logic_vector(15 downto 0);
			FinalAddress	:	std_logic_vector(15 downto 0)
		);
		port(
			--signals connected to BusController
			BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
			BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
			--other signals
			LED	:	out	std_logic_vector(1 downto 0);
			--clock and reset
			Clock			:	in		std_logic;
			GlobalReset	:	in		std_logic
		);
	end component;
	
	component UserModule_SDRAMC
		generic(
			InitialAddress	:	std_logic_vector(15 downto 0);
			FinalAddress	:	std_logic_vector(15 downto 0)
		);
		port(
			--signals connected to BusController
			BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
			BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
			--
			Sdram_cke		: out std_logic;
			Sdram_xdcs		: out std_logic;
			Sdram_xdras		: out std_logic;
			Sdram_xdcas		: out std_logic;
			Sdram_xdwe		: out std_logic;
			Sdram_ldqm		: out std_logic;
			Sdram_udqm		: out std_logic;
			Sdram_sda		: out std_logic_vector (12 downto 0);
			Sdram_ba			: out std_logic_vector (1 downto 0);
			Sdram_sdd		: inout std_logic_vector (15 downto 0);
			debug				: out std_logic;
			--clock and reset
			Clock100MHz		: in std_logic;
			Clock50MHz		: in std_logic;
			GlobalReset		: in std_logic
		);
	end component;
	---------------------------------------------------
	--Declarations of Signals
	---------------------------------------------------
	--clock signal
	signal Clock	: std_logic	:= '0';
	
	--Signals for InternalBus connection
	--these signals are used to connect BusController and
	--each BusIFModule contained in UserModules
	signal BusIF2BusController
				:	iBus_Signals_BusIF2BusController_Vector(NumberOfNodes-1 downto 0);
	signal BusController2BusIF
				:	iBus_Signals_BusController2BusIF_Vector(NumberOfNodes-1 downto 0);
	signal test_BusController2BusIF
				:	iBus_Signals_BusController2BusIF;
	
	signal ChMgr2ChModule_vector	: Signal_ChMgr2ChModule_vector(NumberOfProducerNodes-1 downto 0);
	signal ChModule2ChMgr_vector	: Signal_ChModule2ChMgr_vector(NumberOfProducerNodes-1 downto 0);
	
	signal ChModule2EventMgr_vector		: Signal_ChModule2EventMgr_vector(NumberOfProducerNodes-1 downto 0);
	signal EventMgr2ChModule_vector		: Signal_EventMgr2ChModule_vector(NumberOfProducerNodes-1 downto 0);
	
	signal EventMgr2Consumer_vector	: Signal_EventMgr2Consumer_vector(NumberOfConsumerNodes-1 downto 0);
	signal Consumer2EventMgr_vector	: Signal_Consumer2EventMgr_vector(NumberOfConsumerNodes-1 downto 0);
	
	signal Consumer2ConsumerMgr_vector	: Signal_Consumer2ConsumerMgr_vector(NumberOfConsumerNodes-1 downto 0);
	signal ConsumerMgr2Consumer_vector	: Signal_ConsumerMgr2Consumer_vector(NumberOfConsumerNodes-1 downto 0);
	
	signal AdcModule2Adc_vector	: Signal_AdcModule2Adc_vector(NumberOfProducerNodes-1 downto 0);
	signal Adc2AdcModule_vector	: Signal_Adc2AdcModule_vector(NumberOfProducerNodes-1 downto 0);
	
	--debug
	signal AdcModule2Adc_Dummy	: Signal_AdcModule2Adc;
	
	signal Debug_vector				: Signal_std_logic_vector8(NumberOfProducerNodes-1 downto 0);
	
	--signal
	signal in_signal		: std_logic_vector(15 downto 0) := x"bbbb";
	signal SoftReset		: std_logic	:= '0';
	signal LED_internal	: std_logic_vector(3 downto 0)	:= "0000";
	signal counter			: integer range 0 to 12000000 := 0;
	signal AdcClock			: std_logic	:= '0';
	signal rst_in   : std_logic := '0';
	
	--for simulation
	signal CommonGate : std_logic;
	
	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin
	
	---------------------------------------------------
	--Instantiations of Components
	---------------------------------------------------

	ClockOut <= Clock;
	Clock <= ClockIn;
	AdcClockOut <= AdcClock;
	
	--instantiate InternalBusController
	BusController : iBus_BusController
		generic map(NumberOfNodes)
			--there are "NumberOfUserModules" of UserModules in this template
		port map(
			--connected to BusIFs
			BusIF2BusController	=> BusIF2BusController,
			BusController2BusIF	=> BusController2BusIF,
			Clock			=>	Clock,
			GlobalReset =>	GlobalReset
		);
	
	e2iConnector : iBus_e2iConnector
		generic map(
			InitialAddress	=> InitialAddressOfe2iConnector,
			FinalAddress	=>	FinalAddressOfe2iConnector
		)
		port map(
			--connected to BusController
			BusIF2BusController	=>	BusIF2BusController(0),
			BusController2BusIF	=>	BusController2BusIF(0),
			eBus_Enable		=> eBus_Enable,
			eBus_Done		=> eBus_Done,
			eBus_Address	=> eBus_Address,
			eBus_DataIn		=> eBus_DataIn,
			eBus_DataOut	=> eBus_DataOut,
			eBus_Write		=> eBus_Write,
			eBus_Read		=> eBus_Read,
			meBus_Request	=> meBus_Request,
			meBus_Grant		=> meBus_Grant,
			meBus_Enable	=> meBus_Enable,
			meBus_Done		=> meBus_Done,
			meBus_Address	=> meBus_Address,
			meBus_DataIn	=> meBus_DataIn,
			meBus_DataOut	=> meBus_DataOut,
			meBus_Write		=> meBus_Write,
			meBus_Read		=> meBus_Read,
			Clock			=>	Clock,
			GlobalReset	=>	GlobalReset
		);


	inst_ChMgr : UserModule_ChMgr
		generic map(
			InitialAddress	=> InitialAddressOf_ChMgr,
			FinalAddress	=> FinalAddressOf_ChMgr
		)
		port map(
			--signals connected to BusController
			BusIF2BusController	=>	BusIF2BusController(1),
			BusController2BusIF	=>	BusController2BusIF(1),
			--ch mgr(time, veto, ...)
			ChMgr2ChModule_vector	=> ChMgr2ChModule_vector,
			ChModule2ChMgr_vector	=> ChModule2ChMgr_vector,
			--control
			CommonGateIn	=> GateIn_In, --for simulation
			--clock and reset
			Clock				=> Clock,
			Clock100MHz		=> Clock100MHz,
			AdcClockOut		=> AdcClock,
			GlobalReset		=> GlobalReset,
			ResetOut			=> SoftReset
		);
------------------------------
	inst_ChModule_0 : UserModule_ChModule
		generic map(
			InitialAddress	=> InitialAddressOf_ChModule_0,
			FinalAddress	=> FinalAddressOf_ChModule_0,
			ChNumber			=> "000"
		)
		port map(
			--signals connected to BusController
			BusIF2BusController	=>	BusIF2BusController(2),
			BusController2BusIF	=>	BusController2BusIF(2),
			--evt mgr
			ChModule2EventMgr	=> ChModule2EventMgr_vector(0),
			EventMgr2ChModule	=> EventMgr2ChModule_vector(0),
			--adc signals
			AdcModule2Adc	=> AdcModule2Adc_vector(0),
			Adc2AdcModule	=> Adc2AdcModule_vector(0),
			--ch mgr(time, veto, ...)
			ChModule2ChMgr	=> ChModule2ChMgr_vector(0),
			ChMgr2ChModule	=> ChMgr2ChModule_vector(0),
			--debug
			Debug				=> Debug_vector(0),
			--clock and reset
			Clock				=> AdcClock,--Clock,
			ReadClock		=> Clock,
			GlobalReset		=> GlobalReset
		);

	inst_ChModule_1 : UserModule_ChModule
		generic map(
			InitialAddress	=> InitialAddressOf_ChModule_1,
			FinalAddress	=> FinalAddressOf_ChModule_1,
			ChNumber			=> "001"
		)
		port map(
			--signals connected to BusController
			BusIF2BusController	=>	BusIF2BusController(3),
			BusController2BusIF	=>	BusController2BusIF(3),
			--evt mgr
			ChModule2EventMgr	=> ChModule2EventMgr_vector(1),
			EventMgr2ChModule	=> EventMgr2ChModule_vector(1),
			--adc signals
			AdcModule2Adc	=> AdcModule2Adc_vector(1),
			Adc2AdcModule	=> Adc2AdcModule_vector(1),
			--ch mgr(time, veto, ...)
			ChModule2ChMgr	=> ChModule2ChMgr_vector(1),
			ChMgr2ChModule	=> ChMgr2ChModule_vector(1),
			--debug
			Debug				=> Debug_vector(1),
			--clock and reset
			Clock				=> AdcClock,--Clock,
			ReadClock		=> Clock,
			GlobalReset		=> GlobalReset
		);
	
	inst_ChModule_2 : UserModule_ChModule
		generic map(
			InitialAddress	=> InitialAddressOf_ChModule_2,
			FinalAddress	=> FinalAddressOf_ChModule_2,
			ChNumber			=> "010"
		)
		port map(
			--signals connected to BusController
			BusIF2BusController	=>	BusIF2BusController(4),
			BusController2BusIF	=>	BusController2BusIF(4),
			--evt mgr
			ChModule2EventMgr	=> ChModule2EventMgr_vector(2),
			EventMgr2ChModule	=> EventMgr2ChModule_vector(2),
			--adc signals
			AdcModule2Adc	=> AdcModule2Adc_vector(2),
			Adc2AdcModule	=> Adc2AdcModule_vector(2),
			--ch mgr(time, veto, ...)
			ChModule2ChMgr	=> ChModule2ChMgr_vector(2),
			ChMgr2ChModule	=> ChMgr2ChModule_vector(2),
			--debug
			Debug				=> Debug_vector(2),
			--clock and reset
			Clock				=> AdcClock,--Clock,
			ReadClock		=> Clock,
			GlobalReset		=> GlobalReset
		);

	inst_ChModule_3 : UserModule_ChModule
		generic map(
			InitialAddress	=> InitialAddressOf_ChModule_3,
			FinalAddress	=> FinalAddressOf_ChModule_3,
			ChNumber			=> "011"
		)
		port map(
			--signals connected to BusController
			BusIF2BusController	=>	BusIF2BusController(5),
			BusController2BusIF	=>	BusController2BusIF(5),
			--evt mgr
			ChModule2EventMgr	=> ChModule2EventMgr_vector(3),
			EventMgr2ChModule	=> EventMgr2ChModule_vector(3),
			--adc signals
			AdcModule2Adc	=> AdcModule2Adc_vector(3),
			Adc2AdcModule	=> Adc2AdcModule_vector(3),
			--ch mgr(time, veto, ...)
			ChModule2ChMgr	=> ChModule2ChMgr_vector(3),
			ChMgr2ChModule	=> ChMgr2ChModule_vector(3),
			--debug
			Debug				=> Debug_vector(3),
			--clock and reset
			Clock				=> AdcClock,--Clock,
			ReadClock		=> Clock,
			GlobalReset		=> GlobalReset
		);

	inst_ChModule_4 : UserModule_ChModule
		generic map(
			InitialAddress	=> InitialAddressOf_ChModule_4,
			FinalAddress	=> FinalAddressOf_ChModule_4,
			ChNumber			=> "100"
		)
		port map(
			--signals connected to BusController
			BusIF2BusController	=>	BusIF2BusController(6),
			BusController2BusIF	=>	BusController2BusIF(6),
			--evt mgr
			ChModule2EventMgr	=> ChModule2EventMgr_vector(4),
			EventMgr2ChModule	=> EventMgr2ChModule_vector(4),
			--adc signals
			AdcModule2Adc	=> AdcModule2Adc_vector(4),
			Adc2AdcModule	=> Adc2AdcModule_vector(4),
			--ch mgr(time, veto, ...)
			ChModule2ChMgr	=> ChModule2ChMgr_vector(4),
			ChMgr2ChModule	=> ChMgr2ChModule_vector(4),
			--debug
			Debug				=> Debug_vector(4),
			--clock and reset
			Clock				=> AdcClock,--Clock,
			ReadClock		=> Clock,
			GlobalReset		=> GlobalReset
		);

	inst_ChModule_5 : UserModule_ChModule
		generic map(
			InitialAddress	=> InitialAddressOf_ChModule_5,
			FinalAddress	=> FinalAddressOf_ChModule_5,
			ChNumber			=> "101"
		)
		port map(
			--signals connected to BusController
			BusIF2BusController	=>	BusIF2BusController(7),
			BusController2BusIF	=>	BusController2BusIF(7),
			--evt mgr
			ChModule2EventMgr	=> ChModule2EventMgr_vector(5),
			EventMgr2ChModule	=> EventMgr2ChModule_vector(5),
			--adc signals
			AdcModule2Adc	=> AdcModule2Adc_vector(5),
			Adc2AdcModule	=> Adc2AdcModule_vector(5),
			--ch mgr(time, veto, ...)
			ChModule2ChMgr	=> ChModule2ChMgr_vector(5),
			ChMgr2ChModule	=> ChMgr2ChModule_vector(5),
			--debug
			Debug				=> Debug_vector(5),
			--clock and reset
			Clock				=> AdcClock,--Clock,
			ReadClock		=> Clock,
			GlobalReset		=> GlobalReset
		);

	inst_ChModule_6 : UserModule_ChModule
		generic map(
			InitialAddress	=> InitialAddressOf_ChModule_6,
			FinalAddress	=> FinalAddressOf_ChModule_6,
			ChNumber			=> "110"
		)
		port map(
			--signals connected to BusController
			BusIF2BusController	=>	BusIF2BusController(8),
			BusController2BusIF	=>	BusController2BusIF(8),
			--evt mgr
			ChModule2EventMgr	=> ChModule2EventMgr_vector(6),
			EventMgr2ChModule	=> EventMgr2ChModule_vector(6),
			--adc signals
			AdcModule2Adc	=> AdcModule2Adc_vector(6),
			Adc2AdcModule	=> Adc2AdcModule_vector(6),
			--ch mgr(time, veto, ...)
			ChModule2ChMgr	=> ChModule2ChMgr_vector(6),
			ChMgr2ChModule	=> ChMgr2ChModule_vector(6),
			--debug
			Debug				=> Debug_vector(6),
			--clock and reset
			Clock				=> AdcClock,--Clock,
			ReadClock		=> Clock,
			GlobalReset		=> GlobalReset
		);

	inst_ChModule_7 : UserModule_ChModule
		generic map(
			InitialAddress	=> InitialAddressOf_ChModule_7,
			FinalAddress	=> FinalAddressOf_ChModule_7,
			ChNumber			=> "111"
		)
		port map(
			--signals connected to BusController
			BusIF2BusController	=>	BusIF2BusController(9),
			BusController2BusIF	=>	BusController2BusIF(9),
			--evt mgr
			ChModule2EventMgr	=> ChModule2EventMgr_vector(7),
			EventMgr2ChModule	=> EventMgr2ChModule_vector(7),
			--adc signals
			AdcModule2Adc	=> AdcModule2Adc_vector(7),
			Adc2AdcModule	=> Adc2AdcModule_vector(7),
			--ch mgr(time, veto, ...)
			ChModule2ChMgr	=> ChModule2ChMgr_vector(7),
			ChMgr2ChModule	=> ChMgr2ChModule_vector(7),
			--debug
			Debug				=> Debug_vector(7),
			--clock and reset
			Clock				=> AdcClock,--Clock,
			ReadClock		=> Clock,
			GlobalReset		=> GlobalReset
		);
---------------------------------------------
	
	inst_EventMgr : UserModule_EventMgrModule
		port map(
			ChModule2EventMgr_vector	=> ChModule2EventMgr_vector,
			EventMgr2ChModule_vector	=> EventMgr2ChModule_vector,
			Consumer2EventMgr_vector	=> Consumer2EventMgr_vector,
			EventMgr2Consumer_vector	=> EventMgr2Consumer_vector,
			--clock and reset
			Clock				=> Clock,
			GlobalReset		=> GlobalReset
		);
	
	Consumer : for I in 0 to NumberOfConsumerNodes-1 generate
	inst_Consumer : UserModule_ConsumerModule_Calculator_MaxValue_PSD
		generic map(
			ConsumerNumber => I
		)
		port map(
			EventMgr2Consumer	=> EventMgr2Consumer_vector(I),
			Consumer2EventMgr	=> Consumer2EventMgr_vector(I),
			--
			Consumer2ConsumerMgr	=> Consumer2ConsumerMgr_vector(I),
			ConsumerMgr2Consumer	=> ConsumerMgr2Consumer_vector(I),
			--clock and reset
			Clock			=> Clock,
			GlobalReset	=> GlobalReset
		);
	end generate;
	
	inst_ConsumerMgr : UserModule_ConsumerMgr
		generic map(
			InitialAddress => InitialAddressOf_ConsumerMgr,
			FinalAddress	=> FinalAddressOf_ConsumerMgr
		)
		port map(
			--signals connected to BusController
			BusIF2BusController	=>	BusIF2BusController(11),--6 for 1ch test; 11 for 8ch implementation
			BusController2BusIF	=>	BusController2BusIF(11),--6 for 1ch test; 11 for 8ch implementation
			--signals connected to ConsumerModule
			Consumer2ConsumerMgr_vector	=> Consumer2ConsumerMgr_vector,
			ConsumerMgr2Consumer_vector	=> ConsumerMgr2Consumer_vector,
			--clock and reset
			Clock			=> Clock,
			GlobalReset	=> GlobalReset
		);

	inst_UserModule_LED : UserModule_LED
		generic map(
			InitialAddress	=> InitialAddressOf_LEDModule,
			FinalAddress	=> FinalAddressOf_LEDModule
		)
		port map(
			--signals connected to BusController
			BusIF2BusController	=>	BusIF2BusController(12),--7 for 1ch test; 12 for 8ch implementation
			BusController2BusIF	=>	BusController2BusIF(12),--7 for 1ch test; 12 for 8ch implementation
			--other signals
			LED	=> LEDs(3 downto 2),
			--clock and reset
			Clock			=> Clock,
			GlobalReset	=> GlobalReset
		);
		
	inst_UserModule_SDRAMC:UserModule_SDRAMC
		generic map(
			InitialAddress	=> InitialAddressOfSDRAMC,
			FinalAddress	=> FinalAddressOfSDRAMC
		)
		port map(
			--signals connected to BusController
			BusIF2BusController	=>	BusIF2BusController(13),--18 for 1ch test; 12 for 8ch implementation
			BusController2BusIF	=>	BusController2BusIF(13),--8 for 1ch test; 12 for 8ch implementation
			--
			Sdram_cke		=> Sdram_cke,
			Sdram_xdcs		=> Sdram_xdcs,
			Sdram_xdras		=> Sdram_xdras,
			Sdram_xdcas		=> Sdram_xdcas,
			Sdram_xdwe		=> Sdram_xdwe,
			Sdram_ldqm		=> Sdram_ldqm,
			Sdram_udqm		=> Sdram_udqm,
			Sdram_sda		=> Sdram_sda,
			Sdram_ba			=> Sdram_ba,
			Sdram_sdd		=> Sdram_sdd,
			debug				=> open,
			--clock and reset
			Clock100MHz		=> Clock100MHz,
			Clock50MHz		=> ClockBack,
			GlobalReset		=> GlobalReset
		);

	----------------------------------------------------
	----------------------------------------------------
	--Adc connection
	----------------------------------------------------
	----------------------------------------------------
	--for full implementation (8ch)
	Adc2AdcModule_vector <= Adc2UserFPGA_vector;
	UserFPGA2Adc_vector <= AdcModule2Adc_vector;

	--for test (1ch)
--	Adc2AdcModule_vector(0) <= Adc2UserFPGA_vector(0);
--	UserFPGA2Adc_vector(0) <= AdcModule2Adc_vector(0);
--	
--	AdcModule2Adc_Dummy.AdcPDWN <= '1';
--	UserFPGA2Adc_vector(1) <= AdcModule2Adc_Dummy;
--	UserFPGA2Adc_vector(2) <= AdcModule2Adc_Dummy;
--	UserFPGA2Adc_vector(3) <= AdcModule2Adc_Dummy;
--	UserFPGA2Adc_vector(4) <= AdcModule2Adc_Dummy;
--	UserFPGA2Adc_vector(5) <= AdcModule2Adc_Dummy;
--	UserFPGA2Adc_vector(6) <= AdcModule2Adc_Dummy;
--	UserFPGA2Adc_vector(7) <= AdcModule2Adc_Dummy;
	
	
	DIO_Out(0) <= Debug_vector(0)(1);
	DIO_Out(1) <= AdcClock;
	DIO_Out(2) <= Debug_vector(0)(0); --FastVetoTrigger ch0
	DIO_Out(3) <= ChModule2ChMgr_vector(0).Trigger;
	DIO_Out(4) <= GateIn_In;
	DIO_Out(5) <= ChModule2EventMgr_vector(0).hasData;
	DIO_Out(6) <= AdcClock;
	DIO_Out(7) <= Clock100MHz;
	
	LED_internal(0) <= eBus_Enable;
	LED_internal(1) <= SoftReset;
	LEDs(1 downto 0) <= LED_internal(1 downto 0);
	
--	process(Clock)
--	begin
--		if (Clock='1' and Clock'Event) then
--			if (counter=12000000) then
--				counter <= 0;
--				LED_Internal <= LED_Internal + 1;
--			else
--				--if (ChMgr2ChModule_vector(0).Veto='0') then
--					counter <= counter + 1;
--				--end if;
--			end if;
--		end if;
--	end process;
	
end Behavioral;
