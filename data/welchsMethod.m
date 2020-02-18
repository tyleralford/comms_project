function [data] = welchsMethod(data,num_segments,percent_overlap,window_type)
  %Returns magnitude of power spectrum of data in decibels
  % data is chopped into a number of overlapping segments
  % a window is applied to each segment, the fft is taken of each individually
  % and then the average magnitude of the power spectrum is found
  
  if nargin<4 || isempty(window_type)
    window_type = 'rect';
  end
  total_length = numel(data);
  M = floor(total_length/num_segments);
  N = floor(total_length/num_segments*(1+percent_overlap));
  L = floor((N-M)/2);
  window_type = lower(window_type);
  n = (0:(N-1))/(N-1);
  switch(window_type)
  case 'rect'
    window = ones(size(n));
  case 'hamming'
    window = 0.54-0.46*cos(2*pi*n);
  case 'hann'
    window = 0.50-0.50*cos(2*pi*n);
  case 'blackman'
    window = 0.42-0.50*cos(2*pi*n)+0.08*cos(4*pi*n);
  otherwise
    window = ones(size(n));
  end
  datas = zeros(num_segments,N);
  for i=1:size(datas,1)
    start = (i-1)*N+1-max(i-1,0)*L;
    last  = start+N-1;
    if last>total_length
      break;
    end
    datas(i,:) = data(start:last);
  end
  try
    datas = datas.*window;
  catch ME %#ok<NASGU>
    %if does not handle broadcasting
    for i=1:size(datas,1)
      datas(i,:) = datas(i,:)*window;
    end
  end
  data = abs(fft(datas,[],2)).^2;
  if ismatrix(data) && size(data,1)>1
    data = mean(data,1);
  end
  data = 10*log10(data);
end
