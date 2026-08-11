# Test del bel tempo: scoglio emergente, Itaca all'orizzonte, gabbiano.
# - a t=12s almeno uno scoglio deve essere spawnato (rock_cnt 0xC03B)
# - forzando prog_h (0xC02F) a 21 l'isola deve apparire (island_flag
#   0xC03A = 2) e oltre meta' rotta deve volare il gabbiano (gull_t
#   0xC037 > 0 in almeno uno dei due campioni)
# Esito in build/calm_result.txt.

proc report {msg} {
    set fh [open "build/calm_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/calm_result.txt"}
# FIRE sul titolo, poi si salpa dalla pergamena (SPACE)
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }


after time 12 {
    if {[catch {
        set rocks [debug read memory 0xC03B]
        if {$rocks > 0} {
            report [format "scogli: OK (%d spawnati)" $rocks]
        } else {
            report "scogli: NESSUNO a t=12s (atteso >0)"
        }
        debug write memory 0xC02F 21
        report "rotta forzata a 21/24: Itaca deve apparire"
    } err]} { report "ERRORE: $err"; exit }
    after time 3 {
        if {[catch {
            set isl [debug read memory 0xC03A]
            if {$isl == 2} {
                report "isola: OK (disegnata all'orizzonte)"
            } else {
                report [format "isola: NON disegnata (flag=%d)" $isl]
            }
            set ::g1 [debug read memory 0xC037]
            screenshot -raw ./build/shot_calm.png
            report "screenshot: build/shot_calm.png"
        } err]} { report "ERRORE: $err"; exit }
        after time 2 {
            if {[catch {
                set g2 [debug read memory 0xC037]
                if {$::g1 > 0 || $g2 > 0} {
                    report [format "gabbiano: OK (in volo: %d/%d)" $::g1 $g2]
                } else {
                    report "gabbiano: non visto nei 2 campioni"
                }
            } err]} { report "ERRORE: $err" }
            exit
        }
    }
}
