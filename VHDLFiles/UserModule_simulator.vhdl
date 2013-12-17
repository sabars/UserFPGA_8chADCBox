--UserModule_simulator.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserModule Template / with FIFO version BusIF
--
--ver20081112 Takayuki Yuasa
--file created

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
entity UserModule_simulator is
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
end UserModule_simulator;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_simulator is

	---------------------------------------------------
	--Declarations of Components
	---------------------------------------------------

	--BusIF used for BusProcess(Bus Read/Write Process)
	component iBus_BusIF
		generic(
			InitialAddress	:	std_logic_vector(15 downto 0);
			FinalAddress	:	std_logic_vector(15 downto 0)
		);
		port(
			--connected to BusController
			BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
			BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
			--connected to UserModule
			BusIF2UserModule		:	out	iBus_Signals_BusIF2UserModule;
			UserModule2BusIF		:	in		iBus_Signals_UserModule2BusIF;
			Clock					:	in		std_logic;
			GlobalReset			:	in		std_logic
		);
	end component;

	---------------------------------------------------
	--Declarations of Signals
	---------------------------------------------------
	
	--Signals used in iBus process
	signal BusIF2UserModule		:	iBus_Signals_BusIF2UserModule;
	signal UserModule2BusIF		:	iBus_Signals_UserModule2BusIF;
	
	--State Machines' State-variables
	type iBus_Receive_StateMachine_State is 
		(Initialize,	Idle,	DataReceive_wait,	DataReceive);
	signal iBus_Receive_state : iBus_Receive_StateMachine_State := Initialize;
	
	type iBus_beRead_StateMachine_State is
		(Initialize,	Idle,	WaitDone);
	signal iBus_beRead_state : iBus_beRead_StateMachine_State := Initialize;
	
	type UserModule_StateMachine_State is
		(Initialize, Idle, RegisterSet, CommonGateInTrigger,
		WaitCompletion, Finalize);
	signal UserModule_state : UserModule_StateMachine_State := Initialize;
	
	type AddressData_type is array (INTEGER range <>) of std_logic_vector(31 downto 0);
	
	constant AddressDataNumberOfElement : Integer := 7;
	signal AddressData : AddressData_type(AddressDataNumberOfElement-1 downto 0) :=
		(	--Address & Data
		
			-- 0 ChModule0
			--AddressOf_TriggerModeRegister
			(InitialAddressOf_ChModule_0+x"0002")& x"0002", --Mode_2_CommonGateIn_NumberOfSamples
			
			-- 1 AddressOf_NumberOfSamplesRegister
			(InitialAddressOf_ChModule_0+x"0004")& x"0010", --16samples
			
			-- 2 AddressOf_DepthOfDelayRegister
			(InitialAddressOf_ChModule_0+x"000c")& x"0010", --16-sample delay
			
			-- 3 AddressOf_LivetimeRegisterL
			(InitialAddressOf_ChModule_0+x"000e")& x"1000", --Livetime 0x1000 cycle
			
			--ChMgr
			-- 4 AddressOf_PresetModeRegister
			(InitialAddressOf_ChMgr+x"0006") & x"0001", --PRESET_LIVETIME_MODE
			
			-- 5 AddressOf_PresetLivetimeRegisterL
			(InitialAddressOf_ChMgr+x"0008") & x"1000", --Livetime 0x1000 cycle
			
			-- 6 AddressOf_AdcClockCounter_Register
			(InitialAddressOf_ChMgr+x"0014") & x"0000" --ADC Clock 50MHz
		);
			
	--Registers
	signal LED_internal	:	std_logic_vector(1 downto 0)	:= (others => '0');
	
	signal index : Integer := 0;
	
	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin	
	
	---------------------------------------------------
	--Instantiations of Components
	---------------------------------------------------
	
	--Instantiation of iBus_BusIF
	BusIF : iBus_BusIF
		generic map(
			InitialAddress		=>	InitialAddress,
			FinalAddress		=>	FinalAddress
		)
		port map(
			--connected to BusController
			BusIF2BusController	=>	BusIF2BusController,
			BusController2BusIF	=>	BusController2BusIF,
			--connected to UserModule
			BusIF2UserModule	=> BusIF2UserModule,
			UserModule2BusIF	=> UserModule2BusIF,
			Clock			=>	Clock,
			GlobalReset	=> GlobalReset
		);

	---------------------------------------------------
	--Static relationships
	---------------------------------------------------
	
	---------------------------------------------------
	--Dynamic Processes with Sensitivity List
	---------------------------------------------------
	
	--change Register value by receiving data
	--from BusIF's ReceiveFIFO
	Main_Process:process (Clock,GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			--Initialize StateMachine's state
			iBus_Receive_state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			case UserModule_state is
				when Initialize =>
					UserModule2BusIF.ReceiveEnable <= '0';
					UserModule2BusIF.SendEnable <= '0';
					CommonGate <= '0';
					--move to next state
					UserModule_state  <= Idle;
				when Idle =>
					--move to next state
					UserModule_state <= RegisterSet;
				when RegisterSet =>
					if (BusIF2UserModule.SendBufferFull='0') then
						if (index<AddressDataNumberOfElement) then
							index <= index + 1;
							UserModule2BusIF.SendEnable <= '1';
							UserModule2BusIF.SendData <= AddressData(index)(15 downto 0);
							UserModule2BusIF.SendAddress <= AddressData(index)(31 downto 16);
						else
							if (BusIF2UserModule.SendBufferEmpty='1') then
								index <= 0;
								--move to next state
								UserModule_state <= CommonGateInTrigger;
							end if;
						end if;
					else
						UserModule2BusIF.SendEnable <= '0';
					end if;
				when CommonGateInTrigger =>
					if (index<5) then
						index <= index + 1;
					else
						--move to next state
						UserModule_state <= Finalize;
					end if;
					CommonGate <= '1';
				when Finalize =>
					CommonGate <= '0';
				when others =>
			end case;
		end if;
	end process;
end Behavioral;