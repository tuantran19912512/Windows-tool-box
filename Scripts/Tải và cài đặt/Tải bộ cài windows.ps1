# ==========================================================
# VIETTOOLBOX ISO CLIENT V140 - SMART FILENAME & ETA
# Đặc trị: Tự lấy đuôi file từ Cloud, Tính thời gian tải (ETA)
# ==========================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Net.Http, System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$B64_Key = "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0"
$Global:DriveApiKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($B64_Key))

$LogicIsoClientV140 = {
    $RawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/iso_list.csv"
    $script:CancelDL = $false; $script:PauseDL = $false

    # --- GIAO DIỆN WPF ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VIETTOOLBOX V140 - SMART DOWNLOADER" Width="880" Height="820" WindowStartupLocation="CenterScreen" Background="#F4F7F9" FontFamily="Segoe UI">
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="TRUNG TÂM TẢI XUỐNG V140" FontSize="24" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Tự động lấy đuôi file từ Google Drive + ETA" Foreground="#666666"/>
        </StackPanel>
        <ListView Name="BangISO" Grid.Row="1" Background="White" BorderBrush="#CCCCCC" Margin="0,0,0,15">
            <ListView.View><GridView>
                <GridViewColumn Width="45"><GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Check}"/></DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
                <GridViewColumn Header="TÊN TRONG DANH SÁCH" DisplayMemberBinding="{Binding Name}" Width="520"/>
                <GridViewColumn Header="TRẠNG THÁI" Width="200"><GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Status}" Foreground="{Binding StatusColor}" FontWeight="SemiBold"/></DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
            </GridView></ListView.View>
        </ListView>
        <Border Grid.Row="2" Background="White" CornerRadius="6" Padding="12" Margin="0,0,0,15" BorderBrush="#DDDDDD" BorderThickness="1">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="70"/><ColumnDefinition Width="*"/><ColumnDefinition Width="140"/></Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="LƯU TẠI:" FontWeight="Bold" VerticalAlignment="Center"/><TextBox Name="txtPath" Grid.Column="1" Height="35" IsReadOnly="True" Background="#F0F0F0" Padding="8,0" VerticalContentAlignment="Center"/><Button Name="btnBrowse" Grid.Column="2" Content="CHỌN THƯ MỤC" Height="35" Cursor="Hand"/></Grid>
        </Border>
        <Grid Grid.Row="3" Margin="0,0,0,15">
            <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
            <Grid Grid.Row="0" Margin="0,0,0,5">
                <TextBlock Name="lblStatus" Text="Sẵn sàng..." FontWeight="SemiBold" Foreground="#1565C0" FontSize="14" HorizontalAlignment="Left"/>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
                    <TextBlock Name="lblTime" Text="" FontWeight="Bold" Foreground="#2E7D32" FontSize="14" Margin="0,0,15,0"/>
                    <TextBlock Name="lblSpeed" Text="0 MB/s" FontWeight="Bold" Foreground="#D84315" FontSize="14" FontFamily="Consolas"/>
                </StackPanel>
            </Grid>
            <ProgressBar Name="pgBar" Grid.Row="1" Height="30" Foreground="#2E7D32" Background="#E0E0E0" BorderThickness="0"/>
        </Grid>
        <Grid Grid.Row="4" Margin="0,0,0,15">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Button Name="btnPause" Grid.Column="0" Content="⏸️ TẠM DỪNG" Height="45"/><Button Name="btnResume" Grid.Column="2" Content="▶️ TIẾP TỤC" Height="45"/><Button Name="btnCancel" Grid.Column="4" Content="⏹️ HỦY LỆNH" Height="45"/>
        </Grid>
        <Grid Grid.Row="5">
            <Grid.ColumnDefinitions><ColumnDefinition Width="1*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="2.5*"/></Grid.ColumnDefinitions>
            <Button Name="btnSync" Grid.Column="0" Content="🔄 LÀM MỚI"/><Button Name="btnDownload" Grid.Column="2" Content="🚀 BẮT ĐẦU TẢI FILE" Height="60" Background="#007ACC" Foreground="White" FontSize="18" FontWeight="Bold"/>
        </Grid>
    </Grid>
