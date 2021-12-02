function [grandavgA,grandavgB] = MI_grand_average(directory_name,features,granularity_Hz)

rootdir = directory_name;
filelist = dir(fullfile(rootdir, '**\*.gdf'));  %get list of files and folders in any subfolder
filelist = filelist(~[filelist.isdir]);  %remove folders from list


[flat_data_signal, flat_categories] = MI_signal_processing(directory_name,features,false,granularity_Hz,false);

cat_set = unique(flat_categories);
A_DATA=flat_data_signal(flat_categories==cat_set(1),:);
B_DATA=flat_data_signal(flat_categories==cat_set(2),:);
A_ALL=reshape(A_DATA,size(A_DATA,1),[],length(features));
B_ALL=reshape(B_DATA,size(B_DATA,1),[],length(features));
grandavgA = reshape(mean(A_ALL),[],length(features));
grandavgB = reshape(mean(B_ALL),[],length(features));

%Print out Values
filters = [mod(features,50)' mod(features,50)'+granularity_Hz-1];
channels = floor(features./50+1);
figure()
plot(grandavgA);
names = split(rootdir,'\');
title('Grand Average with ' + names(end-1) + ' ' + names(end),cat_set(1))
legend(strcat("Frequency ",num2str(filters)) + strcat("Hz Channel ",num2str(channels')))
xlabel('time(msec)')
ylabel('Signal(uV)')
ylim([min([grandavgA, grandavgB],[],'all'),max([grandavgA, grandavgB],[],'all')]);
figure()
plot(grandavgB);
title('Grand Average with ' + names(end-1) + ' ' + names(end),cat_set(2))
legend(strcat("Frequency ",num2str(filters)) + strcat("Hz Channel ",num2str(channels')))
xlabel('time(msec)')
ylabel('Signal(uV)')
ylim([min([grandavgA, grandavgB],[],'all'),max([grandavgA, grandavgB],[],'all')]);

end


