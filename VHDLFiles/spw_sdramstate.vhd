-- SpaceWire Board
-- FPGA:xc3s1000-ft256
-- SDRAM Controller
-- DATE '2007-Nov-30
-- Ver0.0


library	IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

ENTITY spw_sdramstate IS
PORT(
	clk				: in	std_logic;-- 48MHz or 96MHz
	xreset			: in	std_logic;-- Active Low
	refreq			: in	std_logic;
	spwreq			: in	std_logic;
	cmdreq			: in	std_logic;
	spw_rdwr		: in	std_logic;--read=1,write=0
	spw_hbe			: in	std_logic;--spw high byte enable 0=enable,1=disable
--	bus_width		: in	std_logic;--Memory Bus Width 0=8bit,1=16bit
	cmdreg			: in	std_logic_vector(5 downto 0) ;--[0]=mode,[1]=alp,[2]=ref,[3]=self,[4]=odt,reg[5]=1=on,0=0ff
	trfc_reg		: in	std_logic_vector(3 downto 0) ;--tRFC=66ns (7clk@100MHz)
	trcd_reg		: in	std_logic_vector(1 downto 0) ;--tRCD=20ns (2clk@100MHz)
	tras_reg		: in	std_logic_vector(3 downto 0) ;--tRAS=44ns (5clk@100MHz)
	trp_reg			: in	std_logic_vector(1 downto 0) ;--tRP=15ns (2clk@100mhz)
	twr_reg			: in	std_logic_vector(1 downto 0) ;--tWR=15ns (2clk@100MHz)
	blen_reg		: in	std_logic_vector(3 downto 0) ;--sdram Burst Length

	ref_ack			: out	std_logic;
	cmd_ack			: out	std_logic;
	cnt_ena		: out	std_logic;
	sdwr_enbl		: out std_logic;
	sd_cae		: out	std_logic;
	mode_set		: out	std_logic;
	ap10			: out	std_logic;


	sdd_enbl		: out	std_logic_vector(15 downto 0) ;
	lbrd_ena		: out	std_logic;
	hbrd_ena		: out	std_logic;
	hbw_ena		: out	std_logic;
	sdram_rdy	: out	std_logic;

	o_cke			: OUT	std_logic;
	o_xdcs			: OUT	std_logic;
	o_xdras			: OUT	std_logic;
	o_xdcas			: OUT	std_logic;
	o_xdwe			: OUT	std_logic;
	o_dqm			: OUT	std_logic_vector(1 downto 0)
	);

END spw_sdramstate;

ARCHITECTURE statemachine OF spw_sdramstate IS
	TYPE	STATE 	IS 	(inital,idle0,cmdidle,slfidle,slfentr,slfexit,alpidl0,alpchrg,prcidle,
						reflsh0,reflsh1,modidle,modact,cpuact,rcdidl1,rdcmd,
						alpidle,wrcmd);

SIGNAL	current_state,next_state					: STATE;
signal	dcs,dras,dcas,dwe,dcae,alp,mdst			: std_logic;

signal	ref_req		: std_logic;
signal	spw_req		: std_logic;
signal	cmd_req		: std_logic;
signal	trfc_cntr	: std_logic_vector(3 downto 0);
signal	trcd_cntr	: std_logic_vector(1 downto 0);
signal	twr_cntr		: std_logic_vector(1 downto 0);
signal	trp_cntr		: std_logic_vector(1 downto 0);
signal	tras_cntr	: std_logic_vector(3 downto 0);
signal	blen_cntr	: std_logic_vector(3 downto 0);
signal	tras_wdth	: std_logic;
signal	cmd_actv	: std_logic;
signal	cact_sft	: std_logic;
signal	ckeena		: std_logic;
signal	rd_ena		: std_logic;
signal	rena		: std_logic_vector(4 downto 0);
signal	hb_wena		: std_logic;
signal	hdqm		: std_logic;
-- signal	rd_rdy	: std_logic;
signal	cntena	: std_logic;
signal	rdy_cntr	: std_logic_vector(3 downto 0);
signal	rdyena	: std_logic;
signal	rdden		: std_logic;



