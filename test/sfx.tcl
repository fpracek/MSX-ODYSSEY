# Diagnostica audio: durante la tempesta campiona (thunder_t, R6, R8)
# ogni 0.1s per 8s. Il tuono deve avere R6=28 (sfx_per), non 12.
proc report {msg} {
    set fh [open "build/sfx_result.txt" a]
    puts $fh $msg
    close $fh
}
catch {file delete "build/sfx_result.txt"}
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }

set ::n 0
proc sample {} {
    set t [debug read memory 0xC02A]
    set p [debug read memory 0xC03C]
    set r6 [debug read "PSG regs" 6]
    set r8 [debug read "PSG regs" 8]
    if {$t > 0} {
        report [format "thunder_t=%-3d sfx_per=%-3d R6=%-3d R8=%-2d" $t $p $r6 $r8]
    }
    incr ::n
    if {$::n < 80} {
        after time 0.1 sample
    } else {
        report "fine campionamento"
        exit
    }
}
after time 21 sample
