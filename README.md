# MI_project

##Main function;
project.mlx
You need to change your project directory.
1. Put all MITraining on this directory.
2. Launch `eeglab` for topoplot and `install` for sload
3. Change the root directory


API (Function)
`output = MI_2d_best(fn);`
output has 5 best selected features. If you want to change feature selection, please modify this.
fn means file name. How to organize it? look at project.mlx

`[outputA, outputB] = MI_grand_average(fn,res(k,:));`
outputA and outputB is your output of grand average for class A and class B. 
res means the output of MI_2d_best function. You have to generate or keep res value before you launch this. 
res = [n x 5] matrix. element should be in range of (1~850)

`[cross_error, model] = MI_Train(fn,res(k,:),true,'lda');`
MI training. Currently support lda and svm. True means frequency domain pattern matching. It converts values into frequency domain and compare. You have to use True for now. It doesn't support for false yet.

` [flat_data_signal, flat_categories] = MI_signal_processing(directory_name,selected_features,frequency_domain)`
Get the signals of selected features. If you want to get frequency domain features, give frequency_domain as true



