;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Window Z-Level Management ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Keep NSNetMon and FB2K on top of the taskbar
; At the top of the script due to script execution setup timing (basically, we
; need to do this *before* pulling in virtual-desktop-enhancer)
TBWindowsRise() {
    WinSet, Top,, dotnet_title_bar
    WinSet, Top,, NSnetmon
}
SetTimer, TBWindowsRise, 1000


;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Desktop Switching ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;
; Near the top of the script as as to minimize environment changes made before
; virtual-desktop-enhancer (and its environment changes) is brought in.

#Include, %A_ScriptDir%\virtual-desktop-enhancer.ahk
; These are a roundabout way of implementing function key shortcuts for desktop
; switching.
F1::SwitchToDesktop(1)
F2::SwitchToDesktop(2)
F3::SwitchToDesktop(3)
F4::SwitchToDesktop(4)
+F1::MoveAndSwitchToDesktop(1)
+F2::MoveAndSwitchToDesktop(2)
+F3::MoveAndSwitchToDesktop(3)
+F4::MoveAndSwitchToDesktop(4)
#UseHook off    ; needed for later stuff to work consistently

; Desktop function key bypass (just in case)
#F1::Send {F1}
#F2::Send {F2}
#F3::Send {F3}
#F4::Send {F4}
#+F1::Send +{F1}
#+F2::Send +{F2}
#+F3::Send +{F3}
#+F4::Send +{F4}


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
        ;Case "bash": Run, C:\cygwin\bin\mintty.exe -i /Cygwin-Terminal.ico -
    ;; msys
        ;Case "tmux": Run, C:\msys64\msys2_shell.cmd -msys -use-full-path -c 'tmux new'
        ;Case "bash": Run, C:\msys64\msys2_shell.cmd -msys -use-full-path
        ;Case "reattach": Run, C:\msys64\msys2_shell.cmd -msys -use-full-path -c 'tmux attach'
    ;; wsl (original attempt)
        ; This one was abandoned because of a bug in which launching wsl.exe
        ; this way causes the scrollbar to be drawn over top of the last two
        ; columns. That was back when WCH was the default.
        ;Case "tmux": Run, wsl tmux new, %home%
        ;Case "bash": Run, wsl, %home%
        ;Case "reattach": Run, wsl tmux attach, %home%
    ;; wsl (direct distro launch)
        ; This doesn't seem to suffer from the above noted wsl.exe bug.
        ; But then I discovered Windows Console Host doesn't support OSC 52.
        ; (It *appears* to if you test with local sessions, but go into ssh -
        ; or try writing the actual commands to the terminal - and you quickly
        ; discover it's just a mirage.)
        ; That's not a problem with WT as default, but then doing things this
        ; way gains you no benefit and costs you yet another process. Ugh.
        ;Case "tmux": Run, debian.exe run "tmux new", %home%
        ;Case "bash": Run, debian.exe, %home%
        ;Case "reattach": Run, debian.exe run "tmux attach -c $HOME", %home%
    ;; wsltty
        ; This one keeps getting tried and abandoned for two reasons:
        ; 1) Process overhead: a WSL session requires SEVEN (yes, SEVEN)
        ;    processes - in addition to wsl.exe/wslhost.exe, the terminal, and
        ;    their respective conhost.exe processes, mintty adds wslbridge2.exe
        ;    and a THIRD conhost.exe
        ; 2) Their software distribution scheme is something beyond utterly
        ;    terrible, hopping into installer-managed profile folders without
        ;    actually bothering to be installer-manageable.
        ;Case "tmux": Run, C:\Users\jvc\AppData\Local\wsltty\bin\mintty.exe --WSL="Debian" --configdir="D:\AppData\Roaming\wsltty" "tmux new", %home%
        ;Case "bash": Run, C:\Users\jvc\AppData\Local\wsltty\bin\mintty.exe --WSL="Debian" --configdir="D:\AppData\Roaming\wsltty" -, %home%
        ;Case "reattach": Run, C:\Users\jvc\AppData\Local\wsltty\bin\mintty.exe --WSL="Debian" --configdir="D:\AppData\Roaming\wsltty" "tmux attach", %home%
        ;Case "isactive": Return (WinActive("ahk_class ConsoleWindowClass") || WinActive("ahk_exe mintty.exe"))
    ;; alternate shells fallback
        ; These have generally assumed Windows Console Host as the default
        ; terminal.
        ;Case "pwsh": Run, pwsh.exe, %home%
        ;Case "cmd":Run, cmd.exe, %home%
    ;; alacritty (wsl AND alternate shells)
        ; I keep coming back to this one as a Least Common Acceptable option
        ; despite frustration with the developers, minor (but sometimes
        ; tolerable and/or workaroundable) bugs, and other foibles.
        ;Case "tmux": Run, alacritty -e "wsl tmux new", %home%
        ;Case "bash": Run, alacritty -e "wsl", %home%
        ;Case "reattach": Run, alacritty -e "wsl tmux attach -c $HOME", %home%
        ;Case "pwsh": Run, alacritty -o scrolling.history=50000 -e "pwsh", %home%
        ;Case "cmd": Run, alacritty -o scrolling.history=50000 -e "cmd", %home%
    ;; Windows Terminal Direct
        ; Current choice because it's got the same process overhead as
        ; alacritty but with smaller processes AND I may have it beaten into
        ; shape now. Direct invocation using 'wt' avoids increasing the
        ; process overhead. Requires use of a custom-edited version of my usual
        ; font of choice because #3498.
        ; Default profile is assumed to be the WSL one.
        Case "tmux": Run, wt wsl tmux new, %home%
        Case "bash": Run, wt, %home%
        Case "reattach": Run, wt wsl tmux attach -c $HOME, %home%
        Case "pwsh": Run, wt -p PowerShell, %home%
        Case "cmd": Run, wt -p "Command Prompt", %home%
    ;; Just a simple test to see any of the above terminals are active.
    ;; This does NOT check for which shell is running!
        Case "isactive": Return (WinActive("ahk_class ConsoleWindowClass") || WinActive("ahk_class mintty") || WinActive("ahk_exe alacritty.exe") || WinActive("ahk_exe WindowsTerminal.exe"))
    }
}
F11::terminal_invoke("tmux")
+F11::terminal_invoke("bash")
^+F11::terminal_invoke("reattach")
^F11::terminal_invoke("pwsh")
^#F11::terminal_invoke("cmd")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Other Application Invocation Hotkeys ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
F10::Run "C:\Program Files\Vim\vim90\gvim.exe", %home%
#If Not WinActive("ahk_exe Arcanum.exe")
F9::Run "C:\WINDOWS\system32\calc.exe"
#If


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; "Command Key" And Other MacOSisms ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; These require that UseHook be turned OFF. Otherwise, you'll run into issues
; with command-C, command-A, et cetera.
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