BEGIN

--//***************************************************
--// reflesh request reg.
--//***************************************************
PROCESS (clk,xreset,refreq,current_state)
BEGIN
	IF (xreset = '0') THEN
											ref_req <= '0';
											ref_ack	<= '0';
	ELSIF (clk'EVENT AND clk = '1') THEN
				IF	(refreq = '1')	THEN
											ref_req <= '1';
				ELSIF	( current_state = reflsh0)	THEN
											ref_req <= '0';
											ref_ack	<= '1';
				ELSE
											ref_ack	<= '0';
				END IF;
	END IF;
END PROCESS;


--//****************************************************
--//	TRFC COUNTER REFLESH RECOVERY TIME
--//	66ns 7clk@100MHz
--//****************************************************
PROCESS (clk,xreset,current_state)
BEGIN
	IF (xreset = '0') THEN
											trfc_cntr <= "0111";
	ELSIF (clk'EVENT AND clk = '1') THEN
				IF	( current_state = reflsh0)	THEN
											trfc_cntr <= trfc_reg;
				ELSIF ( current_state = reflsh1)	THEN
											trfc_cntr <= trfc_cntr - '1';
				END IF;
	END IF;
END PROCESS;


--//***************************************************
--// SpaceWire I/F Request Reg.
--//***************************************************
PROCESS (clk,xreset,spwreq,current_state)
BEGIN
	IF (xreset = '0') THEN
											spw_req <= '0';
	ELSIF (clk'EVENT AND clk = '1') THEN
				IF	(spwreq = '1')	THEN
											spw_req <= '1';
				ELSIF	( current_state = cpuact)	THEN
											spw_req <= '0';
				END IF;
	END IF;
END PROCESS;

--//***************************************************
--// Command Setting Request Reg.
--//***************************************************
PROCESS (clk,xreset,cmdreq,current_state)
BEGIN
	IF (xreset = '0') THEN
											cmd_req <= '0';
	ELSIF (clk'EVENT AND clk = '1') THEN
				IF	(cmdreq = '1')	THEN
											cmd_req <= '1';
				ELSIF	( current_state = cmdidle)	THEN
											cmd_req <= '0';
				END IF;
	END IF;
END PROCESS;



--//****************************************************
--//	TRCD COUNTER RAS-CAS COMMAND DELAY TIME  20nsec
--//****************************************************
PROCESS (clk,xreset,current_state)
BEGIN
	IF (xreset = '0') THEN
											trcd_cntr <= "10";
	ELSIF (clk'EVENT AND clk = '1') THEN
				IF	( current_state = cpuact)	THEN
											trcd_cntr <= trcd_reg;
				ELSIF ( current_state = rcdidl1)	THEN
											trcd_cntr <= trcd_cntr - '1';
				END IF;
	END IF;
END PROCESS;

--//****************************************************
--//	TRAS COUNTER RAS PULSE WIDTH   min44nsec 5clk@100MHz
--//****************************************************
PROCESS (clk,xreset,current_state,tras_wdth)
BEGIN
	IF (xreset = '0') THEN
											tras_cntr <= "0101";
	ELSIF (clk'EVENT AND clk = '1') THEN
				IF	( current_state = cpuact)	THEN
											tras_cntr <= tras_reg;
				ELSIF (tras_wdth= '1')	THEN
											tras_cntr <= tras_cntr - '1';
				END IF;
	END IF;
END PROCESS;


PROCESS (clk,xreset,current_state,tras_cntr)
BEGIN
	IF (xreset = '0') THEN
											tras_wdth <= '0';
	ELSIF (clk'EVENT AND clk = '1') THEN
				IF	( current_state = cpuact)	THEN
											tras_wdth <= '1';
				ELSIF ( tras_cntr = "0001")	THEN
											tras_wdth <= '0';
				END IF;
	END IF;
END PROCESS;



--//****************************************************
--//		TWR counter for WR RECOVERY time
--//		1clk+ 7.5ns or 15ns 2clk@100MHz
--//****************************************************

PROCESS (clk,xreset,current_state)
BEGIN
	IF (xreset = '0') THEN
											twr_cntr <= "10";
	ELSIF (clk'EVENT AND clk = '1') THEN
				IF	( current_state = wrcmd)	THEN
											twr_cntr <= twr_reg;
				ELSE
											twr_cntr <= twr_cntr - '1';
				END IF;
	END IF;
END PROCESS;


--//****************************************************
--//		TRP counter for Precharge Command Period time
--//		20ns  2clk@100MHz
--//****************************************************

PROCESS (clk,xreset,current_state)
BEGIN
	IF (xreset = '0') THEN
											trp_cntr <= "10";
	ELSIF (clk'EVENT AND clk = '1') THEN
				IF	( current_state = alpchrg)	THEN
											trp_cntr <= trp_reg;
				ELSIF ( current_state = prcidle)	THEN
											trp_cntr <= trp_cntr - '1';
				END IF;
	END IF;
END PROCESS;


--//****************************************************
--//		Burst Size Counter
--//		SDRAM Burst=1
--//****************************************************

PROCESS (clk,xreset,current_state)
BEGIN
	IF (xreset = '0') THEN
											blen_cntr <= "0001";
	ELSIF (clk'EVENT AND clk = '1') THEN
				IF	( current_state = cpuact)	THEN
											blen_cntr <= blen_reg;
				ELSIF (( current_state = rdcmd) or ( current_state = wrcmd))	THEN
											blen_cntr <= blen_cntr - '1';
				END IF;
	END IF;
END PROCESS;











--//****************************************************
--//		COMMAND FINISh STATUS
--//****************************************************

PROCESS (clk,xreset,current_state)
BEGIN
	IF (xreset = '0') THEN
											cmd_actv <= '0';
	ELSIF (clk'EVENT AND clk = '1') THEN
		IF	( current_state = cmdidle)	THEN
											cmd_actv <= '1';
		ELSIF ( current_state = idle0)	THEN
											cmd_actv <= '0';
		END IF;
	END IF;
END PROCESS;


PROCESS (clk,xreset,cmd_actv)
BEGIN
	IF (xreset = '0') THEN
											cact_sft <= '0';
											cmd_ack	 <= '0';
	ELSIF (clk'EVENT AND clk = '1') THEN
											cmd_ack	<= (not cmd_actv and cact_sft);
		IF	( cmd_actv = '1')	THEN
											cact_sft <= '1';
		ELSE
											cact_sft <= '0';
		END IF;
	END IF;
END PROCESS;



--//*****************************************************
--//	SDRAM CONTROLLER STATE MACHINE
--//	Burast Length=1,CasLatency=2
--//*****************************************************

PROCESS (clk,xreset)
BEGIN
	IF (xreset = '0') THEN
								current_state <= inital;
	ELSIF (clk'EVENT AND clk = '1') THEN
								current_state <= next_state;
	END IF;
END PROCESS;


PROCESS (current_state,ref_req,spw_req,cmd_req,trfc_cntr,cmdreg, trp_cntr, spw_rdwr, blen_cntr,tras_cntr)
BEGIN
	CASE	current_state	IS
		WHEN	inital	=>		
												next_state	<= idle0;
							dcs		<= '0';
							dras	<= '0';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '0';

		WHEN	idle0	=>		
							IF		(ref_req='1')	THEN	next_state <= reflsh0;
							ELSIF (cmd_req='1')	THEN	next_state <= cmdidle;
							ELSIF (spw_req='1')	THEN	next_state <= cpuact;
							ELSE								next_state <= idle0;
							END IF;
							dcs		<= '0';
							dras	<= '0';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '0';
		WHEN	cmdidle	=>
							IF		(cmdreg(0) = '1')	THEN		next_state <= modidle;
							ELSIF (cmdreg(1) = '1')	THEN		next_state <= alpidl0;--//alpchrg;
							ELSIF (cmdreg(2) = '1')	THEN		next_state <= reflsh0;
							ELSIF (cmdreg(3) = '1')	THEN		next_state <= slfidle;
--							ELSIF (cmdreg(4) = '1')	THEN		next_state <= odtidle;
							ELSE										next_state <= idle0;
							END IF;
							dcs		<= '0';
							dras	<= '0';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '0';

--	//***************** Self Reflesh CONTROL ****************
		WHEN	slfidle	=>
							IF	   (cmdreg(5) = '1')	THEN	next_state <= slfentr;--// self enter
							ELSE									next_state <= slfexit;--// self exit
							END IF;
							dcs		<= '0';
							dras	<= '0';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '0';

--	//***************** Self Reflesh ENTER ***************
		WHEN	slfentr	=>								next_state	<= idle0;
							dcs		<= '1';
							dras	<= '1';
							dcas	<= '1';
							dwe		<= '0';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '0';

--	//***************** Self Reflesh EXIT *****************
		WHEN	slfexit	=>							next_state	<= idle0;
							dcs		<= '0';
							dras	<= '0';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '0';


--//*********** ALL PRECHARGE COMMAND **********************
		WHEN	alpidl0		=>							next_state	<= alpchrg;
							dcs		<= '0';
							dras	<= '0';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '1';
							alp		<= '1';
							mdst	<= '0';

		WHEN	alpchrg		=>							next_state	<= prcidle;
							dcs		<= '1';
							dras	<= '1';
							dcas	<= '0';
							dwe		<= '1';
							dcae	<= '1';
							alp		<= '1';
							mdst	<= '0';

		WHEN	prcidle		=>
							IF	   (trp_cntr <= "01")	THEN	next_state <= idle0;
							ELSE										next_state <= prcidle;
							END IF;
							dcs		<= '0';
							dras	<= '0';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '0';

--//***************** REFLESH COMMAND ***************
		WHEN	reflsh0		=>							next_state <= reflsh1;
							dcs		<= '1';
							dras	<= '1';
							dcas	<= '1';
							dwe		<= '0';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '0';

		WHEN	reflsh1		=>
							IF	   (trfc_cntr <= "0001")	THEN	next_state <= idle0;
							ELSE											next_state <= reflsh1;
							END IF;
							dcs		<= '0';
							dras	<= '0';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '0';
--//***************** MODE REGISTER SET COMMAND ***************
		WHEN	modidle		=>							next_state <= modact;
							dcs		<= '0';
							dras	<= '0';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '1';

		WHEN	modact		=>							next_state <= idle0;
							dcs		<= '1';
							dras	<= '1';
							dcas	<= '1';
							dwe		<= '1';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '1';

--//***************** ACTIVE COMMAND ************
		WHEN	cpuact		=>							next_state <= rcdidl1;
							dcs		<= '1';
							dras	<= '1';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '0';

--		WHEN	rcdidl0		=>
--							IF	   (trcd_cntr <= '1')	next_state <= rcdidl1;
--							ELSE						next_state <= rcdidl0;
--							dcs		<= '0';
--							dras	<= '0';
--							dcas	<= '0';
--							dwe		<= '0';
--							dcae	<= '0';
--							alp		<= '0';
--							mdst	<= '0';

		WHEN	rcdidl1		=>
							IF	   (spw_rdwr = '1')	THEN		next_state <= rdcmd;	--rdwr=1
							ELSE										next_state <= wrcmd;	--rdwr=0
							END IF;
							dcs		<= '0';
							dras	<= '0';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '1';
							alp		<= '0';
							mdst	<= '0';

--	//***************** READ COMMAND ************
		WHEN	rdcmd		=>									--next_state <= rdidl0;
							IF	   (blen_cntr <= "0001")	THEN		next_state <= alpidle;
							ELSE												next_state <= rdcmd;
							END IF;
							dcs		<= '1';
							dras	<= '0';
							dcas	<= '1';
							dwe		<= '0';
							dcae	<= '1';
							alp		<= '0';
							mdst	<= '0';

--		WHEN	rdidl0		=>
--							IF	   (dlen_cntr <= '0001')		next_state <= alpidle;
--							ELSIF  (blen_cntr <= '0000')		next_state <= rdcmd;
--							ELSE								next_state <= rcdidl0;
--							dcs		<= '0';
--							dras	<= '0';
--							dcas	<= '0';
--							dwe		<= '0';
--							dcae	<= '1';
--							alp		<= '0';
--							mdst	<= '0';

		WHEN	alpidle		=>
							IF	   (tras_cntr <= "0001")	THEN		next_state <= alpchrg;
							ELSE												next_state <= alpidle;
							END IF;
							dcs		<= '0';
							dras	<= '0';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '1';
							alp		<= '1';
							mdst	<= '0';

--	//***************** WRITE COMMAND ************
		WHEN	wrcmd		=>									--next_state <= wridl0;
							IF	   (blen_cntr <= "0001")	THEN		next_state <= alpidle;
							ELSE												next_state <= wrcmd;
							END IF;
							dcs		<= '1';
							dras	<= '0';
							dcas	<= '1';
							dwe		<= '1';
							dcae	<= '1';
							alp		<= '0';
							mdst	<= '0';

--		WHEN	wrdidl0		=>
--							IF	   (dlen_cntr <= '0001')	THEN		next_state <= twridl;
--							ELSIF  (blen_cntr <= '0000')	THNE		next_state <= wrcmd;
--							ELSE												next_state <= wridl0;
--							END IF;
--							dcs		<= '0';
--							dras	<= '0';
--							dcas	<= '0';
--							dwe		<= '0';
--							dcae	<= '1';
--							alp		<= '0';
--							mdst	<= '0';

--		WHEN	twridl		=>									--next_state <= alpchrg;
--							IF	   (twr_cntr <= '0001')	THEN		next_state <= alpchrg;
--							ELSE											next_state <= twridl;
--							END IF;
--							dcs		<= '0';
--							dras	<= '0';
--							dcas	<= '0';
--							dwe		<= '0';
--							dcae	<= '1';
--							alp		<= '1';
--							mdst	<= '0';

		WHEN OTHERS		=>										next_state	<= idle0;
							dcs		<= '0';
							dras	<= '0';
							dcas	<= '0';
							dwe		<= '0';
							dcae	<= '0';
							alp		<= '0';
							mdst	<= '0';

		END CASE;
END PROCESS;



--//*************************************************************
--//	SELF REFLESH, ODT CONTROL REGISTER
--//*************************************************************
PROCESS (clk,xreset,current_state)
BEGIN
	IF (xreset = '0') THEN
											ckeena <= '0';
											o_cke  <= '0';
	ELSIF (clk'EVENT AND clk = '1') THEN
		IF	( current_state = slfexit)	THEN
											ckeena <= '1';
		ELSIF ( current_state = slfentr)	THEN
											ckeena <= '0';
		END IF;
		IF	(ckeena = '1')	THEN
											o_cke  <= '1';
		ELSE
											o_cke  <= '0';
		END IF;
	END IF;
END PROCESS;




--//**********************************************
--//		CS,RAS,CAS,WE OUTPUT REGISTER
--//**********************************************
PROCESS (clk,xreset,dcs,dras,dcas,dwe)
BEGIN
	IF (xreset = '0') THEN
											o_xdcs	<=	'1';
											o_xdras	<=	'1';
											o_xdcas	<=	'1';
											o_xdwe	<=	'1';
	ELSIF (clk'EVENT AND clk = '1') THEN
											o_xdcs	<=	not dcs;
											o_xdras	<=	not dras;
											o_xdcas	<=	not dcas;
											o_xdwe	<=	not dwe;
	END IF;
END PROCESS;

PROCESS (clk,xreset,dcae,alp,mdst)
BEGIN
	IF (xreset = '0') THEN
											sd_cae	<=	'0';
											mode_set	<=	'0';
											ap10		<=	'0';
	ELSIF (clk'EVENT AND clk = '1') THEN
											sd_cae	<=	dcae;
											mode_set	<=	mdst;
											ap10		<=	alp;
	END IF;
END PROCESS;

--//*************************************************************
--//	Column address increment enable
--//*************************************************************
PROCESS (clk,xreset,current_state,rdden)
BEGIN
	IF (xreset = '0') THEN
											cntena <= '0';
											rdy_cntr <= "0000";
											rdyena <= '0';
	ELSIF (clk'EVENT AND clk = '1') THEN

		IF	(( current_state = rdcmd) or ( current_state = wrcmd)) 	THEN
											cntena <= '1';
		ELSE								
											cntena <= '0';
		END IF;
		IF	(( rdden='1') or ( current_state = wrcmd)) 	THEN
											rdyena <= '1';
		ELSIF (rdy_cntr="0010")	THEN								
											rdyena <= '0';
		END IF;
		IF	(rdyena='1') 	THEN
											rdy_cntr <= rdy_cntr + '1';
		ELSE								
											rdy_cntr <= "0000";
		END IF;
	END IF;
END PROCESS;

	cnt_ena	<= cntena;
	sdram_rdy	<= rdyena;
--//*************************************************************
--//	Lower Byte Read Enable   @CL=2 + 1(IOB Register
--//*************************************************************
PROCESS (clk,xreset,current_state)
BEGIN
	IF (xreset = '0') THEN
											rd_ena <= '0';
											rena <= "00000";
	ELSIF (clk'EVENT AND clk = '1') THEN
											rena <= (rena(3 downto 0) & rd_ena);

		IF	( current_state = rdcmd) 	THEN
											rd_ena <= '1';
		ELSE
											rd_ena <= '0';
		END IF;
	END IF;
END PROCESS;

	lbrd_ena <= rdden;

PROCESS (clk,xreset,rena)
BEGIN
	IF (xreset = '0') THEN
											rdden <= '0';
											hbrd_ena <= '0';
--											rd_rdy <= '0';
	ELSIF (clk'EVENT AND clk = '1') THEN
		IF	 (rena(1)='1')	THEN
											rdden <= '1';
		ELSE
											rdden	<= '0';
		END IF;
		IF	 (rena(2)='1')	THEN
											hbrd_ena <= '1';
		ELSE
 											hbrd_ena <= '0';
		END IF;

--		IF	 (rena(3)='1')	THEN
--											rd_rdy <= '1';
--		ELSE
-- 										rd_rdy <= '0';
--		END IF;
	END IF;
END PROCESS;





--//*************************************************************
--//	Upper Byte Write Enable
--//*************************************************************
PROCESS (clk,xreset,current_state,spw_hbe)
BEGIN
	IF (xreset = '0') THEN
											hb_wena <= '0';
											hdqm	<= '0';
	ELSIF (clk'EVENT AND clk = '1') THEN
		IF	( current_state = wrcmd) 	THEN
											hb_wena <= '1';
		ELSE
											hb_wena <= '0';
		END IF;
		IF	( hb_wena='1' and spw_hbe='1')	THEN
											hdqm	<= '1';
		ELSE
											hdqm	<= '0';
		END IF;
	END IF;
END PROCESS;

	hbw_ena	<= hb_wena;
	o_dqm	<= hdqm & hdqm;		-- 071129 tei

--***************************************
--	SDRAM Write DATA Buffer Enable
--***************************************
PROCESS (clk,xreset,current_state)
BEGIN
	IF	(xreset='0')	THEN
									sdd_enbl <=	(OTHERS=>'1');
	ELSIF (clk 'event and clk = '1') THEN
		IF	( current_state = wrcmd) 	THEN
									sdd_enbl <= (OTHERS=>'0');
		ELSE
									sdd_enbl <=	(OTHERS=>'1');
		END IF;
	END IF;
END PROCESS;


  
END statemachine;

