%%利用NCC进行周期脉冲分帧
%输入:Channel_signal：多周期声道信号
%     template_refer：模板信号
%     first_xcorr_thred：第一帧CC阈值  
%输出:transmit_delay：每帧脉冲时间
%     Frame_signal：每帧原始信号
%     Frame_signal_CC：每帧CC 
%     Frame_signal_NCC：每帧NCC 
%     Frame_signal_CC_hilbert：每帧CC包络  
%     Frame_signal_CC_start_index：每帧直达径相对起点位置
%     Frame_signal_CC_hilbert_redue：每帧CC包络且直达径作为起点  
function [transmit_delay,Frame_signal,Frame_signal_CC,Frame_signal_NCC,Frame_signal_CC_hilbert,Frame_signal_CC_start_index,Frame_signal_CC_hilbert_redue]=split_chirp_frames(Channel_signal,template_refer,first_xcorr_thred)
  global soundIntervalPot
  size_Channel_signal=size(Channel_signal);
  template_size=size(template_refer); 
  sum_power_template_refer=norm(template_refer);
  compare_bef_index_first_xcorr_thred=floor(template_size(1,2)/2); %模板一半的长度
  thred_xcorr=0; %第一帧互相关最大值作为阈值（预赋值）
  
  %% 估计第一帧发射位置 %%
  for i=1:size_Channel_signal(1,2)-template_size(1,2)+1
      sum_power_origin_data_window=norm(Channel_signal(i:i+template_size(1,2)-1));
      temp_xcorr=dot(Channel_signal(i:i+template_size(1,2)-1),template_refer)/sum_power_origin_data_window/sum_power_template_refer;
      sum_test_xcorr(i)=temp_xcorr;
      if temp_xcorr>first_xcorr_thred
         first_xcorr_thred_index=i; %确定超过阈值的第一个绝对位置
         break;
      end
  end
  if first_xcorr_thred_index<compare_bef_index_first_xcorr_thred
     first_xcorr_thred_index=first_xcorr_thred_index+soundIntervalPot;
  end 
  compare_xcorr_index=0;
  for i=first_xcorr_thred_index:first_xcorr_thred_index+template_size(1,2) 
      compare_xcorr_index=compare_xcorr_index+1;
      sum_power_origin_data_window=norm(Channel_signal(i:i+template_size(1,2)-1));
      temp_xcorr_array(compare_xcorr_index)=dot(Channel_signal(i:i+template_size(1,2)-1),template_refer)/sum_power_origin_data_window/sum_power_template_refer; %在超过阈值后的模板区域求CC序列
  end
  [max_compare_xcorr,max_compare_xcorr_index]=max(temp_xcorr_array);   %确定与first_xcorr_thred_index相比的最大值相对位置
  max_temp_xcorr_index=max_compare_xcorr_index+first_xcorr_thred_index-1;  %确定最大值绝对位置
  clear temp_xcorr_array;
  
  %% 确定最大分帧数 %%
  transmit_delay(1,1)=max_temp_xcorr_index-compare_bef_index_first_xcorr_thred;
  soundNumber=idivide(int32(size_Channel_signal(1,2)-transmit_delay(1,1)),soundIntervalPot,'floor');  
  soundNumber=double(soundNumber); %发声次数
  %% 精细确定一帧发射位置 %%
  for i=1:soundNumber
     %% 第一帧
      if i==1
         Frame_signal{i}=Channel_signal(transmit_delay(1,1)+1:transmit_delay(1,1)+soundIntervalPot);
         compare_xcorr_index=0;
         for j=transmit_delay(1,1)+1:transmit_delay(1,1)+soundIntervalPot 
             compare_xcorr_index=compare_xcorr_index+1;
             sum_power_origin_data_window=norm(Channel_signal(j:j+template_size(1,2)-1));
             if j+template_size(1,2)-1>size_Channel_signal(1,2)
                break;
             end
             CC=dot(Channel_signal(j:j+template_size(1,2)-1),template_refer);
             temp_xcorr_NCC_array(compare_xcorr_index)=CC/sum_power_origin_data_window/sum_power_template_refer;
             temp_xcorr_CC_array(compare_xcorr_index)=CC;
         end
         %归一化互相关
         Frame_signal_NCC{i}=temp_xcorr_NCC_array;
         %互相关
         Frame_signal_CC{i}=temp_xcorr_CC_array;
         %找到互相关最大值在帧中相对位置
         [max_compare_xcorr,max_compare_xcorr_index]=max(temp_xcorr_CC_array);
         Frame_signal_CC_start_index(i)=max_compare_xcorr_index;
         %对互相关进行包络计算
         Frame_signal_CC_hilbert{i}=abs(hilbert(Frame_signal_CC{i}));
         %将互相关最大值视为距离零点，剔除距离负值
         Frame_signal_CC_hilbert_redue{i}=Frame_signal_CC_hilbert{i}(max_compare_xcorr_index:end);
         clear temp_xcorr_CC_array temp_xcorr_NCC_array;
         thred_xcorr=max_compare_xcorr*0.5;
     %% 后续帧
      else
         if i==4384
             break;
         end
         if size_Channel_signal(1,2)-transmit_delay(1,i-1)-soundIntervalPot<soundIntervalPot*2
            break;
         end
         %确定发射位置
         for j=transmit_delay(1,i-1)+soundIntervalPot+1:size_Channel_signal(1,2)-template_size(1,2)-soundIntervalPot+1 
            CC=dot(Channel_signal(j:j+template_size(1,2)-1),template_refer);
            if CC>thred_xcorr
               %达到CC阈值附近寻找CC最大值，并建立帧
               compare_xcorr_index=0;
               for k=j-floor(template_size(1,2))+1:j+floor(template_size(1,2))-1
                   compare_xcorr_index=compare_xcorr_index+1;
                   temp_xcorr_array(compare_xcorr_index)=dot(Channel_signal(k:k+template_size(1,2)-1),template_refer);
               end
               [max_compare_xcorr,max_compare_xcorr_index]=max(temp_xcorr_array);
               clear temp_xcorr_array;
               max_temp_xcorr_index=max_compare_xcorr_index+j-floor(template_size(1,2))+1-1;
               transmit_delay(1,i)=max_temp_xcorr_index-compare_bef_index_first_xcorr_thred;
               Frame_signal{i}=Channel_signal(transmit_delay(1,i)+1:transmit_delay(1,i)+soundIntervalPot);
               %创建帧中相关运算
               compare_xcorr_index=0;
               for k=transmit_delay(1,i)+1:transmit_delay(1,i)+soundIntervalPot 
                   compare_xcorr_index=compare_xcorr_index+1;
                   sum_power_origin_data_window=norm(Channel_signal(k:k+template_size(1,2)-1));
