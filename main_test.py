#!/usr/bin/env python

from libpruio import *
import numpy as np
import matplotlib.pyplot as plt
from scipy.fftpack import fft, fftfreq
import time
import peakutils
from peakutils.plot import plot as pplot
from scipy import signal

print
print("Setting up...")
print
time.sleep(1)

## Set up some variables
tSamp = 55000									#total number of samples (at least 20 full periods)
SampRat = 7000									#sampling rate in ns (20,000ns = 50,000Hz)
SampFreq = 142857.142857								# 1 / (SampRat * 10^-9)
activeADC = 0b00000010								#mask for AIN-0
type = np.float32								#data type for returned array from buffer
low_freq = 50
data_sum = []
rtotal = 40									#number of data sets to capture
threshold = 2									#peak threshold
peak_shift = 2


print("Samples = %s" % tSamp)
print("Sampling rate = %s Hz" % SampFreq)
print("Number of data sets = %s" % rtotal)
print
time.sleep(0.5)

io = pruio_new(PRUIO_DEF_ACTIVE, 0, 0, 0)					#create ctypes pointer to the pruio structure
try:
    do_cal = raw_input('Do you want to use cal data? (y/n)')
    if do_cal == 'y':
        cal = raw_input('Would you like to gather cal data? (y/n)')
        if cal == 'y':
            cal_data = sample()
            cal0 = windowing(cal_data)
            cal_fft = fft(cal0)
            cal_ave = average_fft(cal_fft)
            np.savetxt('cal_data.txt', cal_ave)
        else:
            cal_ave = np.loadtxt('cal_data.txt')
    else:
        cal_ave = 0
        continue

    data = sample()

#    data = np.loadtxt('data/data_-40db_snr.txt', dtype='float32')

    data0 = windowing(data)

    fft_data0 = fft(data0)

    ave_fft0 = average_fft(fft_data0) - cal_ave


#generate frequency vector
    f_vec = np.arange(0, tSamp) * SampFreq / tSamp

	#signal prep and remove offset
    ave_fft0[0] = np.abs(np.mean(ave_fft0))
    ave_fft0[1] = np.abs(np.mean(ave_fft0))

    ave_fft0 = ave_fft0 - np.mean(ave_fft0)*1.3

    peaks_x = peak_find(ave_fft0)

    peaks_x1 = []
    peaks_y1 = []
    p = 0
    while p < len(peaks_x):
        if peaks_x[p]*(SampFreq/tSamp) > 1 and peaks_x[p]*(SampFreq/tSamp) < 4000:
            peaks_x1.append(peaks_x[p]*(SampFreq/tSamp))
            peaks_y1.append(ave_fft0[peaks_x[p]])
        p += 1

    if peaks_x1 != []:
        print
        print("Peaks found!")
        print
        print("There are peaks at the following frequencies:")
        p = 0
        while p < len(peaks_x1):
            print("   %s Hz" % peaks_x1[p])
            p += 1
    else:
        print("No peaks were identified. Check graph.")


# Generate plot
    plt.style.use('ggplot')
    plt.rcParams['font.size']=14
    fig = plt.figure(figsize=(13,4))
    ax = fig.add_subplot(111)
    plt.plot(f_vec, ave_fft0)
    ax.set_ylim([0, np.max(ave_fft0)*1.1])
    ax.set_xlim([1, 4500])
#	plt.xlabel('Frequency [Hz]')
#	plt.ylabel('Amplitude')
#	ax.set_xscale('log')
    plt.grid(which='both', axis='both')
#annotate graph with peaks
    p = 0
    annot_array = []
    while p < len(peaks_x1):
        annot = ax.annotate('F%s: %2.2f'%(1+p, peaks_x1[p]),xy=(peaks_x1[p],peaks_y1[p]),\
            xycoords='data',xytext=(-20,30),textcoords='offset points',\
            arrowprops=dict(arrowstyle="->",color='k'),ha='center',va='top')
        annot_array.append(annot)
        p += 1

    plt.show()

finally:
    pruio_destroy(io)							#end it
    print('Done')


