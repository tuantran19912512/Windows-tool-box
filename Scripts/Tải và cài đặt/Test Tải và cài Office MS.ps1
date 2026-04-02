# ==============================================================================
# VIETTOOLBOX - OFFICE V183 (RUNSPACE ENGINE - CHỐNG TREO TUYỆT ĐỐI)
# Đặc tính: Đa luồng (Background Worker), Xoay Key API, Tự nối lại khi rớt mạng
# ==============================================================================

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit
}

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. BIẾN ĐỒNG BỘ GIỮA CÁC LUỒNG (SYNCHRONIZED HASHTABLE) ---
$Global:Sync = [hashtable]::Synchronized(@{
    TrangThai = "Sẵn sàng..."; TienDo = 0; TocDo = "-- MB/s"; Log = "";
    LenhHienTai = "WAIT"; DuongDanLuu = ""; Path7z = ""; KeyIdx = 0
})
$Global:AppStatus = [hashtable]::Synchronized(@{}) # Lưu trạng thái riêng từng dòng Office
$Global:KeysB64 = @(
    "QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0",
    "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR",
    "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v",
    "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFJnc3M5MDc4QThv"
)

# --- 2. GIAO DIỆN XAML (GIỮ NGUYÊN BẢN CỦA SẾP TUẤN) ---
$XamlCode = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VIETTOOLBOX - OFFICE V183 (MULTI-THREAD)" Width="850" Height="650" 
        WindowStartupLocation="CenterScreen" Background="#F4F7F9" FontFamily="Segoe UI">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/><RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0 autor,15">
            <TextBlock Text="TRUNG TÂM TRIỂN KHAI MICROSOFT OFFICE" FontSize="24" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Text="Cơ chế: Chạy đa luồng Runspace - Chống treo giao diện khi tải file" Foreground="#666666"/>
        </StackPanel>
        <ListView Name="BangOffice" Grid.Row="1" Background="White" BorderBrush="#CCCCCC" SelectionMode="None">
            <ListView.View>
                <GridView>
                    <GridViewColumn Width="45">
                        <GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Check}"/></DataTemplate></GridViewColumn.CellTemplate>
                    </GridViewColumn>
                    <GridViewColumn Header="PHIÊN BẢN OFFICE" DisplayMemberBinding="{Binding Name}" Width="450"/>
                    <GridViewColumn Header="TRẠNG THÁI" Width="250">
                        <GridViewColumn.CellTemplate>
                            <DataTemplate><TextBlock Text="{Binding Status}" Foreground="{Binding StatusColor}" FontWeight="Bold"/></DataTemplate>
                        </GridViewColumn.CellTemplate>
                    </GridViewColumn>
                </GridView>
            </ListView.View>
        </ListView>
        <TextBlock Name="Nhan7Zip" Grid.Row="2" Text="🔍 Đang kiểm tra hệ thống..." FontWeight="SemiBold" Foreground="#FF9800" Margin="0,10,0,10"/>
        <Border Grid.Row="3" Background="White" CornerRadius="8" Padding="15" Margin="0,0,0,15" BorderBrush="#DDDDDD" BorderThickness="1">
            <Grid><Grid.ColumnDefinitions><ColumnDefinition Width="80"/><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/></Grid.ColumnDefinitions>
                <TextBlock Text="LƯU TẠI:" FontWeight="Bold" VerticalAlignment="Center"/><TextBox Name="OTimDuongDan" Grid.Column="1" Height="30" IsReadOnly="True" Margin="0,0,10,0" Background="#F0F0F0"/><Button Name="NutChonThuMuc" Grid.Column="2" Content="CHỌN THƯ MỤC" Height="35" FontWeight="Bold"/></Grid>
        </Border>
        <Border Grid.Row="4" Background="#E3F2FD" CornerRadius="8" Padding="12" Margin="0,0,0,10"><StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
            <TextBlock Text="CẤU HÌNH BẢN QUYỀN:" FontWeight="Bold" Margin="0,0,20,0"/><RadioButton Name="RadNoAct" Content="Không kích hoạt" IsChecked="True" Margin="0,0,30,0"/><RadioButton Name="RadAct" Content="Kích hoạt (Ohook)" FontWeight="Bold" Foreground="#D32F2F"/></StackPanel>
        </Border>
        <Border Grid.Row="5" Background="#FFF3E0" CornerRadius="8" Padding="12" Margin="0,0,0,15"><StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
            <TextBlock Text="CẤU HÌNH FILE:" FontWeight="Bold" Margin="0,0,20,0"/><RadioButton Name="RadDel" Content="Xóa Source ZIP" IsChecked="True" Margin="0,0,30,0"/><RadioButton Name="RadKeep" Content="Giữ lại ZIP" FontWeight="Bold"/></StackPanel>
        </Border>
        <Grid Grid.Row="6"><Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <TextBlock Name="NhanTrangThai" Text="Sẵn sàng..." FontWeight="SemiBold" Foreground="#1565C0"/><TextBlock Name="NhanTocDo" Grid.Column="1" Text="-- MB/s" FontWeight="Bold" Foreground="#D84315" TextAlignment="Right"/></Grid>
        <ProgressBar Name="ThanhChay" Grid.Row="7" Height="25" Margin="0,5,0,20" Foreground="#2E7D32"/>
        <Grid Grid.Row="8" Margin="0,0,0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Button Name="NutTamDung" Content="TẠM DỪNG" Height="45" Background="#FFF59D" IsEnabled="False"/><Button Name="NutHuy" Grid.Column="2" Content="HỦY LỆNH" Height="45" Background="#EF9A9A" IsEnabled="False"/></Grid>
        <Grid Grid.Row="9"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/><ColumnDefinition Width="10"/><ColumnDefinition Width="*"/></Grid.ColumnDefinitions>
            <Button Name="NutNhatKy" Content="NHẬT KÝ" Height="55" Background="#607D8B" Foreground="White"/><Button Name="NutLamMoi" Grid.Column="2" Content="LÀM MỚI" Height="55" Background="#455A64" Foreground="White"/><Button Name="NutCaiDat" Grid.Column="4" Content="🚀 CÀI ĐẶT NGAY" Height="55" Background="#D32F2F" Foreground="White" FontWeight="Bold"/></Grid>
    </Grid>
