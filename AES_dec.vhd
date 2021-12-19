library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity AES_dec is
	port ( clr,clk : in std_logic;
	key_rdy : in std_logic;
	di_vld : in std_logic;
	din : in std_logic_vector(127 downto 0);
	keyex_in0 : in std_logic_vector(31 downto 0);
	keyex_in1 : in std_logic_vector(31 downto 0);
	keyex_in2 : in std_logic_vector(31 downto 0);
	keyex_in3 : in std_logic_vector(31 downto 0);
	dout : out std_logic_vector(127 downto 0);
	do_rdy : out std_logic);
end AES_dec;

architecture Behavioral of AES_dec is

type w_matrix is array (integer range 0 to 3,integer range 0 to 3) of std_logic_vector(7 downto 0);

type sbox is array (integer range 0 to 15, integer range 0 to 15) of std_logic_vector(7 downto 0);
constant INVSUBBOX: sbox := ( ( x"52" , x"09" , x"6a" , x"d5" , x"30" , x"36" , x"a5" , x"38" , x"bf" , x"40" , x"a3" , x"9e" , x"81" , x"f3" , x"d7", x"fb" ) ,
( x"7c" , x"e3" , x"39" , x"82" , x"9b" , x"2f" , x"ff" , x"87" , x"34" , x"8e" , x"43" , x"44" , x"c4" , x"de" , x"e9", x"cb" ) ,
( x"54" , x"7b" , x"94" , x"32" , x"a6" , x"c2" , x"23" , x"3d" , x"ee" , x"4c" , x"95" , x"0b" , x"42" , x"fa" , x"c3", x"4e" ) ,
( x"08" , x"2e" , x"a1" , x"66" , x"28" , x"d9" , x"24" , x"b2" , x"76" , x"5b" , x"a2" , x"49" , x"6d" , x"8b" , x"d1", x"25" ) ,
( x"72" , x"f8" , x"f6" , x"64" , x"86" , x"68" , x"98" , x"16" , x"d4" , x"a4" , x"5c" , x"cc" , x"5d" , x"65" , x"b6", x"92" ) ,
( x"6c" , x"70" , x"48" , x"50" , x"fd" , x"ed" , x"b9" , x"da" , x"5e" , x"15" , x"46" , x"57" , x"a7" , x"8d" , x"9d", x"84" ) ,
( x"90" , x"d8" , x"ab" , x"00" , x"8c" , x"bc" , x"d3" , x"0a" , x"f7" , x"e4" , x"58" , x"05" , x"b8" , x"b3" , x"45", x"06" ) ,
( x"d0" , x"2c" , x"1e" , x"8f" , x"ca" , x"3f" , x"0f" , x"02" , x"c1" , x"af" , x"bd" , x"03" , x"01" , x"13" , x"8a", x"6b" ) ,
( x"3a" , x"91" , x"11" , x"41" , x"4f" , x"67" , x"dc" , x"ea" , x"97" , x"f2" , x"cf" , x"ce" , x"f0" , x"b4" , x"e6", x"73" ) ,
( x"96" , x"ac" , x"74" , x"22" , x"e7" , x"ad" , x"35" , x"85" , x"e2" , x"f9" , x"37" , x"e8" , x"1c" , x"75" , x"df", x"6e" ) ,
( x"47" , x"f1" , x"1a" , x"71" , x"1d" , x"29" , x"c5" , x"89" , x"6f" , x"b7" , x"62" , x"0e" , x"aa" , x"18" , x"be", x"1b" ) ,
( x"fc" , x"56" , x"3e" , x"4b" , x"c6" , x"d2" , x"79" , x"20" , x"9a" , x"db" , x"c0" , x"fe" , x"78" , x"cd" , x"5a", x"f4" ) ,
( x"1f" , x"dd" , x"a8" , x"33" , x"88" , x"07" , x"c7" , x"31" , x"b1" , x"12" , x"10" , x"59" , x"27" , x"80" , x"ec", x"5f" ) ,
( x"60" , x"51" , x"7f" , x"a9" , x"19" , x"b5" , x"4a" , x"0d" , x"2d" , x"e5" , x"7a" , x"9f" , x"93" , x"c9" , x"9c", x"ef" ) ,
( x"a0" , x"e0" , x"3b" , x"4d" , x"ae" , x"2a" , x"f5" , x"b0" , x"c8" , x"eb" , x"bb" , x"3c" , x"83" , x"53" , x"99", x"61" ) ,
( x"17" , x"2b" , x"04" , x"7e" , x"ba" , x"77" , x"d6" , x"26" , x"e1" , x"69" , x"14" , x"63" , x"55" , x"21" , x"0c", x"7d" ));

