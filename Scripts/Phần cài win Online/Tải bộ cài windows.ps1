# ==============================================================================
# VIETTOOLBOX ISO CLIENT V157 - ABSOLUTE RESET (ANTI-MAIN-ERROR)
# Đặc tính: Reset toàn bộ danh sách khi Hủy, Khắc phục triệt để lỗi ShowDialog Null
# ==============================================================================

# 1. KIỂM TRA QUYỀN ADMIN & STA
try {
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -ErrorAction Stop; exit
    }
} catch { exit }

if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne 'STA') {
    Start-Process powershell.exe -ArgumentList "-NoProfile -ApartmentState STA -File `"$PSCommandPath`"" ; exit
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# --- 2. ĐỘNG CƠ TẢI C# V7 (RESET ENGINE) ---
$CSharpSource = @"
using System;
using System.Net.Http;
using System.IO;
using System.Threading.Tasks;

public class SharpIsoEngineV7 {
    public static int Progress = 0;
    public static string Speed = "0 MB/s";
    public static string Info = "0/0 MB";
    public static bool IsCancel = false;

    public static void GlobalReset() {
        Progress = 0; Speed = "0 MB/s"; Info = "0/0 MB"; IsCancel = false;
    }

    public static async Task<int> DownloadFile(string url, string path) {
        IsCancel = false; Progress = 0;
        try {
            using (HttpClient client = new HttpClient()) {
                client.Timeout = TimeSpan.FromHours(5);
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

if (-not ("SharpIsoEngineV7" -as [type])) {
    Add-Type -TypeDefinition $CSharpSource -ReferencedAssemblies "System.Net.Http", "System.Runtime" -ErrorAction SilentlyContinue
}

# --- 3. BIẾN ĐỒNG BỘ ---
$Global:Sync = [hashtable]::Synchronized(@{ Stt = "Sẵn sàng"; Log = ""; Path = ""; Cmd = "WAIT" })
$Global:AppStat = [hashtable]::Synchronized(@{})
$Global:IsoList = New-Object System.Collections.ObjectModel.ObservableCollection[Object]
$Global:B64_Keys = @("QUl6YVN5Q2V0SVlWVzRsQmlULTd3TzdNQUJoWlNVQ0dKR1puQTM0", "QUl6YVN5Q3VKUkJaTDZnUU8tdVZOMWVvdHhmMlppTXNtYy1sandR", "QUl6YVN5QlRhVmRQdmlLaUJyR0JUVk0tUlRiVW51QUdFUzRWck1v", "QUl6YVN5QkI0NENOamtHRkdQSjhBaVZaMURxZFRnc3M5MDc4QThv")

# --- 4. GIAO DIỆN XAML ---
$XAML_Code = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="VIETTOOLBOX ISO V157 - PRO RESET" Width="850" Height="750" WindowStartupLocation="CenterScreen" Background="#F4F7F9">
    <Grid Margin="20">
        <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="120"/><RowDefinition Height="Auto"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
        <StackPanel Grid.Row="0" Margin="0,0,0,10"><TextBlock Text="VIETTOOLBOX ISO CLIENT V157" FontSize="26" FontWeight="Bold" Foreground="#1A237E"/><TextBlock Name="TxtStt" Text="🔄 Đang tải danh sách..." Foreground="#D84315" FontWeight="Bold"/></StackPanel>
        <ListView Name="BangISO" Grid.Row="1" Background="White" BorderBrush="#CCCCCC">
            <ListView.View><GridView>
                <GridViewColumn Width="45"><GridViewColumn.CellTemplate><DataTemplate><CheckBox IsChecked="{Binding Check}"/></DataTemplate></GridViewColumn.CellTemplate></GridViewColumn>
                <GridViewColumn Header="TÊN FILE" DisplayMemberBinding="{Binding Name}" Width="520"/><GridViewColumn Header="TRẠNG THÁI" DisplayMemberBinding="{Binding Status}" Width="180"/>
            </GridView></ListView.View>
        </ListView>
        <GroupBox Grid.Row="2" Header="NHẬT KÝ" Margin="0,10"><TextBox Name="LogBox" IsReadOnly="True" Background="#1E1E1E" Foreground="#00E676" FontFamily="Consolas" VerticalScrollBarVisibility="Auto" FontSize="11" TextWrapping="Wrap"/></GroupBox>
        <Grid Grid.Row="3" Margin="0,5"><Grid.ColumnDefinitions><ColumnDefinition Width="70"/><ColumnDefinition Width="*"/><ColumnDefinition Width="100"/><ColumnDefinition Width="100"/></Grid.ColumnDefinitions>
            <TextBlock Text="LƯU TẠI:" VerticalAlignment="Center" FontWeight="Bold"/><TextBox Name="txtPath" Grid.Column="1" Height="30" IsReadOnly="True" VerticalContentAlignment="Center"/><Button Name="btnBrowse" Grid.Column="2" Content="CHỌN" Margin="5,0"/><Button Name="btnOpen" Grid.Column="3" Content="MỞ" Background="#FFF59D"/></Grid>
        <Grid Grid.Row="4" Margin="0,10"><Grid.ColumnDefinitions><ColumnDefinition Width="*"/><ColumnDefinition Width="150"/><ColumnDefinition Width="100"/><ColumnDefinition Width="180"/></Grid.ColumnDefinitions>
            <StackPanel><Grid><TextBlock Name="TxtStatusSmall" Text="Đang chờ..." FontWeight="Bold"/><TextBlock Name="TxtPerc" Text="0%" HorizontalAlignment="Right" FontWeight="Bold" Foreground="#2E7D32"/></Grid><ProgressBar Name="Pb" Height="20" Margin="0,5" Foreground="#2E7D32"/></StackPanel>
            <StackPanel Grid.Column="1" VerticalAlignment="Center" Margin="10,0"><TextBlock Name="TxtSpd" Text="-- MB/s" FontWeight="Bold" Foreground="#D81B60" HorizontalAlignment="Center"/><TextBlock Name="TxtInfo" Text="0/0 MB" FontSize="10" HorizontalAlignment="Center"/></StackPanel>
            <Button Name="btnCancel" Grid.Column="2" Content="🛑 HỦY" Margin="5,0" IsEnabled="False" Background="#EF9A9A"/><Button Name="btnDownload" Grid.Column="3" Content="🚀 BẮT ĐẦU TẢI" Height="55" Background="#007ACC" Foreground="White" FontWeight="Bold" FontSize="18"/></Grid>
    </Grid>
</Window>
"@

$XmlReader = [System.Xml.XmlReader]::Create((New-Object System.IO.StringReader($XAML_Code)))
$Form = [Windows.Markup.XamlReader]::Load($XmlReader)

$BangISO = $Form.FindName("BangISO"); $LogBox = $Form.FindName("LogBox"); $txtPath = $Form.FindName("txtPath")
$btnBrowse = $Form.FindName("btnBrowse"); $btnOpen = $Form.FindName("btnOpen"); $TxtStt = $Form.FindName("TxtStt")
$TxtPerc = $Form.FindName("TxtPerc"); $Pb = $Form.FindName("Pb"); $TxtSpd = $Form.FindName("TxtSpd")
$TxtInfo = $Form.FindName("TxtInfo"); $btnDownload = $Form.FindName("btnDownload"); $btnCancel = $Form.FindName("btnCancel")
$BangISO.ItemsSource = $Global:IsoList

# --- 5. LUỒNG TẢI ---
$EngineScript = {
    param($S, $AppStat, $List, $Keys, $CSource)
    function Add-Log($m) { $S.Log += "[$((Get-Date).ToString('HH:mm:ss'))] $m`r`n" }
    function Get-Key($p, $i) { return [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($p[$i])) }
    try {
        if (-not ("SharpIsoEngineV7" -as [type])) { Add-Type -TypeDefinition $CSource -ReferencedAssemblies "System.Net.Http", "System.Runtime" }
        $KIdx = 0
        foreach ($item in $List) {
            if ($S.Cmd -eq "STOP") { break }
            $SaveFile = Join-Path $S.SaveDir ($item.Name.Replace(" ", "_"))
            $AppStat[$item.FileID] = "📥 Đang tải..."
            Add-Log "📡 Kết nối: $($item.Name)"
            $Done = $false; $Retries = 0
            while (-not $Done -and $Retries -lt 5) {
                if ($S.Cmd -eq "STOP") { break }
                $Res = [SharpIsoEngineV7]::DownloadFile("https://www.googleapis.com/drive/v3/files/$($item.FileID)?alt=media&key=$(Get-Key $Keys $KIdx)&acknowledgeAbuse=true", $SaveFile).Result
                if ($Res -eq 200) { $Done = $true; Add-Log "✅ Xong: $($item.Name)" }
                elseif ($Res -eq 403) { $KIdx = ($KIdx + 1) % $Keys.Count; Add-Log "⚠️ Đổi API Key..." }
                else { $Retries++; Start-Sleep 3 }
            }
            $AppStat[$item.FileID] = if($Done) {"✅ Xong"} else {"❌ Lỗi"}
        }
    } catch { $S.Log += "❌ LỖI LUỒNG: $($_.Exception.Message)`r`n" }
    $S.Stt = if($S.Cmd -eq "STOP") {"🛑 ĐÃ HỦY"} else {"✅ HOÀN TẤT"}
}

# --- 6. XỬ LÝ SỰ KIỆN ---
$Global:UITimer = New-Object System.Windows.Threading.DispatcherTimer
$Global:UITimer.Interval = [TimeSpan]::FromMilliseconds(300)
$Global:UITimer.Add_Tick({
    if ($null -ne $Form -and $Form.IsVisible) {
        $Pb.Value = [SharpIsoEngineV7]::Progress; $TxtPerc.Text = "$([SharpIsoEngineV7]::Progress)%"
        $TxtSpd.Text = [SharpIsoEngineV7]::Speed; $TxtInfo.Text = [SharpIsoEngineV7]::Info; $TxtStt.Text = $Global:Sync.Stt
        if ($LogBox.Text -ne $Global:Sync.Log) { $LogBox.Text = $Global:Sync.Log; $LogBox.ScrollToEnd() }
        foreach ($i in $Global:IsoList) { if ($Global:AppStat.ContainsKey($i.FileID)) { $i.Status = $Global:AppStat[$i.FileID] } }
        $BangISO.Items.Refresh()
        if ($Global:Sync.Stt -match "✅|🛑") { $btnDownload.IsEnabled = $true; $btnCancel.IsEnabled = $false; $Global:UITimer.Stop() }
    }
})

$btnDownload.Add_Click({
    $Selected = @($Global:IsoList | Where-Object { $_.Check -eq $true })
    if ($Selected.Count -eq 0) { return }
    [SharpIsoEngineV7]::GlobalReset(); $Global:Sync.Cmd = "START"; $Global:Sync.Log = "🚀 Bắt đầu...`r`n"
    $btnDownload.IsEnabled = $false; $btnCancel.IsEnabled = $true; $Global:Sync.SaveDir = $txtPath.Text
    $TempList = @(); foreach ($i in $Selected) { $TempList += @{ FileID = $i.FileID; Name = $i.Name }; $Global:AppStat[$i.FileID] = "⏳ Chờ..." }
    
    $RS = [runspacefactory]::CreateRunspace(); $RS.ApartmentState = "STA"; $RS.Open()
    $PS = [powershell]::Create().AddScript($EngineScript).AddArgument($Global:Sync).AddArgument($Global:AppStat).AddArgument($TempList).AddArgument($Global:B64_Keys).AddArgument($CSharpSource)
    $PS.Runspace = $RS; $PS.BeginInvoke()
    $Global:UITimer.Start()
})

$btnCancel.Add_Click({ 
    [SharpIsoEngineV7]::IsCancel = $true
    $Global:Sync.Cmd = "STOP"
    $Global:Sync.Stt = "🛑 ĐÃ HỦY"
    # RESET TRẠNG THÁI TỪNG DÒNG TRONG BẢNG
    foreach ($i in $Global:IsoList) { $Global:AppStat[$i.FileID] = "Sẵn sàng" }
    # RESET UI CON SỐ
    if ($null -ne $Pb) { $Pb.Value = 0 }
    if ($null -ne $TxtPerc) { $TxtPerc.Text = "0%" }
    if ($null -ne $TxtSpd) { $TxtSpd.Text = "0 MB/s" }
    if ($null -ne $TxtInfo) { $TxtInfo.Text = "0/0 MB" }
    $Global:Sync.Log += "[$((Get-Date).ToString('HH:mm:ss'))] 🛑 Reset hệ thống thành công.`r`n"
    $BangISO.Items.Refresh()
})

$btnOpen.Add_Click({ if(Test-Path $txtPath.Text) { Start-Process explorer.exe $txtPath.Text } })
$btnBrowse.Add_Click({ $f = New-Object System.Windows.Forms.FolderBrowserDialog; if ($f.ShowDialog() -eq "OK") { $txtPath.Text = $f.SelectedPath } })

function Load-ISO {
    try {
        $CsvUrl = "https://raw.githubusercontent.com/tuantran19912512/Windows-tool-box/refs/heads/main/iso_list.csv?t=$(Get-Date).Ticks"
        $Csv = (Invoke-WebRequest $CsvUrl -UseBasicParsing).Content | ConvertFrom-Csv
        $Global:IsoList.Clear()
        foreach ($r in $Csv) { $Global:IsoList.Add([PSCustomObject]@{ Check=$false; Name=$r.Name; FileID=$r.FileID; Status="Sẵn sàng" }) }
        $TxtStt.Text = "✅ Đã nạp $($Global:IsoList.Count) file."; $BangISO.Items.Refresh()
    } catch { $TxtStt.Text = "❌ Lỗi GitHub!" }
}

$Form.Add_Loaded({ $txtPath.Text = Join-Path ([Environment]::GetFolderPath("Desktop")) "VietToolbox_ISO"; Load-ISO })

# CHỐNG LỖI MAIN PANEL: CHỈ CHẠY SHOWDIALOG KHI FORM OK
if ($null -ne $Form) {
    try {
        $Form.ShowDialog() | Out-Null
    } finally {
        $Global:UITimer.Stop()
        $Global:Sync.Stt = "STOPPED"
    }
}