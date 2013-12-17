---------------------------------------------------
--Declarations of Libraries
---------------------------------------------------
library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use work.iBus_Library.all;
use work.iBus_AddressMap.all;
use work.UserModule_Library.all;

entity UserModule_ChModule_DigitalFilterTriggerModule is
	generic(
		Depth : integer range 0 to 25
	);
	port(
		--Input
		AdcClock		:	in		std_logic;
		AdcData		:	in integer range 0 to 4095;
		--Parameters
		CoefficientArray : in ArrayOf_Signed8bitInteger(Depth-1 downto 0); --singed 8bits
		Threshold	:	in		integer range 0 to 4095;
		Width	:	in	integer range 0 to 4095;
		Reentrant : in std_logic;
		--Output
		TriggerOut	:	out	std_logic;
		FilteredAdcData : out integer;
		--clock and reset
		Clock			:	in		std_logic;
		GlobalReset	:	in		std_logic
	);
end UserModule_ChModule_DigitalFilterTriggerModule;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_ChModule_DigitalFilterTriggerModule is
	---------------------------------------------------
	--Declarations of Components
	---------------------------------------------------
	
	signal AdcClock_previous : std_logic := '0';
	
	type states is (
		Initialize, Idle, CalculateFilteredValue
	);
	signal state : states := Initialize;
	signal state_count : integer range 0 to 31 := 0;
	signal depth_count : integer range 0 to Depth := 0;
	signal blstate_count : integer range 0 to 31 := 0;
	
	constant MaxDepth : integer := 25;
	type Type_AdcDataVector is array (INTEGER range <>) of integer range 0 to 4095;
	signal AdcDataVector : Type_AdcDataVector(MaxDepth-1 downto 0);
	
	signal WaitCounter : integer range 0 to 4095 :=0;
	
	signal Triggered : std_logic := '0';

	signal Total : integer := 0;
	
	signal TriggerOutFromWaitCounter : std_logic := '0';

begin
	TriggerOut <= Triggered or TriggerOutFromWaitCounter;
	
	process (Clock, GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			WaitCounter <= 0;
			Triggered <= '0';
			TriggerOutFromWaitCounter <= '0';
			state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			AdcClock_previous <= AdcClock;
			case state is
				when Initialize =>
					state <= Idle;
				when Idle =>
					Triggered <= '0';
					if(AdcClock_previous='0' and AdcClock='1')then
						state_count <= 0;
						depth_count <= 0;
						FilteredAdcData <= Total;
						Total <= 0;
						state <= CalculateFilteredValue;
					end if;
				when CalculateFilteredValue =>
					if(depth_count=Depth)then
						if(Threshold<Total)then
							Triggered <= '1';
						end if;
						state <= Idle;
					else
						Total <= Total + conv_integer(conv_std_logic_vector(AdcDataVector(Depth-1-depth_count),16)*conv_std_logic_vector(conv_integer(CoefficientArray(depth_count)),8));
						depth_count <= depth_count + 1;
					end if;
			end case;
			
			--Trigger width control
			if(Triggered='1')then
				if(Reentrant='1' or WaitCounter=0)then
					TriggerOutFromWaitCounter <= '1';
					WaitCounter <= Width;
				end if;
			elsif(WaitCounter/=0)then
				WaitCounter <= WaitCounter - 1;
			else
				TriggerOutFromWaitCounter <= '0';
			end if;
			
			if(AdcClock_previous='1' and AdcClock='0')then
				--shift AdcDataVector
				AdcDataVector(24) <= AdcDataVector(23);
				AdcDataVector(23) <= AdcDataVector(22);
				AdcDataVector(22) <= AdcDataVector(21);
				AdcDataVector(21) <= AdcDataVector(20);
				AdcDataVector(20) <= AdcDataVector(19);
				AdcDataVector(19) <= AdcDataVector(18);
				AdcDataVector(18) <= AdcDataVector(17);
				AdcDataVector(17) <= AdcDataVector(16);
				AdcDataVector(16) <= AdcDataVector(15);
				AdcDataVector(15) <= AdcDataVector(14);
				AdcDataVector(14) <= AdcDataVector(13);
				AdcDataVector(13) <= AdcDataVector(12);
				AdcDataVector(12) <= AdcDataVector(11);
				AdcDataVector(11) <= AdcDataVector(10);
				AdcDataVector(10) <= AdcDataVector(9);
				AdcDataVector(9) <= AdcDataVector(8);
				AdcDataVector(8) <= AdcDataVector(7);
				AdcDataVector(7) <= AdcDataVector(6);
				AdcDataVector(6) <= AdcDataVector(5);
				AdcDataVector(5) <= AdcDataVector(4);
				AdcDataVector(4) <= AdcDataVector(3);
				AdcDataVector(3) <= AdcDataVector(2);
				AdcDataVector(2) <= AdcDataVector(1);
				AdcDataVector(1) <= AdcDataVector(0);
				AdcDataVector(0) <= AdcData;
				--AdcDataVector(0) <= conv_integer((not AdcData) + 1); --2's complement
			end if;
		end if;
	end process;
	
	
end Behavioral;