signal w, w_in, w_reg, w_add, w_sub, w_shift, w_mix : w_matrix := (("00000000","00000000","00000000","00000000"),("00000000","00000000","00000000","00000000"),("00000000","00000000","00000000","00000000"),("00000000","00000000","00000000","00000000"));
signal w_temp1, w_temp2, w_temp3, w_temp4, w_temp5, w_temp6, w_temp7, w_temp8 : std_logic_vector(10 downto 0);
signal w_temp9, w_temp10, w_temp11, w_temp12, w_temp13, w_temp14, w_temp15, w_temp16 : std_logic_vector(10 downto 0);
signal w_temp1t, w_temp2t, w_temp3t, w_temp4t, w_temp5t, w_temp6t, w_temp7t, w_temp8t : std_logic_vector(10 downto 0);
signal w_temp9t, w_temp10t, w_temp11t, w_temp12t, w_temp13t, w_temp14t, w_temp15t, w_temp16t : std_logic_vector(10 downto 0);
signal w_temp1tt, w_temp2tt, w_temp3tt, w_temp4tt, w_temp5tt, w_temp6tt, w_temp7tt, w_temp8tt : std_logic_vector(10 downto 0);
signal w_temp9tt, w_temp10tt, w_temp11tt, w_temp12tt, w_temp13tt, w_temp14tt, w_temp15tt, w_temp16tt : std_logic_vector(10 downto 0);
signal i_cnt : std_logic_vector(1 downto 0);
signal r_cnt : std_logic_vector(3 downto 0);--, addkey_cnt

type StateType is (ST_IDLE, ST_LOAD, ST_PRE_START, ST_START, ST_RUN, ST_RUN2, ST_END, ST_READY);
signal state: StateType;

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
w <= w_add when (state = ST_run and i_cnt= "00") or (state = ST_run2 and i_cnt = "00") or (state = ST_end and i_cnt = "00") or state = ST_start else
w_shift when (state = ST_run and i_cnt= "01") or (state = ST_run2 and i_cnt = "10") or (state = ST_end and i_cnt = "10") else
w_sub when (state = ST_run and i_cnt= "10") or (state = ST_run2 and i_cnt = "11") or (state = ST_end and i_cnt = "11") else
w_mix when (state = ST_run2 and i_cnt= "01") else
w_in;

--invadd key
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

--invSubBytes
w_sub(0,0) <= INVSUBBOX(conv_integer(w_in(0,0)(7 downto 4)),conv_integer(w_in(0,0)(3 downto 0)));
w_sub(1,0) <= INVSUBBOX(conv_integer(w_in(1,0)(7 downto 4)),conv_integer(w_in(1,0)(3 downto 0)));
w_sub(2,0) <= INVSUBBOX(conv_integer(w_in(2,0)(7 downto 4)),conv_integer(w_in(2,0)(3 downto 0)));
w_sub(3,0) <= INVSUBBOX(conv_integer(w_in(3,0)(7 downto 4)),conv_integer(w_in(3,0)(3 downto 0)));
w_sub(0,1) <= INVSUBBOX(conv_integer(w_in(0,1)(7 downto 4)),conv_integer(w_in(0,1)(3 downto 0)));
w_sub(1,1) <= INVSUBBOX(conv_integer(w_in(1,1)(7 downto 4)),conv_integer(w_in(1,1)(3 downto 0)));
w_sub(2,1) <= INVSUBBOX(conv_integer(w_in(2,1)(7 downto 4)),conv_integer(w_in(2,1)(3 downto 0)));
w_sub(3,1) <= INVSUBBOX(conv_integer(w_in(3,1)(7 downto 4)),conv_integer(w_in(3,1)(3 downto 0)));
w_sub(0,2) <= INVSUBBOX(conv_integer(w_in(0,2)(7 downto 4)),conv_integer(w_in(0,2)(3 downto 0)));
w_sub(1,2) <= INVSUBBOX(conv_integer(w_in(1,2)(7 downto 4)),conv_integer(w_in(1,2)(3 downto 0)));
w_sub(2,2) <= INVSUBBOX(conv_integer(w_in(2,2)(7 downto 4)),conv_integer(w_in(2,2)(3 downto 0)));
w_sub(3,2) <= INVSUBBOX(conv_integer(w_in(3,2)(7 downto 4)),conv_integer(w_in(3,2)(3 downto 0)));
w_sub(0,3) <= INVSUBBOX(conv_integer(w_in(0,3)(7 downto 4)),conv_integer(w_in(0,3)(3 downto 0)));
w_sub(1,3) <= INVSUBBOX(conv_integer(w_in(1,3)(7 downto 4)),conv_integer(w_in(1,3)(3 downto 0)));
w_sub(2,3) <= INVSUBBOX(conv_integer(w_in(2,3)(7 downto 4)),conv_integer(w_in(2,3)(3 downto 0)));
w_sub(3,3) <= INVSUBBOX(conv_integer(w_in(3,3)(7 downto 4)),conv_integer(w_in(3,3)(3 downto 0)));

