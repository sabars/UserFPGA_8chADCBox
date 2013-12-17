------------------------------------------------------------------------------
-- pogo_user_top.vhd
--
--
-- FPGA Device   : XC3S1000-4FT256
--
--     2006.06.01 shimafuji k.tei
------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;
library unisim;
use unisim.vcomponents.all;


entity spw_adc_box_user_top is
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
--			fb_clki 		: in std_logic; 
--			clk_aux 		: in std_logic; 
			gatein 		: in std_logic; 
			uled 			: out std_logic_vector (3 downto 0);
			usw 			: in std_logic_vector (3 downto 0); 
			dio 			: inout std_logic_vector (8 downto 0);
			test 			: out std_logic_vector (5 downto 0)
		);
end spw_adc_box_user_top;

architecture structural of spw_adc_box_user_top is

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

component uclk_pll is
   port ( CLKIN_IN  : in    std_logic; 
          CLKFX_OUT : out   std_logic; 
          CLK0_OUT  : out   std_logic; 
          CLK2X_OUT : out   std_logic);
end component;

component spw_sdram_top is
	port (clk : in std_logic; xreset : in std_logic;
		spw_wr : in std_logic; spw_rd : in std_logic; spw_hbe : in std_logic;
		spw_adr : in std_logic_vector (24 downto 0); spw_wdd : in std_logic_vector(15 downto 0);
		spw_rdd : out std_logic_vector(15 downto 0); sdram_cs : in std_logic; sdram_rdy : out std_logic;
	-- SDRAM Interface		
		o_cke : out std_logic; o_xdcs : out std_logic; o_xdras : out std_logic;
		o_xdcas : out std_logic; o_xdwe: out std_logic; o_dqm : out std_logic_vector(1 downto 0);
		o_sda : out std_logic_vector(12 downto 0); o_ba : out std_logic_vector(1 downto 0);
		sdd : inout std_logic_vector(15 downto 0)
	);
end component;

component   adc_box_user_fpga
	port (
		gclk 			: in std_logic;
		adcclk 		: in std_logic;
		grst 			: in std_logic;
		
		reg_adr		: in std_logic_vector(15 downto 0);
		reg_di		: in std_logic_vector(15 downto 0);
		reg_do		: out std_logic_vector(15 downto 0);
		reg_cs		: in std_logic;								
		reg_wr		: in std_logic;								
		reg_rd		: in std_logic;								
		reg_rdy		: out std_logic;								
		
		adc_pwdn		: out std_logic_vector (7 downto 0);
		adc0_d 		: in std_logic_vector (12 downto 0);
		adc1_d 		: in std_logic_vector (12 downto 0);
		adc2_d 		: in std_logic_vector (12 downto 0);
		adc3_d 		: in std_logic_vector (12 downto 0);
		adc4_d 		: in std_logic_vector (12 downto 0);
		adc5_d 		: in std_logic_vector (12 downto 0);
		adc6_d 		: in std_logic_vector (12 downto 0);
		adc7_d 		: in std_logic_vector (12 downto 0);
		
		gatein 		: in std_logic; 
		dio_en		: out std_logic;
		din			: in std_logic_vector (8 downto 0);
		dout			: out std_logic_vector (8 downto 0);
		uled			: out std_logic_vector (3 downto 0); 
		usw			: in std_logic_vector (3 downto 0); 
		u_revsion	: in std_logic_vector (15 downto 0) 
	);
