library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity AES_enc is
	port( clr,clk : in std_logic;
	key_rdy : in std_logic;
	di_vld : in std_logic;
	din : in std_logic_vector(127 downto 0);
	keyex_in0 : in std_logic_vector(31 downto 0);
	keyex_in1 : in std_logic_vector(31 downto 0);
	keyex_in2 : in std_logic_vector(31 downto 0);
	keyex_in3 : in std_logic_vector(31 downto 0);
	dout : out std_logic_vector(127 downto 0);
	do_rdy : out std_logic);
end AES_enc;

architecture rtl of AES_enc is

type w_matrix is array (integer range 0 to 3,integer range 0 to 3) of std_logic_vector(7 downto 0);

type sbox is array (integer range 0 to 15, integer range 0 to 15) of std_logic_vector(7 downto 0);
constant SUBBOX: sbox := ( ( x"63" , x"7c" , x"77" , x"7b" , x"f2" , x"6b" , x"6f" , x"c5" , x"30" , x"01" , x"67" , x"2b" , x"fe" , x"d7", x"ab" , x"76") ,
( x"ca" , x"82" , x"c9" , x"7d" , x"fa" , x"59" , x"47" , x"f0" , x"ad" , x"d4" , x"a2" , x"af" , x"9c" , x"a4", x"72" , x"c0") ,
( x"b7" , x"fd" , x"93" , x"26" , x"36" , x"3f" , x"f7" , x"cc" , x"34" , x"a5" , x"e5" , x"f1" , x"71" , x"d8", x"31" , x"15") ,
( x"04" , x"c7" , x"23" , x"c3" , x"18" , x"96" , x"05" , x"9a" , x"07" , x"12" , x"80" , x"e2" , x"eb" , x"27", x"b2" , x"75") ,
( x"09" , x"83" , x"2c" , x"1a" , x"1b" , x"6e" , x"5a" , x"a0" , x"52" , x"3b" , x"d6" , x"b3" , x"29" , x"e3", x"2f" , x"84") ,
( x"53" , x"d1" , x"00" , x"ed" , x"20" , x"fc" , x"b1" , x"5b" , x"6a" , x"cb" , x"be" , x"39" , x"4a" , x"4c", x"58" , x"cf") ,
( x"d0" , x"ef" , x"aa" , x"fb" , x"43" , x"4d" , x"33" , x"85" , x"45" , x"f9" , x"02" , x"7f" , x"50" , x"3c", x"9f" , x"a8") ,
( x"51" , x"a3" , x"40" , x"8f" , x"92" , x"9d" , x"38" , x"f5" , x"bc" , x"b6" , x"da" , x"21" , x"10" , x"ff", x"f3" , x"d2") ,
( x"cd" , x"0c" , x"13" , x"ec" , x"5f" , x"97" , x"44" , x"17" , x"c4" , x"a7" , x"7e" , x"3d" , x"64" , x"5d", x"19" , x"73") ,
( x"60" , x"81" , x"4f" , x"dc" , x"22" , x"2a" , x"90" , x"88" , x"46" , x"ee" , x"b8" , x"14" , x"de" , x"5e", x"0b" , x"db") ,
( x"e0" , x"32" , x"3a" , x"0a" , x"49" , x"06" , x"24" , x"5c" , x"c2" , x"d3" , x"ac" , x"62" , x"91" , x"95", x"e4" , x"79") ,
( x"e7" , x"c8" , x"37" , x"6d" , x"8d" , x"d5" , x"4e" , x"a9" , x"6c" , x"56" , x"f4" , x"ea" , x"65" , x"7a", x"ae" , x"08") ,
( x"ba" , x"78" , x"25" , x"2e" , x"1c" , x"a6" , x"b4" , x"c6" , x"e8" , x"dd" , x"74" , x"1f" , x"4b" , x"bd", x"8b" , x"8a") ,
( x"70" , x"3e" , x"b5" , x"66" , x"48" , x"03" , x"f6" , x"0e" , x"61" , x"35" , x"57" , x"b9" , x"86" , x"c1", x"1d" , x"9e") ,
( x"e1" , x"f8" , x"98" , x"11" , x"69" , x"d9" , x"8e" , x"94" , x"9b" , x"1e" , x"87" , x"e9" , x"ce" , x"55", x"28" , x"df") ,
( x"8c" , x"a1" , x"89" , x"0d" , x"bf" , x"e6" , x"42" , x"68" , x"41" , x"99" , x"2d" , x"0f" , x"b0" , x"54", x"bb" , x"16"));

