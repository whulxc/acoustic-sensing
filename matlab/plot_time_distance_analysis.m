%输入：Frame_signal_CC_hilbert：多帧CC序列
%      transmit_delay：对应时延点序列
%      start_transmit_delay：设定开始时延点
%      select_sub：选择子图还是多图
%      startDist2DistStartIndex：局部图像的开始距离
%      endDist2DistEndIndex：局部图像的结束距离
%      start_frame：相对开始帧
%      end_frame：相对结束帧
%      caxis1_max：图3上色最大值
%      caxis2_max：图4上色最大值
%输出：if select_sub=true
%         figure1=figure;figure2=0;figure3=0;figure4=0;
%      else
%         figure1=figure;figure2=figure;figure3=figure;figure4=figure;
function [near_ridge_result,ridge_result,X_t,Y_dis,Z_CC,figure1,figure2,figure3,figure4]=plot_time_distance_analysis(Frame_signal_CC_hilbert,transmit_delay,start_transmit_delay,select_sub,startDist2DistStartIndex,endDist2DistEndIndex,start_frame,end_frame,caxis1_max,caxis2_max)
near_ridge_result=[];
ridge_result=[];
    global fs
    global V_sound

    switch nargin
        case 1:5
            error('no ennough Input in plot_time_distance_analysis');
        case 6
            start_frame=1;
            size_Frame_signal_CC_hilbert_redue=size(Frame_signal_CC_hilbert);
            end_frame=size_Frame_signal_CC_hilbert_redue(1,2);
            caxis1_max=0;
            caxis2_max=0;
        case 7
            size_Frame_signal_CC_hilbert_redue=size(Frame_signal_CC_hilbert);
            end_frame=size_Frame_signal_CC_hilbert_redue(1,2);
            caxis1_max=0;
            caxis2_max=0;
        case 8
            caxis1_max=0;
            caxis2_max=0;
        case 9
            caxis2_max=0;
        case 10  
        otherwise
            error('redundancy Input in plot_time_distance_analysis');
    end
    %% 构建多帧CC序列 %%
    frame_ith=0;
    for i=1:end_frame-start_frame+1 %帧数
        frame_ith=frame_ith+1;
        compare_transmit_time(frame_ith)=(transmit_delay(start_frame+i-1)-start_transmit_delay)/fs; %% 脉冲发射时间序列 %%
    end
    size_Frame_signal_CC_hilbert_redue_i=size(Frame_signal_CC_hilbert{1});
    for i=1:size_Frame_signal_CC_hilbert_redue_i(1,2) %距离数
    distance_array(i)=(i-1)/fs*V_sound/2;  %% 回波距离序列 %%
    end

    for i=1:end_frame-start_frame+1 %帧数
        for j=1:size_Frame_signal_CC_hilbert_redue_i(1,2) %距离数
            CC_waterfall(i,j)=Frame_signal_CC_hilbert{start_frame+i-1}(j); %% 时间-回波距离的CC矩阵 %%
        end
        if i==312
            ccc=1;
        end
    end
    size_CC_waterfall=size(CC_waterfall);

    %% 对应回波距离的频谱FFT %%
    fft_time=compare_transmit_time;
    size_fft_time=size(fft_time);
    T = (fft_time(1,end)-fft_time(1,1))/(size_fft_time(1,2)-1); % 等效均匀采样的采样周期
    nufft_Fs = 1/T;    
    for i=1:size_Frame_signal_CC_hilbert_redue_i(1,2)
        fft_data=CC_waterfall(:,i);
        %不去除趋势项
        Y_nufft(i,:) = nufft(fft_data,fft_time/T); %非均匀采样FFT
        %%去趋势项
        %p_trend = polyfit(fft_time,fft_data,1);
        %y_trend = polyval(p_trend,fft_time);    
        %fft_data_removeTrend = fft_data - y_trend;
        %Y_nufft(i,:) = nufft(fft_data_removeTrend,fft_time/T); %非均匀采样FFT
    end
    abs_Y_nufft=abs(Y_nufft);
    f_nufft = (0:size_CC_waterfall(1,1)-1)/size_CC_waterfall(1,1)*nufft_Fs; %% 频率序列 %%

    %% 绘图 %%
    startfsLarge2f_nufftstartindex=0.0;endfsLarge2f_nufftendindex=6; %大尺度频率范围
    startDistLarge2DistStartIndex=0.4;endDistLarge2DistEndIndex=2.0; %大尺度距离范围
    tartfs2f_nufftstartindex=0.0;endfs2f_nufftendindex=3; %局部频率范围
    %startDist2DistStartIndex;endDist2DistEndIndex; %局部距离范围(自定义)

    %绘制四张图
    if select_sub==false
        %% 大尺度 %%
        [f_nufftStartIndex_Large,f_nufftEndIndex_Large]=value_to_index(f_nufft,startfsLarge2f_nufftstartindex,endfsLarge2f_nufftendindex);
        [distStartIndex_Large,distEndIndex_Large]=value_to_index(distance_array,startDistLarge2DistStartIndex,endDistLarge2DistEndIndex);
        %输出用于训练，X轴为时间，Y轴为距离范围，Z轴为CC值
        X_t=compare_transmit_time;
        Y_dis=distance_array(distStartIndex_Large:distEndIndex_Large);
        Z_CC=CC_waterfall(:,distStartIndex_Large:distEndIndex_Large)';
        %大尺度时间-距离的CC图
        figure1=figure;
        title('大尺度时间-距离的CC图');
        xlim([compare_transmit_time(1),compare_transmit_time(end)]);
        ylim([distance_array(distStartIndex_Large),distance_array(distEndIndex_Large)]);
        hold on
        imagesc(compare_transmit_time,distance_array(distStartIndex_Large:distEndIndex_Large),CC_waterfall(:,distStartIndex_Large:distEndIndex_Large)'); 
        set(gca,'YDir','normal')
        %colorbar;
        %caxis([0 0.06]) 
        hold off
        %大尺度距离-频率亮点图
        figure2=figure;
        title('大尺度距离-频率的功率亮点图');
        hold on
        xlim([f_nufft(f_nufftStartIndex_Large),f_nufft(f_nufftEndIndex_Large)]);
        ylim([distance_array(distStartIndex_Large),distance_array(distEndIndex_Large)]);
        imagesc(f_nufft(f_nufftStartIndex_Large:f_nufftEndIndex_Large),distance_array(distStartIndex_Large:distEndIndex_Large),abs_Y_nufft(distStartIndex_Large:distEndIndex_Large,f_nufftStartIndex_Large:f_nufftEndIndex_Large));
        set(gca,'YDir','normal')
        xlabel('频率');
        ylabel('距离');
        colorbar;
        hold off
        %% 局部 %%
        [f_nufftStartIndex,f_nufftEndIndex]=value_to_index(f_nufft,tartfs2f_nufftstartindex,endfs2f_nufftendindex);
        [distStartIndex,distEndIndex]=value_to_index(distance_array,startDist2DistStartIndex,endDist2DistEndIndex);
        %指定距离范围内时间-距离的CC图中提取山脊线 
        sst=CC_waterfall(:,distStartIndex:distEndIndex)';sst_dis=distance_array(distStartIndex:distEndIndex)';
        ridge = tfridge(sst,sst_dis,0.00357291666666704); %时频脊线提取函数 
        size_sst=size(sst);
        for i=1:size_sst(1,2)
            locMaxIndex_sst{i} = islocalmax(sst(:,i));
        end
        for i=1:size_sst(1,2)    %绘制局部最大值
            y_loc=sst_dis(locMaxIndex_sst{i});
            size_y_loc=size(y_loc);
            x_loc=compare_transmit_time(i)*ones(1,size_y_loc(1,1));
            plot(x_loc,y_loc,'color','k','Marker','.','linestyle','none');
        end
        figure3=figure;
        title('指定距离范围内时间-距离的CC图');
        xlim([compare_transmit_time(1),compare_transmit_time(end)]);
        ylim([distance_array(distStartIndex),distance_array(distEndIndex)]);
        hold on
        imagesc(compare_transmit_time,distance_array(distStartIndex:distEndIndex),CC_waterfall(:,distStartIndex:distEndIndex)');  %局部时间-距离的CC
        set(gca,'YDir','normal')
        colorbar;
        if caxis1_max==0
        else
           caxis([0 caxis1_max]);
        end
        plot(compare_transmit_time,ridge,'r'); %时频脊线
        hold off
        ridge_result(:,1)=compare_transmit_time;
        ridge_result(:,2)=ridge;     
        %指定距离范围内距离-频率亮点图（用于训练）
        figure4=figure;
        title('指定距离范围内距离-频率的功率亮点图');
        xlim([f_nufft(f_nufftStartIndex),f_nufft(f_nufftEndIndex)]);
        ylim([distance_array(distStartIndex),distance_array(distEndIndex)]);
        hold on
        imagesc(f_nufft(f_nufftStartIndex:f_nufftEndIndex),distance_array(distStartIndex:distEndIndex),abs_Y_nufft(distStartIndex:distEndIndex,f_nufftStartIndex:f_nufftEndIndex));
        set(gca,'YDir','normal')
        xlabel('频率');
        ylabel('距离');
        colorbar;
        if caxis2_max==0
        else
           caxis([0 caxis2_max]);
        end
        hold off
    %绘制四张子图
    else 
        figure2=0;figure3=0;figure4=0;
        %% 大尺度 %%
        [f_nufftStartIndex_Large,f_nufftEndIndex_Large]=value_to_index(f_nufft,startfsLarge2f_nufftstartindex,endfsLarge2f_nufftendindex);
        [distStartIndex_Large,distEndIndex_Large]=value_to_index(distance_array,startDistLarge2DistStartIndex,endDistLarge2DistEndIndex);
        %输出用于训练，X轴为时间，Y轴为距离范围，Z轴为CC值
        X_t=compare_transmit_time;
        Y_dis=distance_array(distStartIndex_Large:distEndIndex_Large);
        Z_CC=CC_waterfall(:,distStartIndex_Large:distEndIndex_Large)';
        %大尺度时间-距离的CC图
        figure1=figure;
        subplot(2,2,1);
        title('大尺度时间-距离的CC图');
        xlim([compare_transmit_time(1),compare_transmit_time(end)]);
        ylim([distance_array(distStartIndex_Large),distance_array(distEndIndex_Large)]);
        hold on
        imagesc(compare_transmit_time,distance_array(distStartIndex_Large:distEndIndex_Large),CC_waterfall(:,distStartIndex_Large:distEndIndex_Large)'); 
        set(gca,'YDir','normal')
        colorbar;
        %caxis([0 0.06]) 
        hold off
        %大尺度距离-频率亮点图
        subplot(2,2,2);
        title('大尺度距离-频率的功率亮点图');
        xlim([f_nufft(f_nufftStartIndex_Large),f_nufft(f_nufftEndIndex_Large)]);
        ylim([distance_array(distStartIndex_Large),distance_array(distEndIndex_Large)]);
        hold on
        imagesc(f_nufft(f_nufftStartIndex_Large:f_nufftEndIndex_Large),distance_array(distStartIndex_Large:distEndIndex_Large),abs_Y_nufft(distStartIndex_Large:distEndIndex_Large,f_nufftStartIndex_Large:f_nufftEndIndex_Large));
        set(gca,'YDir','normal')
        xlabel('频率');
        ylabel('距离');
        colorbar;
        hold off
        %% 局部 %%
        [f_nufftStartIndex,f_nufftEndIndex]=value_to_index(f_nufft,tartfs2f_nufftstartindex,endfs2f_nufftendindex);
        [distStartIndex,distEndIndex]=value_to_index(distance_array,startDist2DistStartIndex,endDist2DistEndIndex);
        %指定距离范围内时间-距离的CC图中提取山脊线 
        sst=CC_waterfall(:,distStartIndex:distEndIndex)';sst_dis=distance_array(distStartIndex:distEndIndex)';
        ridge = tfridge(sst,sst_dis,0.00357291666666704,'NumRidges',1,'NumFrequencyBins',10); %时频脊线提取函数 
        %提取每个时刻的局部最大CC的距离
        size_sst=size(sst);
        for i=1:size_sst(1,2)
            locMaxIndex_sst{i} = islocalmax(sst(:,i));
        end
        subplot(2,2,3);
        title('指定距离范围内时间-距离的CC图');
        xlim([compare_transmit_time(1),compare_transmit_time(end)]);
        ylim([distance_array(distStartIndex),distance_array(distEndIndex)]);
        hold on
        imagesc(compare_transmit_time,distance_array(distStartIndex:distEndIndex),CC_waterfall(:,distStartIndex:distEndIndex)');  %局部时间-距离的CC
        set(gca,'YDir','normal')
        colorbar;
        if caxis1_max==0
        else
           caxis([0 caxis1_max]);
        end
        plot(compare_transmit_time,ridge,'r'); %时频脊线
        for i=1:size_sst(1,2)    %绘制局部最大值
            y_loc=sst_dis(locMaxIndex_sst{i});
            y_loc_Index = find(locMaxIndex_sst{i});
            size_y_loc=size(y_loc);
            x_loc=compare_transmit_time(i)*ones(1,size_y_loc(1,1));
            plot(x_loc,y_loc,'color','k','Marker','.','linestyle','none');
            %查找距离山脊线最近的局部最大值
            min_y_loc_to_ridge=abs(y_loc-ridge(i,1));
            [~,min_index_y_loc_to_ridge]=min(min_y_loc_to_ridge);
            y_loc_near_ridge(i,1)=y_loc(min_index_y_loc_to_ridge,1);
            y_loc_near_ridge_index(i,1)=y_loc_Index(min_index_y_loc_to_ridge,1);
            y_loc_near_ridge_cc(i,1)=sst(y_loc_near_ridge_index(i,1),i);
            plot(compare_transmit_time(i),y_loc_near_ridge(i,1),'color','m','Marker','.','linestyle','none');
        end
        hold off
        ridge_result(:,1)=compare_transmit_time;
        ridge_result(:,2)=ridge; 
        near_ridge_result(:,1)=compare_transmit_time;
        near_ridge_result(:,2)=y_loc_near_ridge; 
        near_ridge_result(:,3)=y_loc_near_ridge_cc;
        %指定距离范围内距离-频率亮点图（用于训练）
        subplot(2,2,4);
        title('指定距离范围内距离-频率的功率亮点图');
        xlim([f_nufft(f_nufftStartIndex),f_nufft(f_nufftEndIndex)]);
        ylim([distance_array(distStartIndex),distance_array(distEndIndex)]);
        hold on
        imagesc(f_nufft(f_nufftStartIndex:f_nufftEndIndex),distance_array(distStartIndex:distEndIndex),abs_Y_nufft(distStartIndex:distEndIndex,f_nufftStartIndex:f_nufftEndIndex));
        set(gca,'YDir','normal')
        xlabel('频率');
        ylabel('距离');
        colorbar;
        if caxis2_max==0
        else
           caxis([0 caxis2_max]);
        end
        hold off
    end
end
