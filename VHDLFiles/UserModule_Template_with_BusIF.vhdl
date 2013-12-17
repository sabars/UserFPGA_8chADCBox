--UserModule_Template_with_BusIF.vhdl
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
entity UserModule_Template_with_BusIF is
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
end UserModule_Template_with_BusIF;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_Template_with_BusIF is

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
	signal SampleRegister	:	std_logic_vector(15 downto 0)	:= (others => '0');
	signal InputRegister		:	std_logic_vector(15 downto 0)	:= (others => '0');
	signal OutputRegister	:	std_logic_vector(15 downto 0)	:= (others => '0');
	signal Counter				:	integer range 0 to 10000 := 0;
	
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
	OutputSignal <= OutputRegister;
	
	---------------------------------------------------
	--Dynamic Processes with Sensitivity List
	---------------------------------------------------
	
	--synchronize input signal(s)
	process(Clock, GlobalReset)
	begin
		if (GlobalReset='0') then
			--reset
			InputRegister <= (others => '0'); --all zero
		elsif (Clock'Event and Clock='1') then
			InputRegister <= InputSignal; --latch input signal
		end if;
	end process;
	
	--以下のサンプルでは、IdleステートでCounterという整数型のレジスタを、
	--1Nロックごとにカウントアップしていきます。Counterﾌ値が9999になったら、
	--internal Busにぶら下がったモジュールのx"f000"宛てにx"abcd"という
	--値を送信します。そのために、DoSomethingステートでBusIFの
	--SendAddressやSendDataをセットし、SendEnableを'1'にしています。
	--SendEnable信号は、その次のクロックで移行する、WaitDoneステートの中で
	--'0'にクリアされます。WaitDoneステートでは、BusIFのSend FIFOが
	--ちゃんと空になっているか(x"abcd"というデータが送信されたか)を
	--確認してから、Initializeステートに戻ります。
	--Initializeステート以降は上記の動作を繰り返します。
	
	--UserModule main state machine
	MainProcess : process (Clock, GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			--write Reset process here
			--
			--
			--
			--Initialize StateMachine's state
			UserModule_state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			case UserModule_state is
				when Initialize =>
					--write initialize process here
					--
					--
					--sample
					Counter <= 0;
					UserModule2BusIF.SendEnable <= '0';
					--move to next state
					UserModule_state <= Idle;
				when Idle =>
					--write Idle process here
					--
					--usually, Idle state is prepared to wait
					--something like an event or a trigger for
					--consequent processes
					--
					--
					--sample
					if (Counter=9) then
						Counter <= 0;
						--move to next state
						UserModule_state <= DoSomething;
					else
						Counter <= Counter + 1;
					end if;
				when DoSomething =>
					--write DoSomething process here
					--
					--
					--sample
					UserModule2BusIF.SendAddress <= x"f000";
					UserModule2BusIF.SendData <= x"abcd";
					UserModule2BusIF.SendEnable <= '1';
					--move to next state
					UserModule_state <= WaitCompletion;
				when WaitCompletion =>
					--write WaitDone process here
					--
					--
					--sample
					UserModule2BusIF.SendEnable <= '0';
					if (BusIF2UserModule.SendBufferEmpty='1') then
						--move to next state
						UserModule_state <= Finalize;
					end if;
				when Finalize =>
					--write Finalize process here
					--
					--
					--sample
					--move to next state
					UserModule_state <= Idle;				
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
						when AddressOf_Template_SampleRegister =>
							--write the register then go back to Idle state
							SampleRegister <= BusIF2UserModule.ReceivedData;
							--move to next state
							iBus_Receive_state  <= Idle;
						when AddressOf_Template_OutputRegister =>
							--write the register then go back to Idle state
							OutputRegister <= BusIF2UserModule.ReceivedData;
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
							when AddressOf_Template_SampleRegister =>
								UserModule2BusIF.beReadData <= SampleRegister;
							when AddressOf_Template_InputRegister =>
								UserModule2BusIF.beReadData <= InputRegister;
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