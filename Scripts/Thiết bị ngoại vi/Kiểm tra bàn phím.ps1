# ÉP POWERSHELL HIỂU TIẾNG VIỆT 100%
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

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
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "VietToolbox - Keyboard Test Full 104 (Hardware Scan)"; $form.Size = "1120,450"
    $form.BackColor = "#FFFFFF"; $form.StartPosition = "CenterScreen"; $form.FormBorderStyle = "FixedDialog"; $form.KeyPreview = $true

    $pnlKey = New-Object System.Windows.Forms.Panel
    $pnlKey.Location = "20,50"; $pnlKey.Size = "1065,330"; $pnlKey.BackColor = "#F4F5F7"
    $form.Controls.Add($pnlKey)

    $btns = @{}
    # Cấu trúc chuẩn: Mã Key, X, Y, Rộng, Chữ hiển thị
    $layout = @(
        @("Escape",5,5,40,"Esc"), @("F1",65,5,40,"F1"), @("F2",110,5,40,"F2"), @("F3",155,5,40,"F3"), @("F4",200,5,40,"F4"), @("F5",260,5,40,"F5"), @("F6",305,5,40,"F6"), @("F7",350,5,40,"F7"), @("F8",395,5,40,"F8"), @("F9",455,5,40,"F9"), @("F10",500,5,40,"F10"), @("F11",545,5,40,"F11"), @("F12",590,5,40,"F12"), @("PrintScreen",650,5,40,"Prt"), @("Scroll",695,5,40,"Scr"), @("Pause",740,5,40,"Pau"),
        @("Oemtilde",5,50,40,"~"), @("D1",50,50,40,"1"), @("D2",95,50,40,"2"), @("D3",140,50,40,"3"), @("D4",185,50,40,"4"), @("D5",230,50,40,"5"), @("D6",275,50,40,"6"), @("D7",320,50,40,"7"), @("D8",365,50,40,"8"), @("D9",410,50,40,"9"), @("D0",455,50,40,"0"), @("OemMinus",500,50,40,"-"), @("Oemplus",545,50,40,"="), @("Back",590,50,85,"Back"),
        @("Tab",5,95,60,"Tab"), @("Q",70,95,40,"Q"), @("W",115,95,40,"W"), @("E",160,95,40,"E"), @("R",205,95,40,"R"), @("T",250,95,40,"T"), @("Y",295,95,40,"Y"), @("U",340,95,40,"U"), @("I",385,95,40,"I"), @("O",430,95,40,"O"), @("P",475,95,40,"P"), @("OemOpenBrackets",520,95,40,"["), @("Oem6",565,95,40,"]"), @("Oem5",610,95,65,"\"),
        @("Capital",5,140,75,"Caps"), @("A",85,140,40,"A"), @("S",130,140,40,"S"), @("D",175,140,40,"D"), @("F",220,140,40,"F"), @("G",265,140,40,"G"), @("H",310,140,40,"H"), @("J",355,140,40,"J"), @("K",400,140,40,"K"), @("L",445,140,40,"L"), @("Oem1",490,140,40,";"), @("Oem7",535,140,40,"'"), @("Return",580,140,95,"Enter"),
        @("LShiftKey",5,185,100,"Shift"), @("Z",110,185,40,"Z"), @("X",155,185,40,"X"), @("C",200,185,40,"C"), @("V",245,185,40,"V"), @("B",290,185,40,"B"), @("N",335,185,40,"N"), @("M",380,185,40,"M"), @("Oemcomma",425,185,40,","), @("OemPeriod",470,185,40,"."), @("OemQuestion",515,185,40,"/"), @("RShiftKey",560,185,115,"Shift"),
        @("LControlKey",5,230,55,"Ctrl"), @("LWin",65,230,50,"Win"), @("LMenu",120,230,50,"Alt"), @("Space",175,230,280,"Space"), @("RMenu",460,230,50,"Alt"), @("RWin",515,230,50,"Win"), @("Apps",570,230,50,"App"), @("RControlKey",625,230,50,"Ctrl"),
        
        # --- CỤM ĐIỀU KHIỂN & NUMPAD ---
        @("Insert",690,50,45,"Ins"), @("Home",740,50,45,"Hom"), @("PageUp",790,50,45,"PgU"),
        @("Delete",690,95,45,"Del"), @("End",740,95,45,"End"), @("Next",790,95,45,"PgD"),
        @("Up",740,185,45,"▲"), @("Left",690,230,45,"◄"), @("Down",740,230,45,"▼"), @("Right",790,230,45,"►"),
        @("NumLock",855,50,45,"Num"), @("Divide",905,50,45,"/"), @("Multiply",955,50,45,"*"), @("Subtract",1005,50,45,"-"),
        @("NumPad7",855,95,45,"7"), @("NumPad8",905,95,45,"8"), @("NumPad9",955,95,45,"9"), @("NumPad4",855,140,45,"4"), @("NumPad5",905,140,45,"5"), @("NumPad6",955,140,45,"6"), @("Add",1005,95,45,85,"+"),
        @("NumPad1",855,185,45,"1"), @("NumPad2",905,185,45,"2"), @("NumPad3",955,185,45,"3"), @("NumPad0",855,230,95,"0"), @("Decimal",955,230,45,"."), @("NumEnter",1005,185,45,85,"Ent")
    )

    foreach($k in $layout) {
        $h = if ($k[4] -is [int]) { $k[4] } else { 40 }
        $txt = if ($k[4] -is [string]) { $k[4] } else { $k[5] }
        $b = New-Object System.Windows.Forms.Button
        $b.Text = $txt; $b.Location = New-Object System.Drawing.Point($k[1], $k[2]); $b.Size = New-Object System.Drawing.Size($k[3], $h)
        $b.BackColor = "#E1E4E8"; $b.ForeColor = "#394E60"; $b.FlatStyle = "Flat"; $b.FlatAppearance.BorderSize = 0; $b.Enabled = $false
        $pnlKey.Controls.Add($b); $btns[$k[0]] = $b
    }

    # --- HÀM XỬ LÝ NHẤN PHÍM ---
    $form.Add_KeyDown({ param($s,$e) 
        $k = $e.KeyCode.ToString()

        # XỬ LÝ ĐẶC BIỆT CHO CÁC PHÍM TRÁI/PHẢI BẰNG PHẦN CỨNG (WIN32 API)
        if ($k -eq "ShiftKey") {
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(160) -lt 0) { $btns["LShiftKey"].BackColor = "#00FF00"; $btns["LShiftKey"].ForeColor = "Black" }
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(161) -lt 0) { $btns["RShiftKey"].BackColor = "#00FF00"; $btns["RShiftKey"].ForeColor = "Black" }
            return
        }
        if ($k -eq "ControlKey") {
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(162) -lt 0) { $btns["LControlKey"].BackColor = "#00FF00"; $btns["LControlKey"].ForeColor = "Black" }
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(163) -lt 0) { $btns["RControlKey"].BackColor = "#00FF00"; $btns["RControlKey"].ForeColor = "Black" }
            return
        }
        if ($k -eq "Menu") {
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(164) -lt 0) { $btns["LMenu"].BackColor = "#00FF00"; $btns["LMenu"].ForeColor = "Black" }
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(165) -lt 0) { $btns["RMenu"].BackColor = "#00FF00"; $btns["RMenu"].ForeColor = "Black" }
            return
        }

        # Sáng cả 2 phím Enter khi nhấn Enter
        if ($k -eq "Return") {
            if ($btns.ContainsKey("Return")) { $btns["Return"].BackColor = "#00FF00"; $btns["Return"].ForeColor = "Black" }
            if ($btns.ContainsKey("NumEnter")) { $btns["NumEnter"].BackColor = "#00FF00"; $btns["NumEnter"].ForeColor = "Black" }
            return
        }

        # Các phím thường
        if ($btns.ContainsKey($k)) { $btns[$k].BackColor = "#00FF00"; $btns[$k].ForeColor = "Black" }
    })

    # --- HÀM XỬ LÝ THẢ PHÍM ---
    $form.Add_KeyUp({ param($s,$e) 
        $k = $e.KeyCode.ToString()

        if ($k -eq "ShiftKey") {
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(160) -ge 0) { $btns["LShiftKey"].BackColor = "#0068FF"; $btns["LShiftKey"].ForeColor = "White" }
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(161) -ge 0) { $btns["RShiftKey"].BackColor = "#0068FF"; $btns["RShiftKey"].ForeColor = "White" }
            return
        }
        if ($k -eq "ControlKey") {
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(162) -ge 0) { $btns["LControlKey"].BackColor = "#0068FF"; $btns["LControlKey"].ForeColor = "White" }
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(163) -ge 0) { $btns["RControlKey"].BackColor = "#0068FF"; $btns["RControlKey"].ForeColor = "White" }
            return
        }
        if ($k -eq "Menu") {
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(164) -ge 0) { $btns["LMenu"].BackColor = "#0068FF"; $btns["LMenu"].ForeColor = "White" }
            if ([VietToolbox.KeyHook]::GetAsyncKeyState(165) -ge 0) { $btns["RMenu"].BackColor = "#0068FF"; $btns["RMenu"].ForeColor = "White" }
            return
        }

        if ($k -eq "Return") {
            if ($btns.ContainsKey("Return")) { $btns["Return"].BackColor = "#0068FF"; $btns["Return"].ForeColor = "White" }
            if ($btns.ContainsKey("NumEnter")) { $btns["NumEnter"].BackColor = "#0068FF"; $btns["NumEnter"].ForeColor = "White" }
            return
        }

        # Các phím thường
        if ($btns.ContainsKey($k)) { $btns[$k].BackColor = "#0068FF"; $btns[$k].ForeColor = "White" }
    })

    $form.ShowDialog() | Out-Null
}

&$LogicBanPhimFull