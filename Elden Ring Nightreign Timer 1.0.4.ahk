#Requires AutoHotkey v2.0
Persistent
;Credits Kiluan, Khoraxx (Contact on Discord for issues/bugs)
; ==== PHASE DATA ====
phases := [
    { name: "Day 1 Storm", time: 270 },
    { name: "Day 1 Storm Shrinking", time: 180 },
    { name: "Day 1 Storm 2", time: 210 },
    { name: "Day 1 Storm 2 Shrinking", time: 180 },
    { name: "Boss Fight", time: 0 },
    { name: "Day 2 Storm", time: 270 },
    { name: "Day 2 Storm Shrinking", time: 180 },
    { name: "Day 2 Storm 2", time: 210 },
    { name: "Day 2 Storm 2 Shrinking", time: 180 },
    { name: "Final Boss", time: 0 }
]

; ==== STATE ====
PhaseIndex := 1
Countdown := phases[PhaseIndex].time
Paused := false
Running := false 
GuiInitialized := false
ClickThroughEnabled := false

; ==== HOTKEYS ====
F1::StartOrContinueFromBoss()
F2::ResetTimer()
F3::TogglePause()
F4::ExitAppHandler()
F5::ToggleOverlay()
F6::ToggleWindowSizeMode()

F7::NextPhase()
F8::PreviousPhase()
NumpadAdd::NextPhase()
NumpadSub::PreviousPhase()

; ==== TIMER WARNING ====
TimerWarning := {
    runningOutSeconds: 30,
    runningOutColor: "c0xff9100",
    hurryUpSeconds: 10,
    hurryUpColor: "c0xf31b1b",
}

; ==== TIMER ANIMATION ====
TimerAnimationProps := { 
    enabled: false,
    defaultSize: 32,
    maxSize: 38,
    step: 1,
    currentSize: 32,
    interval: 50,
    growing: true
}
; ==== GUI ====
TransparentColor := "0x010101"
DefaultColor := "0x202020"
CurrentBackground := "Background" DefaultColor
myGui := Gui("+AlwaysOnTop -Resize +ToolWindow +LastFound", "Elden Ring NightReign Countdown")
myGui.BackColor := DefaultColor
myGui.SetFont("s16", "Segoe UI")
PhaseText := myGui.Add("Text", "Center x10 cGray w290 h30 " CurrentBackground, phases[PhaseIndex].name)

myGui.SetFont("s32", "Segoe UI")
TimerText := myGui.Add("Text", "Center x10 cWhite w290 h60 " CurrentBackground, FormatTime(Countdown))

myGui.SetFont("s14", "Segoe UI")
myGui.Add("Text", "x10 y+10 cGray " CurrentBackground, "Phases:")

segmentControls := []
Loop phases.Length {
    label := phases[A_Index].name
    time := phases[A_Index].time > 0 ? FormatTime(phases[A_Index].time) : ""

    ctrlLabel := myGui.Add("Text", "x10 y+0 w220 h25 cWhite " CurrentBackground, label)
    ctrlTime := myGui.Add("Text", "x+10 yp w60 h25 cWhite Right " CurrentBackground, time)

    segmentControls.Push({ label: ctrlLabel, time: ctrlTime })
}

; ==== GUI FUNCTIONS ====
GuiCloseHandler(gui) {
    ExitAppHandler()
}

ToggleOverlay() {
    global WindowIsOverlay
    WindowIsOverlay := !WindowIsOverlay
    global ClickThroughEnabled, myGui
    ClickThroughEnabled := !ClickThroughEnabled
    SetClickThrough(myGui.Hwnd, ClickThroughEnabled)
    FixGuiOffset(WindowIsOverlay ? SetOverlayStyle : SetNormalStyle)

    ApplyWindowLayout()
}

SetOverlayStyle() {
    global myGui, TransparentColor, CurrentBackground
    myGui.Opt("-Caption")
    myGui.BackColor := TransparentColor
    WinSetTransColor(TransparentColor, myGui.Hwnd)
    CurrentBackground := "Background" TransparentColor
    UpdateControlBackgrounds(CurrentBackground)
}

SetNormalStyle() {
    global myGui, DefaultColor, CurrentBackground
    myGui.Opt("+Caption")
    myGui.BackColor := DefaultColor
    WinSetTransColor("Off", myGui.Hwnd)
    CurrentBackground := "Background" DefaultColor
    UpdateControlBackgrounds(CurrentBackground)
}

