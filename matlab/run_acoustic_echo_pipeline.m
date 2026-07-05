clearvars -except DfileName DfilePath output_stereo ResultPath
clf
close all;

script_dir = fileparts(mfilename('fullpath'));
repo_root = fileparts(script_dir);

global fs
global V_sound
global soundIntervalPot

fs = 48000;              % sample rate
V_sound = 346;           % sound speed
soundIntervalPot = 2000; % chirp interval in samples
Ts = 1 / fs;             %#ok<NASGU>
soundInterval = soundIntervalPot / fs; %#ok<NASGU>

if ~exist('output_stereo', 'var') || isempty(output_stereo)
    output_stereo = 2; % 1: top channel, 2: bottom channel, 3: both channels
end

%% Chirp parameters
f0 = 17000;       % start frequency, Hz
f1 = 23000;       % stop frequency, Hz
f_low = f0 - 400;
f_high = f1 + 400;
T  = 0.01;        %#ok<NASGU> % duration, seconds
use_window = 1;   %#ok<NASGU> % reserved for chirp generation
signalGain = 0.8; %#ok<NASGU> % matches the Android-side signal gain

%% Helper functions
apply_path = fullfile(script_dir, 'utilities');
addpath(genpath(apply_path))

%% Reference templates from the current experiment configuration
template_path = fullfile(script_dir, 'templates', 'chirp_17_23khz_10ms');
template_refer_top_mat = load_template_vector( ...
    fullfile(template_path, 'reference_bottom_channel.mat'), ...
    fullfile(template_path, 'reference_bottom_channel.txt'));
template_refer_botton_mat = load_template_vector( ...
    fullfile(template_path, 'reference_top_channel.mat'), ...
    fullfile(template_path, 'reference_top_channel.txt'));

%% Input recording
if ~exist('DfileName', 'var') || isempty(DfileName)
    DfileName = 'Record';
end
if ~exist('DfilePath', 'var') || isempty(DfilePath)
    DfilePath = fullfile(repo_root, 'data', 'example');
end
DfileName = char(DfileName);
DfilePath = char(DfilePath);

template_refer{1} = template_refer_top_mat;
template_refer{2} = template_refer_botton_mat;

%template_refer{1}=ChirpTemplate(15000,20000,0.010,48000,1); % theoretical template
%template_refer{2}=ChirpTemplate(15000,20000,0.010,48000,1); % theoretical template
sum_template_refer{1}=norm(template_refer{1});
sum_template_refer{2}=norm(template_refer{2});
first_xcorr_thred(1)=0.9; % NCC threshold
first_xcorr_thred(2)=0.7; % NCC threshold

DfileName2m = DfileName + ".mat";
DfileName2txt = DfileName + ".txt";
mat_file = fullfile(DfilePath, char(DfileName2m));
txt_file = fullfile(DfilePath, char(DfileName2txt));

if ~exist(mat_file, 'file')
   if exist(txt_file, 'file')
       disp('No MAT recording found; creating it from the TXT recording.');
       load(txt_file);
       save(mat_file, DfileName);
   else
       error('Place %s or %s before running this script.', txt_file, mat_file);
   end
end

origin_data = load_data_vector(mat_file, DfileName);
%原始音频数据

%时间戳均在后
%剔除开始和结束时间戳
size_raw_origin_data=size(origin_data);
end_timmstamp=origin_data(size_raw_origin_data(1,2));         
start_timmstamp=origin_data(size_raw_origin_data(1,2)-1);         
origin_data=origin_data(1:size_raw_origin_data(1,2)-2);
size_raw_origin_data=size(origin_data);
%计算录音时间
round_timmstamp=(end_timmstamp-start_timmstamp)/1e9;
round_record=size_raw_origin_data(1,2)/48000/2;
round_Terror=round_timmstamp-round_record;
disp_Terror=['Terror:',num2str(round_Terror)];
disp(disp_Terror);

%跳过数据（双声道）
skip_num=0;
origin_data=origin_data(1+2*skip_num:size_raw_origin_data(1,2));
size_raw_origin_data=size(origin_data);
%分离左右声道
% origin_data_stereo{1}=origin_data ( 1: 2 :end);  %顶部
% origin_data_stereo{2}=origin_data ( 2: 2 :end);  %底部
 origin_data_stereo{1}=origin_data ( 1+48000*1*2: 2 :end);  %顶部
 origin_data_stereo{2}=origin_data ( 2+48000*1*2: 2 :end);  %底部
