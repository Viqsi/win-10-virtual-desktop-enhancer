#Include, %A_ScriptDir%\virtual-desktop-enhancer.ahk
; These are a roundabout way of implementing function key shortcuts for desktop switching.
F1::SwitchToDesktop(1)
F2::SwitchToDesktop(2)
F3::SwitchToDesktop(3)
F4::SwitchToDesktop(4)
+F1::MoveAndSwitchToDesktop(1)
+F2::MoveAndSwitchToDesktop(2)
+F3::MoveAndSwitchToDesktop(3)
+F4::MoveAndSwitchToDesktop(4)


#UseHook off
;;;;;;; personal hotkeys follow from here

;;;; Terminals
;;; I've gone through several different variants of these...
;; cygwin
;F11::Run C:\cygwin\bin\mintty.exe -i /Cygwin-Terminal.ico -
;; msys
;F11::Run C:\msys64\msys2_shell.cmd -msys -use-full-path -c 'tmux new'
;+F11::Run C:\msys64\msys2_shell.cmd -msys -use-full-path
;^+F11::Run C:\msys64\msys2_shell.cmd -msys -use-full-path -c 'tmux attach'
;; wsl (original attempt)
; This one was abandoned because of a bug in which launching wsl.exe this way
; causes the scrollbar to be drawn over top of the last two columns.
;F11::Run wsl tmux new, %home%
;+F11::Run wsl, %home%
;^+F11::Run wsl tmux attach, %home%
;; wsl (direct distro launch)
; This doesn't seem to suffer from the above noted wsl.exe bug. But it doesn't support OSC 52, so...
;F11::Run debian.exe run "tmux new", %home%
;+F11::Run debian.exe, %home%
;^+F11::Run debian.exe run "tmux attach -c $HOME", %home%
;^F11::Run pwsh.exe, %home%
;^#F11::Run cmd.exe, %home%
;; wsltty
;wsltty_invoke(options) {
;    Run, C:\Users\jvc\AppData\Local\wsltty\bin\mintty.exe --WSL="Debian" --configdir="D:\AppData\Roaming\wsltty" %options%, %home%
;}
;F11::wsltty_invoke("tmux new")
;+F11::wsltty_invoke("-")
;^+F11::wsltty_invoke("tmux attach")
;; powershell fallback
;^F11::Run pwsh.exe, %home%
;; alacritty
F11::Run alacritty -e "wsl tmux new", %home%
+F11::Run alacritty -e "wsl", %home%
^+F11::Run alacritty -e "wsl tmux attach -c $HOME", %home%
^F11::Run alacritty -o scrolling.history=50000 -e "pwsh", %home%
^#F11::Run alacritty -o scrolling.history=50000 -e "cmd", %home%

;; other hotkeys
F10::Run "C:\Program Files\Vim\vim90\gvim.exe", %home%
#If Not WinActive("ahk_exe Arcanum.exe")
F9::Run "C:\WINDOWS\system32\calc.exe"
#If

; screen turn off
; taken from https://superuser.com/a/485930
#m::
Sleep 1000
SendMessage, 0x112, 0xF170, 2,, Program Manager
return


;;;;;;; "command key"
; These require that UseHook be turned OFF. Otherwise, you'll run into issues with command-C, command-A, et cetera
; Taken from https://superuser.com/a/1096541

;![::Send !{Left}
;!]::Send !{Right}
!a::Send ^a
!b::Send ^b
!c::Send ^c
!d::Send ^d
!e::Send ^e
!f::Send ^f
!g::Send ^g
!h::Send ^h
!i::Send ^i
!j::Send ^j
!k::Send ^k
!l::Send ^l
!m::Send ^m
!n::Send ^n
!o::Send ^o
<!p::Send ^p
;!q::Send ^q
!q::WinClose, A
!r::Send ^r
!s::Send ^s
!t::Send ^t
!u::Send ^u
!v::Send ^v
!w::Send ^w
!x::Send ^x
!y::Send ^y
!z::Send ^z
!\::Send ^\
!+a::Send ^+a
!+b::Send ^+b
!+c::Send ^+c
!+d::Send ^+d
!+e::Send ^+e
!+f::Send ^+f
!+g::Send ^+g
!+h::Send ^+h
!+i::Send ^+i
!+j::Send ^+j
!+k::Send ^+k
!+l::Send ^+l
!+m::Send ^+m
!+n::Send ^+n
!+o::Send ^+o
!+p::Send ^+p
!+q::Send ^+q
!+r::Send ^+r
!+s::Send ^+s
!+t::Send ^+t
!+u::Send ^+u
!+v::Send ^+v
!+w::Send ^+w
!+x::Send ^+x
!+y::Send ^+y
!+z::Send ^+z
!+\::Send ^+\

