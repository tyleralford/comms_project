import numpy as np;


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
  if not np.isfinite(agc_threshold) or not np.isfinite(noise_floor):
    #agc threshold or noise floor is dumb, so quit
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


import matplotlib.pyplot as plt;
from matplotlib.pyplot import *;
plot(f,spectrum);
xlabel(r'f [Hz/fs]');
ylabel(r'S(f)');
show();
