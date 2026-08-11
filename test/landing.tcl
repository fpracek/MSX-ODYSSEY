# Test dell'approdo: forzando la rotta a 24, la nave deve entrare
# in cinematica (mode=3), accostare verso l'isola e rimpicciolire
# (ship_y scende sotto 75 -> sagoma lontana). Screenshot a meta'.
# Esito in build/landing_result.txt.

proc report {msg} {
    set fh [open "build/landing_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/landing_result.txt"}
# FIRE sul titolo, poi si salpa dalla pergamena (SPACE)
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }

after time 8 {
    if {[catch {
        debug write memory 0xC02F 24
        report "rotta forzata a 24: deve cominciare l'approdo"
    } err]} { report "ERRORE: $err"; exit }
    after time 3 {
        if {[catch {
            set md [debug read memory 0xC020]
            set sy [debug read memory 0xC03D]
            if {$md == 3} {
                report [format "approdo: IN CORSO (mode=3, ship_y=%d)" $sy]
            } else {
                report [format "approdo: mode=%d ship_y=%d" $md $sy]
            }
        } err]} { report "ERRORE: $err"; exit }
        after time 2 {
            if {[catch {
                set sy [debug read memory 0xC03D]
                if {$sy < 75} {
                    report [format "sagoma lontana: OK (ship_y=%d < 75)" $sy]
                } else {
                    report [format "sagoma lontana: non ancora (ship_y=%d)" $sy]
                }
                screenshot -raw ./build/shot_landing.png
                report "screenshot: build/shot_landing.png"
            } err]} { report "ERRORE: $err" }
            exit
        }
    }
}
