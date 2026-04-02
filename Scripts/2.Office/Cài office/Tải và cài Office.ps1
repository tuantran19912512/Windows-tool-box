# ==============================================================================
# VIETTOOLBOX OFFICE V245 - BẢN THU GỌN NHẬT KÝ (FIX METHOD NOT FOUND)
# Đặc tính: Thu nhỏ khung Log, Đổi tên Engine tránh trùng lặp, Reset sạch UI
# ==============================================================================

try {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -ErrorAction Stop
        exit
    }
} catch { exit }

if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ApartmentState STA -File `"$PSCommandPath`"" ; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 1. ĐỊNH NGHĨA C# ENGINE V2 (ĐỔI TÊN ĐỂ TRÁNH LỖI SESSION) ---
$CSharpSource = @"
using System;
using System.Net.Http;
using System.IO;
using System.Threading.Tasks;

public class SharpEngineV2 {
    public static int Progress = 0;
    public static string Speed = "0 MB/s";
    public static string Info = "0/0 MB";
    public static bool IsCancel = false;

    public static void Reset() {
        Progress = 0; Speed = "0 MB/s"; Info = "0/0 MB"; IsCancel = false;
    }

    public static async Task<int> DownloadFile(string url, string path) {
        IsCancel = false; Progress = 0;
        try {
            using (HttpClient client = new HttpClient()) {
                client.Timeout = TimeSpan.FromMinutes(30);
                using (var response = await client.GetAsync(url, HttpCompletionOption.ResponseHeadersRead)) {
                    if (!response.IsSuccessStatusCode) return (int)response.StatusCode;
                    var totalSize = response.Content.Headers.ContentLength ?? -1L;
                    using (var stream = await response.Content.ReadAsStreamAsync())
                    using (var fs = new FileStream(path, FileMode.Create, FileAccess.Write, FileShare.None)) {
                        var buffer = new byte[1048576]; 
                        var totalRead = 0L;
                        var startTime = DateTime.Now;
                        int read;
                        while ((read = await stream.ReadAsync(buffer, 0, buffer.Length)) > 0) {
                            if (IsCancel) { fs.Close(); if(File.Exists(path)) File.Delete(path); return -1; }
                            await fs.WriteAsync(buffer, 0, read);
                            totalRead += read;
                            if (totalSize != -1) {
                                Progress = (int)((totalRead * 100) / totalSize);
                                double elapsed = (DateTime.Now - startTime).TotalSeconds;
                                if (elapsed > 0) {
                                    Speed = string.Format("{0:F2} MB/s", (totalRead / 1024.0 / 1024.0) / elapsed);
                                    Info = string.Format("{0:F1} / {1:F1} MB", totalRead / 1024.0 / 1024.0, totalSize / 1024.0 / 1024.0);
                                }
                            }
                        }
                    }
                }
                return 200;
            }
        } catch { return 500; }
    }
}
"@

if (-not ("SharpEngineV2" -as [type])) {
    Add-Type -TypeDefinition $CSharpSource -ReferencedAssemblies "System.Net.Http", "System.Runtime" -ErrorAction SilentlyContinue
}

# --- 2. BIẾN ĐỒNG BỘ ---
$Global:Sync = [hashtable]::Synchronized(@{ Stt = "Sẵn sàng"; Log = ""; Path = ""; Seven = ""; Cmd = "WAIT" })
$Global:AppStat = [hashtable]::Synchronized(@{})
$Global:OfficeData = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$Global:KeysPool = @("AIzaSyCetIYVW4lBiT-7wO7MABhZSUCGJGZnA34", "AIzaSyCuJRBZL6gQO-uVN1eotxf2ZiMsmc-ljwQ", "AIzaSyBTaVdPviKiBrGBTVM-RTbUnuAGES4VrMo", "AIzaSyBB44CNjkGGFPJ8AiVZ1DqdRgss9078A8o")

