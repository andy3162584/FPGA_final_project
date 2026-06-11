--******************************************************
-- Title    : Binary to BCD Conveter_8 bits (時序修正純全正緣版)
--*******************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity bintobcd_8 is
    generic(fmax : integer := 5E7);
port(
    clk         :in std_logic;
    rst         :in std_logic;
    start_pulse :in std_logic;
    bin_in      :in std_logic_vector(7 downto 0);
    bcd_out     :out std_logic_vector(11 downto 0);
    done_pulse  :out std_logic
);
end bintobcd_8;

architecture beh of bintobcd_8 is
    signal bin        :std_logic_vector(7 downto 0);
    signal bcd        :std_logic_vector(11 downto 0);
    
    type states is (s_idle, s0, s1, s2, s3, s4, s5, s6, s7, s8);
    signal ps, ns, nns   : states;
    signal flag_start    : std_logic;
begin

    -- 狀態暫存器移轉 (全面同步使用正緣，拒絕正負緣打架)
    process(clk, rst)
    begin
        if(rst = '0') then
            ps <= s_idle;
        elsif rising_edge(clk) then
            ps <= ns;
        end if;
    end process;
    
    -- 組合邏輯與狀態機行為
    process(clk, rst)  
    begin
        if(rst = '0') then 
            bin <= (others => '0');
            bcd <= (others => '0');
            bcd_out <= (others => '0');
            done_pulse <= '0';
            flag_start <= '0';
            ns <= s_idle;
            nns <= s_idle;
        elsif rising_edge(clk) then
            -- 預設清除完成脈衝，確保它只會維持 1 個 Clock 週期 (20ns)
            done_pulse <= '0'; 
            
            if(start_pulse = '1') then
                flag_start <= '1';
                bin <= bin_in;
                bcd <= (others => '0');
                ns <= s0;
            elsif(flag_start = '1') then
                case ps is
                    when s0 =>
                        bcd <= bcd(8 downto 0) & bin(7 downto 5);
                        ns  <= s6;
                        nns <= s1;
                    when s1 =>
                        bcd <= bcd(10 downto 0) & bin(4);
                        ns  <= s6;
                        nns <= s2;
                    when s2 =>
                        bcd <= bcd(10 downto 0) & bin(3);
                        ns  <= s6;
                        nns <= s3;
                    when s3 =>
                        bcd <= bcd(10 downto 0) & bin(2);
                        ns  <= s6;
                        nns <= s4;
                    when s4 =>
                        bcd <= bcd(10 downto 0) & bin(1);
                        ns  <= s6;
                        nns <= s5;
                    when s5 =>
                        bcd <= bcd(10 downto 0) & bin(0);
                        ns  <= s7;
                    when s6 =>
                        -- 這裡必須使用變數或立即條件判斷，優化加 3 演算法
                        if(bcd(3 downto 0) >= 5) then
                            bcd(3 downto 0) <= bcd(3 downto 0) + 3;
                        end if;
                        if(bcd(7 downto 4) >= 5) then
                            bcd(7 downto 4) <= bcd(7 downto 4) + 3;
                        end if;
                        ns <= nns;
                    when s7 => 
                        bcd_out <= bcd;
                        ns  <= s8;
                    when s8 => 
                        done_pulse <= '1'; -- 產生精準 20ns 脈衝
                        flag_start <= '0'; -- 任務結束，關閉 flag
                        ns  <= s_idle;
                    when others => 
                        ns <= s_idle;
                end case;
            else
                ns <= s_idle;
            end if;
        end if;
    end process;

end beh;