type StateType is (ST_IDLE, ST_LOAD, ST_PRE_START, ST_START, ST_RUN, ST_END, ST_READY);

signal state: StateType;
signal w, w_in, w_reg, w_add, w_sub, w_shift, w_mix : w_matrix := (("00000000","00000000","00000000","00000000"),("00000000","00000000","00000000","00000000"),("00000000","00000000","00000000","00000000"),("00000000","00000000","00000000","00000000"));
signal w_temp1, w_temp2, w_temp3, w_temp4, w_temp5, w_temp6, w_temp7, w_temp8 : std_logic_vector(8 downto 0);
signal w_temp9, w_temp10, w_temp11, w_temp12, w_temp13, w_temp14, w_temp15, w_temp16 : std_logic_vector(8 downto 0);
signal i_cnt : std_logic_vector(1 downto 0);
signal r_cnt : std_logic_vector(3 downto 0);--, addkey_cnt

---- on chip scope
--signal control0 : std_logic_vector (35 downto 0);
--signal chipscope_trig : std_logic_vector(7 downto 0);
--
--component ICON_core
--	port (
--	CONTROL0 : inout std_logic_vector(35 downto 0)
--	);
--end component;
--
--component ILA
--	port (
--	CONTROL : inout std_logic_vector(35 downto 0);
--	CLK : in std_logic;
--	TRIG0 : in std_logic_vector(7 downto 0)
--	);
--end component;
--
--
--ICON_inst: ICON_core
--	port map (
--	CONTROL0 => control0 -- INOUT BUS [35:0]
--	);
--
--ILA_inst : ILA
--	port map (
--	CONTROL => control0, -- INOUT BUS (35:0)
--	CLK => CLK, -- IN
--	TRIG0 => chipscope_trig -- IN BUS (7:0)
--	);
--
--with state select
--chipscope_trig(2 downto 0) <= "000" when ST_IDLE,
--			      "001" when ST_PRE_START,
--			      "010" when ST_START,
--			      "011" when ST_RUN,
--			      "100" when ST_END,
--			      "101" when ST_ready,
--			      "111" when others;
--chipscope_trig(6 downto 3) <= r_cnt;
--chipscope_trig(7) <= key_rdy;
---- chipscope_trig(7) <= LOCKED_OUT;

begin

--input MUX
process(state,w_reg,din)
begin
case state is
when (ST_start) =>
w_in(0,0) <= din(127 downto 120);
w_in(1,0) <= din(119 downto 112);
w_in(2,0) <= din(111 downto 104);
w_in(3,0) <= din(103 downto 96);
w_in(0,1) <= din( 95 downto 88);
w_in(1,1) <= din( 87 downto 80);
w_in(2,1) <= din( 79 downto 72);
w_in(3,1) <= din( 71 downto 64);
w_in(0,2) <= din( 63 downto 56);
w_in(1,2) <= din( 55 downto 48);
w_in(2,2) <= din( 47 downto 40);
w_in(3,2) <= din( 39 downto 32);
w_in(0,3) <= din( 31 downto 24);
w_in(1,3) <= din( 23 downto 16);
w_in(2,3) <= din( 15 downto 8);
w_in(3,3) <= din( 7 downto 0);
when others => w_in <= w_reg;
end case;
end process;

--cell MUX
w <= w_add when (state = ST_run and i_cnt= "00") or (state = ST_end and i_cnt = "11") or state = ST_start else
w_sub when (state = ST_run and i_cnt= "01") or (state = ST_end and i_cnt = "01") else
w_shift when (state = ST_run and i_cnt= "10") or (state = ST_end and i_cnt = "10") else
w_mix when (state = ST_run and i_cnt= "11") else
w_in;

