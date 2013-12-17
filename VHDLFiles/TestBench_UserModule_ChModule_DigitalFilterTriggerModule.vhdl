library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
USE ieee.numeric_std.ALL;

ENTITY TestBench_UserModule_ChModule_DigitalFilterTriggerModule IS
END TestBench_UserModule_ChModule_DigitalFilterTriggerModule;
 
ARCHITECTURE behavior OF TestBench_UserModule_ChModule_DigitalFilterTriggerModule IS 

component UserModule_Utility_ToIntegerFromSignedVector is
	generic(
		Width : integer := 8
	);
	port(
		Input : in std_logic_vector(Width-1 downto 0);
		Output : out integer range -2**(Width-1) to 2**(Width-1)-1
	);
end component;
component UserModule_Utility_ToIntegerFromUnsignedVector is
	generic(
		Width : integer := 8
	);
	port(
		Input : in std_logic_vector(Width-1 downto 0);
		Output : out integer  range 0 to 2**(Width)-1
	);
end component;
	signal Depth : integer range 0 to 25 := 21;

 	type Signal_std_logic_vector8 is array (INTEGER range <>) of std_logic_vector(7 downto 0); 
 	type Signal_std_logic_vector16 is array (INTEGER range <>) of std_logic_vector(15 downto 0); 
 	constant WaveformDepth : integer := 200;
	type Type_AdcDataVector is array (INTEGER range <>) of integer range 0 to 4095;
	signal Waveform : Type_AdcDataVector(WaveformDepth-1 downto 0);
	signal index : integer range 0 to WaveformDepth := 0;
	
	signal Output_AsSigned : integer range -2048 to 2047;
	signal Output_AsUnsigned : integer range 0 to 4095;

   --Inputs
   signal AdcClock : std_logic := '0';
   signal AdcData : integer range 0 to 4095 := 0;
   signal CoefficientArray : Signal_std_logic_vector16(20 downto 0);
   signal Threshold : integer;
   signal Width : integer range 0 to 4095;
   signal Clock : std_logic := '0';
   signal GlobalReset : std_logic := '0';
	signal Reentrant : std_logic := '0';
	
 	--Outputs
   signal TriggerOut : std_logic;
   signal FilteredAdcData : integer;

   -- Clock period definitions
   constant Clock_period : time := 20 ns;
   constant AdcClock_period : time := 500 ns;
	constant MaxOfAdcClock_Counter : integer := 24;
	signal adcclock_counter : integer range 0 to MaxOfAdcClock_Counter := 0;

 	signal AdcClock_previous : std_logic := '0';
	
	type states is (
		Initialize, Idle, CalculateFilteredValue
	);
	signal state : states := Initialize;
	signal state_count : integer range 0 to 31 := 0;
	signal depth_count : integer range 0 to Depth := 0;
	signal blstate_count : integer range 0 to 31 := 0;
	
	constant MaxDepth : integer := 25;
	signal AdcDataVector : Type_AdcDataVector(MaxDepth-1 downto 0);
	
	signal WaitCounter : integer range 0 to 4095 :=0;
	
	signal Triggered : std_logic := '0';

	signal Total : integer := 0;
	
	signal TriggerOutFromWaitCounter : std_logic := '0';
	
	signal InitialWaitDone : std_logic := '0';
 
BEGIN


	--input waveform
