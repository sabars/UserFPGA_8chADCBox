--UserModule_ConsumerModule_Calculator_Waveform.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserModule / Consumer Module / extract Max ADC as Pulseheight
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
entity UserModule_ConsumerModule_Calculator_Waveform is
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
end UserModule_ConsumerModule_Calculator_Waveform;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_ConsumerModule_Calculator_Waveform is

	---------------------------------------------------
	--Declarations of Components
	---------------------------------------------------
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
	--Declarations of Signals
	---------------------------------------------------
	--Signals
	signal RamAddress			: std_logic_vector(9 downto 0)	:= (others => '0');
	signal RamDataIn			: std_logic_vector(15 downto 0)	:= (others => '0');
	signal RamDataOut			: std_logic_vector(15 downto 0)	:= (others => '0');
	signal Temp					: std_logic_vector(15 downto 0)	:= (others => '0');
	signal RamWriteEnable	: std_logic	:= '0';
	signal CurrentCh			: std_logic_vector(2 downto 0)	:= (others => '0');
	signal HeaderSize 		: std_logic_vector(11 downto 0)	:= (others => '0');
	signal Realtime	 		: std_logic_vector(47 downto 0)	:= (others => '0');
	signal FlagI				: std_logic	:= '0';
	signal LoopI				: integer range 0 to 127			:= 0;
	signal DataCount			: integer range 0 to 1024			:= 0;
	signal LoopO				: integer range 0 to 1024			:= 0;
	signal LoopP				: integer range 0 to 3				:= 0;
	
	--Registers
		
	type AdcDataVector is array (INTEGER range <>) of std_logic_vector(ADCResolution-1 downto 0);
	signal AdcDataArray	:	AdcDataVector(MaximumOfDelay downto 0);
	
	type UserModule_StateMachine_State is
		(Initialize, Idle, Wait2Clocks, CopyEvent, CopyHeader, CopyHeader_2, CopyHeader_3,
			TellDoneToEventMgr, StartAnalysis, DeleteChFlag, DeleteChFlag_2,
			AnalysisDone, WaitMgrGrant, SendingEvent, WriteSeparator, Finalize);
	signal UserModule_state : UserModule_StateMachine_State := Initialize;

	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin	
	
	---------------------------------------------------
	--Instantiations of Components
	---------------------------------------------------
	inst_ram : UserModule_Ram
		port map(
			Address		=> RamAddress,
			DataIn		=> RamDataIn,
			DataOut		=> RamDataOut,
			WriteEnable	=> RamWriteEnable,
			Clock			=> Clock
		);
		
	---------------------------------------------------
	--Static relationships
	---------------------------------------------------
	
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
					Consumer2EventMgr.Request <= '0';
					Consumer2EventMgr.Done <= '0';
					Consumer2EventMgr.ReadEnable <= '0';
					Consumer2ConsumerMgr.Data <= (others=>'0');
					Consumer2ConsumerMgr.WriteEnable <= '0';
					Consumer2ConsumerMgr.EventReady <= '0';
					RamWriteEnable <= '0';
					FlagI <= '0';
					UserModule_state <= Idle;
				when Idle =>
					--request event
					Consumer2EventMgr.Request <= '1';
					if (EventMgr2Consumer.Grant='1') then
						RamAddress <= (others=>'0');
						DataCount <= 0;
						Consumer2EventMgr.ReadEnable <= '1';
						LoopP <= 0;
						UserModule_state <= Wait2Clocks;
					end if;
				when Wait2Clocks =>
					if (LoopP=1) then
						LoopP <= 0;
						UserModule_state <= CopyEvent;
					else
						LoopP <= LoopP + 1;
					end if;
				--------------------------------------------
				--Copy Event Body from EventProducer
				--------------------------------------------
				when CopyEvent =>
					--copy data from chmodule fifo
					RamDataIn <= EventMgr2Consumer.Data;
					if (LoopP=1) then
						RamWriteEnable <= '1';
						LoopP <= LoopP + 1;
					elsif (LoopP=2) then
						if (EventMgr2Consumer.Data(15 downto 12)/=HEADER_FLAG) then
							DataCount <= DataCount + 1;
						end if;
						RamAddress <= RamAddress + 1;
					else
						LoopP <= LoopP + 1;
					end if;
					if (EventMgr2Consumer.Data(15 downto 12)=HEADER_FLAG) then
						LoopI <= 0;
						HeaderSize <= EventMgr2Consumer.Data(11 downto 0);
						UserModule_state <= CopyHeader;
					end if;
				--------------------------------------------
				--Copy Event Header from EventProducer
				--------------------------------------------
				when CopyHeader =>
					RamWriteEnable <= '0';
					--in this implementation, we know header size (3words)
					--and use the information explicitly.
					--therefore we dont use LoopI variable although we defined it above
					Realtime(47 downto 32) <= EventMgr2Consumer.Data;
					UserModule_state <= CopyHeader_2;
				when CopyHeader_2 =>
					Realtime(31 downto 16) <= EventMgr2Consumer.Data;
					UserModule_state <= CopyHeader_3;
				when CopyHeader_3 =>
					Realtime(15 downto 0) <= EventMgr2Consumer.Data;
					UserModule_state <= TellDoneToEventMgr;
				when TellDoneToEventMgr =>
					RamAddress <= (others=>'0');
					Consumer2EventMgr.ReadEnable <= '0';
					Consumer2EventMgr.Request <= '0';
					if (EventMgr2Consumer.Grant='0') then
						Consumer2EventMgr.Done <= '0';
						UserModule_state <= StartAnalysis;
					else
						Consumer2EventMgr.Done <= '1';
					end if;
				--------------------------------------------
				--Event Analysis
				--------------------------------------------
				when StartAnalysis =>
					--first of all, delete ch information
					--which is written in the first data
					RamAddress <= (others => '0');
					UserModule_state <= DeleteChFlag;
				when DeleteChFlag =>
					Temp <= RamDataOut;
					CurrentCh <= RamDataOut(14 downto 12);
					UserModule_state <= DeleteChFlag_2;
				when DeleteChFlag_2 =>
					RamDataIn <= x"0" & Temp(11 downto 0);
					RamWriteEnable <= '1';
					UserModule_state <= AnalysisDone;
				when AnalysisDone =>
					RamWriteEnable <= '0';
					Consumer2ConsumerMgr.EventReady <= '1';
					--send waveform data to SDRAM
					UserModule_state <= WaitMgrGrant;
				--------------------------------------------
				--Send to ConsumerMgr
				--------------------------------------------
				when WaitMgrGrant =>
					if (ConsumerMgr2Consumer.Grant='1') then
						LoopO <= 1;
						FlagI <= '0';
						Consumer2ConsumerMgr.Data <= x"000" & "0" & CurrentCh;
						RamAddress <= conv_std_logic_vector(LoopO,10);
						UserModule_state <= SendingEvent;
					end if;
				when SendingEvent =>
					if (FlagI='0') then
						FlagI <= '1';
					else
						Consumer2ConsumerMgr.WriteEnable <= '1';
					end if;
					Consumer2ConsumerMgr.Data <= RamDataOut;
					RamAddress <= conv_std_logic_vector(LoopO,10);
					if (LoopO=DataCount) then
						UserModule_state <= WriteSeparator;
					else
						LoopO <= LoopO + 1;
					end if;
				when WriteSeparator =>
					Consumer2ConsumerMgr.Data <= x"ffff";
					UserModule_state <= Finalize;
				--------------------------------------------
				--Finalize
				--------------------------------------------
				when Finalize =>
					Consumer2ConsumerMgr.WriteEnable <= '0';
					Consumer2ConsumerMgr.EventReady <= '0';
					if (ConsumerMgr2Consumer.Grant='0') then
						LoopO <= 0;
						UserModule_state <= Idle;
					end if;
				when others =>
					UserModule_state <= Initialize;
			end case;
		end if;
	end process;
	
end Behavioral;