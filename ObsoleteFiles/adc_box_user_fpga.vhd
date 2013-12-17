--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:    19:13:19 06/13/06
-- Design Name:    
-- Module Name:    user_fpga - Behavioral
-- Project Name:   
-- Target Device:  
-- Tool versions:  
-- Description:
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adc_box_user_fpga is
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
end adc_box_user_fpga;

architecture Behavioral of adc_box_user_fpga is

	TYPE	STATE	IS (MST0,MST1,MST2,MST3,MST4,MST5,MST6,MST7,MST8,MST9);

	signal	current_state,next_state	: STATE;

	constant  REVACC : std_logic_vector (15 downto 0) := "0000000000000000";  -- 0000h revision
	constant  LEDACC : std_logic_vector (15 downto 0) := "0000000000000010";  -- 0002h LED
	constant  DSWACC : std_logic_vector (15 downto 0) := "0000000000000100";  -- 0004h DIP SW
	constant  TSTACC : std_logic_vector (15 downto 0) := "0000000000000110";  -- 0006h TEST
	constant  DENACC : std_logic_vector (15 downto 0) := "0000000000001000";  -- 0008h DIO EN
	constant  DINACC : std_logic_vector (15 downto 0) := "0000000000001010";  -- 000ah DIO IN
	constant  DOUACC : std_logic_vector (15 downto 0) := "0000000000001100";  -- 000ch DIO OUT 
	constant  PWDACC : std_logic_vector (15 downto 0) := "0000000000001110";  -- 000eh ADC PWDN
	constant  CH0ACC : std_logic_vector (15 downto 0) := "0000000000010000";  -- 0010h ADC CH0
	constant  CH1ACC : std_logic_vector (15 downto 0) := "0000000000010010";  -- 0012h ADC CH1
	constant  CH2ACC : std_logic_vector (15 downto 0) := "0000000000010100";  -- 0014h ADC CH2
	constant  CH3ACC : std_logic_vector (15 downto 0) := "0000000000010110";  -- 0016h ADC CH3
	constant  CH4ACC : std_logic_vector (15 downto 0) := "0000000000011000";  -- 0018h ADC CH4
	constant  CH5ACC : std_logic_vector (15 downto 0) := "0000000000011010";  -- 001ah ADC CH5
	constant  CH6ACC : std_logic_vector (15 downto 0) := "0000000000011100";  -- 001ch ADC CH6
	constant  CH7ACC : std_logic_vector (15 downto 0) := "0000000000011110";  -- 001eh ADC CH7
	constant  GATACC : std_logic_vector (15 downto 0) := "0000000000100000";  -- 0020h GATE IN 

	signal	fp_led		: std_logic_vector (3 downto 0);
	signal	test_d		: std_logic_vector (15 downto 0);
	signal	fp_sw			: std_logic_vector (15 downto 0) := (others => '0');
	signal	rdy_cnt		: std_logic_vector (5 downto 0);

	signal	adcpwdn		: std_logic_vector (7 downto 0);
	signal	rd_en			: std_logic;
	signal	dioen			: std_logic;
	signal	adc0_sd		: std_logic_vector (12 downto 0);
	signal	adc1_sd		: std_logic_vector (12 downto 0);
	signal	adc2_sd		: std_logic_vector (12 downto 0);
	signal	adc3_sd		: std_logic_vector (12 downto 0);
	signal	adc4_sd		: std_logic_vector (12 downto 0);
	signal	adc5_sd		: std_logic_vector (12 downto 0);
	signal	adc6_sd		: std_logic_vector (12 downto 0);
	signal	adc7_sd		: std_logic_vector (12 downto 0);

begin

	
-- user sel -----------------------------------------------------
	rd_en <= '1' when (reg_cs = '0' and reg_rd = '0') else '0';
