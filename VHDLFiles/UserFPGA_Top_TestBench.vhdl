library ieee,work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.iBus_Library.all;
use work.iBus_AddressMap.all;
use work.UserModule_Library.all;

ENTITY UserFPGA_Top_TestBench_vhdl IS
END UserFPGA_Top_TestBench_vhdl;

ARCHITECTURE behavior OF UserFPGA_Top_TestBench_vhdl IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT user_top
	PORT(
		grst : IN std_logic;
		uclk : IN std_logic;
		ebus_ena : IN std_logic;
		ebus_grant : IN std_logic;
		ch0_otr : IN std_logic;
		ch0_d : IN std_logic_vector(11 downto 0);
		ch1_otr : IN std_logic;
		ch1_d : IN std_logic_vector(11 downto 0);
		ch2_otr : IN std_logic;
		ch2_d : IN std_logic_vector(11 downto 0);
		ch3_otr : IN std_logic;
		ch3_d : IN std_logic_vector(11 downto 0);
		ch4_otr : IN std_logic;
		ch4_d : IN std_logic_vector(11 downto 0);
		ch5_otr : IN std_logic;
		ch5_d : IN std_logic_vector(11 downto 0);
		ch6_otr : IN std_logic;
		ch6_d : IN std_logic_vector(11 downto 0);
		ch7_otr : IN std_logic;
		ch7_d : IN std_logic_vector(11 downto 0);
		ebus_aux0 : IN std_logic;
		ebus_aux1 : IN std_logic;
		ebus_aux2 : IN std_logic;
		ebus_aux3 : IN std_logic;
		ebus_aux4 : IN std_logic;
		ebus_aux5 : IN std_logic;
		ebus_aux6 : IN std_logic;
		ebus_aux7 : IN std_logic;
		clkback : IN std_logic;
		gatein : IN std_logic;
		usw : IN std_logic_vector(3 downto 0);    
		ebus_adr : INOUT std_logic_vector(24 downto 0);
		ebus_d : INOUT std_logic_vector(15 downto 0);
		ebus_wr : INOUT std_logic;
		ebus_rd : INOUT std_logic;
		ebus_done : INOUT std_logic;
		sdd : INOUT std_logic_vector(15 downto 0);
		dio : INOUT std_logic_vector(8 downto 0);      
		ebus_req : OUT std_logic;
		ch0_clk : OUT std_logic;
		ch0_pdwn : OUT std_logic;
		ch1_clk : OUT std_logic;
		ch1_pdwn : OUT std_logic;
		ch2_clk : OUT std_logic;
		ch2_pdwn : OUT std_logic;
		ch3_clk : OUT std_logic;
		ch3_pdwn : OUT std_logic;
		ch4_clk : OUT std_logic;
		ch4_pdwn : OUT std_logic;
		ch5_clk : OUT std_logic;
		ch5_pdwn : OUT std_logic;
		ch6_clk : OUT std_logic;
		ch6_pdwn : OUT std_logic;
		ch7_clk : OUT std_logic;
		ch7_pdwn : OUT std_logic;
		o_sdclk : OUT std_logic;
		o_cke : OUT std_logic;
		o_xdcs : OUT std_logic;
		o_xdras : OUT std_logic;
		o_xdcas : OUT std_logic;
		o_xdwe : OUT std_logic;
		o_ldqm : OUT std_logic;
		o_udqm : OUT std_logic;
		o_sda : OUT std_logic_vector(12 downto 0);
		o_ba : OUT std_logic_vector(1 downto 0);
		uled : OUT std_logic_vector(3 downto 0);
		test : OUT std_logic_vector(5 downto 0)
		);
	END COMPONENT;

	--Inputs
	SIGNAL grst :  std_logic := '0';
	SIGNAL uclk :  std_logic := '0';
	SIGNAL ebus_ena :  std_logic := '0';
	SIGNAL ebus_grant :  std_logic := '0';
	SIGNAL ch0_otr :  std_logic := '0';
	SIGNAL ch1_otr :  std_logic := '0';
	SIGNAL ch2_otr :  std_logic := '0';
	SIGNAL ch3_otr :  std_logic := '0';
	SIGNAL ch4_otr :  std_logic := '0';
	SIGNAL ch5_otr :  std_logic := '0';
	SIGNAL ch6_otr :  std_logic := '0';
	SIGNAL ch7_otr :  std_logic := '0';
	SIGNAL ebus_aux0 :  std_logic := '0';
	SIGNAL ebus_aux1 :  std_logic := '0';
	SIGNAL ebus_aux2 :  std_logic := '0';
	SIGNAL ebus_aux3 :  std_logic := '0';
	SIGNAL ebus_aux4 :  std_logic := '0';
	SIGNAL ebus_aux5 :  std_logic := '0';
	SIGNAL ebus_aux6 :  std_logic := '0';
	SIGNAL ebus_aux7 :  std_logic := '0';
	SIGNAL clkback :  std_logic := '0';
	SIGNAL gatein :  std_logic := '0';
	SIGNAL ch0_d :  std_logic_vector(11 downto 0) := (others=>'0');
	SIGNAL ch1_d :  std_logic_vector(11 downto 0) := (others=>'0');
	SIGNAL ch2_d :  std_logic_vector(11 downto 0) := (others=>'0');
	SIGNAL ch3_d :  std_logic_vector(11 downto 0) := (others=>'0');
	SIGNAL ch4_d :  std_logic_vector(11 downto 0) := (others=>'0');
	SIGNAL ch5_d :  std_logic_vector(11 downto 0) := (others=>'0');
	SIGNAL ch6_d :  std_logic_vector(11 downto 0) := (others=>'0');
	SIGNAL ch7_d :  std_logic_vector(11 downto 0) := (others=>'0');
	SIGNAL usw :  std_logic_vector(3 downto 0) := (others=>'0');

	--BiDirs
	SIGNAL ebus_adr :  std_logic_vector(24 downto 0);
	SIGNAL ebus_d :  std_logic_vector(15 downto 0);
	SIGNAL ebus_wr :  std_logic;
	SIGNAL ebus_rd :  std_logic;
	SIGNAL ebus_done :  std_logic;
	SIGNAL sdd :  std_logic_vector(15 downto 0);
	SIGNAL dio :  std_logic_vector(8 downto 0);

	--Outputs
	SIGNAL ebus_req :  std_logic;
	SIGNAL ch0_clk :  std_logic;
	SIGNAL ch0_pdwn :  std_logic;
	SIGNAL ch1_clk :  std_logic;
	SIGNAL ch1_pdwn :  std_logic;
	SIGNAL ch2_clk :  std_logic;
	SIGNAL ch2_pdwn :  std_logic;
	SIGNAL ch3_clk :  std_logic;
	SIGNAL ch3_pdwn :  std_logic;
	SIGNAL ch4_clk :  std_logic;
	SIGNAL ch4_pdwn :  std_logic;
	SIGNAL ch5_clk :  std_logic;
	SIGNAL ch5_pdwn :  std_logic;
	SIGNAL ch6_clk :  std_logic;
	SIGNAL ch6_pdwn :  std_logic;
	SIGNAL ch7_clk :  std_logic;
	SIGNAL ch7_pdwn :  std_logic;
	SIGNAL o_sdclk :  std_logic;
	SIGNAL o_cke :  std_logic;
	SIGNAL o_xdcs :  std_logic;
	SIGNAL o_xdras :  std_logic;
	SIGNAL o_xdcas :  std_logic;
	SIGNAL o_xdwe :  std_logic;
	SIGNAL o_ldqm :  std_logic;
	SIGNAL o_udqm :  std_logic;
	SIGNAL o_sda :  std_logic_vector(12 downto 0);
	SIGNAL o_ba :  std_logic_vector(1 downto 0);
	SIGNAL uled :  std_logic_vector(3 downto 0);
	SIGNAL test :  std_logic_vector(5 downto 0);
	
	signal counter : integer :=0;
BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: user_top PORT MAP(
		grst => grst,
		uclk => uclk,
		ebus_adr => ebus_adr,
		ebus_d => ebus_d,
		ebus_ena => ebus_ena,
		ebus_wr => ebus_wr,
		ebus_rd => ebus_rd,
		ebus_req => ebus_req,
		ebus_grant => ebus_grant,
		ebus_done => ebus_done,
		ch0_clk => ch0_clk,
		ch0_pdwn => ch0_pdwn,
		ch0_otr => ch0_otr,
		ch0_d => ch0_d,
		ch1_clk => ch1_clk,
		ch1_pdwn => ch1_pdwn,
		ch1_otr => ch1_otr,
		ch1_d => ch1_d,
		ch2_clk => ch2_clk,
		ch2_pdwn => ch2_pdwn,
		ch2_otr => ch2_otr,
		ch2_d => ch2_d,
		ch3_clk => ch3_clk,
		ch3_pdwn => ch3_pdwn,
		ch3_otr => ch3_otr,
		ch3_d => ch3_d,
		ch4_clk => ch4_clk,
		ch4_pdwn => ch4_pdwn,
		ch4_otr => ch4_otr,
		ch4_d => ch4_d,
		ch5_clk => ch5_clk,
		ch5_pdwn => ch5_pdwn,
		ch5_otr => ch5_otr,
		ch5_d => ch5_d,
		ch6_clk => ch6_clk,
		ch6_pdwn => ch6_pdwn,
		ch6_otr => ch6_otr,
		ch6_d => ch6_d,
		ch7_clk => ch7_clk,
		ch7_pdwn => ch7_pdwn,
		ch7_otr => ch7_otr,
		ch7_d => ch7_d,
		o_sdclk => o_sdclk,
		o_cke => o_cke,
		o_xdcs => o_xdcs,
		o_xdras => o_xdras,
		o_xdcas => o_xdcas,
		o_xdwe => o_xdwe,
		o_ldqm => o_ldqm,
		o_udqm => o_udqm,
		o_sda => o_sda,
		o_ba => o_ba,
		sdd => sdd,
		ebus_aux0 => ebus_aux0,
		ebus_aux1 => ebus_aux1,
		ebus_aux2 => ebus_aux2,
		ebus_aux3 => ebus_aux3,
		ebus_aux4 => ebus_aux4,
		ebus_aux5 => ebus_aux5,
		ebus_aux6 => ebus_aux6,
		ebus_aux7 => ebus_aux7,
		clkback => clkback,
		gatein => gatein,
		uled => uled,
		usw => usw,
		dio => dio,
		test => test
	);

	tb : PROCESS
	BEGIN
		-- Wait 100 ns for global reset to finish
		wait for 20 ns;
		uclk <= '1';
		wait for 20 ns;
		uclk <= '0';
	END PROCESS;

	ebus_grant <= '1';

	clkback <= uclk;
	process(uclk)
	begin
		if (uclk='1' and uclk'Event) then
			if (counter<10) then
				grst<='0';counter <= counter + 1;
			elsif (counter<100) then
				grst <= '1';
				ebus_ena <= '1';
				ebus_grant <= '1';
				ebus_adr <= (others=>'0');
				ebus_d <= (others=>'0');
				ebus_wr <= '1';
				ebus_rd <= '1';
				counter <= counter + 1;
--			elsif (counter=100) then
--				ebus_ena <= '0';
--				--ebus_wr<='0';
--				ebus_rd <= '0';
--				ebus_adr(24 downto 16) <= (others=>'0');
--				ebus_adr(15 downto 0) <= x"0000";
--				--ebus_d <= x"1234";
--				counter <= counter + 1;
--			elsif (counter=101) then
--				if (ebus_done='0') then
--					--ebus_wr<='1';
--					ebus_rd <= '1';
--					ebus_ena<='1';
--					counter <= counter + 1;
--				end if;
--			elsif (counter>=102 and counter<110) then
--				if (ebus_done='1') then
--					counter <= counter + 1;
--				end if;
--			elsif (counter=110) then
--				ebus_ena <= '0';
--				ebus_rd <= '0';
--				ebus_adr(24 downto 16) <= (others=>'0');
--				ebus_adr(15 downto 0) <= x"abc2";
--				ebus_d <= (others=>'Z');
--				counter <= counter + 1;
--				
			end if;
		end if;
	end process;

END;