%                    if j+template_size(1,2)-1>size_Channel_signal(1,2)
%                       break;
%                    end
                   CC=dot(Channel_signal(k:k+template_size(1,2)-1),template_refer);
                   temp_xcorr_NCC_array(compare_xcorr_index)=CC/sum_power_origin_data_window/sum_power_template_refer;
                   temp_xcorr_CC_array(compare_xcorr_index)=CC;
               end        
               %归一化互相关
               Frame_signal_NCC{i}=temp_xcorr_NCC_array;
               %互相关
               Frame_signal_CC{i}=temp_xcorr_CC_array;
               %找到互相关最大值在帧中相对位置
               [~,max_compare_xcorr_index]=max(temp_xcorr_CC_array);
               Frame_signal_CC_start_index(i)=max_compare_xcorr_index;
               %对互相关进行包络计算
               Frame_signal_CC_hilbert{i}=abs(hilbert(Frame_signal_CC{i}));
               %将互相关最大值视为距离零点，剔除距离负值
               Frame_signal_CC_hilbert_redue{i}=Frame_signal_CC_hilbert{i}(max_compare_xcorr_index:end);
               clear temp_xcorr_CC_array temp_xcorr_NCC_array; 
               break;
            end
            
         end
      end
  end
 
 
 
 
 
 
 
 
 
 
 
 
 

end
