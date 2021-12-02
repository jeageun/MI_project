function [maxIndex] = MI_2d_best(directory_name,granularity_Hz)
% This function will get fisher score with stationary result. 
% It measure the fisher score in one session (Online or offline). When we
% call the function with online/offline directory, there are several gdf
% files. In this, 

rootdir = directory_name;
filelist = dir(fullfile(rootdir, '**\*.gdf'));  %get list of files and folders in any subfolder
filelist = filelist(~[filelist.isdir]);  %remove folders from list
total_count=0;
score_result=zeros(length(filelist),850);
file_count = 0;
for file_name = [filelist.name ""]
    if file_name == ""
        continue
    end
    file_count = file_count+1;
    file_name = convertStringsToChars(fullfile(rootdir,file_name));
    [s,h]=sload([file_name]);
    type = h.EVENT.TYP;
    pos = h.EVENT.POS;
    type_verbose = arrayfun(@(x) labeling(x),h.EVENT.TYP);
    fs = h.SampleRate;
    t = [1:length(s)]./fs;
    % For entire data...
    % Frequency = fs ==> Max frequency means 256Hz.

    % USE CAR to filtering
    s = s - mean(s(:,1:16),2);
    s(:,17)=0;
    
    start_idx = pos(type_verbose=="Both Feet" | type_verbose=="Left hand" | type_verbose=="Right hand");

    MI_Class = [769, 770, 771];
    trial_timing = 512;

    start_idx = pos(type_verbose=="Both Feet" | type_verbose=="Left hand" | type_verbose=="Right hand");
    end_idx = pos(or(type_verbose=="Hit",type_verbose=="Miss")); 
    categories = type((type >= 769)&(type <= 771) );
    if (isempty(end_idx))
        end_idx = ones(length(start_idx))*512*5+start_idx;
    end
    total_count = 0;
    for idx = [1:length(end_idx)]      
        jdx = 0;
        while start_idx(idx)+ jdx + trial_timing < end_idx(idx)
            total_count = total_count + 1;
            jdx = jdx+32;
        end
    end
    
    categories_extend = zeros(total_count,1);
    flat_features=zeros(total_count,850);
    
    
    sampling_trials=1;
    for idx = [1:length(end_idx)]  
        jdx = 0; 
        while start_idx(idx)+ jdx + trial_timing < end_idx(idx)
            start = start_idx(idx);
            raw_data = s(start+jdx:min(start+trial_timing+jdx,length(s)),:);
            features = pwelch(raw_data,fs);
            % remove from 1~4Hz part... It is too large and so many noise
            features(1:5,:)=1e-12;
            % granularity of 5Hz, start with current hz to current + 4 Hz
            features = movsum(features,[0,4]);
            flat_features(sampling_trials,:) = reshape(features(1:50,:),1,[]);
            categories_extend(sampling_trials) = categories(idx);
            jdx = jdx+32;
            sampling_trials = sampling_trials+1;
        end        
    end
    
    %%%
    %score_tmp = feature_rank_project(flat_features,categories_extend); 
    %score_tmp = reshape(score_tmp,50,[]);
    %score_tmp(1:5,:)=0;
    %score_tmp = reshape(score_tmp,1,[]);
    %score_result(file_count,:) = score_tmp;
    %%%
    tmp_cat = categories_extend;
    cat_set = unique(categories_extend);
    tmp_cat(categories_extend==cat_set(1)) = 1;
    tmp_cat(categories_extend==cat_set(2)) = -1;
    d=data(flat_features,tmp_cat);
    a=fisher;a.feat=850; a.output_rank=2;[r,a]=train(a,d);
    
    %remove first five frequency coefficients
    score_tmp = a.w;
    score_tmp = reshape(score_tmp,50,[]);
    score_tmp(1:5,:)=0;
    score_tmp = reshape(score_tmp,1,[]);
    score_result(file_count,:) = score_tmp;
end

[~, sortIndex] = sort(score_result', 'descend');
X = reshape(sortIndex(1:20,:),1,[]);
uniqueX = unique(X);
countOfX = hist(X,uniqueX);
indexToRepeatedValue = (countOfX>=3);
repeatedly_large_idx = uniqueX(indexToRepeatedValue);

reward_value = sum(score_result);
reward_value(repeatedly_large_idx) = reward_value(repeatedly_large_idx) + 0.3;

indexToRepeatedValue = (countOfX>=2);
repeatedly_large_idx = uniqueX(indexToRepeatedValue);
reward_value(repeatedly_large_idx) = reward_value(repeatedly_large_idx) + 0.1;

%Find using moving sum of reward value.
%We need this for this case;
%Feature number | score
% 707 0.4
% 708 0.5
% 709 0.8
% 710 1.1
% 711 1.4
% 712 0.1
% 713 0.0 
% 714 0.0
% 715 0.1 ...
% We want to choose 707, not 711 as a feature. Since 711 will choose
% 711-715 as Features.
reward_value = movsum(reward_value,[0,granularity_Hz-1]);
%mdl = fscnca(flat_features,categories_extend,'Solver','sgd','Verbose',1,'MiniBatchSize',64,'IterationLimit',200,'NumTuningIterations',15);

figure()
plot(reward_value,'ro')
grid on
xlabel('Feature index')
ylabel('Feature weight')
figure()

scores = reshape(reward_value,50,[]);
heatmap(scores','GridVisible','off'),colormap(hot)
[~, sortIndex] = sort(reward_value, 'descend');
maxIndex = [sortIndex(1)];
idx = 1;
while length(maxIndex) < 10
    idx = idx + 1;
    cond = ( (mod(sortIndex(idx),50) > mod(maxIndex,50)-(granularity_Hz-1) ) & ...
        (floor(sortIndex(idx)/50))==(floor(maxIndex./50)) ) | ...
       ( (mod(sortIndex(idx),50) < mod(maxIndex,50)+(granularity_Hz-1) ) & ...
        (floor(sortIndex(idx)/50))==(floor(maxIndex./50)) ) | ...
        mod(sortIndex(idx),50) > 40 | mod(sortIndex(idx),50) <(granularity_Hz-1);
    if ~all(~cond)
       continue
    end
    maxIndex(end+1) = sortIndex(idx);
end
xlabel('Frequency')
ylabel('Channel')
load('chanlocs16.mat');
frequency = unique(mod(maxIndex,50));
names = split(rootdir,'\');

% Which one should we use to discriminate A and B
for idx = 1:length(frequency)
    figure()
    freq = frequency(idx);
    tmp_rewards = reward_value(freq:50:850);
    topoplot(tmp_rewards,chanlocs16);
    title(names(end-1) + names(end) +" " +num2str(freq) +"Hz Discriminant power and Actual power");
end


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
        x
  end
end