--add key
w_add(0,0) <= w_in(0,0) xor keyex_in0(31 downto 24);--skey(addkey_cnt)
w_add(1,0) <= w_in(1,0) xor keyex_in0(23 downto 16);
w_add(2,0) <= w_in(2,0) xor keyex_in0(15 downto 8);
w_add(3,0) <= w_in(3,0) xor keyex_in0( 7 downto 0);
w_add(0,1) <= w_in(0,1) xor keyex_in1(31 downto 24);--skey(addkey_cnt + 1)
w_add(1,1) <= w_in(1,1) xor keyex_in1(23 downto 16);
w_add(2,1) <= w_in(2,1) xor keyex_in1(15 downto 8);
w_add(3,1) <= w_in(3,1) xor keyex_in1( 7 downto 0);
w_add(0,2) <= w_in(0,2) xor keyex_in2(31 downto 24);--skey(addkey_cnt + 2)
w_add(1,2) <= w_in(1,2) xor keyex_in2(23 downto 16);
w_add(2,2) <= w_in(2,2) xor keyex_in2(15 downto 8);
w_add(3,2) <= w_in(3,2) xor keyex_in2( 7 downto 0);
w_add(0,3) <= w_in(0,3) xor keyex_in3(31 downto 24);--skey(addkey_cnt + 3)
w_add(1,3) <= w_in(1,3) xor keyex_in3(23 downto 16);
w_add(2,3) <= w_in(2,3) xor keyex_in3(15 downto 8);
w_add(3,3) <= w_in(3,3) xor keyex_in3( 7 downto 0);

--SubBytes
w_sub(0,0) <= SUBBOX(conv_integer(w_in(0,0)(7 downto 4)),conv_integer(w_in(0,0)(3 downto 0)));
w_sub(1,0) <= SUBBOX(conv_integer(w_in(1,0)(7 downto 4)),conv_integer(w_in(1,0)(3 downto 0)));
w_sub(2,0) <= SUBBOX(conv_integer(w_in(2,0)(7 downto 4)),conv_integer(w_in(2,0)(3 downto 0)));
w_sub(3,0) <= SUBBOX(conv_integer(w_in(3,0)(7 downto 4)),conv_integer(w_in(3,0)(3 downto 0)));
w_sub(0,1) <= SUBBOX(conv_integer(w_in(0,1)(7 downto 4)),conv_integer(w_in(0,1)(3 downto 0)));
w_sub(1,1) <= SUBBOX(conv_integer(w_in(1,1)(7 downto 4)),conv_integer(w_in(1,1)(3 downto 0)));
w_sub(2,1) <= SUBBOX(conv_integer(w_in(2,1)(7 downto 4)),conv_integer(w_in(2,1)(3 downto 0)));
w_sub(3,1) <= SUBBOX(conv_integer(w_in(3,1)(7 downto 4)),conv_integer(w_in(3,1)(3 downto 0)));
w_sub(0,2) <= SUBBOX(conv_integer(w_in(0,2)(7 downto 4)),conv_integer(w_in(0,2)(3 downto 0)));
w_sub(1,2) <= SUBBOX(conv_integer(w_in(1,2)(7 downto 4)),conv_integer(w_in(1,2)(3 downto 0)));
w_sub(2,2) <= SUBBOX(conv_integer(w_in(2,2)(7 downto 4)),conv_integer(w_in(2,2)(3 downto 0)));
w_sub(3,2) <= SUBBOX(conv_integer(w_in(3,2)(7 downto 4)),conv_integer(w_in(3,2)(3 downto 0)));
w_sub(0,3) <= SUBBOX(conv_integer(w_in(0,3)(7 downto 4)),conv_integer(w_in(0,3)(3 downto 0)));
w_sub(1,3) <= SUBBOX(conv_integer(w_in(1,3)(7 downto 4)),conv_integer(w_in(1,3)(3 downto 0)));
w_sub(2,3) <= SUBBOX(conv_integer(w_in(2,3)(7 downto 4)),conv_integer(w_in(2,3)(3 downto 0)));
w_sub(3,3) <= SUBBOX(conv_integer(w_in(3,3)(7 downto 4)),conv_integer(w_in(3,3)(3 downto 0)));

