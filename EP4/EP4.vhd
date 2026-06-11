--***********************************************
--Title	:final project
--Author	:Chen Bo An
--CPLD	:Cyolone IV E EP4CE115F29C7
--Date	:2026-06-05
--LES		:1601 / 114,480 ( < 1 % )
--***********************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity EP4 is
    generic(
        fmax : integer := 50000000;
        BAUD_RATE : integer := 9600
    );
    port(
        CLOCK_50    :in std_logic;
        SW          :in std_logic_vector(17 downto 0);
        KEY         :in std_logic_vector(3 downto 0);
        uart_rx     :in std_logic;  
        uart_tx     :out std_logic; 
        LEDR        :out std_logic_vector(17 downto 0);
        LEDG        :out std_logic_vector(7 downto 0); 
        HEX0        :out std_logic_vector(6 downto 0);
        HEX1        :out std_logic_vector(6 downto 0);
        HEX2        :out std_logic_vector(6 downto 0);
        HEX3        :out std_logic_vector(6 downto 0);
        HEX4        :out std_logic_vector(6 downto 0);
        HEX5        :out std_logic_vector(6 downto 0);
        HEX6        :out std_logic_vector(6 downto 0);
        HEX7        :out std_logic_vector(6 downto 0);
        LCD_DATA    :out std_logic_vector(7 downto 0);
        LCD_RW      :out std_logic;
        LCD_EN      :out std_logic;
        LCD_RS      :out std_logic
    );
