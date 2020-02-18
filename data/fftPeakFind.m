function [idx_peaks,noise_floor,agc_threshold] = ...
    fftPeakFind(spectrum,frequencies,num_peaks,min_spacing,agc_threshold,noise_floor)
  % Find N peaks of a spectrum eliminating a band of frequencies found
  % around each peak found
  f = frequencies;
  if nargin<3 || isempty(num_peaks)
    num_peaks =1;
  end
  if nargin<4 || isempty(min_spacing)
    df = abs(f(2)-f(1));
    min_spacing = 2*df;
  end
  if nargin<5 || isempty(agc_threshold)
    agc_threshold = 12;
  end
  if nargin<6 || isempty(noise_floor)
    noise_floor = mean(spectrum(~isinf(spectrum)));
  end
  lgc = (spectrum>(noise_floor+agc_threshold));
  spectrum(~lgc)=-inf;
  idx_peaks = nan(1,num_peaks);
  if ~any(lgc,'all')
    %no peaks anywhere above level
    return;
  end
  for i=1:num_peaks
    [value,idx]=max(spectrum);
    if isinf(value)
      break;
    end
    f_peak = f(idx);
    lgc = (f_peak-min_spacing <= f & f <= f_peak+min_spacing);
    spectrum(lgc)=-inf;
    idx_peaks(i) = idx;
  end
end