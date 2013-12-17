-- SpaceWire Board
-- FPGA:xc3s1000-ft256
-- SDRAM Controller sdram Initialize
-- DATE '2007-Nov-30
-- Ver0.0


library	IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

ENTITY spw_sdraminit IS
PORT(
	clk				: in	std_logic;-- 48MHz or 96MHz
	xreset			: in	std_logic;-- Active Low
	cmd_ack			: in	std_logic;
	bus_width		: in	std_logic;--Memory Bus Width 0=8bit,1=16bit

	ref_req			: out	std_logic;
	cmd_req			: out	std_logic;
	cmd_reg			: out	std_logic_vector(5 downto 0);
	mode_adr		: out	std_logic_vector(12 downto 0);
	init_end		: out	std_logic;
	trfc_reg		: out	std_logic_vector(3 downto 0);--// tRFC=105ns (28clk@266MHz)
	trcd_reg		: out	std_logic_vector(1 downto 0);--// tRCD=15ns (4clk@266mhz)
	tras_reg		: out	std_logic_vector(3 downto 0);--// tRAS=40ns (11clk@266mhz)
	trp_reg			: out	std_logic_vector(1 downto 0);--// tRP=15ns	(4clk@266mhz)
	twr_reg			: out	std_logic_vector(1 downto 0);--// tWR=15ns	(4clk@266mhz)
	blen_reg		: out	std_logic_vector(3 downto 0) --
);

END spw_sdraminit;

ARCHITECTURE sdram_init OF spw_sdraminit IS
--constant	modeset				: std_logic_vector(12 downto 0) := "0000000100000";
constant	TRFC				: std_logic_vector(3 downto 0) := "1000";
constant	TRCD				: std_logic_vector(1 downto 0) := "10";
constant	TRAS				: std_logic_vector(3 downto 0) := "0101";
constant	TRP					: std_logic_vector(1 downto 0) := "10";
constant	TWR					: std_logic_vector(1 downto 0) := "10";

TYPE	STATE 	IS 	(inital,idle0,slfexit,idle1,alprchg,idle2,ref0,idle3,ref1,idle4,mdset,idle5,idle6);

SIGNAL current_state,next_state						: STATE;

signal	cmdreg			: std_logic_vector(5 downto 0);
signal	cmdreq			: std_logic;
signal	mad				: std_logic_vector(12 downto 0);
signal	powup_cntr		: std_logic_vector(15 downto 0);
signal	power_up		: std_logic;
signal	ref_cntr		: std_logic_vector(9 downto 0);
signal	initend			: std_logic;


BEGIN