--ShiftRows
w_shift(0,0) <= w_in(0,0);
w_shift(0,1) <= w_in(0,1);
w_shift(0,2) <= w_in(0,2);
w_shift(0,3) <= w_in(0,3);
w_shift(1,0) <= w_in(1,1);
w_shift(1,1) <= w_in(1,2);
w_shift(1,2) <= w_in(1,3);
w_shift(1,3) <= w_in(1,0);
w_shift(2,0) <= w_in(2,2);
w_shift(2,1) <= w_in(2,3);
w_shift(2,2) <= w_in(2,0);
w_shift(2,3) <= w_in(2,1);
w_shift(3,0) <= w_in(3,3);
w_shift(3,1) <= w_in(3,0);
w_shift(3,2) <= w_in(3,1);
w_shift(3,3) <= w_in(3,2);

--MixColumns
w_temp1 <= (w_in(0,0) & '0') xor
((w_in(1,0) & '0') xor ('0' & w_in(1,0))) xor
('0' & w_in(2,0)) xor ('0' & w_in(3,0));
w_mix(0,0) <= w_temp1(7 downto 0) when w_temp1(8)='0' else
w_temp1(7 downto 0) xor "00011011";

w_temp2 <= ('0' & w_in(0,0)) xor (w_in(1,0) & '0') xor
((w_in(2,0) & '0') xor ('0' & w_in(2,0))) xor
('0' & w_in(3,0));
w_mix(1,0) <= w_temp2(7 downto 0) when w_temp2(8)='0' else
w_temp2(7 downto 0) xor "00011011";

w_temp3 <= ('0' & w_in(0,0)) xor ('0' & w_in(1,0)) xor
(w_in(2,0) & '0') xor
((w_in(3,0) & '0') xor ('0' & w_in(3,0)));
w_mix(2,0) <= w_temp3(7 downto 0) when w_temp3(8)='0' else
w_temp3(7 downto 0) xor "00011011";

w_temp4 <= ((w_in(0,0) & '0') xor ('0' & w_in(0,0))) xor
('0' & w_in(1,0)) xor ('0' & w_in(2,0)) xor
(w_in(3,0) & '0');
w_mix(3,0) <= w_temp4(7 downto 0) when w_temp4(8)='0' else
w_temp4(7 downto 0) xor "00011011";

w_temp5 <= (w_in(0,1) & '0') xor
((w_in(1,1) & '0') xor ('0' & w_in(1,1))) xor
('0' & w_in(2,1)) xor ('0' & w_in(3,1));
w_mix(0,1) <= w_temp5(7 downto 0) when w_temp5(8)='0' else
w_temp5(7 downto 0) xor "00011011";

w_temp6 <= ('0' & w_in(0,1)) xor (w_in(1,1) & '0') xor
((w_in(2,1) & '0') xor ('0' & w_in(2,1))) xor
('0' & w_in(3,1));
w_mix(1,1) <= w_temp6(7 downto 0) when w_temp6(8)='0' else
w_temp6(7 downto 0) xor "00011011";

w_temp7 <= ('0' & w_in(0,1)) xor ('0' & w_in(1,1)) xor
(w_in(2,1) & '0') xor
((w_in(3,1) & '0') xor ('0' & w_in(3,1)));
w_mix(2,1) <= w_temp7(7 downto 0) when w_temp7(8)='0' else
w_temp7(7 downto 0) xor "00011011";

w_temp8 <= ((w_in(0,1) & '0') xor ('0' & w_in(0,1))) xor
('0' & w_in(1,1)) xor ('0' & w_in(2,1)) xor
(w_in(3,1) & '0');
w_mix(3,1) <= w_temp8(7 downto 0) when w_temp8(8)='0' else
w_temp8(7 downto 0) xor "00011011";

w_temp9 <= (w_in(0,2) & '0') xor
((w_in(1,2) & '0') xor ('0' & w_in(1,2))) xor
('0' & w_in(2,2)) xor ('0' & w_in(3,2));
w_mix(0,2) <= w_temp9(7 downto 0) when w_temp9(8)='0' else
w_temp9(7 downto 0) xor "00011011";

w_temp10 <= ('0' & w_in(0,2)) xor (w_in(1,2) & '0') xor
((w_in(2,2) & '0') xor ('0' & w_in(2,2))) xor
('0' & w_in(3,2));
w_mix(1,2) <= w_temp10(7 downto 0) when w_temp10(8)='0' else
w_temp10(7 downto 0) xor "00011011";

