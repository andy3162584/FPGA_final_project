library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity bintobcd_4 is
	generic(fmax : integer := 5E7);
port(
	clk         : in std_logic;
	rst         : in std_logic;
	bin_in      : in std_logic_vector(3 downto 0);
	bcd_out     : out std_logic_vector(4 downto 0)
);
end bintobcd_4;

architecture beh of bintobcd_4 is
    signal bin          : std_logic_vector(3 downto 0);
    signal bcd          : std_logic_vector(3 downto 0);
    signal sign_flag    : std_logic;
    signal count        : integer range 0 to 4;
    signal flag_start   : std_logic;
begin
	bin <= bin_in;
	process(clk,rst)
	begin
		if(bin(3) = '1')then
			bcd_out <= '1' & bin(3) & not(bin(2 downto 0));
		else
			bcd_out <= '0' & bin;
		end if;
	end process;
end beh;