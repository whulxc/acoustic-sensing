function [filtered_signal, coefficients] = bandpass_firpm_zero_phase( ...
    signal, fs, passband, stopband, filter_order, weights)
%BANDPASS_FIRPM_ZERO_PHASE Design and apply a zero-phase FIR band-pass.

if nargin < 6 || isempty(weights)
    weights = [10 1 10];
end

frequencies = [0 stopband(1) passband(1) passband(2) stopband(2) fs / 2] ...
    / (fs / 2);
amplitudes = [0 0 1 1 0 0];

coefficients = firpm(filter_order, frequencies, amplitudes, weights);
filtered_signal = filtfilt(coefficients, 1, signal(:));
end
