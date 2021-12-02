function [] = MI_Class_draw(directory_name,features,granularity_Hz)
    
[flat_data_signal, flat_categories] = MI_signal_processing(directory_name,features,false,true);
names = split(directory_name,'\');

frequency = mod(features,50);
res = reshape(flat_data_signal,size(flat_data_signal,1),513,[]);
cat_set = unique(flat_categories);

gavgA = reshape(mean(res(flat_categories==cat_set(1) ,:,:),1),513,[])';
gavgB = reshape(mean(res(flat_categories==cat_set(2) ,:,:),1),513,[])';

psd_A = pwelch(gavgA',512)';
psd_B = pwelch(gavgB',512)';

psd_A = movsum(psd_A,[0,granularity_Hz-1]);
psd_B = movsum(psd_B,[0,granularity_Hz-1]);

load('chanlocs16.mat');
freq_list = [];
for i=1:length(frequency)
    if any(frequency(i) == freq_list)
        continue
    end
        
    figure()
    sgtitle(names(end-1) + ' Offline PSD with ' + num2str(frequency(i)) + '-' + num2str(frequency(i)+granularity_Hz-1) + 'Hz');
    subplot(1,2,1)
    title(cat_set(1));
    topoplot(psd_A(17*(i-1)+1:17*i,frequency(i)),chanlocs16 );
    subplot(1,2,2)
    title(cat_set(2));
    topoplot(psd_B(17*(i-1)+1:17*i,frequency(i)),chanlocs16 );
    freq_list = [freq_list frequency(i)];
end



end



function y = vec_linspace(start, goal, steps)
x = linspace(0,1,steps);

y = start * ones(1, steps) + (goal - start)*x;
end