def sample():
    IO = io.contents							#pointer dereferencing, using contents member
    if IO.Errr:
        raise AssertionError("pruio_new failed (%s)" %IO.Errr)

    raw_input("Press Enter when ready to start sampling.")
    print
    print('Sampling now...\n')

    if pruio_config(io, tSamp, activeADC, SampRat, 0):			#upload settings, start IO mode, 12-bit resolution
        raise AssertionError("config failed (%s)" % IO.Errr)

    if pruio_rb_start(io):
        raise AssertionError("rb_start failed (%s)" % IO.Errr)

    data_array = []
    data = []
    p = 0
    t0 = time.time()
    while p < rtotal:
        pruio_config(io, tSamp, activeADC, SampRat, 0)
        pruio_rb_start(io)
        p0 = IO.Adc.contents.Value						#pointer to ADC value (start of ring buffer)
        while IO.DRam[0] > tSamp: time.sleep(0.001)				#wait for sampling to finish
        i = 0
        result = 0
	#pull data from buffer and move to list
        data_array = []
        while i < tSamp:
            result = p0[i]
            data_array.append(result)
            i += 1
        data.append(data_array)							#place completed data run in master list
        p += 1

    t1 = time.time()
    tim = t1 - t0
    print("Data collected in %s seconds." % tim)
    print

def windowing(data):
#apply windowing
    t0 = time.time()
    p = 0
    data0 = data
    data1 = data
    while p < rtotal:
        data0[p] = data0[p] * signal.kaiser(tSamp, 0.8, sym=False)
        p += 1
    t1 = time.time()
    tim = t1 - t0
    print("Windowing completed in %s seconds" % tim)
    print

def fft(data0):
#compute FFT
    p = 0
    fft_data0 = []
    t0 = time.time()
    while p < rtotal:
        fft_data0.append(np.abs(fft(data0[p])))
        p += 1
    t1 = time.time()
    tim = t1 - t0
    print("FFT completed in %s seconds" % tim)
    print

def ave_fft0(fft_data0):
#average all data sets
    ave_fft0 = np.zeros(tSamp)
    p = 0
    t0 = time.time()
    while p < rtotal:
        ave_fft0 = ave_fft0 + fft_data0[p]
        p += 1
    ave_fft0 = ave_fft0 / rtotal
    t1 = time.time()
    tim = t1 - t0
    print("Averaging completed in %s seconds" % tim)
    print

def peak_find(ave_fft0):
#Peak finding stuff
    peaks_x = []
    print("Peak finding. First pass.")
    print
    while len(peaks_x) < 8:
    peaks_x = peakutils.indexes(ave_fft0,thres=threshold,min_dist=peak_shift)
        threshold += -0.1

    print("Peak finding. Second pass.")
    print
    while len(peaks_x) > 12:
        threshold += 0.01
        peaks_x = peakutils.indexes(ave_fft0,thres=threshold,min_dist=peak_shift)

    print("Peak finding. Third pass.")
    print
    while len(peaks_x) >= 8:
        threshold += 0.001
        peaks_x = peakutils.indexes(ave_fft0,thres=threshold,min_dist=peak_shift)

    threshold += -0.001
    peaks_x = peakutils.indexes(ave_fft0,thres=threshold,min_dist=peak_shift)
    print("Peak finding. Fourth pass.")
    print
    while len(peaks_x) > 6:
        peaks_x = peakutils.indexes(ave_fft0,thres=threshold,min_dist=peak_shift)
        threshold += 0.0001

    threshold += -0.0002
    peaks_x = peakutils.indexes(ave_fft0,thres=threshold,min_dist=peak_shift)
    print("Peak finding. Fifth pass.")
    print
    while len(peaks_x) > 6:
        peaks_x = peakutils.indexes(ave_fft0,thres=threshold,min_dist=peak_shift)
        threshold += 0.00001

    threshold += -0.00002
    peaks_x = peakutils.indexes(ave_fft0,thres=threshold,min_dist=peak_shift)
    print("Peak finding. Last pass.")
    print
    while len(peaks_x) > 6:
        peaks_x = peakutils.indexes(ave_fft0,thres=threshold,min_dist=peak_shift)
        threshold += 0.000001
#    print("Threshold = %s" % threshold)
#    print("Number of peaks = %s" % len(peaks_x))
return peaks_x
