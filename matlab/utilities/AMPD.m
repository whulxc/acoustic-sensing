function [locs] = AMPD(data)
    p_data = zeros(size(data),'like',data);
    count = length(data);
    arr_rowsum = [];
    c=mod(count,2); %取余
    d=(count-c)/2; %取商
    for k = 1:d
        row_num = 0;
        for i = k:count-k-1
            if data(i+1) > data(i-k+1) && data(i+1) > data(i+k+1)
                row_num = row_num - 1;
            end
        end
        arr_rowsum = [arr_rowsum,row_num];
    end
    mm = min(arr_rowsum);
    min_index = find(arr_rowsum == mm);
    max_window_length = min_index;
    for k = 1:max_window_length
        for i = k:count-k-1
            if data(i+1) > data(i-k+1) && data(i+1) > data(i+k+1)
                p_data(i+1) = p_data(i+1) + 1;
            end
        end
    end
    locs = find(p_data == max_window_length);
end
