library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RS232 is
	generic (
		CLK_FREQ  : integer := 50000000;
		BAUD_RATE : integer := 9600
	);
	port (
		clk       : in  std_logic;
		rst_n     : in  std_logic;
		key       : in  std_logic; 
		sw        : in  std_logic_vector(3 downto 0);
		uart_rx   : in  std_logic;
		uart_tx   : out std_logic;
		
		rx_ready  : out std_logic;                    
		rx_byte   : out std_logic_vector(7 downto 0)  
	);
end entity RS232;

architecture rtl of RS232 is
	constant BIT_TICK : integer := CLK_FREQ / BAUD_RATE;
	constant HALF_TICK: integer := BIT_TICK / 2; 

	-- UART TX 線路
	signal tx_start : std_logic := '0';
	signal tx_data  : std_logic_vector(7 downto 0) := (others => '0');
	signal tx_busy  : std_logic;
	signal rx_data  : std_logic_vector(7 downto 0) := (others => '0');

	-- KEY 邊緣偵測優化
	signal key_reg      : std_logic := '1';
	signal tx_triggered : std_logic := '0';
	signal val_latch    : std_logic_vector(3 downto 0) := (others => '0');

	-- TX 狀態機
	type tx_state_type is (ST_TX_IDLE, ST_TX_SEND_VAL, ST_TX_SEND_NL);
	signal tx_state : tx_state_type := ST_TX_IDLE;

begin

	rx_byte <= rx_data;

	------------------------------------------------------------------------
	-- 【優化一】加入邊緣偵測，確保手按著不放時不會「連發」
	------------------------------------------------------------------------
	process(clk, rst_n)
	begin
		if rst_n = '0' then
			key_reg      <= '1';
			tx_triggered <= '0';
			val_latch    <= (others => '0');
		elsif rising_edge(clk) then
			key_reg <= key; -- 鎖存前一個時脈的按鍵狀態
			
			-- 當前為 '0' 且前一個時脈為 '1' -> 真正的按下瞬間 (下降沿)
			if (key = '0' and key_reg = '1') then
				val_latch    <= sw; 
				tx_triggered <= '1'; -- 只觸發一個脈衝週期
			else
				tx_triggered <= '0';
			end if;
		end if;
	end process;

	------------------------------------------------------------------------
	-- TX 傳送狀態機 (二進位轉 ASCII 碼)
	------------------------------------------------------------------------
	process(clk, rst_n)
		variable int_val : integer range 0 to 15;
	begin
		if rst_n = '0' then
			tx_state <= ST_TX_IDLE;
			tx_start <= '0';
			tx_data  <= (others => '0');
		elsif rising_edge(clk) then
			tx_start <= '0'; -- 每個時脈週期預設關閉，避免連發
			
			case tx_state is
				when ST_TX_IDLE =>
					if tx_triggered = '1' and tx_busy = '0' then
						int_val := to_integer(unsigned(val_latch)); 
						
						if int_val <= 9 then
							tx_data <= std_logic_vector(to_unsigned(48 + int_val, 8)); -- '0' ~ '9' (0x30~0x39)
						else
							tx_data <= std_logic_vector(to_unsigned(55 + int_val, 8)); -- 'A' ~ 'F' (0x41~0x46)
						end if;
						
						tx_start <= '1';
						tx_state <= ST_TX_SEND_VAL;
					end if;
					
				when ST_TX_SEND_VAL =>
					-- 【關鍵時序修正】必須等到 tx_busy 變成 '1'，代表底層硬體已經確實抓取第一個字元了
					if tx_busy = '1' then
						tx_state <= ST_TX_SEND_NL;
					end if;
					
				when ST_TX_SEND_NL =>
					-- 等第一個字元發送完畢 (tx_busy 回到 '0')，才塞入換行符號
					if tx_busy = '0' then
						tx_data  <= x"0A"; -- '\n'
						tx_start <= '1';
						tx_state <= ST_TX_IDLE; -- 送完換行直接回到 IDLE 等下一次按鍵
					end if;
					
				when others => 
					tx_state <= ST_TX_IDLE;
			end case;
		end if;
	end process;
	------------------------------------------------------------------------
	-- 底層內嵌：UART TX 實作
	------------------------------------------------------------------------
	process(clk, rst_n)
		variable clk_cnt : integer range 0 to BIT_TICK := 0;
		variable bit_cnt : integer range 0 to 10 := 0;
		variable tx_reg  : std_logic_vector(7 downto 0) := (others => '0');
	begin
		if rst_n = '0' then
			uart_tx <= '1'; tx_busy <= '0'; clk_cnt := 0; bit_cnt := 0;
		elsif rising_edge(clk) then
			if tx_busy = '0' then
				uart_tx <= '1';
				if tx_start = '1' then
					tx_busy <= '1'; tx_reg := tx_data; clk_cnt := 0; bit_cnt := 0;
					uart_tx <= '0'; 
				end if;
			else
				if clk_cnt < BIT_TICK - 1 then
					clk_cnt := clk_cnt + 1;
				else
					clk_cnt := 0;
					if bit_cnt < 8 then
						uart_tx <= tx_reg(bit_cnt); 
						bit_cnt := bit_cnt + 1;
					elsif bit_cnt = 8 then
						uart_tx <= '1'; 
						bit_cnt := bit_cnt + 1;
					else
						tx_busy <= '0';
					end if;
				end if;
			end if;
		end if;
	end process;

	------------------------------------------------------------------------
	-- 底層內嵌：UART RX 實作
	------------------------------------------------------------------------
	process(clk, rst_n)
		variable rx_d0, rx_d1 : std_logic := '1';
		variable rx_flag      : std_logic := '0';
		variable clk_cnt      : integer range 0 to BIT_TICK := 0;
		variable bit_cnt      : integer range 0 to 10 := 0;
		variable rx_reg       : std_logic_vector(7 downto 0) := (others => '0');
	begin
		if rst_n = '0' then
			rx_flag := '0'; clk_cnt := 0; bit_cnt := 0; 
			rx_ready <= '0'; rx_data <= (others => '0');
			rx_d0 := '1'; rx_d1 := '1';
		elsif rising_edge(clk) then
			rx_ready <= '0';
			rx_d1 := rx_d0; rx_d0 := uart_rx; 
			
			if rx_flag = '0' then
				if rx_d1 = '1' and rx_d0 = '0' then
					rx_flag := '1'; 
					clk_cnt := 0; 
					bit_cnt := 0;
				end if;
			else
				if clk_cnt < BIT_TICK - 1 then
					clk_cnt := clk_cnt + 1;
				else
					clk_cnt := 0; 
				end if;

				if clk_cnt = HALF_TICK then
					if bit_cnt = 0 then
						if rx_d1 = '0' then 
							bit_cnt := bit_cnt + 1; 
						else 
							rx_flag := '0'; 
						end if;
					elsif bit_cnt <= 8 then
						rx_reg(bit_cnt-1) := rx_d1;
						bit_cnt := bit_cnt + 1;
					else
						-- 安全同步修正：資料先寫入，下一時脈沿 ready 再觸發
						rx_flag := '0'; 
						rx_ready <= '1'; 
						rx_data <= rx_reg;
					end if;
				end if;
				
			end if;
		end if;
	end process;

end architecture rtl;