</Window>
"@

$DocXml = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($XamlCode)))
$CuaSo = [Windows.Markup.XamlReader]::Load($DocXml)

# Ánh xạ biến UI
$BangOffice = $CuaSo.FindName("BangOffice"); $Nhan7Zip = $CuaSo.FindName("Nhan7Zip")
$OTimDuongDan = $CuaSo.FindName("OTimDuongDan"); $NutChonThuMuc = $CuaSo.FindName("NutChonThuMuc")
$NhanTrangThai = $CuaSo.FindName("NhanTrangThai"); $NhanTocDo = $CuaSo.FindName("NhanTocDo")
$ThanhChay = $CuaSo.FindName("ThanhChay"); $NutTamDung = $CuaSo.FindName("NutTamDung")
$NutHuy = $CuaSo.FindName("NutHuy"); $NutNhatKy = $CuaSo.FindName("NutNhatKy")
$NutLamMoi = $CuaSo.FindName("NutLamMoi"); $NutCaiDat = $CuaSo.FindName("NutCaiDat")
$RadAct = $CuaSo.FindName("RadAct"); $RadKeep = $CuaSo.FindName("RadKeep")

$Global:OfficeData = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$BangOffice.ItemsSource = $Global:OfficeData

# --- 3. LÕI CHẠY NGẦM (BACKGROUND ENGINE) ---
$EngineCode = {
    param($S, $AppStat, $SelectedList, $Keys, $Active, $Keep)
    Add-Type -AssemblyName System.Net.Http
    
    function Log($m) { $S.Log += "[$((Get-Date).ToString('HH:mm:ss'))] $m`r`n" }
    function Get-Key { return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($Keys[$S.KeyIdx])) }

    foreach ($app in $SelectedList) {
        if ($S.LenhHienTai -eq "CANCEL") { break }
        
        $PathZip = Join-Path $S.DuongDanLuu (($app.Name -replace '\s','_') + ".zip")
        $AppStat[$app.ID] = "⬇️ Đang tải..."
        $S.TrangThai = "🚀 Đang xử lý: $($app.Name)"
        
        $Success = $false; $Retries = 0
        while (-not $Success -and $Retries -lt 3) {
            try {
                $Key = Get-Key; $Http = New-Object System.Net.Http.HttpClient
                $Url = "https://www.googleapis.com/drive/v3/files/$($app.ID)?alt=media&key=$Key"
                
                $Response = $Http.GetAsync($Url, [System.Net.Http.HttpCompletionOption]::ResponseHeadersRead).Result
                if ([int]$Response.StatusCode -eq 403) { 
                    $S.KeyIdx = ($S.KeyIdx + 1) % $Keys.Count; Log "⚠️ Đổi Key API..."; throw "403" 
                }

                $Size = $Response.Content.Headers.ContentLength
                $StreamIn = $Response.Content.ReadAsStreamAsync().Result
                $StreamOut = New-Object System.IO.FileStream($PathZip, [System.IO.FileMode]::Create)
                
                $Buf = New-Object byte[] 1MB; $Watch = [System.Diagnostics.Stopwatch]::StartNew(); $Bytes = 0
                while (($Read = $StreamIn.Read($Buf, 0, $Buf.Length)) -gt 0) {
                    if ($S.LenhHienTai -eq "CANCEL") { break }
                    while ($S.LenhHienTai -eq "PAUSE") { Start-Sleep -Milliseconds 500 }
                    
                    $StreamOut.Write($Buf, 0, $Read); $Bytes += $Read
                    if ($Watch.ElapsedMilliseconds -ge 500) {
                        $S.TienDo = if ($Size) { [int](($Bytes/$Size)*100) } else { 0 }
                        $S.TocDo = "$([Math]::Round(($Bytes/$Watch.Elapsed.TotalSeconds)/1MB,2)) MB/s"
                        $Watch.Restart(); $Bytes = 0
                    }
                }
                $StreamOut.Dispose(); $StreamIn.Dispose(); $Http.Dispose(); $Success = $true
            } catch { $Retries++; Start-Sleep 1 }
        }

        if ($Success -and $S.LenhHienTai -ne "CANCEL") {
            $S.TrangThai = "📦 Giải nén: $($app.Name)"
            $AppStat[$app.ID] = "📦 Đang cài..."
            $Dest = $PathZip + "_Ex"
            & $S.Path7z x "`"$PathZip`"" -p"Admin@2512" -o"`"$Dest`"" -y | Out-Null
            
            $Bat = Get-ChildItem $Dest -Filter "*.bat" -Recurse | Select-Object -First 1
            if ($Bat) { Start-Process $Bat.FullName -WorkingDirectory $Bat.DirectoryName -Wait }
            
            if ($Active) {
                try { (New-Object System.Net.WebClient).DownloadFile("https://gist.githubusercontent.com/tuantran19912512/81329d670436ea8492b73bd5889ad444/raw/Ohook.cmd", "$env:TEMP\Act.cmd")
                Start-Process cmd "/c $env:TEMP\Act.cmd /Ohook" -WindowStyle Hidden -Wait } catch {}
            }
            if (-not $Keep) { Remove-Item $PathZip -Force -ErrorAction SilentlyContinue }
            Remove-Item $Dest -Recurse -Force -ErrorAction SilentlyContinue
            $AppStat[$app.ID] = "✅ Hoàn tất"
        }
    }
    $S.TrangThai = "✅ TẤT CẢ ĐÃ XONG!"
}

