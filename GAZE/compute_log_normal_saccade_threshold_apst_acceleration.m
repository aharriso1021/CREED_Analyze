function varargout= compute_log_normal_saccade_threshold_apst_acceleration(varargin)

%This function computes and plots the parameters of a bimodal lognormal
%plot. The input data for this function is just a vector. 

% INPUTS:
%Data_Vector      =       gaze velocity after blink correction. 
%This value should be in degree/sec. 
%Max_Iteration_MLE      =   maximum iterations for mle
%Max_Fun_Evals_MLE      =     PDF function evaluation limit
%pStart     =       default value 0.2. Shows the mixing ratio of the two pdfs.
%We start with 0.2 unless otherwise specified. 
%Data_Peak_Threshold    =   This threshold is required to determine a lower
%bound for the findpeaks function. Any velocity peak below the Threshold
%will be ignored. The default value for this is 0.05. 


% OUTPUTS:
%   PDFGRID        = The fitted PDF function.
%   ParamEsts     = Estimates of the parameters of the bimodal lognormal distribution.
%   h     = Graphic handle for the bar plot.
%Velocity_Threshold = Velocity Threshold based on the lognormal plot.
%Copyright: Tarkeshwar Singh 2014. Dept. of Exercise Science,USC, Columbia,
%SC.
%% 

Max_Iteration_MLE=600;
Max_Fun_Evals_MLE =800;
pStart=0.1;
muStart_Range = [.6 .4];
Data_Peak_Threshold=0.5;
Bin_Size=.2;
Gaze_Fs=500;
gaze_threshold_ts=50/(1000/(Gaze_Fs)); %Set it to 50 ms 
%% 

if nargin <1
    error('myApp:argChk', 'Wrong number of input arguments');
 
elseif nargin ==1
Data_Vector=varargin{1};

elseif nargin==2
Data_Vector=varargin{1};
Max_Iteration_MLE=varargin{2};

elseif nargin ==3
Data_Vector=varargin{1};
Max_Iteration_MLE=varargin{2};
Max_Fun_Evals_MLE =varargin{3};

elseif nargin==4
Data_Vector=varargin{1};
Max_Iteration_MLE=varargin{2};
Max_Fun_Evals_MLE =varargin{3};
pStart=varargin{4};

elseif nargin==5
Data_Vector=varargin{1};
Max_Iteration_MLE=varargin{2};
Max_Fun_Evals_MLE =varargin{3};
pStart=varargin{4};
muStart_Range = varargin{5};

elseif nargin==6
Data_Vector=varargin{1};
Max_Iteration_MLE=varargin{2};
Max_Fun_Evals_MLE =varargin{3};
pStart=varargin{4};
muStart_Range = varargin{5};
Data_Peak_Threshold=varargin{6};

elseif nargin==7
Data_Vector=varargin{1};
Max_Iteration_MLE=varargin{2};
Max_Fun_Evals_MLE =varargin{3};
pStart=varargin{4};
muStart_Range = varargin{5};
Data_Peak_Threshold=varargin{6};
Bin_Size=varargin{7};

elseif nargin>7
   error('myApp:argChk', 'Wrong number of input arguments');
   
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Body of Function
%% 

[pks,locs] = findpeaks(Data_Vector,'minpeakheight',Data_Peak_Threshold,'minpeakdistance',gaze_threshold_ts);
Sorted_Peak_Vector=sort(pks);
x=log(Sorted_Peak_Vector);

%% 
pdf_normmixture = @(x,p,mu1,mu2,sigma1,sigma2) p*normpdf(x,mu1,sigma1) + (1-p)*normpdf(x,mu2,sigma2);
muStart = quantile(x,muStart_Range);
sigmaStart = sqrt(var(x) - .25*diff(muStart).^2);
start = [pStart muStart sigmaStart sigmaStart];
lb = [0 -Inf -Inf 0 0];
ub = [1 Inf Inf Inf Inf];
%% 

options = statset('MaxIter',Max_Iteration_MLE, 'MaxFunEvals',Max_Fun_Evals_MLE);
paramEsts = mle(x, 'pdf',pdf_normmixture, 'start',start, 'lower',lb, 'upper',ub, 'options',options);
%% 
                      
% bins = 0:Bin_Size:max(x);
% figure('Color',[1 1 1]);
% h=bar(bins,histc(x,bins)/(numel(x)*Bin_Size),'histc');
% set(h,'FaceColor',[.9 .9 .9],'linewidth',2);
xgrid = linspace(1.1*min(x),1.1*max(x),200);
pdfgrid = pdf_normmixture(xgrid,paramEsts(1),paramEsts(2),paramEsts(3),paramEsts(4),paramEsts(5));
% hold on; plot(xgrid,pdfgrid,'LineWidth',4, 'LineStyle','-', 'Color','m'); hold off
% xlabel('Ln(Acceleration) of Local Peaks', 'fontsize',24,'fontweight','b','color','k'); 
% ylabel('Probability Density Function','fontsize',24,'fontweight','b','color','k');
% set(gca,'FontSize',24);
% set(gca, 'box', 'off');

