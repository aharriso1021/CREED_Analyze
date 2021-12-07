function [filt_dat, trial_clk, peak_idx, peak_amp, peak_lat, r_peaks, r_locs] = find_Rpeaks(raw_ekg, sRate, age)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Filters and identifies R-peaks from coninuous Electrocardiogram rec   %
%   Allows for visual inspection of peak detection algorithm              %
% [INPUT]                                                                 %
%   raw_ekg = electrocardiogram recording                                 %  
%   s_rate  = sampling rate of recording                                  %
% [OUTPUT]                                                                %
%   rr_int = array of time intervals between subsequent Rpeaks            %
%   peak_locs = indexing array of Rpeaks in time series                   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[b,a] = butter(4, [1]/(sRate/2), 'high'); % transfer coeff for a 1Hz 4th order highpass filter 
    %% NEW FILTER = BANDPASS 0.3 - 100
filt_ekg = filtfilt(b, a, raw_ekg);
    clearvars b a 
y = abs(filt_ekg);
yi = filt_ekg; 

% RHRV task = 200Hz recording rate

% s_rate = dat.c3d(1).ANALOG.RATE;
clk = [1/sRate: 1/sRate: length(filt_ekg) * 1/sRate];

%% 

[pks,locs] = findpeaks(y);% find peaks within data set (dp > 2 neighbors)

