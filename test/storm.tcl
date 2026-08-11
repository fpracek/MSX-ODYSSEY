# Test tempesta + fulmini + sfida.
# A 50Hz (C-BIOS EU) il sereno dura 600 frame = 12s: a ~15s dal boot
# la tempesta deve essere attiva (weather=1, 0xC021), poi entro
# qualche secondo devono essere caduti fulmini (bolt_cnt>0, 0xC033).
# Screenshot durante la tempesta. Esito in build/storm_result.txt.

proc report {msg} {
    set fh [open "build/storm_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/storm_result.txt"}
# FIRE sul titolo, poi si salpa dalla pergamena (SPACE)
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }


after time 21 {
    if {[catch {
        set w [debug read memory 0xC021]
        if {$w == 1} {
            report "tempesta: ATTIVA a t=21s"
        } else {
            report [format "tempesta: NON ancora attiva (weather=%d)" $w]
        }
    } err]} { report "ERRORE: $err"; exit }
    after time 8 {
        if {[catch {
            set bolts [debug read memory 0xC033]
            set crew  [debug read memory 0xC02B]
            set prog  [debug read memory 0xC02F]
            if {$bolts > 0} {
                report [format "fulmini: OK (%d caduti)" $bolts]
            } else {
                report "fulmini: NESSUNO (atteso >0)"
            }
            report [format "ciurma: %d/12   rotta: %d/24" $crew $prog]
            screenshot -raw ./build/shot_storm.png
            report "screenshot: build/shot_storm.png"
        } err]} { report "ERRORE: $err" }
        exit
    }
}
