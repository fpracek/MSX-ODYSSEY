# Diagnostica del salto: campiona yh/vy/ong/jlatch durante SPACE.
proc report {msg} {
    set fh [open "build/jdiag_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/jdiag_result.txt"}
proc tap {row mask t} {
    after time $t "keymatrixdown $row $mask"
    after time [expr {$t + 0.4}] "keymatrixup $row $mask"
}
tap 3 16 4.0
tap 4 16 4.8
tap 5 2  5.6
tap 4 16 6.4
tap 0 2  7.2

proc snap {tag} {
    set y [debug read memory 0xC054]
    set vh [debug read memory 0xC056]
    set og [debug read memory 0xC057]
    set jl [debug read memory 0xC061]
    report [format "%s yh=%d vyh=%d ong=%d jlatch=%d" $tag $y $vh $og $jl]
}
after time 11 { snap "prima " }
after time 12 { keymatrixdown 8 1 }
after time 12.2 { snap "space+" }
after time 12.4 { snap "space+" }
after time 12.8 { snap "space+" }
after time 13 { keymatrixup 8 1 }
after time 13.5 { snap "dopo  "; exit }
