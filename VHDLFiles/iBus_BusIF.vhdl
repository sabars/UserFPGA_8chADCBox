--iBus_BusIF.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--internal Bus (iBus) / Bus IF / with FIFO buffer
--
--ver20071105 Takayuki Yuasa
--fixed a bug, Send access from BusController
--while this module requests bus citizenship
--
--ver20071102 Takayuki Yuasa
--fixed a bug, Read access from BusController
--while this module requests bus citizenship
--
--ver20071021 Takayuki Yuasa
--FIFO wo ISE9.2 taiou version ni henkou suruto
--tomoni, FIFO no depth wo 1024 words ni fix shita
--
--ver20071013 Takayuki Yuasa
--receive fifo ga full no tokino shori wo tsuika
--ver0.0
--20061225 Takayuki Yuasa
--20061226 Takayuki Yuasa
--implementation of Send process
--20061228 Takayuki Yuasa
--implementation of Read/beRead process
--20061229 Takayuki Yuasa
--simulation succeeded
--20070109 Takayuki Yuasa
--some bugs were fixed

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
entity iBus_BusIF is
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
end iBus_BusIF;

---------------------------------------------------
--Architecture Declaration
---------------------------------------------------
architecture Behavioral of iBus_BusIF is

	---------------------------------------------------
	--component declaration
	---------------------------------------------------
	--FIFO no component sengen
	component iBus_FIFO is
		port (
			clk: IN std_logic;
			din: IN std_logic_VECTOR(31 downto 0);
			rd_en: IN std_logic;
			rst: IN std_logic;
			wr_en: IN std_logic;
			data_count: OUT std_logic_VECTOR(9 downto 0);
			dout: OUT std_logic_VECTOR(31 downto 0);
			empty: OUT std_logic;
			full: OUT std_logic
		);
	end component;
	
	---------------------------------------------------
	--Declaration of Signals
	---------------------------------------------------
	signal BusBusy	:	std_logic	:=	'0';

	type BusIF_Master_Status is (
		Initialize,
		Idle,
		LatchSendData_and_Request_0,
		LatchSendData_and_Request_1,
		WaitSendRequestGrant,
		WaitReadRequestGrant,
		WaitSendRequestDone,
		WaitReadRequestDone,
		WaitRequestCleared,
		WaitReadGoOff
	);
	type BusIF_Target_Status is (
		Initialize,
		Idle,
		AccessFromBusController,
		WaitbeReadDoneFromUserModule,
		WaitbeWrittenDoneFromUserModule,
		WaitAccessFromBusControllerDone
	);
	signal BusIF_Master_State	:	BusIF_Master_Status :=Initialize;
	signal BusIF_Target_State	:	BusIF_Target_Status :=Initialize;
	
	signal BusIFBusy		:	std_logic :='0';
	
	signal SentAddress	:	std_logic_vector(15 downto 0)	:= x"0000";
	signal SentData	:	std_logic_vector(15 downto 0)	:= x"0000";
	
	--signal ReadDone_signal	:	std_logic	:= '1';
	--signal latched_ReadAddress	:	std_logic_vector(15 downto 0)	:= x"0000";
	--signal latched_beReadAddress	:	std_logic_vector(15 downto 0)	:= x"0000";

	signal BusIF2BusController_Data_Send	: std_logic_vector(15 downto 0) := (others=>'0');
	signal BusIF2BusController_Data_beRead	: std_logic_vector(15 downto 0) := (others=>'0');

	--FIFO signals
	--SendFIFO
	signal WriteEnableOfSendFIFO	:	std_logic	:= '0';
	signal ReadEnableOfSendFIFO	:	std_logic	:= '0';
	signal DataInOfSendFIFO	:	std_logic_vector(31 downto 0)	:= x"00000000";
	signal DataOutOfSendFIFO	:	std_logic_vector(31 downto 0)	:= x"00000000";
	signal DataCountOfSendFIFO	:	std_logic_vector(9 downto 0)	:= "0000000000";
	signal EmptyOfSendFIFO		:	std_logic	:= '0';
	signal FullOfSendFIFO		:	std_logic	:= '0';
	
	--ReceiveFIFO
	signal WriteEnableOfReceiveFIFO	:	std_logic	:= '0';
	signal ReadEnableOfReceiveFIFO	:	std_logic	:= '0';
	signal DataInOfReceiveFIFO	:	std_logic_vector(31 downto 0)	:= x"00000000";
	signal DataOutOfReceiveFIFO	:	std_logic_vector(31 downto 0)	:= x"00000000";
	signal DataCountOfReceiveFIFO	:	std_logic_vector(9 downto 0)	:= "0000000000";
	signal EmptyOfReceiveFIFO		:	std_logic	:= '0';
	signal FullOfReceiveFIFO		:	std_logic	:= '0';
	
	--when request is suspended...
	signal SendRequestSuspendFlag	:	std_logic	:= '0';
	signal ReadRequestSuspendFlag	:	std_logic	:= '0';
	
	--reset
	signal reset		: std_logic   := '0';
	
	--for simulation
	signal addressin,address1,address2 : std_logic_vector(15 downto 0);
	signal address3,address4,addressinteger : integer ;
	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin

	---------------------------------------------------
	--Instanciation of components
	---------------------------------------------------
	SendFIFO : iBus_FIFO
		port map(
			clk	=> Clock,
			din	=> DataInOfSendFIFO,
			rd_en	=> ReadEnableOfSendFIFO,
			rst	=> reset,
			wr_en	=> WriteEnableOfSendFIFO,
			dout	=> DataOutOfSendFIFO,
			data_count => DataCountOfSendFIFO,
			empty	=> EmptyOfSendFIFO,
			full	=> FullOfSendFIFO
		);

	ReceiveFIFO : iBus_FIFO
		port map(
			clk	=> Clock,
			din	=> DataInOfReceiveFIFO,
			rd_en	=> ReadEnableOfReceiveFIFO,
			rst	=> reset,
			wr_en	=> WriteEnableOfReceiveFIFO,
			dout	=> DataOutOfReceiveFIFO,
			data_count => DataCountOfReceiveFIFO,
			empty	=> EmptyOfReceiveFIFO,
			full	=> FullOfReceiveFIFO
		);
	
	---------------------------------------------------
	--Static relationships
	---------------------------------------------------
	reset <= not GlobalReset;
	BusIF2BusController.TransferError <= '0';
