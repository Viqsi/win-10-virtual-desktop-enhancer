; vim:ft=autohotkey
;;;;;;;;;;;;;;;;;;;
;;; Setup Start ;;;
;;;;;;;;;;;;;;;;;;;
; As suggested by VD.ah2
#Requires AutoHotkey v2.0
#SingleInstance force
ListLines(False)
SendMode "Input"
SetWorkingDir(A_ScriptDir)
KeyHistory 0
#WinActivateForce

ProcessSetPriority("H")

SetWinDelay(-1)
SetControlDelay(-1)

HomeDir := EnvGet("USERPROFILE")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Window Position Management ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Keep NSNetMon and FB2K titlebar on top of the taskbar
; Uses WinMoveTop because they're *already* always-on-top, but so is the taskbar
GroupAdd("OverTaskbar", "NSnetmon ahk_class NSnetmon ahk_exe netmon.exe")
;GroupAdd("OverTaskbar", "dotnet_title_bar ahk_exe foobar2000.exe")
;GroupAdd("OverTaskbar", "Audacious ahk_exe audacious.exe")
rise_above_taskbar() {
    If IsWindowNotOverlapped(WinExist('ahk_class Shell_TrayWnd')) {
        TargetWindows := WinGetList("ahk_group OverTaskbar")
        For targetwindow In TargetWindows {
            WinMoveTop(targetwindow)
        }
    }
}
; Used to check if a window is overlapped
; Taken from https://www.autohotkey.com/boards/viewtopic.php?t=121402
IsWindowNotOverlapped(hWnd) {
    RECT1 := Buffer(16), RECT2 := Buffer(16), RECT3 := Buffer(16)
    DllCall('GetWindowRect', 'Ptr', hWnd, 'Ptr', RECT1)
    for wnd in WinGetList() {
        if wnd = hWnd {
            break
        }
        DllCall('GetWindowRect', 'Ptr', wnd, 'Ptr', RECT2)
        DllCall('IntersectRect', 'Ptr', RECT3, 'Ptr', RECT1, 'Ptr', RECT2)
        if DllCall('EqualRect', 'Ptr', RECT1, 'Ptr', RECT3) {
            return false
        }
    }
    return true
}


; Move notifications to the top of the screen rather than the bottom.
; Needed for Windows core notifications, micro-popups (current desktop,
; brightness meter, et cetera), and Steam notifications.
; NOTE: Actual window title for Steam is 'notificationtoasts_107_desktop' but
; that '107' makes me wary that it might change with future revisions, so I've
; gone with a truncated version.
GroupAdd("TopNotif", "New notification ahk_class Windows.UI.Core.CoreWindow")
GroupAdd("TopNotif", "ahk_class XamlExplorerHostIslandWindow")
GroupAdd("TopNotif",
        "notificationtoasts ahk_class SDL_app ahk_exe steamwebhelper.exe")
flip_to_top() {
    TargetWindows := WinGetList("ahk_group TopNotif")
    For TargetWindow In TargetWindows {
        WinGetPos(, &OrigY,, &Height, TargetWindow)
        If ((OrigY > (A_ScreenHeight / 2)) && (Height != 53)) {
            ; 53 is the height of a not-yet-opened new notification; this is a
            ; bug workaround.
            ; 50 is the Officially Determined Height of a taskbar in Win11;
            ; this is a workaround when using StartAllBack.
            WinMove(,Abs(A_ScreenHeight - OrigY - Height + 50),,, TargetWindow)
        }
    }
}

; Timer for both of the above.
WindowsManage() {
    flip_to_top()
    rise_above_taskbar()
}
SetTimer(WindowsManage, 10)