;!Space::Send ^{Space}
;!Space::Send ^!{End}

;!Right::
;Send {End}
;return

;*!Right:: ; This handles Shift-Right
;Send {Blind}{LAlt Up}{End}
;return

;!Left::
;Send {Home}
;return

;*!Left:: ; This handles Shift-Left
;Send {Blind}{Alt Up}{Home}
;return

;Alternate screenshot system
!+3::Send #{PrintScreen}
!+4::Send #+s

;Command-N for new window in Explorer
#If WinActive("ahk_class CabinetWClass")
!n::Send #e
#If
;Command-N for new window in WSL
;#If WinActive("ahk_exe wsl.exe")
#If WinActive("ahk_exe debian.exe")
;!n::Run wsl ~ tmux new
!n::Run debian.exe run "tmux new", %home%
#If
;Command-N for new window in PowerShell
#If WinActive("ahk_exe pwsh.exe")
!n::Run pwsh.exe, %home%
#If
;Command-N for new window in wsltty
;#If WinActive("ahk_exe mintty.exe")
;!n::wsltty_invoke("tmux new")
;#If
;Command-N for new window in alacritty
;#If WinActive("ahk_exe alacritty.exe")
;!n::Run alacritty -e "wsl tmux new", %home%
;#If
;Command-R to rename pdf in SumatraPDF
#If WinActive("ahk_exe SumatraPDF.exe")
!r::Send {F2}
#If
;Command/Control-W to close window in PDFXChange
#If WinActive("ahk_exe PDFXEdit.exe")
!w::WinClose, A
^w::WinClose, A
#If


;;;;;;;; Window Maximization
; The basic concept:
; * Alt-F3 maximizes windows.
; * Alt+Shift+F3 maximizes vertically only.
; * Some app windows (gvim, mintty) default to vertical-only.

; Regular maximizing toggle
; Toggle code from https://superuser.com/a/403017
MaximizeToggle() {
    WinGet MX, MinMax, A
    If MX
        WinRestore A
    Else WinMaximize A
}
; Vertical-only maximize setup.
; There's no simple function to make this happen like there is for WinMaximize,
; so we simulate the necessary mouse clicks. Thankfully, it serves as a toggle
; naturally, so I don't have to implement switching to WinRestore, A or
; anything like that.
VerticalOnlyMaximize() {
    ; We want to save our current mouse position, and that requires converting
    ; to screen coordinates mode. For the actual click, tho, we'll want window
    ; coordinates mode.
    CurrentCoordMode := A_CoordModeMouse
    CoordMode, Mouse, Screen
    MouseGetPos, MouseX, MouseY
    CoordMode, Mouse, Window
    MouseClick, left, 20, 1, 2, 0
    CoordMode, Mouse, Screen
    MouseMove, MouseX, MouseY, 0
    CoordMode, Mouse, CurrentCoordMode
}
; Default: Alt-F3 maxizes all, Alt-Shift-F3 does vertical-only.
!F3::MaximizeToggle()
!+F3::VerticalOnlyMaximize()
; Default vertical-only maximize windows.
#If WinActive("ahk_exe gvim.exe") || WinActive("ahk_class ConsoleWindowClass")
!F3::VerticalOnlyMaximize()
!+F3::MaximizeToggle()
#If


;Command-C/X/V for copy/cut/paste in mintty
#If WinActive("ahk_class mintty")
!c::Send ^{Insert}
!x::Send ^{Delete}
!v::Send +{Insert}
#If
;Command-C/X/V for copy/cut/paste in alacritty
#If WinActive("ahk_exe alacritty.exe")
!c::Send ^{Insert}
!x::Send ^{Delete}
!v::Send +{Insert}
#If
;Command-C and Command-V for copy/paste in WSL
;#IfWinActive ahk_exe wsl.exe
#If WinActive("ahk_exe debian.exe")
!c::Send ^+c
!v::Send ^+v
;return
#If

; Desktop function key bypass
#F1::Send {F1}
#F2::Send {F2}
#F3::Send {F3}
#F4::Send {F4}
#+F1::Send +{F1}
#+F2::Send +{F2}
#+F3::Send +{F3}
#+F4::Send +{F4}

; Temporary rename key for irfanview
#if WinActive("ahk_exe i_view64.exe")
Ins::Send {F2}
#If