-- fpga_reg -----------------------------------------------------
process (gclk,grst)
begin
	if(grst ='0') then
		fp_led 	<= "1010";
		dout 		<= (others => '0');
		test_d 	<= "1000001100001000";
		dioen 	<= '0';
		adcpwdn 	<= (others => '0');	
	elsif  (gclk'EVENT and gclk = '1')	 then
		if(reg_cs = '0' and reg_wr = '0') then
			case(reg_adr) is
			when	LEDACC =>	fp_led <= reg_di(3 downto 0);
			when	DOUACC =>	dout <= reg_di(8 downto 0);
			when	TSTACC =>	test_d <= reg_di;
			when	DENACC =>	dioen <= reg_di(0);
			when	PWDACC =>	adcpwdn <= reg_di(7 downto 0);
			when others =>	 
			end case;
		end if;
	end if;
end process;
	fp_sw (3 downto 0)	<= usw;
	reg_do <= u_revsion when (rd_en = '1' and reg_adr = REVACC) else
					"000000000000" & fp_led when (rd_en = '1' and reg_adr = LEDACC) else
					fp_sw when (rd_en = '1' and reg_adr = DSWACC) else
					test_d when (rd_en = '1' and reg_adr = TSTACC) else
					"000000000000000" & dioen when (rd_en = '1' and reg_adr = DENACC) else
					"0000000" & din when (rd_en = '1' and reg_adr = DINACC) else
					"00000000" & adcpwdn  when (rd_en = '1' and reg_adr = PWDACC) else
					"000" & adc0_sd when (rd_en = '1' and reg_adr = CH0ACC) else
					"000" & adc1_sd when (rd_en = '1' and reg_adr = CH1ACC) else
					"000" & adc2_sd when (rd_en = '1' and reg_adr = CH2ACC) else
					"000" & adc3_sd when (rd_en = '1' and reg_adr = CH3ACC) else
					"000" & adc4_sd when (rd_en = '1' and reg_adr = CH4ACC) else
					"000" & adc5_sd when (rd_en = '1' and reg_adr = CH5ACC) else
					"000" & adc6_sd when (rd_en = '1' and reg_adr = CH6ACC) else
					"000" & adc7_sd when (rd_en = '1' and reg_adr = CH7ACC) else
					"000000000000000" & gatein when (rd_en = '1' and reg_adr = GATACC) else
					(others => '0');
	uled <= fp_led;
	dio_en <= dioen;
	adc_pwdn <= adcpwdn;
	
-- adc -------------------------------------	
process (adcclk,grst)
begin
	if(grst = '0') then
		adc0_sd 	<= (others => '0'); 
		adc1_sd 	<= (others => '0');  
		adc2_sd 	<= (others => '0');  
		adc3_sd 	<= (others => '0'); 
		adc4_sd 	<= (others => '0');  
		adc5_sd 	<= (others => '0');  
		adc6_sd 	<= (others => '0');  
		adc7_sd 	<= (others => '0');  
	elsif (adcclk'EVENT and adcclk = '1')	 then
		if(not(rd_en = '1' and reg_adr = CH0ACC)) then
			adc0_sd 	<= adc0_d; 
		end if;
		if(not(rd_en = '1' and reg_adr = CH1ACC)) then
			adc1_sd 	<= adc1_d; 
		end if;
		if(not(rd_en = '1' and reg_adr = CH2ACC)) then
			adc2_sd 	<= adc2_d; 
		end if;
		if(not(rd_en = '1' and reg_adr = CH3ACC)) then
			adc3_sd 	<= adc3_d; 
		end if;
		if(not(rd_en = '1' and reg_adr = CH4ACC)) then
			adc4_sd 	<= adc4_d; 
		end if;
		if(not(rd_en = '1' and reg_adr = CH5ACC)) then
			adc5_sd 	<= adc5_d; 
		end if;
		if(not(rd_en = '1' and reg_adr = CH6ACC)) then
			adc6_sd 	<= adc6_d; 
		end if;
		if(not(rd_en = '1' and reg_adr = CH7ACC)) then
			adc7_sd 	<= adc7_d; 
		end if;
	end if;
end process;


-- slave RDY ---------------------------------------------------------------------
process (gclk,grst)
begin
	if(grst ='0') then
		rdy_cnt <= (others => '0');
		reg_rdy <= '0';
	elsif (gclk'EVENT and gclk = '1') then
		if(reg_cs = '0') then
			rdy_cnt <= rdy_cnt + '1';
		else
			rdy_cnt <= (others => '0');
		end if;
		if(rdy_cnt > 3 and rdy_cnt < 6) then
			reg_rdy <= '1';
		else
			reg_rdy <= '0';
		end if;
	end if;
end process;
		
end Behavioral;