;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Desktop Switching ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;
#Include "VD\VD.ah2"
ChangeDesktopDisplayStatus(prevnum, num:=1) {
    A_IconTip := VD.getNameFromDesktopNum(num)
    try {
        TraySetIcon(A_ScriptDir "/icons/" num ".ico")
    } catch {
        ; if no such icon file is provided
        TraySetIcon(A_ScriptDir "/icons/+.ico")
    }
}
MoveWindowToDesktopNum(num:=1) {
    VD.MoveWindowToDesktopNum("A",num)
    VD.goToDesktopNum(num)
}
; set initial display status on launch
ChangeDesktopDisplayStatus(0,VD.getCurrentDesktopNum())
VD.RegisterDesktopNotifications()
VD.DefineProp("CurrentVirtualDesktopChanged", {Call:ChangeDesktopDisplayStatus})
; These are a roundabout way of implementing function key shortcuts for desktop
; switching.
F1::VD.goToDesktopNum(1)
F2::VD.goToDesktopNum(2)
F3::VD.goToDesktopNum(3)
F4::VD.goToDesktopNum(4)
+F1::MoveWindowToDesktopNum(1)
+F2::MoveWindowToDesktopNum(2)
+F3::MoveWindowToDesktopNum(3)
+F4::MoveWindowToDesktopNum(4)