# --- 3. GIAO DIỆN XAML (THU NHỎ NHẬT KÝ - FIXED HEIGHT 120) ---
$XAML_Code = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="OFFICE DEPLOY V245" Width="820" Height="700" WindowStartupLocation="CenterScreen" Background="#F4F7F9">
    <Grid Margin="15">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>      <RowDefinition Height="*"/>         <RowDefinition Height="120"/>       <RowDefinition Height="Auto"/>      <RowDefinition Height="Auto"/>      <RowDefinition Height="Auto"/>      </Grid.RowDefinitions>
        
        <StackPanel Grid.Row="0" Margin="0,0,0,10">
            <TextBlock Text="OFFICE DEPLOYMENT V245" FontSize="22" FontWeight="Bold" Foreground="#1A237E"/>
            <TextBlock Name="Txt7" Text="🔍 Hệ thống ổn định" Foreground="#E65100"/>
        </StackPanel>

        <ListView Name="Lv" Grid.Row="1" SelectionMode="Extended" Background="White">
            <ListView.View><GridView>
                <GridViewColumn Header="DANH SÁCH OFFICE" DisplayMemberBinding="{Binding Name}" Width="480"/>
                <GridViewColumn Header="TRẠNG THÁI" DisplayMemberBinding="{Binding Status}" Width="180"/>
            </GridView></ListView.View>
        </ListView>

        <GroupBox Grid.Row="2" Header="NHẬT KÝ" Margin="0,5">
            <TextBox Name="LogBox" IsReadOnly="True" Background="#1E1E1E" Foreground="#00E676" FontFamily="Consolas" VerticalScrollBarVisibility="Auto" TextWrapping="Wrap" FontSize="11"/>
        </GroupBox>

        <Grid Grid.Row="3" Margin="0,5">
            <Grid.ColumnDefinitions><ColumnDefinition Width="Auto"/><ColumnDefinition Width="*"/><ColumnDefinition Width="80"/><ColumnDefinition Width="80"/></Grid.ColumnDefinitions>
            <TextBlock Text="LƯU TẠI: " VerticalAlignment="Center" FontWeight="Bold"/><TextBox Name="PathBox" Grid.Column="1" IsReadOnly="True" VerticalContentAlignment="Center"/><Button Name="BtnPath" Grid.Column="2" Content="CHỌN" Margin="5,0"/><Button Name="BtnOpen" Grid.Column="3" Content="MỞ" Background="#FFF59D"/></Grid>

        <UniformGrid Grid.Row="4" Rows="1" Columns="2" Margin="0,5">
            <CheckBox Name="ChkAct" Content="+ Thuốc" IsChecked="True"/><CheckBox Name="ChkKeep" Content="Giữ lại nguồn tải" IsChecked="True"/></UniformGrid>

        <Grid Grid.Row="5" Margin="0,5">
            <Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/><ColumnDefinition Width="100"/><ColumnDefinition Width="180"/></Grid.ColumnDefinitions>
            <StackPanel><Grid><TextBlock Name="TxtStt" Text="Đang chờ..." FontWeight="Bold"/><TextBlock Name="TxtPerc" Text="0%" HorizontalAlignment="Right" FontWeight="Bold" Foreground="#2E7D32"/></Grid><ProgressBar Name="Pb" Height="15" Margin="0,5" Foreground="#2E7D32"/></StackPanel>
            <StackPanel Grid.Column="1" VerticalAlignment="Center"><TextBlock Name="TxtSpd" Text="-- MB/s" HorizontalAlignment="Center" FontWeight="Bold" Foreground="#D84315"/><TextBlock Name="TxtInfo" Text="0/0 MB" HorizontalAlignment="Center" FontSize="10" Foreground="#666666"/></StackPanel>
            <Button Name="BtnStop" Grid.Column="2" Content="🛑 HỦY" Margin="5,0" IsEnabled="False" Background="#EF9A9A"/><Button Name="BtnStart" Grid.Column="3" Content="🚀 CÀI ĐẶT NGAY" Background="#D32F2F" Foreground="White" FontWeight="Bold" FontSize="16"/></Grid>
    </Grid>
</Window>
"@