--invShiftRows
w_shift(0,0) <= w_in(0,0);
w_shift(0,1) <= w_in(0,1);
w_shift(0,2) <= w_in(0,2);
w_shift(0,3) <= w_in(0,3);
w_shift(1,0) <= w_in(1,3);
w_shift(1,1) <= w_in(1,0);
w_shift(1,2) <= w_in(1,1);
w_shift(1,3) <= w_in(1,2);
w_shift(2,0) <= w_in(2,2);
w_shift(2,1) <= w_in(2,3);
w_shift(2,2) <= w_in(2,0);
w_shift(2,3) <= w_in(2,1);
w_shift(3,0) <= w_in(3,1);
w_shift(3,1) <= w_in(3,2);
w_shift(3,2) <= w_in(3,3);
w_shift(3,3) <= w_in(3,0);

--invMixColumns
w_temp1 <="00" & w_in(0,0) & '0' xor
'0' & w_in(0,0) & "00" xor
w_in(0,0) & "000" xor
w_in(1,0) & "000" xor
"00" & w_in(1,0) & '0' xor
"000" & w_in(1,0) xor
w_in(2,0) & "000" xor
'0' & w_in(2,0) & "00" xor
"000" & w_in(2,0) xor
w_in(3,0) & "000" xor
"000" & w_in(3,0);
w_temp1t <= w_temp1(10 downto 0) xor "10001101100" when w_temp1(10)='1' else  -- 1 0001 1011(9 bits) left shift 2 bits, because temp is 8+3=11 bits, so 11-(9)=2 (leftshift)
w_temp1(10 downto 0);
w_temp1tt <= w_temp1t(10 downto 0) xor "01000110110" when w_temp1t(9)='1' else
w_temp1t(10 downto 0);
w_mix(0,0) <= w_temp1tt(7 downto 0) xor "00011011" when w_temp1(8)='1' else
w_temp1tt(7 downto 0);

w_temp2 <= "00" & w_in(1,0) & '0' xor
'0' & w_in(1,0) & "00" xor
w_in(1,0) & "000" xor
w_in(2,0) & "000" xor
"00" & w_in(2,0) & '0' xor
"000" & w_in(2,0) xor
w_in(3,0) & "000" xor
'0' & w_in(3,0) & "00" xor
"000" & w_in(3,0) xor
w_in(0,0) & "000" xor
"000" & w_in(0,0);
w_temp2t <= w_temp2(10 downto 0) xor "10001101100" when w_temp2(10)='1' else
w_temp2(10 downto 0);
w_temp2tt <= w_temp2t(10 downto 0) xor "01000110110" when w_temp2t(9)='1' else
w_temp2t(10 downto 0);
w_mix(1,0) <= w_temp2tt(7 downto 0) xor "00011011" when w_temp2tt(8)='1' else
w_temp2tt(7 downto 0);

w_temp3 <= "00" & w_in(2,0) & '0' xor
'0' & w_in(2,0) & "00" xor
w_in(2,0) & "000" xor
w_in(3,0) & "000" xor
"00" & w_in(3,0) & '0' xor
"000" & w_in(3,0) xor
w_in(0,0) & "000" xor
'0' & w_in(0,0) & "00" xor
"000" & w_in(0,0) xor
w_in(1,0) & "000" xor
"000" & w_in(1,0);
w_temp3t <= w_temp3(10 downto 0) xor "10001101100" when w_temp3(10)='1' else
w_temp3(10 downto 0);
w_temp3tt <= w_temp3t(10 downto 0) xor "01000110110" when w_temp3t(9)='1' else
w_temp3t(10 downto 0);
w_mix(2,0) <= w_temp3tt(7 downto 0) xor "00011011" when w_temp3tt(8)='1' else
w_temp3tt(7 downto 0);

