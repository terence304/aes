library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_ARITH.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity AES_onboard is
port(
	clr, clk : in std_logic;
	enc : in std_logic;
	key : in std_logic_vector(7 downto 0);
	key_vld : in std_logic;
	data_vld : in std_logic;

	segment_a_i: out std_logic;
    	segment_b_i: out std_logic;
    	segment_c_i: out std_logic;
    	segment_d_i: out std_logic;
    	segment_e_i: out std_logic;
    	segment_f_i: out std_logic;
    	segment_g_i: out std_logic;
	AN : out std_logic_vector(3 downto 0);
	do_rdy : out std_logic);
end AES_onboard;

architecture Behavioral of AES_onboard is

component AES
port(
	clr, clk : in std_logic;
	enc : in std_logic;
	key : in std_logic_vector(255 downto 0);
	key_vld : in std_logic;
	data_vld : in std_logic;
	din : in std_logic_vector(127 downto 0);
	dout : out std_logic_vector(127 downto 0);
	data_rdy : out std_logic);
end component;

signal key_in : std_logic_vector(255 downto 0);
signal key_in247 : std_logic_vector(247 downto 0);
signal dout : std_logic_vector(127 downto 0);

-- seg
signal LED_flash_cnt : std_logic_vector(9 downto 0);
signal hex_digit_i : std_logic_vector(3 downto 0);

-- dcm
signal LOCKED,nenc : std_logic;
signal clk_50 : std_logic;
signal clk_125 : std_logic;

signal din :std_logic_vector(127 downto 0);
signal data_rdy : std_logic;

type StateType is (ST_IDLE, ST_key_pulse, ST_run, ST_ready);
signal state: StateType;

-- ICON
  component icon
	  port(
	 CONTROL0: inout std_logic_vector(35 downto 0));
  end component;

    signal CONTROL0 : std_logic_vector(35 downto 0);

-- ILA
  component ila
	  port(
	  CONTROL: inout std_logic_vector(35 downto 0);
    	  CLK: in std_logic;
    	  TRIG0: in std_logic_vector(7 downto 0));
  end component;

  signal TRIG0: std_logic_vector(7 downto 0);

begin

din <= (others => '0');
key_in247 <= (others => '0');
Key_in <= key & key_in247;

-- dcm
clkdv : entity work.dcm
	port map(clk,clk_50,clk_125,clr,LOCKED);

nenc <= not enc;

-- instantiate icon
chipscore_icon: icon
port map(CONTROL0);

-- instantiate ila
chipscore_ila: ila
port map(CONTROL0, clk_50, TRIG0);

	TRIG0(0) <= data_vld; 
	TRIG0(1) <= key_vld; 

	with state select
		TRIG0(3 downto 2) <= 
		"00" when ST_IDLE,
		"01" when ST_key_pulse,
		"10" when ST_run,
		"11" when ST_ready;
	
	TRIG0(7 downto 4) <= dout(3 downto 0);

--AES top
u1 : AES port map(clr, clk_50, nenc, key_in, key_vld, data_vld, din, dout, data_rdy);

-- hex2seg
hex2_7seg : entity work.hex_7seg
port map (
hex_digit => hex_digit_i,
segment_a => segment_a_i,
segment_b => segment_b_i,
segment_c => segment_c_i,
segment_d => segment_d_i,
segment_e => segment_e_i,
segment_f => segment_f_i,
segment_g => segment_g_i
);

-- Flash the LED with the last 4 bytes of dout
process (clr, clk_50)
begin
if (clr='1') then
	hex_digit_i <= (others => '0');
	LED_flash_cnt <= (others => '0');
	AN <= (others => '1');
elsif (clk_50'event and clk_50 = '1') then
	LED_flash_cnt <= LED_flash_cnt + '1';
case LED_flash_cnt(9 downto 8) is
when "00" =>
	hex_digit_i <= dout(15 downto 12);
	AN <= "0111";
when "01" =>
	hex_digit_i <= dout(11 downto 8);
	AN <= "1011";
when "10" =>
	hex_digit_i <= dout( 7 downto 4);
	AN <= "1101";
when "11" =>
	hex_digit_i <= dout( 3 downto 0);
	AN <= "1110";
when others => null;
end case;
end if;
end process;

-- process
process(clr, clk_50)
begin
if (clr = '1') then
state <= st_idle;
elsif (clk_50'event and clk_50 = '1') then
case state is
	when st_idle =>
	if (data_vld = '1') then
	state <= st_key_pulse;
	end if;
	when st_key_pulse =>
	if (key_vld = '1') then
	state <= st_run;
	end if;
	when st_run =>
	if (data_rdy = '1') then
	state <= st_ready;
	end if;
	when st_ready =>
		state <= st_idle;
	end case;
end if;
end process;

--do ready
	with state select
		do_rdy<= '0' when ST_READY,
			 '1' when others;

end Behavioral;

