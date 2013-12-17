--iBus_e2iConnector.vhdl
--iBus_e2iConnector.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--internal Bus (iBus) / Bus Adapter to external Bus (eBus)
--
--ver20071206 Takayuki Yuasa
--SDRAMC implement
--
--ver20071203 Takayuki Yuasa
--InternalRAM access
--
--ver20071106 Takayuki Yuasa
--added AddressIncrement subroutine
--increment Write/increment Read full support
--
--ver20071029 Takayuki Yuasa
--added IncrementThenWrite command and
--WriteThenIncrement command
--
--ver20071021 Takayuki Yuasa
--SpaceWire ADC Box
--
--ver20071013 Takayuki Yuasa
--speedtest you ni, address wo jidoutei ni count up suru logic wo kuwaete aru
--ver20070727-0730
--SDRAM Test
--ver0.1
--20070324 Takayuki Yuasa bi-directional eBus support
--ver0.0
--20070109 Takayuki Yuasa

---------------------------------------------------
--Declarations of Libraries used in this UserModule
---------------------------------------------------
library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.iBus_Library.all;
use work.iBus_AddressMap.all;

---------------------------------------------------
--Entity Declaration of this UserModule
---------------------------------------------------
entity iBus_e2iConnector is
	generic(
		InitialAddress	:	std_logic_vector(15 downto 0);
		FinalAddress	:	std_logic_vector(15 downto 0)
	);
	port(
		--connected to BusController
		BusIF2BusController	:	out	iBus_Signals_BusIF2BusController;
		BusController2BusIF	:	in		iBus_Signals_BusController2BusIF;
		--signals used in SpW FPGA Master eBus Access
		eBus_Enable			: in std_logic; 
		eBus_Done			: out std_logic;
		eBus_Address		: in std_logic_vector (24 downto 0);
		eBus_DataIn			: in std_logic_vector (15 downto 0); 
		eBus_DataOut		: out std_logic_vector (15 downto 0); 
		eBus_Write			: in std_logic; 
		eBus_Read			: in std_logic;
		--signal used in UserFPGA Master eBus Access
		meBus_Request		: out std_logic;
		meBus_Enable		: in std_logic;
		meBus_Grant			: in std_logic;
		meBus_Done			: in std_logic;
		meBus_Address		: out std_logic_vector(24 downto 0);
		meBus_Read			: out std_logic;
		meBus_Write			: out std_logic;
		meBus_DataIn		: in std_logic_vector (15 downto 0); 
		meBus_DataOut		: out std_logic_vector (15 downto 0);
		--clock and reset
		Clock					:	in		std_logic;
		GlobalReset	:	in		std_logic
	);
end iBus_e2iConnector;

