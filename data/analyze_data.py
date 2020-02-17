from __future__ import print_function;
import numpy as np;
try:
  import matplotlib.pyplot as plt;
  from matplotlib.pyplot import *;
except ImportError:
  pass;
##

def fftPeakFind(spectrum,frequencies,num_peaks=1, \
    min_spacing=None,agc_threshold=12,noise_floor=None):
  """ Find N peaks of a spectrum eliminating a band of frequencies found
  around each peak found """ 
  spectrum = spectrum.copy();
  f = frequencies;
  out = {'indices':None,'peaks':None,'values':None,\
    'noise_floor':None,'agc_threshold':None};
  if num_peaks is None or np.isnan(num_peaks):
    num_peaks = 1;
  ##
  if min_spacing is None:
    df = abs(f[1]-f[0]);
    min_spacing = 2*df;
  ##
  if agc_threshold is None:
    agc_threshold = 12;
  ##
  out['agc_threshold']=agc_threshold;
  spectrum[np.isnan(spectrum)]=-np.inf;
  if np.all(np.isinf(spectrum)):
    #everything is inf so return nothing
    return out;
  ##
  if noise_floor is None:
    noise_floor = np.mean(spectrum[spectrum>-np.inf]);
  ##
  out['noise_floor']=noise_floor;
  if not np.isfinite(noise_floor):
    #noise floor is dumb, so quit
    return out;
  ##  
  spectrum[spectrum<(noise_floor+agc_threshold)]=-np.inf;
  if np.all(np.isinf(spectrum)):
    #nothing is above the threshold, quit out now
    return out;
  ##
  out['indices']=[];
  out['peaks']  =[];
  out['values'] =[];
  for i in range(num_peaks):
    try:
      idx = np.nanargmax(spectrum);
    except ValueError:
      #only occurs if things are all nan
      break;
    ##
    fpeak = f[idx];
    value = spectrum[idx];
    if value<=-np.inf:
      break;
    ##
    lgc = np.logical_and((fpeak-min_spacing)<=f,f<=(fpeak+min_spacing));
    spectrum[lgc]=-np.inf;
    out['indices'].append(idx);
    out['peaks'  ].append(fpeak);
    out['values' ].append(value);
  ##
  return out;
##

def simpleTest():
  N = 1000;
  n = np.array(range(N))/(N-1);
  x = np.random.randn(N)/(N/100);
  for i in range(3):
    x+= np.cos(2*np.pi*((i+1)*100)*n);
  ##
  f = np.linspace(-.5,+.5,x.size);
  spectrum = 20*np.log10(abs(np.fft.fftshift(np.fft.fft(x))));
  lgc = (f>=0);
  f = f[lgc];
  spectrum = spectrum[lgc];
  out = fftPeakFind(spectrum,f,num_peaks=3);
  print(out);
  
  try:
    plot(f,spectrum);
    xlabel(r'f [Hz/fs]');
    ylabel(r'S(f)');
    show();
  except:
    pass;
  ##
##

def windowN(N):
  return np.array(range(N))*1./(N-1);
##

def hanning(N):
  return 0.54-0.46*np.cos(2*np.pi*windowN(N));
##

def dataTest(plotit):
  WELCH_IT = True;
  
  data_type = np.float32; #data type for returned array from buffer
  Ts = 7000e-9;
  #sampling period in ns (20,000ns = 50,000Hz)
  fs = 1/Ts;
  f0_min = 100;
  f0_max = 4.5e3;
  
  num_peaks = 2;
  
  filename = 'data_-40db_snr.txt';
  data = np.loadtxt(filename,dtype=data_type);
  if WELCH_IT:
    data_w = data*hanning(data.shape[1]);
    data_f = abs(np.fft.fft(data_w));
    data_f = np.mean(data_f,axis=0);
  else:
    data_f = abs(np.fft.fft(data[1,:]));
  ##
  data_f = 20*np.log10(data_f);
  
  f = fs*np.linspace(0,1,data_f.size);
  
  #Get positive frequencies
  lgc = (f>0);
  f = f[lgc];
  data_f = data_f[lgc];
  
  #"Brickwall" filter for only frequencies of interest
  lgc = np.logical_and(f0_min<=f,f<=f0_max);
  f = f[lgc];
  data_f = data_f[lgc];
  
  out = fftPeakFind(data_f,f,num_peaks=num_peaks,agc_threshold=-np.inf,\
    min_spacing=(f0_max-f0_min)/50);
  print(out);
  try:
    plot(f/1e3,data_f);
    xlabel(r'f [kHz]');
    ylabel(r'S(f) [W/kHz]');
    show();
  except:
    pass;
  ##
##

dataTest(3);