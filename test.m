predict_cat=[]; real_cat=[];
for k=1:length(filelist)-1
    fn=fullfile(filelist(k,1), filelist(k,2));
    % MI_grand_average will return the grand average of top features. It is
    % based on previous result, "res".
    names = split(fn,'\');
    if names(end) == "Offline"
        continue
    end
    [output_pre_cat, output_real_cat]=MI_validation(fn,res(k,:),models);
    predict_cat = [predict_cat, output_pre_cat];
    real_cat = [real_cat, output_real_cat];
end 