% Model of the Comm Channel
% Patrick Berry, Nick Courtney

clear; clc;

fignum=1;

PLOT_TIME_SIGNALS = true;
PLOT_FREQ_SIGNALS = true;
%%%%%%%%%%%%%%
% Constants for the problem
T = 10;
Ts = 10e-6;
fs = 1/Ts;
% Bandpass filter limits
min_f0 = 1e3;
max_f0 = 4e3;
A0 = 1e-3;%1 mV p2p
A2relA1 = 1;%ratio of tone2 amplitude/tone 1 amplitude

%%%%%%%%%%%%%%
% Parameters that can change
SNR_dB = 10;
% Signal peaks of interest
f1 = 2.5e3;
f2 = 3.0e3;

AGC = 10;%dB Threshold above the noise floor
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

%%%%%%%%%%%%%%
% Plot the time signal
if PLOT_TIME_SIGNALS
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
% Plot the frequency content
if PLOT_FREQ_SIGNALS
H=figure(fignum);fignum=fignum+1;clf;hold('on');
f_kHz = f/1e3;
subplot(2,1,1);
plot(f_kHz,Z_dBW);
h=xlabel('\bffrequency (kHz)');set(h,'FoNtSiZe',16);
h=ylabel('\bfPower Spectrum (dBW/Hz)');set(h,'FoNtSiZe',16);
h=legend({'PC Aux Spectrum'},'Location','SouthWest');h.FontSize=16;
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