--	BusIF2BusController.TransferError
--		<= '1' when WriteEnableOfReceiveFIFO='1' and FullOfSendFIFO='1'
--		else '0';
	
	BusBusy <= BusController2BusIF.BusBusy;
	
	--FIFO-UserModule or FIFO-BusController connection
	--Send FIFO
	DataInOfSendFIFO(31 downto 16)	<= UserModule2BusIF.SendAddress;
	DataInOfSendFIFO(15 downto 0)		<= UserModule2BusIF.SendData;
	WriteEnableOfSendFIFO				<= UserModule2BusIF.SendEnable;
	BusIF2UserModule.SendBufferEmpty	<= EmptyOfSendFIFO;
	BusIF2UserModule.SendBufferFull	<= FullOfSendFIFO;
	
	--Receive FIFO
	DataInOfReceiveFIFO(31 downto 16)	<= BusController2BusIF.Address;
	DataInOfReceiveFIFO(15 downto 0)		<= BusController2BusIF.Data;
	ReadEnableOfReceiveFIFO					<=	UserModule2BusIF.ReceiveEnable;
	BusIF2UserModule.ReceivedAddress		<=	DataOutOfReceiveFIFO(31 downto 16);
	BusIF2UserModule.ReceivedData			<= DataOutOfReceiveFIFO(15 downto 0);
	BusIF2UserModule.ReceiveBufferEmpty	<= EmptyOfReceiveFIFO;
	BusIF2UserModule.ReceiveBufferFull	<= FullOfReceiveFIFO;
	
	--internal signals
	BusIF2UserModule.BusIFBusy <= BusIFBusy;

	--BusIF2UserModule.ReadAddress <= latched_ReadAddress;
	--BusIF2UserModule.beReadAddress <= latched_beReadAddress;
	--BusIF2UserModule.ReadDone <= '0' when UserModule2BusIF.ReadGo='1' else ReadDone_signal;
	--BusIF2UserModule.ReadDone <= ReadDone_signal;
	
	BusIF2BusController.Data <= BusIF2BusController_Data_beRead when BusIF_Target_State/=Idle else BusIF2BusController_Data_Send;
	--for simulation
	
	---------------------------------------------------
	--Dynamic Processes with Sensitivity List
	----------- ----------------------------------------
	MasterProcess : process (Clock,GlobalReset)
		variable a,b,c,d:Integer;
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			BusIF_Master_State <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			case BusIF_Master_State is
				when Initialize =>
					--initialize outputs to bus
					BusIF2BusController.Address <= x"0000";
					BusIF2BusController_Data_Send <= x"0000";
					BusIF2BusController.Request <= '0';
					BusIF2BusController.Send <= '0';
					BusIF2BusController.Read <= '0';
					BusIF2UserModule.ReadDone <= '0';
					--
					ReadEnableOfSendFIFO <= '0';
					
					--move to next state
					BusIF_Master_State <= Idle;
				when Idle =>
					--is Send set?
					if (EmptyOfSendFIFO='0') then
						ReadEnableOfSendFIFO <= '1';
						BusIF_Master_State <= LatchSendData_and_Request_0;
					--is there any request to Read data from another UserModule
					elsif (UserModule2BusIF.ReadGo='1') then
						--tell Read request to BusController
						BusIF2BusController.Request <= '1';
						BusIF2BusController.Read <= '1';
						BusIF2BusController.Address <= UserModule2BusIF.ReadAddress;
						--move to next state(bRead process)
						BusIF_Master_State <= WaitReadRequestGrant;
					end if;
				when LatchSendData_and_Request_0 =>
					ReadEnableOfSendFIFO <= '0';
					BusIF_Master_State <= LatchSendData_and_Request_1;
				when LatchSendData_and_Request_1 =>
					--set ON('1') the Request signal
					BusIF2BusController.Request <= '1';
					--set Send signal ON
					BusIF2BusController.Send <= '1';
					--tell Address/Data of Send command to BusController
					BusIF2BusController.Address <= DataOutOfSendFIFO(31 downto 16);
					BusIF2BusController_Data_Send	 <= DataOutOfSendFIFO(15 downto 0);
					--move to next state
					BusIF_Master_State <= WaitSendRequestGrant;
				when WaitSendRequestGrant =>
					--wait until write request is granted
					if (BusController2BusIF.RequestGrant='1') then
						--move to next state
						BusIF_Master_State <= WaitSendRequestDone;
					end if;
				when WaitReadRequestGrant =>
					--wait until read request is granted
					if (BusController2BusIF.RequestGrant='1') then
						--move to next state
						BusIF_Master_State <= WaitReadRequestDone;
					end if;
				when WaitSendRequestDone =>
					--is send request completed?
					if (BusController2BusIF.RequestGrant='0') then
						BusIF2BusController.Send <= '0';
						BusIF2BusController.Request <= '0';
						--move to next state
						BusIF_Master_State <= Idle;
					end if;
				when WaitReadRequestDone =>
					--is read request completed?
					if (BusController2BusIF.RequestGrant='0') then
						BusIF2BusController.Request <= '0';
						BusIF2BusController.Read <= '0';
						--latch the Read data from BusController
						BusIF2UserModule.ReadData <= BusController2BusIF.Data;
						--tell request completion to UserModule
						BusIF2UserModule.ReadDone <= '1';
						--move to next state
						BusIF_Master_State <= WaitReadGoOff;
					end if;
				when WaitReadGoOff =>
					if (UserModule2BusIF.ReadGo='0') then
						BusIF2UserModule.ReadDone <= '0';
						--move to next state
						BusIF_Master_State <= Idle;
					end if;
				when others =>
					BusIF_Master_State <= Initialize;
			end case;
		end if;
	end process;

	TargetProcess : process (Clock,GlobalReset)
		variable a,b,c,d:Integer;
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			BusIF_Target_State <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			case BusIF_Target_State is
				when Initialize =>
					--clear signal connected to Bus Controller
					BusIF2BusController.Respond <= '0';
					BusIF2UserModule.beRead <= '0';
					BusIF2UserModule.beReadAddress <= (others=>'0');
					WriteEnableOfReceiveFIFO <= '0';
					--move to next state
					BusIF_Target_State <= Idle;
				when Idle =>
					--is there any request from bus controller
					if ((BusController2BusIF.Send='1' or BusController2BusIF.Read='1')
							and BusBusy='1') then
						--move to next state
						BusIF_Target_State <= AccessFromBusController;
					end if;
				when AccessFromBusController =>
					a:=conv_integer(unsigned(BusController2BusIF.Address));
					address1 <= InitialAddress;
					address2 <= FinalAddress;
					if (conv_integer(InitialAddress)<=a and
							a<=conv_integer(FinalAddress)) then
						--if Send(Receive) command
						if (BusController2BusIF.Send='1' and FullOfReceiveFIFO='0') then
							WriteEnableOfReceiveFIFO <= '1';
							BusIF2BusController.Respond <= '1';
							--move to next state
							BusIF_Target_State <= WaitAccessFromBusControllerDone;
						--if Read command
						elsif (BusController2BusIF.Read='1') then
							--tell UserModule that there is read request from BusController
							BusIF2UserModule.beRead <= '1';
							BusIF2UserModule.beReadAddress <= BusController2BusIF.Address;
							--move to next state
							BusIF_Target_State <= WaitbeReadDoneFromUserModule;
						elsif (BusController2BusIF.Send='0' and BusController2BusIF.Read='0') then
							BusIF_Target_State <= Initialize;
						end if;
					else
						--the request from Bus Controller is not for me
						--nothing to do
						--move to next state
						BusIF_Target_State <= WaitAccessFromBusControllerDone;
					end if;
				when WaitbeReadDoneFromUserModule =>
					if (UserModule2BusIF.beReadDone='1') then
						--turn off beRead
						BusIF2UserModule.beRead <= '0';
						--tell BusController the end of Read process
						BusIF2BusController.Respond <= '1';
						--return the read out data
						BusIF2BusController_Data_beRead <= UserModule2BusIF.beReadData;
						--move to next state
						BusIF_Target_State <= WaitAccessFromBusControllerDone;
					end if;
				when WaitAccessFromBusControllerDone =>
					WriteEnableOfReceiveFIFO <= '0';
					if (BusController2BusIF.Send='0' and BusController2BusIF.Read='0') then
						--set Respond OFF
						BusIF2BusController.Respond <= '0';
						--move to next state
						BusIF_Target_State <= Idle;
					end if;				
				when others =>
					BusIF_Target_State <= Initialize;
			end case;
		end if;
	end process;