--//****************************************************
--//	Power UP Counter  100 usec 10,000clk@100MHz 2710hex
--//****************************************************
PROCESS (clk,xreset)
	BEGIN
		IF (xreset = '0') THEN
								powup_cntr <= (OTHERS =>'0');
								power_up <= '0';
		ELSIF (clk'EVENT AND clk = '1') THEN
			IF	(power_up = '0')	THEN
								powup_cntr <= powup_cntr + '1';
			ELSE
								powup_cntr <= powup_cntr;
			END IF;
			IF	(powup_cntr >= "0010011100010000")	THEN
--			IF	(powup_cntr >= "0000000100010000")	THEN --for sim test
								power_up <= '1';
			END IF;
		END IF;
	END PROCESS;

--//******************************************************************************
--//--SDRAM INITIALIZE Sequence State Machine
--//******************************************************************************
PROCESS (clk,xreset)
BEGIN
	IF (xreset = '0') THEN
								current_state <= inital;
	ELSIF (clk'EVENT AND clk = '1') THEN
								current_state <= next_state;
	END IF;
END PROCESS;

PROCESS (current_state,power_up,cmd_ack)
BEGIN
	CASE	current_state	IS
			WHEN	inital	=>								next_state	<= idle0;
								cmdreg	<= (OTHERS =>'0');
								cmdreq	<= '0';
								mad		<= (OTHERS =>'0');

			WHEN	idle0	=>		
							IF	(power_up = '1')	THEN		next_state	<= slfexit;
							ELSE							next_state	<= idle0;
							END IF;

								cmdreg	<= (OTHERS =>'0');
								cmdreq	<= '0';
								mad		<= (OTHERS =>'0');

			WHEN	slfexit	=>								next_state	<= idle1;
								cmdreg	<= "001000";
								cmdreq	<= '1';
								mad		<= (OTHERS =>'0');

			WHEN	idle1	=>		
							IF	(cmd_ack = '1')	THEN		next_state	<= alprchg;
							ELSE							next_state	<= idle1;
							END IF;

								cmdreg	<= "001000";
								cmdreq	<= '0';
								mad		<= (OTHERS =>'0');

			WHEN	alprchg	=>								next_state	<= idle2;

								cmdreg	<= "000010";
								cmdreq	<= '1';
								mad		<= (OTHERS =>'0');

			WHEN	idle2	=>		
							IF	(cmd_ack = '1')	THEN		next_state	<= ref0;
							ELSE							next_state	<= idle2;
							END IF;

								cmdreg	<= "000010";
								cmdreq	<= '0';
								mad		<= (OTHERS =>'0');

			WHEN	ref0	=>								next_state	<= idle3;

								cmdreg	<= "000100";
								cmdreq	<= '1';
								mad		<= (OTHERS =>'0');

			WHEN	idle3	=>		
							IF	(cmd_ack = '1')	THEN		next_state	<= ref1;
							ELSE							next_state	<= idle3;
							END IF;

								cmdreg	<= "000100";
								cmdreq	<= '0';
								mad		<= (OTHERS =>'0');

			WHEN	ref1	=>								next_state	<= idle4;

								cmdreg	<= "000100";
								cmdreq	<= '1';
								mad		<= (OTHERS =>'0');

			WHEN	idle4	=>		
							IF	(cmd_ack = '1')	THEN		next_state	<= mdset;
							ELSE							next_state	<= idle4;
							END IF;

								cmdreg	<= "000100";
								cmdreq	<= '0';
								mad		<= (OTHERS =>'0');


			WHEN	mdset	=>								next_state	<= idle5;

								cmdreg	<= "000001";
								cmdreq	<= '1';
								mad		<= "0000000100000";


			WHEN	idle5	=>		
							IF	(cmd_ack = '1')	THEN		next_state	<= idle6;
							ELSE							next_state	<= idle5;
							END IF;

								cmdreg	<= "000001";
								cmdreq	<= '0';
								mad		<= "0000000100000";

			WHEN	idle6	=>								next_state	<= idle6;

								cmdreg	<= "000000";
								cmdreq	<= '0';
								mad		<= (OTHERS =>'0');


		END CASE;
END PROCESS;


--//****************************************************
--//	INITIALIZE FINISHED
--//****************************************************
PROCESS (clk,xreset)
BEGIN
	IF (xreset = '0') THEN
								initend <= '0';
	ELSIF (clk'EVENT AND clk = '1') THEN
		IF	(current_state = idle6)	THEN
								initend <= '1';
		END IF;
	END IF;
END PROCESS;

	init_end <= initend;

PROCESS (clk,xreset)
BEGIN
	IF (xreset = '0') THEN
								cmd_req <= '0';
								cmd_reg	<= "000000";
								mode_adr <= (OTHERS => '0');
	ELSIF (clk'EVENT AND clk = '1') THEN
								cmd_req	<= cmdreq;
								cmd_reg <= cmdreg;
								mode_adr <= mad;
	END IF;
END PROCESS;




	trfc_reg <= TRFC;--tRFC=66ns (7clk@100MHz)
	trcd_reg <= TRCD;--tRCD=20ns (2clk@100MHz)
	tras_reg <= TRAS;--tRAS=44ns (5clk@100MHz)
	trp_reg	 <= TRP; --tRP=15ns (2clk@100mhz)
	twr_reg  <= TWR; --tWR=15ns (2clk@100MHz)
	blen_reg <= "0001" WHEN (bus_width ='1')	ELSE "0010";




--//****************************************************
--//	Reflesh Counter  8192times @ 64ms 7.8us
--//****************************************************
PROCESS (clk,xreset,initend)
BEGIN
	IF (xreset = '0') THEN
								ref_cntr <= "1100001100";
								ref_req	 <= '0';
	ELSIF (clk'EVENT AND clk = '1') THEN
		IF	(initend ='1')	THEN
			IF (ref_cntr = "0000000000") THEN
								ref_cntr <= "1100001100";
								ref_req  <= '1';
			ELSE
								ref_cntr <= ref_cntr - '1';
								ref_req	 <= '0';
			END IF;
		END IF;
	END IF;
END PROCESS;











END sdram_init;