$Form = [Windows.Markup.XamlReader]::Load([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($XAML_Code))))
$Lv = $Form.FindName("Lv"); $LogBox = $Form.FindName("LogBox"); $PathBox = $Form.FindName("PathBox")
$TxtStt = $Form.FindName("TxtStt"); $Pb = $Form.FindName("Pb"); $TxtSpd = $Form.FindName("TxtSpd")
$TxtPerc = $Form.FindName("TxtPerc"); $TxtInfo = $Form.FindName("TxtInfo"); $BtnStart = $Form.FindName("BtnStart")
$BtnStop = $Form.FindName("BtnStop"); $BtnOpen = $Form.FindName("BtnOpen"); $BtnPath = $Form.FindName("BtnPath")
$ChkAct = $Form.FindName("ChkAct"); $ChkKeep = $Form.FindName("ChkKeep")
$Lv.ItemsSource = $Global:OfficeData

# --- 4. ENGINE ĐIỀU KHIỂN ---
$EngineScript = {
    param($S, $AppStat, $List, $Keys, $IsAct, $IsKeep, $CSource)
    function Add-Log($m) { $S.Log += "[$((Get-Date).ToString('HH:mm:ss'))] $m`r`n" }
    try {
        if (-not ("SharpEngineV2" -as [type])) { Add-Type -TypeDefinition $CSource -ReferencedAssemblies "System.Net.Http", "System.Runtime" }
        $KIdx = 0
        foreach ($item in $List) {
            if ($S.Cmd -eq "STOP") { break }
            $FileZip = Join-Path $S.SaveDir (($item.Name -replace '\W','_') + ".zip")
            $AppStat[$item.ID] = "⬇️ Đang tải..."
            $S.Stt = "🚀 Đang xử lý: $($item.Name)"
            $Done = $false; $Retries = 0
            while (-not $Done -and $Retries -lt 5) {
                if ($S.Cmd -eq "STOP") { break }
                $Res = [SharpEngineV2]::DownloadFile("https://www.googleapis.com/drive/v3/files/$($item.ID)?alt=media&key=$($Keys[$KIdx])", $FileZip).Result
                if ($Res -eq 200) { $Done = $true; Add-Log "✅ Đã tải xong ZIP: $($item.Name)." }
                elseif ($Res -eq -1) { Add-Log "🛑 Đã hủy tiến trình tải."; break }
                elseif ($Res -eq 403) { $KIdx = ($KIdx + 1) % $Keys.Count; Add-Log "⚠️ Đổi Key API..." }
                else { $Retries++; Add-Log "⚠️ Lỗi mạng, thử lại lần $Retries..." ; Start-Sleep 3 }
            }
            if ($Done -and $S.Cmd -ne "STOP") {
                $AppStat[$item.ID] = "📦 Đang cài..."
                $ExPath = $FileZip + "_Ex"
                Start-Process $S.Seven -ArgumentList "x `"$FileZip`" -p`"Admin@2512`" -o`"$ExPath`" -y" -WindowStyle Hidden -Wait
                $Bat = Get-ChildItem $ExPath -Filter "*.bat" -Recurse | Select-Object -First 1
                if ($Bat) { Add-Log "🚀 Thực thi: $($Bat.Name)"; Start-Process $Bat.FullName -WorkingDirectory $Bat.DirectoryName -Wait }
                if ($IsAct) { try { (New-Object System.Net.WebClient).DownloadFile("https://gist.githubusercontent.com/tuantran19912512/81329d670436ea8492b73bd5889ad444/raw/Ohook.cmd", "$env:TEMP\A.cmd")
                              Start-Process cmd "/c $env:TEMP\A.cmd /Ohook" -WindowStyle Hidden -Wait } catch {} }
                if (-not $IsKeep) { Remove-Item $FileZip -Force -ErrorAction SilentlyContinue }
                Remove-Item $ExPath -Recurse -Force -ErrorAction SilentlyContinue
                $AppStat[$item.ID] = "✅ Xong"
            }
        }
    } catch { Add-Log "❌ LỖI LUỒNG: $($_.Exception.Message)" }
    $S.Stt = if($S.Cmd -eq "STOP") {"🛑 ĐÃ HỦY"} else {"✅ HOÀN TẤT"}
}

