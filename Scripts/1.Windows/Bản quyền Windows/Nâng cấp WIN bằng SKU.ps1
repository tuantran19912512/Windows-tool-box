# ==============================================================================
# VIETTOOLBOX V67 - MODULE CLIENT (NÂNG CẤP WINDOWS)
# Tác giả: Tuấn
# ==============================================================================

# 1. Ép hệ thống dùng chuẩn UTF-8 (Bản chuẩn cho PowerShell 5.1)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$LogicVietToolboxClientV67 = {
    # 2. Cấu hình Link Cloud
    $UrlCSV = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/main/DanhMucSKU.csv"
    $BaseZipUrl = "https://raw.githubusercontent.com/tuantran19912512/skuwin/main/"

    # 3. Giao diện WPF
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        Title="VietToolbox - Nâng Cấp Windows" Width="550" Height="500" 
        WindowStartupLocation="CenterScreen" Background="#F0F2F5" FontFamily="Segoe UI">
    <Grid Margin="25">
        <StackPanel>
            <TextBlock Text="NÂNG CẤP WINDOWS CLOUD" FontWeight="Bold" FontSize="20" Foreground="#1A237E" Margin="0,0,0,5"/>
            <Separator Margin="0,0,0,20"/>

            <Border Background="#E3F2FD" CornerRadius="10" Padding="15" Margin="0,0,0,20" BorderBrush="#BBDEFB" BorderThickness="1">
                <StackPanel Orientation="Horizontal">
                    <TextBlock Text="🖥️ Phiên bản hiện tại:" FontWeight="Bold" Foreground="#1565C0" Margin="0,0,10,0"/>
                    <TextBlock Name="TxtCurrentVer" Text="Đang kiểm tra..." FontWeight="Bold" Foreground="#D32F2F"/>
                </StackPanel>
            </Border>

            <TextBlock Text="Chọn phiên bản muốn nâng cấp:" FontWeight="Bold" Margin="0,0,0,10"/>
            <ComboBox Name="CbEditions" Height="40" VerticalContentAlignment="Center" Padding="10,0" Margin="0,0,0,20">
                 <ComboBox.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="8"/></Style></ComboBox.Resources>
            </ComboBox>

            <Button Name="BtnStart" Content="🚀 BẮT ĐẦU NÂNG CẤP" Height="60" Background="#1565C0" Foreground="White" FontWeight="Bold" FontSize="16" Cursor="Hand">
                <Button.Resources><Style TargetType="Border"><Setter Property="CornerRadius" Value="12"/></Style></Button.Resources>
            </Button>

            <TextBlock Name="TxtLog" Text="Hệ thống sẵn sàng." FontSize="12" Foreground="#666" Margin="0,15,0,0" HorizontalAlignment="Center" TextWrapping="Wrap" TextAlignment="Center" FontWeight="SemiBold"/>
            <ProgressBar Name="ProgBar" Height="10" Margin="0,10,0,0" IsIndeterminate="True" Visibility="Collapsed"/>
        </StackPanel>
    </Grid>