end component;

	constant  U_REVSION : std_logic_vector (15 downto 0) := "1010101000000001";  -- aa01h revision
	signal	gclk 			: std_logic;
	signal	clk100m		: std_logic;
	signal	clk100mb		: std_logic;
	signal	adc_clk 		: std_logic;
	
	signal	bus_adr		: std_logic_vector(24 downto 0);
	signal	bus_rdy		: std_logic;
	signal	bus_cs		: std_logic;								
	signal	bus_wr		: std_logic;								
	signal	bus_rd		: std_logic;
	signal	bus_done		: std_logic;
	signal	bus_req		: std_logic := '1';								
	signal	reg_di		: std_logic_vector(15 downto 0);
	signal	reg_do		: std_logic_vector(15 downto 0);
	signal	reg_cs		: std_logic;								

	signal	nd_ebus_aux0 : std_logic; 
	signal	nd_ebus_aux1 : std_logic; 
	signal	nd_ebus_aux2	: std_logic; 
	signal	nd_ebus_aux3 : std_logic; 
	signal	nd_ebus_aux4 : std_logic; 
	signal	nd_ebus_aux5 : std_logic; 
	signal	nd_ebus_aux6 : std_logic; 
	signal	nd_ebus_aux7 : std_logic; 

	signal	adc_pwdn		: std_logic_vector (7 downto 0);
	signal	adc0_d	   : std_logic_vector (12 downto 0);
	signal	adc1_d	   : std_logic_vector (12 downto 0);
	signal	adc2_d	   : std_logic_vector (12 downto 0);
	signal	adc3_d	   : std_logic_vector (12 downto 0);
	signal	adc4_d	   : std_logic_vector (12 downto 0);
	signal	adc5_d	   : std_logic_vector (12 downto 0);
	signal	adc6_d	   : std_logic_vector (12 downto 0);
	signal	adc7_d	   : std_logic_vector (12 downto 0);
	signal	dio_en 		: std_logic;
	signal	din_nd   	: std_logic_vector (8 downto 0);
	signal	dout_nd	   : std_logic_vector (8 downto 0);
	signal	sdram_di		: std_logic_vector (15 downto 0);
	signal	sdram_do		: std_logic_vector (15 downto 0);
	signal	sdram_rdy	: std_logic;
	signal	sd_rdy		: std_logic_vector (2 downto 0);
	signal	sdram_cs		: std_logic;
	signal	sdram_bhen	: std_logic := '0';								
	signal	o_dqm	: std_logic_vector (1 downto 0);

begin

	user_clk : uclk_pll
   port map ( 
		CLKIN_IN  => uclk,
      CLKFX_OUT => adc_clk,
      CLK0_OUT  => gclk,
      CLK2X_OUT => clk100m
		);
		
	clk100mb <= not clk100m;
	
	sdramclk : FDDRRSE
	port map (
		d0 => '1',
		d1 => '0',       
		c0 => clk100mb,
		c1 => clk100m,
		ce => '1',
		r  => '0',
		s  => '0',
		q  => o_sdclk
		);

	sdram_cont: spw_sdram_top
		port map (
		--SpW Interface
			clk			=> clk100m,
			xreset		=> grst,		--xreset,
			spw_wr		=> bus_wr,
			spw_rd		=> bus_rd,
			spw_hbe		=> sdram_bhen,
			spw_adr		=> bus_adr,
			spw_wdd		=> sdram_di,
			spw_rdd		=> sdram_do,
			sdram_cs		=>	sdram_cs,
			sdram_rdy	=> sdram_rdy,
		-- SDRAM Interface		
			o_cke			=> o_cke,
			o_xdcs		=> o_xdcs,
			o_xdras		=> o_xdras,
			o_xdcas		=> o_xdcas,
			o_xdwe		=> o_xdwe,
			o_dqm			=> o_dqm,
			o_sda			=> o_sda,
			o_ba			=> o_ba,
			sdd			=> sdd
	);
	o_ldqm <= o_dqm(0);
	o_udqm <= o_dqm(1);
	
-- FPGA register -------------------------------------------------------------
user_fpga_0:  adc_box_user_fpga
	port map (
--		gclk 			=> gclk,
		gclk 			=> uclk,
		adcclk		=> adc_clk,
		grst			=> grst,

		reg_adr		=> bus_adr(15 downto 0),
		reg_di		=> reg_di,
		reg_do		=> reg_do,
		reg_cs		=>	reg_cs,						
		reg_wr		=>	bus_wr,					
		reg_rd		=>	bus_rd,							
		reg_rdy		=>	bus_rdy,							
		
		adc_pwdn		=> adc_pwdn,
		adc0_d 		=> adc0_d,
		adc1_d 		=> adc1_d,
		adc2_d 		=> adc2_d,
		adc3_d 		=> adc3_d,
		adc4_d 		=> adc4_d,
		adc5_d 		=> adc5_d,
		adc6_d 		=> adc6_d,
		adc7_d 		=> adc7_d,
		gatein 		=> gatein,
		dio_en		=> dio_en,
		din			=> din_nd,
		dout			=> dout_nd,
		uled			=> uled,
		usw			=> usw,
		u_revsion	=>  U_REVSION
	);

