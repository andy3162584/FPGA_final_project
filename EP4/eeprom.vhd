library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity eeprom is
    port (
        iCLK         : in    std_logic;
        iRST_N       : in    std_logic;
        
        -- 控制命令 (來自頂層直接對接按鍵狀態)
        iStart_write : in    std_logic;                     
        iStart_read  : in    std_logic;                     
        
        -- 寫入資料
        iW_num0      : in    std_logic_vector(7 downto 0); 
        iW_num1      : in    std_logic_vector(7 downto 0);
        iW_num2      : in    std_logic_vector(7 downto 0);
        iW_num3      : in    std_logic_vector(7 downto 0);
        
        -- 讀出資料
        oR_num0      : out   std_logic_vector(7 downto 0);
        oR_num1      : out   std_logic_vector(7 downto 0);
        oR_num2      : out   std_logic_vector(7 downto 0);
        oR_num3      : out   std_logic_vector(7 downto 0);
        
        -- I2C 總線
        ioI2C_SDAT   : inout std_logic;
        oI2C_SCLK    : out   std_logic;
        oBusy        : out   std_logic
    );
end eeprom;

architecture arch of eeprom is
    -- 狀態機
    type state_type is (ST_IDLE, ST_START, ST_SEND_BYTE, ST_GET_ACK, ST_READ_BYTE, ST_SEND_ACK, ST_STOP, ST_WRITE_DELAY);
    signal state : state_type;

    signal clk_count : integer range 0 to 124 := 0;
    signal i2c_clk   : std_logic := '0';

    -- 傳輸與接收暫存器
    type ram_type is array (0 to 6) of std_logic_vector(7 downto 0);
    signal tx_buffer : ram_type;
    signal rx_buffer : ram_type;

    signal is_read_mode : std_logic := '0'; 
    signal byte_idx     : integer range 0 to 7 := 0;
    signal bit_idx      : integer range 0 to 7 := 7;
    signal scl_en       : std_logic := '0';
    signal sda_out      : std_logic := '1';
    signal sda_mode     : std_logic := '1'; -- '1':輸出, '0':輸入
    signal delay_count  : integer := 0;