FixGuiOffset(styleCallback) {
    myGui.GetClientPos(&clientX_old, &clientY_old, &_, &_)

    styleCallback.Call()

    myGui.GetPos(&winX_new, &winY_new, &_, &_)
    myGui.GetClientPos(&clientX_new, &clientY_new, &_, &_)

    deltaClientX := clientX_old - clientX_new
    deltaClientY := clientY_old - clientY_new

    newX := winX_new + deltaClientX
    newY := winY_new + deltaClientY

    myGui.Move(newX, newY)
}

ToggleWindowSizeMode() {
    global WindowCompactMode
    WindowCompactMode := !WindowCompactMode
    ApplyWindowLayout()
}

ApplyWindowLayout() {
    borderWidth := WindowIsOverlay ? 0 : WindowBorderWidth
    borderHeight := WindowIsOverlay ? 0 : WindowBorderHeight

    width := WindowDefaultWidth + borderWidth
    height := WindowCompactMode ? WindowCompactHeight : WindowDefaultHeight
    height += borderHeight

    WinGetPos(&x, &y, &_, &_, myGui.Hwnd)
    WinMove(x, y, width, height, myGui.Hwnd)
}

EnableDarkMode(hwnd) {
    DWMWA_USE_IMMERSIVE_DARK_MODE := 20  ; 20 for newer Windows-Versions, 19 for older ones
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", DWMWA_USE_IMMERSIVE_DARK_MODE, "int*", 1, "int", 4)
}
EnableDarkMode(myGui.Hwnd)

; ==== GUI MODES ====
WindowIsOverlay := false
WindowCompactMode := false
WindowDefaultWidth := 310
WindowCompactHeight := 124
WindowDefaultHeight := 0 ; UPDATE AFTER WINDOW SHOW
WindowBorderWidth := 0
WindowBorderHeight := 0

; ==== GUI EVENTS ====
myGui.OnEvent("Close", GuiCloseHandler)

; ==== GUI OTHER ====
; AUTO SHOW ON LAUNCH
myGui.Show(Format("w{}", WindowDefaultWidth))

; WINDOW LAYOUT VALUES
myGui.GetPos(&_, &_, &pos_w, &pos_h)
myGui.GetClientPos(&_, &_, &client_w, &client_h)
WindowBorderWidth := pos_w - client_w
WindowBorderHeight := pos_h - client_h
WindowDefaultHeight := client_h

; APPLY CURRENT LAYOUT
ApplyWindowLayout()

; START APP
GuiInitialized := true
UpdateGuiText()

; ==== FUNCTIONS ====
UpdateControlBackgrounds(newBg) {
    global PhaseText, TimerText, segmentControls, myGui
    PhaseText.Opt(newBg)
    TimerText.Opt(newBg)
    for ctrl in segmentControls {
        ctrl.label.Opt(newBg)
        ctrl.time.Opt(newBg)
    }
    ; Update the "Phases:" label as well
    for ctrl in myGui {
        if ctrl.Type = "Text" && ctrl.Text = "Phases:"
            ctrl.Opt(newBg)
    }
}
SetClickThrough(hwnd, enable) {
    static WS_EX_LAYERED := 0x80000
    static WS_EX_TRANSPARENT := 0x20

    exStyle := DllCall("GetWindowLong", "Ptr", hwnd, "Int", -20, "Int")
    if enable {
        newStyle := exStyle | WS_EX_LAYERED | WS_EX_TRANSPARENT
    } else {
        newStyle := exStyle & ~WS_EX_TRANSPARENT  ; remove transparent bit
    }
    DllCall("SetWindowLong", "Ptr", hwnd, "Int", -20, "Int", newStyle)
}

NextPhase() {
    global PhaseIndex, Running, Paused, Countdown
    if PhaseIndex < phases.Length {
        PhaseIndex++
        Running := false
        Paused := false
        SetTimer(UpdateTimer, 0) ; Para o timer se estiver rodando
        Countdown := phases[PhaseIndex].time
        UpdateGuiText()
    }
}

PreviousPhase() {
    global PhaseIndex, Running, Paused, Countdown
    if PhaseIndex > 1 {
        PhaseIndex--
        Running := false
        Paused := false
        SetTimer(UpdateTimer, 0) ; Para o timer se estiver rodando
        Countdown := phases[PhaseIndex].time
        UpdateGuiText()
    }
}