; Alternate screenshot system
!+3::Send #{PrintScreen}
!+4::Send #+s

; Command-N for new window in Explorer
#If WinActive("ahk_class CabinetWClass")
!n::Send #e
#If
; Command-N for new window in terminals
; NOTE: Dependent on my configuration elsewhere that sets window title strings
; based on the current shell. Yay egregious hacks!
#If terminal_invoke("isactive") && WinActive("PS ")
!n::terminal_invoke("pwsh")
#If
#If terminal_invoke("isactive") && WinActive("CMD ")
!n::terminal_invoke("cmd")
#If
#If terminal_invoke("isactive")
!n::terminal_invoke("tmux")
#If
;Command-C/X/V for copy/cut/paste in terminals
#If terminal_invoke("isactive")
!c::Send ^{Insert}
!x::Send ^{Delete}
!v::Send +{Insert}
#If
; Command-R to rename pdf in SumatraPDF
#If WinActive("ahk_exe SumatraPDF.exe")
!r::Send {F2}
#If
; Command/Control-W to close window in PDFXChange
#If WinActive("ahk_exe PDFXEdit.exe")
!w::WinClose, A
^w::WinClose, A
#If


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Window Maximization ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
; The basic concept:
; * Alt-F3 maximizes windows.
; * Alt+Shift+F3 maximizes vertically only.
; * Some app windows (gvim, terminals) default to vertical-only.

; Regular maximizing toggle
; Toggle code from https://superuser.com/a/403017
MaximizeToggle() {
    WinGet MX, MinMax, A
    If MX
        WinRestore A
    Else WinMaximize A
}
; Vertical-only maximizing toggle.
; Previously, I handled this via simulating the necessary mouse clicks, but
; this became a tad error-prone (especially if the mouse was bumped between
; clicks somehow). So now I'm using one based on the keyboard shortcut Windows
; provides. I'd just use it all the time, except it's not a toggle, so...
VMaximizeToggle() {
    ; unlike regular maximizing, no "maximized" state is explicitly set when
    ; doing a vertical-only maximize, so we have to try other means
    WinGetPos ,OX,OY,OW,OH,A
    ;MsgBox, "OX:%OX% OY:%OY% OW:%OW% OH:%OH%"
    Send #+{Up}
    WinGetPos ,NX,NY,NW,NH,A
    ;MsgBox, "NX:%NX% NY:%NY% NW:%NW% NH:%NH%"
    If (OY == OY && OX == NX && OW == NW && OH == NH)
        WinRestore A
}
; Default: Alt-F3 maximizes all, Alt-Shift-F3 does vertical-only.
!F3::MaximizeToggle()
!+F3::VMaximizeToggle()
; Vertical-only maximize windows swap these.
#If WinActive("ahk_exe gvim.exe") || terminal_invoke("isactive")
!F3::VMaximizeToggle()
!+F3::MaximizeToggle()
#If


;;;;;;;;;;;;;;;;;;;;;;;
;;; Everything Else ;;;
;;;;;;;;;;;;;;;;;;;;;;;

; screen turn off
; taken from https://superuser.com/a/485930
#m::
Sleep 1000
SendMessage, 0x112, 0xF170, 2,, Program Manager
return

; Temporary rename key for irfanview
#if WinActive("ahk_exe i_view64.exe")
Ins::Send {F2}
#If
