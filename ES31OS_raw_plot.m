rootdir = 'C:\Users\Haiyun_Zhang\Documents\GitHub\MI_project\ES31OS\Offline';
filelist = dir(fullfile(rootdir, '**\*.gdf'));
filelist = filelist(~[filelist.isdir]);  %remove folders from list

for file_name = [filelist.name ""]
    if file_name == ""
        continue
    end
    fileName = convertStringsToChars(fullfile(rootdir,file_name));
    [s,h]=sload([fileName]);
    type = h.EVENT.TYP;
    pos = h.EVENT.POS;
    start_idx = pos(type == 769| type == 770| type == 771);
 
    for i=1:16
        figure();
        plot(0:1/512:(length(s)-1)/512,s(:,i));
        hold on
        tx = [(start_idx-1).'/512; (start_idx-1).'/512;nan(1,length(start_idx))];
        ty = [zeros(1,length(start_idx)); 500*ones(1,length(start_idx)); nan(1,length(start_idx))];
        plot(tx(:),ty(:))
        legend('Raw EEG', 'Trigger')
        title("ES31OS Offline"+" "+file_name+" Channel "+i);
        xlabel("Time second")
        ylabel("EEG raw signal uV")
        hold off
    end
end