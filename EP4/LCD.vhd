library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity LCD is
	generic (
		CLK_Divide : integer := 16  -- 用作基礎時脈除頻
	);
	port (
		-- Host Side
		iDATA    : in  std_logic_vector(7 downto 0);
		iRS      : in  std_logic;
		iStart   : in  std_logic;
		oDone    : out std_logic := '0';
		iCLK     : in  std_logic;
		iRST_N   : in  std_logic;
		
		-- LCD Interface
		LCD_DATA : out std_logic_vector(7 downto 0);
		LCD_RW   : out std_logic;
		LCD_EN   : out std_logic := '0';
		LCD_RS   : out std_logic
	);
end entity LCD;

architecture Behavioral of LCD is
	signal Cont     : integer range 0 to 255 := 0; 
	signal ST       : integer range 0 to 4   := 0; 
	signal preStart : std_logic := '0';
	signal mStart   : std_logic := '0';
begin

	---------------------------------------------
	-- 固定的寫入控制
	---------------------------------------------
	LCD_DATA <= iDATA;
	LCD_RW   <= '0';
	LCD_RS   <= iRS;

	process(iCLK, iRST_N)
	begin
		if iRST_N = '0' then
			oDone    <= '0';
			LCD_EN   <= '0';
			preStart <= '0';
			mStart   <= '0';
			Cont     <= 0;
			ST       <= 0;
		elsif rising_edge(iCLK) then
			-- 正緣偵測 iStart
			preStart <= iStart;
			if preStart = '0' and iStart = '1' then
				mStart <= '1';
				oDone  <= '0'; -- 開始新任務，確保 Done 是低電平
			end if;

			-- 慢速 LCD 驅動狀態機
			if mStart = '1' then
				case ST is
					-- 【狀態 0：建立時間 (Setup Time)】
					when 0 =>
						if Cont < CLK_Divide then
							Cont <= Cont + 1;
						else
							Cont <= 0;
							ST   <= 1;
						end if;

					-- 【狀態 1：拉高 Enable】
					when 1 =>
						LCD_EN <= '1';
						ST     <= 2;

					-- 【狀態 2：維持高電平脈衝 (Pulse Width)】
					when 2 =>
						if Cont < (CLK_Divide * 2) then
							Cont <= Cont + 1;
						else
							Cont <= 0;
							ST   <= 3;
						end if;

					-- 【狀態 3：拉低 Enable】
					when 3 =>
						LCD_EN <= '0';
						ST     <= 4;

					-- 【狀態 4：維持時間 (Hold Time) 與結束確認】
					when 4 =>
						if Cont < CLK_Divide then
							Cont <= Cont + 1;
						else
							Cont   <= 0;
							mStart <= '0';
							oDone  <= '1'; -- 告訴外層：寫入完成
							ST     <= 0;
						end if;

					when others =>
						ST <= 0;
				end case;
			else
				-- 當沒有啟動時，若外層放開 iStart，清除 Done 訊號，完成握手
				if iStart = '0' then
					oDone <= '0';
				end if;
			end if;
		end if;
	end process;

end architecture Behavioral;