# --- 4. ĐIỀU KHIỂN GIAO DIỆN ---
function Update-UI {
    $Timer = New-Object System.Windows.Threading.DispatcherTimer
    $Timer.Interval = [TimeSpan]::FromMilliseconds(200)
    $Timer.Add_Tick({
        $ThanhChay.Value = $Global:Sync.TienDo
        $NhanTocDo.Text = $Global:Sync.TocDo
        $NhanTrangThai.Text = $Global:Sync.TrangThai
        foreach ($item in $Global:OfficeData) {
            if ($Global:AppStatus.ContainsKey($item.ID)) { $item.Status = $Global:AppStatus[$item.ID] }
        }
        $BangOffice.Items.Refresh()
        if ($Global:Sync.TrangThai -match "✅|🛑") {
            $NutCaiDat.IsEnabled = $true; $NutHuy.IsEnabled = $false; $NutTamDung.IsEnabled = $false; $Timer.Stop()
        }
    })
    $Timer.Start()
}

$NutCaiDat.Add_Click({
    $Selected = @($Global:OfficeData | Where-Object { $_.Check -eq $true })
    if ($Selected.Count -eq 0) { return }
    
    $Global:Sync.LenhHienTai = "RUN"; $NutCaiDat.IsEnabled = $false; $NutHuy.IsEnabled = $true; $NutTamDung.IsEnabled = $true
    $Global:Sync.DuongDanLuu = $OTimDuongDan.Text
    if (-not (Test-Path $Global:Sync.DuongDanLuu)) { New-Item $Global:Sync.DuongDanLuu -ItemType Directory | Out-Null }

    # KHỞI TẠO LUỒNG NGẦM
    $RS = [runspacefactory]::CreateRunspace(); $RS.ApartmentState = "STA"; $RS.Open()
    $PS = [powershell]::Create().AddScript($EngineCode).AddArgument(@{
        S = $Global:Sync; AppStat = $Global:AppStatus; SelectedList = $Selected;
        Keys = $Global:KeysB64; Active = $RadAct.IsChecked; Keep = $RadKeep.IsChecked
    })
    $PS.Runspace = $RS; $PS.BeginInvoke()
    Update-UI
})

