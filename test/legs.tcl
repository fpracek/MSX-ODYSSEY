# Test delle tratte: si parte verso i Ciclopi (leg 0, 0xC040);
# forzando l'arrivo (prog_h 0xC02F = 24) la sequenza di vittoria
# deve far ripartire il viaggio verso Circe (leg 1) col nuovo nome
# nel cielo. Esito in build/legs_result.txt.

proc report {msg} {
    set fh [open "build/legs_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/legs_result.txt"}
# FIRE sul titolo, poi si salpa dalla pergamena (SPACE)
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }
# ... e dalla seconda pergamena, dopo la sequenza di vittoria
after time 17 { keymatrixdown 8 1 }
after time 18 { keymatrixup 8 1 }


after time 8 {
    if {[catch {
        set l0 [debug read memory 0xC040]
        if {$l0 == 0} {
            report "tratta iniziale: OK (leg=0, verso i Ciclopi)"
        } else {
            report [format "tratta iniziale: leg=%d (atteso 0)" $l0]
        }
        screenshot -raw ./build/shot_leg0.png
        debug write memory 0xC02F 24
        report "arrivo forzato: sequenza di vittoria..."
    } err]} { report "ERRORE: $err"; exit }
    after time 12 {
        if {[catch {
            set l1 [debug read memory 0xC040]
            set md [debug read memory 0xC020]
            if {$l1 == 1 && $md == 0} {
                report "tratta successiva: OK (leg=1, verso Circe, in gioco)"
            } else {
                report [format "tratta successiva: leg=%d mode=%d (attesi 1,0)" $l1 $md]
            }
            screenshot -raw ./build/shot_leg1.png
            report "screenshot: build/shot_leg0.png / shot_leg1.png"
        } err]} { report "ERRORE: $err" }
        exit
    }
}
