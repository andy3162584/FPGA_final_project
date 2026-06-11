using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO.Ports;
using System.Net.Http;
using System.Windows.Forms;
using Newtonsoft.Json.Linq;
using System.Linq;

namespace WeatherApp
{
    public partial class Form1 : Form
    {
        private int idCounter = 0;
        private readonly string apiKey = "68f8ada10a0a2fbc32e542a06be0c761";
        private SerialPort serialPort;
        private Dictionary<string, ForecastAqiData> extendedDataMap = new Dictionary<string, ForecastAqiData>();


        private class ForecastAqiData
        {
            public List<DailyForecast> Forecasts = new List<DailyForecast>();
            public int Aqi = -1;
            public double Pm25 = -1;
            public double Pm10 = -1;
        }

        private class DailyForecast
		{
			public string Date;
			public string TempMax;
			public string TempMin;
			public string Humi;
			public string pop;
		}

        private Dictionary<string, List<string>> locationData = new Dictionary<string, List<string>>()
        {
            { "台灣", new List<string> { "台北", "台中", "高雄", "台南", "桃園", "新北" } },
            { "日本", new List<string> { "東京", "大阪", "京都", "沖繩", "北海道" } },
            { "美國", new List<string> { "紐約", "洛杉磯", "舊金山", "西雅圖" } },
            { "韓國", new List<string> { "首爾", "釜山", "濟州島" } }
        };

        private Dictionary<string, string> cityEnglishMap = new Dictionary<string, string>()
        {
            { "台北", "Taipei,TW" }, { "台中", "Taichung,TW" }, { "高雄", "Kaohsiung,TW" },
            { "台南", "Tainan,TW" }, { "桃園", "Taoyuan,TW" }, { "新北", "New Taipei,TW" },
            { "東京", "Tokyo,JP" }, { "大阪", "Osaka,JP" }, { "京都", "Kyoto,JP" },
            { "沖繩", "Okinawa,JP" }, { "北海道", "Hokkaido,JP" },
            { "紐約", "New York,US" }, { "洛杉磯", "Los Angeles,US" },
            { "舊金山", "San Francisco,US" }, { "西雅圖", "Seattle,US" },
            { "首爾", "Seoul,KR" }, { "釜山", "Busan,KR" }, { "濟州島", "Jeju,KR" }
        };

        private Dictionary<string, (double lat, double lon)> cityGeoMap = new Dictionary<string, (double, double)>()
        {
            { "台北",   (25.0330, 121.5654) }, { "台中",   (24.1477, 120.6736) },
            { "高雄",   (22.6273, 120.3014) }, { "台南",   (22.9999, 120.2269) },
            { "桃園",   (24.9937, 121.3010) }, { "新北",   (25.0169, 121.4627) },
            { "東京",   (35.6895, 139.6917) }, { "大阪",   (34.6937, 135.5023) },
            { "京都",   (35.0116, 135.7681) }, { "沖繩",   (26.2124, 127.6809) },
            { "北海道", (43.0642, 141.3469) },
            { "紐約",   (40.7128, -74.0060) }, { "洛杉磯", (34.0522, -118.2437) },
            { "舊金山", (37.7749, -122.4194) }, { "西雅圖", (47.6062, -122.3321) },
            { "首爾",   (37.5665, 126.9780) }, { "釜山",   (35.1796, 129.0756) },
            { "濟州島", (33.4996, 126.5312) }
        };

        private Dictionary<string, string> conditionMap = new Dictionary<string, string>()
        {
            { "Clear", "晴天" }, { "Clouds", "多雲" }, { "Rain", "下雨" },
            { "Drizzle", "毛毛雨" }, { "Thunderstorm", "雷陣雨" }, { "Snow", "下雪" },
            { "Mist", "有霧" }, { "Haze", "霾" }, { "Fog", "濃霧" }
        };

