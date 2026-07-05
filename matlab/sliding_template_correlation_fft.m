function [cc, ncc, window_power] = sliding_template_correlation_fft(signal, template)
%SLIDING_TEMPLATE_CORRELATION_FFT Fast sliding template correlation.
%
%   [cc, ncc, window_power] = sliding_template_correlation_fft(signal, template)
%
% Computes the same valid-start sliding dot product as:
%   cc(k) = dot(signal(k:k+M-1), template)
% but evaluates all k with one FFT-based convolution. The normalized
% correlation uses a cumulative-energy window norm to avoid another loop.

signal = signal(:).';
template = template(:).';

num_signal = numel(signal);
num_template = numel(template);
if num_signal < num_template
    error('Signal length must be at least the template length.');
end

nfft = 2 ^ nextpow2(num_signal + num_template - 1);
correlation_full = real(ifft( ...
    fft(signal, nfft) .* fft(fliplr(template), nfft)));

% The valid convolution samples correspond to every legal template start.
cc = correlation_full(num_template:num_signal);

energy_prefix = [0, cumsum(signal .^ 2)];
start_index = 1:numel(cc);
stop_index = start_index + num_template - 1;
window_energy = energy_prefix(stop_index + 1) - energy_prefix(start_index);
window_power = sqrt(max(window_energy, 0));

template_power = norm(template);
denominator = window_power * template_power;
ncc = zeros(size(cc));
valid = denominator > eps;
ncc(valid) = cc(valid) ./ denominator(valid);
end
