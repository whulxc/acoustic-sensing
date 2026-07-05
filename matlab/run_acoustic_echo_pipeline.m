clearvars -except DfileName DfilePath output_stereo
clf
close all;
script_dir=fileparts(mfilename('fullpath'));
repo_root=fileparts(script_dir);
global fs
global V_sound
global soundIntervalPot
fs=48000; %采样频率
V_sound=346;%声速
soundIntervalPot=2000; %发声间隔点数 
Ts=1/fs;  %采样间隔
soundInterval=soundIntervalPot/fs; %发声间隔
if ~exist('output_stereo','var') || isempty(output_stereo)
    output_stereo=2; %1:仅输出顶部声道 2:仅输底部声道 3.输出顶部和底部声道
end

%% chirp参数设置
f0 = 17000;       % 起始频率 Hz
f1 = 23000;       % 终止频率 Hz
f_low=f0-400;
f_high=f1+400;
T  = 0.01;       % 持续时间 s
use_window = 1;   % 是否加 Hann 窗 (1=加, 0=不加)
signalGain = 0.8; % 与 Java 代码一致

%% 导入辅助函数 %%
apply_path=fullfile(script_dir,'utilities');
addpath(genpath(apply_path))%调用该路径下的函数
%% 导入模板信号 %%
template_path=fullfile(script_dir,'templates','chirp_17_23khz_10ms');
template_refer_top_mat=importdata(fullfile(template_path,'reference_bottom_channel.txt')); %顶部麦克风（幅值大）
template_refer_botton_mat=importdata(fullfile(template_path,'reference_top_channel.txt'));  %底部麦克风（幅值小）

%% 导入并预处理音频数据（仅有txt文件则生成mat文件以加速调用）%%
if ~exist('DfileName','var') || isempty(DfileName)
    DfileName='Record'; %数据文件名
end
if ~exist('DfilePath','var') || isempty(DfilePath)
    DfilePath=fullfile(repo_root,'data','example'); %数据路径
end
DfileName=char(DfileName);
DfilePath=char(DfilePath);

template_refer{1}=template_refer_top_mat;
template_refer{2}=template_refer_botton_mat;

%template_refer{1}=ChirpTemplate(15000,20000,0.010,48000,1); %理论信号模板
%template_refer{2}=ChirpTemplate(15000,20000,0.010,48000,1); %理论信号模板
sum_template_refer{1}=norm(template_refer{1});
sum_template_refer{2}=norm(template_refer{2});
first_xcorr_thred(1)=0.9; %NCC相关度门限
first_xcorr_thred(2)=0.7; %NCC相关度门限

