---------------------------------------------------
--Declarations of Libraries
---------------------------------------------------
library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.iBus_Library.all;
use work.iBus_AddressMap.all;
use work.UserModule_Library.all;

entity UserModule_ChModule_FastVetoModule is
	port(
		--
		AdcClock		:	in		std_logic;
		AdcData		:	in		std_logic_vector(ADCResolutionForFastVeto-1 downto 0);
		TriggerOut	:	out	std_logic;
		--parameters
		ThresholdDelta	:	in		std_logic_vector(15 downto 0); --in terms of ch
		WaitDurationAfterTriggeringInUnitsOfClock	:	in	std_logic_vector(15 downto 0);
		--clock and reset
		Clock			:	in		std_logic;
		GlobalReset	:	in		std_logic
	);
end UserModule_ChModule_FastVetoModule;

---------------------------------------------------
--Behavioral description
---------------------------------------------------
architecture Behavioral of UserModule_ChModule_FastVetoModule is
	---------------------------------------------------
	--Declarations of Components
	---------------------------------------------------
	
	signal AdcClock_previous : std_logic := '0';
	
	type states is (
		Initialize, Idle, JudgeIfTriggers, TriggeredState
	);
	signal state : states := Initialize;
	signal state_count : integer range 0 to 31 := 0;
	signal blstate_count : integer range 0 to 31 := 0;
	
	type Type_AdcDataVector is array (INTEGER range <>) of std_logic_vector(ADCResolutionForFastVeto-1 downto 0);
	signal AdcDataVector : Type_AdcDataVector(7 downto 0);
	constant WidthOfBaseline : integer := 16;
	constant WidthOfJump : integer := 16;
	signal Jump : integer range 0 to 65535 := 0;--std_logic_vector(WidthOfJump-1 downto 0) := (others => '0');
	signal Delta : integer range 0 to 65535 := 0;--std_logic_vector(WidthOfJump-1 downto 0) := (others => '0');
	signal Delta_vector : std_logic_vector(WidthOfJump-1 downto 0) := (others => '0');
	signal Baseline : integer range 0 to 65535 := 0;--std_logic_vector(WidthOfBaseline-1 downto 0) := (others => '0');
	constant ZeroPaddingForAdcDataAndBaseline : std_logic_vector(WidthOfBaseline-1 downto ADCResolutionForFastVeto) := (others => '0');
	constant ZeroPaddingForAdcDataAndJump : std_logic_vector(WidthOfJump-1 downto ADCResolutionForFastVeto) := (others => '0');
	
	signal WaitCounter : std_logic_vector(15 downto 0) := (others => '0');
	
	signal Triggered : std_logic := '0';

begin
	TriggerOut <= Triggered;
	
	Delta_vector <= conv_std_logic_vector(Delta,16);
	
	process (Clock, GlobalReset)
	begin
		--is this process invoked with GlobalReset?
		if (GlobalReset='0') then
			state <= Initialize;
		--is this process invoked with Clock Event?
		elsif (Clock'Event and Clock='1') then
			AdcClock_previous <= AdcClock;
			case state is
				when Initialize =>
					state <= Idle;
				when Idle =>
					Triggered <= '0';
					WaitCounter <= (others => '0');
					if(AdcClock_previous='0' and AdcClock='1')then
						state_count <= 0;
						state <= JudgeIfTriggers;
					end if;
				when JudgeIfTriggers =>
					if(state_count=0)then
						--wait for AdcDataVector shifted
						state_count <= 1;
						Baseline <= 0;--(others => '0');
						Jump <= 0;--(others => '0');
					elsif(state_count=1)then
						--calculate baseline and jump (step0)
						Baseline <= conv_integer(AdcDataVector(7)) + conv_integer(AdcDataVector(6));
						Jump <= conv_integer(AdcDataVector(1)) + conv_integer(AdcDataVector(0));
						state_count <= 2;
					elsif(state_count=2)then
						--calculate baseline and jump (step1)
						Baseline <= Baseline + conv_integer(AdcDataVector(5)) + conv_integer(AdcDataVector(4));
						Jump <= Jump + conv_integer(AdcDataVector(3)) + conv_integer(AdcDataVector(2));
						state_count <= 3;
					elsif(state_count=3)then
						if(Baseline<Jump)then
							Delta <= Jump - Baseline;
							state_count <= 4;
						else
							state <= Idle;
						end if;
					elsif(state_count=4)then
						Delta <= conv_integer("00" & Delta_vector(15 downto 2));
						state_count <= 5;
					elsif(state_count=5)then
						if(conv_integer(ThresholdDelta)<=conv_integer(Delta))then
							Triggered <= '1';
							state <= TriggeredState;
						else
							state <= Idle;
						end if;
					end if;
				when TriggeredState =>
					if(WaitCounter=WaitDurationAfterTriggeringInUnitsOfClock)then
						WaitCounter <= (others => '0');
						Triggered <= '0';
						state_count <= 0;
						state <= Idle;
					else
						WaitCounter <= WaitCounter + 1;
					end if;
			end case;
			
			if(AdcClock_previous='1' and AdcClock='0')then
				--shift AdcDataVector
				AdcDataVector(7) <= AdcDataVector(6);
				AdcDataVector(6) <= AdcDataVector(5);
				AdcDataVector(5) <= AdcDataVector(4);
				AdcDataVector(4) <= AdcDataVector(3);
				AdcDataVector(3) <= AdcDataVector(2);
				AdcDataVector(2) <= AdcDataVector(1);
				AdcDataVector(1) <= AdcDataVector(0);
				AdcDataVector(0) <= AdcData;
			end if;
		end if;
	end process;
	
	
end Behavioral;

