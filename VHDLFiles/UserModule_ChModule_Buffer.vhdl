--UserModule_ChModule_Buffer.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserModule / Ch Module / Buffer Module
--
--ver20071023 Takayuki Yuasa
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
entity UserModule_ChModule_Buffer is
	generic(
		ChNumber			: std_logic_vector(2 downto 0)	:= (others=>'0')
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
		Clock				: in		std_logic;
		ReadClock		: in		std_logic;
		GlobalReset		: in		std_logic
	);
end UserModule_ChModule_Buffer;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_ChModule_Buffer is

	---------------------------------------------------
	--Declarations of Components
	---------------------------------------------------
	component UserModule_Fifo
		port(
			--data
			DataIn		: in std_logic_VECTOR(15 downto 0);
			DataOut		: out std_logic_VECTOR(15 downto 0);
			--controll
			ReadEnable	: in std_logic;
			WriteEnable	: in std_logic;
			--status
			Empty			: out std_logic;
			Full			: out std_logic;
			ReadDataCount	: out std_logic_VECTOR(9 downto 0);
			WriteDataCount	: out std_logic_VECTOR(9 downto 0);
			--clock and reset
			ReadClock	: in std_logic;	
			WriteClock	: in std_logic;
			GlobalReset	: in	std_logic
		);
	end component;

	---------------------------------------------------
	--Declarations of Signals
	---------------------------------------------------
	--Signals
	signal WriteEnable	: std_logic	:= '0';
	signal Empty			: std_logic	:= '0';
	signal Full				: std_logic	:= '0';
	signal WriteDataCount		: std_logic_vector(9 downto 0)	:= (others => '0');
	signal ReadDataCount		: std_logic_vector(9 downto 0)	:= (others => '0');
	signal DataIn			: std_logic_vector(FifoDataWidth-1 downto 0);
		
	signal NoRoomForMoreEvent_internal	: std_logic	:= '0';
	signal Busy				: std_logic := '0';
	signal Veto				: std_logic := '0';
	signal RealTime		: std_logic_vector(WidthOfRealTime-1 downto 0);
	signal RealTime_latched		: std_logic_vector(WidthOfRealTime-1 downto 0);
	
	--Registers
	
	--Counters
	
	--State Machines' State-variables

	type UserModule_StateMachine_State is
		(Initialize, Idle, WaitVetoOff, WaitTriggerOff, Triggered, WriteHeader_1, WriteHeader_2, WriteHeader_3, Finalize);
	signal UserModule_state : UserModule_StateMachine_State := Initialize;
	
	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin	
	
	---------------------------------------------------
	--Instantiations of Components
	---------------------------------------------------
	inst_fifo : UserModule_Fifo
		port map(
			--data
			DataIn	=> DataIn,
			DataOut	=> DataOut,
			--controll
			ReadEnable	=> ReadEnable,
			WriteEnable	=> WriteEnable,
			--status
			Empty			=> Empty,
			Full			=> Full,
			ReadDataCount	=> ReadDataCount,
			WriteDataCount	=> WriteDataCount,
			--clock and reset
			ReadClock	=> ReadClock,
			WriteClock	=> Clock,
			GlobalReset	=> GlobalReset
		);
	
	---------------------------------------------------
	--Static relationships
	---------------------------------------------------
	BufferEmpty <= Empty;
	hasEvent <= '1'
				when ((
					conv_integer(ReadDataCount)
					>= conv_integer(ChModule2InternalModule.SizeOfHeader)+
					conv_integer(ChModule2InternalModule.NumberOfSamples)
				)) else '0';
	BufferNoGood <= Full or NoRoomForMoreEvent_internal or Busy;
	NoRoomForMoreEvent <= NoRoomForMoreEvent_internal;
	NoRoomForMoreEvent_internal
		<= '1'
			when ((
				DepthOfChModuleBufferFifo-conv_integer(WriteDataCount)
				< conv_integer(ChModule2InternalModule.SizeOfHeader)+
				conv_integer(ChModule2InternalModule.NumberOfSamples)
			) or Full='1') else '0';
	Veto <= ChModule2InternalModule.Veto;
	
	---------------------------------------------------
	--Dynamic Processes with Sensitivity List
	---------------------------------------------------
	--UserModule main state machine
	MainProcess : process (Clock, GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			UserModule_state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			Realtime <= ChModule2InternalModule.RealTime;
			case UserModule_state is
				when Initialize =>
					Busy <= '0';
					WriteEnable <= '0';
					--move to next state
					UserModule_state <= Idle;
				when Idle =>
					DataIn(15) <= '1'; --start flag
					DataIn(14 downto 12) <= ChNumber; --ChNumber of this module
					DataIn(11 downto 0) <= AdcDataIn;
					if (TriggerIn='1' and Full='0' and NoRoomForMoreEvent_internal='0') then
						RealTime_latched <= Realtime;
						WriteEnable <= '1';
						Busy <= '1';
						UserModule_state <= WaitTriggerOff;
					elsif (Veto='1') then
						UserModule_state <= WaitVetoOff;
					else
						WriteEnable <= '0';
					end if;
				when WaitVetoOff =>
					if (Veto='0' and TriggerIn='0') then
						UserModule_state <= Idle;
					end if;
				when WaitTriggerOff =>
					if (TriggerIn='0') then
						--Write Header Separator
						DataIn(15 downto 12) <= HEADER_FLAG; --header flag
						DataIn(11 downto 0) <= x"003"; --indicate that size of header is 'three words'
						UserModule_state <= WriteHeader_1;
					else
						DataIn(15) <= '0';
						DataIn(14 downto 12) <= "000";
						DataIn(11 downto 0) <= AdcDataIn;
					end if;
				when WriteHeader_1 =>
					DataIn <= RealTime_latched(WidthOfRealTime-1 downto 32);
					UserModule_state <= WriteHeader_2;
				when WriteHeader_2 =>
					DataIn <= RealTime_latched(31 downto 16);
					UserModule_state <= WriteHeader_3;
				when WriteHeader_3 =>
					DataIn <= RealTime_latched(15 downto 0);
					UserModule_state <= Finalize;
				when Finalize =>
					WriteEnable <= '0';
					--moshimo, header wo kakikonde iru aida ni,
					--tsugino trigger ga tatte itara, tadashiku shori
					--dekinai node, NG wo ON ni shite, trigger off made
					--matsu koto ni suru
					if (TriggerIn='0') then
						Busy <= '0';
						UserModule_state <= Idle;
					end if;
				when others =>
					UserModule_state <= Initialize;
			end case;
		end if;
	end process;
end Behavioral;