w_temp4 <= "00" & w_in(3,0) & '0' xor
'0' & w_in(3,0) & "00" xor
w_in(3,0) & "000" xor
w_in(0,0) & "000" xor
"00" & w_in(0,0) & '0' xor
"000" & w_in(0,0) xor
w_in(1,0) & "000" xor
'0' & w_in(1,0) & "00" xor
"000" & w_in(1,0) xor
w_in(2,0) & "000" xor
"000" & w_in(2,0);
w_temp4t <= w_temp4(10 downto 0) xor "10001101100" when w_temp4(10)='1' else
w_temp4(10 downto 0);
w_temp4tt <= w_temp4t(10 downto 0) xor "01000110110" when w_temp4t(9)='1' else
w_temp4t(10 downto 0);
w_mix(3,0) <= w_temp4tt(7 downto 0) xor "00011011" when w_temp4tt(8)='1' else
w_temp4tt(7 downto 0);

w_temp5 <="00" & w_in(0,1) & '0' xor
'0' & w_in(0,1) & "00" xor
w_in(0,1) & "000" xor
w_in(1,1) & "000" xor
"00" & w_in(1,1) & '0' xor
"000" & w_in(1,1) xor
w_in(2,1) & "000" xor
'0' & w_in(2,1) & "00" xor
"000" & w_in(2,1) xor
w_in(3,1) & "000" xor
"000" & w_in(3,1);
w_temp5t <= w_temp5(10 downto 0) xor "10001101100" when w_temp5(10)='1' else
w_temp5(10 downto 0);
w_temp5tt <= w_temp5t(10 downto 0) xor "01000110110" when w_temp5t(9)='1' else
w_temp5t(10 downto 0);
w_mix(0,1) <= w_temp5tt(7 downto 0) xor "00011011" when w_temp5(8)='1' else
w_temp5tt(7 downto 0);

w_temp6 <= "00" & w_in(1,1) & '0' xor
'0' & w_in(1,1) & "00" xor
w_in(1,1) & "000" xor
w_in(2,1) & "000" xor
"00" & w_in(2,1) & '0' xor
"000" & w_in(2,1) xor
w_in(3,1) & "000" xor
'0' & w_in(3,1) & "00" xor
"000" & w_in(3,1) xor
w_in(0,1) & "000" xor
"000" & w_in(0,1);
w_temp6t <= w_temp6(10 downto 0) xor "10001101100" when w_temp6(10)='1' else
w_temp6(10 downto 0);
w_temp6tt <= w_temp6t(10 downto 0) xor "01000110110" when w_temp6t(9)='1' else
w_temp6t(10 downto 0);
w_mix(1,1) <= w_temp6tt(7 downto 0) xor "00011011" when w_temp6tt(8)='1' else
w_temp6tt(7 downto 0);

w_temp7 <= "00" & w_in(2,1) & '0' xor
'0' & w_in(2,1) & "00" xor
w_in(2,1) & "000" xor
w_in(3,1) & "000" xor
"00" & w_in(3,1) & '0' xor
"000" & w_in(3,1) xor
w_in(0,1) & "000" xor
'0' & w_in(0,1) & "00" xor
"000" & w_in(0,1) xor
w_in(1,1) & "000" xor
"000" & w_in(1,1);
w_temp7t <= w_temp7(10 downto 0) xor "10001101100" when w_temp7(10)='1' else
w_temp7(10 downto 0);
w_temp7tt <= w_temp7t(10 downto 0) xor "01000110110" when w_temp7t(9)='1' else
w_temp7t(10 downto 0);
w_mix(2,1) <= w_temp7tt(7 downto 0) xor "00011011" when w_temp7tt(8)='1' else
w_temp7tt(7 downto 0);

w_temp8 <= "00" & w_in(3,1) & '0' xor
'0' & w_in(3,1) & "00" xor
w_in(3,1) & "000" xor
w_in(0,1) & "000" xor
"00" & w_in(0,1) & '0' xor
"000" & w_in(0,1) xor
w_in(1,1) & "000" xor
'0' & w_in(1,1) & "00" xor
"000" & w_in(1,1) xor
w_in(2,1) & "000" xor
"000" & w_in(2,1);
w_temp8t <= w_temp8(10 downto 0) xor "10001101100" when w_temp8(10)='1' else
w_temp8(10 downto 0);
w_temp8tt <= w_temp8t(10 downto 0) xor "01000110110" when w_temp8t(9)='1' else
w_temp8t(10 downto 0);
w_mix(3,1) <= w_temp8tt(7 downto 0) xor "00011011" when w_temp8tt(8)='1' else
w_temp8tt(7 downto 0);

