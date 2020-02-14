# comms_project
E-Week communications project built on Python 2 using the libpruio library.

See requirements.txt for a list of the required libraries. 

This is meant to be run on a BeagleBone SBC.
It samples ~20 seconds of analog data divided into 40 sets. Applies a Kaiser window and computes the FFT of each set, then takes the average of the entire data set. It then plots the frequencies and attempts to identify the peaks and show them on the plot.


Ideas:

- Clean up the code and use better variable names.
- Put repetitive code in functions.
- Better peak finding and plotting.
- Cut off frequencies after 4kHz. (Tried this forever ago but had weird issues with plotting, gave up.)
- Different windowing maybe? Kaiser seemed to work best, but I haven't tried with real data.
