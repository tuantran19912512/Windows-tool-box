# ==========================================================
# VIETTOOLBOX ISO CLIENT V143 - MULTI-TASKING (FIX FREEZE UI)
# Đặc trị: Nút bấm bị đơ, Treo giao diện khi đang tải
# ==========================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Net.Http, System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$B64_Key = "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0"
$Global:DriveApiKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($B64_Key))

$LogicIsoClientV143 = {
    $RawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/iso_list.csv"
    $script:CancelDL = $false; $script:PauseDL = $false

    # --- GIAO DIỆN WPF (TỐI ƯU RESPONSIVE) ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="VIETTOOLBOX V143 - MULTI-TASKING" Width="880" Height="820" WindowStartupLocation="CenterScreen" Background="#F4F7F9" FontFamily="Segoe UI">
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="TRUNG TÂM TẢI XUỐNG V143" FontSize="24" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Đã sửa lỗi đơ nút bấm - Hỗ trợ đa nhiệm mượt mà" Foreground="#666666"/>
        </StackPanel>

        <ListView Name="BangISO" Grid.Row="1" Background="White" BorderBrush="#CCCCCC" Margin="0,0,0,15">
            <ListView.View><GridView>
                <GridViewColumn Width="45"><GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Check}"/></DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
                <GridViewColumn Header="TÊN FILE" DisplayMemberBinding="{Binding Name}" Width="520"/>
                <GridViewColumn Header="TRẠNG THÁI" Width="200"><GridViewColumn.CellTemplate><DataTemplate><TextBlock Text="{Binding Status}" Foreground="{Binding StatusColor}" FontWeight="SemiBold"/></DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
            </GridView></ListView.View>
        </ListView>

        <Border Grid.Row="2" Background="White" CornerRadius="6" Padding="12" Margin="0,0,0,15" BorderBrush="#DDDDDD" BorderThickness="1">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="70"/><ColumnDefinition Width="*"/><ColumnDefinition Width="140"/></Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="LƯU TẠI:" FontWeight="Bold" VerticalAlignment="Center"/><TextBox Name="txtPath" Grid.Column="1" Height="35" IsReadOnly="True" Background="#F0F0F0" Padding="8,0" VerticalContentAlignment="Center"/><Button Name="btnBrowse" Grid.Column="2" Content="CHỌN THƯ MỤC" Height="35" Cursor="Hand" FontWeight="Bold"/></Grid>
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
            <Button Name="btnPause" Grid.Column="0" Content="⏸️ TẠM DỪNG" Height="45" Background="#FFF59D" Foreground="#F57F17" Cursor="Hand" FontWeight="Bold"/>
            <Button Name="btnResume" Grid.Column="2" Content="▶️ TIẾP TỤC" Height="45" Background="#A5D6A7" Foreground="#1B5E20" Cursor="Hand" FontWeight="Bold" IsEnabled="False"/>
            <Button Name="btnCancel" Grid.Column="4" Content="⏹️ HỦY LỆNH" Height="45" Background="#EF9A9A" Foreground="#B71C1C" Cursor="Hand" FontWeight="Bold"/>
        </Grid>

        <Grid Grid.Row="5">
            <Grid.ColumnDefinitions><ColumnDefinition Width="1*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="2.5*"/></Grid.ColumnDefinitions>
            <Button Name="btnSync" Grid.Column="0" Content="🔄 LÀM MỚI" Height="60" Background="#455A64" Foreground="White" Cursor="Hand" FontWeight="Bold"/><Button Name="btnDownload" Grid.Column="2" Content="🚀 BẮT ĐẦU TẢI" Height="60" Background="#007ACC" Foreground="White" FontSize="18" FontWeight="Bold" Cursor="Hand"/>
        </Grid>
    </Grid>
