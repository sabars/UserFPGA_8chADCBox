--UserModule_SDRAMC.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserFPGA / DCM
--
--ver20071205 Takayuki Yuasa
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
entity UserModule_SDRAMC is
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
end UserModule_SDRAMC;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_SDRAMC is

	---------------------------------------------------
	--Declarations of Components
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
	
	component spw_sdram_top
		port(
			clk				: in	std_logic;-- 96MHz
			xreset			: in	std_logic;
			spw_wr			: in	std_logic;
			spw_rd			: in	std_logic;
			spw_hbe			: in	std_logic;
			spw_adr			: in	std_logic_vector(24 downto 0);
			spw_wdd			: in	std_logic_vector(15 downto 0);
			spw_rdd			: out	std_logic_vector(15 downto 0);
			sdram_cs			: in	std_logic;
			sdram_rdy		: out	std_logic;
		-- SDRAM Interface		
			o_cke			: out	std_logic;
			o_xdcs		: out	std_logic;
			o_xdras		: out	std_logic;
			o_xdcas		: out	std_logic;
			o_xdwe		: out	std_logic;
			o_dqm			: out	std_logic_vector(1 downto 0);
			o_sda			: out	std_logic_vector(12 downto 0);
			o_ba			: out	std_logic_vector(1 downto 0);
			sdd			: inout	std_logic_vector(15 downto 0)
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
		(Initialize,	Idle,	DataReceive_wait,	DataReceive,  Request_and_Wait, WriteAddressIncrement, ReadAddressIncrement, Finalize);
	signal iBus_Receive_state : iBus_Receive_StateMachine_State := Initialize;
	signal WriteAddressIncrement_ReturnState : iBus_Receive_StateMachine_State := Initialize;
	
	type iBus_beRead_StateMachine_State is
		(Initialize,	Idle,	WaitDone, Request_and_Wait);
	signal iBus_beRead_state : iBus_beRead_StateMachine_State := Initialize;

	type Sdramc_StateMachine_State is
		(Initialize,	Idle,
			SdramAccess_Write_Wait_0,SdramAccess_Write_Wait_1,
			SdramAccess_Read_Wait_0,SdramAccess_Read_Wait_1
		);
	signal Sdram_state : Sdramc_StateMachine_State := Initialize;

	--Signals
	signal reset		: std_logic   := '0';
	signal Clock		: std_logic   := '0';
	
	--SDRAMC
	signal Sdram_dqm		: std_logic_vector(1 downto 0) := (others=>'0');
	signal SdramWrite		: std_logic   := '0';
	signal SdramRead		: std_logic   := '0';
	signal SdramWriteX	: std_logic; --SDRAMC signals are Active-Low
	signal SdramReadX		: std_logic;
	signal SdramCs			: std_logic   := '1';
	signal SdramReady		: std_logic   := '0';

	signal SdramWriteData		: std_logic_vector(15 downto 0) := (others=>'0');
	signal SdramReadData			: std_logic_vector(15 downto 0) := (others=>'0');
	
	signal SdramAddress				:	std_logic_vector(24 downto 0);
	signal SdramWriteAddress		:	std_logic_vector(24 downto 0);
	signal SdramWriteAddress_High	:	std_logic_vector(15 downto 0) := (others=>'0');
		--only the least 9bits ([8:0]) are valid
	signal SdramWriteAddress_Low	:	std_logic_vector(15 downto 0) := (others=>'0');
	signal SdramReadAddress			:	std_logic_vector(24 downto 0);
	signal SdramReadAddress_High	:	std_logic_vector(15 downto 0) := (others=>'0');
		--only the least 9bits ([8:0]) are valid
	signal SdramReadAddress_Low	:	std_logic_vector(15 downto 0) := (others=>'0');

	signal Sdram_WriteRequest			: std_logic   := '0';
	signal Sdram_WriteRequest_Done	: std_logic   := '0';
	signal Sdram_ReadRequest			: std_logic   := '0';
	signal Sdram_ReadRequest_Done		: std_logic   := '0';
	
	signal WriteAddress_IncrementFlag		: std_logic	:= '0';
	signal ReadAddress_IncrementFlag			: std_logic	:= '0';
	signal Request_ReadAddress_Increment	: std_logic	:= '0';
	signal ReadAddress_Increment_Done		: std_logic	:= '0';
	--Registers

	--Counters
	
	--State Machines' State-variables
	
	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin	
	
	---------------------------------------------------
	--Instantiations of Components
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

	inst_spw_sdram_top : spw_sdram_top
		port map(
			clk				=> Clock100MHz,
			xreset			=> GlobalReset,
			spw_wr			=> SdramWriteX,
			spw_rd			=> SdramReadX,
			spw_hbe			=> '0',
			spw_adr			=> SdramAddress,
			spw_wdd			=> SdramWriteData,
			spw_rdd			=> SdramReadData,
			sdram_cs			=> '1',
			sdram_rdy		=> SdramReady,
		-- SDRAM Interface		
			o_cke			=> Sdram_cke,
			o_xdcs		=> Sdram_xdcs,
			o_xdras		=> Sdram_xdras,
			o_xdcas		=> Sdram_xdcas,
			o_xdwe		=> Sdram_xdwe,
			o_dqm			=> Sdram_dqm,
			o_sda			=> Sdram_sda,
			o_ba			=> Sdram_ba,
			sdd			=> Sdram_sdd
		);
	Sdram_ldqm <= Sdram_dqm(0);
	Sdram_udqm <= Sdram_dqm(1);

	---------------------------------------------------
	--Static relationships
	---------------------------------------------------
	reset <= not GlobalReset;
	Clock <= Clock50MHz;
	SdramWriteAddress(24 downto 16) <= SdramWriteAddress_High(8 downto 0);
	SdramWriteAddress(15 downto 0) <= SdramWriteAddress_Low;
	
	SdramReadAddress(24 downto 16) <= SdramReadAddress_High(8 downto 0);
	SdramReadAddress(15 downto 0) <= SdramReadAddress_Low;
	
	SdramWriteX <= not SdramWrite;
	SdramReadX <= not SdramRead;
	
	
	---------------------------------------------------
	--Dynamic Processes with Sensitivity List
	---------------------------------------------------
	process (Clock100MHz,GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			--Initialize StateMachine's state
			Sdram_state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			case Sdram_state is
				when Initialize =>
					SdramWrite <= '0'; --SDRAMC signals are Active-Low
					SdramRead <= '0';
					Sdram_state <= Idle;
				when Idle =>
					Sdram_WriteRequest_Done <= '0';
					Sdram_ReadRequest_Done <= '0';
					if (Sdram_WriteRequest='1') then
						SdramAddress <= SdramWriteAddress;
						SdramWriteData <= BusIF2UserModule.ReceivedData;
						SdramWrite <= '1';
						Sdram_state <= SdramAccess_Write_Wait_0;
					elsif (Sdram_ReadRequest='1') then
						SdramAddress <= SdramReadAddress;
						SdramRead <= '1';
						Sdram_state <= SdramAccess_Read_Wait_0;
					end if;
				when SdramAccess_Write_Wait_0 =>
					if (SdramReady='1') then
						SdramWrite <= '0';
						Sdram_WriteRequest_Done <= '1';
						Sdram_state <= SdramAccess_Write_Wait_1;
					end if;
				when SdramAccess_Write_Wait_1 =>
					if (Sdram_WriteRequest='0') then
						Sdram_WriteRequest_Done <= '0';
						Sdram_state <= Idle;
					else
						Sdram_WriteRequest_Done <= '1';
					end if;
				when SdramAccess_Read_Wait_0 =>
					if (SdramReady='1') then
						SdramRead <= '0';
						Sdram_ReadRequest_Done <= '1';
						Sdram_state <= SdramAccess_Read_Wait_1;
					end if;
				when SdramAccess_Read_Wait_1 =>
					if (Sdram_ReadRequest='0') then
						Sdram_ReadRequest_Done <= '0';
						Sdram_state <= Idle;
					end if;
				when others =>
					Sdram_state <= Initialize;
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
					Sdram_WriteRequest <= '0';
					--move to next state
					iBus_Receive_state  <= Idle;
				when Idle =>
					WriteAddress_IncrementFlag <= '0';
					--check if there is any received data (sent from another UserModule)
					--if there is, ReceiveFIFO's Empty is '0'
					if (Request_ReadAddress_Increment='1') then
						--move to next state
						iBus_Receive_state  <= ReadAddressIncrement;
					elsif (BusIF2UserModule.ReceiveBufferEmpty='0') then
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
					case BusIF2UserModule.ReceivedAddress is
						when AddressOf_SDRAM_WriteAddresss_High_Register =>
							SdramWriteAddress_High <= BusIF2UserModule.ReceivedData;
							--move to next state
							iBus_Receive_state  <= Idle;
						when AddressOf_SDRAM_WriteAddresss_Low_Register =>
							SdramWriteAddress_Low <= BusIF2UserModule.ReceivedData;
							--move to next state
							iBus_Receive_state  <= Idle;
						when AddressOf_SDRAM_ReadAddresss_High_Register =>
							SdramReadAddress_High <= BusIF2UserModule.ReceivedData;
							--move to next state
							iBus_Receive_state  <= Idle;
						when AddressOf_SDRAM_ReadAddresss_Low_Register =>
							SdramReadAddress_Low <= BusIF2UserModule.ReceivedData;
							--move to next state
							iBus_Receive_state  <= Idle;
						when AddressOf_SDRAM_Write_Register =>
							--move to next state
							iBus_Receive_state  <= Request_and_Wait;
						when AddressOf_SDRAM_WriteThenIncrement_Register =>
							WriteAddress_IncrementFlag <= '1';
							--move to next state
							iBus_Receive_state  <= Request_and_Wait;
						when AddressOf_SDRAM_IncrementThenWrite_Register =>
							--move to next state
							WriteAddressIncrement_ReturnState <= Request_and_Wait;
							iBus_Receive_state  <= WriteAddressIncrement;
						when others =>
							--move to next state
							iBus_Receive_state  <= Idle;
					end case;
				when Request_and_Wait =>
					if (Sdram_WriteRequest_Done='1') then
						Sdram_WriteRequest <= '0';
						--move to next state
						iBus_Receive_state  <= Finalize;
					else
						Sdram_WriteRequest <= '1';
					end if;
				when Finalize =>
					if (WriteAddress_IncrementFlag='1') then
						WriteAddress_IncrementFlag <= '0';
						--move to next state
						WriteAddressIncrement_ReturnState <= Idle;
						iBus_Receive_state  <= WriteAddressIncrement;
					else
						iBus_Receive_state  <=  Idle;
					end if;
				when WriteAddressIncrement =>
					if (SdramWriteAddress_Low=x"fffe") then
						if (SdramWriteAddress_High=FinalAddressOf_SDRAM(31 downto 16)) then
							SdramWriteAddress_High <= InitialAddressOf_SDRAM(31 downto 16);
							SdramWriteAddress_Low <= InitialAddressOf_SDRAM(15 downto 0);
						else
							SdramWriteAddress_High <= SdramWriteAddress_High + 1;
							SdramWriteAddress_Low <= x"0000";
						end if;
					else
						SdramWriteAddress_Low <= SdramWriteAddress_Low + 2;
					end if;
					--move to next state
					iBus_Receive_state  <= WriteAddressIncrement_ReturnState;
				when ReadAddressIncrement =>
					if (Request_ReadAddress_Increment='0') then
						ReadAddress_Increment_Done <= '0';
						--move to next state
						iBus_Receive_state  <= Idle;
						if (SdramReadAddress_Low=x"fffe") then
							if (SdramReadAddress_High=FinalAddressOf_SDRAM(31 downto 16)) then
								SdramReadAddress_High <= InitialAddressOf_SDRAM(31 downto 16);
								SdramReadAddress_Low <= InitialAddressOf_SDRAM(15 downto 0);
							else
								SdramReadAddress_High <= SdramReadAddress_High + 1;
								SdramReadAddress_Low <= x"0000";
							end if;
						else
							SdramReadAddress_Low <= SdramReadAddress_Low + 2;
						end if;					
					else
						ReadAddress_Increment_Done <= '1';
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
					UserModule2BusIF.beReadDone <= '0';
					Sdram_ReadRequest <= '0';
					--move to next state
					iBus_beRead_state <= Idle;
				when Idle =>
					ReadAddress_IncrementFlag <= '0';
					if (BusIF2UserModule.beRead='1') then
						case BusIF2UserModule.beReadAddress is
							when AddressOf_SDRAM_WriteAddresss_High_Register =>
								UserModule2BusIF.beReadData <= SdramWriteAddress_High;
								--tell completion of the "beRead" process to iBus_BusIF
								UserModule2BusIF.beReadDone <= '1';
								--move to next state
								iBus_beRead_state  <= WaitDone;
							when AddressOf_SDRAM_WriteAddresss_Low_Register =>
								UserModule2BusIF.beReadData <= SdramWriteAddress_Low;
								--tell completion of the "beRead" process to iBus_BusIF
								UserModule2BusIF.beReadDone <= '1';
								--move to next state
								iBus_beRead_state  <= WaitDone;
							when AddressOf_SDRAM_ReadAddresss_High_Register =>
								UserModule2BusIF.beReadData <= SdramReadAddress_High;
								--tell completion of the "beRead" process to iBus_BusIF
								UserModule2BusIF.beReadDone <= '1';
								--move to next state
								iBus_beRead_state  <= WaitDone;
							when AddressOf_SDRAM_ReadAddresss_Low_Register =>
								UserModule2BusIF.beReadData <= SdramReadAddress_Low;
								--tell completion of the "beRead" process to iBus_BusIF
								UserModule2BusIF.beReadDone <= '1';
								--move to next state
								iBus_beRead_state  <= WaitDone;
							when AddressOf_SDRAM_Read_Register =>
								Sdram_ReadRequest <= '1';
								--move to next state
								iBus_beRead_state  <= Request_and_Wait;
							when AddressOf_SDRAM_ReadThenIncrement_Register =>
								ReadAddress_IncrementFlag <= '1';
								Sdram_ReadRequest <= '1';
								--move to next state
								iBus_beRead_state  <= Request_and_Wait;
							when others =>
								--sonzai shina address heno yomikomi datta tokiha
								--0xabcd toiu tekitou na value wo kaeshite oku kotoni shitearu
								UserModule2BusIF.beReadData <= x"abcd";
						end case;
					end if;
				when Request_and_Wait =>
					if (Sdram_ReadRequest_Done='1') then
						Sdram_ReadRequest <= '0';
						UserModule2BusIF.beReadDone <= '1';
						UserModule2BusIF.beReadData <= SdramReadData;
						iBus_beRead_state  <= WaitDone;
					end if;
				when WaitDone =>
					--wait until the "beRead" process completes
					if (BusIF2UserModule.beRead='0') then
						UserModule2BusIF.beReadDone <= '0';
						if (ReadAddress_IncrementFlag='1') then
							if (ReadAddress_Increment_Done='1') then
								Request_ReadAddress_Increment <= '0';
								--move to next state
								iBus_beRead_state  <= Idle;
							else
								Request_ReadAddress_Increment <= '1';
							end if;
						else
							--move to next state
							iBus_beRead_state  <= Idle;
						end if;
					end if;
				when others =>
					--move to next state
					iBus_beRead_state  <= Initialize;
			end case;
		end if;
	end process;
end Behavioral;