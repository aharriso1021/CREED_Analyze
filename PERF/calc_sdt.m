function table_out = calc_sdt(table_in, h, f, LLh, LLf)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                              Calculates Signal Detection Variables                                 % 
%               [Stanislaw & Todorov Behav Res Methods, Instruments, & Comp (1999)]                  %
%         Assumes LOGLINEAR corrections are used for measures impacted by EXTREME HR & FR            %
% INPUT:                                                                                             %
% h = hit rate                                                                                       %
% f = false alarm rate                                                                               %
% LLh = LogLinear corrected hit rate                                                                 %
% LLf = LogLinear corrected false alarm rate                                                         %
% OUTPUT:                                                                                            % 
% dprime  [d']: sensitivity measure (ability to distinguish Targ:Dist)                               %
%                   Larger values = better seperation (0 = no seperation)                            %
%               * Loglinear Correction applied to avoid Inf values                                   %
% Beta        : response bias (< 1.0 = bias YES)                                                     %
% lnBeta      : natural log Beta (NEG = bias YES)                                                    % 
% c           : distance [sd units] from NATURAL POINT and decision threshold (criterion)            %
%               * Calculations omit '-' for ease of interpretation                                   %
%                   POSITIVE: favor YES response                                                     %
%                   NEGATIVE: favor NO response                                                      % 
% aPrime  [A']: non-parametric measure of sensitivity (d') [0.5 <-> 1.0]                             %
% bPrime2 [B"]: non-parametric measure of response bias (-1: Bias YES ; 1: Bias NO)                  % 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
table_out = table_in;

table_out.dPrime = norminv(LLh) - norminv(LLf);
table_out.Beta = exp(((norminv(LLf)^2) - (norminv(LLh)^2)) / 2);
table_out.lnBeta = ((norminv(LLf)^2) - (norminv(LLh)^2)) / 2;
table_out.c = (norminv(LLh) + norminv(LLf)) / 2; % omitted '-' to make interpretation easier (NEG = bias towards NO)

table_out.aPrime = 0.5 + (sign(h-f)*((((h-f)^2) + abs(h-f)) / ((4*max(h,f))-(4*h*f))));
table_out.bPrime2 = sign(h-f)*(((h*(1-h))-(f*(1-f))) / ((h*(1-h))+(f*(1-f))));

end