--
--	process (Clock,GlobalReset)
--		variable a,b,c,d:Integer;
--	begin
--		--is this process invoked with GlobalReset?
--		if (GlobalReset='0') then
--			BusIF_State <= Initialize;
--		--is this process invoked with Clock Event?
--		elsif (Clock'Event and Clock='1' and GlobalReset='1') then
--			case BusIF_State is
--				when Initialize =>
--					--initialize outputs to bus
--					BusIF2BusController.Address <= x"0000";
--					BusIF2BusController.Data <= x"0000";
--					BusIF2BusController.Request <= '0';
--					BusIF2BusController.Respond <= '0';
--					BusIF2BusController.Send <= '0';
--					BusIF2BusController.Read <= '0';
--					--initialize output to FIFO
--					ReadEnableOfSendFIFO <= '0';
--					WriteEnableOfReceiveFIFO <= '0';
--					--unset BusIFModuleBusy
--					BusIFBusy <= '0';
--					--move to next state
--					BusIF_State <= Idle;
--				when Idle =>
--					--does SendFIFO have any data to be sent to another UserModule(s)?
--					if (EmptyOfSendFIFO='0' and BusBusy='0') then
--						--set ON('1') the Request signal
--						BusIF2BusController.Request <= '1';
--						--to latch the data from SendFIFO
--						ReadEnableOfSendFIFO <= '1';
--						--move to next state
--						BusIF_State <= LatchDataFromSendFIFO;
--					--is there any request to Read data from another UserModule
--					elsif (UserModule2BusIF.ReadGo='1' and BusBusy='0') then
--						--clear ReadDone_signal and start new Read process
--						ReadDone_signal <= '0';
--						--tell Read request to BusController
--						BusIF2BusController.Request <= '1';
--						BusIF2BusController.Read <= '1';
--						BusIF2BusController.Address <= UserModule2BusIF.ReadAddress;
--						latched_ReadAddress <= UserModule2BusIF.ReadAddress;
--						--move to next state(bRead process)
--						BusIF_State <= WaitReadRequestGrant;
--					--is there any Send(Receive) access from BusController?
--					elsif (BusController2BusIF.Send='1' and BusBusy='1') then
--						--set ON BusIFBusy
--						BusIFBusy <= '1';
--						--move to next state(beRead process)
--						BusIF_State <= AccessFromBusController;
--					--is there any Read access(beRead) from BusController?
--					elsif (BusController2BusIF.Read='1' and BusBusy='1') then
--						--latch Address to be Read
--						latched_beReadAddress <= BusController2BusIF.Address;
--						--set ON BusIFBusy
--						BusIFBusy <= '1';
--						--move to next state(beRead process)
--						BusIF_State <= AccessFromBusController;
--					end if;
--				when LatchDataFromSendFIFO =>
--					--set off the ReadEnableOfSendFIFO
--					ReadEnableOfSendFIFO <= '0';
--					--move to next state
--					BusIF_State <= LatchDataFromSendFIFO_2;
--				when LatchDataFromSendFIFO_2 =>
--					--latch SentAddress/SentData
--					SentAddress <= DataOutOfSendFIFO(31 downto 16);
--					SentData <= DataOutOfSendFIFO(15 downto 0);
--					--move to next state
--					BusIF_State <= WaitSendRequestGrant;
--				when WaitSendRequestGrant =>
--					--tell Address/Data of Send command to BusController
--					BusIF2BusController.Address <= SentAddress;
--					BusIF2BusController.Data <= SentData;
--					--set Request signal ON then wait request  grant
--					if (BusController2BusIF.RequestGrant='1') then
--						--if the request is granted by BusController
--						--set Send signal ON
--						BusIF2BusController.Send <= '1';
--						--move to next state
--						BusIF_State <= WaitSendRequestDone;
--					elsif (BusController2BusIF.RequestGrant='0' and BusBusy='1') then
--						--the request was not granted and another bus process began
--						--set SendRequestSuspendFlag and move to beRead process
--						SendRequestSuspendFlag <= '1';
--						--set off Request signal
--						BusIF2BusController.Request <= '0';
--						--jump to branching state
--						BusIF_State <= AccessFromBusController;
--					end if;
--				when WaitReadRequestGrant =>
--					--wait request  grant
--					if (BusController2BusIF.RequestGrant='1') then
--						--move to next state
--						BusIF_State <= WaitReadRequestDone;
--					elsif (BusController2BusIF.RequestGrant='0' and BusBusy='1') then
--						--the request was not granted and another bus process began
--						--set ReadRequestSuspendFlag and move to beRead process
--						ReadRequestSuspendFlag <= '1';
--						--set off Request signal
--						BusIF2BusController.Request <= '0';
--						--set off Read command signal
--						BusIF2BusController.Read <= '0';
--						--jump to branching state
--						BusIF_State <= AccessFromBusController;
--					end if;
--				when AccessFromBusController =>
--					if (BusController2BusIF.Send='1' or BusController2BusIF.Read='1') then
--						a:=conv_integer(unsigned(BusController2BusIF.Address));
--						if (conv_integer(InitialAddress)<=a and
--								a<=conv_integer(FinalAddress)) then
--							--if Send(Receive) command
--							if (BusController2BusIF.Send='1' and FullOfReceiveFIFO='0') then
--								--Write Data To ReceiveFIFO
--								WriteEnableOfReceiveFIFO <= '1';
--								--reply Respond to BusController
--								BusIF2BusController.Respond <= '1';
--								--move to next state
--								BusIF_State <= WaitAccessFromBusControllerDone;
--							--if Read command
--							elsif (BusController2BusIF.Read='1') then
--								--latch Address to be Read
--								latched_ReadAddress <= BusController2BusIF.Address;
--								latched_beReadAddress <= BusController2BusIF.Address;
--								--tell UserModule that there is read request from BusController
--								BusIF2UserModule.beRead <= '1';
--								--move to next state
--								BusIF_State <= WaitbeReadDoneFromUserModule;
--							else
--								BusIF_State <= Initialize;
--							end if;
--						else
--							addressin <= BusController2BusIF.Address;
--							address1<=InitialAddress;
--							address2<=FinalAddress;
--							address3<=conv_integer(InitialAddress);
--							address4<=conv_integer(FinalAddress);
--							addressinteger<=a;--conv_integer(unsigned(BusController2BusIF.Address));
--							--move to next state
--							BusIF_State <= WaitAccessFromBusControllerDone;
--						end if;
--					end if;
--				when WaitbeReadDoneFromUserModule =>
--					if (UserModule2BusIF.beReadDone='1') then
--						--turn off beRead
--						BusIF2UserModule.beRead <= '0';
--						--tell BusController the end of Read process
--						BusIF2BusController.Respond <= '1';
--						--return the read out data
--						BusIF2BusController.Data <= UserModule2BusIF.beReadData;
--						--move to next state
--						BusIF_State <= WaitAccessFromBusControllerDone;						
--					end if;
--				when WaitSendRequestDone =>
--					if (BusController2BusIF.RequestGrant='0') then
--						--initialize outputs to bus
--						BusIF2BusController.Address <= x"0000";
--						BusIF2BusController.Data <= x"0000";
--						BusIF2BusController.Request <= '0';
--						BusIF2BusController.Respond <= '0';
--						BusIF2BusController.Send <= '0';
--						BusIF2BusController.Read <= '0';
--						--initialize output to FIFO
--						ReadEnableOfSendFIFO <= '0';
--						WriteEnableOfReceiveFIFO <= '0';
--						--unset BusIFModuleBusy
--						BusIFBusy <= '0';
--						--move to next state
--						BusIF_State <= Idle;
--					end if;
--				when WaitReadRequestDone =>
--					if (BusController2BusIF.RequestGrant='0') then
--						--latch the Read data from BusController
--						BusIF2UserModule.ReadData <= BusController2BusIF.Data;
--						--set ReadDone_signal
--						ReadDone_signal <= '1';
--						--initialize outputs to bus
--						BusIF2BusController.Address <= x"0000";
--						BusIF2BusController.Data <= x"0000";
--						BusIF2BusController.Request <= '0';
--						BusIF2BusController.Respond <= '0';
--						BusIF2BusController.Send <= '0';
--						BusIF2BusController.Read <= '0';
--						--initialize output to FIFO
--						ReadEnableOfSendFIFO <= '0';
--						WriteEnableOfReceiveFIFO <= '0';
--						--unset BusIFModuleBusy
--						BusIFBusy <= '0';
--						--move to next state
--						BusIF_State <= Idle;
--					end if;
--				when WaitAccessFromBusControllerDone =>
--					--set off WriteEnableOfReceiveFIFO
--					WriteEnableOfReceiveFIFO <= '0';
--						-- <======
--						--    this operation has no future if this process is beRead one,
--						--    otherwise when it is in Receive process, it has a point.
--					if (BusController2BusIF.BusBusy='0') then
--						--set Respond OFF
--						BusIF2BusController.Respond <= '0';
--						if (SendRequestSuspendFlag='1') then
--							--set OFF BusIFBusy
--							BusIFBusy <= '0';
--							--there is suspended Request so resume request
--							BusIF2BusController.Request <= '1';
--							BusIF2BusController.Address <= SentAddress;
--							BusIF2BusController.Data <= SentData;
--							--set off SendRequestSuspendFlag
--							SendRequestSuspendFlag <= '0';
--							--return to Send Request state
--							BusIF_State <= WaitSendRequestGrant;
--						elsif (ReadRequestSuspendFlag='1') then
--							--set OFF BusIFBusy
--							BusIFBusy <= '0';
--							--if there is suspended Request
--							--resume request
--							BusIF2BusController.Request <= '1';
--							BusIF2BusController.Read <= '1';
--							--set off ReadRequestSuspendFlag
--							ReadRequestSuspendFlag <= '0';
--							--return to Send Request state
--							BusIF_State <= WaitReadRequestGrant;
--						else
--							--if there is no suspended Request
--							--initialize outputs to bus
--							BusIF2BusController.Address <= x"0000";
--							BusIF2BusController.Data <= x"0000";
--							BusIF2BusController.Request <= '0';
--							BusIF2BusController.Respond <= '0';
--							BusIF2BusController.Send <= '0';
--							BusIF2BusController.Read <= '0';
--							--initialize output to FIFO
--							ReadEnableOfSendFIFO <= '0';
--							WriteEnableOfReceiveFIFO <= '0';
--							--unset BusIFModuleBusy
--							BusIFBusy <= '0';
--							--move to next state
--							BusIF_State <= Idle;
--						end if;
--					end if;
--				when others =>
--					BusIF_State <= Initialize;
--			end case;
--		end if;
--	end process;

end Behavioral;