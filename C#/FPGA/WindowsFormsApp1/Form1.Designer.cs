
namespace WeatherApp
{
    partial class Form1
    {
        /// <summary>
        /// 設計工具所需的變數。
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// 清除任何使用中的資源。
        /// </summary>
        /// <param name="disposing">如果應該處置受控資源則為 true，否則為 false。</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form 設計工具產生的程式碼

        /// <summary>
        /// 此為設計工具支援所需的方法 - 請勿使用程式碼編輯器修改
        /// 這個方法的內容。
        /// </summary>
        private void InitializeComponent()
        {
            System.Windows.Forms.DataVisualization.Charting.ChartArea chartArea2 = new System.Windows.Forms.DataVisualization.Charting.ChartArea();
            System.Windows.Forms.DataVisualization.Charting.Legend legend2 = new System.Windows.Forms.DataVisualization.Charting.Legend();
            System.Windows.Forms.DataVisualization.Charting.Series series2 = new System.Windows.Forms.DataVisualization.Charting.Series();
            this.cmbCountry = new System.Windows.Forms.ComboBox();
            this.cmbCity = new System.Windows.Forms.ComboBox();
            this.btnConfirm = new System.Windows.Forms.Button();
            this.lsWeather = new System.Windows.Forms.ListView();
            this.編號 = ((System.Windows.Forms.ColumnHeader)(new System.Windows.Forms.ColumnHeader()));
            this.地點 = ((System.Windows.Forms.ColumnHeader)(new System.Windows.Forms.ColumnHeader()));
            this.溫度 = ((System.Windows.Forms.ColumnHeader)(new System.Windows.Forms.ColumnHeader()));
            this.濕度 = ((System.Windows.Forms.ColumnHeader)(new System.Windows.Forms.ColumnHeader()));
            this.天氣狀況 = ((System.Windows.Forms.ColumnHeader)(new System.Windows.Forms.ColumnHeader()));
            this.pnlAqi = new System.Windows.Forms.Panel();
            this.lblPm25 = new System.Windows.Forms.Label();
            this.lblPm10 = new System.Windows.Forms.Label();
            this.lblAqiLevel = new System.Windows.Forms.Label();
            this.lblAqiTitle = new System.Windows.Forms.Label();
            this.btnDelete = new System.Windows.Forms.Button();
            this.chart1 = new System.Windows.Forms.DataVisualization.Charting.Chart();
            this.pnlAqi.SuspendLayout();
            ((System.ComponentModel.ISupportInitialize)(this.chart1)).BeginInit();
            this.SuspendLayout();
            // 
            // cmbCountry
            // 
            this.cmbCountry.Font = new System.Drawing.Font("微軟正黑體", 10.8F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(136)));
            this.cmbCountry.FormattingEnabled = true;
            this.cmbCountry.Location = new System.Drawing.Point(72, 43);
            this.cmbCountry.Margin = new System.Windows.Forms.Padding(3, 4, 3, 4);
            this.cmbCountry.Name = "cmbCountry";
            this.cmbCountry.Size = new System.Drawing.Size(140, 36);
            this.cmbCountry.TabIndex = 0;
            this.cmbCountry.SelectedIndexChanged += new System.EventHandler(this.cmbCountry_SelectedIndexChanged_1);
            // 
            // cmbCity
            // 
            this.cmbCity.Font = new System.Drawing.Font("微軟正黑體", 10.8F, System.Drawing.FontStyle.Regular, System.Drawing.GraphicsUnit.Point, ((byte)(136)));
            this.cmbCity.FormattingEnabled = true;
            this.cmbCity.Location = new System.Drawing.Point(268, 43);
            this.cmbCity.Margin = new System.Windows.Forms.Padding(3, 4, 3, 4);
            this.cmbCity.Name = "cmbCity";
            this.cmbCity.Size = new System.Drawing.Size(175, 36);
            this.cmbCity.TabIndex = 1;
            this.cmbCity.SelectedIndexChanged += new System.EventHandler(this.cmbCountry_SelectedIndexChanged);
            // 
            // btnConfirm
            // 
            this.btnConfirm.BackColor = System.Drawing.Color.DodgerBlue;
            this.btnConfirm.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnConfirm.ForeColor = System.Drawing.Color.White;
            this.btnConfirm.Location = new System.Drawing.Point(498, 38);
            this.btnConfirm.Margin = new System.Windows.Forms.Padding(3, 4, 3, 4);
            this.btnConfirm.Name = "btnConfirm";
            this.btnConfirm.Size = new System.Drawing.Size(141, 48);
            this.btnConfirm.TabIndex = 2;
            this.btnConfirm.Text = "確認";
            this.btnConfirm.UseVisualStyleBackColor = false;
            this.btnConfirm.Click += new System.EventHandler(this.btnConfirm_Click);
            // 
            // lsWeather
            // 
            this.lsWeather.Columns.AddRange(new System.Windows.Forms.ColumnHeader[] {
            this.編號,
            this.地點,
            this.溫度,
            this.濕度,
            this.天氣狀況});
            this.lsWeather.FullRowSelect = true;
            this.lsWeather.HideSelection = false;
            this.lsWeather.Location = new System.Drawing.Point(72, 118);
            this.lsWeather.Margin = new System.Windows.Forms.Padding(3, 4, 3, 4);
            this.lsWeather.MultiSelect = false;
            this.lsWeather.Name = "lsWeather";
            this.lsWeather.Size = new System.Drawing.Size(612, 354);
            this.lsWeather.TabIndex = 3;
            this.lsWeather.UseCompatibleStateImageBehavior = false;
            this.lsWeather.View = System.Windows.Forms.View.Details;
            this.lsWeather.SelectedIndexChanged += new System.EventHandler(this.lsWeather_SelectedIndexChanged);
            // 
            // 編號
            // 
            this.編號.Text = "編號";
            this.編號.Width = 49;
            // 
            // 地點
            // 
            this.地點.Text = "地點";
            this.地點.Width = 110;
            // 
            // 溫度
            // 
            this.溫度.Text = "溫度";
            this.溫度.Width = 74;
            // 
            // 濕度
            // 
            this.濕度.Text = "濕度";
            this.濕度.Width = 80;
            // 
            // 天氣狀況
            // 
            this.天氣狀況.Text = "天氣狀況";
            this.天氣狀況.Width = 92;
            // 
            // pnlAqi
            // 
            this.pnlAqi.BackColor = System.Drawing.Color.AliceBlue;
            this.pnlAqi.BorderStyle = System.Windows.Forms.BorderStyle.FixedSingle;
            this.pnlAqi.Controls.Add(this.lblPm25);
            this.pnlAqi.Controls.Add(this.lblPm10);
            this.pnlAqi.Controls.Add(this.lblAqiLevel);
            this.pnlAqi.Controls.Add(this.lblAqiTitle);
            this.pnlAqi.Location = new System.Drawing.Point(722, 118);
            this.pnlAqi.Margin = new System.Windows.Forms.Padding(3, 4, 3, 4);
            this.pnlAqi.Name = "pnlAqi";
            this.pnlAqi.Size = new System.Drawing.Size(388, 355);
            this.pnlAqi.TabIndex = 4;
            // 
            // lblPm25
            // 
            this.lblPm25.AutoSize = true;
            this.lblPm25.Font = new System.Drawing.Font("微軟正黑體", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(136)));
            this.lblPm25.Location = new System.Drawing.Point(3, 143);
            this.lblPm25.Name = "lblPm25";
            this.lblPm25.Size = new System.Drawing.Size(191, 26);
            this.lblPm25.TabIndex = 3;
            this.lblPm25.Text = "PM2.5：— μg/m³";
            // 
            // lblPm10
            // 
            this.lblPm10.AutoSize = true;
            this.lblPm10.Font = new System.Drawing.Font("微軟正黑體", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(136)));
            this.lblPm10.Location = new System.Drawing.Point(4, 216);
            this.lblPm10.Name = "lblPm10";
            this.lblPm10.Size = new System.Drawing.Size(186, 26);
            this.lblPm10.TabIndex = 2;
            this.lblPm10.Text = "PM10：— μg/m³";
            // 
            // lblAqiLevel
            // 
            this.lblAqiLevel.AutoSize = true;
            this.lblAqiLevel.Font = new System.Drawing.Font("微軟正黑體", 10.2F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(136)));
            this.lblAqiLevel.Location = new System.Drawing.Point(4, 68);
            this.lblAqiLevel.Name = "lblAqiLevel";
            this.lblAqiLevel.Size = new System.Drawing.Size(98, 26);
            this.lblAqiLevel.TabIndex = 1;
            this.lblAqiLevel.Text = "等級：—";
            // 
            // lblAqiTitle
            // 
            this.lblAqiTitle.AutoSize = true;
            this.lblAqiTitle.Font = new System.Drawing.Font("微軟正黑體", 12F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(136)));
            this.lblAqiTitle.Location = new System.Drawing.Point(3, 11);
            this.lblAqiTitle.Name = "lblAqiTitle";
            this.lblAqiTitle.Size = new System.Drawing.Size(149, 31);
            this.lblAqiTitle.TabIndex = 0;
            this.lblAqiTitle.Text = "🌫 空氣品質";
            // 
            // btnDelete
            // 
            this.btnDelete.BackColor = System.Drawing.Color.FromArgb(((int)(((byte)(220)))), ((int)(((byte)(53)))), ((int)(((byte)(69)))));
            this.btnDelete.FlatStyle = System.Windows.Forms.FlatStyle.Flat;
            this.btnDelete.Font = new System.Drawing.Font("微軟正黑體", 9F, System.Drawing.FontStyle.Bold, System.Drawing.GraphicsUnit.Point, ((byte)(136)));
            this.btnDelete.ForeColor = System.Drawing.Color.White;
            this.btnDelete.Location = new System.Drawing.Point(688, 37);
            this.btnDelete.Margin = new System.Windows.Forms.Padding(3, 4, 3, 4);
            this.btnDelete.Name = "btnDelete";
            this.btnDelete.Size = new System.Drawing.Size(141, 48);
            this.btnDelete.TabIndex = 5;
            this.btnDelete.Text = "🗑 刪除選取";
            this.btnDelete.UseVisualStyleBackColor = false;
            this.btnDelete.Click += new System.EventHandler(this.btnDelete_Click_1);
            // 
            // chart1
            // 
            chartArea2.Name = "ChartArea1";
            this.chart1.ChartAreas.Add(chartArea2);
            legend2.Name = "Legend1";
            this.chart1.Legends.Add(legend2);
            this.chart1.Location = new System.Drawing.Point(72, 495);
            this.chart1.Name = "chart1";
            series2.ChartArea = "ChartArea1";
            series2.Legend = "Legend1";
            series2.Name = "Series1";
            this.chart1.Series.Add(series2);
            this.chart1.Size = new System.Drawing.Size(1038, 194);
            this.chart1.TabIndex = 6;
            this.chart1.Text = "chart1";
            this.chart1.Click += new System.EventHandler(this.chart1_Click);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(9F, 18F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(1180, 720);
            this.Controls.Add(this.chart1);
            this.Controls.Add(this.btnDelete);
            this.Controls.Add(this.pnlAqi);
            this.Controls.Add(this.lsWeather);
            this.Controls.Add(this.btnConfirm);
            this.Controls.Add(this.cmbCity);
            this.Controls.Add(this.cmbCountry);
            this.Margin = new System.Windows.Forms.Padding(3, 4, 3, 4);
            this.Name = "Form1";
            this.Text = "Form1";
            this.Load += new System.EventHandler(this.Form1_Load);
            this.pnlAqi.ResumeLayout(false);
            this.pnlAqi.PerformLayout();
            ((System.ComponentModel.ISupportInitialize)(this.chart1)).EndInit();
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.ComboBox cmbCountry;
        private System.Windows.Forms.ComboBox cmbCity;
        private System.Windows.Forms.Button btnConfirm;
        private System.Windows.Forms.ListView lsWeather;
        private System.Windows.Forms.ColumnHeader 編號;
        private System.Windows.Forms.ColumnHeader 地點;
        private System.Windows.Forms.ColumnHeader 溫度;
        private System.Windows.Forms.ColumnHeader 濕度;
        private System.Windows.Forms.ColumnHeader 天氣狀況;
        private System.Windows.Forms.Panel pnlAqi;
        private System.Windows.Forms.Label lblPm25;
        private System.Windows.Forms.Label lblPm10;
        private System.Windows.Forms.Label lblAqiLevel;
        private System.Windows.Forms.Label lblAqiTitle;
        private System.Windows.Forms.Button btnDelete;
        private System.Windows.Forms.DataVisualization.Charting.Chart chart1;
    }
}

