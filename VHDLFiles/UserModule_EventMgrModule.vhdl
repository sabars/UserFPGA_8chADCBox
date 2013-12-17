--UserModule_EventMgrModule.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserModule / Event Manager Module
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
entity UserModule_EventMgrModule is
	port(
		ChModule2EventMgr_vector	: in Signal_ChModule2EventMgr_Vector(NumberOfProducerNodes-1 downto 0);
		EventMgr2ChModule_vector	: out Signal_EventMgr2ChModule_Vector(NumberOfProducerNodes-1 downto 0);
		Consumer2EventMgr_vector	: in Signal_Consumer2EventMgr_Vector(NumberOfConsumerNodes-1 downto 0);
		EventMgr2Consumer_vector	: out Signal_EventMgr2Consumer_Vector(NumberOfConsumerNodes-1 downto 0);
		--clock and reset
		Clock				: in	std_logic;
		GlobalReset		: in	std_logic
	);
end UserModule_EventMgrModule;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_EventMgrModule is

	---------------------------------------------------
	--Declarations of Components
	---------------------------------------------------
	component UserModule_EventMgrModule_Selector
		port(
			DataIn			: in	Data_Vector(15 downto 0);
			DataOut			: out	std_logic_vector(15 downto 0);
			Selection		: in	integer range 0 to 16;
			--clock and reset
			Clock				: in	std_logic;
			GlobalReset		: in	std_logic
		);
	end component;
	
	---------------------------------------------------
	--Declarations of Signals
	---------------------------------------------------
	--Signals
	signal LoopI,LoopO,LoopP	: integer range 0 to 15 := 0;	
	
	type Integer_Vector is array (INTEGER range <>) of integer range 0 to 16;--16 is for dummy connection
	signal EventMgr2ChModule_ConnectionMatrix	: Integer_Vector(MaximumOfProducerAndConsumerNodes-1 downto 0);
	signal EventMgr2Consumer_ConnectionMatrix	: Integer_Vector(MaximumOfProducerAndConsumerNodes-1 downto 0);
	
	signal temp : Data_Vector(15 downto 0);
	signal selectorDataOut : Data_Vector(15 downto 0);
	
	signal dummy_EventMgr2ChModule	: Signal_EventMgr2ChModule;
	signal dummy_EventMgr2Consumer	: Signal_EventMgr2Consumer;
	
	constant NotConnected		:	Integer	:= 16; --not connected state
	
	--Registers
	
	--Counters
	
	--State Machines' State-variables

	type UserModule_StateMachine_State is
		(Initialize, Initialize_2, Idle, isAnyDone, Disconnection, isAnyRequest, FindUnconnectedHasDataProducer);
	signal UserModule_state : UserModule_StateMachine_State := Initialize;
	
	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin	
	
	---------------------------------------------------
	--Instantiations of Components
	---------------------------------------------------


	---------------------------------------------------
	--Static relationships
	---------------------------------------------------
	dummy_EventMgr2ChModule.ReadEnable <= '0';
	dummy_EventMgr2Consumer.Grant <= '0';
	dummy_EventMgr2Consumer.Data <= (others=>'X');
	
	Connection :
	for I in 0 to NumberOfProducerNodes-1 generate
	 EventMgr2ChModule_vector(I).ReadEnable
		<=	dummy_EventMgr2ChModule.ReadEnable when EventMgr2ChModule_connectionMatrix(I)=NotConnected
			else Consumer2EventMgr_vector(EventMgr2ChModule_connectionMatrix(I)).ReadEnable;

	 temp(I) <= ChModule2EventMgr_vector(I).Data;
	 inst_selector : UserModule_EventMgrModule_Selector
		port map(
			DataIn		=> temp,
			DataOut		=> selectorDataOut(I),
			Selection	=> EventMgr2Consumer_connectionMatrix(I),
			--clock and reset
			Clock			=> Clock,
			GlobalReset	=> GlobalReset
		);
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
			EventMgr2Consumer_vector(0).Data <= selectorDataOut(0);
			EventMgr2Consumer_vector(1).Data <= selectorDataOut(1);
			case UserModule_state is
				when Initialize =>
					--initialize for vector
					if (LoopI=NumberOfProducerNodes) then
						UserModule_state <= Initialize_2;
					else
						LoopI <= LoopI + 1;
						EventMgr2ChModule_connectionMatrix(LoopI) <= NotConnected;
						EventMgr2Consumer_connectionMatrix(LoopI) <= NotConnected;
					end if;
				when Initialize_2 =>
					--initialize for vector
					if (LoopP=NumberOfConsumerNodes) then
						UserModule_state <= Idle;
					else
						LoopP <= LoopP + 1;
						EventMgr2Consumer_vector(LoopP).Grant <= '0';
					end if;
				when Idle =>
					LoopI <= 0;
					LoopO <= 0;
					LoopP <= 0;
					UserModule_state <= isAnyDone;
				when isAnyDone =>
					if (LoopI=NumberOfConsumerNodes) then
						LoopI <= 0;
						UserModule_state <= isAnyRequest;
					elsif (Consumer2EventMgr_vector(LoopI).Done='1') then
						EventMgr2Consumer_vector(LoopI).Grant <= '0';
						EventMgr2Consumer_connectionMatrix(LoopI) <= NotConnected;
						EventMgr2ChModule_connectionMatrix(EventMgr2Consumer_connectionMatrix(LoopI)) <= NotConnected;
						UserModule_state <= Disconnection;
					else
						LoopI <= LoopI + 1;
					end if;
				when Disconnection =>
					if (Consumer2EventMgr_vector(LoopI).Request='0') then
						LoopI <= LoopI + 1;
						UserModule_state <= isAnyDone;
					end if;
				when isAnyRequest =>
					if (LoopO=NumberOfConsumerNodes) then
						LoopO <= 0;
						UserModule_state <= Idle;
					elsif (Consumer2EventMgr_vector(LoopO).Request='1'
							and EventMgr2Consumer_connectionMatrix(LoopO)=NotConnected) then
						LoopP <= 0;
						UserModule_state <= FindUnconnectedHasDataProducer;
					else
						LoopO <= LoopO + 1;
					end if;
				when FindUnconnectedHasDataProducer =>
					if (LoopP=NumberOfProducerNodes) then
						--could not find "unconnected hasData producer node"
						LoopP <= 0;
						LoopO <= LoopO + 1;
						UserModule_state <= isAnyRequest;
					elsif (EventMgr2ChModule_connectionMatrix(LoopP)=NotConnected
								and ChModule2EventMgr_vector(LoopP).hasData='1') then
						--found! then connect them
						EventMgr2ChModule_connectionMatrix(LoopP) <= LoopO;
						EventMgr2Consumer_connectionMatrix(LoopO) <= LoopP;
						--grant
						EventMgr2Consumer_vector(LoopO).Grant <= '1';
						--break loop
						LoopP <= 0;
						LoopO <= LoopO + 1;
						UserModule_state <= isAnyRequest;
					else
						LoopP <= LoopP + 1;
					end if;
				when others =>
					UserModule_state <= Initialize;
			end case;
		end if;
	end process;
end Behavioral;

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
entity UserModule_EventMgrModule_Selector is
	port(
		DataIn			: in	Data_Vector(15 downto 0);
		DataOut			: out	std_logic_vector(15 downto 0);
		Selection		: in	integer range 0 to 16;
		--clock and reset
		Clock				: in	std_logic;
		GlobalReset		: in	std_logic
	);
end UserModule_EventMgrModule_Selector;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_EventMgrModule_Selector is
	signal temp : std_logic_vector(15 downto 0)	:= x"0000";
begin
	process (Clock, GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			if (Selection<NumberOfProducerNodes) then
				DataOut <= DataIn(Selection);
			else
				DataOut <= x"0000";
			end if;
		end if;
	end process;
end Behavioral;