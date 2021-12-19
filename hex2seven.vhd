library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;	-- we will use conv_integ

entity hex_7seg is
	port(
		hex_digit : in std_logic_vector(3 downto 0);
		segment_a, segment_b, segment_c, segment_d, segment_e, segment_f, segment_g: out std_logic	
	);
end hex_7seg;

architecture rtl of hex_7seg is
	signal segment_data : std_logic_vector(7 downto 0);
begin
	Process(hex_digit)	-- HEX to 7 segment Decoder for LED Display
	begin			-- HEX-digit is the four bit binary value to display in hexadecimal
		case hex_digit is
			when "0000" =>
				segment_data <= "00000001";
			when "0001" =>
				segment_data <= "01001111";
			when "0010" =>
				segment_data <= "00010010";
			when "0011" =>
				segment_data <= "00000110";
			when "0100" =>
				segment_data <= "01001100";
			when "0101" =>
				segment_data <= "00100100";
			when "0110" =>
				segment_data <= "00100000";
			when "0111" =>
				segment_data <= "00001111";
			when "1000" =>
				segment_data <= "00000000";
			when "1001" =>
				segment_data <= "00000100";
			when "1010" =>
				segment_data <= "00001000";
			when "1011" =>
				segment_data <= "01100000";
			when "1100" =>
				segment_data <= "00110001";
			when "1101" =>
				segment_data <= "01000010";
			when "1110" =>
				segment_data <= "00110000";
			when "1111" =>
				segment_data <= "00111000";
			when others =>
				segment_data <= "11111111";
		end case;
	end process;
	-- extract segment data bits
	-- LED driver circuit
	segment_a <= segment_data(6);
	segment_b <= segment_data(5);
	segment_c <= segment_data(4);
	segment_d <= segment_data(3);
	segment_e <= segment_data(2);
	segment_f <= segment_data(1);
	segment_g <= segment_data(0);
end rtl;



