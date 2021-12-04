function MI_fisher_scores(directory_name,granularity_Hz,chls,chl16)
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
%load('chanlocs16.mat');
best_chl = [find([chl16.labels,""] == chls(1)),...
    find([chl16.labels,""] == chls(2)),... 
    find([chl16.labels,""] == chls(3)),...
    find([chl16.labels,""] == chls(4)),...
    find([chl16.labels,""] == chls(5))]; 


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
    cat=unique(categories);
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
    
    sampling_trials=1;
    categories_extend = zeros(total_count,1);
    psd = zeros(5, total_count);
    for idx = [1:length(end_idx)]  
        jdx = 0; 
        while start_idx(idx)+ jdx + trial_timing < end_idx(idx)
            start = start_idx(idx);
            raw_data = s(start+jdx:min(start+trial_timing+jdx,length(s)),best_chl);
            features = pwelch(raw_data,fs);
            
 
            % granularity of 5Hz, start with current hz to current + 4 Hz
            psd(:,sampling_trials) = [sum(features(granularity_Hz(1):granularity_Hz(2),1)),...
               sum(features(granularity_Hz(3):granularity_Hz(4),2)),... 
               sum(features(granularity_Hz(5):granularity_Hz(6),3)),...
               sum(features(granularity_Hz(7):granularity_Hz(8),4)),...
               sum(features(granularity_Hz(9):granularity_Hz(10),5))];

            categories_extend(sampling_trials) = categories(idx);
            jdx = jdx+32;
            sampling_trials = sampling_trials+1;
        end        
    end
    names = split(file_name,'\');
    figure()
    psd_c1=[];
    for i = 1:5
        tmp_psd = psd(i,:);
        psd_c1 = [psd_c1; tmp_psd(categories_extend==cat(1))];           
    end
    boxplot(psd_c1',{"["+granularity_Hz(1)+","+granularity_Hz(2)+"]Hz"+chls(1),...
        "["+granularity_Hz(3)+","+granularity_Hz(4)+"]Hz"+chls(2),...
        "["+granularity_Hz(5)+","+granularity_Hz(6)+"]Hz"+chls(3),...
        "["+granularity_Hz(7)+","+granularity_Hz(8)+"]Hz"+chls(4),...
        "["+granularity_Hz(9)+","+granularity_Hz(10)+"]Hz"+chls(5)}) 
    title(names(end)+"Cat1")
    hold off
    
    figure()
    psd_c2=[];
    for i = 1:5
        tmp_psd = psd(i,:);
        psd_c2 = [psd_c2; tmp_psd(categories_extend==cat(2))]; 
    end
    boxplot(psd_c2',{"["+granularity_Hz(1)+","+granularity_Hz(2)+"]Hz"+chls(1),...
        "["+granularity_Hz(3)+","+granularity_Hz(4)+"]Hz"+chls(2),...
        "["+granularity_Hz(5)+","+granularity_Hz(6)+"]Hz"+chls(3),...
        "["+granularity_Hz(7)+","+granularity_Hz(8)+"]Hz"+chls(4),...
        "["+granularity_Hz(9)+","+granularity_Hz(10)+"]Hz"+chls(5)})
    title(names(end)+"Cat2")
    hold off
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

end
