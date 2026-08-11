# Cattura ~18s di tempesta (tuoni con ducking) in build/storm_audio.wav
after time 4 { keymatrixdown 8 1 }
after time 5 { keymatrixup 8 1 }
after time 6 { keymatrixdown 8 1 }
after time 7 { keymatrixup 8 1 }
after time 19 {
    catch {record start build/storm_audio -audioonly}
    after time 18 {
        catch {record stop}
        exit
    }
}
