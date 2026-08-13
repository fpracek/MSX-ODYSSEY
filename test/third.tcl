# Test della TERZA stanza (l'antro dell'accecamento): GOTO1, poi
# teletrasporti sulle uscite per attraversare spiaggia e caverna,
# raccolta del PALO sulla piattaforma, STOCCATA dal sopracciglio
# (ciclope addormentato), verifica furia + uscita illuminata, e
# fuga dalla bocca della caverna = VITTORIA (leg 0 -> 1).
# Esito in build/third_result.txt.

proc report {msg} {
    set fh [open "build/third_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/third_result.txt"}

proc tap {row mask t} {
    after time $t "keymatrixdown $row $mask"
    after time [expr {$t + 0.4}] "keymatrixup $row $mask"
}
# G O T O 1 sul titolo
tap 3 16 4.0
tap 4 16 4.8
tap 5 2  5.6
tap 4 16 6.4
tap 0 2  7.2

# stanza 0 (spiaggia): dritti sull'uscita E (r6 c25)
after time 10 {
    debug write memory 0xC052 196
    debug write memory 0xC054 40
}
# stanza 1 (caverna): uscita E (r6 c29)
after time 11 {
    debug write memory 0xC052 228
    debug write memory 0xC054 40
}
# stanza 2: verifica palo presente, spegni il pipistrello
after time 12 {
    if {[catch {
        set rm [debug read memory 0xC050]
        set stk [debug read memory 0xC292]
        if {$rm == 2 && $stk == 10} {
            report "antro: OK (stanza 2, il palo e' al suo posto)"
        } else {
            report [format "antro: room=%d stake_tile=%d (attesi 2,10)" $rm $stk]
        }
        debug write memory 0xC06E 0
    } err]} { report "ERRORE t12: $err" }
}
# sulla piattaforma del palo (r14): raccolta automatica
after time 12.5 {
    debug write memory 0xC058 0
    debug write memory 0xC059 0
    debug write memory 0xC052 136
    debug write memory 0xC054 88
}
after time 13.5 {
    if {[catch {
        set st [debug read memory 0xC076]
        set cell [debug read memory 0xC292]
        set plat [debug read memory 0xC2D2]
        if {$st == 1 && $cell == 0 && $plat == 3} {
            report "palo: RACCOLTO (celle pulite, piattaforma intatta)"
        } else {
            report [format "palo: stake=%d cell=%d plat=%d (attesi 1,0,3)" $st $cell $plat]
        }
    } err]} { report "ERRORE t13.5: $err" }
}
# sul sopracciglio, ciclope addormentato: la STOCCATA
after time 14 {
    debug write memory 0xC058 0
    debug write memory 0xC059 0
    debug write memory 0xC055 0
    debug write memory 0xC056 0
    debug write memory 0xC052 48
    debug write memory 0xC054 40
}
after time 15 {
    if {[catch {
        set bl [debug read memory 0xC077]
        set cy [debug read memory 0xC059]
        set door [debug read memory 0xC33D]
        if {$bl == 1 && $cy == 2 && $door == 7} {
            report "stoccata: ACCECATO (furia attiva, uscita accesa)"
        } else {
            report [format "stoccata: blind=%d cyc=%d door=%d (attesi 1,2,7)" $bl $cy $door]
        }
        screenshot -raw ./build/shot_third.png
    } err]} { report "ERRORE t15: $err" }
}
# la fuga: sull'uscita illuminata (r17 c29)
after time 15.5 {
    debug write memory 0xC05E 200
    debug write memory 0xC052 228
    debug write memory 0xC054 128
}
after time 19 {
    if {[catch {
        set ph [debug read memory 0xC04F]
        set lg [debug read memory 0xC040]
        if {$ph == 0 && $lg == 1} {
            report "fuga: VITTORIA (phase=0, rotta verso Circe: leg 1)"
        } else {
            report [format "fuga: phase=%d leg=%d (attesi 0,1)" $ph $lg]
        }
    } err]} { report "ERRORE t19: $err" }
    exit
}
