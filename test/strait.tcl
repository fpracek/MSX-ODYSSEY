# Test della ROTTA FINALE in tre atti (tratta 4): (1) si salpa
# in mare aperto con la scritta TO ITHACA e str_act=0; (2) al
# progresso centrale entra LO STRETTO: insegna SCYLLA AND
# CHARYBDIS nel cielo (slot extra 16+), Scilla erutta mirata,
# Cariddi risucchia e morde; (3) usciti dallo stretto la scritta
# torna TO ITHACA; (4) l'arrivo porta DIRITTI a Itaca (phase 5).
# Esito in build/strait_result.txt.

proc report {msg} {
    set fh [open "build/strait_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/strait_result.txt"}

after time 3 { debug write memory 0xC040 4 }
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }

# atto 1: mare aperto, niente stretto, slot extra dei glifi vuoti
after time 8 {
    if {[catch {
        set act [debug read memory 0xC094]
        set t16 [debug read VRAM 0x80]
        if {$act == 0 && $t16 == 0} {
            report "atto 1: OK (mare aperto, scritta TO ITHACA)"
        } else {
            report [format "atto 1: str_act=%d tile16=%d (attesi 0,0)" $act $t16]
        }
        debug write memory 0xC02F 8
    } err]} { report "ERRORE t8: $err" }
}
# atto 2 innescato: insegna dello stretto caricata dall'ISR
after time 9.5 {
    if {[catch {
        set act [debug read memory 0xC094]
        set t16 [debug read VRAM 0x80]
        if {$act == 1 && $t16 != 0} {
            report [format "atto 2: LO STRETTO (insegna nel cielo, tile16=%d)" $t16]
        } else {
            report [format "atto 2: str_act=%d tile16=%d (attesi 1,!=0)" $act $t16]
        }
    } err]} { report "ERRORE t9.5: $err" }
}
# la prima quiete dura 90f: Scilla erutta mirata sulla nave
after time 10.6 {
    if {[catch {
        set st [debug read memory 0xC090]
        set rt [debug read memory 0xC034]
        set rx [debug read memory 0xC036]
        set sx [debug read memory 0xC01D]
        if {$st == 1 && $rt > 0} {
            report [format "Scilla: ERUTTA mirata (mostro a x=%d, nave a x=%d)" $rx $sx]
        } else {
            report [format "Scilla: st=%d rock_t=%d (attesi 1,>0)" $st $rt]
        }
    } err]} { report "ERRORE t10.6: $err" }
}
# CARIDDI forzata: gorgo a sinistra, risucchio lungo
after time 11 {
    if {[catch {
        debug write memory 0xC034 0
        debug write memory 0xC092 40
        debug write memory 0xC090 3
        debug write memory 0xC091 250
        set ::x0 [debug read memory 0xC01D]
    } err]} { report "ERRORE t11: $err" }
}
after time 12 {
    if {[catch {
        set x1 [debug read memory 0xC01D]
        if {$x1 < $::x0 - 20} {
            report [format "Cariddi: RISUCCHIA (nave x %d -> %d)" $::x0 $x1]
        } else {
            report [format "Cariddi: x %d -> %d (atteso -20+)" $::x0 $x1]
        }
        screenshot -raw ./build/shot_strait.png
    } err]} { report "ERRORE t12: $err" }
}
# il gorgo ha morso e sputato; poi si esce dallo stretto
after time 13 {
    if {[catch {
        set cr [debug read memory 0xC02B]
        set x2 [debug read memory 0xC01D]
        if {$cr < 12 && $x2 > 64} {
            report [format "gorgo: MORDE E SPUTA (ciurma %d, a x=%d)" $cr $x2]
        } else {
            report [format "gorgo: ciurma=%d x=%d (attesi <12, >64)" $cr $x2]
        }
        debug write memory 0xC02F 16
    } err]} { report "ERRORE t13: $err" }
}
# atto 3: lo stretto e' alle spalle, la scritta torna TO ITHACA
after time 14.2 {
    if {[catch {
        set act [debug read memory 0xC094]
        set st  [debug read memory 0xC090]
        set t16 [debug read VRAM 0x80]
        if {$act == 2 && $st == 0 && $t16 == 0} {
            report "atto 3: OK (gorgo chiuso, scritta TO ITHACA)"
        } else {
            report [format "atto 3: str_act=%d str_st=%d tile16=%d (attesi 2,0,0)" $act $st $t16]
        }
        debug write memory 0xC02F 60
    } err]} { report "ERRORE t14.2: $err" }
}
# l'approdo e' una cinematica lenta: si arriva DIRITTI a Itaca
after time 25 {
    if {[catch {
        set lg [debug read memory 0xC040]
        set ph [debug read memory 0xC04F]
        set rm [debug read memory 0xC050]
        if {$lg == 4 && $ph == 5 && $rm == 0} {
            report "approdo: ITACA (nessun altro mare in mezzo)"
        } else {
            report [format "approdo: leg=%d phase=%d room=%d (attesi 4,5,0)" $lg $ph $rm]
        }
    } err]} { report "ERRORE t25: $err" }
    exit
}
