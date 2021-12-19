library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity AES is
	port(
	clr, clk : in std_logic;
	enc : in std_logic;
	key : in std_logic_vector(255 downto 0);
	key_vld : in std_logic;
	data_vld : in std_logic;
	din : in std_logic_vector(127 downto 0);
	dout : out std_logic_vector(127 downto 0);
	data_rdy : out std_logic);
end AES;

architecture Behavioral of AES is
component KeyExpansion
	Port ( clr : in std_logic;
	clk : in std_logic;
	key : in std_logic_vector(255 downto 0);
	key_vld : in std_logic;
	key_add : out std_logic_vector(5 downto 0);
	keyex_out : out std_logic_vector(31 downto 0);
	key_rdy : out std_logic);
end component;

component AES_enc
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
	end component;

component AES_dec
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
end component;

COMPONENT keyblock IS
PORT (
	clka : IN STD_LOGIC;
    	wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    	addra : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    	dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    	douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0));
END COMPONENT;

signal key_rdy : std_logic;
signal dout_enc : std_logic_vector(127 downto 0);
signal dout_dec : std_logic_vector(127 downto 0);
signal dec_rdy : std_logic;
signal enc_rdy : std_logic;
signal WEA : STD_LOGIC_VECTOR(0 DOWNTO 0);
signal keyex_in : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal keyex_out1,keyex_out2 : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal keyex_out3,keyex_out4 : STD_LOGIC_VECTOR(31 DOWNTO 0);
signal key_add : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal key_en0,key_en1 : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal key_en2,key_en3 : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal key_de0,key_de1 : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal key_de2,key_de3 : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal ram_add1,ram_add2 : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal ram_add3,ram_add4 : STD_LOGIC_VECTOR(5 DOWNTO 0);
signal r_cnt : std_logic_vector(5 downto 0);
signal s_cnt : std_logic_vector(5 downto 0);
signal i_cnt : std_logic_vector(1 downto 0);

type StateType is (ST_IDLE, st_pre_key, ST_keyex, ST_RUN, ST_ready);
signal state: StateType;

begin
	-- enc key address
	key_en0<= r_cnt;
	key_en1<= r_cnt+ "000001";
	key_en2<= r_cnt+ "000010";
	key_en3<= r_cnt+ "000011";

	-- dec key address
	key_de0<= s_cnt;
	key_de1<= s_cnt+ "000001";
	key_de2<= s_cnt+ "000010";
	key_de3<= s_cnt+ "000011";

--counter
process(clr, clk)
begin
if(clr='1') then
i_cnt <= "00";
elsif (clk'event and clk='1' and state= ST_RUN) then
if (i_cnt = "11") then
i_cnt <= "00";
else
i_cnt <= i_cnt + '1';
end if;
end if;
end process;

--enc round counter
process(clr, clk, i_cnt)
begin
if(clr='1') then
r_cnt <= "000000";
elsif (clk'event and clk='1' and state= ST_RUN) then
	if(i_cnt= "10") then
		if (r_cnt = "111000") then
		r_cnt <= "000000";
		else
		r_cnt <= r_cnt + "000100";
		end if;
	end if;
end if;
end process;

--dec round counter
process(clr, clk, i_cnt)
begin
if(clr='1') then
s_cnt <= "111000";
elsif (clk'event and clk='1' and state= ST_RUN) then
	if(i_cnt= "10") then
		if (s_cnt = "000000") then
		s_cnt <= "111000";
		else
		s_cnt <= s_cnt - "000100";
		end if;
	end if;
end if;
end process;

---- State
process(clr, clk)
begin
if (clr = '1') then
state <= st_idle;
elsif (clk'event and clk = '1') then
case state is
	when st_idle =>
	if (data_vld = '1') then
	state <= st_pre_key;
	end if;
	when st_pre_key =>
	if (key_vld = '1') then
	state <= ST_keyex;
	end if;
	when ST_keyex =>
	if (key_rdy = '1') then
	state <= st_run;
	end if;
	when st_run =>
	if(enc_rdy= '1') then
	state <= st_ready;
	end if;
	when st_ready=>
	state<= st_idle;
end case;
end if;
end process;
WEA <= "1" when state = ST_keyex or state = st_pre_key else
"0";

---- Ram address control
ram_add1 <= key_en0 when WEA = "0" and enc = '1' else
key_de0 when WEA = "0" and enc = '0' else
key_add;
ram_add2 <= key_en1 when WEA = "0" and enc = '1' else
key_de1 when WEA = "0" and enc = '0' else
key_add;
ram_add3 <= key_en2 when WEA = "0" and enc = '1' else
key_de2 when WEA = "0" and enc = '0' else
key_add;
ram_add4 <= key_en3 when WEA = "0" and enc = '1' else
key_de3 when WEA = "0" and enc = '0' else
key_add;

----change WEA
ram_core1 : keyblock PORT MAP (clk,WEA,ram_add1,keyex_in,keyex_out1);
ram_core2 : keyblock PORT MAP (clk,WEA,ram_add2,keyex_in,keyex_out2);
ram_core3 : keyblock PORT MAP (clk,WEA,ram_add3,keyex_in,keyex_out3);
ram_core4 : keyblock PORT MAP (clk,WEA,ram_add4,keyex_in,keyex_out4);

u1 : KeyExpansion port map(clr, clk, key, key_vld, key_add, keyex_in, key_rdy);

u2 : AES_enc port map(clr,clk,key_rdy,data_vld,din,
keyex_out1,keyex_out2,keyex_out3,keyex_out4,dout_enc,enc_rdy);

u3 : AES_dec port map(clr,clk,key_rdy,data_vld,din,
keyex_out1,keyex_out2,keyex_out3,keyex_out4,dout_dec,dec_rdy);

with enc select
dout <= dout_enc when '1',
dout_dec when others;

with enc select
data_rdy <= enc_rdy when '1',
dec_rdy when others;

end Behavioral;

