# Boot test: verifica il self-test del mapper ASCII8 (banktest_ok a
# 0xC000: 0xAA = ok, 0x55 = fallito) e scatta uno screenshot del mare.
# L'esito va in build/boot_result.txt (lo stdout di openmsx.exe su
# Windows non raggiunge la console).

proc report {msg} {
    set fh [open "build/boot_result.txt" a]
    puts $fh $msg
    close $fh
}

catch {file delete "build/boot_result.txt"}
# FIRE sul titolo, poi si salpa dalla pergamena (SPACE)
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }


after time 8 {
    if {[catch {
        set bt [debug read memory 0xC000]
        if {$bt == 0xAA} {
            report "banktest: OK (0xAA)"
        } else {
            report [format "banktest: FALLITO (0x%02X)" $bt]
        }
        set ::f1 [debug read memory 0xC001]
        set ::p1 [list [debug read "PSG regs" 9] [debug read "PSG regs" 10]]
    } err]} {
        report "ERRORE: $err"
        exit
    }
    after time 1 {
        if {[catch {
            set f2 [debug read memory 0xC001]
            if {$f2 != $::f1} {
                report "frame hook: attivo (frame_cnt avanza)"
            } else {
                report "frame hook: FERMO (frame_cnt non avanza)"
            }
            set p2 [list [debug read "PSG regs" 9] [debug read "PSG regs" 10]]
            if {$p2 != $::p1} {
                report "risacca PSG: attiva (volumi B/C $::p1 -> $p2)"
            } else {
                report "risacca PSG: FERMA (volumi B/C invariati: $p2)"
            }
            screenshot -raw ./build/shot.png
            report "screenshot: build/shot.png"
        } err]} {
            report "ERRORE: $err"
        }
        exit
    }
}