</Window>
"@

    # Tải giao diện
    $window = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create([System.IO.StringReader]$MaGiaoDien))
    $cb = $window.FindName("CbEditions")
    $btn = $window.FindName("BtnStart")
    $log = $window.FindName("TxtLog")
    $txtCurrent = $window.FindName("TxtCurrentVer")
    $pb = $window.FindName("ProgBar")

    # 4. NHẬN DẠNG WINDOWS HIỆN TẠI
    $currentEdition = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").EditionID
    $txtCurrent.Text = $currentEdition

    # 5. TẢI VÀ LỌC DANH MỤC TỪ GITHUB (Bản nâng cấp có Phân Cấp Rank)
    try {
        $log.Text = "⏳ Đang đồng bộ danh mục từ Cloud..."
        $wc = New-Object System.Net.WebClient
        $wc.Encoding = [System.Text.Encoding]::UTF8
        $csvText = $wc.DownloadString($UrlCSV)
        $data = $csvText | ConvertFrom-Csv
        
        # --- HỆ THỐNG PHÂN CẤP BẢN WIN (RANKING) ---
        # Bậc càng cao thì càng xịn. Thêm các bản khác vào đây nếu Tuấn có.
        $WinRank = @{
            "Core" = 1               # Home
            "CoreSingleLanguage" = 1 # Home SL
            "Professional" = 2       # Pro
            "Education" = 3          # Edu
            "Enterprise" = 4         # Enterprise
            "ServerRdsh" = 5         # Enterprise Multi-Session (nếu có)
        }

        # Tìm bậc (Rank) của máy hiện tại. Nếu không có trong danh sách thì mặc định là bậc 0
        $currentRank = 0
        if ($WinRank.ContainsKey($currentEdition)) {
            $currentRank = $WinRank[$currentEdition]
        }
        
        $cb.Items.Clear()
        foreach ($item in $data) {
            # Suy đoán bậc của bản Win trong file CSV dựa vào Tên File Zip
            $itemRank = 0
            if ($item.FileName -match "Core|Home") { $itemRank = 1 }
            elseif ($item.FileName -match "Pro") { $itemRank = 2 }
            elseif ($item.FileName -match "Edu") { $itemRank = 3 }
            elseif ($item.FileName -match "Enterprise") { $itemRank = 4 }
            else { $itemRank = 99 } # Nếu file lạ không phân loại được thì cứ cho hiện ra

            # LOGIC QUAN TRỌNG: Chỉ thêm vào danh sách nếu bậc của nó CAO HƠN bản hiện tại
            if ($itemRank -gt $currentRank) {
                [void]$cb.Items.Add($item)
            }
        }
        
        $cb.DisplayMemberPath = "Name"
        if ($cb.Items.Count -gt 0) {
            $cb.SelectedIndex = 0
            $log.Text = "✅ Đã tải danh sách. Chỉ hiển thị các bản cao hơn $currentEdition."
        } else {
            $log.Text = "ℹ️ Bạn đang ở phiên bản cao nhất, không thể nâng cấp thêm."
            $btn.IsEnabled = $false
        }
    } catch {
        $log.Text = "❌ Lỗi: Không thể kết nối Cloud để lấy danh sách SKU!"
    }

    # 6. XỬ LÝ NÂNG CẤP KHI BẤM NÚT (Fix lỗi Null-Valued Expression)
    $btn.Add_Click({
        $selected = $cb.SelectedItem
        if (-not $selected) { return }

        $msg = [System.Windows.MessageBox]::Show("Hệ thống sẽ tải SKU và nâng cấp lên $($selected.Name). Bạn có chắc chắn không?", "Xác nhận nâng cấp", "YesNo", "Information")
        if ($msg -ne "Yes") { return }

        $btn.IsEnabled = $false
        $pb.Visibility = "Visible"
        $log.Text = "⏳ Đang khởi tạo quá trình tải dữ liệu..."

        # ScriptBlock chạy ngầm
        $JobCode = {
            param($url, $key, $name)
            try {
                $tempZip = "$env:TEMP\upgrade_sku.zip"
                $tempDir = "$env:TEMP\SKU_Extract"
                
                $web = New-Object System.Net.WebClient
                $web.DownloadFile($url, $tempZip)
                
                if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
                Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force
                
                $files = Get-ChildItem -Path $tempDir -Filter "*.xrm-ms" -Recurse
                foreach ($f in $files) {
                    $null = cscript //nologo C:\Windows\System32\slmgr.vbs /ilc "$($f.FullName)"
                }
                
                Start-Process "changepk.exe" -ArgumentList "/ProductKey $key" -Wait
                return "✅ THÀNH CÔNG: Đã gửi lệnh nâng cấp lên $name!"
            } catch {
                return "❌ LỖI: $($_.Exception.Message)"
            }
        }

        # Khởi chạy Job
        $DownloadUrl = $BaseZipUrl + $selected.FileName
        $script:currentJob = Start-Job -ScriptBlock $JobCode -ArgumentList $DownloadUrl, $selected.GenericKey, $selected.Name
        
        $log.Text = "🚀 Đang tải và nạp cấu hình... Vui lòng không tắt Tool!"

        # Bộ đếm thời gian (Đã bọc bảo hiểm an toàn tuyệt đối)
        $timer = New-Object System.Windows.Threading.DispatcherTimer
        $timer.Interval = [TimeSpan]::FromSeconds(2)
        $timer.Add_Tick({
            param($sender, $e) # <- CHÌA KHÓA GIẢI QUYẾT LỖI NẰM Ở ĐÂY

            # Nếu Job bị mất, dừng đồng hồ ngay
            if (-not $script:currentJob) {
                $sender.Stop()
                return
            }

            # Lấy trạng thái Job (nuốt lỗi đỏ nếu có)
            $jobStatus = Get-Job -Id $script:currentJob.Id -ErrorAction SilentlyContinue
            
            # Nếu Job đã xong (Completed/Failed)
            if ($jobStatus -and $jobStatus.State -ne "Running") {
                $sender.Stop() # Dừng đồng hồ bằng chính object của nó
                
                $result = Receive-Job -Job $jobStatus -ErrorAction SilentlyContinue
                if ($result) { $log.Text = $result } else { $log.Text = "✅ Đã xử lý xong tác vụ!" }
                
                $pb.Visibility = "Collapsed"
                $btn.IsEnabled = $true
                
                # Dọn rác
                Remove-Job -Id $script:currentJob.Id -Force -ErrorAction SilentlyContinue
                $script:currentJob = $null
                
                if ($result -match "THÀNH CÔNG") {
                    [System.Windows.MessageBox]::Show("Quá trình cài đặt SKU đã hoàn tất! Hệ thống đang tiến hành chuyển bản Windows, bạn có thể kiểm tra trong Settings.", "Thành Công", "OK", "Information")
                }
            }
        })
        $timer.Start()
    })

    $window.ShowDialog() | Out-Null
}

&$LogicVietToolboxClientV67