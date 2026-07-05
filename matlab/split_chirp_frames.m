function [transmit_delay, Frame_signal, Frame_signal_CC, Frame_signal_NCC, ...
    Frame_signal_CC_hilbert, Frame_signal_CC_start_index, ...
    Frame_signal_CC_hilbert_redue] = split_chirp_frames( ...
    channel_signal, template_refer, first_xcorr_thred, frame_interval)
%SPLIT_CHIRP_FRAMES Segment repeated chirps by template correlation.
%
% This function keeps the original input/output contract, but replaces the
% repeated time-domain dot products with one FFT-based sliding correlation.
% The following frame search still follows the legacy logic:
%   1. find the first NCC threshold crossing;
%   2. refine the first chirp start near that crossing;
%   3. find later chirps by a raw-CC threshold and local refinement;
%   4. export per-frame CC, NCC, Hilbert envelope, and reduced envelope.

channel_signal = channel_signal(:).';
template_refer = template_refer(:).';

num_signal = numel(channel_signal);
template_length = numel(template_refer);
template_half_length = floor(template_length / 2);

if nargin < 4 || isempty(frame_interval)
    error('frame_interval must be provided.');
end
if num_signal < template_length + frame_interval
    error('Input signal is too short for the template and one chirp frame.');
end

[sliding_cc, sliding_ncc] = sliding_template_correlation_fft( ...
    channel_signal, template_refer);
valid_start_count = numel(sliding_cc);

first_candidates = find(sliding_ncc > first_xcorr_thred, 1, 'first');
if isempty(first_candidates)
    error('No frame exceeds the first NCC threshold %.3f.', first_xcorr_thred);
end

first_threshold_index = first_candidates;
if first_threshold_index < template_half_length
    first_threshold_index = first_threshold_index + frame_interval;
end

% Match the legacy first-frame refinement window: threshold index through
% roughly one template length later, clipped to valid correlation samples.
first_refine_start = first_threshold_index;
first_refine_end = min(first_threshold_index + template_length, valid_start_count);
[~, local_first_peak] = max(sliding_ncc(first_refine_start:first_refine_end));
first_peak_index = first_refine_start + local_first_peak - 1;

max_frame_count = floor((num_signal - (first_peak_index - template_half_length)) ...
    / frame_interval);
max_frame_count = max(0, double(max_frame_count));

transmit_delay = zeros(1, max_frame_count);
Frame_signal = cell(1, max_frame_count);
Frame_signal_CC = cell(1, max_frame_count);
Frame_signal_NCC = cell(1, max_frame_count);
Frame_signal_CC_hilbert = cell(1, max_frame_count);
Frame_signal_CC_hilbert_redue = cell(1, max_frame_count);
Frame_signal_CC_start_index = zeros(1, max_frame_count);

transmit_delay(1) = first_peak_index - template_half_length;
frame_count = 0;
cc_threshold = 0;

for frame_index = 1:max_frame_count
    if frame_index == 1
        current_delay = transmit_delay(1);
    else
        if num_signal - transmit_delay(frame_index - 1) - frame_interval ...
                < frame_interval * 2
            break
        end

        search_start = transmit_delay(frame_index - 1) + frame_interval + 1;
        search_end = num_signal - template_length - frame_interval + 1;
        search_start = max(1, search_start);
        search_end = min(valid_start_count, search_end);
        if search_start > search_end
            break
        end

        candidate_offset = find(sliding_cc(search_start:search_end) > cc_threshold, ...
            1, 'first');
        if isempty(candidate_offset)
            break
        end

        candidate_index = search_start + candidate_offset - 1;
        refine_start = max(1, candidate_index - template_length + 1);
        refine_end = min(valid_start_count, candidate_index + template_length - 1);
        [~, local_peak] = max(sliding_cc(refine_start:refine_end));
        peak_index = refine_start + local_peak - 1;

        current_delay = peak_index - template_half_length;
        transmit_delay(frame_index) = current_delay;
    end

    [frame_signal, frame_cc, frame_ncc] = extract_frame_correlation( ...
        channel_signal, sliding_cc, sliding_ncc, current_delay, frame_interval);
    if isempty(frame_signal)
        break
    end

    frame_count = frame_count + 1;
    Frame_signal{frame_count} = frame_signal;
    Frame_signal_CC{frame_count} = frame_cc;
    Frame_signal_NCC{frame_count} = frame_ncc;

    [max_cc, peak_in_frame] = max(frame_cc);
    Frame_signal_CC_start_index(frame_count) = peak_in_frame;
    Frame_signal_CC_hilbert{frame_count} = abs(hilbert(frame_cc));
    Frame_signal_CC_hilbert_redue{frame_count} = ...
        Frame_signal_CC_hilbert{frame_count}(peak_in_frame:end);

    if frame_index == 1
        cc_threshold = max_cc * 0.5;
    end
end

transmit_delay = transmit_delay(1:frame_count);
Frame_signal = Frame_signal(1:frame_count);
Frame_signal_CC = Frame_signal_CC(1:frame_count);
Frame_signal_NCC = Frame_signal_NCC(1:frame_count);
Frame_signal_CC_hilbert = Frame_signal_CC_hilbert(1:frame_count);
Frame_signal_CC_hilbert_redue = Frame_signal_CC_hilbert_redue(1:frame_count);
Frame_signal_CC_start_index = Frame_signal_CC_start_index(1:frame_count);
end

function [frame_signal, frame_cc, frame_ncc] = extract_frame_correlation( ...
    channel_signal, sliding_cc, sliding_ncc, transmit_delay, frame_length)
% Return the raw frame and its per-start CC/NCC arrays.

frame_start = transmit_delay + 1;
frame_end = transmit_delay + frame_length;

if frame_start < 1 || frame_end > numel(channel_signal) ...
        || frame_end > numel(sliding_cc)
    frame_signal = [];
    frame_cc = [];
    frame_ncc = [];
    return
end

frame_signal = channel_signal(frame_start:frame_end);
frame_cc = sliding_cc(frame_start:frame_end);
frame_ncc = sliding_ncc(frame_start:frame_end);
end
