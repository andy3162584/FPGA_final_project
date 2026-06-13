--******************************************************
-- Date		: 111/07/11
-- Author	: BO-AN,CHEN
-- School	: Daan-Electronics
-- FPGA		: Cyclone III   (EP3C16Q240C8N)
-- Title		: SSD model
-- LES		: /15408
--*******************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity SSD_8 is
	generic(fmax : integer := 5E7);
port(
	--input pin
	clk			:in std_logic;
	rst			:in std_logic;
	flash			:in std_logic_vector(7 downto 0);
	dot			:in std_logic_vector(7 downto 0);
	clk_flash	:in std_logic;
	scan_p		:in std_logic;
	data			:in std_logic_vector(47 downto 0);
	--output pin
	HEX0			:out std_logic_vector(6 downto 0);
	HEX1			:out std_logic_vector(6 downto 0);
	HEX2			:out std_logic_vector(6 downto 0);
	HEX3			:out std_logic_vector(6 downto 0);
	HEX4			:out std_logic_vector(6 downto 0);
	HEX5			:out std_logic_vector(6 downto 0);
	HEX6			:out std_logic_vector(6 downto 0);
	HEX7			:out std_logic_vector(6 downto 0)
);
end SSD_8;
--*******************************************************
architecture beh of SSD_8 is
	function bin_to_7seg(bin : std_logic_vector(5 downto 0)) return std_logic_vector is
	begin
		 case bin is
			  when "000000" => return "1000000"; -- 0
			  when "000001" => return "1111001"; -- 1
			  when "000010" => return "0100100"; -- 2
			  when "000011" => return "0110000"; -- 3
			  when "000100" => return "0011001"; -- 4
			  when "000101" => return "0010010"; -- 5
			  when "000110" => return "0000010"; -- 6
			  when "000111" => return "1111000"; -- 7
			  when "001000" => return "0000000"; -- 8
			  when "001001" => return "0010000"; -- 9
			  when "001010" => return "0001000"; -- A
			  when "001011" => return "0000011"; -- B
			  when "001100" => return "1000110"; -- C
			  when "001101" => return "0100001"; -- D
			  when "001110" => return "0000110"; -- E
			  when "001111" => return "0001110"; -- F
			  when "010000" => return "1000010"; -- G
			  when "010001" => return "0001001"; -- H
			  when "010010" => return "1001111"; -- I
			  when "010011" => return "1110001"; -- J
			  when "010100" => return "0001010"; -- K
			  when "010101" => return "1000111"; -- L
			  when "010110" => return "0101010"; -- M
			  when "010111" => return "0101011"; -- N
			  when "011000" => return "0100011"; -- O
			  when "011001" => return "0001100"; -- P
			  when "011010" => return "0011000"; -- Q
			  when "011011" => return "1011111"; -- R
			  when "011100" => return "0010010"; -- S
			  when "011101" => return "0000111"; -- T
			  when "011110" => return "0000001"; -- U
			  when "011111" => return "1110011"; -- V
			  when "100000" => return "1010101"; -- W
			  when "100001" => return "0110110"; -- X
			  when "100010" => return "0010001"; -- Y
			  when "100011" => return "0100100"; -- Z
			  when "100100" => return "0111111"; -- -
			  when "100101" => return "0011100"; -- *
			  when "100110" => return "0101101"; -- /
			  when others   => return "1111111"; -- none
		 end case;
	end function;
	signal scan_cnt	:integer range 0 to 7;
begin
	----------------------------------------------------
	--SSD scan
	process(clk,rst)
	begin
		if(rst = '0')then
			scan_cnt <= 0;
		elsif(clk'event and clk='1')then
			if(scan_p = '1')then
				if(scan_cnt < 7)then
					scan_cnt <= scan_cnt + 1;
				else
					scan_cnt <= 0;
				end if;
			end if;
		end if;
	end process;
	----------------------------------------------------
	--SSD display
	HEX0 <= bin_to_7seg(data(5 downto 0))   when (flash(0) = '0' or clk_flash = '1') else "1111111";
	HEX1 <= bin_to_7seg(data(11 downto 6))  when (flash(1) = '0' or clk_flash = '1') else "1111111";
	HEX2 <= bin_to_7seg(data(17 downto 12)) when (flash(2) = '0' or clk_flash = '1') else "1111111";
	HEX3 <= bin_to_7seg(data(23 downto 18)) when (flash(3) = '0' or clk_flash = '1') else "1111111";
	HEX4 <= bin_to_7seg(data(29 downto 24)) when (flash(4) = '0' or clk_flash = '1') else "1111111";
	HEX5 <= bin_to_7seg(data(35 downto 30)) when (flash(5) = '0' or clk_flash = '1') else "1111111";
	HEX6 <= bin_to_7seg(data(41 downto 36)) when (flash(6) = '0' or clk_flash = '1') else "1111111";
	HEX7 <= bin_to_7seg(data(47 downto 42)) when (flash(7) = '0' or clk_flash = '1') else "1111111";
	
end beh;




