clc;clear all;
true_f = [332,1236];
x = [-40,-30,-20,-10,-5,0];
files = arrayfun(@(x)sprintf('data_%ddb_snr.txt',x),x,'Un',0);
for i=1:numel(files)
  analyzeData(files{i},true_f,[],figure(i));
end
fprintf('\n');

function analyzeData(filename,true_f,use_welches,Handle)
  if nargin<2 || isempty(true_f)
    true_f = [];
  end
  if nargin<3 || isempty(use_welches)
    use_welches = false;
  end
  if nargin<4 || isempty(Handle)
    Handle = [];
  end
  data = load(filename);
  if ismatrix(data) && size(data,1)>1
    data = data(1,:);
  end
  f0_min = 100;%1e3/1.1;
  f0_max = 4e3*1.1;
  Ts = 7e-6;
  fs = 1/Ts;
  agc_threshold = 13;%this value is critical
  % You should analyze just plain noise through your system and choise a
  % threshold level such that only 1e-3% of your noise is above the level
  % or whatever you choose your false alarm level to be.

  min_spacing = (f0_max-f0_min)/50;
  if use_welches
    df = 1/(numel(data)*Ts);
    num_segments = floor(min_spacing/df);
    data_f = welchsMethod(data,num_segments,1/2,'hamming');
  else
    data_f = 20*log10(abs(fft(data)));
  end
  f = fs*linspace(0,1,numel(data_f));

  lgc = (f0_min<=f & f<=f0_max);
  data_f = data_f(lgc);
  f = f(lgc);
  
  [idx_peaks,noise_floor,agc_threshold] = fftPeakFind(data_f,f,2,min_spacing,agc_threshold);
  idx_peaks = idx_peaks(~isnan(idx_peaks));
  if ~isempty(idx_peaks)
    idx_peaks = sort(idx_peaks);
  end
  dataf_peaks = data_f(idx_peaks);
  f_peaks = f(idx_peaks);
  SNR = mean(data_f(idx_peaks))-noise_floor;
  
  % Displaying results etc.
  fprintf('--------------------------\n');
  fprintf('Filename: "%s"\n',filename);
  fprintf('Effective SNR: %f\n',SNR);
  if ~isempty(f_peaks)
    fprintf('Peak found at %.2f kHz\n',f_peaks/1e3);
  else
    fprintf('No peaks found\n');
  end
  if ~isempty(true_f)
    score = calculateScore(true_f,f_peaks);
    fprintf('Score: %f\n',score);
  end
  
  if ~isempty(Handle)
    H=figure(Handle);clf;
    legs = {};
    hold('on');
    plot(f/1e3,data_f,'LiNeWidTh',2);
    axis('tight');
    legs{end+1}='Power Spectrum';
    axs=axis();
    plot(axs(1:2),noise_floor+[0,0],'k--','LineWidtH',2);
    legs{end+1}='Noise Floor';
    for i=1:numel(f_peaks)
      plot(f_peaks(i)/1e3+[0,0],dataf_peaks(i)+[0,0],'ro','MarkerSizE',16);
      legs{end+1}=sprintf('Tone #%d',i);
    end
    if exist('agc_threshold','var')
      plot(axs(1:2),noise_floor+agc_threshold+[0,0],'g--','LineWIDTH',2);
      legs{end+1}='AGC Threshold';
    end
    h=legend(legs,'Location','SoUtHeAst');
    h.FontSize=16;
    grid('on');
    h=xlabel('\bffrequency (kHz)');h.FontSize=16;
    h=ylabel('\bfPower Spectrum (W/Hz)');h.FontSize=16;
    h=title(['Spectrum of "' filename '"']);
    h.FontWeight='BolD';h.FontSize=20;h.Interpreter='none';
  end
end

function [score] = calculateScore(true_f,peak_f)
  score = 0;
  peak_f = peak_f(~isnan(peak_f));
  for f=peak_f
    [~,idx]=min(abs(true_f-f));
    score = -10*log10(abs(true_f(idx)-f)/true_f(idx));
    true_f = true_f([1:numel(true_f)]~=idx);
  end
end