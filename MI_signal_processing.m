function [flat_data_signal, flat_categories] = MI_signal_processing(directory_name,selected_features,frequency_domain)

    rootdir = directory_name;
    filelist = dir(fullfile(rootdir, '**\*.gdf'));  %get list of files and folders in any subfolder
    filelist = filelist(~[filelist.isdir]);  %remove folders from list
    file_count = 0;
    res_struct=struct;

    for file_name = [filelist.name ""]
        if file_name == ""
            continue
        end
        %figure();
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

        % From the features that we make before, compute channel and frequency
        % with that, filter out values and save the only selected values on
        % filtered_s
        filters = [mod(selected_features,50)' mod(selected_features,50)'+4];
        filtered_s=zeros(length(filters),length(s));
        for i = 1:length(filters)
            channels = floor(selected_features./50+1);
            N = 5;
            [B, A] = butter(N,[filters(i,:)]*2 / fs);
            s_a = filter(B,A,s);
            filtered_s(i,:) = s_a(:,channels(i))';
        end


        % Basic setup for start end positions and category selections
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
        if frequency_domain
            flat_data_signal=zeros(total_count,50*length(selected_features));
        else
            flat_data_signal=zeros(total_count,513*length(selected_features));
        end
        sig_count = 1;
        for idx = [1:length(end_idx)]  
            jdx = 0; 
            while start_idx(idx)+ jdx + trial_timing < end_idx(idx)
                start = start_idx(idx);
                raw_data = filtered_s(:,start+jdx:min(start+trial_timing+jdx,length(filtered_s')));
                if isnan(raw_data)
                    % When data surges dramatically, filter would not work
                    % correctly. In this case, just ignore that data. If we
                    % could remove this part in previous feature selection
                    % session, data would be better.
                    jdx = jdx+32;
                    continue
                end
                if frequency_domain
                    tmp = [start_idx(idx):32:end_idx(idx)-513]';
                    arr = vec_linspace(tmp,tmp+512,513);
                    raw_data = filtered_s(:,arr');
                    tmp_data = reshape(raw_data,5,513,[]);
                    pout = pwelch(permute(tmp_data, [2 1 3]),fs)';
                    
                    %pwelch(permute(tmp_data, [2 1 3]),fs)
                    pout = pout(:,1:50);
                    p_result = reshape(permute(pout,[2,1]),length(selected_features)*50,[])';
                    flat_data_signal(sig_count:sig_count+size(arr,1)-1,:) = p_result;
                    categories_extend(sig_count:sig_count+size(arr,1)-1) = categories(idx);
                    jdx = jdx+32;
                    sig_count = sig_count+size(arr,1);
                    break;
                else
                    tmp = [start_idx(idx):32:end_idx(idx)-513]';
                    arr = vec_linspace(tmp,tmp+512,513);
                    raw_data = filtered_s(:,arr');
                    tmp_data = reshape(raw_data,5,513,[]);
                    ttmp_data = reshape(permute(tmp_data, [2 1 3]),[],size(arr,1));
                    flat_data_signal(sig_count:sig_count+size(arr,1)-1,:) = ttmp_data';
                    categories_extend(sig_count:sig_count+size(arr,1)-1) = categories(idx);
                    sig_count = sig_count+size(arr,1);
                    break;
                end
                
            end        
        end

        % remove all zero rows from the data
        flat_data_signal( all(~flat_data_signal,2), : ) = [];
        categories_extend( all(~categories_extend,2), : ) = [];

        res_struct.(strcat('X',num2str(file_count)))= flat_data_signal;
        res_struct.(strcat('Y',num2str(file_count)))=categories_extend;    
    end

    file_count = 0;
    flat_data_signal = [];
    flat_categories = [];



    for file_name = [filelist.name ""]
        if file_name == ""
            continue
        end
        file_count = file_count +1;
        flat_data_signal = [flat_data_signal;res_struct.(strcat('X',num2str(file_count)))];
        flat_categories = [flat_categories;res_struct.(strcat('Y',num2str(file_count)))];    
    end
    if length(unique(flat_categories))>2
        % There is a case of rlhb but rhbf prediction. See ES31OS case.
        flat_data_signal = flat_data_signal(flat_categories>769,:);
        flat_categories = flat_categories(flat_categories>769);
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
        x;
  end
end

function y = vec_linspace(start, goal, steps)
x = linspace(0,1,steps);

y = start * ones(1, steps) + (goal - start)*x;
end
