--UserModule_ConsumerModule_Calculator_MaxValue_PSD.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--UserModule / Consumer Module
--extract Max ADC as Pulseheight / calculate pulse shape index
--
--
--ver20071114 Takayuki Yuasa
--file created
--based on UserModule_ConsumerModule_Calculator_<axValue_PSD.vhdl

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
entity UserModule_ConsumerModule_Calculator_MaxValue_PSD is
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
end UserModule_ConsumerModule_Calculator_MaxValue_PSD;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_ConsumerModule_Calculator_MaxValue_PSD is

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
	constant NumberOf_BaselineSample	: integer := 4;
	
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
	
	signal Maximum				: std_logic_vector(15 downto 0)	:= (others => '0');
	signal Maximum_Address	: std_logic_vector(9 downto 0)	:= (others => '0');
	signal BL_corrected_Maximum	: std_logic_vector(15 downto 0)	:= (others => '0');
	signal Baseline			: std_logic_vector(31 downto 0)	:= (others => '0');
	
	signal RisetimeLD			: std_logic_vector(15 downto 0)	:= (others => '0');
	signal RisetimeUD			: std_logic_vector(15 downto 0)	:= (others => '0');
	signal RisetimeLD_Time	: std_logic_vector(15 downto 0)	:= (others => '0');
	signal RisetimeUD_Time	: std_logic_vector(15 downto 0)	:= (others => '0');
	
	--Registers
		
	type AdcDataVector is array (INTEGER range <>) of std_logic_vector(ADCResolution-1 downto 0);
	signal AdcDataArray	:	AdcDataVector(MaximumOfDelay downto 0);
	
	type UserModule_StateMachine_State is
		(Initialize, Idle, Wait2Clocks, 
			--Event Copy
			CopyEvent_0, CopyEvent_1, CopyEvent_1_5, CopyEvent_2, CopyEvent_3, CopyHeader_0, CopyHeader_0_5, CopyHeader_1, CopyHeader_2, CopyHeader_3, TellDoneToEventMgr,
			--Analysis
			StartAnalysis, DeleteChFlag, DeleteChFlag_2, DeleteChFlag_3, SearchMaximum, SearchMaximum_2,
			Baseline_1, Baseline_2, Baseline_3, Baseline_4, 
			Risetime_1, Risetime_2, Risetime_3, Risetime_4, Risetime_5, Risetime_6,
			Psd_1, Psd_2, Psd_3, Psd_4,
			AnalysisDone,
			--Sent Result
			WaitMgrGrant,
			Send_0, Send_1, Send_1_5, Send_2, Send_3, Send_4, Send_5, Send_6, Send_7, Send_8, Send_9, Send_10, Send_11, Send_12,
			WriteConsumerNumber, WriteSeparator_0, WriteSeparator_1,
			--Finalize
			Finalize);
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
					Maximum <= (others=>'0');
					Maximum_Address <= (others=>'0');
					FlagI <= '0';
					UserModule_state <= Idle;
				when Idle =>
					--initialize
					Baseline <= (others=>'0');
					RisetimeLD_Time <= (others=>'0');
					RisetimeUD_Time <= (others=>'0');
					LoopI <= 0;
					--request event
					Consumer2EventMgr.Request <= '1';
					if (EventMgr2Consumer.Grant='1') then
						RamAddress <= (others=>'0');
						DataCount <= 0;
						LoopP <= 0;
						UserModule_state <= CopyEvent_0;
					end if;
				--------------------------------------------
				--Copy Event Body from EventProducer
				--------------------------------------------
				when CopyEvent_0 =>
					RamWriteEnable <= '0';
					Consumer2EventMgr.ReadEnable <= '1';
					UserModule_state <= CopyEvent_1;
				when CopyEvent_1 =>
					Consumer2EventMgr.ReadEnable <= '0';
					if (LoopP=2) then
						LoopP <= 0;
						UserModule_state <= CopyEvent_2;
					else
						LoopP <= LoopP + 1;
					end if;
				when CopyEvent_2 =>
					if (EventMgr2Consumer.Data(15 downto 12)=HEADER_FLAG) then
						--the data/header separator
						HeaderSize <= EventMgr2Consumer.Data(11 downto 0);
						UserModule_state <= CopyHeader_0;					
					else
						RamDataIn <= EventMgr2Consumer.Data;
						RamWriteEnable <= '1';
						UserModule_state <= CopyEvent_3;	
					end if;
				when CopyEvent_3 =>
					RamWriteEnable <= '0';
					RamAddress <= RamAddress + 1;
					DataCount <= DataCount + 1;
					UserModule_state <= CopyEvent_0;
				--------------------------------------------
				--Copy Event Header from EventProducer
				--------------------------------------------
				when CopyHeader_0 =>
					Consumer2EventMgr.ReadEnable <= '1';
					LoopP <= 0;
					UserModule_state <= CopyHeader_0_5;
				when CopyHeader_0_5 =>
					Consumer2EventMgr.ReadEnable <= '0';
					if (LoopP=2) then
						LoopP <= 0;
						UserModule_state <= CopyHeader_1;
					else
						LoopP <= LoopP + 1;
					end if;
				when CopyHeader_1 =>
					LoopI <= LoopI + 1;
					case LoopI is
						when 0 =>
							Realtime(47 downto 32) <= EventMgr2Consumer.Data;
							UserModule_state <= CopyHeader_0;
						when 1 =>
							Realtime(31 downto 16) <= EventMgr2Consumer.Data;
							UserModule_state <= CopyHeader_0;
						when 2 =>
							Realtime(15 downto 0) <= EventMgr2Consumer.Data;
							UserModule_state <= TellDoneToEventMgr;
						when others =>
					end case;
				when TellDoneToEventMgr =>
					RamAddress <= (others=>'0');
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
					UserModule_state <= DeleteChFlag_3;
				when DeleteChFlag_3 =>
					RamWriteEnable <= '0';
					RamAddress <= (others => '0');
					UserModule_state <= SearchMaximum;
				--pha_max
				when SearchMaximum =>
					Maximum <= (others=>'0');
					LoopO <= 0;
					RamAddress <= RamAddress + 1;
					UserModule_state <= SearchMaximum_2;
				when SearchMaximum_2 =>
					if (Maximum<RamDataOut) then
						Maximum <= RamDataOut;
						Maximum_Address <= RamAddress;
					end if;
					if (LoopO=DataCount-1) then
						UserModule_state <= Baseline_1;
					else
						LoopO <= LoopO + 1;
						RamAddress <= RamAddress + 1;
					end if;
				--baseline
				when Baseline_1 =>
					RamAddress <= (others=>'0');
					LoopO <= 0;
					UserModule_state <= Baseline_2;
				when Baseline_2 =>
					RamAddress <= RamAddress + 1;
					UserModule_state <= Baseline_3;
				when Baseline_3 =>
					if (LoopO=NumberOf_BaselineSample) then
						Baseline <= "00" & Baseline(31 downto 2);
						UserModule_state <= Baseline_4;
					else
						LoopO <= LoopO + 1;
						Baseline <= Baseline + (x"0000"&RamDataOut);
						RamAddress <= RamAddress + 1;
					end if;
				when Baseline_4 =>
					UserModule_state <= Risetime_1;
				--risetime
				when Risetime_1 =>
					BL_corrected_Maximum <= Maximum - Baseline(15 downto 0);
					RamAddress <= (others=>'0');
					UserModule_state <= Risetime_2;
				when Risetime_2 =>
					RisetimeLD <= "000" & BL_corrected_Maximum(15 downto 3);
					UserModule_state <= Risetime_3;
				when Risetime_3 =>
					RisetimeLD <= RisetimeLD + Baseline(15 downto 0);
					RisetimeUD <= BL_corrected_Maximum - RisetimeLD;
					UserModule_state <= Risetime_4;
				when Risetime_4 =>
					RisetimeUD <= RisetimeUD + Baseline(15 downto 0);
					RamAddress <= RamAddress + 1;
					UserModule_state <= Risetime_5;
				when Risetime_5 =>
					if (RamDataOut>=RisetimeLD or RamAddress>=Maximum_Address) then
						RisetimeLD_Time(9 downto 0) <= RamAddress;
						UserModule_state <= Risetime_6;
					else
						RamAddress <= RamAddress + 1;
					end if;
				when Risetime_6 =>
					if (RamDataOut>=RisetimeUD or RamAddress>=Maximum_Address) then
						RisetimeUD_Time(9 downto 0) <= RamAddress;
						UserModule_state <= AnalysisDone;
					else
						RamAddress <= RamAddress + 1;
					end if;
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
						UserModule_state <= Send_0;
					end if;
				when Send_0 =>
					Consumer2ConsumerMgr.Data <= x"fff0";
					UserModule_state <= Send_1;
				when Send_1 =>
					Consumer2ConsumerMgr.WriteEnable <= '1';
					Consumer2ConsumerMgr.Data <= x"fff0";
					UserModule_state <= Send_1_5;
				when Send_1_5 =>
					Consumer2ConsumerMgr.Data(15 downto 3) <= (others=>'0');
					Consumer2ConsumerMgr.Data(2 downto 0) <= CurrentCh;
					UserModule_state <= Send_2;
				when Send_2 =>
					Consumer2ConsumerMgr.Data <= conv_std_logic_vector(ConsumerNumber,16);
					UserModule_state <= Send_3;
				when Send_3 =>
					Consumer2ConsumerMgr.Data <= Maximum;
					UserModule_state <= Send_4;
				when Send_4 =>
					Consumer2ConsumerMgr.Data <= Realtime(47 downto 32);
					UserModule_state <= Send_5;
				when Send_5 =>
					Consumer2ConsumerMgr.Data <= Realtime(31 downto 16);
					UserModule_state <= Send_6;
				when Send_6 =>
					Consumer2ConsumerMgr.Data <= Realtime(15 downto 0);
					UserModule_state <= Send_7;
				when Send_7 =>
					Consumer2ConsumerMgr.Data <= Baseline(15 downto 0);
					UserModule_state <= Send_8;
				when Send_8 =>
					Consumer2ConsumerMgr.Data <= RisetimeLD_time;
					UserModule_state <= Send_9;
				when Send_9 =>
					Consumer2ConsumerMgr.Data <= RisetimeUD_time;
					RamAddress <= (others=>'0');
					UserModule_state <= Send_10;
				when Send_10 =>
					Consumer2ConsumerMgr.Data <= x"fff1";
					UserModule_state <= Send_11;
				when Send_11 =>
					Consumer2ConsumerMgr.WriteEnable <= '0';
					RamAddress <= RamAddress + 1;
					UserModule_state <= Send_12;
				when Send_12 => --waveform
					if (RamAddress>=ConsumerMgr2Consumer.EventPacket_NumberOfWaveform(9 downto 0)) then
					--if (RamAddress>=10) then
						Consumer2ConsumerMgr.WriteEnable <= '0';
						UserModule_state <= WriteSeparator_0;
					else
						Consumer2ConsumerMgr.WriteEnable <= '1';
						Consumer2ConsumerMgr.Data <= RamDataOut;
						RamAddress <= RamAddress + 1;
					end if;
				when WriteSeparator_0 =>
					Consumer2ConsumerMgr.WriteEnable <= '1';
					Consumer2ConsumerMgr.Data <= x"fff2";
					UserModule_state <= WriteSeparator_1;
				when WriteSeparator_1 =>
					Consumer2ConsumerMgr.WriteEnable <= '1';
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