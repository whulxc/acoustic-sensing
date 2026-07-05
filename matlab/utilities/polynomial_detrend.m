function [detrended_signal, trend_signal] = polynomial_detrend(signal, fs, degree)
%POLYNOMIAL_DETREND Remove a polynomial trend from a 1-D signal.

signal = signal(:);
num_samples = numel(signal);
time = (0:num_samples - 1)' / fs;

coefficients = polyfit(time, signal, degree);
trend_signal = polyval(coefficients, time);
detrended_signal = signal - trend_signal;
end