---------------------------------------------------
--Behavioral description of this UserModule
---------------------------------------------------
architecture Behavioral of iBus_e2iConnector is

	---------------------------------------------------
	--Declarations of Components used in this UserModule
	---------------------------------------------------

	--BusIFModule used for BusProcess(Bus Read/Write Process)
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

	component UserModule_Ram
		port(
			Address		: in std_logic_VECTOR(9 downto 0);
			DataIn		: in std_logic_VECTOR(15 downto 0);
			DataOut		: out std_logic_VECTOR(15 downto 0);
			WriteEnable	: in std_logic;
			Clock			: in std_logic
		);
	end component;
	
	---------------------------------------------------
	--Declarations of Signals used in this UserModule
	---------------------------------------------------
	
	--Signals used in iBus process
	signal BusIF2UserModule		:	iBus_Signals_BusIF2UserModule;
	signal UserModule2BusIF		:	iBus_Signals_UserModule2BusIF;

	type UserModule_StateMachine_State_SF_Master is 
		(Initialize,	Idle,	beWritten,	beRead, Sdram_Write_0, Sdram_Write_1, Sdram_Read_0, Sdram_Read_1,
		Wait_InternalRAM_Read,	Finalize_InternalRAM_Read,
		beRead_1,	beRead_2,	beRead_3,	Done_output,	WaitForEndOfCommand);
	signal UserModule_SF_Master_state : UserModule_StateMachine_State_SF_Master := Initialize;

	type UserModule_StateMachine_State_UF_Master is 
		(Initialize,	Idle,	DataReceive_1,	DataReceive_2,	DataReceive_3,	Request,
			Wait_InternalRAM_Write,	Finalize_InternalRAM_Write,
			WaitGrant,	WaitDone,	Finalize,	AddressIncrement);
	signal UserModule_UF_Master_state : UserModule_StateMachine_State_UF_Master := Initialize;
	signal AddressIncrement_ReturnState : UserModule_StateMachine_State_UF_Master := Initialize;
	
	type UserModule_StateMachine_State_IR is 
		(Initialize,	Idle,	WriteRAM, ReadRAM_0, ReadRAM_1, ReadRAM_2, ReadRAM_3 );
	signal UserModule_IR_state : UserModule_StateMachine_State_IR := Initialize;
	
	
	type Command_type is (Write,Read,None);
	signal UF_Master_Command_Type	:	Command_type	:= None;
	signal SF_Master_Command_Type	:	Command_type	:= None;
	
	--SDRAM Address Register
	--SDRAM Address is 25bits, so,
	--two registers (SDRAM_Address_High and SDRAM_Address_Low)
	--are used to construct the actual SDRAM_Address
	signal SDRAM_Address	:	std_logic_vector(24 downto 0);
	signal SDRAM_Address_High	:	std_logic_vector(15 downto 0) := (others=>'0');
		--only the least 9bits ([8:0]) are valid
	signal SDRAM_Address_Low	:	std_logic_vector(15 downto 0) := (others=>'0');
	
	signal IncrementFlag	: std_logic	:= '0';
	signal counter : integer range 0 to 100 := 0;
	
	--Internal RAM
	signal RamWriteEnable	: std_logic	:= '0';
	signal RamAddress			:	std_logic_vector(9 downto 0);
	signal RamDataOut			:	std_logic_vector(15 downto 0);
	signal InternalRAM_Address_Read	:	std_logic_vector(15 downto 0);
	signal InternalRAM_Mode	: std_logic	:= '0';--0:Read 1:Write
	signal eBus_Read_Mode	: std_logic	:= '0';--0:InternalRAM 1:iBus
	signal InternalRAM_WriteDone	: std_logic	:= '0';
	signal InternalRAM_ReadDone	: std_logic	:= '0';
	
	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin	
	
	---------------------------------------------------
	--Instantiations of Components used in this UserModule
	---------------------------------------------------
	
	--Instantiation of InternalBusIFModule as BusIFModule
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

	inst_ram : UserModule_Ram
		port map(
			Address	=> RamAddress,
			DataIn	=> BusIF2UserModule.ReceivedData,
			DataOut	=> RamDataOut,
			WriteEnable	=> RamWriteEnable,
			Clock			=> Clock
		);
	RamAddress
		<= SDRAM_Address_Low(10 downto 1) when InternalRAM_Mode='1'--write
			else InternalRAM_Address_Read(10 downto 1);--read
	
	---------------------------------------------------
	--Static relationships
	---------------------------------------------------
	meBus_Address(24 downto 16) <= SDRAM_Address_High(8 downto 0);
	meBus_Address(15 downto 0) <= SDRAM_Address_Low;

	eBus_DataOut
		<= BusIF2UserModule.ReadData when eBus_Read_Mode='1'--iBus
			else RamDataOut;--InternalRAM
	
	---------------------------------------------------
	--Dynamic Processes with Sensitivity List
	---------------------------------------------------
	
	--UserFPGA Master eBus Access and iBus Access
	UFMaster_Process:process (Clock,GlobalReset)
	begin
		
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			--Initialize StateMachine's state
			UserModule_UF_Master_state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			case UserModule_UF_Master_state is
				when Initialize =>
					meBus_Request <= '1';
					meBus_Write	<= '1';
					meBus_Read	<= '1';
					
					UserModule2BusIF.ReceiveEnable <= '0';
					UserModule2BusIF.beReadDone <= '0';
					
					UF_Master_Command_Type <= None;
					--move to next state
					UserModule_UF_Master_state  <= idle;
					
				when Idle =>
					if (BusIF2UserModule.beRead='1') then
						if (BusIF2UserModule.beReadAddress=AddressOf_SDRAM_Read_Register) then
							UF_Master_Command_Type <= Read;
							--move to next state
							UserModule_UF_Master_state  <= Request;
						elsif (BusIF2UserModule.beReadAddress=AddressOf_SDRAM_ReadThenIncrement_Register) then
							UF_Master_Command_Type <= Read;
							IncrementFlag <= '1';
							--move to next state
							UserModule_UF_Master_state  <= Request;
						elsif (BusIF2UserModule.beReadAddress=AddressOf_SDRAM_IncrementThenRead_Register) then
							UF_Master_Command_Type <= Read;
							--move to next state
							AddressIncrement_ReturnState <= Request;
							UserModule_UF_Master_state  <= AddressIncrement;
						else
							UF_Master_Command_Type <= Read;
							--dummy data
							UserModule2BusIF.beReadData <= x"0000";
							UserModule2BusIF.beReadDone <= '1';
							--move to next state
							UserModule_UF_Master_state  <= Finalize;
						end if;
					elsif (BusIF2UserModule.ReceiveBufferEmpty='0') then
						--get Received Data from iBus_BusIF's FIFO
						UserModule2BusIF.ReceiveEnable <= '1';
						--move to next state
						UserModule_UF_Master_state  <= DataReceive_1;
					end if;
				
				when DataReceive_1 =>
					UserModule2BusIF.ReceiveEnable <= '0';
					--move to next state
					UserModule_UF_Master_state  <= DataReceive_2;
					
				when DataReceive_2 =>
					--wait
					--move to next state
					UserModule_UF_Master_state  <= DataReceive_3;

				when DataReceive_3 =>
					--interpret the address of received data
					case BusIF2UserModule.ReceivedAddress is
						when AddressOf_SDRAM_Addresss_High_Register =>
							SDRAM_Address_High <= BusIF2UserModule.ReceivedData;
							--move to next state
							UserModule_UF_Master_state  <= Idle;
						when AddressOf_SDRAM_Addresss_Low_Register =>
							SDRAM_Address_Low <= BusIF2UserModule.ReceivedData;
							--move to next state
							UserModule_UF_Master_state  <= Idle;
						when AddressOf_SDRAM_Write_Register =>
							UF_Master_Command_Type <= Write;
							--move to next state
							UserModule_UF_Master_state  <= Request;
						when AddressOf_SDRAM_WriteThenIncrement_Register =>
							UF_Master_Command_Type <= Write;
							IncrementFlag <= '1';
							--move to next state
							UserModule_UF_Master_state  <= Request;
						when AddressOf_SDRAM_IncrementThenWrite_Register =>
							UF_Master_Command_Type <= Write;
							--move to next state
							AddressIncrement_ReturnState <= Request;
							UserModule_UF_Master_state  <= AddressIncrement;
						when others =>
							--move to next state
							UserModule_UF_Master_state  <= Idle;
					end case;

				when Request =>
					--send Request to SpW FPGA
					--InternalRAM用に書き換えてあるので注意
					--eBus経由でSDRAMにアクセスするときは、コメントアウトをはずす
					--meBus_Request <= '0';
					--move to next state
					UserModule_UF_Master_state  <= Wait_InternalRAM_Write;--for simulation:Finalize, for implementation:WaitGrant
				when Wait_InternalRAM_Write =>
					if (InternalRAM_WriteDone='1') then
						UserModule_UF_Master_state  <= Finalize_InternalRAM_Write;
					end if;
				when Finalize_InternalRAM_Write =>
					--internalRAM access ha, write shika support shinai
					if (UF_Master_Command_Type=Write) then
						if (IncrementFlag='1') then
							IncrementFlag <= '0';
							--move to next state
							AddressIncrement_ReturnState <= Idle;
							UserModule_UF_Master_state  <= AddressIncrement;
						else
							UserModule_UF_Master_state  <=  Idle;
						end if;
					end if;
				when WaitGrant =>
					if (UF_Master_Command_Type=Read) then
						meBus_Read <= '0';
					elsif (UF_Master_Command_Type=Write) then
						meBus_DataOut <= BusIF2UserModule.ReceivedData;
						meBus_Write <= '0';
					end if;
					
					if (meBus_Grant='0') then
						--move to next state
						UserModule_UF_Master_state  <= WaitDone;						
					end if;
				
				when WaitDone =>
					if (meBus_Done='0') then
						if (UF_Master_Command_Type=Read) then
							UserModule2BusIF.beReadData <= meBus_DataIn;
							UserModule2BusIF.beReadDone <= '1';
						end if;
						--move to next state
						UserModule_UF_Master_state  <= Finalize;
					end if;
					meBus_Request <= '1';
				
				when Finalize =>
					meBus_Read <= '1';
					meBus_Write <= '1';
					if (meBus_Grant='1') then
						if (UF_Master_Command_Type=Read) then
							if (BusIF2UserModule.beRead='0') then
								UserModule2BusIF.beReadDone <= '0';
								if (IncrementFlag='1') then
									IncrementFlag <= '0';
									--move to next state
									AddressIncrement_ReturnState <= Idle;
									UserModule_UF_Master_state  <= AddressIncrement;
								else
									--move to next state
									UserModule_UF_Master_state  <= Idle;
								end if;
							end if;
						elsif (UF_Master_Command_Type=Write) then
							if (IncrementFlag='1') then
								IncrementFlag <= '0';
								--move to next state
								AddressIncrement_ReturnState <= Idle;
								UserModule_UF_Master_state  <= AddressIncrement;
							else
								UserModule_UF_Master_state  <=  Idle;
							end if;
						end if;
					end if;
					
				when AddressIncrement =>
					if (SDRAM_Address_Low=x"ffff") then
						if (SDRAM_Address_High=FinalAddressOf_SDRAM(31 downto 16)) then
							SDRAM_Address_High <= InitialAddressOf_SDRAM(31 downto 16);
							SDRAM_Address_Low <= InitialAddressOf_SDRAM(15 downto 0) + 1;
						else
							SDRAM_Address_High <= SDRAM_Address_High + 1;
							SDRAM_Address_Low <= x"0001";
						end if;
					elsif (SDRAM_Address_Low=x"fffe") then
						if (SDRAM_Address_High=FinalAddressOf_SDRAM(31 downto 16)) then
							SDRAM_Address_High <= InitialAddressOf_SDRAM(31 downto 16);
							SDRAM_Address_Low <= InitialAddressOf_SDRAM(15 downto 0);
						else
							SDRAM_Address_High <= SDRAM_Address_High + 1;
							SDRAM_Address_Low <= x"0000";
						end if;
					else
						SDRAM_Address_Low <= SDRAM_Address_Low + 2;
					end if;
					--move to next state
					UserModule_UF_Master_state  <= AddressIncrement_ReturnState;

				when others =>
					--move to next state
					UserModule_UF_Master_state  <= Initialize;
			end case;
		end if;
	end process UFMaster_Process;
	

	InternalRAM_Process:process (Clock,GlobalReset)
	begin
		if (GlobalReset='0') then
			UserModule_IR_state <= Initialize;
		elsif (Clock'Event and Clock='1') then
			case UserModule_IR_state is
				when	Initialize =>
					RamWriteEnable <= '0';
					UserModule_IR_state <= Idle;
				when Idle =>
					if (UserModule_SF_Master_state=Wait_InternalRAM_Read) then
						RamWriteEnable <= '0';
						InternalRam_Mode <= '0'; -- read
						InternalRAM_Address_Read <= eBus_Address(15 downto 0)-InitialAddressOfe2iConnector_InternalRAM;
						UserModule_IR_state <= ReadRAM_0;
					elsif (UserModule_UF_Master_state=Wait_InternalRAM_Write) then
						RamWriteEnable <= '1';
						InternalRam_Mode <= '1'; -- write
						InternalRAM_WriteDone <= '1';
						UserModule_IR_state <= WriteRAM;
					else
						RamWriteEnable <= '0';
						InternalRAM_WriteDone <= '0';
						InternalRAM_ReadDone <= '0';
					end if;
				when WriteRAM =>
					RamWriteEnable <= '0';
					if (UserModule_UF_Master_state=Finalize_InternalRAM_Write) then
						InternalRAM_WriteDone <= '0';
						UserModule_IR_state <= Idle;
					end if;
				when ReadRAM_0 =>
					UserModule_IR_state <= ReadRAM_1;
				when ReadRAM_1 =>
					UserModule_IR_state <= ReadRAM_2;
				when ReadRAM_2 =>
					InternalRAM_ReadDone <= '1';
					UserModule_IR_state <= ReadRAM_3;
				when ReadRAM_3 =>
					if (UserModule_SF_Master_state=Finalize_InternalRAM_Read) then
						InternalRAM_ReadDone <= '0';
						UserModule_IR_state <= Idle;
					end if;
			end case;
		end if;
	end process;
	
	--SpW FPGA Master eBus Access
	SFMaster_Process:process (Clock,GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			--Initialize StateMachine's state
			UserModule_SF_Master_state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			case UserModule_SF_Master_state is
				when Initialize =>
					UserModule2BusIF.ReadGo <= '0';
					UserModule2BusIF.SendEnable <= '0';
					eBus_Done <= '1';
					--move to next state
					UserModule_SF_Master_state  <= Idle;
	
				when Idle =>
					--if any data is received by BusIF, pull out from BusIF Receive Buffer(FIFO)
					if (eBus_Enable='0' and meBus_Grant='1') then
						if (eBus_Write='0') then
							--move to next state
							UserModule_SF_Master_state <= beWritten;
						elsif (eBus_Read='0') then
							--move to next state
							UserModule_SF_Master_state <= beRead;
						end if;
					end if;
				
				when beWritten =>
					--SDRAMC access?
					if (eBus_Address>=InitialAddressOf_SDRAM(24 downto 0) and eBus_Address<=FinalAddressOf_SDRAM(24 downto 0)) then
						if (BusIF2UserModule.SendBufferFull='0') then
							UserModule2BusIF.SendAddress <= AddressOf_SDRAM_WriteAddresss_High_Register;
							UserModule2BusIF.SendData(15 downto 9) <= (others=>'0');
							UserModule2BusIF.SendData(8 downto 0) <= eBus_Address(24 downto 16);
							UserModule2BusIF.SendEnable <= '1';
							--move to next state
							UserModule_SF_Master_state <= Sdram_Write_0;
						end if;
					elsif (BusIF2UserModule.SendBufferFull='0') then
						UserModule2BusIF.SendAddress <= eBus_Address(15 downto 0);
						UserModule2BusIF.SendData <= eBus_DataIn;
						UserModule2BusIF.SendEnable <= '1';
						eBus_Done <= '0';
						--move to next state
						UserModule_SF_Master_state <= WaitForEndOfCommand;
					end if;
				
				when beRead=>
					--SDRAMC access?
					if (eBus_Address>=InitialAddressOf_SDRAM(24 downto 0) and eBus_Address<=FinalAddressOf_SDRAM(24 downto 0)) then
						if (BusIF2UserModule.SendBufferFull='0') then
							eBus_Read_Mode <= '1'; --iBus
							--set Address High
							UserModule2BusIF.SendAddress <= AddressOf_SDRAM_ReadAddresss_High_Register;
							UserModule2BusIF.SendData(15 downto 9) <= (others=>'0');
							UserModule2BusIF.SendData(8 downto 0) <= eBus_Address(24 downto 16);
							UserModule2BusIF.SendEnable <= '1';
							UserModule_SF_Master_state <= Sdram_Read_0;
						end if;
					--InternalRAM access?
					elsif (eBus_Address(15 downto 0)>=InitialAddressOfe2iConnector_InternalRAM and eBus_Address(15 downto 0)<=FinalAddressOfe2iConnector_InternalRAM) then
						eBus_Read_Mode <= '0'; --InternalRAM
						UserModule_SF_Master_state <= Wait_InternalRAM_Read;
					--iBus access
					else
						eBus_Read_Mode <= '1'; --iBus
						UserModule2BusIF.ReadAddress <= eBus_Address(15 downto 0);
						UserModule2BusIF.ReadGo <= '1';
						--move to next state
						UserModule_SF_Master_state <= beRead_2;
					end if;
				when Sdram_Write_0 =>
					if (BusIF2UserModule.SendBufferFull='0') then
						--set Address Low
						UserModule2BusIF.SendAddress <= AddressOf_SDRAM_WriteAddresss_Low_Register;
						UserModule2BusIF.SendData <= eBus_Address(15 downto 0);
						UserModule2BusIF.SendEnable <= '1';
						UserModule_SF_Master_state <= Sdram_Write_1;
					end if;
				when Sdram_Write_1 =>
					if (BusIF2UserModule.SendBufferFull='0') then
						--set Address Low
						UserModule2BusIF.SendAddress <= AddressOf_SDRAM_Write_Register;
						UserModule2BusIF.SendData <= eBus_DataIn(15 downto 0);
						UserModule2BusIF.SendEnable <= '1';
						eBus_Done <= '0';
						UserModule_SF_Master_state <= WaitForEndOfCommand;
					end if;
				when Sdram_Read_0 =>
					if (BusIF2UserModule.SendBufferFull='0') then
						--set Address Low
						UserModule2BusIF.SendAddress <= AddressOf_SDRAM_ReadAddresss_Low_Register;
						UserModule2BusIF.SendData <= eBus_Address(15 downto 0);
						UserModule2BusIF.SendEnable <= '1';
						UserModule_SF_Master_state <= Sdram_Read_1;
					end if;
				when Sdram_Read_1 =>
					UserModule2BusIF.SendEnable <= '0';
					if (BusIF2UserModule.SendBufferEmpty='1') then
						UserModule2BusIF.ReadAddress <= AddressOf_SDRAM_Read_Register;
						UserModule2BusIF.ReadGo <= '1';
						UserModule_SF_Master_state <= beRead_2;
					end if;
				when Wait_InternalRAM_Read =>
					if (InternalRAM_ReadDone='1') then
						UserModule_SF_Master_state  <= Finalize_InternalRAM_Read;
					end if;
				when Finalize_InternalRAM_Read =>
					eBus_Done <= '0';
					UserModule_SF_Master_state  <= WaitForEndOfCommand;
					
				when beRead_2 =>
					if (BusIF2UserModule.ReadDone='0') then
						--move to next state
						UserModule_SF_Master_state <= beRead_3;
					end if;
					--timeout
					if (eBus_Enable='1') then
						eBus_Done <= '1';
						--move to next state
						UserModule_SF_Master_state <= Initialize;		
					end if;

				when beRead_3 =>
					if (BusIF2UserModule.ReadDone='1') then
						UserModule2BusIF.ReadGo <= '0';
						--eBus_DataOut <= BusIF2UserModule.ReadData;
						eBus_Done <= '0';
						--move to next state
						UserModule_SF_Master_state <= WaitForEndOfCommand;
					end if;

				when WaitForEndOfCommand =>
					UserModule2BusIF.SendEnable <= '0';
					if (eBus_Enable='1') then
						eBus_Done <= '1';
						--move to next state
						UserModule_SF_Master_state <= Initialize;						
					end if;

				when others =>
					UserModule_SF_Master_state <= Initialize;
					
			end case;
		end if;
	end process SFMaster_Process;
	
end Behavioral;