% subplot(3,1,1) % plots data & overlay ID's peaks
% plot(y); hold on;
% plot(locs,pks,'k^','markerfacecolor',[1 0 0]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. Calculates MAX nBeats per TRIAL frame                               %
% 2. Sorts peaks MAX --> MIN (find assoc location in dataset              %
% 3. Trime data = MAX possible beats per trial                            %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isempty(age)
    tHRM = 220 - 18; % 18yo = default
else
    tHRM = 220 - age;
end
min_IBI = 1/(tHRM/60); 
max_beats = ceil(clk(end) ./ min_IBI); %MAX # of beats in rec based off tHRmax 
    [sorted_peaks, sorted_index] = sort(pks,'descend');
    sorted_locs = locs(sorted_index);
r_peaks = sorted_peaks(1:max_beats);
r_locs = sorted_locs(1:max_beats); % Keeps MAX nPeaks based on tHRmax 

% ID peaks in original data that represent R-peak == threshold comparison
minV = 0.07; %Typically at 0.2, but lowered to 0.07 for participant with low R wave amplitude
cutt_idx = find(yi(r_locs) <= minV);

r_locs(cutt_idx) = [];
r_peaks(cutt_idx) = [];

% Sorts PEAKS by increasing time in data set 
[native_locs, native_sorted_index] = sort(r_locs,'ascend');
native_sorted_pks = r_peaks(native_sorted_index);

% Double checks to ensure that Peaks > smallest interval == MAX HR
clk_diff = diff(clk(native_locs));
clkdiff_error = find(clk_diff < min_IBI);

while ~isempty(clkdiff_error)
adj_pks = [native_sorted_pks [native_sorted_pks(2:end);0]];
    if adj_pks(clkdiff_error(1),1) < adj_pks(clkdiff_error(1),2)
        native_sorted_pks(clkdiff_error(1)) = [];
        native_locs(clkdiff_error(1)) = [];
    else
        native_sorted_pks(clkdiff_error(1)+1) = [];
        native_locs(clkdiff_error(1)+1) = [];        
    end
    
    clk_diff = diff(clk(native_locs));
    clkdiff_error = find(clk_diff < min_IBI); % reset 
end

% Final purge of any remaining peak < 65% median 
mTh_cutt = find(native_sorted_pks < median(native_sorted_pks) - (median(native_sorted_pks)*.65));
    clean_Ridx = native_locs; 
        clean_Ridx(mTh_cutt) = [];
    clean_Ramp = native_sorted_pks;
        clean_Ramp(mTh_cutt) = [];
%% Computing Variables %%
filt_dat = yi;
trial_clk = clk;
peak_idx = clean_Ridx;
peak_amp = clean_Ramp;
peak_lat = clk(clean_Ridx);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                         Algorithm Visualization                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% subplot(311)
% hold on;
% plot(native_locs,native_sorted_pks,'go','markerfacecolor','g');
% 
% subplot(312)
% plot(yi,'k');
% hold on;
% plot(native_locs,native_sorted_pks,'go','markerfacecolor','g');
% 
% subplot(313)
% x = ones(length(ibi),1)';
% plot(ibi,x,'ok','markerfacecolor','k');
% 
% % trial_num = num2str(i);
% % title_word = 'Trial ';
% % title_cat = strcat(title_word,trial_num);
% % subplot(311);
% % title(title_cat);
% 
% while ~strcmpi(user_input,'G')
% user_input = input(['G = Good, move on to next',...
%     '\n A = add R peak',...
%     '\n R = remove R peak',...
%     '\n B = break loop',...
%     '\n User decision: '],'s');
% 
% if strcmpi(user_input,'A')
%     disp('Choose 2 points on either side of peak')
%     [x,~] = ginput(2);
%     x=floor(x);
%     [maxY,maxI] = max(yi(x(1):x(2)));
%     %maxY is the mV value
%     %maxI is the index value between x(1) and x(2)
%     
%     maxI = maxI + min(x);
%     native_locs = [maxI;native_locs];
%     native_sorted_pks = [maxY;native_sorted_pks];
%     [native_locs,indexer] = sort(native_locs);
%     native_sorted_pks = native_sorted_pks(indexer);
%     
%     peak_struct.peak_locs = native_locs;
%     peak_struct.peak_amplitudes = native_sorted_pks;
%     peak_struct.peak_times = trials(i).clock(native_locs)-(trials(i).clock(1));
%     qrs = clk(native_locs);
%     ibi = diff(qrs);
%     rr_int = ibi;
% 
% %Clear charts and replot with added data point
% 
%     subplot(311);cla;
%     subplot(312);cla;
%     subplot(313);cla;
%     
%     subplot(311)
%     plot(y); hold on;
%     plot(locs,pks,'k^','markerfacecolor',[1 0 0]);
%     
%     subplot(311)
%     hold on;
%     plot(native_locs,native_sorted_pks,'go','markerfacecolor','g');
% 
%     subplot(312)
%     plot(yi,'k');
%     hold on;
%     plot(native_locs,native_sorted_pks,'go','markerfacecolor','g');
% 
%     subplot(313)
%     len = length(ibi);
%     x=1:len;
%     x(:)=1;
%     plot(ibi,x,'ok','markerfacecolor','k');
% 
% %     trial_num = num2str(i);
% %     title_word = 'Trial ';
% %     title_cat = strcat(title_word,trial_num);
% %     subplot(311);
% %     title(title_cat);
% 
% elseif strcmpi(user_input,'R');
%     disp('Enter data point');
%     [x,~] = ginput(1);
%     [~,idx]=min(abs(native_locs-x));
%     disp(idx);
%     
%     native_locs(idx) = [];
%     native_sorted_pks(idx) = [];
%     
%     peak_struct.peak_locs = native_locs;
%     peak_struct.peak_amplitudes = native_sorted_pks;
%     peak_struct.peak_times = trials(i).clock(native_locs)-(trials(i).clock(1));
%     qrs = clk(native_locs);
%     ibi = diff(qrs);
%     rr_int = ibi;
% 
% %Clear charts and replot with removed data point
% 
%     subplot(311);cla;
%     subplot(312);cla;
%     subplot(313);cla;
%     
%     subplot(311)
%     plot(y); hold on;
%     plot(locs,pks,'k^','markerfacecolor',[1 0 0]);
%     
%     subplot(311)
%     hold on;
%     plot(native_locs,native_sorted_pks,'go','markerfacecolor','g');
% 
%     subplot(312)
%     plot(yi,'k');
%     hold on;
%     plot(native_locs,native_sorted_pks,'go','markerfacecolor','g');
% 
%     subplot(313)
%     len = length(ibi);
%     x=1:len;
%     x(:)=1;
%     plot(ibi,x,'ok','markerfacecolor','k');
% 
% %     trial_num = num2str(i);
% %     title_word = 'Trial ';
% %     title_cat = strcat(title_word,trial_num);
% %     subplot(311);
% %     title(title_cat);
% 
% elseif strcmpi(user_input,'B')
%     break
% end
% 
% if strcmpi(user_input,'B')
%     break
% end
%     
% end
% subplot(311);cla;
% subplot(312);cla;
% subplot(313);cla;
% 
% if strcmpi(user_input,'B')
% end

end 