</Window>
"@

    $DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($MaGiaoDien)))
    $CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

    # Ánh xạ UI
    $BangISO = $CuaSo.FindName("BangISO"); $txtPath = $CuaSo.FindName("txtPath"); $btnBrowse = $CuaSo.FindName("btnBrowse")
    $lblStatus = $CuaSo.FindName("lblStatus"); $lblSpeed = $CuaSo.FindName("lblSpeed"); $lblTime = $CuaSo.FindName("lblTime")
    $pgBar = $CuaSo.FindName("pgBar"); $btnPause = $CuaSo.FindName("btnPause"); $btnResume = $CuaSo.FindName("btnResume")
    $btnCancel = $CuaSo.FindName("btnCancel"); $btnSync = $CuaSo.FindName("btnSync"); $btnDownload = $CuaSo.FindName("btnDownload")

    $Global:DanhSachDuLieu = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
    $BangISO.ItemsSource = $Global:DanhSachDuLieu
    $txtPath.Text = Join-Path ([Environment]::GetFolderPath("Desktop")) "VietToolbox_Downloads"

    # Hàm cực quan trọng để chống treo nút bấm
    $CapNhatGiaoDien = { 
        [System.Windows.Forms.Application]::DoEvents()
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) 
    }

    function Load-IsoList {
        try {
            # Báo trạng thái đang tải để người dùng biết
            $lblStatus.Text = "🔄 Đang làm mới danh sách..."
            &$CapNhatGiaoDien
            
            $csv = Invoke-WebRequest -Uri ($RawUrl + "?t=" + (Get-Date -UFormat %s)) -UseBasicParsing | ConvertFrom-Csv
            
            # TỐI ƯU HÓA: Gom dữ liệu vào mảng tạm, KHÔNG Add lắt nhắt
            $MangTam = foreach ($r in $csv) { 
                if ($r.Name -and $r.FileID) { 
                    [PSCustomObject]@{ Check = $false; Name = $r.Name; FileID = $r.FileID; Status = "Sẵn sàng"; StatusColor = "#666666" } 
                } 
            }
            
            # Khởi tạo danh sách mới ôm trọn mảng tạm và gán thẳng vào giao diện trong 1 nhịp
            $Global:DanhSachDuLieu = New-Object System.Collections.ObjectModel.ObservableCollection[Object]($MangTam)
            $BangISO.ItemsSource = $Global:DanhSachDuLieu
            
            $lblStatus.Text = "✅ Đã cập nhật $($Global:DanhSachDuLieu.Count) mục mới nhất."
        } catch { 
            $lblStatus.Text = "❌ Lỗi mạng khi lấy list!" 
        }
    }

    # Sự kiện nút bấm bổ trợ
    $CuaSo.Add_ContentRendered({ Load-IsoList })
    $btnSync.Add_Click({ Load-IsoList })
    $btnBrowse.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtPath.Text = $fb.SelectedPath } })
    
    # Logic điều khiển trạng thái
    $btnPause.Add_Click({ $script:PauseDL = $true; $btnPause.IsEnabled = $false; $btnResume.IsEnabled = $true; $lblStatus.Text = "⏸️ Đã tạm dừng tải..." })
    $btnResume.Add_Click({ $script:PauseDL = $false; $btnResume.IsEnabled = $false; $btnPause.IsEnabled = $true; $lblStatus.Text = "▶️ Đang tiếp tục tải..." })
    $btnCancel.Add_Click({ $script:CancelDL = $true; $lblStatus.Text = "⏹️ Đang xử lý lệnh hủy..." })

    # --- CHU TRÌNH TẢI FILE ĐA NHIỆM ---
    $btnDownload.Add_Click({
        $DaChon = @($Global:DanhSachDuLieu | Where-Object { $_.Check -eq $true })
        if ($DaChon.Count -eq 0) { return }
        
        # Thiết lập UI khi bắt đầu
        $btnDownload.IsEnabled = $false; $btnSync.IsEnabled = $false; $btnBrowse.IsEnabled = $false
        $script:CancelDL = $false; $script:PauseDL = $false
        
        $HttpClient = New-Object System.Net.Http.HttpClient
        $HttpClient.Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
        
        foreach ($item in $DaChon) {
            if ($script:CancelDL) { break }
            $pgBar.Value = 0; $lblTime.Text = ""; $lblSpeed.Text = "0 MB/s"
            
            try {
                $item.Status = "🔍 Đang check Metadata..."; &$CapNhatGiaoDien
                $metaUrl = "https://www.googleapis.com/drive/v3/files/$($item.FileID)?fields=name&key=$($Global:DriveApiKey)"
                $metaResponse = Invoke-RestMethod -Uri $metaUrl
                $realName = $metaResponse.name.Replace(" ", "_")
                $dest = Join-Path $txtPath.Text $realName
                if (-not (Test-Path $txtPath.Text)) { New-Item $txtPath.Text -ItemType Directory -Force | Out-Null }
                
                $item.Status = "⏳ Đang kết nối..."; $CuaSo.Dispatcher.Invoke([action]{ $BangISO.Items.Refresh() }); &$CapNhatGiaoDien
                $url = "https://www.googleapis.com/drive/v3/files/$($item.FileID)?alt=media&key=$($Global:DriveApiKey)&acknowledgeAbuse=true"
                $response = $HttpClient.GetAsync($url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
                
                $totalBytes = $response.Content.Headers.ContentLength
                $stream = $response.Content.ReadAsStreamAsync().Result
                $fileStream = [System.IO.File]::Create($dest)
                $buffer = New-Object byte[] 1048576 
                $totalRead = 0; $chunkRead = 0; $sw = [System.Diagnostics.Stopwatch]::StartNew()

                $item.Status = "⬇️ Đang tải..."; $item.StatusColor = "#1565C0"
                $CuaSo.Dispatcher.Invoke([action]{ $BangISO.Items.Refresh() })

                # VÒNG LẶP TẢI FILE (NƠI NHẢ LUỒNG ĐỂ NÚT BẤM HOẠT ĐỘNG)
                while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    # Kiểm tra lệnh Hủy
                    if ($script:CancelDL) { break }
                    
                    # Kiểm tra lệnh Tạm dừng (Dùng vòng lặp nhả luồng liên tục)
                    while ($script:PauseDL) { 
                        if ($script:CancelDL) { break }
                        Start-Sleep -Milliseconds 100
                        &$CapNhatGiaoDien 
                    }
                    
                    $fileStream.Write($buffer, 0, $bytesRead)
                    $totalRead += $bytesRead; $chunkRead += $bytesRead

                    # Cập nhật UI & Nhả luồng để nút bấm không bị đơ
                    if ($sw.ElapsedMilliseconds -ge 800) {
                        $phanTram = if ($totalBytes -gt 0) { [math]::Min(100, [int](($totalRead / $totalBytes) * 100)) } else { 0 }
                        $pgBar.Value = $phanTram
                        $tocDoByte = $chunkRead / $sw.Elapsed.TotalSeconds
                        $lblSpeed.Text = "$([Math]::Round($tocDoByte / 1MB, 2)) MB/s"
                        
                        if ($totalBytes -gt 0 -and $tocDoByte -gt 0) {
                            $ts = [TimeSpan]::FromSeconds(($totalBytes - $totalRead) / $tocDoByte)
                            $lblTime.Text = "⏳ Còn lại: $(if($ts.TotalHours -ge 1){[int]$ts.TotalHours + 'g '})$($ts.Minutes)p $($ts.Seconds)s"
                        }
                        $lblStatus.Text = "Đang tải: $realName ($phanTram%)"
                        $sw.Restart(); $chunkRead = 0
                        &$CapNhatGiaoDien # ÉP UI PHẢI NGHE LỆNH TỪ CÁC NÚT KHÁC
                    }
                }
                
                $fileStream.Close(); $fileStream.Dispose(); $stream.Close(); $stream.Dispose()
                
                if (-not $script:CancelDL) { 
                    $pgBar.Value = 100; $item.Status = "✅ Hoàn tất"; $item.StatusColor = "#2E7D32"
                } else { 
                    $item.Status = "🛑 Đã hủy"; $item.StatusColor = "#D32F2F"
                    if (Test-Path $dest) { Remove-Item $dest -Force -ErrorAction SilentlyContinue }
                }
                $CuaSo.Dispatcher.Invoke([action]{ $BangISO.Items.Refresh() }); &$CapNhatGiaoDien
            } catch { $item.Status = "❌ Lỗi mạng" }
        }
        
        # Reset UI khi xong
        $HttpClient.Dispose()
        $btnDownload.IsEnabled = $true; $btnSync.IsEnabled = $true; $btnBrowse.IsEnabled = $true
        $btnPause.IsEnabled = $true; $btnResume.IsEnabled = $false
        $lblTime.Text = ""; $lblSpeed.Text = "0 MB/s"; $lblStatus.Text = "✅ CHU TRÌNH KẾT THÚC!"
        &$CapNhatGiaoDien
    })

    $CuaSo.ShowDialog() | Out-Null
}
&$LogicIsoClientV143