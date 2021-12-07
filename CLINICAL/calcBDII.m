function BDIIvars = calcBDII(datain)
data = datain(~isnan(datain));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Coeffecients & Indexes Steer et al (1999) J Clin Psychology
coeflist = [ .46, .10, -.15,  .50, -.03, .02, .00, -.01, .18, .20, .15, .53, .46, .23,  .85, .25,  .38,  .63, .41,  .91, .40;...
             .39, .58,  .71,  .28,  .60, .52, .55,  .64, .44, .35, .24, .24, .25, .56, -.09, .25,  .24, -.10, .30, -.15, .01];
        ncogI = [1 4 10 11 12 13 15 16 17 18 19 20 21];
        cogI  = [2 3 5 6 7 8 9 14];
%   
BDIIvars.total = sum(data);
BDIIvars.cog   = sum(data(cogI).*coeflist(2,cogI)');
BDIIvars.ncog  = sum(data(ncogI).*coeflist(1,ncogI)'); 
end
