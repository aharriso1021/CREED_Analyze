function FATGvars = calcFATG(datain)
FATGvars.Pre = nansum(datain(:,1));
FATGvars.Mid = nansum(datain(:,2));
FATGvars.Pst = nansum(datain(:,3));
end