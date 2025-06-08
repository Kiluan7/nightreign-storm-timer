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

; ==== GUI ====
myGui := Gui("+AlwaysOnTop +Resize", "Elden Ring NightReign Countdown")
myGui.BackColor := "0x202020"
myGui.SetFont("s16", "Segoe UI")

PhaseText := myGui.Add("Text", "Center cGray w300 h30", phases[PhaseIndex].name)
myGui.SetFont("s32", "Segoe UI")
TimerText := myGui.Add("Text", "Center cWhite w300 h60", FormatTime(Countdown))

myGui.SetFont("s14", "Segoe UI")
myGui.Add("Text", "x10 y+10 cGray", "Segments:")

segmentControls := []
Loop phases.Length {
    label := phases[A_Index].name
    time := phases[A_Index].time > 0 ? FormatTime(phases[A_Index].time) : ""

    ctrlLabel := myGui.Add("Text", "x10 y+0 w220 h25 cWhite", label)
    ctrlTime := myGui.Add("Text", "x+10 yp w60 h25 cWhite Right", time)

    segmentControls.Push({ label: ctrlLabel, time: ctrlTime })
}

; ==== HOTKEYS ====
F1::StartOrContinueFromBoss()
F2::ResetTimer()
F3::TogglePause()
F4::ExitAppHandler()
F5::ToggleClickThrough()

; ==== FUNCTIONS ====

StartOrContinueFromBoss() {
    global Running, Paused, PhaseIndex, Countdown, GuiInitialized, phases
    if !Running && phases[PhaseIndex].time = 0 {
        ; Was at a boss phase — advance manually
        PhaseIndex++
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
        PhaseIndex := 1
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
    UpdateGuiText()

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

UpdateGuiText() {
    global Countdown, TimerText, PhaseText, PhaseIndex, phases, segmentControls
    TimerText.Text := FormatTime(Countdown)
    PhaseText.Text := phases[PhaseIndex].name

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

ToggleClickThrough() {
    global ClickThroughEnabled, myGui
    ClickThroughEnabled := !ClickThroughEnabled
    SetClickThrough(myGui.Hwnd, ClickThroughEnabled)
}

FormatTime(t) {
    return Format("{:02}:{:02}", Floor(t / 60), Mod(t, 60))
}

; ==== AUTO SHOW ON LAUNCH ====
myGui.Show()
GuiInitialized := true
UpdateGuiText()
; ==== DARK TITLEBAR ENABLE ====
EnableDarkMode(hwnd) {
    DWMWA_USE_IMMERSIVE_DARK_MODE := 20  ; 20 for newer Windows-Versions, 19 for older ones
    DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", DWMWA_USE_IMMERSIVE_DARK_MODE, "int*", 1, "int", 4)
}
EnableDarkMode(myGui.Hwnd)