--UserFPGA_Top.vhdl
--
--SpaceWire Board / User FPGA / Modularized Structure Template
--
--ver20071202 Takayuki Yuasa
--for SpW ADC Box UserFPGA
--ver20071101 Takayuki Yuasa
--copied from UserFPGA_XilinxFADC_20071015_2200
--ver20071021 Takayuki Yuasa
--SpaceWire ADC Box

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
entity user_top is
		port ( grst, uclk : in std_logic; 
		-- Ext bus
			ebus_adr		: inout std_logic_vector(24 downto 0);
			ebus_d		: inout std_logic_vector(15 downto 0);
			ebus_ena		: in std_logic;								
			ebus_wr		: inout std_logic;								
			ebus_rd		: inout std_logic;								
			ebus_req		: out std_logic;								
			ebus_grant	: in std_logic;								
			ebus_done	: inout std_logic;
		-- Analog Interface
			ch0_clk		: out std_logic;
			ch0_pdwn		: out std_logic;
			ch0_otr		: in std_logic;
			ch0_d			: in std_logic_vector(11 downto 0);
			ch1_clk		: out std_logic;
			ch1_pdwn		: out std_logic;
			ch1_otr		: in std_logic;
			ch1_d			: in std_logic_vector(11 downto 0);
			ch2_clk		: out std_logic;
			ch2_pdwn		: out std_logic;
			ch2_otr		: in std_logic;
			ch2_d			: in std_logic_vector(11 downto 0);
			ch3_clk		: out std_logic;
			ch3_pdwn		: out std_logic;
			ch3_otr		: in std_logic;
			ch3_d			: in std_logic_vector(11 downto 0);
			ch4_clk		: out std_logic;
			ch4_pdwn		: out std_logic;
			ch4_otr		: in std_logic;
			ch4_d			: in std_logic_vector(11 downto 0);
			ch5_clk		: out std_logic;
			ch5_pdwn		: out std_logic;
			ch5_otr		: in std_logic;
			ch5_d			: in std_logic_vector(11 downto 0);
			ch6_clk		: out std_logic;
			ch6_pdwn		: out std_logic;
			ch6_otr		: in std_logic;
			ch6_d			: in std_logic_vector(11 downto 0);
			ch7_clk		: out std_logic;
			ch7_pdwn		: out std_logic;
			ch7_otr		: in std_logic;
			ch7_d			: in std_logic_vector(11 downto 0);
		-- SDRAM Interface
			o_sdclk		: out std_logic;		
			o_cke			: out std_logic;
			o_xdcs		: out std_logic;
			o_xdras		: out std_logic;
			o_xdcas		: out std_logic;
			o_xdwe		: out std_logic;
			o_ldqm		: out std_logic;
			o_udqm		: out std_logic;
			o_sda			: out std_logic_vector (12 downto 0);
			o_ba			: out std_logic_vector (1 downto 0);
			sdd			: inout std_logic_vector (15 downto 0);
		-- Aux 
			ebus_aux0 	: in std_logic; 
			ebus_aux1 	: in std_logic; 
			ebus_aux2	: in std_logic; 
			ebus_aux3 	: in std_logic; 
			ebus_aux4 	: in std_logic; 
			ebus_aux5 	: in std_logic; 
			ebus_aux6 	: in std_logic; 
			ebus_aux7 	: in std_logic; 		
		-- LED,DSW,DIO,&etc
			clkback 		: in std_logic; 
			gatein 		: in std_logic; 
			uled 			: out std_logic_vector (3 downto 0);
			usw 			: in std_logic_vector (3 downto 0); 
			dio 			: inout std_logic_vector (8 downto 0);
			test 			: out std_logic_vector (5 downto 0)
		);
end user_top;

