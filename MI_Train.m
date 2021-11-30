function [cross_error, final_model] = MI_Train(directory_name,features,frequency_domain,model_type)
    
[flat_data_signal, flat_categories] = MI_signal_processing(directory_name,features,frequency_domain);

frequency = mod(features,50);
base = 0:50:200;
tmp = base+frequency;
selected = vec_linspace(tmp',tmp'+4,5);
selected = reshape(selected',1,[]);
tbl = array2table(flat_data_signal(:,selected));
tbl.Y = flat_categories;
if model_type == "svm"
    Mdl = fitcsvm(tbl,'Y');
    %CVMdl = crossval(Mdl);
elseif model_type == "lda"
    Mdl = fitcdiscr(tbl,'Y');
    CVMdl = crossval(Mdl);
elseif model_type == "qda"
    Mdl = fitcdiscr(tbl,'Y');
    CVMdl = crossval(Mdl);
end
%cross_error = kfoldLoss(CVMdl);
cross_error=0;
final_model = Mdl;

end


function y = vec_linspace(start, goal, steps)
x = linspace(0,1,steps);

y = start * ones(1, steps) + (goal - start)*x;
end
