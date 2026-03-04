Add-Type -AssemblyName PresentationFramework
$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Title="Upgrade Windows" Height="300" Width="450" Background="#1E1E1E" WindowStartupLocation="CenterScreen">
    <StackPanel Margin="20">
        <TextBlock Text="CHỌN PHIÊN BẢN NÂNG CẤP" Foreground="#007ACC" FontSize="18" FontWeight="Bold" Margin="0,0,0,20" HorizontalAlignment="Center"/>
        <ComboBox Name="ComboUp" Height="35" FontSize="14" Margin="0,0,0,20"/>
        <Button Name="BtnUp" Content="BẮT ĐẦU NÂNG CẤP" Height="40" Background="#007ACC" Foreground="White" FontWeight="Bold"/>
    </StackPanel>
</Window>
"@
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)
$combo = $window.FindName("ComboUp")
$list = @{"Pro"="VK7JG-NPHTM-C97JM-9MPGT-3V66T"; "Enterprise"="NPPR9-FWDCX-D2C8J-H872K-2YT43"; "Education"="NW6C2-QMPVW-D7KKK-3GKT6-VCFB2"}
foreach($item in $list.Keys){ [void]$combo.Items.Add($item) }
$combo.SelectedIndex = 0
$window.FindName("BtnUp").Add_Click({
    $key = $list[$combo.SelectedItem]
    Start-Process "changepk.exe" -ArgumentList "/ProductKey $key"
    $window.Close()
})
$window.ShowDialog() | Out-Null