; Desktop function key bypass (just in case)
#F1::Send("{F1}")
#F2::Send("{F2}")
#F3::Send("{F3}")
#F4::Send("{F4}")
#+F1::Send("+{F1}")
#+F2::Send("+{F2}")
#+F3::Send("+{F3}")
#+F4::Send("+{F4}")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Terminal Invocation/Management ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; I've gone through enough variants of these that I now have just a stand-in
; function for them with six possible calls.
terminal_invoke(termlaunchmode) {
    Switch termlaunchmode
    {
    ;; cygwin
        ; Note no "tmux" cases, as my switch to using tmux regularly came after
        ; I left cygwin behind (so "bash" was in the "tmux" hotkey spot)
        ;Case "bash": Run("C:\cygwin\bin\mintty.exe -i /Cygwin-Terminal.ico -")
    ;; msys
        ;Case "tmux": Run("C:\msys64\msys2_shell.cmd -msys -use-full-path -c 'tmux new'")
        ;Case "bash": Run("C:\msys64\msys2_shell.cmd -msys -use-full-path")
        ;Case "reattach": Run("C:\msys64\msys2_shell.cmd -msys -use-full-path -c 'tmux attach'")
    ;; wsl (original attempt)
        ; This one was abandoned because of a bug in which launching wsl.exe
        ; this way causes the scrollbar to be drawn over top of the last two
        ; columns. That was back when WCH was the default.
        ;Case "tmux": Run("wsl tmux new", HomeDir)
        ;Case "bash": Run("wsl", HomeDir)
        ;Case "reattach": Run("wsl tmux attach", HomeDir)
    ;; wsl (direct distro launch)
        ; This doesn't seem to suffer from the above noted wsl.exe bug.
        ; But then I discovered Windows Console Host doesn't support OSC 52.
        ; (It *appears* to if you test with local sessions, but go into ssh -
        ; or try writing the actual commands to the terminal - and you quickly
        ; discover it's just a mirage.)
        ; That's not a problem with WT as default, but then doing things this
        ; way gains you no benefit and costs you yet another process. Ugh.
        ;Case "tmux": Run("debian.exe run 'tmux new'", HomeDir)
        ;Case "bash": Run("debian.exe", HomeDir)
        ;Case "reattach": Run("debian.exe run 'tmux attach -c $HOME'", HomeDir)
    ;; wsltty
        ; This one keeps getting tried and abandoned for two reasons:
        ; 1) Process overhead: a WSL session requires SEVEN (yes, SEVEN)
        ;    processes - in addition to wsl.exe/wslhost.exe, the terminal, and
        ;    their respective conhost.exe processes, mintty adds wslbridge2.exe
        ;    and a THIRD conhost.exe
        ; 2) Their software distribution scheme is something beyond utterly
        ;    terrible, hopping into installer-managed profile folders without
        ;    actually bothering to be installer-manageable.
        ;Case "tmux": Run("C:\Users\jvc\AppData\Local\wsltty\bin\mintty.exe --WSL='Debian' --configdir='D:\AppData\Roaming\wsltty' 'tmux new'", HomeDir)
        ;Case "bash": Run("C:\Users\jvc\AppData\Local\wsltty\bin\mintty.exe --WSL='Debian' --configdir='D:\AppData\Roaming\wsltty' -", HomeDir)
        ;Case "reattach": Run("C:\Users\jvc\AppData\Local\wsltty\bin\mintty.exe --WSL='Debian' --configdir='D:\AppData\Roaming\wsltty' 'tmux attach'", HomeDir)
    ;; alternate shells fallback
        ; These have generally assumed Windows Console Host as the default
        ; terminal.
        ;Case "pwsh": Run("pwsh.exe", HomeDir)
        ;Case "cmd":Run("cmd.exe", HomeDir)
    ;; alacritty (wsl AND alternate shells)
        ; I keep coming back to this one as a Least Common Acceptable option
        ; despite frustration with the developers, minor (but sometimes
        ; tolerable and/or workaroundable) bugs, and other foibles.
        ;Case "tmux": Run("alacritty -e 'wsl tmux new'", HomeDir)
        ;Case "bash": Run("alacritty -e 'wsl'", HomeDir)
        ;Case "reattach": Run("alacritty -e 'wsl tmux attach -c $HOME'", HomeDir)
        ;Case "pwsh": Run("alacritty -o scrolling.history=50000 -e 'pwsh'", HomeDir)
        ;Case "cmd": Run("alacritty -o scrolling.history=50000 -e 'cmd'", HomeDir)
    ;; Windows Terminal Direct
        ; Current choice because it's got the same process overhead as
        ; alacritty but with smaller processes AND I may have it beaten into
        ; shape now. Direct invocation using 'wt' avoids increasing the
        ; process overhead. Requires use of a custom-edited version of my usual
        ; font of choice because #3498.
        ; Default profile is assumed to be the WSL one.
        Case "tmux": Run("wt -p DebianNewTmux", HomeDir)
        Case "bash": Run("wt -p Debian", HomeDir)
        Case "reattach": Run("wt -p DebianReattachTmux", HomeDir)
        Case "pwsh": Run("wt -p PowerShell", HomeDir)
        Case "cmd": Run("wt -p `"Command Prompt`"", HomeDir)
    }
}
F11::terminal_invoke("tmux")
+F11::terminal_invoke("bash")
^+F11::terminal_invoke("reattach")
^F11::terminal_invoke("pwsh")
^#F11::terminal_invoke("cmd")

; Contextual new terminal windows function
; NOTE: Dependent on my configuration elsewhere that sets window title strings
; based on the current shell. Yay egregious hacks!
NewTerminalWindowFromExisting() {
    if (WinActive("PS ")) {
        terminal_invoke("pwsh")
    } else if (WinActive("CMD ")) {
        terminal_invoke("cmd")
    } else {
        terminal_invoke("tmux")
    }
}

; Terminal Windows group. Used for checking if they're active, which comes up in
; some "command key" aliases below.
GroupAdd("TerminalWindows", "ahk_class ConsoleWindowClass")
GroupAdd("TerminalWindows", "ahk_class mintty")
GroupAdd("TerminalWindows", "ahk_exe alacritty.exe")
GroupAdd("TerminalWindows", "ahk_exe WindowsTerminal.exe")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Other Application Invocation Hotkeys ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
F10::Run("C:\Program Files\Vim\vim91\gvim.exe", HomeDir)
#HotIf Not WinActive("ahk_exe Arcanum.exe")
F9::Run("C:\WINDOWS\system32\calc.exe")
#HotIf


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; "Command Key" And Other MacOSisms ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; These require that UseHook be turned OFF. Otherwise, you'll run into issues
; with command-C, command-A, et cetera.
; Adapted from original ahk1 code from https://superuser.com/a/1096541

;![::Send("!{Left}")
;!]::Send("!{Right}")
!a::Send("^a")
!b::Send("^b")
!c::Send("^c")
!d::Send("^d")
!e::Send("^e")
#HotIf Not WinActive("ahk_exe Civ4BeyondSword.exe")
!f::Send("^f")
#HotIf
!g::Send("^g")
!h::Send("^h")
!i::Send("^i")
!j::Send("^j")
!k::Send("^k")
!l::Send("^l")
!m::Send("^m")
!n::Send("^n")
!o::Send("^o")
<!p::Send("^p")
;!q::Send("^q")
!q::WinClose("A")
!r::Send("^r")
!s::Send("^s")
!t::Send("^t")
!u::Send("^u")
!v::Send("^v")
!w::Send("^w")
#HotIf Not WinActive("ahk_exe Civ4BeyondSword.exe")
!x::Send("^x")
#HotIf
!y::Send("^y")
!z::Send("^z")
!\::Send("^\")
!+a::Send("^+a")
!+b::Send("^+b")
!+c::Send("^+c")
!+d::Send("^+d")
!+e::Send("^+e")
!+f::Send("^+f")
!+g::Send("^+g")
!+h::Send("^+h")
!+i::Send("^+i")
!+j::Send("^+j")
!+k::Send("^+k")
!+l::Send("^+l")
!+m::Send("^+m")
!+n::Send("^+n")
!+o::Send("^+o")
!+p::Send("^+p")
!+q::Send("^+q")
!+r::Send("^+r")
!+s::Send("^+s")
!+t::Send("^+t")
!+u::Send("^+u")
!+v::Send("^+v")
!+w::Send("^+w")
!+x::Send("^+x")
!+y::Send("^+y")
!+z::Send("^+z")
!+\::Send("^+\")

^!e::Send("€")

;!Space::Send("^{Space}")
;!Space::Send("^!{End}")

;!Right::
;Send("{End}")
;return

;*!Right:: ; This handles Shift-Right
;Send("{Blind}{LAlt Up}{End}")
;return

;!Left::
;Send("{Home}")
;return

;*!Left:: ; This handles Shift-Left
;Send("{Blind}{Alt Up}{Home}")
;return

; Alternate screenshot system
!+3::Send("#{PrintScreen}")
!+4::Send("#+s")

; Command-N for new window in Explorer
#HotIf WinActive("ahk_class CabinetWClass")
!n::Send("#e")
#HotIf
; Command-N for new window and Command-C/X/V for copy/cut/paste in terminals
#HotIf WinActive("ahk_group TerminalWindows")
!n::NewTerminalWindowFromExisting()
!c::Send("^{Insert}")
!x::Send("^{Delete}")
!v::Send("+{Insert}")
#HotIf
; Command-R to rename pdf, Command/Control-W to close window in SumatraPDF
#HotIf WinActive("ahk_exe SumatraPDF.exe")
!r::Send("{F2}")
!w::WinClose("A")
^w::WinClose("A")
!q::Send("^q")  ; override earlier 
#HotIf
; Command/Control-W to close window in PDFXChange
#HotIf WinActive("ahk_exe PDFXEdit.exe")
!w::WinClose("A")
^w::WinClose("A")
#HotIf
; Command/Control-backslash for 1password in Floorp
#HotIf WinActive("ahk_class MozillaWindowClass")
!\::Send("^.")
^\::Send("^.")
#HotIf


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Window Maximization ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; The basic concept:
; * Alt-F3 maximizes windows.
; * Alt+Shift+F3 maximizes vertically only.
; * Some app windows (gvim, terminals) default to vertical-only.

; WinRestore workaround
; Documented on https://www.autohotkey.com/docs/v2/lib/WinRestore.htm
; Used instead because WSL X windows in particular freak out at WinRestore()
WinRestoreWork(wintitle) {
    PostMessage(0x0112, 0xF120, , , wintitle)
}

; Regular maximizing toggle
; based on original v1 toggle code from https://superuser.com/a/403017
MaximizeToggle() {
    if (WinGetMinMax("A")) {
        WinRestoreWork("A")
    } else {
        WinMaximize("A")
    }
}
; Vertical-only maximizing toggle.
; Previously, I handled this via simulating the necessary mouse clicks, but
; this became a tad error-prone (especially if the mouse was bumped between
; clicks somehow). So now I'm using one based on the keyboard shortcut Windows
; provides. I'd just use it all the time, except it's not a toggle, so...
VMaximizeToggle() {
    ; unlike regular maximizing, no "maximized" state is explicitly set when
    ; doing a vertical-only maximize, so we have to try other means
    WinGetPos(&OX,&OY,&OW,&OH,"A")
    ;MsgBox("OX:" OX " OY:" OY " OW:" OW " OH:" OH)
    Send("#+{Up}")  ; no-op if already vertically maximized
    WinGetPos(&NX,&NY,&NW,&NH,"A")
    ;MsgBox("NX:" NX " NY:" NY " NW:" NW " NH:" NH)
    if (OY == OY && OX == NX && OW == NW && OH == NH) {
        WinRestoreWork("A")
    }
}
; Default: Alt-F3 maximizes all, Alt-Shift-F3 does vertical-only.
!F3::MaximizeToggle()
!+F3::VMaximizeToggle()
; Vertical-only maximize windows swap these.
GroupAdd("VerticalMaximizeDefault", "ahk_group TerminalWindows")
GroupAdd("VerticalMaximizeDefault", "ahk_exe gvim.exe")
GroupAdd("VerticalMaximizeDefault", "GVIM ahk_exe msrdc.exe")
#HotIf WinActive("ahk_group VerticalMaximizeDefault")
!F3::VMaximizeToggle()
!+F3::MaximizeToggle()
#HotIf


;;;;;;;;;;;;;;;;;;;;;;;
;;; Everything Else ;;;
;;;;;;;;;;;;;;;;;;;;;;;

; screen turn off
; adapted from ahk1 code from https://superuser.com/a/485930
ScreenTurnOff() {
    Sleep(1000)
    SendMessage(0x112, 0xF170, 2,, "Program Manager")
}
#m::ScreenTurnOff()

; extra hotkeys for FBReader
#HotIf WinActive("ahk_exe FBReader.exe",,"FBReader")
Up::Left
Down::Right
PgUp::Left
PgDn::Right
BS::Left
+Space::Left
(::Left
)::Right
#HotIf

; Temporary rename key for irfanview
#HotIf WinActive("ahk_exe i_view64.exe")
Ins::Send("{F2}")
#HotIf

ExplicitResize() {
    Active_ID := WinGetID("A")
    Active_Title := WinGetTitle("A")
    wW := InputBox("Enter the desired window width:", "Window width", "W260 H130")
    wH := InputBox("Enter the desired window height:", "Window height", "W260 H130")
    WinRestoreWork(%Active_Title%)
    WinMove(, , wW, wH, "ahk_id " Active_ID)
}
^=::ExplicitResize()


; Scripting silliness for Roblox (specifically The Wild West but could possibly 
; be extended to others).
;
; The goal is basically to be able to Toggle Aim/Camera Follows Mouse. Roblox
; games generally require the right mouse button to be held down to aim, and we
; want that to be toggleable, and we also want to be able to indicate when
; messing with that toggle should be temporarily suspended (when typing in a
; text window, for example).
; There are normally ways to toggle "hold down RMB" with other utilities I
; have, BUT when certain keys are pressed, Roblox seemingly throws away the
; current RMB-pressed state. So it has to be reestablished.
; So in the end, we have two states to track - whether or not RMB should be
; held down right now (for doing the Right Thing during refreshes) and whether
; or not we're currently in a mode in-game where messing with that toggle
; should be temporarily suspended.
; This got turned into a class because, frankly, I was rapidly ending up with
; too many globals. And I needed something to track the state of our state (so
; now it's even got a GUI!)
;
; States are:
; * HoldingRMB: We want the RMB (Right Mouse Button) to be held down.
; * ChatMode: Halt *all* processing of RMB holds because we are inputting text.
; I used to also have a SuspendingHold for temporarily suspending Hold whether
; it was on or off and then resume afterwards, but backing out of Suspend Mode
; could be done with multiple different possible inputs and it proved to be too
; difficult to track reliably, so instead those cases Force Hold Off.
;
; Despite best efforts, occasionally use of this script will put the system in
; a state such that left and right mouse clicks do not make it through to *any*
; other window. The only reliable way I've found of clearing this state is to,
; using keyboard shortcuts, *hibernate the computer then bring it back up
; again*. Yeah. It's that kind of hack. :(

class RobloxHoldRMB {
    __new(DestWindow) {
        this.DestWindow := DestWindow
        this.HoldingRMB := False
        this.ChatMode := False
        this.ButtonCount := 0
        this.OSDGui := this._OSDCreateGui()
        ; figure center of screen
        WinGetClientPos(&RBX, &RBY, &RBW, &RBH, this.DestWindow)
        this.xcenter := (RBW) // 2
        this.ycenter := (RBH) // 2
    }
    
    _OSDCreateGui() {
        OSDGui := Gui("-caption +alwaysontop +toolwindow")
        OSDGui.SetFont("s10 w600", "Arial Bold")
        OSDGui.MarginX := 0
        OSDGui.MarginY := 0
        OSDGui.Add("Text", "x0 y0 cWhite backgroundRed vRMBHeld", "Hold")
        OSDGui.Add("Text", "x+10 y0 cWhite backgroundRed vRMBChat", "Chat")
        OSDGui.Add("Text", "x+10 y0 cWhite backgroundBlue vRMBCount",
                this.ButtonCount)
        OSDGui.Show("x500 y26")
        return OSDGui
    }
    
    _CenterMouse() {
        MouseMove(this.xcenter, this.ycenter, 0)
    }
    
    _SendClick(updown) {
        ;ControlClick("x" . this.xcenter . " y" . this.ycenter, this.DestWindow,,"R",,updown . " Pos NA")
        ; Roblox doesn't seem to respond to ControlClick at all (probably for
        ; anticheat reasons; you could implement an idle background bot with
        ; it). So instead we armor Sends with WinActive checks.
        WinActivate(this.DestWindow)
        If (updown = "D") {
            If (WinActive(this.DestWindow)) {
                Send("{RButton down}")
                this.ButtonCount += 1
            }
        } Else {
            If (WinActive(this.DestWindow)) {
                Send("{RButton up}")
                this.ButtonCount -= 1
            }
        }
        this.OSDGui["RMBCount"].Text := this.ButtonCount
        this.OSDGui["RMBCount"].Redraw()
    }
    
    _UpdateGui(textctl, onoroff) {
        If onoroff {
            this.OSDGui[textctl].Opt("backgroundGreen")
        } Else {
            this.OSDGui[textctl].Opt("backgroundRed")
        }
        this.OSDGui[textctl].Redraw()
    }
    
    _Reconcile() {
        While this.ButtonCount > 0 {
            this._SendClick("U")
        }
        While this.ButtonCount < 0 {
            this._SendClick("D")
        }
    }
    
    RMBRefresh() {
        ; Refresh RMB hold state after Roblox throws it away.
        this._Reconcile()
        if (!this.ChatMode and this.HoldingRMB) {
            this._CenterMouse()
            ;Sleep(200)
            ;this._SendClick("D")
            Loop(3) {
                this._SendClick("D")
                Sleep 100
            }
        }
    }
    
    RMBChatSwitch(mode) {
        this.ChatMode := mode
        this._UpdateGui("RMBChat", this.ChatMode)
        this.RMBRefresh()
    }
    
    RMBForceOff() {
        ; only needs to fire if we're already on
        if (!this.ChatMode and this.HoldingRMB) {
            this.HoldingRMB := False
            this._UpdateGui("RMBHeld", this.HoldingRMB)
            this.RMBRefresh()
        }
    }
    
    RMBToggle() {
        if (!this.ChatMode) {
            this.HoldingRMB := !this.HoldingRMB
            this._UpdateGui("RMBHeld", this.HoldingRMB)
            this.RMBRefresh()
        }
    }
    
    __Delete() {
        this._Reconcile()
        this.OSDGui.Destroy()
    }
}

RBHRMB() {
    global RBHRMBInstance
    if (!IsSet(RBHRMBInstance)) {
        try {
            RBHRMBInstance := RobloxHoldRMB(
                    WinExist("ahk_exe RobloxPlayerBeta.exe"))
                    ;WinExist("ahk_exe KeyTest.exe"))
        }
    }
    return RBHRMBInstance
}
RBHRMB_Exit() {
    global RBHRMBInstance
    if (IsSet(RBHRMBInstance)) {
        RBHRMBInstance := unset   ; destroy (AHK will GC the object)
    }
}

#HotIf WinActive("ahk_exe RobloxPlayerBeta.exe")
;#HotIf WinActive("ahk_exe KeyTest.exe")
; Currently set up for controls for The Wild West.
~1::RBHRMB().RMBRefresh()   ; hotbar weapons and tools
~2::RBHRMB().RMBRefresh()
~3::RBHRMB().RMBRefresh()
~4::RBHRMB().RMBRefresh()
~5::RBHRMB().RMBRefresh()
~6::RBHRMB().RMBRefresh()
~7::RBHRMB().RMBForceOff()  ; for sheriff baton
~8::RBHRMB().RMBForceOff()  ; for sheriff cuffs
~v::RBHRMB().RMBRefresh()   ; first/third person switch
~b::RBHRMB().RMBForceOff()  ; backpack window
~m::RBHRMB().RMBForceOff()  ; map window
~t::RBHRMB().RMBForceOff()  ; character customization window
~h::RBHRMB().RMBForceOff()  ; Pick A Horse window
~p::RBHRMB().RMBRefresh()   ; Friendly/Hostile toggle
~e::RBHRMB().RMBRefresh()   ; primary use/action
~f::RBHRMB().RMBRefresh()   ; secondary use/action
        ; The above two are complicated because they don't always pop up a UX
        ; dialog. When they *do* (talking to shopkeepers, opening a chest, et
        ; cetera) we'd prefer ForceOff, and when they *don't* (picking up a
        ; drop, sitting down, et cetera) we'd prefer Refresh. And we have no
        ; reliable way of detecting which because Roblox doesn't expose hooks
        ; for detecting such states for anticheat reasons.
        ; So I'm opting to just leave them alone and do any switching manually.
        ; CORRECTION: I'm having it refresh, and turning things off manually.
~/::RBHRMB().RMBChatSwitch(True)    ; send a message
~Esc::{ ; EITHER Roblox menu OR cancel chat
    ; forceoff first as it'll work outside of chat mode
    ; otherwise, just end chat mode
    RBHRMB().RMBForceOff()
    RBHRMB().RMBChatSwitch(False)
}
~Enter::RBHRMB().RMBChatSwitch(False)   ; Chat Send
F13::RBHRMB().RMBToggle()     ; primary toggle key
`::{    ; "master reset and rehold" key
    RBHRMB_Exit()
    RBHRMB().RMBToggle()
}
Del::RBHRMB_Exit()  ; "bail out" key
#HotIf
F14::Reload ; in case the "can't click on anything else" bug recurs