w_temp11 <= ('0' & w_in(0,2)) xor ('0' & w_in(1,2)) xor
(w_in(2,2) & '0') xor
((w_in(3,2) & '0') xor ('0' & w_in(3,2)));
w_mix(2,2) <= w_temp11(7 downto 0) when w_temp11(8)='0' else
w_temp11(7 downto 0) xor "00011011";

w_temp12 <= ((w_in(0,2) & '0') xor ('0' & w_in(0,2))) xor
('0' & w_in(1,2)) xor ('0' & w_in(2,2)) xor
(w_in(3,2) & '0');
w_mix(3,2) <= w_temp12(7 downto 0) when w_temp12(8)='0' else
w_temp12(7 downto 0) xor "00011011";

w_temp13 <= (w_in(0,3) & '0') xor
((w_in(1,3) & '0') xor ('0' & w_in(1,3))) xor
('0' & w_in(2,3)) xor ('0' & w_in(3,3));
w_mix(0,3) <= w_temp13(7 downto 0) when w_temp13(8)='0' else
w_temp13(7 downto 0) xor "00011011";

w_temp14 <= ('0' & w_in(0,3)) xor (w_in(1,3) & '0') xor
((w_in(2,3) & '0') xor ('0' & w_in(2,3))) xor
('0' & w_in(3,3));
w_mix(1,3) <= w_temp14(7 downto 0) when w_temp14(8)='0' else
w_temp14(7 downto 0) xor "00011011";

w_temp15 <= ('0' & w_in(0,3)) xor ('0' & w_in(1,3)) xor
(w_in(2,3) & '0') xor
((w_in(3,3) & '0') xor ('0' & w_in(3,3)));
w_mix(2,3) <= w_temp15(7 downto 0) when w_temp15(8)='0' else
w_temp15(7 downto 0) xor "00011011";

w_temp16 <= ((w_in(0,3) & '0') xor ('0' & w_in(0,3))) xor
('0' & w_in(1,3)) xor ('0' & w_in(2,3)) xor
(w_in(3,3) & '0');
w_mix(3,3) <= w_temp16(7 downto 0) when w_temp16(8)='0' else
w_temp16(7 downto 0) xor "00011011";

--w register
process(clr, clk)
begin
if(clr = '1') then
w_reg <= (("00000000","00000000","00000000","00000000"),("00000000","00000000","00000000","00000000"),("00000000","00000000","00000000","00000000"),("00000000","00000000","00000000","00000000")); --initialize areg to all zero's
elsif (clk'event and clk='1') then
if(state = st_run or state = st_start or state = st_end) then
w_reg <= w;
end if;
end if;
end process;

--run counter
process(clr, clk)
begin
if(clr='1') then
i_cnt<="00";
elsif (clk'event and clk='1') then
if(state = ST_RUN or state = ST_start or state = ST_end) then
if (i_cnt = "11") then
i_cnt <= "00";
else
i_cnt <= i_cnt + '1';
end if;
end if;
end if;
end process;

--round counter
process(clr, clk, i_cnt)
begin
if(clr='1') then
	r_cnt <= "0000";
elsif (clk'event and clk= '1') then
	if (r_cnt = "1110") then
	r_cnt <= "0000";
	elsif(i_cnt= "01") then
	r_cnt <= r_cnt + '1';
	end if;
end if;
end process;

--state
process(clr, clk)
begin
if (clr = '1') then
state <= st_idle;
elsif (clk'event and clk = '1') then
case state is
	when st_idle =>
	if (di_vld = '1') then
	state <= st_load;
	end if;
	when st_load =>
	if (key_rdy = '1') then
	state <= ST_PRE_START;
	end if;
	when ST_PRE_START =>
	state <= st_start;
	when st_start =>
	state <= st_run;
	when st_run =>
	if (r_cnt = "1110") then
	state <= st_end;
	end if;
	when st_end =>
	if (i_cnt = "11") then
	state <= st_ready;
	end if;
	when st_ready =>
	state <= st_idle;
end case;
end if;
end process;

do_rdy <= '1' when state = st_ready else '0';

dout <= (others => '0') when clr ='1' else
w(0,0) & w(1,0) & w(2,0) & w(3,0) &
w(0,1) & w(1,1) & w(2,1) & w(3,1) &
w(0,2) & w(1,2) & w(2,2) & w(3,2) &
w(0,3) & w(1,3) & w(2,3) & w(3,3);
end rtl;