w_temp9 <="00" & w_in(0,2) & '0' xor
'0' & w_in(0,2) & "00" xor
w_in(0,2) & "000" xor
w_in(1,2) & "000" xor
"00" & w_in(1,2) & '0' xor
"000" & w_in(1,2) xor
w_in(2,2) & "000" xor
'0' & w_in(2,2) & "00" xor
"000" & w_in(2,2) xor
w_in(3,2) & "000" xor
"000" & w_in(3,2);
w_temp9t <= w_temp9(10 downto 0) xor "10001101100" when w_temp9(10)='1' else
w_temp9(10 downto 0);
w_temp9tt <= w_temp9t(10 downto 0) xor "01000110110" when w_temp9t(9)='1' else
w_temp9t(10 downto 0);
w_mix(0,2) <= w_temp9tt(7 downto 0) xor "00011011" when w_temp9(8)='1' else
w_temp9tt(7 downto 0);

w_temp10 <= "00" & w_in(1,2) & '0' xor
'0' & w_in(1,2) & "00" xor
w_in(1,2) & "000" xor
w_in(2,2) & "000" xor
"00" & w_in(2,2) & '0' xor
"000" & w_in(2,2) xor
w_in(3,2) & "000" xor
'0' & w_in(3,2) & "00" xor
"000" & w_in(3,2) xor
w_in(0,2) & "000" xor
"000" & w_in(0,2);
w_temp10t <= w_temp10(10 downto 0) xor "10001101100" when w_temp10(10)='1' else
w_temp10(10 downto 0);
w_temp10tt <= w_temp10t(10 downto 0) xor "01000110110" when w_temp10t(9)='1' else
w_temp10t(10 downto 0);
w_mix(1,2) <= w_temp10tt(7 downto 0) xor "00011011" when w_temp10tt(8)='1' else
w_temp10tt(7 downto 0);

w_temp11 <= "00" & w_in(2,2) & '0' xor
'0' & w_in(2,2) & "00" xor
w_in(2,2) & "000" xor
w_in(3,2) & "000" xor
"00" & w_in(3,2) & '0' xor
"000" & w_in(3,2) xor
w_in(0,2) & "000" xor
'0' & w_in(0,2) & "00" xor
"000" & w_in(0,2) xor
w_in(1,2) & "000" xor
"000" & w_in(1,2);
w_temp11t <= w_temp11(10 downto 0) xor "10001101100" when w_temp11(10)='1' else
w_temp11(10 downto 0);
w_temp11tt <= w_temp11t(10 downto 0) xor "01000110110" when w_temp11t(9)='1' else
w_temp11t(10 downto 0);
w_mix(2,2) <= w_temp11tt(7 downto 0) xor "00011011" when w_temp11tt(8)='1' else
w_temp11tt(7 downto 0);

w_temp12 <= "00" & w_in(3,2) & '0' xor
'0' & w_in(3,2) & "00" xor
w_in(3,2) & "000" xor
w_in(0,2) & "000" xor
"00" & w_in(0,2) & '0' xor
"000" & w_in(0,2) xor
w_in(1,2) & "000" xor
'0' & w_in(1,2) & "00" xor
"000" & w_in(1,2) xor
w_in(2,2) & "000" xor
"000" & w_in(2,2);
w_temp12t <= w_temp12(10 downto 0) xor "10001101100" when w_temp12(10)='1' else
w_temp12(10 downto 0);
w_temp12tt <= w_temp12t(10 downto 0) xor "01000110110" when w_temp12t(9)='1' else
w_temp12t(10 downto 0);
w_mix(3,2) <= w_temp12tt(7 downto 0) xor "00011011" when w_temp12tt(8)='1' else
w_temp12tt(7 downto 0);

