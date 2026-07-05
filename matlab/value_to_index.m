function [startIndex,endIndex]=value_to_index(Array,startValue2index,endValue2index)
    size_Array=size(Array); %频率
    for i=1:size_Array(1,2)-1
    if (Array(i)<=startValue2index&&Array(i+1)>startValue2index)
          startIndex=i;
          break;
    end
    end
    for i=1:size_Array(1,2)-1
        if (Array(i)<=endValue2index&&Array(i+1)>endValue2index)
            endIndex=i+1;
          break;
       end
    end
end