begin

    -- 產生 400KHz I2C 時鐘基準
    process(iCLK, iRST_N) begin
        if iRST_N = '0' then clk_count <= 0; i2c_clk <= '0';
        elsif rising_edge(iCLK) then
            if clk_count = 124 then clk_count <= 0; i2c_clk <= not i2c_clk;
            else clk_count <= clk_count + 1; end if;
        end if;
    end process;

    -- I2C 主狀態機 (修正硬體等待時間與讀取時序)
    process(i2c_clk, iRST_N)
        variable sub_step : integer range 0 to 3 := 0;
    begin
        if iRST_N = '0' then
            state <= ST_IDLE; scl_en <= '0'; sda_out <= '1'; sda_mode <= '1';
            byte_idx <= 0; bit_idx <= 7; oBusy <= '0'; delay_count <= 0; sub_step := 0;
            is_read_mode <= '0';
            oR_num0 <= (others => '0'); oR_num1 <= (others => '0');
            oR_num2 <= (others => '0'); oR_num3 <= (others => '0');
        elsif rising_edge(i2c_clk) then
            case state is
                
                when ST_IDLE =>
                    oBusy <= '0'; scl_en <= '0'; sda_out <= '1'; sda_mode <= '1'; sub_step := 0;
                    delay_count <= 0; 
                    
                    if iStart_write = '1' then 
                        oBusy <= '1'; is_read_mode <= '0';
                        tx_buffer(0) <= "10101110"; -- Control (Write)
                        tx_buffer(1) <= "00000000"; -- Addr High
                        tx_buffer(2) <= "00000000"; -- Addr Low
                        tx_buffer(3) <= iW_num0;
                        tx_buffer(4) <= iW_num1;
                        tx_buffer(5) <= iW_num2;
                        tx_buffer(6) <= iW_num3;
                        byte_idx <= 0; state <= ST_START;
                        
                    elsif iStart_read = '1' then 
                        oBusy <= '1'; is_read_mode <= '1';
                        tx_buffer(0) <= "10101110"; -- Control (Write)
                        tx_buffer(1) <= "00000000"; -- Addr High
                        tx_buffer(2) <= "00000000"; -- Addr Low
                        tx_buffer(3) <= "10101111"; -- Control (Read)
                        byte_idx <= 0; state <= ST_START;
                    end if;

                when ST_START => 
                    if sub_step = 0 then sda_mode <= '1'; sda_out <= '1'; scl_en <= '0';
                    elsif sub_step = 2 then sda_out <= '0';
                    elsif sub_step = 3 then scl_en <= '1'; bit_idx <= 7; state <= ST_SEND_BYTE;
                    end if;
                    sub_step := (sub_step + 1) rem 4;

                when ST_SEND_BYTE => 
                    sda_mode <= '1';
                    if sub_step = 0 then sda_out <= tx_buffer(byte_idx)(bit_idx);
                    elsif sub_step = 3 then
                        if bit_idx = 0 then state <= ST_GET_ACK; else bit_idx <= bit_idx - 1; end if;
                    end if;
                    sub_step := (sub_step + 1) rem 4;

                when ST_GET_ACK => 
                    if sub_step = 0 then sda_mode <= '0'; -- 釋放總線聽 ACK
                    elsif sub_step = 3 then
                        if is_read_mode = '0' then 
                            if byte_idx = 6 then state <= ST_STOP;
                            else byte_idx <= byte_idx + 1; bit_idx <= 7; state <= ST_SEND_BYTE; end if;
                        else 
                            if byte_idx < 2 then
                                byte_idx <= byte_idx + 1; bit_idx <= 7; state <= ST_SEND_BYTE;
                            elsif byte_idx = 2 then 
                                byte_idx <= 3; 
                                state <= ST_START; -- 重新發送 Restart 訊號
                            elsif byte_idx = 3 then 
                                byte_idx <= 0; bit_idx <= 7; state <= ST_READ_BYTE; -- 開始讀取第一個 Byte
                            end if;
                        end if;
                    end if;
                    sub_step := (sub_step + 1) rem 4;

                when ST_READ_BYTE => 
                    sda_mode <= '0';
                    if sub_step = 2 then
                        rx_buffer(byte_idx)(bit_idx) <= ioI2C_SDAT; 
                    elsif sub_step = 3 then
                        if bit_idx = 0 then state <= ST_SEND_ACK; else bit_idx <= bit_idx - 1; end if;
                    end if;
                    sub_step := (sub_step + 1) rem 4;

                when ST_SEND_ACK => 
                    sda_mode <= '1';
                    if sub_step = 0 then
                        if byte_idx = 3 then
                            sda_out <= '1'; -- NACK (最後一個位元組，發 NACK 結束讀取)
                        else
                            sda_out <= '0'; -- ACK (繼續讀下一個)
                        end if;
                    elsif sub_step = 3 then
                        if byte_idx = 3 then 
                            state <= ST_STOP; -- 【修正】先去發送 Stop 訊號，不要急著在這裡把資料倒出去
                        else
                            byte_idx <= byte_idx + 1; bit_idx <= 7; state <= ST_READ_BYTE;
                        end if;
                    end if;
                    sub_step := (sub_step + 1) rem 4;

                when ST_STOP => 
                    if sub_step = 0 then sda_mode <= '1'; sda_out <= '0';
                    elsif sub_step = 1 then scl_en <= '0';
                    elsif sub_step = 2 then sda_out <= '1';
                    elsif sub_step = 3 then
                        if is_read_mode = '0' then 
                            state <= ST_WRITE_DELAY; -- 寫入模式：進入物理燒錄延遲
                        else 
                            -- 【修正】讀取模式在 Stop 訊號完全產生後，安全地把暫存器資料倒給頂層
                            oR_num0 <= rx_buffer(0); 
                            oR_num1 <= rx_buffer(1);
                            oR_num2 <= rx_buffer(2); 
                            oR_num3 <= rx_buffer(3);
                            state <= ST_IDLE; 
                        end if; 
                    end if;
                    sub_step := (sub_step + 1) rem 4;

                when ST_WRITE_DELAY => 
                    scl_en <= '0';
                    -- 【重大修正】強迫硬體等待至少 10ms (400kHz / 4 sub-steps = 每 10 微秒增加 1)
                    -- 計數到 4000 相當於 40 毫秒，絕對保證 EEPROM 內部硬體燒錄完成！
                    if delay_count >= 4000 then 
                        state <= ST_IDLE; 
                    else 
                        delay_count <= delay_count + 1; 
                    end if;

                when others => state <= ST_IDLE;
            end case;
        end if;
    end process;

    -- 【重大修正】符合真正精確的 I2C 三態開漏（Open-Drain）硬體行為
    oI2C_SCLK <= i2c_clk when (scl_en = '1') else '1';
    ioI2C_SDAT <= '0' when (sda_mode = '1' and sda_out = '0') else 'Z'; 
    
end arch;