        // AQI 等級：文字、背景色、前景色
        private string[] aqiLabels = { "", "優良", "良好", "輕度污染", "中度污染", "嚴重污染" };
        private Color[] aqiColors = {
            Color.Gray,
            Color.FromArgb(0, 153, 102),   // 1 優良 深綠
            Color.FromArgb(255, 222, 51),   // 2 良好 黃
            Color.FromArgb(255, 153, 51),   // 3 輕度 橙
            Color.FromArgb(204, 0, 51),     // 4 中度 紅
            Color.FromArgb(126, 0, 35)      // 5 嚴重 深紅
        };

        public Form1()
        {
            InitializeComponent();
            LoadCountryData();
            this.cmbCountry.SelectedIndexChanged += new EventHandler(cmbCountry_SelectedIndexChanged);
            if (cmbCountry.Items.Count > 0)
                cmbCountry.SelectedIndex = 0;

            InitSerialPort();
            InitChart();

            // 綁定 ListView 選取事件：點選城市時更新 AQI 面板
            lsWeather.SelectedIndexChanged += new EventHandler(lsWeather_SelectedIndexChanged);
        }

        
        // =========================================================
        // 點選 ListView 的城市 → 更新 AQI 面板
        // =========================================================
        private void lsWeather_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (lsWeather.SelectedItems.Count == 0)
            {
                ResetAqiPanel();
                return;
            }

            string id = lsWeather.SelectedItems[0].Text;

            if (!extendedDataMap.ContainsKey(id) || extendedDataMap[id].Aqi < 0)
            {
                ResetAqiPanel();
                return;
            }

            var data = extendedDataMap[id];
            int aqi = data.Aqi;
            string cityName = lsWeather.SelectedItems[0].SubItems[1].Text;

            lblAqiTitle.Text = $"🌫 空氣品質　—　{cityName}";
            lblAqiLevel.Text = $"AQI 等級：{aqi}　{aqiLabels[aqi]}";
            lblAqiLevel.ForeColor = aqi >= 1 && aqi <= 5 ? aqiColors[aqi] : Color.Gray;

            lblPm25.Text = $"PM2.5：{data.Pm25} μg/m³";
            lblPm10.Text = $"PM10 ：{data.Pm10} μg/m³";
            UpdateForecastChart(data);
        }

        private void ResetAqiPanel()
        {
            lblAqiTitle.Text = "🌫 空氣品質";
            lblAqiLevel.Text = "等級：—";
            lblAqiLevel.ForeColor = Color.Gray;
            lblPm25.Text = "PM2.5：— μg/m³";
            lblPm10.Text = "PM10：— μg/m³";
            pnlAqi.BackColor = Color.FromArgb(240, 248, 255);
        }

        // =========================================================
        // SerialPort 初始化
        // =========================================================
        private void InitSerialPort()
        {
            serialPort = new SerialPort();
            serialPort.PortName = "COM8";
            serialPort.BaudRate = 9600;
            serialPort.DataBits = 8;
            serialPort.Parity = Parity.None;
            serialPort.StopBits = StopBits.One;
            serialPort.DataReceived += new SerialDataReceivedEventHandler(SerialPort_DataReceived);
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            try
            {
                if (!serialPort.IsOpen)
                    serialPort.Open();
            }
            catch (Exception)
            {
                this.Text += " (COM8 離線中)";
            }
        }

