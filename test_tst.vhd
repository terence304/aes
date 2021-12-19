library IEEE;
use IEEE.std_logic_1164.all;
use std.textio.all;
use IEEE.std_logic_textio.all;
use work.txt_util.all;

entity tst_AES is
	end tst_AES;

architecture test_bench of tst_AES is
	component AES port(
	clr, clk : in std_logic;
	enc : in std_logic;
	key : in std_logic_vector(255 downto 0);
	key_vld : in std_logic;
	data_vld : in std_logic;
	din : in std_logic_vector(127 downto 0);
	dout : out std_logic_vector(127 downto 0);
	data_rdy : out std_logic);
	end component;

	signal key_vld, data_vld, data_rdy: std_logic;
	signal clk, clr, enc: std_logic;
       	signal key: std_logic_vector(255 downto 0);
	signal din, dout: std_logic_vector(127 downto 0);

	constant period: time := 10 ns;

begin
	UUT: AES port map(clr, clk, enc, key, key_vld, data_vld, din, dout, data_rdy);

	-- clock process
	clk_gen: process
	begin
		loop
			clk<= '0';
			wait for period/2;
			clk<= '1';
			wait for period/2;
		end loop;
	end process;

	-- reading test vector
FILE_IO: process
	
	file cmdfile: TEXT;       -- Define the file 'handle'
   variable L: Line;         -- Define the line buffer
   variable good: boolean; --status of the read operation

	variable key_test: std_logic_vector(255 downto 0);
	variable din_test: std_logic_vector(127 downto 0);
	variable dout_test: std_logic_vector(127 downto 0);

begin

	-- test encoder
	clr <= '1';
	key <= (others => '0');
	din <= (others => '0');
	enc <= '1';
	key_vld <= '0';
	data_vld<= '1';

	wait for 5*period;
	clr<= '0';
	wait until rising_edge(clk);
        
   print("BEGIN ENCRYPTION");
        
   -- Open the command file
   FILE_OPEN(cmdfile,"AES_256_ECB_TestVectors_MonteCarlo_1_.vec",READ_MODE);
			
   loop
            wait for PERIOD;
                clr <= '0';
                
            if endfile(cmdfile) then  -- Check EOF
                assert false
                    report "End of file encountered; exiting."
                    severity NOTE; 
                exit;
            end if;
				
      readline(cmdfile,L);     -- Read the line
      next when L'length = 0;  -- Skip empty lines
		
		hread(L,key_test,good);     -- Read the key argument as hex value
		assert good
		report "Text I/O read data in error"
		severity error;
		
		hread(L,din_test,good);     -- Read the din argument as hex value
      assert good
      report "Text I/O read data in error"
      severity ERROR;
		
		hread(L, dout_test, good);  -- Read the dout argument
		assert good
		report "Text I/O read data in error"
		severity error;

		enc<= '1';
		wait until rising_edge(clk);
		key<= key_test;
		wait until rising_edge(clk);
		key_vld<= '1';
		wait for 20*period;
		key_vld <= '0';
		din<= din_test;
		wait until rising_edge(clk);
		wait until data_rdy= '1';
		wait until rising_edge(clk);

		if dout /= dout_test then             -- VERIFY THE OUTPUT
			print("Error- compare check failed!");
			print("Expected output= " & hstr(dout_test(63 downto 0)) & "Received output= " & hstr(dout(63 downto 0)));
		end if;

		clr<= '1';
		wait until rising_edge(clk);

	end loop;
	FILE_CLOSE(cmdfile);
	print("======================");



	-- test decryption

	clr <= '1';
	key <= (others => '0');
	din <= (others => '0');
	enc <= '0';
	key_vld <= '0';
	data_vld<= '1';

	wait for 5*period;
	clr<= '0';
	wait until rising_edge(clk);

	print("Begin Decryption");
	print(" ==============================");
                
   -- Open the command file
	
	file_open(cmdfile, "AES_256_ECB_TestVectors_MonteCarlo_1_.vec", read_mode);

	loop
		wait for period;
		clr<= '0';

		if endfile(cmdfile) then   -- Check EOF
			assert false
			report "End of file encountered; exiting."
			severity note;
			exit;
		end if;

		readline(cmdfile,L);     -- Read the line
      next when L'length = 0;  -- Skip empty lines
            
      hread(L,key_test,good);     -- Read the key argument as hex value
      assert good
      report "Text I/O read key error"
      severity ERROR;

      hread(L,din_test,good);     -- Read the din argument as hex value
      assert good
      report "Text I/O read data in error"
      severity ERROR;

      hread(L,dout_test,good);     -- Read the dout argument
      assert good
      report "Text I/O read data out error"
      severity ERROR;

		enc<= '0';
		key<= key_test;
		wait for period;
		key_vld<= '1';
		wait for 20*period;
		key_vld<= '0';
		din<= dout_test;
		wait until rising_edge(clk);
		wait until data_rdy= '1';
		wait until rising_edge(clk);

		if dout /= din_test then   -- VERIFY THE OUTPUT
			print("Error- compare check failed!");
			print("Expected output= " & hstr(din_test(63 downto 0)) & "Received output= " & hstr(dout(63 downto 0)));
		end if;
		
		clr<= '1';
		wait until rising_edge(clk);
	end loop;
	FILE_CLOSE(cmdfile);
	print("Test complete- all test vector pass");
	wait;
	
end process;

end test_bench;	

