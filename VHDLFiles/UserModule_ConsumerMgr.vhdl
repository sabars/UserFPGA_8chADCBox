--UserModule_ConsumerMgr.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserModule / Consumer Manager
--
--ver20071022 Takayuki Yuasa
--file created
--based on UserModule_ChModule_Delay.vhdl (ver20071022)

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
entity UserModule_ConsumerMgr is
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
end UserModule_ConsumerMgr;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_ConsumerMgr is

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
			GlobalReset		: in	std_logic
		);
	end component;
	---------------------------------------------------
	--Declarations of Signals
	---------------------------------------------------
	--Signals used in iBus process
	signal BusIF2UserModule		:	iBus_Signals_BusIF2UserModule;
	signal UserModule2BusIF		:	iBus_Signals_UserModule2BusIF;
	--Fifo signals
	signal FifoWriteEnable	: std_logic	:= '0';
	signal FifoEmpty			: std_logic	:= '0';
	signal FifoFull			: std_logic	:= '0';
	signal FifoReadEnable	: std_logic	:= '0';
	signal FifoDataCount		: std_logic_vector(9 downto 0)	:= (others => '0');
	signal FifoDataIn			: std_logic_vector(FifoDataWidth-1 downto 0);
	signal FifoDataOut		: std_logic_vector(FifoDataWidth-1 downto 0);

	signal LoopI					: integer range 0 to NumberOfConsumerNodes	:= 0;
	signal FlagWroteSomething	: std_logic	:= '0';
	signal Granting				: std_logic	:= '0';
	signal SendData				: std_logic_vector(15 downto 0)	:= (others => '0');
	signal FifoData_stored		: std_logic_vector(15 downto 0)	:= (others => '0');
	signal AddressUpdateDone	: std_logic	:= '0';
	signal WritePointer			: std_logic_vector(31 downto 0)	:= (others => '0');
	signal WriteStartPointer	: std_logic_vector(31 downto 0)	:= (others => '0');
	signal WritePointer_plus_2	: std_logic_vector(31 downto 0)	:= (others => '0');
	signal ReadPointer			: std_logic_vector(31 downto 0)	:= (others => '0');
	signal GuardBit				: std_logic	:= '0';
	signal Writepointer_Semaphore_Request	: std_logic	:= '0';
	signal ResetDone				: std_logic	:= '0';
	
	
	--Registers
	signal DisableRegister			: std_logic_vector(15 downto 0)	:= (others => '0');
	signal WritePointerRegister	: std_logic_vector(31 downto 0)	:= (others => '0');
	signal ReadPointerRegister		: std_logic_vector(31 downto 0)	:= (others => '0');
	signal GuardBitRegister			: std_logic_vector(15 downto 0)	:= (others => '0');
	signal AddressUpdateGoRegister		: std_logic_vector(15 downto 0)	:= (others => '0');
	signal GateSize_FastGate_Register	: std_logic_vector(15 downto 0)	:= x"0001";
	signal GateSize_SlowGate_Register	: std_logic_vector(15 downto 0)	:= x"0001";
	signal NumberOf_BaselineSample_Register	: std_logic_vector(15 downto 0)	:= x"0001";
	signal EventPacket_NumberOfWaveform_Register	: std_logic_vector(15 downto 0)	:= x"0010";
	signal Writepointer_Semaphore_Register	: std_logic_vector(15 downto 0)	:= x"0000";
	
	signal ResetRegister	: std_logic_vector(15 downto 0)	:= x"0000";
	--State Machines' State-variables
	type iBus_Receive_StateMachine_State is 
		(Initialize,	Idle,	DataReceive_wait,	DataReceive, WaitAddressUpdateDone, WaitResetDone);
	signal iBus_Receive_state : iBus_Receive_StateMachine_State := Initialize;
	
	type iBus_beRead_StateMachine_State is
		(Initialize,	Idle,	WaitDone);
	signal iBus_beRead_state : iBus_beRead_StateMachine_State := Initialize;
		
	type UserModule_StateMachine_State is
		(Initialize, Initialize_2, Idle, WaitReset, Writepointer_Semaphore_wait, Grant, 
		Transfer_0_SDRAM_Address_Set, Transfer, Transfer_2, Transfer_3,
		Transfer_3_Fifo_Read, Transfer_3_Fifo_Wait, Transfer_3_Send_To_SDRAM,
		Transfer_3_Address_Increment, Transfer_3_Address_Check,
		AddressIncrement, WaitAddressUpdate, WaitAddressUpdate_2,
		Reset_Sdram_Address, Reset_Sdram_Address_2, AddressUpdateGo, Finalize);
	signal UserModule_state : UserModule_StateMachine_State := Initialize;
	signal WaitAddressUpdata_ReturnState : UserModule_StateMachine_State := Initialize;
	signal Writepointer_Semaphore_wait_ReturnState : UserModule_StateMachine_State := Initialize;
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

	inst_fifo : UserModule_Fifo
		port map(
			--data
			DataIn	=> FifoDataIn,
			DataOut	=> FifoDataOut,
			--controll
			ReadEnable	=> FifoReadEnable,
			WriteEnable	=> FifoWriteEnable,
			--status
			Empty			=> FifoEmpty,
			Full			=> FifoFull,
			ReadDataCount	=> open,
			WriteDataCount	=> FifoDataCount,
			--clock and reset
			ReadClock	=> Clock,
			WriteClock	=> Clock,
			GlobalReset	=> GlobalReset
		);
	
	---------------------------------------------------
	--Static relationships
	---------------------------------------------------
	
	FifoDataIn <= Consumer2ConsumerMgr_vector(LoopI).Data when LoopI/=NumberOfConsumerNodes else (others=>'0');
	FifoWriteEnable <= Consumer2ConsumerMgr_vector(LoopI).WriteEnable when LoopI/=NumberOfConsumerNodes else '0';
	
	UserModule2BusIF.SendData <= FifoDataOut when Granting='1' else SendData;
		
	Connection : for I in 0 to NumberOfConsumerNodes-1 generate
		ConsumerMgr2Consumer_vector(I).GateSize_FastGate <= GateSize_FastGate_Register;
		ConsumerMgr2Consumer_vector(I).GateSize_SlowGate <= GateSize_SlowGate_Register;
		ConsumerMgr2Consumer_vector(I).EventPacket_NumberOfWaveform <= EventPacket_NumberOfWaveform_Register;
		ConsumerMgr2Consumer_vector(I).NumberOf_BaselineSample <= NumberOf_BaselineSample_Register;
	end generate;
	
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
			case UserModule_state is
				when Initialize =>
					AddressUpdateDone <= '0';
					FlagWroteSomething <= '0';
					WriteStartPointer <= InitialAddressOf_Sdram_EventList;
					WritePointer <= InitialAddressOf_Sdram_EventList;
					ReadPointer <= InitialAddressOf_Sdram_EventList;
					ResetDone <= '0';
					LoopI <= 0;
					GuardBit <= '0';
					Writepointer_Semaphore_Register(0) <= '0';
					UserModule_state <= Initialize_2;
				when Initialize_2 =>
					if (LoopI=NumberOfConsumerNodes) then
						LoopI <= 0;
						UserModule_state <= Idle;
					else
						ConsumerMgr2Consumer_vector(LoopI).Grant <= '0';
						LoopI <= LoopI + 1;
					end if;
				when Idle =>
					if (LoopI=NumberOfConsumerNodes) then
						LoopI <= 0;
					else
						if (ResetRegister(0)='1') then
							ResetDone <= '1';
							UserModule_state <= WaitReset;
						elsif (Writepointer_Semaphore_Request='1') then
							Writepointer_Semaphore_wait_ReturnState <= Idle;
							UserModule_state <= Writepointer_Semaphore_wait;
						elsif (AddressUpdateGoRegister(0)='1') then
							UserModule_state <= AddressUpdateGo;
						elsif (DisableRegister(0)='0' and Consumer2ConsumerMgr_vector(LoopI).EventReady='1') then
							ConsumerMgr2Consumer_vector(LoopI).Grant <= '1';
							Granting <= '1';
							UserModule_state <= Grant;
						else
							LoopI <= LoopI + 1;
						end if;
					end if;
				when WaitReset =>
					if (ResetRegister(0)='0') then
						ResetDone <= '0';
						UserModule_state <= Initialize;
					end if;
				when Writepointer_Semaphore_wait =>
					if (Writepointer_Semaphore_Request='0') then
						Writepointer_Semaphore_Register(0) <= '0';
						UserModule_state <= Idle;
					else
						Writepointer_Semaphore_Register(0) <= '1';
					end if;
				when Grant =>
					if (Consumer2ConsumerMgr_vector(LoopI).EventReady='0') then
						Granting <= '0';
						ConsumerMgr2Consumer_vector(LoopI).Grant <= '0';
						UserModule_state <= Transfer_0_SDRAM_Address_Set;
					end if;
				when Transfer_0_SDRAM_Address_Set =>
					if (WritePointer=FinalAddressOf_Sdram_EventList) then
						WriteStartPointer <= InitialAddressOf_Sdram_EventList;
					else
						if (FlagWroteSomething='1') then
							WriteStartPointer <= WritePointer + 2;
						else
							WriteStartPointer <= WritePointer;
						end if;
					end if;
					UserModule_state <= Transfer;
				when Transfer =>
					UserModule2BusIF.SendAddress <= AddressOf_SDRAM_Addresss_High_Register;
					SendData <= WriteStartPointer(31 downto 16);
					UserModule2BusIF.SendEnable <= '1';
					UserModule_state <= Transfer_2;
				when Transfer_2 =>
					UserModule2BusIF.SendAddress <= AddressOf_SDRAM_Addresss_Low_Register;
					SendData <= WriteStartPointer(15 downto 0);
					UserModule_state <= Transfer_3;
				when Transfer_3 =>
					UserModule2BusIF.SendEnable <= '0';
					UserModule_state <= Transfer_3_Address_Check ;
				when Transfer_3_Address_Check =>
					if (GuardBit='1') then
						if (WritePointer=ReadPointer) then
							--suspend writing
							WaitAddressUpdata_ReturnState <= Transfer;
							UserModule_state <= WaitAddressUpdate;
						else
							UserModule_state <= Transfer_3_Fifo_Read;
						end if;
					else
						if (WritePointer=FinalAddressOf_Sdram_EventList) then
							UserModule_state <= Reset_Sdram_Address;
						else
							UserModule_state <= Transfer_3_Fifo_Read;
						end if;
					end if;
				when Transfer_3_Fifo_Read =>
					if (FifoEmpty='1') then
						UserModule_state <= Finalize;
					else
						FifoReadEnable <= '1';
						UserModule_state <= Transfer_3_Fifo_Wait;
					end if;
				when Transfer_3_Fifo_Wait =>
					FifoReadEnable <= '0';
					UserModule_state <= Transfer_3_Send_To_SDRAM;
				when Transfer_3_Send_To_SDRAM =>
					UserModule2BusIF.SendAddress <= AddressOf_SDRAM_WriteThenIncrement_Register;
					SendData(15 downto 0) <= FifoDataOut;
					UserModule2BusIF.SendEnable <= '1';
					UserModule_state <= Transfer_3_Address_Increment;
				when Transfer_3_Address_Increment =>
					UserModule2BusIF.SendEnable <= '0';
					if (FlagWroteSomething='0') then
						FlagWroteSomething <= '1';
					else
						WritePointer <= WritePointer + 2;
					end if;
					UserModule_state <= Transfer_3_Address_Check;
				when WaitAddressUpdate =>
					if (AddressUpdateGoRegister(0)='1') then
						ReadPointer <= ReadPointerRegister;
						if (ReadPointerRegister<ReadPointer) then
							GuardBit <= '0';
						end if;
						AddressUpdateDone <= '1';
						UserModule_state <= WaitAddressUpdate_2;
					else
						AddressUpdateDone <= '0';
						--resume send
						FifoReadEnable <= '0';
						if (ResetRegister(0)='1') then
							UserModule_state <= Initialize;
						elsif (Writepointer_Semaphore_Request='1') then
							Writepointer_Semaphore_wait_ReturnState <= WaitAddressUpdate;
							UserModule_state <= Writepointer_Semaphore_wait;
						end if;
					end if;
				when WaitAddressUpdate_2 =>
					if (AddressUpdateGoRegister(0)='0') then
						UserModule_state <= WaitAddressUpdata_ReturnState;
					end if;
				when Reset_Sdram_Address =>
					UserModule2BusIF.SendEnable <= '1';
					UserModule2BusIF.SendAddress <= AddressOf_SDRAM_Addresss_Low_Register;
					SendData <= InitialAddressOf_Sdram_EventList(15 downto 0);
					UserModule_state <= Reset_Sdram_Address_2;
				when Reset_Sdram_Address_2 =>
					UserModule2BusIF.SendAddress <= AddressOf_SDRAM_Addresss_High_Register;
					SendData <= InitialAddressOf_Sdram_EventList(31 downto 16);
					WritePointer <= InitialAddressOf_Sdram_EventList;
					GuardBit <= '1';
					FlagWroteSomething <= '0';
					UserModule_state <= Transfer_3;
				when Finalize =>
					if (BusIF2UserModule.SendBufferEmpty='1') then
						UserModule_state <= Idle;
					end if;
				when AddressUpdateGo =>
					ReadPointer <= ReadPointerRegister;
					if (ReadPointerRegister<ReadPointer) then
						GuardBit <= '0';
					end if;
					if (AddressUpdateGoRegister(0)='1') then
						AddressUpdateDone <= '1';
					else
						AddressUpdateDone <= '0';
						UserModule_state <= Idle;
					end if;
				when others =>
					UserModule_state <= Initialize;
			end case;
		end if;
	end process;

	--change Register value by receiving data
	--from BusIF's ReceiveFIFO
	iBus_Receive_Process:process (Clock,GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			--Initialize StateMachine's state
			iBus_Receive_state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			case iBus_Receive_state is
				when Initialize =>
					UserModule2BusIF.ReceiveEnable <= '0';
					--move to next state
					iBus_Receive_state  <= Idle;
				when Idle =>
					--check if there is any received data (sent from another UserModule)
					--if there is, ReceiveFIFO's Empty is '0'
					if (BusIF2UserModule.ReceiveBufferEmpty='0') then
						--pop Received Data from iBus_BusIF's FIFO
						UserModule2BusIF.ReceiveEnable <= '1';
						--move to next state
						iBus_Receive_state  <= DataReceive_wait;
					end if;
				when DataReceive_wait =>
					UserModule2BusIF.ReceiveEnable <= '0';
					--move to next state
					iBus_Receive_state  <= DataReceive;
				when DataReceive =>
					--interpret the address of the received data
					case BusIF2UserModule.ReceivedAddress is
						when AddressOf_DisableRegister =>
							DisableRegister(0) <= BusIF2UserModule.ReceivedData(0);
							--move to next state
							iBus_Receive_state  <= Idle;
						when AddressOf_ReadPointerRegister_Low =>
							ReadPointerRegister(15 downto 0) <= BusIF2UserModule.ReceivedData;
							--move to next state
							iBus_Receive_state  <= Idle;
						when AddressOf_ReadPointerRegister_High =>
							ReadPointerRegister(31 downto 16) <= BusIF2UserModule.ReceivedData;
							--move to next state
							iBus_Receive_state  <= Idle;
						when AddressOF_GuardBitRegister =>
							--GuardBit will be automatically updated in UserModule_state=WaitAddressUpdate or AddressUpdateGo states
							--so, nothing to do in this write sequence
							--move to next state
							iBus_Receive_state  <= Idle;
						when AddressOf_AddressUpdateGoRegister =>
							AddressUpdateGoRegister(0) <= '1';
							--move to next state
							iBus_Receive_state  <= WaitAddressUpdateDone;
						when AddressOf_GateSize_FastGate_Register =>
							GateSize_FastGate_Register <= BusIF2UserModule.ReceivedData;
							--move to next state
							iBus_Receive_state  <= WaitAddressUpdateDone;
						when AddressOf_GateSize_SlowGate_Register =>
							GateSize_SlowGate_Register <= BusIF2UserModule.ReceivedData;
							--move to next state
							iBus_Receive_state  <= WaitAddressUpdateDone;
						when AddressOf_NumberOf_BaselineSample_Register =>
							NumberOf_BaselineSample_Register <= BusIF2UserModule.ReceivedData;
							--move to next state
							iBus_Receive_state  <= WaitAddressUpdateDone;
						when AddressOf_ResetRegister =>
							ResetRegister(0) <= '1';
							--move to next state
							iBus_Receive_state  <= WaitResetDone;
						when AddressOf_EventPacket_NumberOfWaveform_Register =>
							EventPacket_NumberOfWaveform_Register <= BusIF2UserModule.ReceivedData;
							--move to next state
							iBus_Receive_state  <= Idle;
						when AddressOf_Writepointer_Semaphore_Register =>
							if (BusIF2UserModule.ReceivedData(0)='0') then
								Writepointer_Semaphore_Request <= '0';
							else
								Writepointer_Semaphore_Request <= '1';
							end if;
							iBus_Receive_state  <= Idle;
						when others =>
							--no corresponding address or register
							--move to next state
							iBus_Receive_state  <= Idle;
					end case;
				when WaitAddressUpdateDone =>
					if (AddressUpdateDone='1') then
						AddressUpdateGoRegister(0) <= '0';
						iBus_Receive_state  <= Idle;
					end if;
				when WaitResetDone =>
					if (ResetDone='1') then
						ResetRegister(0) <= '0';
						iBus_Receive_state <= Initialize;
					end if;
				when others =>
					--move to next state
					iBus_Receive_state  <= Initialize;
			end case;
		end if;
	end process;

	--processes beRead access from BusIF
	--usually, return register value according to beRead-Address
	iBus_beRead_Process : process (Clock,GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			--Initialize StateMachine's state
			iBus_beRead_state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			case iBus_beRead_state is
				when Initialize =>
					--move to next state
					iBus_beRead_state <= Idle;
				when Idle =>
					if (BusIF2UserModule.beRead='1') then
						case BusIF2UserModule.beReadAddress is
							when AddressOf_DisableRegister =>
								UserModule2BusIF.beReadData(15 downto 1) <= (others => '0');
								UserModule2BusIF.beReadData(0) <= DisableRegister(0);
							when AddressOf_WritePointerRegister_Low =>
								UserModule2BusIF.beReadData <= WritePointer(15 downto 0);
							when AddressOf_WritePointerRegister_High =>
								UserModule2BusIF.beReadData <= WritePointer(31 downto 16);
							when AddressOf_ReadPointerRegister_Low =>
								UserModule2BusIF.beReadData <= ReadPointer(15 downto 0);
							when AddressOf_ReadPointerRegister_High =>
								UserModule2BusIF.beReadData <= ReadPointer(31 downto 16);
							when AddressOF_GuardBitRegister =>
								UserModule2BusIF.beReadData(15 downto 1) <= (others => '0');
								UserModule2BusIF.beReadData(0) <= GuardBit;
							when AddressOf_AddressUpdateGoRegister =>
								UserModule2BusIF.beReadData(15 downto 1) <= (others => '0');
								UserModule2BusIF.beReadData(0) <= AddressUpdateGoRegister(0);
							when AddressOf_EventPacket_NumberOfWaveform_Register =>
								UserModule2BusIF.beReadData <= EventPacket_NumberOfWaveform_Register;
							when AddressOf_Writepointer_Semaphore_Register =>
								UserModule2BusIF.beReadData(15 downto 1) <= (others => '0');
								UserModule2BusIF.beReadData(0) <= Writepointer_Semaphore_Register(0);
							when others =>
								--sonzai shina address heno yomikomi datta tokiha
								--0xabcd toiu tekitou na value wo kaeshite oku kotoni shitearu
								UserModule2BusIF.beReadData <= x"abcd";
						end case;
						--tell completion of the "beRead" process to iBus_BusIF
						UserModule2BusIF.beReadDone <= '1';
						--move to next state
						iBus_beRead_state  <= WaitDone;
					end if;
				when WaitDone =>
					--wait until the "beRead" process completes
					if (BusIF2UserModule.beRead='0') then
						UserModule2BusIF.beReadDone <= '0';
						--move to next state
						iBus_beRead_state  <= Idle;
					end if;
				when others =>
					--move to next state
					iBus_beRead_state  <= Initialize;
			end case;
		end if;
	end process;
end Behavioral;