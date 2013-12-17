-- SpaceWire Board  DIO,POGO,ETC.....
-- FPGA :XCS3S1000-4ft256
-- SDRAM Controller TOP file
-- DATE '2007-Nov-30
-- VER0.0



library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;


library UNISIM;
use UNISIM.VComponents.all;

---------------------------
entity spw_sdram_top is
port(

	clk				: in	std_logic;-- 96MHz
	xreset			: in	std_logic;
	spw_wr			: in	std_logic;
	spw_rd			: in	std_logic;
	spw_hbe			: in	std_logic;
	spw_adr			: in	std_logic_vector(24 downto 0);
	spw_wdd			: in	std_logic_vector(15 downto 0);
	spw_rdd			: out	std_logic_vector(15 downto 0);
	sdram_cs			: in	std_logic;
	sdram_rdy		: out	std_logic;

-- SDRAM Interface		
	o_cke			: out	std_logic;
	o_xdcs		: out	std_logic;
	o_xdras		: out	std_logic;
	o_xdcas		: out	std_logic;
	o_xdwe		: out	std_logic;
	o_dqm			: out	std_logic_vector(1 downto 0);
	o_sda			: out	std_logic_vector(12 downto 0);
	o_ba			: out	std_logic_vector(1 downto 0);
	sdd			: inout	std_logic_vector(15 downto 0)
	);
end spw_sdram_top;


------------------------------------------------------------------------------
architecture sdramcont of spw_sdram_top is
------------------------------------------------------------------------------
constant	bus_width	: std_logic := '1';--Memory bus 8bit

--*********SIGNAL 06/19
signal		sdramreq	: std_logic;
signal		req			: std_logic_vector(1 downto 0);
signal		spw_req		: std_logic;
signal		spw_wdat	: std_logic_vector(15 downto 0);
signal		o_sdd		: std_logic_vector(15 downto 0);
signal		i_sdd		: std_logic_vector(15 downto 0);
signal		sdd_di		: std_logic_vector(15 downto 0);
signal		sdd_do		: std_logic_vector(15 downto 0);
signal		hbw_ena		: std_logic;
signal		lbrd_ena	: std_logic;
signal		hbrd_ena	: std_logic;
signal		sdd_enbl	: std_logic_vector(15 downto 0);

signal		refreq		: std_logic;
signal		cmdreq		: std_logic;
signal		cmdreg		: std_logic_vector(5 downto 0) ;--[0]=mode,[1]=alp,[2]=ref,[3]=self,[4]=odt,reg[5]=1=on,0=0ff
signal		trfc_reg	: std_logic_vector(3 downto 0) ;--tRFC=66ns (7clk@100MHz)
signal		trcd_reg	: std_logic_vector(1 downto 0) ;--tRCD=20ns (2clk@100MHz)
signal		tras_reg	: std_logic_vector(3 downto 0) ;--tRAS=44ns (5clk@100MHz)
signal		trp_reg		: std_logic_vector(1 downto 0) ;--tRP=15ns (2clk@100mhz)
signal		twr_reg		: std_logic_vector(1 downto 0) ;--tWR=15ns (2clk@100MHz)
signal		blen_reg	: std_logic_vector(3 downto 0) ;--sdram Burst Length
signal		ref_ack		: std_logic;
signal		cmd_ack		: std_logic;
signal		cnt_ena		: std_logic;
signal		sdwr_enbl	: std_logic;
signal		sd_cae		: std_logic;
signal		mode_set	: std_logic;
signal		ap10		: std_logic;
signal		init_end		: std_logic;

signal		mode_adr	: std_logic_vector(12 downto 0);

