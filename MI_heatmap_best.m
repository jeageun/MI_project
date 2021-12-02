function [maxIndex] = MI_heatmap_best(directory_name)

rootdir = directory_name;
filelist = dir(fullfile(rootdir, '**\*.gdf'));  %get list of files and folders in any subfolder
filelist = filelist(~[filelist.isdir]);  %remove folders from list
total_count=0;

for file_name = [filelist.name ""]
    if file_name == ""
        continue
    end
    file_name = convertStringsToChars(fullfile(rootdir,file_name));
    [s,h]=sload([file_name]);
    type = h.EVENT.TYP;
    pos = h.EVENT.POS;
    type_verbose = arrayfun(@(x) labeling(x),h.EVENT.TYP);
    fs = h.SampleRate;
    t = [1:length(s)]./fs;

    % For entire data...
    % Frequency = fs ==> Max frequency means 256Hz.

    start_idx = pos(type_verbose=="Both Feet" | type_verbose=="Left hand" | type_verbose=="Right hand");

    MI_Class = [769, 770, 771];
    trial_timing = 512;

    start_idx = pos(type_verbose=="Both Feet" | type_verbose=="Left hand" | type_verbose=="Right hand");
    end_idx = pos(or(type_verbose=="Hit",type_verbose=="Miss")); 
    categories = type((type >= 769)&(type <= 771) );
    if (isempty(end_idx))
        end_idx = ones(length(start_idx))*512*5+start_idx;
    end

    for idx = [1:length(end_idx)]  
        jdx = 0;
        while start_idx(idx)+ jdx + trial_timing < end_idx(idx)
            total_count= total_count+1;
            jdx = jdx+32;
        end
    end
    if total_count ==0
       maxIndex = zeros(5,1);
       return  
    end
end
   
categories_extend = zeros(total_count,1);
flat_features=zeros(total_count,850);

total_count=1;

for file_name = [filelist.name ""]
    if file_name == ""
        continue
    end
    file_name = convertStringsToChars(fullfile(rootdir,file_name));
    [s,h]=sload([file_name]);
    
    type = h.EVENT.TYP;
    pos = h.EVENT.POS;
    type_verbose = arrayfun(@(x) labeling(x),h.EVENT.TYP);
    fs = h.SampleRate;
    t = [1:length(s)]./fs;

    % For entire data...
    % Frequency = fs ==> Max frequency means 256Hz.

    start_idx = pos(type_verbose=="Both Feet" | type_verbose=="Left hand" | type_verbose=="Right hand");

    MI_Class = [769, 770, 771];
    trial_timing = 512;

    start_idx = pos(type_verbose=="Both Feet" | type_verbose=="Left hand" | type_verbose=="Right hand");
    end_idx = pos(or(type_verbose=="Hit",type_verbose=="Miss")); 
    categories = type((type >= 769)&(type <= 771) );
    if (isempty(end_idx))
        end_idx = ones(length(start_idx))*512*5+start_idx;
    end

    for idx = [1:length(end_idx)]  
        jdx = 0;
        while start_idx(idx)+ jdx + trial_timing < end_idx(idx)
            start = start_idx(idx);
            raw_data = s(start+jdx:min(start+trial_timing+jdx,length(s)),:);
            features = pwelch(raw_data,fs);
            % remove from 1~4Hz part... It is too large and so many noise
            features(1:5,:)=0;
            flat_features(total_count,:) = reshape(features(1:50,:),1,[]);
            categories_extend(total_count,:) = categories(idx);
            jdx = jdx+32;
            total_count = total_count+1;
        end
    end
end 
score_result = feature_rank(flat_features,categories_extend);
%mdl = fscnca(flat_features,categories_extend,'Solver','sgd','Verbose',1,'MiniBatchSize',64,'IterationLimit',200,'NumTuningIterations',15);

figure()
plot(score_result,'ro')
grid on
xlabel('Feature index')
ylabel('Feature weight')
figure()

scores = reshape(score_result,50,[]);
heatmap(scores','GridVisible','off'),colormap(hot)
[~, sortIndex] = sort(score_result, 'descend');
maxIndex = sortIndex(1:5);
xlabel('Frequency')
ylabel('Channel')
% Good features 
% channel 2,9Hz
% Channel 12, 11Hz
% Channel 7, 34Hz

% Random fetures
% Channel 9, 23Hz
% Channel 3, 44Hz

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

