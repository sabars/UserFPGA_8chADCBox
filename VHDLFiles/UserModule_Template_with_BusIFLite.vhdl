--UserModule_Template_with_BusIFLite.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserModule Template / with Lite version BusIF
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
entity UserModule_Template_with_BusIFLite is
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
end UserModule_Template_with_BusIFLite;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_Template_with_BusIFLite is

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


	---------------------------------------------------
	--Declarations of Signals
	---------------------------------------------------
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
	signal SampleRegister	:	std_logic_vector(15 downto 0)	:= (others => '0');
	signal InputRegister		:	std_logic_vector(15 downto 0)	:= (others => '0');
	signal OutputRegister	:	std_logic_vector(15 downto 0)	:= (others => '0');
	signal Counter				:	integer range 0 to 10000 := 0;
	
	--State Machines' State-variables
	type iBus_beWritten_StateMachine_State is
		(Initialize,	Idle,	WaitDone);
	signal iBus_beWritten_state : iBus_beWritten_StateMachine_State := Initialize;

	type iBus_beRead_StateMachine_State is
		(Initialize,	Idle,	WaitDone);
	signal iBus_beRead_state : iBus_beRead_StateMachine_State := Initialize;
	
	type UserModule_StateMachine_State is
		(Initialize, Idle, DoSomething, WaitCompletion, Finalize);
	signal UserModule_state : UserModule_StateMachine_State := Initialize;
	
	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin	
	
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
					if (Counter=9999) then
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
					SendAddress <= x"f010";
					SendData <= x"abcd";
					SendGo <= '1';
					--move to next state
					UserModule_state <= WaitCompletion;
				when WaitCompletion =>
					--write WaitDone process here
					--
					--
					--sample
					SendGo <= '0';
					if (SendDone='1') then
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


	--processes beWritten access from BusIF
	--usually, set register value according to beWritten data
	iBus_beWritten_Process : process (Clock,GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			--Initialize StateMachine's state
			iBus_beWritten_state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			case iBus_beWritten_state is
				when Initialize =>
					--move to next state
					iBus_beWritten_state <= Idle;
				when Idle =>
					if (beWritten='1') then
						case beWrittenAddress is
							when AddressOf_Template_Lite_SampleRegister =>
								SampleRegister <= beWrittenData;
							when AddressOf_Template_Lite_OutputRegister =>
								OutputRegister <= beWrittenData;
							when others =>
						end case;
						--tell completion of the "beRead" process to iBus_BusIF
						beWrittenDone <= '1';
						--move to next state
						iBus_beWritten_state  <= WaitDone;
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
					if (beRead='1') then
						case beReadAddress is
							when AddressOf_Template_Lite_SampleRegister =>
								beReadData <= SampleRegister;
							when AddressOf_Template_Lite_InputRegister =>
								beReadData <= InputRegister;
							when others =>
								--sonzai shina address heno yomikomi datta tokiha
								--0xabcd toiu tekitou na value wo kaeshite oku kotoni shitearu
								beReadData <= x"abcd";
						end case;
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

end Behavioral;