%  origin_data_stereo{1}= [zeros(1,200),origin_data_stereo{1}];
%  origin_data_stereo{2}= [zeros(1,200),origin_data_stereo{2}];
%%并剔除录音前期无效零值
%origin_data_stereo{1}=origin_data;
% for i=1:output_stereo
%     size_origin_data=size(origin_data_stereo{i});
%     for j=1:size_origin_data(1,2)
%         if origin_data_stereo{i}(j)>0
%            start_record_index(1,i)=j;
%            break;
%         end
%     end
%     origin_data_stereo{i}=origin_data_stereo{i}(start_record_index(1,i):end);
%end
%消除趋势项并且带通滤波
for i=1:output_stereo
%消除趋势项
[origin_data_stereo_polydetrend{i}, origin_data_stereo_xtrend{i}] = polynomial_detrend(origin_data_stereo{i}, fs, 3);
origin_data_stereo_polydetrend{i}=origin_data_stereo_polydetrend{i}';
%带通滤波
%origin_data_stereo_bandpass{i}= filter(filter_bandpass, origin_data_stereo_polydetrend{i});%注意群时延，大概延迟207-146个点，实际应该可以抵消

[origin_data_stereo_bandpass{i}, ~] = bandpass_firpm_zero_phase(origin_data_stereo_polydetrend{i}, fs, [f0 f1], [f_low f_high], 600);
origin_data_stereo_bandpass{i}=origin_data_stereo_bandpass{i}';
end

% %% 检查绘制原始数据 %%
% %检查滤波后原始数据
% figure(1)
% title('滤波后原始数据');
% subplot(1,2,1);
% hold on
% plot(origin_data_stereo_bandpass{1}(1:40000),'color','r');
%  subtitle('顶部');
% subplot(1,2,2);
% hold on
% plot(origin_data_stereo_bandpass{2}(1:40000),'color','r');
% subtitle('底部');
% %检查NCC结果
% figure(2)
% title('NCC');
% for i=1:2
% subplot(1,2,i);
% hold on
% if i==1
% subtitle('顶部');
% else
%  subtitle('底部');   
% end
% compare_xcorr_index=0;
% size_sum_template_refer=size(template_refer{i});
% sum_power_template_refer{i}=norm(template_refer{i});
% Use sliding_template_correlation_fft(...) for NCC diagnostics.
% plot(temp_xcorr_array,'color','r');
% clear temp_xcorr_array;
% end
% %检查模板信号
% figure(3)
% title('模板信号');
% subplot(1,2,1);
% hold on
% plot(template_refer{1},'color','r');
%  subtitle('顶部');
% subplot(1,2,2);
% hold on
% plot(template_refer{2},'color','r');
% subtitle('底部');

%% 周期脉冲分帧，在与模板信号NCC最大处向前若干为起点分帧 %%
if output_stereo==1
[transmit_delay{1},Frame_signal{1},Frame_signal_CC{1},Frame_signal_NCC{1},Frame_signal_CC_hilbert{1},Frame_signal_CC_start_index{1},Frame_signal_CC_hilbert_redue{1}]=split_chirp_frames(origin_data_stereo_bandpass{1},template_refer{1},first_xcorr_thred(1),soundIntervalPot);
elseif output_stereo==2
[transmit_delay{2},Frame_signal{2},Frame_signal_CC{2},Frame_signal_NCC{2},Frame_signal_CC_hilbert{2},Frame_signal_CC_start_index{2},Frame_signal_CC_hilbert_redue{2}]=split_chirp_frames(origin_data_stereo_bandpass{2},template_refer{2},first_xcorr_thred(2),soundIntervalPot);
else
[transmit_delay{1},Frame_signal{1},Frame_signal_CC{1},Frame_signal_NCC{1},Frame_signal_CC_hilbert{1},Frame_signal_CC_start_index{1},Frame_signal_CC_hilbert_redue{1}]=split_chirp_frames(origin_data_stereo_bandpass{1},template_refer{1},first_xcorr_thred(1),soundIntervalPot);  
[transmit_delay{2},Frame_signal{2},Frame_signal_CC{2},Frame_signal_NCC{2},Frame_signal_CC_hilbert{2},Frame_signal_CC_start_index{2},Frame_signal_CC_hilbert_redue{2}]=split_chirp_frames(origin_data_stereo_bandpass{2},template_refer{2},first_xcorr_thred(2),soundIntervalPot);
end 