        private void SerialPort_DataReceived(object sender, SerialDataReceivedEventArgs e)
        {
            try
            {
                string rawData = serialPort.ReadExisting();
                // 1. 過濾不可見字元並修剪，確保拿到乾淨的字串
                string input = new string(rawData.Where(c => !char.IsControl(c)).ToArray()).Trim();

                if (string.IsNullOrEmpty(input)) return;

                this.Invoke(new Action(() =>
                {
                    System.Diagnostics.Debug.WriteLine($"[DEBUG] 原始收到: '{input}'");

					// 這裡假設收到的是純 ID (例如 "0")
					string searchId = input;

					// 如果 FPGA 之後改為送 "C:0" 等格式，這裡可以再加邏輯
					if (input.Contains(":")) searchId = input.Split(':')[1];

					bool found = false;
					foreach (ListViewItem row in lsWeather.Items)
					{
						string rowId = row.Text.Trim();
						if (rowId == searchId)
						{
							// 提取資料
							string enCityName = "Unknown";
							string chCityName = row.SubItems[1].Text.Split('-')[1];
							foreach (var pair in cityEnglishMap)
								if (pair.Key == chCityName) { enCityName = pair.Value.Split(',')[0]; break; }

							string rawTempStr = row.SubItems[2].Text.Replace("°", "").Replace("C", "").Trim();
							string humiValue = row.SubItems[3].Text.Replace("%", "").Trim();
							string chWeather = row.SubItems[4].Text;
							string enCondition = conditionMap.FirstOrDefault(x => x.Value == chWeather).Key?.ToUpper() ?? "UNKNOWN";

							var data = extendedDataMap[rowId];

							// 分段發送，減輕 FPGA 接收負擔
							serialPort.Write($"C{enCityName}:{rawTempStr},{humiValue},{enCondition},");
							System.Threading.Thread.Sleep(20);
							serialPort.Write($"A:{data.Aqi},{data.Pm25:F1},{data.Pm10:F1},");
							System.Threading.Thread.Sleep(20);
							foreach (var f in extendedDataMap[rowId].Forecasts)
							{
                                double popValue = double.Parse(f.pop);
                                int popPercent = (int)(popValue * 100);

                                serialPort.Write($"F:{f.Date},{f.TempMax},{f.TempMin},{f.Humi},{popPercent}\n");
                                System.Threading.Thread.Sleep(50);
							}

							found = true;
							break;
						}
					}

					if (!found)
					{
						System.Diagnostics.Debug.WriteLine($"[DEBUG] 找不到 ID: {searchId}");
						serialPort.Write("E:NOT FOUND\n");
					}
                }));
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine($"[ERROR]: {ex.Message}");
            }
        }


        private void LoadCountryData()
        {
            cmbCountry.Items.Clear();
            foreach (var country in locationData.Keys)
                cmbCountry.Items.Add(country);
        }

        private void cmbCountry_SelectedIndexChanged(object sender, EventArgs e)
        {
            if (sender != cmbCountry) return;
            cmbCity.Items.Clear();
            if (cmbCountry.SelectedItem == null) return;
            string selectedCountry = cmbCountry.SelectedItem.ToString();
            if (locationData.ContainsKey(selectedCountry))
            {
                foreach (var city in locationData[selectedCountry])
                    cmbCity.Items.Add(city);
                if (cmbCity.Items.Count > 0)
                    cmbCity.SelectedIndex = 0;
            }
        }

