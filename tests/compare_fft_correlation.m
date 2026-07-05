clear
repo_root = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(repo_root, 'matlab'));

record = load_first_numeric(fullfile(repo_root, 'data', 'example', 'Record.mat'));
template = load_first_numeric(fullfile(repo_root, 'matlab', 'templates', ...
    'chirp_17_23khz_10ms', 'reference_top_channel.mat'));

record_signal = record(1:end - 2);
first_nonzero = find(abs(record_signal) > 0, 1, 'first');
if isempty(first_nonzero)
    error('The example recording does not contain nonzero samples.');
end
signal_end = min(first_nonzero + 50000 - 1, numel(record_signal));
signal = record_signal(first_nonzero:signal_end);
template = template(:).';
max_start = 3000;

[cc_fft, ncc_fft] = sliding_template_correlation_fft(signal, template);
cc_direct = zeros(1, max_start);
ncc_direct = zeros(1, max_start);
valid_ncc = false(1, max_start);
template_power = norm(template);

for index = 1:max_start
    window = signal(index:index + numel(template) - 1);
    cc_direct(index) = dot(window, template);
    denominator = norm(window) * template_power;
    if denominator > eps
        ncc_direct(index) = cc_direct(index) / denominator;
        valid_ncc(index) = true;
    end
end

cc_error = max(abs(cc_fft(1:max_start) - cc_direct));
ncc_error = max(abs(ncc_fft(valid_ncc) - ncc_direct(valid_ncc)));

fprintf('Max CC error: %.6g\n', cc_error);
fprintf('Max NCC error: %.6g\n', ncc_error);

assert(cc_error < 1e-7, 'FFT CC differs from direct dot-product CC.');
assert(ncc_error < 1e-9, 'FFT NCC differs from direct dot-product NCC.');

function values = load_first_numeric(file_path)
    loaded = importdata(file_path);
    if isnumeric(loaded)
        values = loaded(:).';
        return
    end

    names = fieldnames(loaded);
    for index = 1:numel(names)
        candidate = loaded.(names{index});
        if isnumeric(candidate)
            values = candidate(:).';
            return
        end
    end

    error('No numeric vector found in %s.', file_path);
end
