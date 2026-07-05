clear
repo_root = fileparts(fileparts(mfilename('fullpath')));

DfileName = 'Record';
DfilePath = fullfile(repo_root, 'data', 'example');
output_stereo = 2; % 1: top channel, 2: bottom channel, 3: both channels

txt_file = fullfile(DfilePath, [DfileName '.txt']);
mat_file = fullfile(DfilePath, [DfileName '.mat']);
if ~exist(txt_file, 'file') && ~exist(mat_file, 'file')
    error('Place Record.txt or Record.mat in %s before running this example.', DfilePath);
end

run(fullfile(repo_root, 'matlab', 'run_acoustic_echo_pipeline.m'));