Waveform(0) <= 126;
Waveform(1) <= 126;
Waveform(2) <= 127;
Waveform(3) <= 127;
Waveform(4) <= 127;
Waveform(5) <= 128;
Waveform(6) <= 127;
Waveform(7) <= 127;
Waveform(8) <= 127;
Waveform(9) <= 127;
Waveform(10) <= 127;
Waveform(11) <= 127;
Waveform(12) <= 127;
Waveform(13) <= 127;
Waveform(14) <= 127;
Waveform(15) <= 126;
Waveform(16) <= 126;
Waveform(17) <= 127;
Waveform(18) <= 127;
Waveform(19) <= 127;
Waveform(20) <= 127;
Waveform(21) <= 126;
Waveform(22) <= 126;
Waveform(23) <= 126;
Waveform(24) <= 127;
Waveform(25) <= 127;
Waveform(26) <= 127;
Waveform(27) <= 127;
Waveform(28) <= 127;
Waveform(29) <= 128;
Waveform(30) <= 137;
Waveform(31) <= 143;
Waveform(32) <= 147;
Waveform(33) <= 149;
Waveform(34) <= 150;
Waveform(35) <= 150;
Waveform(36) <= 150;
Waveform(37) <= 151;
Waveform(38) <= 151;
Waveform(39) <= 151;
Waveform(40) <= 151;
Waveform(41) <= 151;
Waveform(42) <= 150;
Waveform(43) <= 151;
Waveform(44) <= 150;
Waveform(45) <= 150;
Waveform(46) <= 150;
Waveform(47) <= 150;
Waveform(48) <= 150;
Waveform(49) <= 149;
Waveform(50) <= 149;
Waveform(51) <= 147;
Waveform(52) <= 148;
Waveform(53) <= 148;
Waveform(54) <= 148;
Waveform(55) <= 147;
Waveform(56) <= 147;
Waveform(57) <= 147;
Waveform(58) <= 147;
Waveform(59) <= 146;
Waveform(60) <= 145;
Waveform(61) <= 145;
Waveform(62) <= 146;
Waveform(63) <= 146;
Waveform(64) <= 146;
Waveform(65) <= 145;
Waveform(66) <= 145;
Waveform(67) <= 144;
Waveform(68) <= 144;
Waveform(69) <= 145;
Waveform(70) <= 144;
Waveform(71) <= 144;
Waveform(72) <= 143;
Waveform(73) <= 143;
Waveform(74) <= 143;
Waveform(75) <= 143;
Waveform(76) <= 142;
Waveform(77) <= 142;
Waveform(78) <= 143;
Waveform(79) <= 142;
Waveform(80) <= 142;
Waveform(81) <= 141;
Waveform(82) <= 141;
Waveform(83) <= 141;
Waveform(84) <= 141;
Waveform(85) <= 140;
Waveform(86) <= 140;
Waveform(87) <= 140;
Waveform(88) <= 140;
Waveform(89) <= 140;
Waveform(90) <= 140;
Waveform(91) <= 140;
Waveform(92) <= 140;
Waveform(93) <= 140;
Waveform(94) <= 141;
Waveform(95) <= 139;
Waveform(96) <= 139;
Waveform(97) <= 139;
Waveform(98) <= 139;
Waveform(99) <= 139;
Waveform(100) <= 139;
Waveform(101) <= 139;
Waveform(102) <= 139;
Waveform(103) <= 140;
Waveform(104) <= 139;
Waveform(105) <= 138;
Waveform(106) <= 138;
Waveform(107) <= 138;
Waveform(108) <= 138;
Waveform(109) <= 138;
Waveform(110) <= 138;
Waveform(111) <= 137;
Waveform(112) <= 138;
Waveform(113) <= 137;
Waveform(114) <= 137;
Waveform(115) <= 137;
Waveform(116) <= 137;
Waveform(117) <= 137;
Waveform(118) <= 136;
Waveform(119) <= 137;
Waveform(120) <= 136;
Waveform(121) <= 136;
Waveform(122) <= 136;
Waveform(123) <= 136;
Waveform(124) <= 137;
Waveform(125) <= 137;
Waveform(126) <= 136;
Waveform(127) <= 136;
Waveform(128) <= 135;
Waveform(129) <= 136;
Waveform(130) <= 135;
Waveform(131) <= 136;
Waveform(132) <= 135;
Waveform(133) <= 135;
Waveform(134) <= 136;
Waveform(135) <= 135;
Waveform(136) <= 135;
Waveform(137) <= 135;
Waveform(138) <= 135;
Waveform(139) <= 135;
Waveform(140) <= 134;
Waveform(141) <= 134;
Waveform(142) <= 134;
Waveform(143) <= 134;
Waveform(144) <= 134;
Waveform(145) <= 135;
Waveform(146) <= 135;
Waveform(147) <= 134;
Waveform(148) <= 134;
Waveform(149) <= 134;
Waveform(150) <= 134;
Waveform(151) <= 135;
Waveform(152) <= 134;
Waveform(153) <= 133;
Waveform(154) <= 134;
Waveform(155) <= 133;
Waveform(156) <= 133;
Waveform(157) <= 133;
Waveform(158) <= 133;
Waveform(159) <= 133;
Waveform(160) <= 133;
Waveform(161) <= 133;
Waveform(162) <= 133;
Waveform(163) <= 133;
Waveform(164) <= 133;
Waveform(165) <= 132;
Waveform(166) <= 133;
Waveform(167) <= 133;
Waveform(168) <= 132;
Waveform(169) <= 132;
Waveform(170) <= 132;
Waveform(171) <= 132;
Waveform(172) <= 132;
Waveform(173) <= 131;
Waveform(174) <= 131;
Waveform(175) <= 132;
Waveform(176) <= 131;
Waveform(177) <= 132;
Waveform(178) <= 132;
Waveform(179) <= 133;
Waveform(180) <= 132;
Waveform(181) <= 132;
Waveform(182) <= 131;
Waveform(183) <= 131;
Waveform(184) <= 131;
Waveform(185) <= 131;
Waveform(186) <= 132;
Waveform(187) <= 132;
Waveform(188) <= 132;
Waveform(189) <= 132;
Waveform(190) <= 131;
Waveform(191) <= 132;
Waveform(192) <= 131;
Waveform(193) <= 131;
Waveform(194) <= 132;
Waveform(195) <= 131;
Waveform(196) <= 131;
Waveform(197) <= 131;
Waveform(198) <= 130;
Waveform(199) <= 130;

	--FIR coefficients
