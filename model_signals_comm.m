% Model of the Comm Channel
% Patrick Berry, Nick Courtney

clear; clc;


global fignum;fignum=1;

BASIC_ANALYSIS = true;
%%%%%%%%%%%%%%
% Constants for the problem
input.T = 10;
input.Ts = 10e-6;
input.fs = 1/input.Ts;
% Bandpass filter limits
input.min_f0 = 1e3;
input.max_f0 = 4e3;
input.A0 = 1e-3;%1 mV p2p
input.A2relA1 = 1;%ratio of tone2 amplitude/tone 1 amplitude
%%%%%%%%%%%%%%
% Parameters that can change
%%%%%%%%%%%%%%
input.AGC = 10;%dB Threshold above the noise floor
input.SNR_dB = 10;
% Signal peaks of interest
input.f1 = 2.5e3;
input.f2 = 3.0e3;
%%%%%%%%%%%%%%

if BASIC_ANALYSIS
  input.SNR_dB = 10;
  input.f1 = 2.5e3;
  input.f2 = 3.0e3;

  output = simulateSystem(input);

  % Signal peaks of interest
  timeSignalPlot      (input,output);
  plotFrequencySignals(input,output);
end

  
%%%%%%%%%%%%%%
% Plot the time signal
function timeSignalPlot(input,output)
  global fignum;
  %%%%%%%%%%%%%%
  fs = 1/input.Ts;
  f1 =   input.f1;
  f2 =   input.f2;
  t = output.t;
  x = output.tone1;
  y = output.tone2;
  z = output.pc_aux;
  zc = output.led_state;
  %%%%%%%%%%%%%%
  H=figure(fignum);fignum=fignum+1;clf;
  t0 = 6/min([fs,f1,f2]);
  lgc = (0<= t & t < t0);
  subplot(3,1,1);
  h=plot(t(lgc),x(lgc),t(lgc),y(lgc));
  arrayfun(@(h)set(h,'LiNeWiDtH',2),h);
  h=xlabel('\bftime (s)');h.FontSize=12;
  h=ylabel('\bfvoltage (V)');h.FontSize=12;
  h=legend({'Tone #1','Tone #2'},'Location','Best');h.FontSize=14;
  grid('on');
  subplot(3,1,2);
  plot(t(lgc),z(lgc));
  h=xlabel('\bftime (s)');h.FontSize=12;
  h=ylabel('\bfvoltage (V)');h.FontSize=12;
  h=legend({'Tones + Noise'},'Location','Best');h.FontSize=14;
  grid('on');
  subplot(3,1,3);
  plot(t(lgc),zc(lgc));
  h=xlabel('\bftime (s)');h.FontSize=12;
  h=ylabel('\bfvoltage (V)');h.FontSize=12;
  h=legend({'LED Signal'},'Location','Best');h.FontSize=14;
  grid('on');
end

%%%%%%%%%%%%%%
% Plot the frequency content
function plotFrequencySignals(input,output)
  global fignum;
  %%%%%%%%%%%%%%
  f1_kHz = input.f1/1e3;
  f2_kHz = input.f2/1e3;
  AGC = input.AGC;
  f_kHz = output.f/1e3;
  Z_dBW = output.pca_aux_psd;
  Zc_dBW = output.led_state_psd;
  avg_noise = output.avg_noise;
  %%%%%%%%%%%%%%
  H=figure(fignum);clf;fignum=fignum+1;
  
  subplot(2,1,1);
  hold('on');
  plot(f_kHz,Z_dBW);
  axs=axis();
  h=plot(f1_kHz+[0,0],axs(3:4),'ko','LineWidth',2);
  h=plot(f2_kHz+[0,0],axs(3:4),'ko','LiNeWidth',2);
  plot(f_kHz,avg_noise+zeros(size(f_kHz)),'r--','LineWIDTH',2);
  h=xlabel('\bffrequency (kHz)');set(h,'FoNtSiZe',16);
  h=ylabel('\bfPower Spectrum (dBW/Hz)');set(h,'FoNtSiZe',16);
  h=legend({'PC Aux Spectrum','Tone 1','Tone 2','Average Noise Floor'},'Location','SouthWest');h.FontSize=16;
  grid('on');
  
  subplot(2,1,2);
  hold('on');
  plot(f_kHz,Zc_dBW);
  plot(f_kHz,avg_noise+zeros(size(f_kHz)),'r--','LineWIDTH',2);
  plot(f_kHz,avg_noise+zeros(size(f_kHz))+AGC,'g--','LineWidth',2);
  axs=axis();
  h=xlabel('\bffrequency (kHz)');set(h,'FoNtSiZe',16);
  h=ylabel('\bfPower Spectrum (dBW/Hz)');set(h,'FoNtSiZe',16);
  grid('on');
  h=legend({'Received Spectrum','Average Noise Floor','AGC Threshold'},'Location','SouthWest');
  set(h,'fOntSiZe',16);
end


function [output] = simulateSystem(input)
  %%%%%%%%%%%%%%
  T = input.T;
  Ts = input.Ts;
  fs = 1/Ts;
  
  min_f0 = input.min_f0;
  max_f0 = input.max_f0;
  A0 = input.A0;
  A2relA1 = input.A2relA1;%ratio of tone2 amplitude/tone 1 amplitude

  SNR_dB = input.SNR_dB;
  f1 = input.f1;
  f2 = input.f2;
  %%%%%%%%%%%%%%
  
  %%%%%%%%%%%%%%
  t = 0:Ts:T;
  x = A0        *sin(2*pi*f1*t);%signal 1
  y = A0*A2relA1*cos(2*pi*f2*t);%signal 2
  tone_input = x+y;
  E_input = trapz(t,x.^2);
  assert(abs(E_input - A0^2/2*T)<1e-8);
  %Input Signal Energy for one tone should be A0^2*T

  NSR_dB = -SNR_dB;
  NSR_WpW = 10.^(NSR_dB/10);
  N0_WpHz = NSR_WpW*E_input;%W/Hz = (unitless)*Energy
  N0_W    = N0_WpHz*fs;%W/Hz*Hz = W
  N0_V    = sqrt(N0_W);

  % AWGN
  N = N0_V*randn(size(x));

  % Add noise to tones
  z = tone_input + N;

  % Comparator
  zc = z;
  lgc = (z>=0);
  zc(lgc)  = 0;
  zc(~lgc) = 1;
  %%%%%%%%%%%%%%
  output.t = t;
  output.tone1 = x;
  output.tone2 = y;
  output.tone_input = tone_input;
  output.noise = N;
  output.pc_aux = z;
  output.led_state = zc;
  %%%%%%%%%%%%%%
  
  %%%%%%%%%%%%%%
  % Process Sampled Data and Inspect Frequency Spectrum
  f = fs/2*linspace(-1,1,length(t));
  Z  = fftshift(fft(z ));
  Zc = fftshift(fft(zc));
  crappy_filter = (min_f0 <= f & f <= max_f0);
  f = f(crappy_filter);
  Z     = Z (crappy_filter);
  Zc    = Zc(crappy_filter);
  Z_dBW  = fftshift(20*log10(abs(Z )));
  Zc_dBW = fftshift(20*log10(abs(Zc)));
  avg_noise = mean(Zc_dBW(:));
  %%%%%%%%%%%%%%
  output.f = f;
  output.pca_aux_psd   = Z_dBW;
  output.led_state_psd = Zc_dBW;
  output.avg_noise = avg_noise;
  %%%%%%%%%%%%%%
end
