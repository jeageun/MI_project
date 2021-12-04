% Initialization.
% You need to change root directory for your case.

rootdir = 'C:\Users\Haiyun_Zhang\Documents\GitHub\MI_project\MITraining';
filelist = dir(fullfile(rootdir,"*","*","*"));  %get list of files and folders in any subfolder
filelist = filelist([filelist.isdir]);  %folders from list
filelist = filelist ( [filelist.name, " "] == "Offline" | [filelist.name, " "] == "S2" | [filelist.name, " "] == "S3"  );
filelist = [[filelist.folder ""];[filelist.name ""]]';
%%
chls=['CP2', 'FC1', 'Fz', 'CP4', 'FCz',...
    'FC3', 'C2', 'CP1', 'FC1', 'C3',...
    'CP4','C3','C1','CP3', 'C4',...
    'C3', 'C1', 'CP3', 'CP1', 'Cz',""];
granularity_Hz = [7, 11, 7, 11, 23, 27, 7, 11, 7, 11;...
    24, 28, 26, 30, 6, 10, 24, 28, 26, 30;...
    18, 22, 23, 27, 24, 28, 22, 26, 17, 21;...
    8, 12, 17, 21, 7, 11, 17, 21, 24, 27];
load("chanlocs16.mat")
ind=1;
for k=1:length(filelist)-1
    fn=fullfile(filelist(k,1), filelist(k,2));
    names = split(fn,'\');
    if names(end) == "Offline"
        MI_fisher_scores(fn,granularity_Hz(ind,:),chls(1+5*(ind-1):5+5*(ind-1)),chanlocs16);
        ind = ind +1;
    end
end 