DfileName2m=DfileName+".mat";
DfileName2txt=DfileName+".txt";
%不存在txt文件则报错
if ~exist(DfilePath+"\"+DfileName2txt,'file')
    error('no txtFile');    
else
   %当不存在txt数据文件时，生成mat数据文件
   if ~exist(DfilePath+"\"+DfileName2m,'file')
       display('no mfile and create');
       load(DfilePath+"\"+DfileName2txt);
       save(DfilePath+"\"+DfileName2m,DfileName); 
   end
end
%原始音频数据
origin_data=importdata(DfilePath+"\"+DfileName2m); 

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

[origin_data_stereo_bandpass{i}, ~] = bp_firpm(origin_data_stereo_polydetrend{i}, fs, [f0 f1], [f_low f_high], 600);
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
% for j=1:30000 
%       compare_xcorr_index=compare_xcorr_index+1;
%       sum_power_origin_data_window=norm(origin_data_stereo_bandpass{i}(j:j+size_sum_template_refer(1,2)-1));
%       temp_xcorr_array(compare_xcorr_index)=dot(origin_data_stereo_bandpass{i}(j:j+size_sum_template_refer(1,2)-1),template_refer{i})/sum_power_origin_data_window/sum_power_template_refer{i};
% end
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
[transmit_delay{1},Frame_signal{1},Frame_signal_CC{1},Frame_signal_NCC{1},Frame_signal_CC_hilbert{1},Frame_signal_CC_start_index{1},Frame_signal_CC_hilbert_redue{1}]=split_chirp_frames(origin_data_stereo_bandpass{1},template_refer{1},first_xcorr_thred(1));
elseif output_stereo==2
[transmit_delay{2},Frame_signal{2},Frame_signal_CC{2},Frame_signal_NCC{2},Frame_signal_CC_hilbert{2},Frame_signal_CC_start_index{2},Frame_signal_CC_hilbert_redue{2}]=split_chirp_frames(origin_data_stereo_bandpass{2},template_refer{2},first_xcorr_thred(2));
else
[transmit_delay{1},Frame_signal{1},Frame_signal_CC{1},Frame_signal_NCC{1},Frame_signal_CC_hilbert{1},Frame_signal_CC_start_index{1},Frame_signal_CC_hilbert_redue{1}]=split_chirp_frames(origin_data_stereo_bandpass{1},template_refer{1},first_xcorr_thred(1));  
[transmit_delay{2},Frame_signal{2},Frame_signal_CC{2},Frame_signal_NCC{2},Frame_signal_CC_hilbert{2},Frame_signal_CC_start_index{2},Frame_signal_CC_hilbert_redue{2}]=split_chirp_frames(origin_data_stereo_bandpass{2},template_refer{2},first_xcorr_thred(2));
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
%大尺度时间-距离的CC图
figure1=figure;
title('大尺度时间-距离的CC图-处理');
xlim([compare_transmit_time(1),compare_transmit_time(end)]);
ylim([Distance_array(Distance_arrayStartIndex_Large),Distance_array(Distance_arrayEndIndex_Large)]);
hold on
imagesc(compare_transmit_time,Distance_array(Distance_arrayStartIndex_Large:Distance_arrayEndIndex_Large),R_xy_redue_jubu_hilbert_1); 
set(gca,'YDir','normal')
%colorbar;
caxis([0 max_minR_xy_redue_jubu_hilbert_1]) 
hold off

%%不加密结果可视化
for i=1:length(Frame_signal_CC_hilbert_redue{2}{1}) %距离数
    Distance_array_1(i)=(i-1)/fs*V_sound/2;  %% 回波距离序列 %%
end
[Distance_arrayStartIndex_Large_1,Distance_arrayEndIndex_Large_1]=value_to_index(Distance_array_1,startDist2DistStartIndex,endDist2DistEndIndex);
%大尺度时间-距离的CC图
figure2=figure;
title('大尺度时间-距离的CC图-不处理');
xlim([compare_transmit_time(1),compare_transmit_time(end)]);
ylim([Distance_array_1(Distance_arrayStartIndex_Large_1),Distance_array_1(Distance_arrayEndIndex_Large_1)]);
hold on
imagesc(compare_transmit_time,Distance_array_1(Distance_arrayStartIndex_Large_1:Distance_arrayEndIndex_Large_1),R_xy_redue_jubu_hilbert_1); 
set(gca,'YDir','normal')
colorbar;
%caxis([0 0.06]) 
hold off

%% save成txt格式 %%
%% 导出时间-距离的CC数据 %%
correlation_output_path=fullfile(DfilePath,'correlation_map.txt');
fid=fopen(correlation_output_path,'w');
[m,n]=size(Z_CC);
for i=1:m
   for j=1:n
      if j==n
         fprintf(fid,'%f\n',Z_CC(i,j));
      else
         fprintf(fid,'%f ',Z_CC(i,j));
      end
   end 
end
fclose(fid);
%% 导出距离的数据 %%
distance_output_path=fullfile(DfilePath,'distance_axis.txt');
fid=fopen(distance_output_path,'w');
[m,n]=size(Y_dis);
for i=1:m
   for j=1:n
      if j==n
         fprintf(fid,'%f\n',Y_dis(i,j));
      else
         fprintf(fid,'%f ',Y_dis(i,j));
      end
   end 
end
fclose(fid);
%% 导出时间的数据 %%
time_output_path=fullfile(DfilePath,'time_axis.txt');
fid=fopen(time_output_path,'w');
[m,n]=size(X_t);
for i=1:m
   for j=1:n
      if j==n
         fprintf(fid,'%f\n',X_t(i,j));
      else
         fprintf(fid,'%f ',X_t(i,j));
      end
   end 
end
fclose(fid);
function [y, b] = bp_firpm(x, Fs, passband, stopband, N, W)
%BP_FIRPM 设计等波纹 FIR 带通滤波器并对信号滤波
%
%   [y, b] = bp_firpm(x, Fs, passband, stopband, N, W)
%
%   输入参数：
%       x        - 输入信号 (列向量或行向量均可)
%       Fs       - 采样率 (Hz)
%       passband - 通带频率范围 [f1 f2] (Hz)，例如 [12000 15000]
%       stopband - 阻带频率范围 [fstop1 fstop2] (Hz)，
%                  例如 [11600 15400]，分别对应通带两侧阻带边界
%       N        - 滤波器阶数（越大通带越平坦，典型值 400-800）
%       W        - 权重 [w_stop1, w_pass, w_stop2]，控制不同带宽的重要性
%                  一般可设为 [10 1 10]
%
%   输出参数：
%       y  - 滤波后的信号（零相位 filtfilt 处理）
%       b  - FIR 滤波器系数
%
%   示例：
%       Fs = 48000;
%       load handel.mat; % 示例音频
%       x = y;           % 原始信号
%       [y_filt, b] = bp_firpm(x, Fs, [12000 15000], [11600 15400], 500, [10 1 10]);
%       sound(y_filt, Fs);
%
%   作者：ChatGPT（封装自 firpm 等波纹 FIR 带通设计方案）

    % 参数检查
    if nargin < 6
        W = [10 1 10]; % 默认权重
    end

    % 归一化频率 (0~1 对应 0~Fs/2)
    F = [0 stopband(1) passband(1) passband(2) stopband(2) Fs/2] / (Fs/2);

    % 幅值目标
    A = [0 0 1 1 0 0];

    % 设计滤波器
    b = firpm(N, F, A, W);

    % 零相位滤波
    y = filtfilt(b, 1, x(:));

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
