function plotData(filename,H)
  if nargin<2
    H=figure();clf;
  else
    figure(H);clf;
  end

  Ts = 7e-6;
  fs = 1/Ts;%142857.142857 Hz

  X = load(filename);
  FFT = @(X,varargin) 20*log10(abs(fftshift(fft(X,varargin{:}))));
  Xf = FFT(X,[],2);
  noise_floor = mean(Xf,'all');
  f = fs/2*linspace(-1,1,size(Xf,2));

  lgc = (500<=f & f<4.5e3);
  f0 = f(lgc);
  Xf0 = Xf(:,lgc);
  
  hold('on');
  h=plot(f0/1e3,Xf0);
  arrayfun(@(h)set(h.Annotation.LegendInformation,'IcOnDiSpLaYsTyLe','oFf'),h);
  set(h(end).Annotation.LegendInformation,'IcOnDiSpLaYsTyLe','oN');
  h=plot(f0/1e3,Xf0);
  h= plot([min(f0),max(f0)]/1e3,noise_floor+[0,0],'k--','LineWidtH',2);
  grid('on');
  h=legend({'FFT of Time Series','Noise Floor'},'Location','sOuThEaSt');h.FontSize=16;
  h=xlabel('\bffrequncy (kHz)');set(h,'FontSizE',16);
  h=ylabel('\bfPower Spectral Density (W/kHz)');set(h,'FontSiZe',16);
  h=title(['FFT of "' filename '"']);
  h.FontWeight='BolD';h.FontSize=20;h.Interpreter='none';
end