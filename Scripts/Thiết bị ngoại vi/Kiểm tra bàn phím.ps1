# ==========================================================
# VIETTOOLBOX - KEYBOARD TEST FULL 104 (PURE WPF EDITION - FIX MÃ PHÍM)
# Tác giả: Tuấn Kỹ Thuật Máy Tính
# ==========================================================

# ÉP POWERSHELL HIỂU TIẾNG VIỆT 100%
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# --- GỌI WIN32 API ĐỂ QUÉT CHÍNH XÁC PHẦN CỨNG PHÍM TRÁI/PHẢI ---
if (-not ([Ref].Assembly.GetType("VietToolbox.KeyHook"))) {
    $Source = @"
    using System;
    using System.Runtime.InteropServices;
    namespace VietToolbox {
        public class KeyHook {
            [DllImport("user32.dll")]
            public static extern short GetAsyncKeyState(int vKey);
        }
    }
"@
    try { Add-Type -TypeDefinition $Source -ErrorAction SilentlyContinue } catch { }
}

$LogicBanPhimFull = {
    # 1. GIAO DIỆN XAML
    $MaGiaoDien = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="VietToolbox - Keyboard Test Full 104 (Pure WPF)" Width="1120" Height="450"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize" Background="#FFFFFF" FontFamily="Segoe UI">
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        
        <TextBlock Text="KIỂM TRA BÀN PHÍM TOÀN DIỆN (HARDWARE SCAN)" FontSize="20" FontWeight="Bold" Foreground="#394E60" Margin="0,0,0,15" HorizontalAlignment="Center"/>
        
        <Border Grid.Row="1" Background="#F4F5F7" CornerRadius="8" Padding="15">
            <Canvas Name="KeyCanvas" Width="1060" Height="280" HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Border>
    </Grid>
</Window>
"@

    $DocChuoi = New-Object System.IO.StringReader($MaGiaoDien)
    $DocXml = [System.Xml.XmlReader]::Create($DocChuoi)
    $window = [Windows.Markup.XamlReader]::Load($DocXml)
    $canvas = $window.FindName("KeyCanvas")

    $btns = @{}
    
    # 2. CẤU TRÚC LAYOUT 104 PHÍM
    $layout = @(
        @("Escape",5,5,40,"Esc"), @("F1",65,5,40,"F1"), @("F2",110,5,40,"F2"), @("F3",155,5,40,"F3"), @("F4",200,5,40,"F4"), @("F5",260,5,40,"F5"), @("F6",305,5,40,"F6"), @("F7",350,5,40,"F7"), @("F8",395,5,40,"F8"), @("F9",455,5,40,"F9"), @("F10",500,5,40,"F10"), @("F11",545,5,40,"F11"), @("F12",590,5,40,"F12"), @("PrintScreen",650,5,40,"Prt"), @("Scroll",695,5,40,"Scr"), @("Pause",740,5,40,"Pau"),
        @("OemTilde",5,50,40,"~"), @("D1",50,50,40,"1"), @("D2",95,50,40,"2"), @("D3",140,50,40,"3"), @("D4",185,50,40,"4"), @("D5",230,50,40,"5"), @("D6",275,50,40,"6"), @("D7",320,50,40,"7"), @("D8",365,50,40,"8"), @("D9",410,50,40,"9"), @("D0",455,50,40,"0"), @("OemMinus",500,50,40,"-"), @("OemPlus",545,50,40,"="), @("Back",590,50,85,"Back"),
        @("Tab",5,95,60,"Tab"), @("Q",70,95,40,"Q"), @("W",115,95,40,"W"), @("E",160,95,40,"E"), @("R",205,95,40,"R"), @("T",250,95,40,"T"), @("Y",295,95,40,"Y"), @("U",340,95,40,"U"), @("I",385,95,40,"I"), @("O",430,95,40,"O"), @("P",475,95,40,"P"), @("OemOpenBrackets",520,95,40,"["), @("OemCloseBrackets",565,95,40,"]"), @("Oem5",610,95,65,"\"),
        @("CapsLock",5,140,75,"Caps"), @("A",85,140,40,"A"), @("S",130,140,40,"S"), @("D",175,140,40,"D"), @("F",220,140,40,"F"), @("G",265,140,40,"G"), @("H",310,140,40,"H"), @("J",355,140,40,"J"), @("K",400,140,40,"K"), @("L",445,140,40,"L"), @("OemSemicolon",490,140,40,";"), @("OemQuotes",535,140,40,"'"), @("Return",580,140,95,"Enter"),
        @("LeftShift",5,185,100,"Shift"), @("Z",110,185,40,"Z"), @("X",155,185,40,"X"), @("C",200,185,40,"C"), @("V",245,185,40,"V"), @("B",290,185,40,"B"), @("N",335,185,40,"N"), @("M",380,185,40,"M"), @("OemComma",425,185,40,","), @("OemPeriod",470,185,40,"."), @("OemQuestion",515,185,40,"/"), @("RightShift",560,185,115,"Shift"),
        @("LeftCtrl",5,230,55,"Ctrl"), @("LWin",65,230,50,"Win"), @("LeftAlt",120,230,50,"Alt"), @("Space",175,230,280,"Space"), @("RightAlt",460,230,50,"Alt"), @("RWin",515,230,50,"Win"), @("Apps",570,230,50,"App"), @("RightCtrl",625,230,50,"Ctrl"),
        
        @("Insert",690,50,45,"Ins"), @("Home",740,50,45,"Hom"), @("PageUp",790,50,45,"PgU"),
        @("Delete",690,95,45,"Del"), @("End",740,95,45,"End"), @("PageDown",790,95,45,"PgD"),
        @("Up",740,185,45,"▲"), @("Left",690,230,45,"◄"), @("Down",740,230,45,"▼"), @("Right",790,230,45,"►"),
        @("NumLock",855,50,45,"Num"), @("Divide",905,50,45,"/"), @("Multiply",955,50,45,"*"), @("Subtract",1005,50,45,"-"),
        @("NumPad7",855,95,45,"7"), @("NumPad8",905,95,45,"8"), @("NumPad9",955,95,45,"9"), @("Add",1005,95,45,85,"+"),
        @("NumPad4",855,140,45,"4"), @("NumPad5",905,140,45,"5"), @("NumPad6",955,140,45,"6"),
        @("NumPad1",855,185,45,"1"), @("NumPad2",905,185,45,"2"), @("NumPad3",955,185,45,"3"), @("NumEnter",1005,185,45,85,"Ent"),
        @("NumPad0",855,230,95,"0"), @("Decimal",955,230,45,".")
    )

    # 3. TẠO GIAO DIỆN PHÍM BẰNG CODE
    $brushDefault = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#E1E4E8")
    $textDefault = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#394E60")
    $brushPressed = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#00FF00")
    $textPressed = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#000000")
    $brushTested = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#0068FF")
    $textTested = (New-Object System.Windows.Media.BrushConverter).ConvertFromString("#FFFFFF")

    foreach($k in $layout) {
        $h = if ($k.Count -eq 6) { $k[4] } else { 40 }
        $txt = if ($k.Count -eq 6) { $k[5] } else { $k[4] }
        
        $border = New-Object System.Windows.Controls.Border
        $border.Width = $k[3]; $border.Height = $h
        $border.Background = $brushDefault
        $border.CornerRadius = New-Object System.Windows.CornerRadius(4)
        [System.Windows.Controls.Canvas]::SetLeft($border, $k[1])
        [System.Windows.Controls.Canvas]::SetTop($border, $k[2])

        $textBlock = New-Object System.Windows.Controls.TextBlock
        $textBlock.Text = $txt
        $textBlock.Foreground = $textDefault
        $textBlock.HorizontalAlignment = "Center"
        $textBlock.VerticalAlignment = "Center"
        $textBlock.FontWeight = "SemiBold"

        $border.Child = $textBlock
        $canvas.Children.Add($border) | Out-Null
        $btns[$k[0]] = $border
    }

    function Set-KeyColor($keyName, $state) {
        if ($btns.ContainsKey($keyName)) {
            $b = $btns[$keyName]
            if ($state -eq "Pressed") {
                $b.Background = $brushPressed
                $b.Child.Foreground = $textPressed
            } elseif ($state -eq "Tested") {
                $b.Background = $brushTested
                $b.Child.Foreground = $textTested
            }
        }
    }

    # HÀM PHIÊN DỊCH MÃ PHÍM WPF -> TÊN LAYOUT
    function Translate-WPFKey($k) {
        switch ($k) {
            "Oem3" { return "OemTilde" }
            "Capital" { return "CapsLock" }
            "Oem1" { return "OemSemicolon" }
            "Oem7" { return "OemQuotes" }
            "Oem6" { return "OemCloseBrackets" }
            "OemBackslash" { return "Oem5" }
            "Snapshot" { return "PrintScreen" }
            "Prior" { return "PageUp" }
            "Next" { return "PageDown" }
            default { return $k }
        }
    }

    # 4. SỰ KIỆN NHẤN PHÍM (PREVIEW KEY DOWN)
    $window.Add_PreviewKeyDown({ 
        param($s, $e) 
        $rawKey = if ($e.Key -eq 'System') { $e.SystemKey.ToString() } else { $e.Key.ToString() }
        
        # Phiên dịch phím dị của WPF
        $k = Translate-WPFKey $rawKey

        # Quét phần cứng Win32 API
        if ($k -match "Shift") {
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(160) -lt 0) { Set-KeyColor "LeftShift" "Pressed" }
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(161) -lt 0) { Set-KeyColor "RightShift" "Pressed" }
            $e.Handled = $true; return
        }
        if ($k -match "Ctrl" -or $k -match "Control") {
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(162) -lt 0) { Set-KeyColor "LeftCtrl" "Pressed" }
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(163) -lt 0) { Set-KeyColor "RightCtrl" "Pressed" }
            $e.Handled = $true; return
        }
        if ($k -match "Alt") {
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(164) -lt 0) { Set-KeyColor "LeftAlt" "Pressed" }
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(165) -lt 0) { Set-KeyColor "RightAlt" "Pressed" }
            $e.Handled = $true; return
        }

        # Sáng cả 2 Enter
        if ($k -eq "Return") {
            Set-KeyColor "Return" "Pressed"; Set-KeyColor "NumEnter" "Pressed"
            $e.Handled = $true; return
        }

        Set-KeyColor $k "Pressed"
        $e.Handled = $true 
    })

    # 5. SỰ KIỆN THẢ PHÍM (PREVIEW KEY UP)
    $window.Add_PreviewKeyUp({ 
        param($s, $e) 
        $rawKey = if ($e.Key -eq 'System') { $e.SystemKey.ToString() } else { $e.Key.ToString() }
        
        # Phiên dịch phím dị của WPF
        $k = Translate-WPFKey $rawKey

        if ($k -match "Shift") {
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(160) -ge 0) { Set-KeyColor "LeftShift" "Tested" }
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(161) -ge 0) { Set-KeyColor "RightShift" "Tested" }
            $e.Handled = $true; return
        }
        if ($k -match "Ctrl" -or $k -match "Control") {
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(162) -ge 0) { Set-KeyColor "LeftCtrl" "Tested" }
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(163) -ge 0) { Set-KeyColor "RightCtrl" "Tested" }
            $e.Handled = $true; return
        }
        if ($k -match "Alt") {
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(164) -ge 0) { Set-KeyColor "LeftAlt" "Tested" }
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(165) -ge 0) { Set-KeyColor "RightAlt" "Tested" }
            $e.Handled = $true; return
        }

        if ($k -eq "Return") {
            Set-KeyColor "Return" "Tested"; Set-KeyColor "NumEnter" "Tested"
            $e.Handled = $true; return
        }

        Set-KeyColor $k "Tested"
        $e.Handled = $true
    })

    $window.ShowDialog() | Out-Null
}

&$LogicBanPhimFull