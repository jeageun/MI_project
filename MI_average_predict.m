function [predicted_labels] = MI_average_predict(averageA,averageB,features,directory_name)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    rootdir = directory_name;
    filelist = dir(fullfile(rootdir, '**\*.gdf'));  %get list of files and folders in any subfolder
    filelist = filelist(~[filelist.isdir]);  %remove folders from list
    file_count = 0;
    res_struct=struct;
    [flat_data_signal, flat_categories] = MI_signal_processing(directory_name,features,false);
    
    
    
    A_xcorrvalue = xcorr(averageA,flat_data_signal);
    B_xcorrvalue = xcorr(averageB,flat_data_signal);
    

end