end EP4;
--*******************************************************--
architecture beh of EP4 is
	-------------------------------------------------
	--component
    component SSD_8 is
	port(
		--input pin
		clk				:in std_logic;
		rst				:in std_logic;
		flash			:in std_logic_vector(7 downto 0);
		clk_flash		:in std_logic;
		scan_p			:in std_logic;
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
	end component;
    
	component RS232 is
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
	end component;
    
	component LCD is
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
	end component;
	-------------------------------------------------
	--signal define
   signal rst				:std_logic;
   -- x1 : frequency divider
   signal f_1s, f_1p		:std_logic;
   signal f_2s, f_2p		:std_logic;
   signal f_10s,f_10p	:std_logic;
   signal f_1ks,f_1kp	:std_logic;
   -- x2 : main
   signal mode				:std_logic_vector(1 downto 0) := "00";
	signal reg_mode		:std_logic_vector(1 downto 0) := "00";
	signal mode_change	:std_logic;
   signal mode_unit		:std_logic_vector(1 downto 0);
	signal mode_day		:integer range 0 to 4 := 0;
	-- x3 : HEX
   signal SSD_data		:std_logic_vector(47 downto 0) := (others => '1');
	signal SSD_flash		:std_logic_vector(7 downto 0);
	-- x4 : LCD_DATA
	signal mLCD_ST    	:integer range 0 to 3 := 0;          
	signal mDLY       	:std_logic_vector(17 downto 0) := (others => '0');
	signal mLCD_Start 	:std_logic := '0';
	signal mLCD_DATA  	:std_logic_vector(7 downto 0) := (others => '0');
	signal mLCD_RS    	:std_logic := '0';
	signal mLCD_Done  	:std_logic;
	-- x5 : RS232
	signal r_ready			:std_logic;
   signal r_byte			:std_logic_vector(7 downto 0);
	signal city				:std_logic_vector(127 downto 0);
	signal weather			:std_logic_vector(127 downto 0);
   signal temp				:std_logic_vector(11 downto 0);
	signal hum				:std_logic_vector(7 downto 0);
	signal aqi				:std_logic_vector(3 downto 0);
	signal pm25				:std_logic_vector(11 downto 0);
	signal pm10				:std_logic_vector(11 downto 0);
	type date is array (0 to 4) of std_logic_vector(15 downto 0);
	type max_temp is array (0 to 4) of std_logic_vector(11 downto 0);
	type min_temp is array (0 to 4) of std_logic_vector(11 downto 0);
	type humi is array (0 to 4) of std_logic_vector(7 downto 0);
	type pop is array (0 to 4) of std_logic_vector(7 downto 0);
	signal f_date			:date;
	signal f_max_temp		:max_temp;
	signal f_min_temp		:min_temp;
	signal f_hum			:humi;
	signal f_pop			:pop;
begin
   rst <= KEY(3);
	
   U1 : SSD_8 port map(CLOCK_50, rst, SSD_flash, f_1s, f_1ks, SSD_data, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7);
   U2 : RS232 port map(CLOCK_50, rst, KEY(1), SW(3 downto 0) , uart_rx, uart_tx, r_ready, r_byte);
	U3 : LCD port map (mLCD_DATA, mLCD_RS, mLCD_Start, mLCD_Done, CLOCK_50, rst, LCD_DATA, LCD_RW, LCD_EN, LCD_RS);

--***************************************************************
-- x1 : frequency divider
x1 : block
	signal cnt1, cnt2, cnt3, cnt4 : std_logic_vector(25 downto 0);
begin
	process(CLOCK_50, rst)
	begin
		if (rst = '0') then
			cnt1 <= (others => '0');
			cnt2 <= (others => '0');
			cnt3 <= (others => '0'); 
			cnt4 <= (others => '0'); 
		elsif (CLOCK_50'event and CLOCK_50 = '1') then 
			---- 1Hz ------------------------------------------------------------
			if (cnt1 < fmax / 2 - 1) then
				f_1s <= '0'; 
				f_1p <= '0';
				cnt1 <= cnt1 + 1;
			elsif (cnt1 < fmax / 1 - 1) then
				f_1s <= '1'; 
				f_1p <= '0';
				cnt1 <= cnt1 + 1;
			else
				f_1s <= '0'; 
				f_1p <= '1';
				cnt1 <= (others => '0');
			end if;
			
			---- 2Hz ------------------------------------------------------------
			if (cnt2 < fmax / 4 - 1) then
				f_2s <= '0'; 
				f_2p <= '0';
				cnt2 <= cnt2 + 1;
			elsif (cnt2 < fmax / 2 - 1) then
				f_2s <= '1'; 
				f_2p <= '0';
				cnt2 <= cnt2 + 1;
			else
				f_2s <= '0'; 
				f_2p <= '1';
				cnt2 <= (others => '0');
			end if;
			
			---- 10Hz -----------------------------------------------------------
			if (cnt3 < fmax / 20 - 1) then
				f_10s <= '0'; 
				f_10p <= '0';
				cnt3 <= cnt3 + 1;
			elsif (cnt3 < fmax / 10 - 1) then
				f_10s <= '1'; 
				f_10p <= '0';
				cnt3 <= cnt3 + 1;
			else
				f_10s <= '0'; 
				f_10p <= '1';
				cnt3 <= (others => '0');
			end if;
			
			---- 1kHz -----------------------------------------------------------
			if (cnt4 < fmax / 2000 - 1) then
				f_1ks <= '0'; 
				f_1kp <= '0';
				cnt4  <= cnt4 + 1;
			elsif (cnt4 < fmax / 1000 - 1) then
				f_1ks <= '1'; 
				f_1kp <= '0';
				cnt4  <= cnt4 + 1;
			else
				f_1ks <= '0'; 
				f_1kp <= '1';
				cnt4  <= (others => '0');
			end if;
		end if;
	end process;
end block x1;

--***************************************************************
-- main
x2 : block
	signal key2_dly : std_logic := '1';
begin
	process(CLOCK_50, rst)
	begin
		if(rst = '0') then
			reg_mode     <= "00";
			mode         <= "00";
			mode_unit    <= "00";
			key2_dly     <= '1';
		elsif(CLOCK_50'event and CLOCK_50='1') then
			key2_dly <= KEY(2);

			reg_mode <= SW(17 downto 16);
			
			if(KEY(0) = '0') then
				mode <= reg_mode;
				mode_unit <= "00";
			elsif(KEY(1) = '0') then
				null;
				
			elsif (KEY(2) = '0' and key2_dly = '1') then
				mode_unit <= mode_unit + 1;
				if(mode= "01")then
					if(mode_unit = "10")then
						mode_unit <= "00";
					end if;
				elsif(mode = "10")then
					if(mode_unit = "01")then
						mode_unit <= "00";
					end if;
				elsif(mode = "11")then
					if(mode_unit = "11")then
						mode_unit <= "00";
					end if;
				end if;
			end if;
			
			if(mode = "11")then
				case SW(15 downto 11) is
					when "00001"=>
						mode_day <= 0;
					when "00010" =>
						mode_day <= 1;
					when "00100"=>
						mode_day <= 2;
					when "01000"=>
						mode_day <= 3;
					when "10000"=>
						mode_day <= 4;
					when others=>
				end case;
			end if;
			
			if(reg_mode /= mode)then
				mode_change <= '1';
			else
				mode_change <= '0';
			end if;
			
		end if;
	end process;
end block x2;

--***************************************************************
-- HEX
x3 : block
begin
	process(CLOCK_50,rst)
	begin
		if(rst = '0')then
			SSD_data <= (others => '1');
			SSD_flash <= (others => '0');
		elsif(CLOCK_50'event and CLOCK_50='1')then
			if(reg_mode = "00")then
				SSD_data(47 downto 36) <= "010110"&"000000";	--M0
			elsif(reg_mode = "01")then
				SSD_data(47 downto 36) <= "010110"&"000001";	--M1
			elsif(reg_mode = "10")then
				SSD_data(47 downto 36) <= "010110"&"000010";	--M2
			elsif(reg_mode = "11")then
				SSD_data(47 downto 36) <= "010110"&"000011";	--M3
			end if;
			
			if(mode = "11")then
				case mode_day is
					when 0=>
						SSD_data(35 downto 24) <= "001101" & "000001";
					when 1=>
						SSD_data(35 downto 24) <= "001101" & "000010";
					when 2=>
						SSD_data(35 downto 24) <= "001101" & "000011";
					when 3=>
						SSD_data(35 downto 24) <= "001101" & "000100";
					when 4=>
						SSD_data(35 downto 24) <= "001101" & "000101";
					when others=> 
						SSD_data(35 downto 24) <= "111111" & "111111";
				end case;
			end if;
			
			if(mode_change = '1')then
				SSD_flash <= "11000000";
			else
				SSD_flash <= (others => '0');
			end if;
			
			SSD_data(23 downto 0) <= "00"&f_date(0)(15 downto 12) & "00" & f_max_temp(mode_day)(11 downto 8) & "00" & f_max_temp(mode_day)(7 downto 4) & "00" & f_max_temp(mode_day)(3 downto 0);
		end if;
	end process;
end block x3;

--***************************************************************--
-- x4 : LCD
x4 : block
	constant LCD_LINE1    : integer := 9;                    
	constant LCD_CH_LINE  : integer := LCD_LINE1 + 16;       
	constant LCD_LINE2    : integer := LCD_CH_LINE + 1;      
	constant LUT_SIZE     : integer := LCD_LINE2 + 16;       

	signal LUT_INDEX  : integer range 0 to 63 := 0;          
	signal mLCD_ST    : integer range 0 to 4 := 0; 
	signal mDLY       : std_logic_vector(17 downto 0) := (others => '0');
	
	signal boot_delay : integer range 0 to 100000000 := 0;
	signal is_booted  : std_logic := '0'; 

	signal scroll_clk_cnt : integer range 0 to 15000000 := 0;
	signal scroll_offset  : integer range 0 to 39 := 0;
	signal scroll_index   : integer range 0 to 39 := 0;

	signal lut_out    : std_logic_vector(8 downto 0);
	
	signal lcd_refresh_cnt : integer range 0 to 2 := 0; 
	signal lcd_update_trig : std_logic := '0';
begin

	process(CLOCK_50, rst)
	begin
		if rst = '0' then
			scroll_clk_cnt <= 0; scroll_offset  <= 0;
		elsif rising_edge(CLOCK_50) then
			if is_booted = '1' then
				if scroll_clk_cnt < 15000000 then
					scroll_clk_cnt <= scroll_clk_cnt + 1;
				else
					scroll_clk_cnt <= 0;
					if scroll_offset >= 39 then scroll_offset <= 0;
					else scroll_offset <= scroll_offset + 1;
					end if;
				end if;
			end if;
		end if;
	end process;

	process(CLOCK_50, rst)
	begin
		if rst = '0' then
			lcd_refresh_cnt <= 0; lcd_update_trig <= '0';
		elsif rising_edge(CLOCK_50) then
			if f_10p = '1' then
				if lcd_refresh_cnt < 1 then 
					lcd_refresh_cnt <= lcd_refresh_cnt + 1; lcd_update_trig <= '0';
				else
					lcd_refresh_cnt <= 0; lcd_update_trig <= '1'; 
				end if;
			else
				lcd_update_trig <= '0';
			end if;
		end if;
	end process;

	process(CLOCK_50, rst)
	begin
		if rst = '0' then
			LUT_INDEX  <= 0; 
			mLCD_ST    <= 0; 
			mDLY       <= (others => '0');
			boot_delay <= 0; 
			is_booted  <= '0'; 
			mLCD_Start <= '0';
			mLCD_DATA  <= (others => '0'); 
			mLCD_RS    <= '0';
		elsif rising_edge(CLOCK_50) then
			case mLCD_ST is
				when 0 =>
					mLCD_DATA  <= lut_out(7 downto 0); 
					mLCD_RS <= lut_out(8);
					mLCD_Start <= '1'; 
					mLCD_ST <= 1;
				when 1 =>
					if mLCD_Done = '1' then 
						mLCD_Start <= '0'; 
						mLCD_ST <= 2; 
					end if;
				when 2 =>
					if mDLY < "111111111111111110" then 
						mDLY <= mDLY + 1;
					else mDLY <= (others => '0'); 
						mLCD_ST <= 3; 
					end if;
				when 3 =>
					if LUT_INDEX >= LUT_SIZE - 1 then
						if is_booted = '0' then 
							mLCD_ST <= 4; 
						else
							if lcd_update_trig = '1' then LUT_INDEX <= 8; mLCD_ST <= 0;
							else mLCD_ST <= 3; end if;
						end if;
					else
						LUT_INDEX <= LUT_INDEX + 1; mLCD_ST <= 0;
					end if;
				when 4 =>
					if boot_delay < 100000000 then boot_delay <= boot_delay + 1;
					else boot_delay <= 0; is_booted <= '1'; LUT_INDEX <= 8; mLCD_ST <= 0; end if;
				when others => mLCD_ST <= 0;
			end case;
		end if;
	end process;

	process(LUT_INDEX, scroll_offset, mode, is_booted)
		variable temp_idx : integer;
	begin
		if (is_booted = '1') and (mode = "00") then
			if (LUT_INDEX >= 9 and LUT_INDEX <= 24) then
				temp_idx := (LUT_INDEX - 9) + scroll_offset;
				if temp_idx >= 40 then scroll_index <= temp_idx - 40;
				else scroll_index <= temp_idx; end if;
			else scroll_index <= 0; end if;
		else scroll_index <= 0; end if;
	end process;

	process(LUT_INDEX)
		variable c_val  : integer;
		variable f_val  : integer;
		variable f_tens : integer;
		variable f_ones : integer;
	begin
		case LUT_INDEX is
			when 0 => lut_out <= "000110000";
			when 1 => lut_out <= "000110000";
			when 2 => lut_out <= "000110000";
			when 3 => lut_out <= "000111000";
			when 4 => lut_out <= "000001000";
			when 5 => lut_out <= "000000001";
			when 6 => lut_out <= "000000110";
			when 7 => lut_out <= "000001100";
			
			---------------------------------------------------------
			--line 1
			---------------------------------------------------------
			when 8 => lut_out <= "010000000";
				
			when 9 to 24 =>
				if is_booted = '0' then     
					case LUT_INDEX is
						when 9  => lut_out <= "101010011"; -- 'S'
						when 10 => lut_out <= "101111001"; -- 'y'
						when 11 => lut_out <= "101110011"; -- 's'
						when 12 => lut_out <= "101110100"; -- 't'
						when 13 => lut_out <= "101100101"; -- 'e'
						when 14 => lut_out <= "101101101"; -- 'm'
						when 15 => lut_out <= "100100000"; -- ' '
						when 16 => lut_out <= "101001001"; -- 'I'
						when 17 => lut_out <= "101101110"; -- 'n'
						when 18 => lut_out <= "101101001"; -- 'i'
						when 19 => lut_out <= "101110100"; -- 't'
						when 20 => lut_out <= "101101001"; -- 'i'
						when 21 => lut_out <= "101100001"; -- 'a'
						when 22 => lut_out <= "101101100"; -- 'l'
						when others => lut_out <= "100100000"; 
					end case;
				elsif(mode_change = '1')then
					case reg_mode is
						-- 模式 0: MODE 0
						when "00" =>
							case LUT_INDEX is
								when 9 => lut_out <= "101001101"; -- 'M'
								when 10 => lut_out <= "101001111"; -- 'O'
								when 11 => lut_out <= "101000100"; -- 'D'
								when 12 => lut_out <= "101000101"; -- 'E'
								when 13 => lut_out <= "100100000"; -- ' '
								when 14 => lut_out <= "100110000"; -- '0'
								when others => lut_out <= "100100000";
							end case;

						-- 模式 1: MODE 1
						when "01" =>
							case LUT_INDEX is
								when 9 => lut_out <= "101001101"; -- 'M'
								when 10 => lut_out <= "101001111"; -- 'O'
								when 11 => lut_out <= "101000100"; -- 'D'
								when 12 => lut_out <= "101000101"; -- 'E'
								when 13 => lut_out <= "100100000"; -- ' '
								when 14 => lut_out <= "100110001"; -- '1'
								when others => lut_out <= "100100000";
							end case;

						-- 模式 2: MODE 2
						when "10" =>
							case LUT_INDEX is
								when 9 => lut_out <= "101001101"; -- 'M'
								when 10 => lut_out <= "101001111"; -- 'O'
								when 11 => lut_out <= "101000100"; -- 'D'
								when 12 => lut_out <= "101000101"; -- 'E'
								when 13 => lut_out <= "100100000"; -- ' '
								when 14 => lut_out <= "100110010"; -- '2'
								when others => lut_out <= "100100000";
							end case;

						-- 模式 3: MODE 3
						when "11" =>
							case LUT_INDEX is
								when 9 => lut_out <= "101001101"; -- 'M'
								when 10 => lut_out <= "101001111"; -- 'O'
								when 11 => lut_out <= "101000100"; -- 'D'
								when 12 => lut_out <= "101000101"; -- 'E'
								when 13 => lut_out <= "100100000"; -- ' '
								when 14 => lut_out <= "100110011"; -- '3'
								when others => lut_out <= "100100000";
							end case;
						when others => lut_out <= "100100000";
					end case;
				else
					case mode is
						when "00" =>  -- 模式 0：滾動顯示 "Weather Management System" (0 ~ 39 點陣)
							case scroll_index is
								when 0  => lut_out <= "101010111"; -- 'W'
								when 1  => lut_out <= "101100101"; -- 'e'
								when 2  => lut_out <= "101100001"; -- 'a'
								when 3  => lut_out <= "101110100"; -- 't'
								when 4  => lut_out <= "101101000"; -- 'h'
								when 5  => lut_out <= "101100101"; -- 'e'
								when 6  => lut_out <= "101110010"; -- 'r'
								when 7  => lut_out <= "100100000"; -- ' '
								when 8  => lut_out <= "101001101"; -- 'M'
								when 9  => lut_out <= "101100001"; -- 'a'
								when 10 => lut_out <= "101101110"; -- 'n'
								when 11 => lut_out <= "101100001"; -- 'a'
								when 12 => lut_out <= "101100111"; -- 'g'
								when 13 => lut_out <= "101100101"; -- 'e'
								when 14 => lut_out <= "101101101"; -- 'm'
								when 15 => lut_out <= "101100101"; -- 'e'
								when 16 => lut_out <= "101101110"; -- 'n'
								when 17 => lut_out <= "101110100"; -- 't'
								when 18 => lut_out <= "100100000"; -- ' '
								when 19 => lut_out <= "101010011"; -- 'S'
								when 20 => lut_out <= "101111001"; -- 'y'
								when 21 => lut_out <= "101110011"; -- 's'
								when 22 => lut_out <= "101110100"; -- 't'
								when 23 => lut_out <= "101100101"; -- 'e'
								when 24 => lut_out <= "101101101"; -- 'm'
								when 25 => lut_out <= "100100000"; -- ' '
								when 26 => lut_out <= "100101010"; -- '*'
								when 27 => lut_out <= "100101010"; -- '*'
								when 28 => lut_out <= "100101010"; -- '*'
								when others => lut_out <= "100100000"; -- 剩餘空間留白滾動
							end case;
						when others => 
							case LUT_INDEX is
								when 9  => lut_out <= '1' & city(127 downto 120);
								when 10 => lut_out <= '1' & city(119 downto 112);
								when 11 => lut_out <= '1' & city(111 downto 104);
								when 12 => lut_out <= '1' & city(103 downto 96);
								when 13 => lut_out <= '1' & city(95  downto 88);
								when 14 => lut_out <= '1' & city(87  downto 80);
								when 15 => lut_out <= '1' & city(79  downto 72);
								when 16 => lut_out <= '1' & city(71  downto 64);
								when 17 => lut_out <= '1' & city(63  downto 56);
								when 18 => lut_out <= '1' & city(55  downto 48);
								when 19 => lut_out <= '1' & city(47  downto 40);
								when 20 => lut_out <= '1' & city(39  downto 32);
								when 21 => lut_out <= '1' & city(31  downto 24);
								when 22 => lut_out <= '1' & city(23  downto 16);
								when 23 => lut_out <= '1' & city(15  downto 8);
								when 24 => lut_out <= '1' & city(7   downto 0);
								when others => lut_out <= "100100000";
							end case;
					end case;
				end if;
				
			---------------------------------------------------------
			--line 2
			---------------------------------------------------------
			when 25 => lut_out <= "011000000";

			when 26 to 41 =>
				if is_booted = '0' then     
					case LUT_INDEX is
						when 26 => lut_out <= "101000010"; -- 'B'
						when 27 => lut_out <= "101101111"; -- 'o'
						when 28 => lut_out <= "101101111"; -- 'o'
						when 29 => lut_out <= "101110100"; -- 't'
						when 30 => lut_out <= "101101001"; -- 'i'
						when 31 => lut_out <= "101101110"; -- 'n'
						when 32 => lut_out <= "101100111"; -- 'g'
						when others => lut_out <= "100101110"; -- '.'
					end case;
				else
					if(mode_change = '0')then
						case mode is
							when "01" => -- 僅在城市天氣模式下啟用 KEY(2) 的三合一分流
								case mode_unit is
									-------------------------------------------------------
									-- 1. 顯示攝氏： T:25C  H:60%
									-------------------------------------------------------
									when "00" =>
										case LUT_INDEX is
											when 26 => lut_out <= "101010100"; -- 'T'
											when 27 => lut_out <= "100111010"; -- ':'
											when 28 => lut_out <= "10011" & temp(11 downto 8); 
											when 29 => lut_out <= "10011" & temp(7 downto 4);
											when 30 => lut_out <= "101000011"; -- 'C'
											when 31 => lut_out <= "100100000"; -- ' '
											when 32 => lut_out <= "101001000"; -- 'H'
											when 33 => lut_out <= "100111010"; -- ':'
											when 34 => lut_out <= "10011" & hum(7 downto 4); 
											when 35 => lut_out <= "10011" & hum(3 downto 0);
											when 36 => lut_out <= "100100101"; -- '%'
											when others => lut_out <= "100100000";
										end case;
									
									-------------------------------------------------------
									-- 2. 顯示華氏： T:77F  H:60%
									-------------------------------------------------------
									when "01" =>
										c_val  := (to_integer(unsigned(temp(11 downto 8))) * 10) + to_integer(unsigned(temp(7 downto 4)));
										f_val  := ((c_val * 9) / 5) + 32;
										f_tens := f_val / 10;
										f_ones := f_val rem 10;
										case LUT_INDEX is
											when 26 => lut_out <= "101010100"; -- 'T'
											when 27 => lut_out <= "100111010"; -- ':'
											when 28 => lut_out <= "10011" & std_logic_vector(to_unsigned(f_tens, 4));
											when 29 => lut_out <= "10011" & std_logic_vector(to_unsigned(f_ones, 4));
											when 30 => lut_out <= "101000110"; -- 'F'
											when 31 => lut_out <= "100100000"; -- ' '
											when 32 => lut_out <= "101001000"; -- 'H'
											when 33 => lut_out <= "100111010"; -- ':'
											when 34 => lut_out <= "10011" & hum(7 downto 4); 
											when 35 => lut_out <= "10011" & hum(3 downto 0);
											when 36 => lut_out <= "100100101"; -- '%'
											when others => lut_out <= "100100000";
										end case;

									-------------------------------------------------------
									-- 3. 顯示完整英文字串天氣名字： WEA: CLOUDY    
									-------------------------------------------------------
									when "10" =>
										case LUT_INDEX is
											when 26 => lut_out <= "101010111"; -- 'W'
											when 27 => lut_out <= "101000101"; -- 'E'
											when 28 => lut_out <= "101000001"; -- 'A'
											when 29 => lut_out <= "100111010"; -- ':'
											when 30 => lut_out <= "100100000"; -- ' '
											when 31 => lut_out <= "100100000"; -- ' '
											when 32 => lut_out <= "100100000"; -- ' '
											when 33 => lut_out <= '1' & weather(127 downto 120);
											when 34 => lut_out <= '1' & weather(119 downto 112);
											when 35 => lut_out <= '1' & weather(111 downto 104);
											when 36 => lut_out <= '1' & weather(103 downto 96);
											when 37 => lut_out <= '1' & weather(95  downto 88);
											when 38 => lut_out <= '1' & weather(87  downto 80);
											when 39 => lut_out <= '1' & weather(79  downto 72);
											when 40 => lut_out <= '1' & weather(71  downto 64);
											when 41 => lut_out <= '1' & weather(63  downto 56);
											when others => lut_out <= "100100000";
										end case;
									when others => lut_out <= "100100000";
								end case;
							when "10"=>
								case mode_unit is
									when "00"=>
										case LUT_INDEX is
											when 26 => lut_out <= "101010000"; -- 'P'
											when 27 => lut_out <= "101001101"; -- 'M'
											when 28 => lut_out <= "100110010"; -- '2'
											when 29 => lut_out <= "100101110"; -- '.'
											when 30 => lut_out <= "100110101"; -- '5' 
											when 31 => lut_out <= "100111010"; -- ':'
											when 32 => lut_out <= "10011" & pm25(11 downto 8);
											when 33 => lut_out <= "10011" & pm25(7 downto 4);
											when 34 => lut_out <= "100101110"; -- '.'
											when 35 => lut_out <= "10011" & pm25(3 downto 0);
											when others => lut_out <= "100100000";
										end case;
									when "01"=>
										case LUT_INDEX is
											when 26 => lut_out <= "101010000"; -- 'P'
											when 27 => lut_out <= "101001101"; -- 'M'
											when 28 => lut_out <= "100110001"; -- '1'
											when 29 => lut_out <= "100110000"; -- '0' 
											when 30 => lut_out <= "100111010"; -- ':'
											when 31 => lut_out <= "10011" & pm10(11 downto 8);
											when 32 => lut_out <= "10011" & pm10(7 downto 4);
											when 33 => lut_out <= "100101110"; -- '.'
											when 34 => lut_out <= "10011" & pm10(3 downto 0);
											when others => lut_out <= "100100000";
										end case;
									when others=>
								end case;
							when "11"=>
								
							when others => lut_out <= "100100000";
						end case;
					else
						case reg_mode is
							-- 模式 0: Standby
							when "00" =>
								case LUT_INDEX is
									when 26 => lut_out <= "101010011"; -- 'S'
									when 27 => lut_out <= "101010100"; -- 'T'
									when 28 => lut_out <= "101000001"; -- 'A'
									when 29 => lut_out <= "101001110"; -- 'N'
									when 30 => lut_out <= "101000100"; -- 'D'
									when 31 => lut_out <= "101000010"; -- 'B'
									when 32 => lut_out <= "101011001"; -- 'Y'
									when 33 => lut_out <= "100100000"; -- ' '
									when 34 => lut_out <= "101001101"; -- 'M'
									when 35 => lut_out <= "101001111"; -- 'O'
									when 36 => lut_out <= "101000100"; -- 'D'
									when 37 => lut_out <= "101000101"; -- 'E'
									when others => lut_out <= "100100000";
								end case;

							-- 模式 1: Weather
							when "01" =>
								case LUT_INDEX is
									when 26 => lut_out <= "101010111"; -- 'W'
									when 27 => lut_out <= "101000101"; -- 'E'
									when 28 => lut_out <= "101000001"; -- 'A'
									when 29 => lut_out <= "101010100"; -- 'T'
									when 30 => lut_out <= "101001000"; -- 'H'
									when 31 => lut_out <= "101000101"; -- 'E'
									when 32 => lut_out <= "101010010"; -- 'R'
									when 33 => lut_out <= "100100000"; -- ' '
									when 34 => lut_out <= "101000100"; -- 'D'
									when 35 => lut_out <= "101000001"; -- 'A'
									when 36 => lut_out <= "101010100"; -- 'T'
									when 37 => lut_out <= "101000001"; -- 'A'
									when others => lut_out <= "100100000";
								end case;

							-- mode2 : AQI display
							when "10" =>
								case LUT_INDEX is
									 when 26 => lut_out <= "101000001"; -- 'A'
									 when 27 => lut_out <= "101010001"; -- 'Q'
									 when 28 => lut_out <= "101001001"; -- 'I'
									 when 29 => lut_out <= "100100000"; -- ' ' (SPACE)
									 when 30 => lut_out <= "101000100"; -- 'D'
									 when 31 => lut_out <= "101101001"; -- 'I'
									 when 32 => lut_out <= "101010011"; -- 'S'
									 when 33 => lut_out <= "101010000"; -- 'P'
									 when 34 => lut_out <= "101101100"; -- 'L'
									 when 35 => lut_out <= "101100001"; -- 'A'
									 when 36 => lut_out <= "101011001"; -- 'Y'
									 when others => lut_out <= "100100000"; -- DEFAULT: 空白
								end case;

							-- mode3 : 5 days forecast
							when "11" =>
								case LUT_INDEX is
									  when 26 => lut_out <= "100110101"; -- '5'
									  when 27 => lut_out <= "100100000"; -- ' '
									  when 28 => lut_out <= "101000100"; -- 'D'
									  when 29 => lut_out <= "101000001"; -- 'A'
									  when 30 => lut_out <= "101111001"; -- 'Y'
									  when 31 => lut_out <= "101010011"; -- 'S'
									  when 32 => lut_out <= "100100000"; -- ' '
									  when 33 => lut_out <= "101000110"; -- 'F' (修正編碼)
									  when 34 => lut_out <= "101001111"; -- 'O'
									  when 35 => lut_out <= "101010010"; -- 'R'
									  when 36 => lut_out <= "101000101"; -- 'E'
									  when 37 => lut_out <= "101000011"; -- 'C'
									  when 38 => lut_out <= "101000001"; -- 'A'
									  when 39 => lut_out <= "101010011"; -- 'S'
									  when 40 => lut_out <= "101010100"; -- 'T'
									  when others => lut_out <= "100100000";
								end case;
						end case;
					end if;
				end if;
			when others => lut_out <= "100100000";
		end case;
	end process;
end block x4;

--***************************************************************
-- x5 : RS232 (四階段字串接收狀態機)
x5 : block
	-- 統一狀態定義
	type states is (s_header, 
	                s_city, s_temp, s_humi, s_wea, 
	                s_aqi_q, s_aqi_i, s_aqi_val, s_aqi_pm25, s_aqi_pm10,
						 s_forecast);
	signal ps : states := s_header; -- 從標頭開始
	signal char_cnt : integer range 0 to 16 := 0;
	signal field_cnt	:integer range 0 to 4 := 0;
	signal f_idx		:integer range 0 to 4 := 0;	
begin
	process(f_idx)
	begin
		 case f_idx is
			  when 0 => LEDR(4 downto 0) <= "00001"; -- 第1天時亮1顆 (這樣比較直觀)
			  when 1 => LEDR(4 downto 0) <= "00011";
			  when 2 => LEDR(4 downto 0) <= "00111";
			  when 3 => LEDR(4 downto 0) <= "01111";
			  when 4 => LEDR(4 downto 0) <= "11111";
			  when others => LEDR(4 downto 0) <= "00000";
		 end case;
	end process;
	
	process(CLOCK_50, rst)
	begin
		if (rst = '0') then
			city        <= (others => '0');
			weather     <= (others => '0');
			temp        <= (others => '1');
			hum         <= (others => '1');
			char_cnt    <= 0;
			ps          <= s_city;
		elsif rising_edge(CLOCK_50) then 
			if r_ready = '1' then
				case ps is
					when s_header =>
						char_cnt <= 0; -- 每次重啟都重置計數
						if r_byte = x"43" then 
							ps <= s_city;  -- 'C' (City)
							city <= (others => '0');
							pm25    <= (others => '0');
							pm10    <= (others => '0');
							weather     <= (others => '0');
							
						else 
							ps <= s_header; -- 繼續等待合法標頭
						end if;

					when s_city =>
						if r_byte = x"3A" then char_cnt <= 0; ps <= s_temp;
						elsif r_byte /= x"0A" then
							if char_cnt < 16 then
								case char_cnt is
									when 0  => city(127 downto 120) <= r_byte;
									when 1  => city(119 downto 112) <= r_byte;
									when 2  => city(111 downto 104) <= r_byte;
									when 3  => city(103 downto 96)  <= r_byte;
									when 4  => city(95  downto 88)  <= r_byte;
									when 5  => city(87  downto 80)  <= r_byte;
									when 6  => city(79  downto 72)  <= r_byte;
									when 7  => city(71  downto 64)  <= r_byte;
									when 8  => city(63  downto 56)  <= r_byte;
									when 9  => city(55  downto 48)  <= r_byte;
									when 10 => city(47  downto 40)  <= r_byte;
									when 11 => city(39  downto 32)  <= r_byte;
									when 12 => city(31  downto 24)  <= r_byte;
									when 13 => city(23  downto 16)  <= r_byte;
									when 14 => city(15  downto 8)   <= r_byte;
									when 15 => city(7   downto 0)   <= r_byte;
									when others => null;
								end case;
								char_cnt <= char_cnt + 1;
							end if;
						end if;
		
					-- 2. 抓取三位數溫度 (修改後：忽略非數字字元)
					when s_temp =>
						if r_byte = x"2C" then -- 遇到 ',' 結束
							char_cnt <= 0;
							ps       <= s_humi;
						elsif r_byte >= x"30" and r_byte <= x"39" then -- 只處理 '0'-'9'
							case char_cnt is
								when 0 => temp(11 downto 8) <= r_byte(3 downto 0); char_cnt <= 1;
								when 1 => temp(7 downto 4)  <= r_byte(3 downto 0); char_cnt <= 2;
								when 2 => temp(3 downto 0)  <= r_byte(3 downto 0); char_cnt <= 3;
								when others => null;
							end case;
						end if;
					
					-- 3. 抓取兩位數濕度
					when s_humi =>
						if r_byte = x"2C" then -- 遇到 ',' 結束，跳進讀取天氣
							char_cnt <= 0;
							ps       <= s_wea;        
						elsif r_byte >= x"30" and r_byte <= x"39" then -- 只處理 '0'-'9'
							case char_cnt is
								when 0 => 
									hum(7 downto 4) <= r_byte(3 downto 0); 
									char_cnt <= 1;
								when 1 => 
									hum(3 downto 0) <= r_byte(3 downto 0); 
									char_cnt <= 2;
								when others => null;
							end case;
						end if;
					
					-- 4. 讀取完整的英文天氣名字
					when s_wea =>
						if r_byte = x"2C" then -- 遇到 ',' 結束 (這是連接到 AQI 的關鍵)
							char_cnt <= 0;
							ps <= s_aqi_val; -- 轉跳到 AQI 解析狀態！
						elsif r_byte = x"0A" or r_byte = x"0D" then
							null;
						else
							if char_cnt < 16 then
								case char_cnt is
									when 0  => weather(127 downto 120) <= r_byte;
									when 1  => weather(119 downto 112) <= r_byte;
									when 2  => weather(111 downto 104) <= r_byte;
									when 3  => weather(103 downto 96)  <= r_byte;
									when 4  => weather(95  downto 88)  <= r_byte;
									when 5  => weather(87  downto 80)  <= r_byte;
									when 6  => weather(79  downto 72)  <= r_byte;
									when 7  => weather(71  downto 64)  <= r_byte;
									when 8  => weather(63  downto 56)  <= r_byte;
									when 9  => weather(55  downto 48)  <= r_byte;
									when 10 => weather(47  downto 40)  <= r_byte;
									when 11 => weather(39  downto 32)  <= r_byte;
									when 12 => weather(31  downto 24)  <= r_byte;
									when 13 => weather(23  downto 16)  <= r_byte;
									when 14 => weather(15  downto 8)   <= r_byte;
									when 15 => weather(7   downto 0)   <= r_byte;
									when others => null;
								end case;
								char_cnt <= char_cnt + 1;
							end if;
						end if;
						
					-- 3. 解析 AQI 數值
					when s_aqi_val =>
						if r_byte = x"2C" then -- 遇到 ',' 結束
							char_cnt <= 0;
							ps <= s_aqi_pm25; 
						elsif r_byte >= x"30" and r_byte <= x"39" then 
							aqi <= r_byte(3 downto 0); 
						end if;

					 -- 2. PM2.5 解析 (忽略小數點)
					 when s_aqi_pm25 =>
						  if r_byte = x"2C" then 
								ps <= s_aqi_pm10; -- 遇到 ',' 轉 PM10
								char_cnt <= 0;
						  elsif r_byte = x"2E" then 
								null;
						  elsif r_byte >= x"30" and r_byte <= x"39" then 
								case char_cnt is
									when 0 => 
										pm25(11 downto 8) <= r_byte(3 downto 0); 
										char_cnt <= 1;
									when 1 => 
										pm25(7 downto 4) <= r_byte(3 downto 0); 
										char_cnt <= 2;
									when 2 => 
										pm25(3 downto 0) <= r_byte(3 downto 0); 
										char_cnt <= 3;
									when others => null;
								end case;
						  end if;

					 -- 3. PM10 解析
					 when s_aqi_pm10 =>
						  if r_byte = x"2C" then 
								ps <= s_forecast;
								char_cnt <= 0;
						  elsif r_byte = x"2E" then null;          -- 忽略小數點 '.'
						  elsif r_byte >= x"30" and r_byte <= x"39" then
								case char_cnt is
									when 0 => 
										pm10(11 downto 8) <= r_byte(3 downto 0); 
										char_cnt <= 1;
									when 1 => 
										pm10(7 downto 4) <= r_byte(3 downto 0); 
										char_cnt <= 2;
									when 2 => 
										pm10(3 downto 0) <= r_byte(3 downto 0); 
										char_cnt <= 3;
									when others => null;
								end case;
						  end if;
						  
					when s_forecast =>
						 if r_byte = x"46" then
							  field_cnt <= 0;
							  char_cnt  <= 0;
						 elsif r_byte = x"3A" then
							  null; 
						 elsif r_byte = x"2C" then
							  field_cnt <= field_cnt + 1;
							  char_cnt  <= 0;
						 elsif r_byte = x"0A" then
							  if f_idx < 4 then
									f_idx <= f_idx + 1;
							  else
									f_idx <= 0;
									ps    <= s_header;
							  end if;
							  field_cnt <= 0;
							  char_cnt  <= 0;
						 end if;
						
						if field_cnt = 0 then
							if(r_byte /= x"2F" and r_byte >= x"30" and r_byte <= x"39")then 
								  case char_cnt is
										when 0 => f_date(f_idx)(15 downto 12) <= r_byte(3 downto 0); char_cnt <= 1;
										when 1 => f_date(f_idx)(11 downto 8)  <= r_byte(3 downto 0); char_cnt <= 2;
										when 2 => f_date(f_idx)(7  downto 4)  <= r_byte(3 downto 0); char_cnt <= 3;
										when 3 => f_date(f_idx)(3  downto 0)  <= r_byte(3 downto 0); char_cnt <= 4;
										when others => null;
								  end case;
							 end if;
						elsif field_cnt = 1 then
							 if(r_byte /= x"2e" and r_byte >= x"30" and r_byte <= x"39")then 
								  case char_cnt is
										when 0 => f_max_temp(f_idx)(11 downto 8)  <= r_byte(3 downto 0); char_cnt <= 1;
										when 1 => f_max_temp(f_idx)(7  downto 4)  <= r_byte(3 downto 0); char_cnt <= 2;
										when 2 => f_max_temp(f_idx)(3  downto 0)  <= r_byte(3 downto 0); char_cnt <= 3;
										when others => null;
								  end case;
							 end if;
						elsif field_cnt = 2 then
							 if(r_byte /= x"2e" and r_byte >= x"30" and r_byte <= x"39")then 
								  case char_cnt is
										when 0 => f_min_temp(f_idx)(11 downto 8)  <= r_byte(3 downto 0); char_cnt <= 1;
										when 1 => f_min_temp(f_idx)(7  downto 4)  <= r_byte(3 downto 0); char_cnt <= 2;
										when 2 => f_min_temp(f_idx)(3  downto 0)  <= r_byte(3 downto 0); char_cnt <= 3;
										when others => null;
								  end case;
							 end if;
						elsif field_cnt = 3 then
							 if(r_byte >= x"30" and r_byte <= x"39")then 
								  case char_cnt is
										when 0 => f_hum(f_idx)(7  downto 4)  <= r_byte(3 downto 0); char_cnt <= 1;
										when 1 => f_hum(f_idx)(3  downto 0)  <= r_byte(3 downto 0); char_cnt <= 2;
										when others => null;
								  end case;
							 end if;
						elsif field_cnt = 4 then
							 if(r_byte >= x"30" and r_byte <= x"39")then 
								  case char_cnt is
										when 0 => f_pop(f_idx)(7  downto 4)  <= r_byte(3 downto 0); char_cnt <= 1;
										when 1 => f_pop(f_idx)(3  downto 0)  <= r_byte(3 downto 0); char_cnt <= 2;
										when others => null;
								  end case;
							 end if;
						end if;
					when others => ps <= s_header;
				end case;
			end if;
		end if;
	end process;
end block x5;
--***************************************************************
end beh;