-- state machine signal
component spw_sdramstate
	port	(
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
	end component;
	


-- sdram mpx address signal
component spw_adrmpx
	port	(
	clk				: in	std_logic;-- 48MHz or 96MHz
	xreset			: in	std_logic;-- Active Low
	spw_adr			: in	std_logic_vector(24 downto 0);
	mode_adr		: in	std_logic_vector(12 downto 0);
	mode_set		: in	std_logic;
	ap10			: in	std_logic;
	cae				: in	std_logic;
	cnt_ena			: in	std_logic;
	adr_load		: in	std_logic;
	bus_width		: in	std_logic;--0=8bit,1=16bit
	o_sda			: out	std_logic_vector(12 downto 0);
	o_ba			: out	std_logic_vector(1 downto 0)
	);
	end component;

-- sdram mpx address signal
component spw_sdraminit
	port	(
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
	end component;




--********************************************************************************************06/19begin
BEGIN

--***************************************
--	spw Address Decode

	sdramreq <= sdram_cs and ( (not spw_rd) or (not spw_wr));

--***************************************
--	spw Request Gen.

PROCESS (clk,xreset)
BEGIN
	IF	(xreset='0')	THEN
											req	<=	"00";
	ELSIF (clk'EVENT and clk = '1') THEN
											req <= (req(0) & sdramreq);
		END IF;
	END PROCESS;

	spw_req	 <= sdramreq and not req(1);


--***************************************
--	spw WriteData

PROCESS (clk,xreset,spw_req)
BEGIN
	IF	(xreset='0')	THEN
											spw_wdat	<=	(OTHERS =>'0');
	ELSIF (clk'EVENT and clk = '1') THEN
			IF	(spw_req='1')	THEN
											spw_wdat	<= spw_wdd;
			ELSE
											spw_wdat	<= spw_wdat;
			END IF;
	END IF;
END PROCESS;


--***************************************
--	spw WriteData 16bit
--***************************************
--	sdd_do <= spw_wdat(15 downto 8) WHEN (hbw_ena='1') ELSE spw_wdat(7 downto 0);
	sdd_do <= spw_wdat; -- 071129 tei


--***************************************
--	SDRAM READ DATA 8bit -> 16bit SWAP

PROCESS (clk,xreset,lbrd_ena,sdd_di)
BEGIN
	IF	(xreset='0')	THEN
											spw_rdd	<=	(OTHERS =>'0');
	ELSIF (clk'EVENT and clk = '1') THEN
		IF	  (lbrd_ena = '1')	THEN
											spw_rdd		<= sdd_di;  -- 071129 tei
--		ELSIF (hbrd_ena = '1')	THEN
--											spw_rdd(15 downto 8)	<= sdd_di;
		END IF;
	END IF;
END PROCESS;

--***************************************
--	SDRAM DATA IOB DFF

PROCESS (clk)
BEGIN
	IF (clk'EVENT AND clk = '1') THEN
								o_sdd	<= sdd_do;
	END IF;
END PROCESS;
PROCESS (clk)
BEGIN
	IF (clk'EVENT AND clk = '1') THEN  -- for sim
--	IF (clk'EVENT AND clk = '0') THEN
								sdd_di	<= i_sdd;
	END IF;
END PROCESS;
		sdram_dq_io0: IOBUF port map	(I=>o_sdd(0), IO=>sdd(0),O=>i_sdd(0), T=>sdd_enbl(0));
		sdram_dq_io1: IOBUF port map	(I=>o_sdd(1), IO=>sdd(1),O=>i_sdd(1), T=>sdd_enbl(1));
		sdram_dq_io2: IOBUF port map	(I=>o_sdd(2), IO=>sdd(2),O=>i_sdd(2), T=>sdd_enbl(2));
		sdram_dq_io3: IOBUF port map	(I=>o_sdd(3), IO=>sdd(3),O=>i_sdd(3), T=>sdd_enbl(3));
		sdram_dq_io4: IOBUF port map	(I=>o_sdd(4), IO=>sdd(4),O=>i_sdd(4), T=>sdd_enbl(4));
		sdram_dq_io5: IOBUF port map	(I=>o_sdd(5), IO=>sdd(5),O=>i_sdd(5), T=>sdd_enbl(5));
		sdram_dq_io6: IOBUF port map	(I=>o_sdd(6), IO=>sdd(6),O=>i_sdd(6), T=>sdd_enbl(6));
		sdram_dq_io7: IOBUF port map	(I=>o_sdd(7), IO=>sdd(7),O=>i_sdd(7), T=>sdd_enbl(7));
		sdram_dq_io8: IOBUF port map	(I=>o_sdd(8), IO=>sdd(8),O=>i_sdd(8), T=>sdd_enbl(8));
		sdram_dq_io9: IOBUF port map	(I=>o_sdd(9), IO=>sdd(9),O=>i_sdd(9), T=>sdd_enbl(9));
		sdram_dq_io10: IOBUF port map	(I=>o_sdd(10), IO=>sdd(10),O=>i_sdd(10), T=>sdd_enbl(10));
		sdram_dq_io11: IOBUF port map	(I=>o_sdd(11), IO=>sdd(11),O=>i_sdd(11), T=>sdd_enbl(11));
		sdram_dq_io12: IOBUF port map	(I=>o_sdd(12), IO=>sdd(12),O=>i_sdd(12), T=>sdd_enbl(12));
		sdram_dq_io13: IOBUF port map	(I=>o_sdd(13), IO=>sdd(13),O=>i_sdd(13), T=>sdd_enbl(13));
		sdram_dq_io14: IOBUF port map	(I=>o_sdd(14), IO=>sdd(14),O=>i_sdd(14), T=>sdd_enbl(14));
		sdram_dq_io15: IOBUF port map	(I=>o_sdd(15), IO=>sdd(15),O=>i_sdd(15), T=>sdd_enbl(15));


--sdram controlller statemachine
statemachine:spw_sdramstate port map
(
		clk			=>	clk,
		xreset		=>	xreset,
		refreq		=>	refreq,
		spwreq		=>	spw_req,
		cmdreq		=>	cmdreq,
		spw_rdwr	=>	spw_wr,
		spw_hbe		=>	spw_hbe,
--		bus_width	=>	bus_width,
		cmdreg		=>	cmdreg,
		trfc_reg	=>	trfc_reg,
		trcd_reg	=>	trcd_reg,
		tras_reg	=>	tras_reg,
		trp_reg		=>	trp_reg,
		twr_reg		=>	twr_reg,
		blen_reg	=>	blen_reg,
		ref_ack		=>	ref_ack,
		cmd_ack		=>	cmd_ack,
		cnt_ena		=>	cnt_ena,
		sdwr_enbl	=>	sdwr_enbl,
		sd_cae		=>	sd_cae,
		mode_set	=>	mode_set,
		ap10		=>	ap10,
		sdd_enbl	=>	sdd_enbl,
		lbrd_ena	=>	lbrd_ena,
		hbrd_ena	=>	hbrd_ena,
		hbw_ena		=>	hbw_ena,
		sdram_rdy	=> sdram_rdy,
		o_cke		=>	o_cke,
		o_xdcs		=>	o_xdcs,
		o_xdras		=>	o_xdras,
		o_xdcas		=>	o_xdcas,
		o_xdwe		=>	o_xdwe,
		o_dqm		=>	o_dqm

);


--address
address :spw_adrmpx		port map
(
		clk			=> clk,
		xreset		=> xreset,
		mode_adr	=>	mode_adr,
		spw_adr		=>	spw_adr(24 downto 0),
		mode_set	=>	mode_set,
		ap10		=>	ap10,
		cae			=>	sd_cae,
		cnt_ena		=>	cnt_ena,
		adr_load	=>	spw_req,
		bus_width	=>	bus_width,
		o_sda		=>	o_sda,
		o_ba		=>	o_ba
		);

--SDRAM Inialize
init_dram :spw_sdraminit		port map
(
		clk			=> clk,
		xreset		=> xreset,
		bus_width	=>	bus_width,
		mode_adr	=>	mode_adr,
		cmd_ack		=>	cmd_ack,

		ref_req		=>	refreq,
		cmd_req		=>	cmdreq,
		cmd_reg		=>	cmdreg,
		init_end	=>	init_end,
		trfc_reg	=>	trfc_reg,
		trcd_reg	=>	trcd_reg,
		tras_reg	=>	tras_reg,
		trp_reg		=>	trp_reg,
		twr_reg		=>	twr_reg,
		blen_reg	=>	blen_reg

		);

END sdramcont;
