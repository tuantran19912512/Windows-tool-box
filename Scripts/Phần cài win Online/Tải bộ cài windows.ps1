# ==========================================================
# VIETTOOLBOX ISO CLIENT V148 - GIỮ NGUYÊN ĐỊNH DẠNG GỐC
# ==========================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Net.Http, System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# --- DANH SÁCH API KEYS ---
$Global:B64_Key_Pool = @(
    "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0", # Key 1
    "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR", # Key 2
    "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v", # Key 3
    "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv"  # Key 4
)
$Global:CurrentKeyIndex = 0

function Get-NextApiKey {
    $rawKey = $Global:B64_Key_Pool[$Global:CurrentKeyIndex]
    return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($rawKey))
}

$LogicIsoClientV148 = {
    $RawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/iso_list.csv"
    $script:CancelDL = $false

    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        Title="VIETTOOLBOX V148 - DỮ PHÒNG WEB + GIỮ ĐỊNH DẠNG" Width="900" Height="850" 
        WindowStartupLocation="CenterScreen" Background="#F0F2F5" FontFamily="Segoe UI">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="HỆ THỐNG TẢI FILE - GIỮ NGUYÊN ĐỊNH DẠNG" FontSize="26" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Đã sửa: Tải file theo đúng tên và đuôi file trong danh sách CSV." Foreground="#555555"/>
        </StackPanel>

        <ListView Name="BangISO" Grid.Row="1" Background="White" BorderBrush="#CCCCCC" Margin="0,0,0,15">
            <ListView.View><GridView>
                <GridViewColumn Width="45">
                    <GridViewColumn.CellTemplate>
                        <DataTemplate><CheckBox IsChecked="{Binding Check, Mode=TwoWay, UpdateSourceTrigger=PropertyChanged}"/></DataTemplate>
                    </GridViewColumn.CellTemplate>
                </GridViewColumn>
                <GridViewColumn Header="TÊN FILE" DisplayMemberBinding="{Binding Name}" Width="520"/>
                <GridViewColumn Header="TRẠNG THÁI" Width="220">
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
                <TextBlock Name="lblStatus" Text="Sẵn sàng..." FontWeight="Bold" Foreground="#1565C0" FontSize="14" Width="420"/>
                <TextBlock Name="lblSpeed" Text="Tốc độ: 0 MB/s" FontWeight="Bold" Foreground="#D81B60" FontSize="14" TextAlignment="Right" Width="400"/>
            </StackPanel>
            <ProgressBar Name="pgBar" Grid.Row="1" Height="35" Foreground="#2E7D32" Background="#E0E0E0" BorderThickness="0"/>
            <TextBlock Name="lblSize" Grid.Row="2" Text="Tự động nhận diện định dạng file" HorizontalAlignment="Center" Margin="0,5,0,0" Foreground="#333333" FontWeight="SemiBold"/>
        </Grid>

        <Grid Grid.Row="4" Margin="0,0,0,15">
            <Button Name="btnCancel" Content="⏹️ DỪNG TIẾN TRÌNH" Height="45" Background="#FFEBEE" Foreground="#B71C1C" BorderBrush="#EF9A9A" Cursor="Hand" FontWeight="Bold"/>
        </Grid>

        <Grid Grid.Row="5">
            <Grid.ColumnDefinitions><ColumnDefinition Width="1*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="2.5*"/></Grid.ColumnDefinitions>
            <Button Name="btnSync" Grid.Column="0" Content="🔄 LÀM MỚI" Height="65" Background="#455A64" Foreground="White" Cursor="Hand" FontWeight="Bold"/>
            <Button Name="btnDownload" Grid.Column="2" Content="🚀 BẮT ĐẦU TẢI" Height="65" Background="#007ACC" Foreground="White" FontSize="20" FontWeight="Bold" Cursor="Hand"/>
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
            $lblStatus.Text = "🔄 Đang lấy danh sách..."
            &$CapNhatUI
            $csv = Invoke-WebRequest -Uri ($RawUrl + "?t=" + (Get-Date -UFormat %s)) -UseBasicParsing | ConvertFrom-Csv
            $Global:DanhSachDuLieu.Clear()
            foreach ($r in $csv) { 
                if ($r.Name) { 
                    $Global:DanhSachDuLieu.Add([PSCustomObject]@{ Check=$false; Name=$r.Name; FileID=$r.FileID; Status="Sẵn sàng"; StatusColor="#666666" })
                } 
            }
            $lblStatus.Text = "✅ Đã nạp $($Global:DanhSachDuLieu.Count) mục."
        } catch { $lblStatus.Text = "❌ Lỗi kết nối GitHub!" }
    }

    $CuaSo.Add_ContentRendered({ Load-List })
    $btnSync.Add_Click({ Load-List })
    $btnBrowse.Add_Click({ $fb = New-Object System.Windows.Forms.FolderBrowserDialog; if ($fb.ShowDialog() -eq "OK") { $txtPath.Text = $fb.SelectedPath } })
    $btnCancel.Add_Click({ $script:CancelDL = $true; $lblStatus.Text = "🛑 Đang dừng..." })

    $btnDownload.Add_Click({
        $DaChon = @($Global:DanhSachDuLieu | Where-Object { $_.Check -eq $true })
        if ($DaChon.Count -eq 0) { return }

        $btnDownload.IsEnabled = $false; $script:CancelDL = $false
        $HttpClient = New-Object System.Net.Http.HttpClient
        
        foreach ($item in $DaChon) {
            if ($script:CancelDL) { break }
            
            $RetryWithNextKey = $true

            while ($RetryWithNextKey) {
                try {
                    $CurrentApiKey = Get-NextApiKey
                    $item.Status = "🌐 Đang kết nối..."; $item.StatusColor = "#1565C0"
                    $BangISO.Items.Refresh(); &$CapNhatUI

                    $url = "https://www.googleapis.com/drive/v3/files/$($item.FileID)?alt=media&key=$CurrentApiKey&acknowledgeAbuse=true"
                    
                    # --- DÒNG ĐÃ SỬA: SỬ DỤNG TÊN FILE GỐC TỪ CSV ---
                    $SafeFileName = $item.Name.Replace(" ", "_")
                    $dest = Join-Path $txtPath.Text $SafeFileName
                    
                    if (-not (Test-Path $txtPath.Text)) { New-Item $txtPath.Text -ItemType Directory -Force | Out-Null }

                    $responseTask = $HttpClient.GetAsync($url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead)
                    while (-not $responseTask.IsCompleted) { &$CapNhatUI; Start-Sleep -Milliseconds 50 }
                    $response = $responseTask.Result

                    if (-not $response.IsSuccessStatusCode) {
                        $statusCode = [int]$response.StatusCode
                        if ($statusCode -eq 403 -or $statusCode -eq 429) {
                            if ($Global:CurrentKeyIndex -lt ($Global:B64_Key_Pool.Count - 1)) {
                                $Global:CurrentKeyIndex++
                                $lblStatus.Text = "⚠️ Đang đổi sang Key dự phòng #$($Global:CurrentKeyIndex + 1)..."
                                &$CapNhatUI; Start-Sleep -Seconds 1; continue 
                            } else {
                                $item.Status = "⚠️ Chuyển Web"; $item.StatusColor = "#F57C00"
                                $lblStatus.Text = "❌ API lỗi. Đang mở trình duyệt..."
                                Start-Process "https://drive.google.com/uc?id=$($item.FileID)&export=download"
                                $RetryWithNextKey = $false; continue
                            }
                        } else {
                            $item.Status = "❌ Lỗi HTTP $statusCode"; $RetryWithNextKey = $false; continue
                        }
                    }

                    $RetryWithNextKey = $false
                    $totalBytes = $response.Content.Headers.ContentLength
                    $totalMB = [Math]::Round($totalBytes / 1MB, 2)
                    $stream = $response.Content.ReadAsStreamAsync().Result
                    $fileStream = [System.IO.File]::Create($dest)
                    $buffer = New-Object byte[] 262144
                    $totalRead = 0
                    $sw_speed = [System.Diagnostics.Stopwatch]::StartNew(); $sw_ui = [System.Diagnostics.Stopwatch]::StartNew()
                    $bytesInInterval = 0

                    while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                        if ($script:CancelDL) { break }
                        $fileStream.Write($buffer, 0, $bytesRead)
                        $totalRead += $bytesRead; $bytesInInterval += $bytesRead

                        if ($sw_ui.ElapsedMilliseconds -ge 500) {
                            $phanTram = [int](($totalRead / $totalBytes) * 100)
                            $speed = ($bytesInInterval / $sw_speed.Elapsed.TotalSeconds) / 1MB
                            $pgBar.Value = $phanTram
                            $lblStatus.Text = "🚀 Đang tải: $SafeFileName"
                            $lblSpeed.Text = "$([Math]::Round($speed, 2)) MB/s"
                            $lblSize.Text = "API #$($Global:CurrentKeyIndex + 1) | $phanTram %"
                            $item.Status = "📥 $phanTram %"; $BangISO.Items.Refresh()
                            $bytesInInterval = 0; $sw_speed.Restart(); $sw_ui.Restart(); &$CapNhatUI
                        }
                    }
                    $fileStream.Close(); $fileStream.Dispose(); $stream.Dispose()
                    $item.Status = if ($script:CancelDL) { "🛑 Đã hủy" } else { "✅ Hoàn tất" }
                    $item.StatusColor = if ($script:CancelDL) { "#D32F2F" } else { "#2E7D32" }

                } catch {
                    $item.Status = "❌ Lỗi hệ thống"; $RetryWithNextKey = $false
                }
            }
            $lblSpeed.Text = "0 MB/s"
            $BangISO.Items.Refresh()
        }
        $HttpClient.Dispose()
        $btnDownload.IsEnabled = $true
        $lblStatus.Text = "✅ TIẾN TRÌNH KẾT THÚC."
    })

    $CuaSo.ShowDialog() | Out-Null
}

&$LogicIsoClientV148