StartOrContinueFromBoss() {
    global Running, Paused, PhaseIndex, Countdown, GuiInitialized, phases
    if !Running && phases[PhaseIndex].time = 0 {
        ; Was at a boss phase — advance manually
        PhaseIndex++
        
        if PhaseIndex > phases.Length {
            PhaseIndex := 1
        }

        if PhaseIndex <= phases.Length {
            SoundBeep
            Countdown := phases[PhaseIndex].time
            Paused := false
            Running := true
            UpdateGuiText()
            SetTimer(UpdateTimer, 1000)
        }
    } else if !Running {
        ; First ever start
        SoundBeep
        if PhaseIndex < 1 || PhaseIndex > phases.Length {
            PhaseIndex := 1
        }
        Countdown := phases[PhaseIndex].time
        Paused := false
        Running := true

        UpdateGuiText()
        SetTimer(UpdateTimer, 1000)
    }
}

ResetTimer() {
    global Running, Paused, Countdown, PhaseIndex, phases
    SetTimer(UpdateTimer, 0)
    PhaseIndex := 1
    Countdown := phases[PhaseIndex].time
    Paused := false
    Running := false
    UpdateGuiText()
}

TogglePause() {
    global Paused
    if Running
        Paused := !Paused
}

ExitAppHandler() {
    SetTimer(UpdateTimer, 0)
    myGui.Destroy()
    ExitApp()
}

UpdateTimer() {
    global Countdown, PhaseIndex, Paused, Running, phases

    if Paused
        return

    Countdown--
    UpdateTimerGuiText()

    if Countdown <= 0 {
        SoundBeep(300, 200)

        ; If next phase is a boss → pause and wait for F1 manually
        if PhaseIndex + 1 <= phases.Length && phases[PhaseIndex + 1].time = 0 {
            PhaseIndex++
            Countdown := 0
            UpdateGuiText()
            SetTimer(UpdateTimer, 0)
            Running := false
            return
        }

        ; Otherwise, continue automatically
        PhaseIndex++
        if PhaseIndex <= phases.Length {
            Countdown := phases[PhaseIndex].time
            UpdateGuiText()
        } else {
            SetTimer(UpdateTimer, 0)
            Running := false
        }
    }
}

UpdateTimerGuiText() {
    global Countdown, TimerText, PhaseIndex, phases
    TimerText.Text := FormatTime(Countdown)
    TimerText.SetFont("norm")
    TimerText.Opt("cWhite")
    
    if phases[PhaseIndex].time > 0 && Countdown <= 30 {
        TimerText.SetFont("bold")

        if Countdown <= TimerWarning.runningOutSeconds {
            TimerText.Opt(TimerWarning.runningOutColor)
        }
        
        if Countdown <= TimerWarning.hurryUpSeconds {
            TimerText.Opt(TimerWarning.hurryUpColor)
            if TimerAnimationProps.enabled
                SetTimer(TimerAnimation, 50)
        }
    } else {
        if TimerAnimationProps.enabled
            StopTimerAnimation()
    }
}

UpdateGuiText() {
    global Countdown, TimerText, PhaseText, PhaseIndex, phases, segmentControls
    PhaseText.Text := phases[PhaseIndex].name
    
    UpdateTimerGuiText()

    Loop segmentControls.Length {
        segmentControls[A_Index].label.SetFont("norm")
        segmentControls[A_Index].time.SetFont("norm")
        segmentControls[A_Index].label.Opt("cWhite")
        segmentControls[A_Index].time.Opt("cWhite")
    }
    if PhaseIndex <= segmentControls.Length {
        segmentControls[PhaseIndex].label.SetFont("bold")
        segmentControls[PhaseIndex].time.SetFont("bold")
        segmentControls[PhaseIndex].label.Opt("cYellow")
        segmentControls[PhaseIndex].time.Opt("cYellow")
    }
}

FormatTime(t) {
    return Format("{:02}:{:02}", Floor(t / 60), Mod(t, 60))
}

StopTimerAnimation() {
    TimerText.SetFont("s" TimerAnimationProps.defaultSize, "Segoe UI")
    SetTimer(TimerAnimation, 0)
}

TimerAnimation() {
    global TimerAnimationProps, TimerText

    if (TimerAnimationProps.growing) {
        TimerAnimationProps.currentSize += TimerAnimationProps.step
        if (TimerAnimationProps.currentSize >= TimerAnimationProps.maxSize)
            TimerAnimationProps.growing := false
    } else {
        TimerAnimationProps.currentSize -= TimerAnimationProps.step
        if (TimerAnimationProps.currentSize <= TimerAnimationProps.defaultSize)
            TimerAnimationProps.growing := true
    }

    TimerText.SetFont("s" TimerAnimationProps.currentSize, "Segoe UI")
}