---------------------------------------------------
--Structural description
---------------------------------------------------
architecture Structural of user_top is

	---------------------------------------------------
	--Declarations of Components
	---------------------------------------------------
	component UserFPGA
		port (
			ClockIn		:	in		std_logic;
			ClockOut		:	out	std_logic;
			ClockBack	:	in		std_logic;
			Clock100MHz	:	in		std_logic;
			AdcClockOut	:	out	std_logic;
			LockedIn		:	in		std_logic;
			GlobalReset	:	in		std_logic;
			
			GateIn_In	:	in		std_logic;
			DIO_Out		:	out	std_logic_vector(7 downto 0);
			DIO_In		:	in		std_logic_vector(3 downto 0);
			
			UserFPGA2Adc_vector	: out	Signal_UserFPGA2Adc_Vector(7 downto 0);
			Adc2UserFPGA_vector	: in	Signal_Adc2UserFPGA_Vector(7 downto 0);
			
			LEDs			:	out	std_logic_vector (3 downto 0); 
			Switches		:	in		std_logic_vector (3 downto 0);
			
			eBus_Enable		: in std_logic; 
			eBus_Done		: out std_logic;
			eBus_Address	: in std_logic_vector (24 downto 0);
			eBus_DataIn		: in std_logic_vector (15 downto 0); 
			eBus_DataOut	: out std_logic_vector (15 downto 0); 
			eBus_Write		: in std_logic; 
			eBus_Read		: in std_logic;
			meBus_Request	: out std_logic;
			meBus_Grant		: in std_logic;
			meBus_Enable	: in std_logic;
			meBus_Done		: in std_logic;
			meBus_Address	: out std_logic_vector(24 downto 0);
			meBus_Read		: out std_logic;
			meBus_Write		: out std_logic;
			meBus_DataIn	: in std_logic_vector (15 downto 0); 
			meBus_DataOut	: out std_logic_vector (15 downto 0);
			
			Sdram_cke		: out std_logic;
			Sdram_xdcs		: out std_logic;
			Sdram_xdras		: out std_logic;
			Sdram_xdcas		: out std_logic;
			Sdram_xdwe		: out std_logic;
			Sdram_ldqm		: out std_logic;
			Sdram_udqm		: out std_logic;
			Sdram_sda		: out std_logic_vector (12 downto 0);
			Sdram_ba			: out std_logic_vector (1 downto 0);
			Sdram_sdd		: inout std_logic_vector (15 downto 0);
			
			Revision			: in std_logic_vector (15 downto 0) 
		);
	end component;

	component UserFPGA_DCM
		port(
			Locked : OUT std_logic;
			--clock and reset
			Clock_50MHz_In	: in std_logic;
			Clock_50MHz_IBUFG_Out : OUT std_logic;
			Clock_50MHz_Out	: out std_logic;
			Clock_100MHz_Out : OUT std_logic;
			GlobalReset	: in	std_logic
		);
	end component;
	
	COMPONENT FDDRRSE
		PORT(
			d0 : in std_logic;
			d1 : in std_logic;          
			c0 : in std_logic;
			c1 : in std_logic;
			ce : in std_logic;
			r  : in std_logic;
			s  : in std_logic;
			q : out std_logic
			);
	END COMPONENT;
	---------------------------------------------------
	--Declarations of Signals
	---------------------------------------------------

	constant  U_REVSION : std_logic_vector (15 downto 0) := "1010001000000001";  -- a201h revision
	
	--signals used in "SpW FPGA Master Access" of eBus
	signal	SeBus_Enable	: std_logic;
	signal	SeBus_Done		: std_logic;
	signal	SeBus_Write		: std_logic;							
	signal	SeBus_Read		: std_logic;	
	signal	SeBus_Address	: std_logic_vector(24 downto 0);
	signal	SeBus_DataIn	: std_logic_vector(15 downto 0);
	signal	SeBus_DataOut	: std_logic_vector(15 downto 0);
	
	--signals used in "UserFPGA Master Access" of eBus
	signal	UeBus_Request	: std_logic;
	signal	UeBus_Grant		: std_logic;
	signal	UeBus_Enable	: std_logic;
	signal	UeBus_Done		: std_logic;
	signal	UeBus_Write		: std_logic;
	signal	UeBus_Read		: std_logic;
	signal	UeBus_Address	: std_logic_vector(24 downto 0);
	signal	UeBus_DataIn	: std_logic_vector (15 downto 0); 
	signal	UeBus_DataOut	: std_logic_vector (15 downto 0); 
	
	
	signal	GateIn_In		: std_logic;
	
	signal	DIO_Out			: std_logic_vector(3 downto 0);
	signal	DIO_In			: std_logic_vector(3 downto 0);

	signal	UserFPGA2Adc_vector	: Signal_UserFPGA2Adc_Vector(7 downto 0);
	signal	Adc2UserFPGA_vector	: Signal_Adc2UserFPGA_Vector(7 downto 0);

	signal	Sdram_cke		: std_logic;
	signal	Sdram_xdcs		: std_logic;
	signal	Sdram_xdras		: std_logic;
	signal	Sdram_xdcas		: std_logic;
	signal	Sdram_xdwe		: std_logic;
	signal	Sdram_ldqm		: std_logic;
	signal	Sdram_udqm		: std_logic;
	signal	Sdram_sda		: std_logic_vector (12 downto 0);
	signal	Sdram_ba			: std_logic_vector (1 downto 0);
	signal	Sdram_sdd		: std_logic_vector (15 downto 0);

	signal	Clock50MHz		: std_logic;
	signal	Clock100MHz		: std_logic;
	signal	Clock100MHzX	: std_logic;
	signal	AdcClock			: std_logic;
	signal	Locked			: std_logic;
	
	---------------------------------------------------
	--Beginning of behavioral description
	---------------------------------------------------
	begin
	inst_dcm: UserFPGA_DCM
		port map(
			Locked	=> Locked,
			--clock and reset
			Clock_50MHz_In	=> uclk,
			Clock_50MHz_IBUFG_Out	=> open,
			Clock_50MHz_Out	=> Clock50MHz,
			Clock_100MHz_Out	=> Clock100MHz,
			GlobalReset	=> grst
		);

	Clock100MHzX <= not Clock100MHz;
	sdramclk : FDDRRSE
		port map (
			d0 => '1',
			d1 => '0',       
			c0 => Clock100MHzX,
			c1 => Clock100MHz,
			ce => '1',
			r  => '0',
			s  => '0',
			q  => o_sdclk
		);

	ints_UserFPGA:  UserFPGA
		port map (
			ClockIn 		=> Clock50MHz,
			ClockOut		=> open,
			ClockBack	=> clkback,
			Clock100MHz => Clock100MHz,
			AdcClockOut	=> AdcClock,--AdcClock ha 8ch common
			LockedIn		=> Locked,
			GlobalReset	=> grst,
			
			GateIn_In		=> GateIn_In,
			DIO_Out		=>	dio(7 downto 0),
			DIO_In		=>	DIO_In,
			
			UserFPGA2Adc_vector	=> UserFPGA2Adc_vector,
			Adc2UserFPGA_vector	=> Adc2UserFPGA_vector,
			
			LEDs			=> uled,
			Switches		=> usw,
			
			eBus_Enable	=> SeBus_Enable,
			eBus_Done	=> SeBus_Done,
			eBus_Address	=> SeBus_Address,
			eBus_DataIn		=> SeBus_DataIn,
			eBus_DataOut	=> SeBus_DataOut, 
			eBus_Write		=> SeBus_Write,
			eBus_Read		=> SeBus_Read,
			meBus_Request	=> UeBus_Request,
			meBus_Grant		=> UeBus_Grant,
			meBus_Enable	=> UeBus_Enable,
			meBus_Done		=> UeBus_Done,
			meBus_Address	=> UeBus_Address,
			meBus_DataIn	=> UeBus_DataIn,
			meBus_DataOut	=> UeBus_DataOut,
			meBus_Read		=> UeBus_Read,
			meBus_Write		=> UeBus_Write,
			
			Sdram_cke		=> Sdram_cke,
			Sdram_xdcs		=> Sdram_xdcs,
			Sdram_xdras		=> Sdram_xdras,
			Sdram_xdcas		=> Sdram_xdcas,
			Sdram_xdwe		=> Sdram_xdwe,
			Sdram_ldqm		=> Sdram_ldqm,
			Sdram_udqm		=> Sdram_udqm,
			Sdram_sda		=> Sdram_sda,
			Sdram_ba			=> Sdram_ba,
			Sdram_sdd		=> sdd,

			Revision	=> U_REVSION
		);
		
	o_cke <= Sdram_cke;
	o_xdcs <= Sdram_xdcs;
	o_xdras <= Sdram_xdras;
	o_xdcas <= Sdram_xdcas;
	o_xdwe <= Sdram_xdwe;
	o_ldqm <= Sdram_ldqm;
	o_udqm <= Sdram_udqm;
	o_sda <= Sdram_sda;
	o_ba <= Sdram_ba;
	
	
	--synchronization of incoming (input) signals from
	--outside UserFPGA
	process(Clock50MHz,grst)
	begin
		if (grst='0') then
		
		elsif (Clock50MHz='1' and Clock50MHz'Event) then
			if (ebus_grant='1') then
				--SpW FPGA Master Mode
				SeBus_Enable <= ebus_ena;
				UeBus_Enable <= '1';
				UeBus_done <= '1';
				SeBus_Address <= ebus_adr;
				if (ebus_wr='0') then
					SeBus_DataIn <= ebus_d;
				else
					SeBus_DataIn <= (others=>'0');
				end if;
				UeBus_DataIn <= (others=>'0');
				SeBus_Write <= ebus_wr;
				SeBus_Read <= ebus_rd;
				UeBus_Grant <= '1';
			else
				--UserFPGA Master Mode
				SeBus_Enable <= '1';
				UeBus_Enable <= ebus_ena;
				UeBus_done <= ebus_done;
				SeBus_Address <= (others=>'0');
				SeBus_DataIn <= (others=>'0');
				if (UeBus_Read='0') then
					UeBus_DataIn <= ebus_d;
				else
					UeBus_DataIn <= (others=>'0');
				end if;
				SeBus_Write <= '1';
				SeBus_Read <= '1';
				UeBus_Grant <= '0';
			end if;
			--buffer
			GateIn_In <= gatein;
			--DIO_In <= dio(3 downto 0);
		end if;
	end process;

	--signal output to the real ports
--	dio(3 downto 0) <= "ZZZZ";
--	dio(7 downto 4) <= DIO_Out;
--debug------------------------
--	dio(0) <= SeBus_Enable;
--	dio(1) <= SeBus_Done;
--	dio(2) <= SeBus_Write;
--	dio(3) <= SeBus_Read;
--	dio(4) <= DIO_Out(0);
--	dio(5) <= DIO_Out(1);
--	dio(6) <= DIO_Out(2);
--	dio(7) <= DIO_Out(3);
dio(8) <= Clock100MHz;
-------------------------------
	ebus_done <= SeBus_Done when (eBus_Grant='1' and ebus_ena='0') else 'Z';
	ebus_adr <= UeBus_Address when (eBus_Grant='0') else (others=>'Z');
	ebus_d <=
			SeBus_DataOut when (eBus_Grant='1' and SeBus_Read='0') else
			UeBus_DataOut when (eBus_Grant='0' and UeBus_Write='0') else
			(others=>'Z');
	ebus_wr <= UeBus_Write when (eBus_Grant='0') else 'Z';
	ebus_rd <= UeBus_Read when (eBus_Grant='0') else 'Z';
	ebus_req <= UeBus_Request;

	-----------------------------------
	--Adc
	-----------------------------------
	
	--inputs from Adc
	process(AdcClock,grst)
	begin
		if (grst='0') then
		
		elsif (AdcClock='1' and AdcClock'Event) then
			Adc2UserFPGA_vector(0).AdcD <= ch0_d; Adc2UserFPGA_vector(0).AdcOTR <= ch0_otr;
			Adc2UserFPGA_vector(1).AdcD <= ch1_d; Adc2UserFPGA_vector(1).AdcOTR <= ch1_otr;
			Adc2UserFPGA_vector(2).AdcD <= ch2_d; Adc2UserFPGA_vector(2).AdcOTR <= ch2_otr;
			Adc2UserFPGA_vector(3).AdcD <= ch3_d; Adc2UserFPGA_vector(3).AdcOTR <= ch3_otr;
			Adc2UserFPGA_vector(4).AdcD <= ch4_d; Adc2UserFPGA_vector(4).AdcOTR <= ch4_otr;
			Adc2UserFPGA_vector(5).AdcD <= ch5_d; Adc2UserFPGA_vector(5).AdcOTR <= ch5_otr;
			Adc2UserFPGA_vector(6).AdcD <= ch6_d; Adc2UserFPGA_vector(6).AdcOTR <= ch6_otr;
			Adc2UserFPGA_vector(7).AdcD <= ch7_d; Adc2UserFPGA_vector(7).AdcOTR <= ch7_otr;
		end if;
	end process;

	--outputs to Adc
	ch0_clk <= UserFPGA2Adc_vector(0).AdcClk; ch0_pdwn <= UserFPGA2Adc_vector(0).AdcPDWN;
	ch1_clk <= UserFPGA2Adc_vector(1).AdcClk; ch1_pdwn <= UserFPGA2Adc_vector(1).AdcPDWN;
	ch2_clk <= UserFPGA2Adc_vector(2).AdcClk; ch2_pdwn <= UserFPGA2Adc_vector(2).AdcPDWN;
	ch3_clk <= UserFPGA2Adc_vector(3).AdcClk; ch3_pdwn <= UserFPGA2Adc_vector(3).AdcPDWN;
	ch4_clk <= UserFPGA2Adc_vector(4).AdcClk; ch4_pdwn <= UserFPGA2Adc_vector(4).AdcPDWN;
	ch5_clk <= UserFPGA2Adc_vector(5).AdcClk; ch5_pdwn <= UserFPGA2Adc_vector(5).AdcPDWN;
	ch6_clk <= UserFPGA2Adc_vector(6).AdcClk; ch6_pdwn <= UserFPGA2Adc_vector(6).AdcPDWN;
	ch7_clk <= UserFPGA2Adc_vector(7).AdcClk; ch7_pdwn <= UserFPGA2Adc_vector(7).AdcPDWN;
--	ch1_clk <= '0'; ch1_pdwn <= '1';
--	ch2_clk <= '0'; ch2_pdwn <= '1';
--	ch3_clk <= '0'; ch3_pdwn <= '1';
--	ch4_clk <= '0'; ch4_pdwn <= '1';
--	ch5_clk <= '0'; ch5_pdwn <= '1';
--	ch6_clk <= '0'; ch6_pdwn <= '1';
--	ch7_clk <= '0'; ch7_pdwn <= '1';
	
	--other signals
	test <= (others=>'0');

end Structural;

