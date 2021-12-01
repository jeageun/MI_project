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
    CVMdl = crossval(Mdl);
elseif model_type == "svm_opt"
    Mdl = fitcsvm(tbl,'Y',"Standardize",true,'Cachesize',10000);
    CVMdl = crossval(Mdl);
elseif model_type == "lda"
    Mdl = fitcdiscr(tbl,'Y');
    CVMdl = crossval(Mdl);
elseif model_type == "lda_opt"
    Mdl  = fitcdiscr(tbl,'Y','OptimizeHyperparameters','auto',...
        'HyperparameterOptimizationOptions',...
        struct('AcquisitionFunctionName','expected-improvement-plus','Kfold',5));
    CVMdl = crossval(Mdl);
elseif model_type == "dnn"
    Mdl = fitcnet(tbl,"Y");
    CVMdl = crossval(Mdl);
elseif model_type == "dnn_opt"
    lambda = (0:0.5:5)*1e-4;
    cvloss = zeros(length(lambda),1);
    cvp = cvpartition(tbl.Y,"KFold",5);
    for i = 1:length(lambda)
        cvMdl = fitcnet(tbl,"Y","Lambda",lambda(i), ...
        "CVPartition",cvp,"Standardize",true);
        cvloss(i) = kfoldLoss(cvMdl,"LossFun","classiferror");
    end
    [~,idx] = min(cvloss);
    bestLambda = lambda(idx);
    Mdl = fitcnet(tbl,"Y","Lambda",bestLambda, ...
    "Standardize",true);
    CVMdl = crossval(Mdl);
elseif model_type == "knn_opt"
    Mdl = fitcknn(tbl,'Y','OptimizeHyperparameters','auto',...
        'HyperparameterOptimizationOptions',...
        struct('AcquisitionFunctionName','expected-improvement-plus','Kfold',5));
    CVMdl = crossval(Mdl);
end
    cross_error = kfoldLoss(CVMdl);
    final_model = Mdl;

end



function y = vec_linspace(start, goal, steps)
x = linspace(0,1,steps);

y = start * ones(1, steps) + (goal - start)*x;
end
