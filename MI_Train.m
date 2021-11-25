function [cross_error, final_model] = MI_Train(directory_name,features,frequency_domain,model_type)
    
[flat_data_signal, flat_categories] = MI_signal_processing(directory_name,features,frequency_domain);

tbl = array2table(flat_data_signal);
tbl.Y = flat_categories;
if model_type == "svm"
    Mdl = fitcsvm(tbl,'Y');
    CVMdl = crossval(Mdl,{'kfold', 5,'stratify',false});
elseif model_type == "lda"
    Mdl = fitcdiscr(tbl,'Y');
    CVMdl = crossval(Mdl,{'kfold', 5,'stratify',false});
elseif model_type == "qda"
    Mdl = fitcdiscr(tbl,'Y','CVPartition');
    CVMdl = crossval(Mdl,{'kfold', 5,'stratify',false});
end
cross_error = kfoldLoss(CVMdl);
final_model = Mdl;

end

