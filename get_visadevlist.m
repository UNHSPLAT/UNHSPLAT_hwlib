function resourcelist = get_visadevlist()
    %function to errorcatch empty visadevlist (useful for at home development)
    try
        resourcelist = visadevlist;
    catch    
        resourcelist = table([],[],[],[],[],[],...
                    'VariableNames',["ResourceName","Alias","Vendor","Model","SerialNumber","Type"]);%
    end
end