function [outputArg1,outputArg2] = MI_validation(directory_name,features,models)
%MI_VALIDATION Summary of this function goes here
%   Detailed explanation goes here
[flat_data_signal, ~] = MI_signal_processing(directory_name,features,true);

names=split(directory_name,'\');

frequency = mod(features,50);
base = 0:50:200;
tmp = base+frequency;
selected = vec_linspace(tmp',tmp'+4,5);
selected = reshape(selected',1,[]);

[Pre_label,~] = predict(models.(names(end-1)),flat_data_signal(:,selected));

rootdir = directory_name;
filelist = dir(fullfile(rootdir, '**\*.gdf'));  %get list of files and folders in any subfolder
filelist = filelist(~[filelist.isdir]);  %remove folders from list

total_pred = [];
total_cat =[];

count_pre_sample=0;
for file_name = [filelist.name ""]
    if file_name == ""
        continue
    end
    
    file_name = convertStringsToChars(fullfile(rootdir,file_name));
    [s,h]=sload([file_name]);
    type = h.EVENT.TYP;
    pos = h.EVENT.POS;
    type_verbose = arrayfun(@(x) labeling(x),type);
    fs = h.SampleRate;
    t = [1:length(s)]./fs;
    % For entire data...
    % Frequency = fs ==> Max frequency means 256Hz.
    
    % Basic setup for start end positions and category selections
    trial_timing = 512;
    
    start_idx = pos(type_verbose=="Both Feet" | type_verbose=="Left hand" | type_verbose=="Right hand");
    end_idx = pos(or(type_verbose=="Hit",type_verbose=="Miss"));
    categories = type((type >= 769)&(type <= 771) );
    
    if (isempty(end_idx))
        end_idx = ones(length(start_idx))*512*5+start_idx;
    end
    
    cat_set = unique(categories);
    pre_cat_trial = zeros(length(start_idx),1);
    len_trials = 0;
    for idx = [1:length(end_idx)]
        jdx = 0;
        accum_poss = 0;
        tmp = [start_idx(idx):32:end_idx(idx)-513]';
        count_pre_sample = len_trials;
        while start_idx(idx)+ jdx + trial_timing < end_idx(idx)
            count_pre_sample = count_pre_sample + 1;
            jdx = jdx+32;
            accum_poss = accum_poss + (cat_set == Pre_label(count_pre_sample));
            difference = accum_poss(1) - accum_poss(2);
            if difference > 15 
                pre_cat_trial(idx) = cat_set(1);
                break;
            elseif difference < -15
                pre_cat_trial(idx) = cat_set(2);
                break;
            end         
        end
        if pre_cat_trial(idx) == 0
            pre_cat_trial(idx) = 999;
        end
        len_trials = len_trials + length(tmp);

    end
    
    %sum(pre_cat_trial == categories)/length(categories);
    total_pred = [total_pred; pre_cat_trial];
    total_cat = [total_cat; categories];
    

end

perc_r = sum(total_pred == total_cat)/ length(total_cat)* 100;                        %Correctness
perc_w = sum(and(total_pred ~= 999,total_pred ~= total_cat))/ length(total_cat)* 100; %Incorrectness
perc_u = sum(total_pred == 999)/ length(total_cat)* 100;                              %Unknow
disp(names(end-1)+' ' + names(end) + ' Correctness '+ perc_r +'% Incorrectness '+ perc_w + '% Unknown' + perc_u + '%');
outputArg1 = total_pred';
outputArg2 = total_cat';
end


function res = labeling(x)
switch x
    case 1
        res = "Trial start";
    case 786
        res = "Fixation";
    case 769
        res = "Left hand";
    case 770
        res = "Right hand";
    case 771
        res = "Both Feet";
    case 781
        res = "Bar start moving";
    case 783
        res = "Rest MI";
    case 897
        res = "Hit";
    case 898
        res = "Miss";
    otherwise
        res = "WHATHAPPEN";
        
end
end
function y = vec_linspace(start, goal, steps)
x = linspace(0,1,steps);

y = start * ones(1, steps) + (goal - start)*x;
end