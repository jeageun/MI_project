function [cross_error, final_model] = MI_Train(directory_name,features,frequency_domain,model_type,granularity_Hz)
    
[flat_data_signal, flat_categories] = MI_signal_processing(directory_name,features,frequency_domain,granularity_Hz);

frequency = mod(features,50);
base = 0:50:50*(length(features)-1);
tmp = base+frequency;
selected = vec_linspace(tmp',tmp'+granularity_Hz-1,granularity_Hz);
selected = reshape(selected',1,[]);
tbl = array2table(flat_data_signal(:,selected));
tbl.Y = flat_categories;

fold_size= 5;
CVMdl = struct;
test_fset = struct;
subset_tbl= MI_kfolds_sequential(tbl,fold_size);
train_set = table;


if model_type == "svm"
    Mdl = fitcsvm(tbl,'Y');
    for i = 1:fold_size
        setnumbers = 1:fold_size;
        train_setnumbers = setnumbers(setnumbers~=i);
        for j =1:length(train_setnumbers)
            train_set = [train_set ; subset_tbl{train_setnumbers(j)}];
        end
        test_fset.("X"+num2str(i)) = subset_tbl{i};
        CVMdl.("X"+num2str(i)) = fitcsvm(train_set,'Y');
    end
elseif model_type == "svm_opt"
    Mdl = fitcsvm(tbl,'Y',"Standardize",true,'Cachesize',10000);
    for i = 1:fold_size
        setnumbers = 1:fold_size;
        train_setnumbers = setnumbers(setnumbers~=i);
        for j =1:length(train_setnumbers)
            train_set = [train_set ; subset_tbl{train_setnumbers(j)}];
        end
        test_fset.("X"+num2str(i)) = subset_tbl{i};
        CVMdl.("X"+num2str(i)) = fitcsvm(train_set,'Y',"Standardize",true,'Cachesize',10000);
    end
elseif model_type == "lda"
    Mdl = fitcdiscr(tbl,'Y');
    for i = 1:fold_size
        setnumbers = 1:fold_size;
        train_setnumbers = setnumbers(setnumbers~=i);
        for j =1:length(train_setnumbers)
            train_set = [train_set ; subset_tbl{train_setnumbers(j)}];
        end
        test_fset.("X"+num2str(i)) = subset_tbl{i};
        CVMdl.("X"+num2str(i)) = fitcdiscr(train_set,'Y');
    end
elseif model_type == "lda_opt"
    Mdl  = fitcdiscr(tbl,'Y','OptimizeHyperparameters','auto',...
        'HyperparameterOptimizationOptions',...
        struct('AcquisitionFunctionName','expected-improvement-plus'));
    for i = 1:fold_size
        setnumbers = 1:fold_size;
        train_setnumbers = setnumbers(setnumbers~=i);
        for j =1:length(train_setnumbers)
            train_set = [train_set ; subset_tbl{train_setnumbers(j)}];
        end
        test_fset.("X"+num2str(i)) = subset_tbl{i};
        CVMdl.("X"+num2str(i)) = fitcdiscr(train_set,'Y','OptimizeHyperparameters','auto',...
        'HyperparameterOptimizationOptions',...
        struct('AcquisitionFunctionName','expected-improvement-plus'));
    end
elseif model_type == "dnn"
    Mdl = fitcnet(tbl,"Y");
    for i = 1:fold_size
        setnumbers = 1:fold_size;
        train_setnumbers = setnumbers(setnumbers~=i);
        for j =1:length(train_setnumbers)
            train_set = [train_set ; subset_tbl{train_setnumbers(j)}];
        end
        test_fset.("X"+num2str(i)) = subset_tbl{i};
        CVMdl.("X"+num2str(i)) = fitcnet(train_set,"Y");
    end
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
    for i = 1:fold_size
        setnumbers = 1:fold_size;
        train_setnumbers = setnumbers(setnumbers~=i);
        for j =1:length(train_setnumbers)
            train_set = [train_set ; subset_tbl{train_setnumbers(j)}];
        end
        test_fset.("X"+num2str(i)) = subset_tbl{i};
        CVMdl.("X"+num2str(i)) = fitcnet(train_set,"Y","Lambda",bestLambda, ...
    "Standardize",true);
    end
end
    cross_error = 0;
    for i = 1:fold_size
        cross_error = cross_error + loss(CVMdl.("X"+num2str(i)),test_fset.("X"+num2str(i)),"Y");
    end
    cross_error = cross_error/fold_size;
    final_model = Mdl;

end



function y = vec_linspace(start, goal, steps)
x = linspace(0,1,steps);

y = start * ones(1, steps) + (goal - start)*x;
end
