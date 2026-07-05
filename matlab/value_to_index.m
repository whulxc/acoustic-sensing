function [startIndex, endIndex] = value_to_index(array_value, startValue, endValue)
%VALUE_TO_INDEX Convert a numeric value range to inclusive array indices.
%
% The original code selected the first interval that crosses each boundary.
% This version keeps that behavior and adds clear bounds handling.

array_value = array_value(:).';
if isempty(array_value)
    error('array_value must not be empty.');
end
if startValue > endValue
    error('startValue must be less than or equal to endValue.');
end

startIndex = find(array_value <= startValue & [array_value(2:end), inf] > startValue, ...
    1, 'first');
endIndex = find(array_value <= endValue & [array_value(2:end), inf] > endValue, ...
    1, 'first') + 1;

if isempty(startIndex)
    if startValue <= array_value(1)
        startIndex = 1;
    else
        startIndex = numel(array_value);
    end
end

if isempty(endIndex) || endIndex > numel(array_value)
    if endValue <= array_value(1)
        endIndex = 1;
    else
        endIndex = numel(array_value);
    end
end

if endIndex < startIndex
    endIndex = startIndex;
end
end
