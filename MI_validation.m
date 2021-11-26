function [outputArg1,outputArg2] = MI_validation(directory_name,features,models)
%MI_VALIDATION Summary of this function goes here
%   Detailed explanation goes here
[flat_data_signal, flat_categories] = MI_signal_processing(directory_name,features,true);
names=split(directory_name,'\');

[labelIdx,score] = predict(models.(names(end-1)),flat_data_signal);



outputArg1 = inputArg1;
outputArg2 = inputArg2;
end