select_Frame_signal=Frame_signal{2};
select_Frame_signal_CC=Frame_signal_CC{2};
Frame_signal_length=length(select_Frame_signal);
OSF=1;
[t_idealWave_16, idealWave_interp_16, ~] = sinc_interp_cc(template_refer{2}, fs, OSF);
%% 对每次脉冲进行估计 %%
for i=1:Frame_signal_length
    [t_select_Frame_signal_16, select_Frame_signal_interp_16, ~] = sinc_interp_cc(select_Frame_signal{1,i}, fs, OSF);  %SinC加密信号

    %单帧信号处理
    %% 互相关 %%
    fs_interp = fs * OSF;   % 插值后的采样率
    x = select_Frame_signal_interp_16(:);   % 接收（列向量）
    y = idealWave_interp_16(:);             % 模板（列向量）
    % 选择 FFT 长度（至少 lenx+leny-1），用2的幂提高效率
    n = length(x) + length(y) - 1;
    Nfft = 2^nextpow2(n);   
    % 计算 FFT
    X = fft(x, Nfft);
    Y = fft(y, Nfft);
    % --------- 标准频域互相关（ifft(X * conj(Y))) ---------
    R_xy = ifft( X .* conj(Y) );   % 线性互相关 (circular padding handled by zero-pad)
    R_xy = real(R_xy);             % 结果应为实数（数值误差）
    % 将互相关结果重排为 lags = -(L_y-1) : (L_x-1)
    lags = -(length(y)-1) : (length(x)-1);
    % keep only n points (first n elements correspond to 0..Nfft-1 circular indexing)
    R_xy = [ R_xy(Nfft - (length(y)-1) + 1 : Nfft); R_xy(1 : length(x)) ]; % 对应上面 lags
    
    % --------- 全局CC最大值（直达声）---------
    [max_value_CC(i), max_idx_CC(i)]=max(R_xy); 
    R_xy_redue{i}=R_xy(max_idx_CC(i):end);
    %全局CC最大值作为起点来确定定位区间
    for j=1:length(R_xy_redue{i}) %距离数
        distance_array(j)=(j-1)/(fs*OSF)*V_sound/2;  %% 回波距离序列 %%
    end
    startDist2DistStartIndex=0.4;endDist2DistEndIndex=2; %查看局部距离范围(根据姿势决定)   
    %加密结果
    [distance_arrayStartIndex_Large,distance_arrayEndIndex_Large]=value_to_index(distance_array,startDist2DistStartIndex,endDist2DistEndIndex);
    R_xy_redue_jubu(:,i)=R_xy_redue{i}(distance_arrayStartIndex_Large:distance_arrayEndIndex_Large);
    R_xy_redue_jubu_hilbert(:,i)=abs(hilbert(R_xy_redue_jubu(:,i)));

    %不加密结果
    for j=1:length(Frame_signal_CC_hilbert_redue{2}{i}) %距离数
        distance_array_1(j)=(j-1)/fs*V_sound/2;  %% 回波距离序列 %%
    end
    [distance_arrayStartIndex_Large_1,distance_arrayEndIndex_Large_1]=value_to_index(distance_array_1,startDist2DistStartIndex,endDist2DistEndIndex);
    R_xy_redue_jubu_hilbert_1(:,i)=Frame_signal_CC_hilbert_redue{2}{i}(distance_arrayStartIndex_Large_1:distance_arrayEndIndex_Large_1);

    %局部CC最大值
    min_startDist2DistStartIndex=0.8;min_endDist2DistEndIndex=1.8; 
    [min_distance_arrayStartIndex_Large_1,min_distance_arrayEndIndex_Large_1]=value_to_index(distance_array_1,min_startDist2DistStartIndex,min_endDist2DistEndIndex);
    minR_xy_redue_jubu_hilbert_1(:,i)=Frame_signal_CC_hilbert_redue{2}{i}(min_distance_arrayStartIndex_Large_1:min_distance_arrayEndIndex_Large_1);


    
%     figure_signal=figure;
%     hold on;
%     plot(R_xy_redue_jubu,'k-');
%     plot(R_xy_redue_jubu_hilbert,'r-');
%     if exist('figure_signal','var') && isvalid(figure_signal)
%        close(figure_signal);
%     end
end

%%处理结果可视化
startDist2DistStartIndex=0.4;endDist2DistEndIndex=2; %查看局部距离范围(根据姿势决定)   
for i=1:length(R_xy_redue{1}) %距离数
    Distance_array(i)=(i-1)/(fs*OSF)*V_sound/2;  %% 回波距离序列 %%
