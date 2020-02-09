Sample frequency = 142857.142857 Hz
Tone #1 = 954Hz
Tone #2 = 3064Hz
SNR should be 0dB with full spectrum white noise. But it was generated with a phone app so who really knows.

raw_data.txt contains 40 sets of 55000 samples each.

data.txt should contain the identical data, but does not. Not sure why, I must have messed something up while saving it.

I expect data.txt is the real one and raw_data.txt is garbage. But right now that's just a guess.

This data does contain some non-continuous sections where the signal passed below 0V. This is an artifact of my setup. The real circuit should keep the waveform centered at 0.9V.
