library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity KeyExpansion is 
	Port ( 
	clr : in std_logic;
	clk : in std_logic;
	key : in std_logic_vector(255 downto 0);
	key_vld : in std_logic;
	key_add : out std_logic_vector(5 downto 0);
	keyex_out : out std_logic_vector(31 downto 0);
	key_rdy : out std_logic);
end KeyExpansion;

architecture Behavioral of KeyExpansion is

type Rcon is array (integer range 0 to 9) of std_logic_vector(7 downto 0);
constant RCONST: Rcon := (x"01",x"02",x"04",x"08",x"10",x"20",x"40",x"80",x"1b",x"36");

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

signal subxor_cnt : std_logic_vector(2 downto 0);
signal rcon_cnt : std_logic_vector(3 downto 0);
signal sub1,sub2,sub3,sub4 : std_logic_vector(7 downto 0);
signal subxor1,subxor2,subxor3,subxor4 : std_logic_vector(7 downto 0);
signal subxor,sub,temp : std_logic_vector(31 downto 0);
signal w, w_reg, rot_word : std_logic_vector(31 downto 0);
signal i_cnt : std_logic_vector(5 downto 0);
signal wink,wink0,wink1,wink2,wink3,wink4 : std_logic_vector(31 downto 0);
signal wink5,wink6 : std_logic_vector(31 downto 0);
type state_machine is (st_idle, st_key_in, st_key_exp, st_ready);
signal state : state_machine;

begin

w <= key( 31 downto 0) when i_cnt = "000111" else -- w= temp xor w[i-Nk]
key( 63 downto 32) when i_cnt = "000110" else
key( 95 downto 64) when i_cnt = "000101" else
key(127 downto 96) when i_cnt = "000100" else
key(159 downto 128) when i_cnt = "000011" else
key(191 downto 160) when i_cnt = "000010" else
key(223 downto 192) when i_cnt = "000001" else
key(255 downto 224) when i_cnt = "000000" else
wink6 xor temp;

rot_word <= w_reg(23 downto 0) & w_reg(31 downto 24); -- rot_word rotate 8 bits

subxor1 <= SUBBOX(conv_integer(rot_word( 7 downto 4)), conv_integer(rot_word( 3 downto 0)));  -- Subword
subxor2 <= SUBBOX(conv_integer(rot_word(15 downto 12)), conv_integer(rot_word(11 downto 8)));
subxor3 <= SUBBOX(conv_integer(rot_word(23 downto 20)), conv_integer(rot_word(19 downto 16)));
subxor4 <= SUBBOX(conv_integer(rot_word(31 downto 28)), conv_integer(rot_word(27 downto 24)));	

subxor <= ((subxor4 xor RCONST(conv_integer(rcon_cnt))) & subxor3 & subxor2 & subxor1);  --Xor with Rcon

sub1 <= SUBBOX(conv_integer(w_reg( 7 downto 4)), conv_integer(w_reg( 3 downto 0)));
sub2 <= SUBBOX(conv_integer(w_reg(15 downto 12)), conv_integer(w_reg(11 downto 8)));
sub3 <= SUBBOX(conv_integer(w_reg(23 downto 20)), conv_integer(w_reg(19 downto 16)));
sub4 <= SUBBOX(conv_integer(w_reg(31 downto 28)), conv_integer(w_reg(27 downto 24)));
sub <= (sub4 & sub3 & sub2 & sub1);

-- temp
temp <= subxor when subxor_cnt = "000" and (state = st_key_exp) else --i_cnt % 8 =0
sub when subxor_cnt = "100" and (state = st_key_exp) else --i_cnt % 8 =4
w_reg;

keyex_out <= w;

key_add <= i_cnt;
--------------------------------
process(clr, clk, w) 
begin
if(clr = '1') then
wink <= (others => '0');
wink0 <= (others => '0');
wink1 <= (others => '0');
wink2 <= (others => '0');
wink3 <= (others => '0');
wink4 <= (others => '0');
wink5 <= (others => '0');
wink6 <= (others => '0');  -- w[i-Nk]
elsif (clk'event and clk='1') then
wink <= w;
wink0 <= wink;
wink1 <= wink0;
wink2 <= wink1;
wink3 <= wink2;
wink4 <= wink3;
wink5 <= wink4;
wink6 <= wink5;
end if;
end process;
--------------------------------
--w register
process(clr, clk)
begin
if(clr = '1') then
w_reg <= (others => '0'); --initialize areg to all zero's
elsif (clk'event and clk='1') then
w_reg <= w;
end if;
end process;

--rcon_cnt
process(clr, clk, state, subxor_cnt)
begin
if (clr = '1' or state = st_idle) then
rcon_cnt <= "0000";
elsif (clk'event and clk = '1' and state = st_key_exp and subxor_cnt = "111") then
if (rcon_cnt = "1001") then
rcon_cnt <= "0000";
else
rcon_cnt <= rcon_cnt + '1';
end if;
end if;
end process;

--i_cnt
process(clr, clk, state)
begin
if (clr = '1') then
i_cnt <= "000000";
elsif (clk'event and clk = '1' and (state = st_key_in or state = st_key_exp)) then
if (i_cnt = "111011") then
i_cnt <= "000000";
else
i_cnt <= i_cnt + '1';
end if;
end if;
end process;

--subxor_cnt
process(clr, clk, state)
begin
if (clr = '1' or state = st_idle) then
subxor_cnt <= "000";
elsif (clk'event and clk = '1' and state = st_key_exp) then
if (subxor_cnt = "111") then
subxor_cnt <= "000";
else
subxor_cnt <= subxor_cnt + '1';
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
		if(key_vld = '1') then
		state <= st_key_in;
		end if;
	when st_key_in =>
		if (i_cnt = "000111") then
		state <= st_key_exp;
		end if;	
	when st_key_exp =>
		if (i_cnt = "111011") then
		state <= st_ready;
		end if;	
	when st_ready =>
		state <= st_idle;
	end case;
	end if;
end process;

key_rdy <= '1' when state = st_ready 
	       else '0';
end Behavioral;