end
[Distance_arrayStartIndex_Large,Distance_arrayEndIndex_Large]=value_to_index(Distance_array,startDist2DistStartIndex,endDist2DistEndIndex);
compare_transmit_time=(0:soundIntervalPot/fs:(Frame_signal_length-1)*soundIntervalPot/fs);

%局部CC最大值
for i=1:size(minR_xy_redue_jubu_hilbert_1,1)
temp_sum(i)=sum(minR_xy_redue_jubu_hilbert_1(i,:));
end
[max_value_temp_sum,max_index_temp_sum]=max(temp_sum);
max_minR_xy_redue_jubu_hilbert_1=max(minR_xy_redue_jubu_hilbert_1(max_index_temp_sum,:));

%max_minR_xy_redue_jubu_hilbert_1=max(minR_xy_redue_jubu_hilbert_1(:));

%对时距图滤波
% % 假设 R_xy_redue_jubu_hilbert 是 M x N 矩阵，每一行是一个时间序列
% time_fs = 24;             % 采样率 Hz
% f_cut = 8;          % 截止频率 Hz
% 
% % 归一化截止频率
% Wc = f_cut / (time_fs/2);
% 
% % 设计4阶Butterworth低通滤波器
% [b, a] = butter(4, Wc, 'low');
% 
% % 对每一行进行滤波
% R_filtered = zeros(size(R_xy_redue_jubu_hilbert));
% for i = 1:size(R_xy_redue_jubu_hilbert,1)
%     R_filtered(i,:) = filtfilt(b, a, R_xy_redue_jubu_hilbert(i,:));
% end
filter_R_xy_redue_jubu_hilbert_1=R_xy_redue_jubu_hilbert_1;
for i=1:size(R_xy_redue_jubu_hilbert_1,1)
temp_sum_minR_xy_redue_jubu_hilbert_1(i)=sum(R_xy_redue_jubu_hilbert_1(i,:));
per_temp_sum_minR_xy_redue_jubu_hilbert_1(i)=temp_sum_minR_xy_redue_jubu_hilbert_1(i)/max_value_temp_sum;
if per_temp_sum_minR_xy_redue_jubu_hilbert_1(i)<0.2
   filter_R_xy_redue_jubu_hilbert_1(i,:)=zeros(size(R_xy_redue_jubu_hilbert_1,2),1);
end
end
% Large-scale time-distance CC map after the display-level suppression step.
figure1=figure;
title('大尺度时间-距离的CC图-处理');
xlim([compare_transmit_time(1),compare_transmit_time(end)]);
ylim([Distance_array(Distance_arrayStartIndex_Large),Distance_array(Distance_arrayEndIndex_Large)]);
hold on
imagesc(compare_transmit_time,Distance_array(Distance_arrayStartIndex_Large:Distance_arrayEndIndex_Large),R_xy_redue_jubu_hilbert_1); 
set(gca,'YDir','normal')
xlabel('Time (s)');
ylabel('Distance (m)');
%colorbar;
caxis([0 max_minR_xy_redue_jubu_hilbert_1]) 
hold off

%% Unprocessed large-scale CC-map visualization
for i=1:length(Frame_signal_CC_hilbert_redue{2}{1}) %距离数
    Distance_array_1(i)=(i-1)/fs*V_sound/2;  %% 回波距离序列 %%
end
[Distance_arrayStartIndex_Large_1,Distance_arrayEndIndex_Large_1]=value_to_index(Distance_array_1,startDist2DistStartIndex,endDist2DistEndIndex);
X_t = compare_transmit_time;
Y_dis = Distance_array(Distance_arrayStartIndex_Large:Distance_arrayEndIndex_Large);
Z_CC = R_xy_redue_jubu_hilbert_1;
% Large-scale time-distance CC map before the display-level suppression step.
figure2=figure;
title('大尺度时间-距离的CC图-不处理');
xlim([compare_transmit_time(1),compare_transmit_time(end)]);
ylim([Distance_array_1(Distance_arrayStartIndex_Large_1),Distance_array_1(Distance_arrayEndIndex_Large_1)]);
hold on
imagesc(compare_transmit_time,Distance_array_1(Distance_arrayStartIndex_Large_1:Distance_arrayEndIndex_Large_1),R_xy_redue_jubu_hilbert_1); 
set(gca,'YDir','normal')
xlabel('Time (s)');
ylabel('Distance (m)');
colorbar;
%caxis([0 0.06]) 
hold off