w_temp13 <="00" & w_in(0,3) & '0' xor
'0' & w_in(0,3) & "00" xor
w_in(0,3) & "000" xor
w_in(1,3) & "000" xor
"00" & w_in(1,3) & '0' xor
"000" & w_in(1,3) xor
w_in(2,3) & "000" xor
'0' & w_in(2,3) & "00" xor
"000" & w_in(2,3) xor
w_in(3,3) & "000" xor
"000" & w_in(3,3);
w_temp13t <= w_temp13(10 downto 0) xor "10001101100" when w_temp13(10)='1' else
w_temp13(10 downto 0);
w_temp13tt <= w_temp13t(10 downto 0) xor "01000110110" when w_temp13t(9)='1' else
w_temp13t(10 downto 0);
w_mix(0,3) <= w_temp13tt(7 downto 0) xor "00011011" when w_temp13(8)='1' else
w_temp13tt(7 downto 0);

w_temp14 <= "00" & w_in(1,3) & '0' xor
'0' & w_in(1,3) & "00" xor
w_in(1,3) & "000" xor
w_in(2,3) & "000" xor
"00" & w_in(2,3) & '0' xor
"000" & w_in(2,3) xor
w_in(3,3) & "000" xor
'0' & w_in(3,3) & "00" xor
"000" & w_in(3,3) xor
w_in(0,3) & "000" xor
"000" & w_in(0,3);
w_temp14t <= w_temp14(10 downto 0) xor "10001101100" when w_temp14(10)='1' else
w_temp14(10 downto 0);
w_temp14tt <= w_temp14t(10 downto 0) xor "01000110110" when w_temp14t(9)='1' else
w_temp14t(10 downto 0);
w_mix(1,3) <= w_temp14tt(7 downto 0) xor "00011011" when w_temp14tt(8)='1' else
w_temp14tt(7 downto 0);

w_temp15 <= "00" & w_in(2,3) & '0' xor
'0' & w_in(2,3) & "00" xor
w_in(2,3) & "000" xor
w_in(3,3) & "000" xor
"00" & w_in(3,3) & '0' xor
"000" & w_in(3,3) xor
w_in(0,3) & "000" xor
'0' & w_in(0,3) & "00" xor
"000" & w_in(0,3) xor
w_in(1,3) & "000" xor
"000" & w_in(1,3);
w_temp15t <= w_temp15(10 downto 0) xor "10001101100" when w_temp15(10)='1' else
w_temp15(10 downto 0);
w_temp15tt <= w_temp15t(10 downto 0) xor "01000110110" when w_temp15t(9)='1' else
w_temp15t(10 downto 0);
w_mix(2,3) <= w_temp15tt(7 downto 0) xor "00011011" when w_temp15tt(8)='1' else
w_temp15tt(7 downto 0);

w_temp16 <= "00" & w_in(3,3) & '0' xor
'0' & w_in(3,3) & "00" xor
w_in(3,3) & "000" xor
w_in(0,3) & "000" xor
"00" & w_in(0,3) & '0' xor
"000" & w_in(0,3) xor
w_in(1,3) & "000" xor
'0' & w_in(1,3) & "00" xor
"000" & w_in(1,3) xor
w_in(2,3) & "000" xor
"000" & w_in(2,3);
w_temp16t <= w_temp16(10 downto 0) xor "10001101100" when w_temp16(10)='1' else
w_temp16(10 downto 0);
w_temp16tt <= w_temp16t(10 downto 0) xor "01000110110" when w_temp16t(9)='1' else
w_temp16t(10 downto 0);
w_mix(3,3) <= w_temp16tt(7 downto 0) xor "00011011" when w_temp16tt(8)='1' else
w_temp16tt(7 downto 0);

--w register
process(clr, clk)
begin
if(clr = '1') then
w_reg <= (("00000000","00000000","00000000","00000000"),("00000000","00000000","00000000","00000000"),("00000000","00000000","00000000","00000000"),("00000000","00000000","00000000","00000000")); --initialize areg to all zero's
elsif (clk'event and clk='1') then
if(state = st_run or state = st_start or state = st_end or state= st_run2) then
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
	if(state = ST_RUN or state = ST_start) then
		if (i_cnt = "10") then
			i_cnt <= "00";
		else
			i_cnt <= i_cnt + '1';
		end if;
	elsif(state= ST_RUN2 or state= ST_end) then
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
elsif (clk'event and clk='1') then
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
	state <= st_PRE_START;
	end if;
	when st_PRE_START =>
	state <= st_START;
	when st_start =>
	state <= st_run;
	when st_run =>
	if (i_cnt = "0010") then
	state <= st_run2;
	end if;
	when st_run2 =>
	if (r_cnt = "1110") then
	state <= st_end;
	end if;
	when st_end =>
	if (i_cnt = "00") then
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
end Behavioral;


