# Test vento di Eolo + timone.
# 1) senza input la nave deve andare in deriva col vento (x cresce
#    dal punto di partenza 84, fino al clamp 208)
# 2) tenendo LEFT (matrice riga 8, bit 4) il timone deve vincere il
#    vento e riportare la nave indietro
# Esito in build/wind_result.txt. ship_xh = 0xC01D.

proc report {msg} {
    set fh [open "build/wind_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/wind_result.txt"}
# FIRE sul titolo, poi si salpa dalla pergamena (SPACE)
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }


after time 10 {
    if {[catch {
        set ::x1 [debug read memory 0xC01D]
        if {$::x1 > 90} {
            report [format "deriva col vento: OK (x 84 -> %d)" $::x1]
        } else {
            report [format "deriva col vento: SOSPETTA (x=%d, atteso >90)" $::x1]
        }
        keymatrixdown 8 16
        report "timone: LEFT premuto"
    } err]} { report "ERRORE: $err"; exit }
    after time 3 {
        if {[catch {
            set x2 [debug read memory 0xC01D]
            keymatrixup 8 16
            if {$x2 < $::x1} {
                report [format "timone contro vento: OK (x %d -> %d)" $::x1 $x2]
            } else {
                report [format "timone contro vento: FALLITO (x %d -> %d)" $::x1 $x2]
            }
            screenshot -raw ./build/shot_wind.png
            report "screenshot: build/shot_wind.png"
        } err]} { report "ERRORE: $err" }
        exit
    }
}