%% save成txt格式 %%
%% 导出时间-距离的CC数据 %%
% Standard names are easier to read; legacy names preserve old workflows.
save_matrix_text(fullfile(DfilePath, 'correlation_map.txt'), Z_CC);
save_matrix_text(fullfile(DfilePath, 'CCvalue.txt'), Z_CC);
%% 导出距离的数据 %%
save_matrix_text(fullfile(DfilePath, 'distance_axis.txt'), Y_dis);
save_matrix_text(fullfile(DfilePath, 'Disvalue.txt'), Y_dis);
%% 导出时间的数据 %%
save_matrix_text(fullfile(DfilePath, 'time_axis.txt'), X_t);
save_matrix_text(fullfile(DfilePath, 'Tvalue.txt'), X_t);

if exist('ResultPath', 'var') && ~isempty(ResultPath)
    if ~exist(ResultPath, 'dir')
        mkdir(ResultPath);
    end

    save_matrix_text(fullfile(ResultPath, 'correlation_map.txt'), Z_CC);
    save_matrix_text(fullfile(ResultPath, 'distance_axis.txt'), Y_dis);
    save_matrix_text(fullfile(ResultPath, 'time_axis.txt'), X_t);
    save_matrix_text(fullfile(ResultPath, 'CCvalue.txt'), Z_CC);
    save_matrix_text(fullfile(ResultPath, 'Disvalue.txt'), Y_dis);
    save_matrix_text(fullfile(ResultPath, 'Tvalue.txt'), X_t);

    correlation_map = Z_CC; %#ok<NASGU>
    distance_axis = Y_dis; %#ok<NASGU>
    time_axis = X_t; %#ok<NASGU>
    save(fullfile(ResultPath, 'correlation_map.mat'), 'correlation_map');
    save(fullfile(ResultPath, 'distance_axis.mat'), 'distance_axis');
    save(fullfile(ResultPath, 'time_axis.mat'), 'time_axis');

    if exist('figure1', 'var') && isgraphics(figure1)
        savefig(figure1, fullfile(ResultPath, 'acoustic_echo_result.fig'));
        exportgraphics(figure1, fullfile(ResultPath, 'acoustic_echo_result.png'), ...
            'Resolution', 150);
        exportgraphics(figure1, fullfile(ResultPath, 'time_distance_cc_processed.png'), ...
            'Resolution', 150);
    end
    if exist('figure2', 'var') && isgraphics(figure2)
        exportgraphics(figure2, fullfile(ResultPath, 'time_distance_cc_unprocessed.png'), ...
            'Resolution', 150);
    end
end

function template = load_template_vector(mat_path, txt_path)
    if exist(mat_path, 'file')
        loaded = importdata(mat_path);
    elseif exist(txt_path, 'file')
        loaded = importdata(txt_path);
    else
        error('Missing template file: %s or %s', mat_path, txt_path);
    end
    template = first_numeric_vector(loaded);
end

function data = load_data_vector(mat_path, variable_name)
    loaded = importdata(mat_path);
    if isstruct(loaded) && isfield(loaded, variable_name)
        data = loaded.(variable_name);
    else
        data = first_numeric_vector(loaded);
    end
end

function values = first_numeric_vector(loaded)
    if isnumeric(loaded)
        values = loaded(:).';
        return
    end

    if isstruct(loaded)
        names = fieldnames(loaded);
        for index = 1:numel(names)
            candidate = loaded.(names{index});
            if isnumeric(candidate)
                values = candidate(:).';
                return
            end
        end
    end

    error('Expected a numeric vector in the loaded file.');
end

function [t_fine, r_interp, toa_sinc] = sinc_interp_cc(r, Fs, OSF)
% SINC_INTERP_CC 对互相关结果进行 sinc 插值，获得超采样精度的互相关
%
% 输入参数:
%   r   - 互相关结果 (列向量/行向量)
%   Fs  - 采样率 [Hz]
%   OSF - 过采样因子 (e.g., 8, 16, 32)
%
% 输出参数:
%   t_fine   - 超采样时间轴 (秒)
%   r_interp - 插值后的互相关序列
%   toa_sinc - 互相关峰值对应的时间 (秒)

    r = r(:);            % 保证是列向量
    N = length(r);       
    t = (0:N-1)/Fs;      % 原始时间轴

    % 构造超采样时间轴
    t_fine = linspace(0, (N-1)/Fs, N*OSF);

    % sinc 插值 (理想带限插值)
    r_interp = zeros(size(t_fine));
    for n = 1:N
        r_interp = r_interp + r(n) * sinc(Fs*(t_fine - t(n)));
    end

    % 查找最大峰值对应的 TOA
    [~, idx_max] = max(abs(r_interp));
    toa_sinc = t_fine(idx_max);
end
