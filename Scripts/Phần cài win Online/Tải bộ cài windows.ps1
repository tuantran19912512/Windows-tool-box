# ==========================================================
# VIETTOOLBOX ISO CLIENT V143 - PHIÊN BẢN HIỂN THỊ TỐC ĐỘ (MB/S)
# ==========================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Net.Http, System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$B64_Key = "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0"
$Global:DriveApiKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($B64_Key))

$LogicIsoClientV143 = {
    $RawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/iso_list.csv"
    $script:CancelDL = $false

    # --- GIAO DIỆN WPF NÂNG CẤP ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        Title="VIETTOOLBOX V143 - PRO DOWNLOADER" Width="900" Height="850" 
        WindowStartupLocation="CenterScreen" Background="#F0F2F5" FontFamily="Segoe UI">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="HỆ THỐNG TẢI ISO CHUYÊN NGHIỆP" FontSize="26" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Đầy đủ trạng thái: Tốc độ tải | % Tiến độ | Dung lượng" Foreground="#555555"/>
        </StackPanel>

        <ListView Name="BangISO" Grid.Row="1" Background="White" BorderBrush="#CCCCCC" Margin="0,0,0,15">
            <ListView.View><GridView>
                <GridViewColumn Width="45">
                    <GridViewColumn.CellTemplate>
                        <DataTemplate><CheckBox IsChecked="{Binding Check, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"/></DataTemplate>
                    </GridViewColumn.CellTemplate>
                </GridViewColumn>
                <GridViewColumn Header="TÊN FILE" DisplayMemberBinding="{Binding Name}" Width="540"/>
                <GridViewColumn Header="TRẠNG THÁI" Width="200">
                    <GridViewColumn.CellTemplate>
                        <DataTemplate><TextBlock Text="{Binding Status}" Foreground="{Binding StatusColor}" FontWeight="SemiBold"/></DataTemplate>
                    </GridViewColumn.CellTemplate>
                </GridViewColumn>
            </GridView></ListView.View>
        </ListView>

        <Border Grid.Row="2" Background="White" CornerRadius="6" Padding="12" Margin="0,0,0,15" BorderBrush="#DDDDDD" BorderThickness="1">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="70"/><ColumnDefinition Width="*"/><ColumnDefinition Width="140"/></Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="LƯU TẠI:" FontWeight="Bold" VerticalAlignment="Center"/>
                <TextBox Name="txtPath" Grid.Column="1" Height="35" IsReadOnly="True" Background="#F9F9F9" Padding="8,0" VerticalContentAlignment="Center"/>
                <Button Name="btnBrowse" Grid.Column="2" Content="CHỌN THƯ MỤC" Height="35" Cursor="Hand" FontWeight="Bold" Margin="5,0,0,0"/>
            </Grid>
        </Border>

        <Grid Grid.Row="3" Margin="0,0,0,15">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Stretch" Margin="0,0,0,5">
                <TextBlock Name="lblStatus" Text="Sẵn sàng..." FontWeight="Bold" Foreground="#1565C0" FontSize="14" Width="400"/>
                <TextBlock Name="lblSpeed" Text="Tốc độ: 0 MB/s" FontWeight="Bold" Foreground="#D81B60" FontSize="14" TextAlignment="Right" Width="420"/>
            </StackPanel>
            <ProgressBar Name="pgBar" Grid.Row="1" Height="35" Foreground="#2E7D32" Background="#E0E0E0" BorderThickness="0"/>
            <TextBlock Name="lblSize" Grid.Row="2" Text="Đã tải: 0 MB / 0 MB (0%)" HorizontalAlignment="Center" Margin="0,5,0,0" Foreground="#333333" FontWeight="SemiBold"/>
        </Grid>

        <Grid Grid.Row="4" Margin="0,0,0,15">
            <Button Name="btnCancel" Content="⏹️ DỪNG LỆNH TẢI HIỆN TẠI" Height="45" Background="#FFEBEE" Foreground="#B71C1C" BorderBrush="#EF9A9A" Cursor="Hand" FontWeight="Bold"/>
        </Grid>

        <Grid Grid.Row="5">
            <Grid.ColumnDefinitions><ColumnDefinition Width="1*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="2.5*"/></Grid.ColumnDefinitions>
            <Button Name="btnSync" Grid.Column="0" Content="🔄 LÀM MỚI" Height="65" Background="#455A64" Foreground="White" Cursor="Hand" FontWeight="Bold"/>
            <Button Name="btnDownload" Grid.Column="2" Content="🚀 BẮT ĐẦU TẢI NGAY" Height="65" Background="#007ACC" Foreground="White" FontSize="20" FontWeight="Bold" Cursor="Hand"/>
        </Grid>
    </Grid>
</Window>
"@

    $DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaGiaoDien)))
    $CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

    $BangISO = $CuaSo.FindName("BangISO"); $txtPath = $CuaSo.FindName("txtPath"); $btnBrowse = $CuaSo.FindName("btnBrowse")
    $lblStatus = $CuaSo.FindName("lblStatus"); $lblSpeed = $CuaSo.FindName("lblSpeed"); $lblSize = $CuaSo.FindName("lblSize")
    $pgBar = $CuaSo.FindName("pgBar"); $btnCancel = $CuaSo.FindName("btnCancel")
    $btnSync = $CuaSo.FindName("btnSync"); $btnDownload = $CuaSo.FindName("btnDownload")

    $Global:DanhSachDuLieu = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
    $BangISO.ItemsSource = $Global:DanhSachDuLieu
    $txtPath.Text = Join-Path ([Environment]::GetFolderPath("Desktop")) "VietToolbox_Downloads"

    $CapNhatUI = { [System.Windows.Forms.Application]::DoEvents() }

    function Load-List {
        try {
            $lblStatus.Text = "🔄 Đang lấy danh sách file..."
            &$CapNhatUI
            $csv = Invoke-WebRequest -Uri ($RawUrl + "?t=" + (Get-Date -UFormat %s)) -UseBasicParsing | ConvertFrom-Csv
            $Global:DanhSachDuLieu.Clear()
            foreach ($r in $csv) { 
                if ($r.Name) { 
                    $Global:DanhSachDuLieu.Add([PSCustomObject]@{ Check=$false; Name=$r.Name; FileID=$r.FileID; Status="Sẵn sàng"; StatusColor="#666666" })
                } 
            }
            $lblStatus.Text = "✅ Danh sách đã sẵn sàng."
        } catch { $lblStatus.Text = "❌ Lỗi kết nối GitHub!" }
    }

    $CuaSo.Add_ContentRendered({ Load-List })
    $btnSync.Add_Click({ Load-List })
    $btnBrowse.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq "OK") { $txtPath.Text = $fb.SelectedPath } })
    $btnCancel.Add_Click({ $script:CancelDL = $true; $lblStatus.Text = "🛑 Đang dừng..." })

    $btnDownload.Add_Click({
        $DaChon = @($Global:DanhSachDuLieu | Where-Object { $_.Check -eq $true })
        if ($DaChon.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("Bạn chưa chọn file nào!", "Thông báo")
            return
        }

        $btnDownload.IsEnabled = $false; $script:CancelDL = $false
        $HttpClient = New-Object System.Net.Http.HttpClient
        
        foreach ($item in $DaChon) {
            if ($script:CancelDL) { break }
            $pgBar.Value = 0
            try {
                $item.Status = "🌐 Đang kết nối..."; $item.StatusColor = "#1565C0"
                $BangISO.Items.Refresh(); &$CapNhatUI

                $url = "https://www.googleapis.com/drive/v3/files/$($item.FileID)?alt=media&key=$($Global:DriveApiKey)&acknowledgeAbuse=true"
                $dest = Join-Path $txtPath.Text ($item.Name.Replace(" ", "_") + ".iso")
                if (-not (Test-Path $txtPath.Text)) { New-Item $txtPath.Text -ItemType Directory -Force | Out-Null }

                $responseTask = $HttpClient.GetAsync($url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead)
                while (-not $responseTask.IsCompleted) { &$CapNhatUI; Start-Sleep -Milliseconds 50 }
                
                $response = $responseTask.Result
                if (-not $response.IsSuccessStatusCode) {
                    $item.Status = "❌ Lỗi Drive"; $item.StatusColor = "#D32F2F"
                    continue
                }

                $totalBytes = $response.Content.Headers.ContentLength
                $totalMB = [Math]::Round($totalBytes / 1MB, 2)
                $stream = $response.Content.ReadAsStreamAsync().Result
                $fileStream = [System.IO.File]::Create($dest)
                $buffer = New-Object byte[] 262144 # 256KB buffer
                $totalRead = 0
                
                $sw_speed = [System.Diagnostics.Stopwatch]::StartNew()
                $sw_ui = [System.Diagnostics.Stopwatch]::StartNew()
                $bytesInInterval = 0

                while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    if ($script:CancelDL) { break }
                    $fileStream.Write($buffer, 0, $bytesRead)
                    $totalRead += $bytesRead
                    $bytesInInterval += $bytesRead

                    # Cập nhật UI mỗi 400ms để tránh giật lag
                    if ($sw_ui.ElapsedMilliseconds -ge 400) {
                        $phanTram = [int](($totalRead / $totalBytes) * 100)
                        $sec = $sw_speed.Elapsed.TotalSeconds
                        $speed = if ($sec -gt 0) { ($bytesInInterval / $sec) / 1MB } else { 0 }
                        
                        $pgBar.Value = $phanTram
                        $lblStatus.Text = "🚀 Đang tải: $($item.Name)"
                        $lblSpeed.Text = "Tốc độ: $([Math]::Round($speed, 2)) MB/s"
                        $lblSize.Text = "Đã tải: $([Math]::Round($totalRead/1MB, 1)) MB / $totalMB MB ($phanTram%)"
                        
                        $item.Status = "📥 $phanTram %"; $BangISO.Items.Refresh()
                        
                        # Reset để tính tốc độ cho interval tiếp theo
                        $bytesInInterval = 0
                        $sw_speed.Restart()
                        $sw_ui.Restart()
                        &$CapNhatUI
                    }
                }
                $fileStream.Close(); $fileStream.Dispose(); $stream.Dispose()
                
                if ($script:CancelDL) {
                    $item.Status = "🛑 Đã hủy"; $item.StatusColor = "#D32F2F"
                    if (Test-Path $dest) { Remove-Item $dest -Force }
                } else {
                    $item.Status = "✅ Hoàn tất"; $item.StatusColor = "#2E7D32"
                }
            } catch {
                $item.Status = "❌ Lỗi hệ thống"; $item.StatusColor = "#D32F2F"
            }
            $lblSpeed.Text = "Tốc độ: 0 MB/s"
            $BangISO.Items.Refresh()
        }
        $HttpClient.Dispose()
        $btnDownload.IsEnabled = $true
        $lblStatus.Text = "✅ ĐÃ KẾT THÚC QUÁ TRÌNH."
    })

    $CuaSo.ShowDialog() | Out-Null
}

&$LogicIsoClientV143