-- ADC ---------------------------------------------------------------------
	ch0_clk <= adc_clk;
	ch1_clk <= adc_clk;
	ch2_clk <= adc_clk;
	ch3_clk <= adc_clk;
	ch4_clk <= adc_clk;
	ch5_clk <= adc_clk;
	ch6_clk <= adc_clk;
	ch7_clk <= adc_clk;
	ch0_pdwn <= adc_pwdn(0);
	ch1_pdwn <= adc_pwdn(1);
	ch2_pdwn <= adc_pwdn(2);
	ch3_pdwn <= adc_pwdn(3);
	ch4_pdwn <= adc_pwdn(4);
	ch5_pdwn <= adc_pwdn(5);
	ch6_pdwn <= adc_pwdn(6);
	ch7_pdwn <= adc_pwdn(7);
	adc0_d <= ch0_otr & ch0_d;
	adc1_d <= ch1_otr & ch1_d;
	adc2_d <= ch2_otr & ch2_d;
	adc3_d <= ch3_otr & ch3_d;
	adc4_d <= ch4_otr & ch4_d;
	adc5_d <= ch5_otr & ch5_d;
	adc6_d <= ch6_otr & ch6_d;
	adc7_d <= ch7_otr & ch7_d;
	
-- DIO ---------------------------------------------------------------------
	dio		<= dout_nd when(dio_en = '1') else (others => 'Z');
	din_nd	<= dio when(dio_en = '0') else (others => 'Z');
-- BUS ---------------------------------------------------------------------
process (gclk,grst)
begin
	if(grst ='0') then
		sd_rdy <= "000";
	elsif (gclk'EVENT and gclk = '1') then
		sd_rdy <= sd_rdy(1 downto 0) & sdram_rdy;
	end if;
end process;
process (gclk,grst)
begin
	if(grst ='0') then
		bus_done <= '1';
	elsif (gclk'EVENT and gclk = '1') then
		if(bus_cs = '0' and (sd_rdy(2) = '1' or bus_rdy = '1')) then
			bus_done <= '0';
		elsif(bus_cs = '1') then
			bus_done <= '1';
		end if;
	end if;
end process;
	ebus_adr		<=  (others => '0') when (bus_req = '0') else (others => 'Z');
	ebus_req 	<= bus_req;
	ebus_wr		<= '0' when (bus_req = '0') else 'Z';						
	ebus_rd		<= '0' when (bus_req = '0') else 'Z';								
	ebus_done	<= bus_done when (bus_req = '1') else 'Z';
	bus_cs		<= ebus_ena;
	bus_wr		<= ebus_wr;						
	bus_rd		<= ebus_rd;	
	bus_adr		<= ebus_adr;	

	reg_di	<= ebus_d;
	sdram_di	<= ebus_d;
	ebus_d	<= reg_do when (reg_cs = '0' and ebus_rd = '0') else
					sdram_do when (sdram_cs = '1' and ebus_rd = '0') else
					(others => 'Z');
	
-- DEC ---------------------------------------------------------------------
	sdram_cs <= not bus_cs when (ebus_adr (24 downto 23) = "11")  else '0';
	reg_cs 	<= bus_cs when (ebus_adr (24 downto 16) ="100000001")  else '1';
	
-- aux ---------------------------------------------------------------------
	nd_ebus_aux0  <= ebus_aux0;
	nd_ebus_aux1  <= ebus_aux1;
	nd_ebus_aux2  <= ebus_aux2;
	nd_ebus_aux3  <= ebus_aux3;
	nd_ebus_aux4  <= ebus_aux4;
	nd_ebus_aux5  <= ebus_aux5;
	nd_ebus_aux6  <= ebus_aux6;
	nd_ebus_aux7  <= ebus_aux7;

-- test --------------------------------------------------------------------
	test(0) <= bus_cs;
	test(1) <= bus_rd;
	test(2) <= bus_wr;
	test(3) <= bus_rdy;
	test(4) <= ebus_d(0);
	test(5) <= ebus_d(1);

end structural;