$NutTamDung.Add_Click({ 
    if ($Global:Sync.LenhHienTai -eq "RUN") { $Global:Sync.LenhHienTai = "PAUSE"; $NutTamDung.Content = "TIẾP TỤC" }
    else { $Global:Sync.LenhHienTai = "RUN"; $NutTamDung.Content = "TẠM DỪNG" }
})
$NutHuy.Add_Click({ $Global:Sync.LenhHienTai = "CANCEL"; $Global:Sync.TrangThai = "🛑 Đang dừng..." })
$NutChonThuMuc.Add_Click({ $f = New-Object System.Windows.Forms.FolderBrowserDialog; if ($f.ShowDialog() -eq "OK") { $OTimDuongDan.Text = $f.SelectedPath } })
$NutNhatKy.Add_Click({ if ($Global:Sync.Log) { $Global:Sync.Log | Out-File "$env:TEMP\OfficeLog.txt"; Start-Process notepad "$env:TEMP\OfficeLog.txt" } })

# Nạp danh sách ban đầu
$CuaSo.Add_Loaded({
    $Global:Sync.Path7z = @("${env:ProgramFiles}\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $Global:Sync.Path7z) { $Nhan7Zip.Text = "❌ Cần cài 7-Zip!" } else { $Nhan7Zip.Text = "✅ 7-Zip OK!" }
    
    try {
        $Csv = (Invoke-WebRequest "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv?t=$(Get-Date).Ticks" -UseBasicParsing).Content | ConvertFrom-Csv
        foreach ($r in $Csv) { $Global:OfficeData.Add([PSCustomObject]@{ Check=$false; Name=$r.Name; Status="Sẵn sàng"; ID=$r.ID; StatusColor="Black" }) }
    } catch { $NhanTrangThai.Text = "❌ Lỗi GitHub!" }
})

$CuaSo.ShowDialog() | Out-Null