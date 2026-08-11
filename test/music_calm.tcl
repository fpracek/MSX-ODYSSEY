# Cattura ~14s di sereno (ribollio + splash dello scoglio) in
# build/calm_audio.wav
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }
after time 9 {
    catch {record start build/calm_audio -audioonly}
    after time 14 {
        catch {record stop}
        exit
    }
}
