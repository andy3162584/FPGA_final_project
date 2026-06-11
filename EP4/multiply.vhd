library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity multiply is
	generic(fmax : integer := 5E7);
port(
	clk         :in std_logic;
	rst         :in std_logic;
	start_pulse	:in std_logic;
	m				:in std_logic_vector(3 downto 0);
	rm				:in std_logic_vector(4 downto 0);
	product		:out std_logic_vector(7 downto 0)
);
end multiply;

architecture beh of multiply is
	type states is(s0,s1,s2,s3,s4);
	signal ps,ns			:states;
	signal p					:std_logic_vector(8 downto 0);
	signal flag_start		:std_logic;
begin
	process(clk,rst) -- (1) State changing
	begin
		if(rst = '0')then      -- Initializations
			ps <= s0;
		elsif(clk'event and clk = '1')then -- Positive-Edge Trigger
			ps <= ns;
		end if;
	end process;
	---------------------------------------------------------
	process(rst,clk) -- (2) Individual state excution sequence
	begin
		if(rst = '0')then      -- Initializations
			ns <= s0;
		elsif(clk'event and clk = '0')then -- Negative-Edge Trigger
			if(start_pulse = '1')then
				flag_start <= '1';
				ns <= s0;
			elsif(flag_start = '1')then
				case ps is
					when s0 =>
						if(m(0) = '1')then
							p <= (rm+p(8 downto 4)) & m;
						else
							p <= '0' & p(8 downto 1);
						end if;
						ns <= s1;
					when s1 =>
						if(m(0) = '1')then
							p <= (rm+p(8 downto 4)) & m;
						else
							p <= '0' & p(8 downto 1);
						end if;
						ns <= s2;
					when s2 =>
						if(m(0) = '1')then
							p <= (rm+p(8 downto 4)) & m;
						else
							p <= '0' & p(8 downto 1);
						end if;
						ns <= s3;
					when s3 =>
						if(m(0) = '1')then
							p <= (rm+p(8 downto 4)) & m;
						else
							p <= '0' & p(8 downto 1);
						end if;
						ns <= s4;
					when s4 =>
						product <= p(7 downto 0);
					when others => ns <= s0;
				end case;
			end if;
		end if;
	end process;
end beh;