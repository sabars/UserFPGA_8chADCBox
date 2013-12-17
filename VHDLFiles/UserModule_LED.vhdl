--UserModule_LED.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserModule Template / with FIFO version BusIF
--
--ver20071021 Takayuki Yuasa
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

---------------------------------------------------
--Entity Declaration
---------------------------------------------------
entity UserModule_LED is
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
end UserModule_LED;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_LED is

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
		(Initialize, Idle, DoSomething, WaitCompletion, Finalize);
	signal UserModule_state : UserModule_StateMachine_State := Initialize;
	
	--Registers
	signal LED_internal	:	std_logic_vector(1 downto 0)	:= (others => '0');
	
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
	LED <= LED_internal;
	
	---------------------------------------------------
	--Dynamic Processes with Sensitivity List
	---------------------------------------------------
	
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
					iBus_Receive_state  <= idle;
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
						when AddressOf_LED_Register =>
							--write the register then go back to Idle state
							LED_internal <= BusIF2UserModule.ReceivedData(1 downto 0);
							--move to next state
							iBus_Receive_state  <= Idle;
						when others =>
							--no corresponding address or register
							--move to next state
							iBus_Receive_state  <= Idle;
					end case;
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
							when AddressOf_LED_Register =>
								UserModule2BusIF.beReadData(15 downto 2) <= (others=>'0');
								UserModule2BusIF.beReadData(1 downto 0) <= LED_internal(1 downto 0);
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