        private async void btnConfirm_Click(object sender, EventArgs e)
        {
            if (cmbCountry.SelectedItem == null || cmbCity.SelectedItem == null)
            {
                MessageBox.Show("請先選擇國家與城市！", "提示", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            string country = cmbCountry.SelectedItem.ToString();
            string city = cmbCity.SelectedItem.ToString();

            string newEntry = $"{country}-{city}";
            foreach (ListViewItem existingRow in lsWeather.Items)
            {
                if (existingRow.SubItems[1].Text == newEntry)
                {
                    MessageBox.Show($"「{city}」已經在清單中！\n請勿重複新增。",
                                    "重複城市", MessageBoxButtons.OK, MessageBoxIcon.Warning);

                    // 自動反白該列，讓使用者看到它在哪
                    lsWeather.SelectedItems.Clear();
                    existingRow.Selected = true;
                    existingRow.EnsureVisible();
                    return;
                }
            }

            string geoQuery = cityEnglishMap.ContainsKey(city) ? cityEnglishMap[city] : city;
            (double lat, double lon) = cityGeoMap.ContainsKey(city) ? cityGeoMap[city] : (0, 0);

            string temp = "無資料", humidity = "無資料", condition = "觀測中";
            var extData = new ForecastAqiData();

            using (HttpClient client = new HttpClient())
            {
                // API 1：當天天氣
                try
                {
                    string url = $"https://api.openweathermap.org/data/2.5/weather?q={Uri.EscapeDataString(geoQuery)}&appid={apiKey}&units=metric";
                    JObject w = JObject.Parse(await client.GetStringAsync(url));
                    if (w["main"]?["temp"] != null)
                        temp = Math.Round(Convert.ToDouble(w["main"]["temp"]), 1) + "°C";
                    if (w["main"]?["humidity"] != null)
                        humidity = w["main"]["humidity"] + "%";
                    if (w["weather"]?[0]?["main"] != null)
                    {
                        string en = w["weather"][0]["main"].ToString();
                        condition = conditionMap.ContainsKey(en) ? conditionMap[en] : en;
                    }
                }
                catch (Exception ex) { MessageBox.Show($"當天天氣取得失敗: {ex.Message}"); return; }

                // API 2：5 天預報
                try
                {
                    string fUrl = $"https://api.openweathermap.org/data/2.5/forecast?lat={lat}&lon={lon}&appid={apiKey}&units=metric";
                    JObject fData = JObject.Parse(await client.GetStringAsync(fUrl));
                    var seen = new HashSet<string>();
                    foreach (var item in fData["list"])
                    {
                        string dtTxt = item["dt_txt"].ToString();
                        string dateKey = dtTxt.Substring(0, 10);
                        if (!dtTxt.Contains("12:00:00") || seen.Contains(dateKey)) continue;
                        if (extData.Forecasts.Count >= 5) break;
                        seen.Add(dateKey);
                        extData.Forecasts.Add(new DailyForecast
                        {
                            Date = DateTime.Parse(dateKey).ToString("MM/dd"),
                            TempMax = Math.Round(Convert.ToDouble(item["main"]["temp_max"]), 1).ToString("00.0"),
                            TempMin = Math.Round(Convert.ToDouble(item["main"]["temp_min"]), 1).ToString("00.0"),
							Humi = item["main"]["humidity"].ToString(),
							pop = Math.Round(Convert.ToDouble(item["pop"]) * 100).ToString("00"),
                        });
                    }
                }
                catch (Exception ex) { MessageBox.Show($"5天預報取得失敗: {ex.Message}"); }

                // API 3：空氣污染
                try
                {
                    string aUrl = $"https://api.openweathermap.org/data/2.5/air_pollution?lat={lat}&lon={lon}&appid={apiKey}";
                    JObject aData = JObject.Parse(await client.GetStringAsync(aUrl));
                    extData.Aqi = Convert.ToInt32(aData["list"][0]["main"]["aqi"]);
                    extData.Pm25 = Math.Round(Convert.ToDouble(aData["list"][0]["components"]["pm2_5"]), 1);
                    extData.Pm10 = Math.Round(Convert.ToDouble(aData["list"][0]["components"]["pm10"]), 1);
                }
                catch (Exception ex) { MessageBox.Show($"空氣品質取得失敗: {ex.Message}"); }
            }

            // 加入 ListView
            string id = idCounter.ToString();
            ListViewItem row = new ListViewItem(id);
            row.SubItems.Add($"{country}-{city}");
            row.SubItems.Add(temp);
            row.SubItems.Add(humidity);
            row.SubItems.Add(condition);

            string aqiDisplay = extData.Aqi > 0
                ? $"AQI:{extData.Aqi} {aqiLabels[extData.Aqi]} PM2.5:{extData.Pm25}"
                : "AQI:無資料";
            row.SubItems.Add(aqiDisplay);

            string forecastSummary = extData.Forecasts.Count > 0
                ? string.Join(" | ", extData.Forecasts.ConvertAll(f =>
                    $"{f.Date} {f.TempMax}↑{f.TempMin} {f.Humi} {f.pop}"))
                : "無預報資料";
            row.SubItems.Add(forecastSummary);

            lsWeather.Items.Add(row);
            extendedDataMap[id] = extData;
            idCounter++;
        }

        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            if (serialPort != null && serialPort.IsOpen)
                serialPort.Close();
            base.OnFormClosing(e);
        }

        private void btnDelete_Click_1(object sender, EventArgs e)
        {
            if (lsWeather.SelectedItems.Count == 0)
            {
                MessageBox.Show("請先點選要刪除的城市！", "提示", MessageBoxButtons.OK, MessageBoxIcon.Information);
                return;
            }

            // 記錄要刪除的 id（舊的），從 extendedDataMap 移除
            string oldId = lsWeather.SelectedItems[0].Text;
            extendedDataMap.Remove(oldId);

            // 從 ListView 移除該列
            lsWeather.Items.Remove(lsWeather.SelectedItems[0]);

            // ---- 重新整理所有編號（從 0 開始連續重排）----
            var newMap = new Dictionary<string, ForecastAqiData>();
            for (int i = 0; i < lsWeather.Items.Count; i++)
            {
                string originalId = lsWeather.Items[i].Text;  // 舊的 id
                string newId = i.ToString();                    // 新的 id

                lsWeather.Items[i].Text = newId;               // 更新 ListView 第一欄

                // 把對應的 extendedDataMap 資料搬到新 id
                if (extendedDataMap.ContainsKey(originalId))
                {
                    newMap[newId] = extendedDataMap[originalId];
                    extendedDataMap.Remove(originalId);
                }
            }
            extendedDataMap = newMap;

            // idCounter 重設為目前筆數，下次新增從正確編號開始
            idCounter = lsWeather.Items.Count;

            // 清除 AQI 面板
            ResetAqiPanel();
        }

        private void cmbCountry_SelectedIndexChanged_1(object sender, EventArgs e)
        {

        }

        private void chart1_Click(object sender, EventArgs e)
        {

        }

        private void UpdateForecastChart(ForecastAqiData data)
        {
            chart1.Series["溫度"].Points.Clear();
            chart1.Series["濕度"].Points.Clear();

            foreach (var f in data.Forecasts)
            {
                double temp = double.Parse(f.TempMax); // 這裡需確保格式正確
                double humi = double.Parse(f.Humi);

                // 新增點到對應的 Series
                chart1.Series["溫度"].Points.AddXY(f.Date, temp);
                chart1.Series["濕度"].Points.AddXY(f.Date, humi);
            }
        }

        private void InitChart()
        {
            chart1.Series.Clear();

            // 1. 先加入濕度 (底層，設為深藍色但帶點透明)
            var sHumi = chart1.Series.Add("濕度");
            sHumi.ChartType = System.Windows.Forms.DataVisualization.Charting.SeriesChartType.Column;
            // 顏色調整：設為較深的藍色，透明度 150 (範圍 0-255，越小越透明)
            sHumi.Color = Color.FromArgb(150, 0, 100, 200);
            sHumi.YAxisType = System.Windows.Forms.DataVisualization.Charting.AxisType.Secondary;

            // 2. 後加入溫度 (上層，顯示在長條圖前方)
            var sTemp = chart1.Series.Add("溫度");
            sTemp.ChartType = System.Windows.Forms.DataVisualization.Charting.SeriesChartType.Line;
            sTemp.BorderWidth = 3;
            sTemp.Color = Color.Red;
            sTemp.MarkerStyle = System.Windows.Forms.DataVisualization.Charting.MarkerStyle.Circle;
            sTemp.YAxisType = System.Windows.Forms.DataVisualization.Charting.AxisType.Primary;

            // 3. 調整格線 (讓標線淺一點)
            var area = chart1.ChartAreas[0];
            area.AxisY.MajorGrid.LineColor = Color.LightGray; // 設定為淺灰色
            area.AxisY.MajorGrid.LineDashStyle = System.Windows.Forms.DataVisualization.Charting.ChartDashStyle.Dot; // 虛線
            area.AxisY2.MajorGrid.Enabled = false; // 關閉次軸格線，避免線條太亂
        }
    }
}