--CoefficientArray(0) <= conv_std_logic_vector(-1,16);
--CoefficientArray(1) <= conv_std_logic_vector(-10,16);
--CoefficientArray(2) <= conv_std_logic_vector(-53,16);
--CoefficientArray(3) <= conv_std_logic_vector(-208,16);
--CoefficientArray(4) <= conv_std_logic_vector(-655,16);
--CoefficientArray(5) <= conv_std_logic_vector(-1641,16);
--CoefficientArray(6) <= conv_std_logic_vector(-3230,16);
--CoefficientArray(7) <= conv_std_logic_vector(-4878,16);
--CoefficientArray(8) <= conv_std_logic_vector(-5362,16);
--CoefficientArray(9) <= conv_std_logic_vector(-3619,16);
--CoefficientArray(10) <= conv_std_logic_vector(0,16);
--CoefficientArray(11) <= conv_std_logic_vector(3619,16);
--CoefficientArray(12) <= conv_std_logic_vector(5362,16);
--CoefficientArray(13) <= conv_std_logic_vector(4878,16);
--CoefficientArray(14) <= conv_std_logic_vector(3230,16);
--CoefficientArray(15) <= conv_std_logic_vector(1641,16);
--CoefficientArray(16) <= conv_std_logic_vector(655,16);
--CoefficientArray(17) <= conv_std_logic_vector(208,16);
--CoefficientArray(18) <= conv_std_logic_vector(53,16);
--CoefficientArray(19) <= conv_std_logic_vector(10,16);
--CoefficientArray(20) <= conv_std_logic_vector(1,16);

	CoefficientArray(0) <= conv_std_logic_vector(-1,16);
	CoefficientArray(1) <= conv_std_logic_vector(-1,16);
	CoefficientArray(2) <= conv_std_logic_vector(-1,16);
	CoefficientArray(3) <= conv_std_logic_vector(-1,16);
	CoefficientArray(4) <= conv_std_logic_vector(1,16);
	CoefficientArray(5) <= conv_std_logic_vector(1,16);
	CoefficientArray(6) <= conv_std_logic_vector(1,16);
	CoefficientArray(7) <= conv_std_logic_vector(1,16);

------------------------		
	GlobalReset <= '1';
 
   Clock_process :process
   begin
		Clock <= '0';
		wait for Clock_period/2;
		Clock <= '1';
		wait for Clock_period/2;
   end process; 

   AdcClock_process :process
   begin
		AdcClock <= '0';
		wait for AdcClock_period/2;
		AdcClock <= '1';
		wait for AdcClock_period/2;
   end process; 

	--for dg21 filter
--	Threshold <= 30000;
--	Width <= 40000/20;
--	Reentrant <= '1';
--	Depth <= 21;

	--for fv4 filter
	Threshold <= 5;
	Width <= 40000/20;
	Reentrant <= '1';
	Depth <= 8;
	
   -- Stimulus process
   stim_proc: process(clock)
   begin		
		if(clock'event and clock='1')then
			AdcClock_previous <= AdcClock;
			if(AdcClock_previous='0' and AdcClock='1')then
				if(index=WaveformDepth)then
					--end
				else
					AdcData <= Waveform(index);
					index <= index + 1;
				end if;
			end if;
		end if;
   end process;

-----------------------

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
						Total <= Total + conv_integer(conv_std_logic_vector(AdcDataVector(Depth-1-depth_count),16)*conv_std_logic_vector(conv_integer(CoefficientArray(depth_count)),16));
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
			
			if(InitialWaitDone='0')then
				InitialWaitDone <= '1';
				AdcDataVector(0) <= Waveform(0);
				AdcDataVector(1) <= Waveform(0);
				AdcDataVector(2) <= Waveform(0);
				AdcDataVector(3) <= Waveform(0);
				AdcDataVector(4) <= Waveform(0);
				AdcDataVector(5) <= Waveform(0);
				AdcDataVector(6) <= Waveform(0);
				AdcDataVector(7) <= Waveform(0);
				AdcDataVector(8) <= Waveform(0);
				AdcDataVector(9) <= Waveform(0);
				AdcDataVector(10) <= Waveform(0);
				AdcDataVector(11) <= Waveform(0);
				AdcDataVector(12) <= Waveform(0);
				AdcDataVector(13) <= Waveform(0);
				AdcDataVector(14) <= Waveform(0);
				AdcDataVector(15) <= Waveform(0);
				AdcDataVector(16) <= Waveform(0);
				AdcDataVector(17) <= Waveform(0);
				AdcDataVector(18) <= Waveform(0);
				AdcDataVector(19) <= Waveform(0);
				AdcDataVector(20) <= Waveform(0);
				AdcDataVector(21) <= Waveform(0);
				AdcDataVector(22) <= Waveform(0);
				AdcDataVector(23) <= Waveform(0);
				AdcDataVector(24) <= Waveform(0);
			elsif(AdcClock_previous='1' and AdcClock='0')then
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
	
END;