axis tight
xlim([4 12])
%% 
varargout{1}=pdfgrid;
paramEsts(6)=(paramEsts(3)-paramEsts(2))/(2*(paramEsts(4)+paramEsts(5)));
varargout{2}=paramEsts;
% varargout{3}=h;

lower_saccade_vel=paramEsts(2)-(2*paramEsts(4));
upper_fixation_vel=paramEsts(3)+(2*paramEsts(5));
Acceleration_Threshold_Vector=[exp(0.5*((1*lower_saccade_vel)+(1*upper_fixation_vel))),2000];
Acceleration_Threshold=max(Acceleration_Threshold_Vector);%If the distribution is not bimodal, the threshold could be affected. 
% Acceleration_Threshold=max(10^lower_saccade_vel,30); %If the distribution is not bimodal, the threshold could be affected. 

% if Acceleration_Threshold>35
%     Acceleration_Threshold=35;
% end

varargout{4}=Acceleration_Threshold;
% vline(paramEsts(2),'k')
% h2=vline(log(Acceleration_Threshold),'g');
% set(gca,'LineWidth',4);
% set(h2,'LineWidth',4);
% text(log(Acceleration_Threshold)+0.1,0.4,strcat(num2str(round(Acceleration_Threshold)),'^{\circ}','/s^2'),'fontsize',24,'fontname','Helvetica') 
varargout{5}=max(Acceleration_Threshold_Vector);
%% 
% figure('Color',[1 1 1]);
% PeakSig=abs(Data_Vector(1001:6000));
% time_vector=1:1:length(PeakSig);
% [pks,locs] = findpeaks(PeakSig,'minpeakheight',Acceleration_Threshold,'minpeakdistance',25);
% h1=plot(time_vector,PeakSig,'linewidth',3);
% hold on
% % (locs)
% %  Offset values of peak heights for plotting
% h2=plot(time_vector(locs),pks+0.05,'k^','markerfacecolor',[1 0 0]);
% hold off
% xlabel('Time (ms)', 'fontsize',28,'fontweight','b','color','k'); 
% ylabel('Acceleration (^o/s^2)','fontsize',28,'fontweight','b','color','k');
% set(gca,'FontSize',24);
% set(gca, 'box', 'off');
% set(h2,'markersize',16)
% axis tight
% h3=hline(Acceleration_Threshold,'g');
% set(gca,'LineWidth',2);
% set(h3,'LineWidth',6);
% h4=hline(6000,'c');
% % set(gca,'LineWidth',2);
% set(h4,'LineWidth',6);

end

% figure('Color',[1 1 1]);
% [pks,locs] = findpeaks(PeakSig,'minpeakheight',0.5,'minpeakdistance',25);
% h1=plot(x,PeakSig,'linewidth',3), hold on
% %  Offset values of peak heights for plotting
% h2=plot(x(locs),pks+0.05,'k^','markerfacecolor',[1 0 0]), hold off
% xlabel('Time (ms)', 'fontsize',28,'fontweight','b','color','k'); 
% ylabel('Gaze Angular Velocity (^o/s)','fontsize',28,'fontweight','b','color','k');
% set(gca,'FontSize',24);
% set(gca, 'box', 'off');
% set(h2,'markersize',16)
% axis([0 3600 0 350])
% hline(saccade_Acceleration_Threshold,'k')




% Max_Iteration_MLE=600;
% Max_Fun_Evals_MLE =800;
% pStart=0.1;
% muStart_Range = [.4 .6];
% Data_Peak_Threshold=50;
% Bin_Size=.2;
% Gaze_Fs=500;
% gaze_threshold_ts=50/(1000/(Gaze_Fs)); %Set it to 50 ms 
% 
% Data_Vector=trail_making.gaze_angular_velocity_time(:,3);
% [pks,locs] = findpeaks(Data_Vector,'minpeakheight',Data_Peak_Threshold,'minpeakdistance',gaze_threshold_ts);
% Sorted_Peak_Vector=sort(pks);
% x=log(Sorted_Peak_Vector);
% pd = fitdist(x,'Normal');
% bins = 3:Bin_Size:(1.2*max(x));
% 
% figure('Color',[1 1 1]);
% h=bar(bins,histc(x,bins)/(numel(x)*Bin_Size),'histc');
% set(h,'FaceColor',[.9 .9 .9]);
% xgrid = linspace(1.1*min(x),1.1*max(x),200);
% y = pdf(pd,xgrid);
% hold on; plot(xgrid,y,'LineWidth',2, 'LineStyle','-', 'Color','b'); hold off
% xlabel('Ln(Velocity) of Local Peaks', 'fontsize',24,'fontweight','b','color','k'); 
% ylabel('Probability Density Function','fontsize',24,'fontweight','b','color','k');
% set(gca,'FontSize',24);
% set(gca, 'box', 'off');
% axis tight