# --- 5. XỬ LÝ SỰ KIỆN ---
$Global:Timer = New-Object System.Windows.Threading.DispatcherTimer
$Global:Timer.Interval = [TimeSpan]::FromMilliseconds(300)
$Global:Timer.Add_Tick({
    if ($null -ne $Form) {
        $Pb.Value = [SharpEngineV2]::Progress
        $TxtPerc.Text = "$([SharpEngineV2]::Progress)%"
        $TxtSpd.Text = [SharpEngineV2]::Speed
        $TxtInfo.Text = [SharpEngineV2]::Info
        $TxtStt.Text = $Global:Sync.Stt
        if ($LogBox.Text -ne $Global:Sync.Log) { $LogBox.Text = $Global:Sync.Log; $LogBox.ScrollToEnd() }
        foreach ($i in $Global:OfficeData) { if ($Global:AppStat.ContainsKey($i.ID)) { $i.Status = $Global:AppStat[$i.ID] } }
        $Lv.Items.Refresh()
        if ($Global:Sync.Stt -match "✅|🛑") {
            $BtnStart.IsEnabled = $true; $BtnStop.IsEnabled = $false; $Global:Timer.Stop()
        }
    }
})

$BtnStart.Add_Click({
    $Selected = @($Lv.SelectedItems)
    if ($Selected.Count -eq 0) { [System.Windows.MessageBox]::Show("Bôi xanh bản cần cài sếp ơi!"); return }
    [SharpEngineV2]::Reset()
    $Global:Sync.Cmd = "START"; $Global:Sync.Log = "🚀 Khởi động...`r`n"; 
    $BtnStart.IsEnabled = $false; $BtnStop.IsEnabled = $true
    $Global:Sync.SaveDir = $PathBox.Text
    $TempList = @(); foreach ($i in $Selected) { $TempList += @{ ID = $i.ID; Name = $i.Name }; $Global:AppStat[$i.ID] = "⏳ Chờ..." }
    
    $Global:RS = [runspacefactory]::CreateRunspace(); $Global:RS.ApartmentState = "STA"; $Global:RS.Open()
    $Global:PS = [powershell]::Create().AddScript($EngineScript).AddArgument($Global:Sync).AddArgument($Global:AppStat).AddArgument($TempList).AddArgument($Global:KeysPool).AddArgument($ChkAct.IsChecked).AddArgument($ChkKeep.IsChecked).AddArgument($CSharpSource)
    $Global:PS.Runspace = $Global:RS; $Global:PS.BeginInvoke()
    $Global:Timer.Start()
})

$BtnStop.Add_Click({
    [SharpEngineV2]::IsCancel = $true
    $Global:Sync.Cmd = "STOP"
    $Global:Sync.Stt = "🛑 ĐÃ HỦY"
    $Pb.Value = 0; $TxtPerc.Text = "0%"; $TxtSpd.Text = "0 MB/s"; $TxtInfo.Text = "0/0 MB"
    $Global:Sync.Log += "[$((Get-Date).ToString('HH:mm:ss'))] 🛑 Reset hệ thống...`r`n"
})

$BtnOpen.Add_Click({ if(Test-Path $PathBox.Text) { Start-Process explorer.exe $PathBox.Text } })
$BtnPath.Add_Click({ $f = New-Object System.Windows.Forms.FolderBrowserDialog; if ($f.ShowDialog() -eq "OK") { $PathBox.Text = $f.SelectedPath } })

$Form.Add_Loaded({
    $Global:Sync.Seven = @("${env:ProgramFiles}\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
    $PathBox.Text = if(Test-Path "D:\") {"D:\BoCaiOffice"} else {"C:\BoCaiOffice"}
    try {
        $Csv = (Invoke-WebRequest "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/DanhSachOffice.csv?t=$(Get-Date).Ticks" -UseBasicParsing).Content | ConvertFrom-Csv
        foreach ($r in $Csv) { $Global:OfficeData.Add([PSCustomObject]@{ Name=$r.Name; Status="Sẵn sàng"; ID=$r.ID }) }
    } catch {}
})

if ($null -ne $Form) { $Form.ShowDialog() | Out-Null }