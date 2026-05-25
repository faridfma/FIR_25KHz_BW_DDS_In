% =========================================================
% FIR OUTPUT FFT ANALYSIS + SIMULINK EXPORT
% =========================================================

clear;
clc;
close all;

% Remove old workspace variable
clear simulink_signal;

%% ================= USER SETTINGS =================

filename = 'fir_output.txt';

Fs = 500e3;          % Sample rate (Hz)
ADC_FS = 32767;      % 16-bit full scale

%% ================= LOAD DATA =================

fprintf('Loading file: %s\n', filename);

raw = dlmread(filename);

% Extract first column
x = raw(:,1);

% Force column vector
x = x(:);

Nraw = length(x);

fprintf('Total samples loaded: %d\n', Nraw);

%% ================= VALIDATION =================

if Nraw < 64
    error('Too few samples for FFT analysis');
end

%% ================= REMOVE DC =================

x = x - mean(x);

%% ================= FFT SIZE =================

% Largest power-of-2 FFT
NFFT = 2^floor(log2(Nraw));

if NFFT < 64
    error('FFT size too small');
end

% Truncate signal
x = x(1:NFFT);

N = NFFT;

fprintf('FFT size used: %d\n', N);

%% ================= NORMALIZATION =================

x = double(x) / ADC_FS;

%% ================= WINDOW =================

w = hann(N);

cg = mean(w);

xw = x .* w;

%% ================= FFT =================

X = fft(xw);

Xmag = abs(X) / (N * cg);

%% ================= SINGLE-SIDED FFT =================

Nh = floor(N/2);

Xmag = Xmag(1:Nh+1);

if Nh > 1
    Xmag(2:end-1) = 2 * Xmag(2:end-1);
end

f = (0:Nh) * Fs / N;

Xdb = 20*log10(Xmag + 1e-12);

%% ================= TIME DOMAIN PLOT =================

figure('Name','Time Domain');

plot(x,'LineWidth',1);

grid on;

title('FIR Output - Time Domain');

xlabel('Sample Index');

ylabel('Amplitude');

%% ================= FFT PLOT =================

figure('Name','FFT Spectrum');

plot(f/1e3, Xdb, 'LineWidth',1.2);

grid on;

title('FIR Output Spectrum');

xlabel('Frequency (kHz)');

ylabel('Magnitude (dBFS)');

xlim([0 Fs/2]/1e3);

%% ================= PEAK DETECTION =================

numPeaks = 5;

minPeakHeight = max(Xdb) - 80;

[pks, locs] = findpeaks( ...
    Xdb, ...
    'MinPeakHeight', minPeakHeight, ...
    'MinPeakDistance', 10);

[pks, idx] = sort(pks, 'descend');

locs = locs(idx);

fprintf('\n================ PEAKS ================\n');

fprintf('Rank\tFreq (kHz)\tMagnitude (dBFS)\n');

for i = 1:min(numPeaks, length(pks))

    fprintf('%d\t%.3f\t\t%.2f\n', ...
        i, ...
        f(locs(i))/1e3, ...
        pks(i));

end

fprintf('=======================================\n');

%% ================= SIMULINK EXPORT =================

% Exact sample time
Ts = 1/Fs;

fprintf('\nSample time = %.12e seconds\n', Ts);

% Create time vector
t = (0:N-1)' * Ts;

% Force column vectors
t = double(t(:));

x = double(x(:));

% Verify dimensions
fprintf('Length x = %d\n', length(x));
fprintf('Length t = %d\n', length(t));

% Create matrix format for From Workspace block
% Column 1 = time
% Column 2 = signal
simulink_signal = [t x];

% Export to MATLAB base workspace
assignin('base', 'simulink_signal', simulink_signal);

fprintf('\nVariable exported to workspace:\n');

whos simulink_signal

fprintf('\nREADY FOR SIMULINK\n');

%% ================= HOW TO USE IN SIMULINK =================
%
% 1. Add "From Workspace" block
%
% 2. Set Variable Name:
%
%       simulink_signal
%
% 3. Set model fixed-step size to:
%
%       2e-6
%
% because:
%
%       Ts = 1/Fs = 1/500e3 = 2e-6 sec
%