</Window>
"@

    $DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaGiaoDien)))
    $CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

    $BangISO = $CuaSo.FindName("BangISO"); $txtPath = $CuaSo.FindName("txtPath"); $btnBrowse = $CuaSo.FindName("btnBrowse")
    $lblStatus = $CuaSo.FindName("lblStatus"); $lblSpeed = $CuaSo.FindName("lblSpeed"); $lblTime = $CuaSo.FindName("lblTime")
    $pgBar = $CuaSo.FindName("pgBar"); $btnPause = $CuaSo.FindName("btnPause"); $btnResume = $CuaSo.FindName("btnResume")
    $btnCancel = $CuaSo.FindName("btnCancel"); $btnSync = $CuaSo.FindName("btnSync"); $btnDownload = $CuaSo.FindName("btnDownload")

    $Global:DanhSachDuLieu = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
    $BangISO.ItemsSource = $Global:DanhSachDuLieu
    $txtPath.Text = Join-Path ([Environment]::GetFolderPath("Desktop")) "VietToolbox_Downloads"

    $CapNhatGiaoDien = { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) }

    function Load-IsoList {
        try {
            $csv = Invoke-WebRequest -Uri ($RawUrl + "?t=" + (Get-Date -UFormat %s)) -UseBasicParsing | ConvertFrom-Csv
            $Global:DanhSachDuLieu.Clear()
            foreach ($r in $csv) { if ($r.Name -and $r.FileID) { $Global:DanhSachDuLieu.Add([PSCustomObject]@{ Check = $false; Name = $r.Name; FileID = $r.FileID; Status = "Sẵn sàng"; StatusColor = "#666666" }) } }
            $lblStatus.Text = "✅ Đã đồng bộ danh sách."
        } catch { $lblStatus.Text = "❌ Lỗi kết nối!" }
    }

    $CuaSo.Add_ContentRendered({ Load-IsoList })
    $btnSync.Add_Click({ Load-IsoList })
    $btnBrowse.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtPath.Text = $fb.SelectedPath } })

    $btnDownload.Add_Click({
        $DaChon = @($Global:DanhSachDuLieu | Where-Object { $_.Check -eq $true })
        if ($DaChon.Count -eq 0) { return }
        $btnDownload.IsEnabled = $false; $btnCancel.IsEnabled = $true; $btnPause.IsEnabled = $true
        $script:CancelDL = $false; $script:PauseDL = $false
        $HttpClient = New-Object System.Net.Http.HttpClient
        $HttpClient.Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
        
        foreach ($item in $DaChon) {
            $item.Status = "🔍 Đang lấy tên file..."; &$CapNhatGiaoDien
            
            # --- CHIÊU MỚI: LẤY TÊN THẬT VÀ ĐUÔI FILE TỪ GOOGLE DRIVE ---
            try {
                $metaUrl = "https://www.googleapis.com/drive/v3/files/$($item.FileID)?fields=name&key=$($Global:DriveApiKey)"
                $metaResponse = Invoke-RestMethod -Uri $metaUrl
                $realName = $metaResponse.name.Replace(" ", "_")
                $item.Status = "⏳ Đang kết nối..."; $CuaSo.Dispatcher.Invoke([action]{ $BangISO.Items.Refresh() })
            } catch {
                $realName = $item.Name.Replace(" ", "_") + ".iso" # Fallback nếu lỗi meta
            }

            $dest = Join-Path $txtPath.Text $realName
            if (-not (Test-Path $txtPath.Text)) { New-Item $txtPath.Text -ItemType Directory -Force | Out-Null }
            
            $url = "https://www.googleapis.com/drive/v3/files/$($item.FileID)?alt=media&key=$($Global:DriveApiKey)&acknowledgeAbuse=true"

            try {
                $response = $HttpClient.GetAsync($url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
                if (-not $response.IsSuccessStatusCode) { $item.Status = "❌ Lỗi link"; continue }

                $totalBytes = $response.Content.Headers.ContentLength
                $stream = $response.Content.ReadAsStreamAsync().Result
                $fileStream = [System.IO.File]::Create($dest)
                $buffer = New-Object byte[] 102400
                $totalRead = 0; $chunkRead = 0; $sw = [System.Diagnostics.Stopwatch]::StartNew()

                $item.Status = "⬇️ Đang tải..."; $CuaSo.Dispatcher.Invoke([action]{ $BangISO.Items.Refresh() })

                while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    if ($script:CancelDL) { break }
                    while ($script:PauseDL) { &$CapNhatGiaoDien; Start-Sleep -Milliseconds 200 }
                    
                    $fileStream.Write($buffer, 0, $bytesRead)
                    $totalRead += $bytesRead; $chunkRead += $bytesRead

                    if ($sw.ElapsedMilliseconds -ge 800) {
                        $pgBar.Value = if ($totalBytes -gt 0) { [math]::Min(100, [int](($totalRead / $totalBytes) * 100)) } else { 0 }
                        $tocDoByte = $chunkRead / $sw.Elapsed.TotalSeconds
                        $lblSpeed.Text = "$([Math]::Round($tocDoByte / 1MB, 2)) MB/s"
                        
                        # TÍNH ETA (THỜI GIAN CÒN LẠI)
                        if ($totalBytes -gt 0 -and $tocDoByte -gt 0) {
                            $ts = [TimeSpan]::FromSeconds(($totalBytes - $totalRead) / $tocDoByte)
                            $lblTime.Text = "⏳ Còn lại: $(if($ts.TotalHours -ge 1){[int]$ts.TotalHours + 'g '})$($ts.Minutes)p $($ts.Seconds)s"
                        }

                        $lblStatus.Text = "Tải file: $realName ($([Math]::Round($totalRead/1GB, 2)) / $([Math]::Round($totalBytes/1GB, 2)) GB)"
                        $sw.Restart(); $chunkRead = 0; &$CapNhatGiaoDien
                    }
                }
                $fileStream.Close(); $fileStream.Dispose(); $stream.Close(); $stream.Dispose()
                $item.Status = if ($script:CancelDL) { "🛑 Đã hủy" } else { "✅ Hoàn tất" }
                $CuaSo.Dispatcher.Invoke([action]{ $BangISO.Items.Refresh() })
                if ($script:CancelDL) { break }
            } catch { $item.Status = "❌ Lỗi mạng" }
        }
        $HttpClient.Dispose(); $btnDownload.IsEnabled = $true; $btnCancel.IsEnabled = $false; $lblTime.Text = ""; $lblSpeed.Text = "0 MB/s"
    })
    $CuaSo.ShowDialog() | Out-Null
}
&$LogicIsoClientV140