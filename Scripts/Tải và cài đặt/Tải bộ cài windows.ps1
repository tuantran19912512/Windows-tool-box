# ==========================================================
# VIETTOOLBOX ISO CLIENT V137 - WPF EDITION (AUTO EXTENSION)
# ==========================================================

# 1. ÉP CHẠY QUYỀN QUẢN TRỊ VIÊN
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. KHỞI TẠO MÔI TRƯỜNG WPF & THƯ VIỆN
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase
Add-Type -AssemblyName System.Net.Http, System.Windows.Forms
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Tối ưu kết nối mạng
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
[System.Net.ServicePointManager]::DefaultConnectionLimit = 100

# Giải mã API Key (Giữ nguyên gốc)
$B64_Key = "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0"
$Global:DriveApiKey = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($B64_Key))

$LogicIsoClientV137 = {
    $RawUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/iso_list.csv"
    $script:CancelDL = $false; $script:PauseDL = $false

    # --- 3. GIAO DIỆN XAML WPF ---
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VIETTOOLBOX - ISO V137 (AUTO EXTENSION WPF)" Width="880" Height="820"
        WindowStartupLocation="CenterScreen" Background="#F4F7F9" FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Opacity" Value="0.5"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,15">
            <TextBlock Text="TRUNG TÂM TẢI XUỐNG DỮ LIỆU WINDOWS" FontSize="24" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Hỗ trợ tải file ISO, WIM, ESD, ZIP, CAB tốc độ cao qua Fast API" Foreground="#666666"/>
        </StackPanel>

        <ListView Name="BangISO" Grid.Row="1" Background="White" BorderBrush="#CCCCCC" BorderThickness="1" Margin="0,0,0,15">
            <ListView.View>
                <GridView>
                    <GridViewColumn Width="45">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate><CheckBox IsChecked="{Binding Check}"/></DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="TÊN PHIÊN BẢN (GỒM ĐUÔI FILE)" DisplayMemberBinding="{Binding Name}" Width="520"/>
                    <GridViewColumn Header="TRẠNG THÁI" Width="200">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate><TextBlock Text="{Binding Status}" Foreground="{Binding StatusColor}" FontWeight="SemiBold"/></DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                </GridView>
            </ListView.View>
        </ListView>

        <Border Grid.Row="2" Background="White" CornerRadius="6" Padding="12" Margin="0,0,0,15" BorderBrush="#DDDDDD" BorderThickness="1">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="70"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="140"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="LƯU TẠI:" FontWeight="Bold" VerticalAlignment="Center" Foreground="#333333"/>
                <TextBox Name="txtPath" Grid.Column="1" Height="35" VerticalContentAlignment="Center" IsReadOnly="True" Margin="0,0,10,0" Background="#F0F0F0" Padding="8,0" FontSize="14"/>
                <Button Name="btnBrowse" Grid.Column="2" Content="CHỌN THƯ MỤC" Height="35" Background="#ECEFF1" Foreground="#333333"/>
            </Grid>
        </Border>

        <Grid Grid.Row="3" Margin="0,0,0,15">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Grid Grid.Row="0" Margin="0,0,0,5">
                <TextBlock Name="lblStatus" Text="Sẵn sàng..." FontWeight="SemiBold" Foreground="#1565C0" FontSize="14" HorizontalAlignment="Left"/>
                <TextBlock Name="lblSpeed" Text="0 MB/s" FontWeight="Bold" Foreground="#D84315" FontSize="14" HorizontalAlignment="Right" FontFamily="Consolas"/>
            </Grid>
            <ProgressBar Name="pgBar" Grid.Row="1" Height="30" Foreground="#2E7D32" Background="#E0E0E0" BorderThickness="0"/>
        </Grid>

        <Grid Grid.Row="4" Margin="0,0,0,15">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/><ColumnDefinition Width="10"/>
                <ColumnDefinition Width="*"/><ColumnDefinition Width="10"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>
            <Button Name="btnPause" Grid.Column="0" Content="⏸️ TẠM DỪNG" Height="45" Background="#FFF59D" Foreground="#F57F17" IsEnabled="False"/>
            <Button Name="btnResume" Grid.Column="2" Content="▶️ TIẾP TỤC" Height="45" Background="#A5D6A7" Foreground="#1B5E20" IsEnabled="False"/>
            <Button Name="btnCancel" Grid.Column="4" Content="⏹️ HỦY LỆNH" Height="45" Background="#EF9A9A" Foreground="#B71C1C" IsEnabled="False"/>
        </Grid>

        <Grid Grid.Row="5">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="1*"/><ColumnDefinition Width="15"/><ColumnDefinition Width="2.5*"/>
            </Grid.ColumnDefinitions>
            <Button Name="btnSync" Grid.Column="0" Content="🔄 LÀM MỚI LIST" Height="60" Background="#455A64" Foreground="White"/>
            <Button Name="btnDownload" Grid.Column="2" Content="🚀 BẮT ĐẦU TẢI (FAST API)" Height="60" Background="#007ACC" Foreground="White" FontSize="18"/>
        </Grid>
    </Grid>
</Window>
"@

    # --- 4. KHỞI TẠO CỬA SỔ & ÁNH XẠ BIẾN ---
    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

    # Ánh xạ thành phần UI
    $BangISO = $CuaSo.FindName("BangISO")
    $txtPath = $CuaSo.FindName("txtPath")
    $btnBrowse = $CuaSo.FindName("btnBrowse")
    $lblStatus = $CuaSo.FindName("lblStatus")
    $lblSpeed = $CuaSo.FindName("lblSpeed")
    $pgBar = $CuaSo.FindName("pgBar")
    $btnPause = $CuaSo.FindName("btnPause")
    $btnResume = $CuaSo.FindName("btnResume")
    $btnCancel = $CuaSo.FindName("btnCancel")
    $btnSync = $CuaSo.FindName("btnSync")
    $btnDownload = $CuaSo.FindName("btnDownload")

    # Tạo danh sách liên kết dữ liệu cho WPF
    $Global:DanhSachDuLieu = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
    $BangISO.ItemsSource = $Global:DanhSachDuLieu

    # Thiết lập thư mục lưu mặc định
    $DriveMacDinh = (Get-PSDrive -PSProvider FileSystem | Sort-Object Free -Descending | Select-Object -First 1).Root
    $txtPath.Text = Join-Path $DriveMacDinh "VietToolbox_Downloads"

    # --- HÀM DOEVENTS CHO WPF (TRÁNH ĐƠ GIAO DIỆN) ---
    $CapNhatGiaoDien = {
        $Dispatcher = [System.Windows.Threading.Dispatcher]::CurrentDispatcher
        $Dispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
    }

    # --- 5. LOGIC LẤY DANH SÁCH ---
    function Load-IsoList {
        try {
            $lblStatus.Text = "Đang tải danh sách từ Cloud..."
            &$CapNhatGiaoDien

            $csv = Invoke-WebRequest -Uri ($RawUrl + "?t=" + (Get-Date -UFormat %s)) -UseBasicParsing | ConvertFrom-Csv
            $Global:DanhSachDuLieu.Clear()

            foreach ($r in $csv) {
                if ($r.Name -and $r.FileID) {
                    $Global:DanhSachDuLieu.Add([PSCustomObject]@{
                        Check = $false
                        Name = $r.Name
                        FileID = $r.FileID
                        Status = "Sẵn sàng"
                        StatusColor = "#666666"
                    })
                }
            }
            $lblStatus.Text = "✅ Đồng bộ xong $($Global:DanhSachDuLieu.Count) mục!"
            $lblStatus.Foreground = "#2E7D32"
        } catch { 
            $lblStatus.Text = "❌ Lỗi đồng bộ danh sách! Kiểm tra lại mạng."
            $lblStatus.Foreground = "#D32F2F"
        }
    }

    # --- 6. CÁC NÚT ĐIỀU KHIỂN PHỤ ---
    $CuaSo.Add_ContentRendered({ Load-IsoList })
    $btnSync.Add_Click({ Load-IsoList })
    
    $btnBrowse.Add_Click({ 
        $fb = New-Object System.Windows.Forms.FolderBrowserDialog
        if ($fb.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $txtPath.Text = $fb.SelectedPath } 
    })

    $btnPause.Add_Click({ 
        $script:PauseDL = $true; $btnPause.IsEnabled = $false; $btnResume.IsEnabled = $true
        $lblStatus.Text = "Đã tạm dừng..."
        $lblStatus.Foreground = "#F57F17"
    })
    
    $btnResume.Add_Click({ 
        $script:PauseDL = $false; $btnResume.IsEnabled = $false; $btnPause.IsEnabled = $true
        $lblStatus.Text = "Đang tiếp tục tải..."
        $lblStatus.Foreground = "#1565C0"
    })
    
    $btnCancel.Add_Click({ 
        $script:CancelDL = $true
        $lblStatus.Text = "Đang xử lý hủy lệnh..."
        $lblStatus.Foreground = "#D32F2F"
    })

    # --- 7. TRÁI TIM: LOGIC TẢI FILE ---
    $btnDownload.Add_Click({
        # Lấy danh sách các mục đã được Check
        $DaChon = @($Global:DanhSachDuLieu | Where-Object { $_.Check -eq $true })
        if ($DaChon.Count -eq 0) { 
            [System.Windows.MessageBox]::Show("Tuấn chưa chọn file nào để tải!", "Nhắc nhở", 0, 48)
            return 
        }
        
        $btnDownload.IsEnabled = $false; $btnCancel.IsEnabled = $true; $btnPause.IsEnabled = $true; $btnSync.IsEnabled = $false
        $script:CancelDL = $false; $script:PauseDL = $false
        
        $HttpClient = New-Object System.Net.Http.HttpClient
        $HttpClient.Timeout = [System.Threading.Timeout]::InfiniteTimeSpan
        
        foreach ($item in $DaChon) {
            # TỰ ĐỘNG NHẬN DIỆN ĐUÔI FILE (GIỮ NGUYÊN LOGIC)
            $rawFileName = $item.Name.Replace(" ", "_")
            if ($rawFileName -notmatch "\.(iso|wim|esd|zip|rar|exe|cab|img)$") {
                $rawFileName += ".iso"
            }
            
            $dest = Join-Path $txtPath.Text $rawFileName
            if (-not (Test-Path $txtPath.Text)) { New-Item $txtPath.Text -ItemType Directory -Force | Out-Null }
            
            $url = "https://www.googleapis.com/drive/v3/files/$($item.FileID)?alt=media&key=$($Global:DriveApiKey)&acknowledgeAbuse=true"
            $item.Status = "⏳ Đang kết nối..."
            $item.StatusColor = "#FF9800"
            $CuaSo.Dispatcher.Invoke([action]{ $BangISO.Items.Refresh() })
            &$CapNhatGiaoDien

            try {
                $response = $HttpClient.GetAsync($url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
                if (-not $response.IsSuccessStatusCode) {
                    $item.Status = "❌ Lỗi: $($response.StatusCode)"; $item.StatusColor = "#D32F2F"
                    $CuaSo.Dispatcher.Invoke([action]{ $BangISO.Items.Refresh() }); continue
                }

                $totalBytes = $response.Content.Headers.ContentLength
                $stream = $response.Content.ReadAsStreamAsync().Result
                $fileStream = [System.IO.File]::Create($dest)
                $buffer = New-Object byte[] 102400 # Bộ đệm 100KB tải tốc độ cao
                $totalRead = 0; $chunkRead = 0; $sw = [System.Diagnostics.Stopwatch]::StartNew()

                $item.Status = "⬇️ Đang tải..."; $item.StatusColor = "#1565C0"
                $CuaSo.Dispatcher.Invoke([action]{ $BangISO.Items.Refresh() })

                # Vòng lặp tải dữ liệu
                while (($bytesRead = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                    if ($script:CancelDL) { break }
                    
                    while ($script:PauseDL) { 
                        &$CapNhatGiaoDien; Start-Sleep -Milliseconds 200 
                        if ($script:CancelDL) { break }
                    }
                    if ($script:CancelDL) { break }
                    
                    if (-not $sw.IsRunning) { $sw.Start() }

                    $fileStream.Write($buffer, 0, $bytesRead)
                    $totalRead += $bytesRead
                    $chunkRead += $bytesRead

                    # Cập nhật thông số mỗi 0.8 giây để tránh treo màn hình
                    if ($sw.ElapsedMilliseconds -ge 800) {
                        $pgBar.Value = if ($totalBytes -gt 0) { [math]::Min(100, [int](($totalRead / $totalBytes) * 100)) } else { 0 }
                        $tocDo = [Math]::Round(($chunkRead / $sw.Elapsed.TotalSeconds) / 1MB, 2)
                        $lblSpeed.Text = "$tocDo MB/s"
                        
                        $daTai = [Math]::Round($totalRead/1GB, 2)
                        $tongCong = if ($totalBytes -gt 0) { [Math]::Round($totalBytes/1GB, 2) } else { "?" }
                        $lblStatus.Text = "Đang tải $($item.Name): $daTai / $tongCong GB"
                        
                        $sw.Restart(); $chunkRead = 0
                        &$CapNhatGiaoDien
                    }
                }
                
                $fileStream.Close(); $fileStream.Dispose(); $stream.Close(); $stream.Dispose()
                
                # Xử lý kết quả sau vòng lặp
                if ($script:CancelDL) { 
                    $item.Status = "🛑 Đã hủy"; $item.StatusColor = "#D32F2F"
                    if (Test-Path $dest) { Remove-Item $dest -Force -ErrorAction SilentlyContinue }
                    $CuaSo.Dispatcher.Invoke([action]{ $BangISO.Items.Refresh() })
                    break 
                } else { 
                    $item.Status = "✅ Hoàn tất"; $item.StatusColor = "#2E7D32"
                    $CuaSo.Dispatcher.Invoke([action]{ $BangISO.Items.Refresh() })
                }
            } catch { 
                $item.Status = "❌ Lỗi kết nối/mạng"; $item.StatusColor = "#D32F2F"
                $CuaSo.Dispatcher.Invoke([action]{ $BangISO.Items.Refresh() })
            }
        }
        
        $HttpClient.Dispose()
        $btnDownload.IsEnabled = $true; $btnCancel.IsEnabled = $false; $btnSync.IsEnabled = $true
        $btnPause.IsEnabled = $false; $btnResume.IsEnabled = $false
        $pgBar.Value = 0; $lblSpeed.Text = "0 MB/s"
        
        if ($script:CancelDL) { $lblStatus.Text = "Đã hủy toàn bộ tiến trình tải." }
        else { $lblStatus.Text = "Chu trình tải xuống hoàn tất!" }
    })

    $CuaSo.ShowDialog() | Out-Null
}

&$LogicIsoClientV137