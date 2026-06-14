## FPGA期末專題-城市天氣監測系統
本專題製作了一個整合電腦端與 FPGA 硬體的即時天氣監測系統，系統透過 C# 程式獲取[OpenWeatherMap](https://openweathermap.org/)的即時氣象數據，並透過通訊介面傳輸至 FPGA 進行處理與顯示。

### 電腦端 (C#)
* 從 OpenWeatherMap API 獲取指定城市的即時天氣數據
* 讀取氣溫、濕度、天氣狀況、AQI、PM2.5、PM10、五天天氣預測、降雨機率
* 提供圖形化使用者介面，顯示目前監測狀態
* 負責將解析後的數據透過序列埠傳輸至 FPGA
* 可即時更新數據

### FPGA端 (VHDL)
#### 實驗板規格
Cyclone EP4CE115
#### 功能
* 傳送要求觀看城市數值
* 接收 UART 傳入的數據並分析資料
* mode 0 : 顯示Weather Management System的跑馬燈
* mode 1 : 顯示當天的天氣資訊(溫度、濕度、天氣狀況)在LCD上
* mode 2 : 顯示當天空氣品質(AQI、PM2.5、PM10)在LCD上
* mode 3 : 顯示五天天氣預報，並將降雨機率用LED加強顯示
