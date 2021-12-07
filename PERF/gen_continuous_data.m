function [OHA_parameters, hit_matrix, task_length] = gen_continuous_data (kin)

% data = zip_load (zip_file);
try
    data = kin.c3d;
catch 
    data = kin;
end

data = KINARM.KINARM_add_hand_kinematics(data);
    hand_kinematics = OHA.Hand_Data(data, data.ANALOG.RATE);
    
task_length = length(data.event_code);
n_sparse_col=12;
event_code=data.event_code;
event_supplement=data.event_supplement;
supp_value = cast(event_supplement, 'uint32');

% Target was created.
index_target_created=find(abs(event_code)==100);
isTarget = bitand(supp_value(index_target_created),1);
isDistractor=(isTarget==0);
channel = bitand(bitshift(supp_value(index_target_created), -1), 15);
targetTableRow = bitand(bitshift(supp_value(index_target_created), -5), 65535);
ocm=[index_target_created isTarget isDistractor channel targetTableRow];
ocm_sorted=sortrows(ocm,[4 1]); %First sort by channel and then by time index

% Target was hit.
index_object_hit=find(event_code~=0 & abs(event_code)~=100);

first_four_bits = bitand(supp_value(index_object_hit), 15);
second_four_bits = bitand(bitshift(supp_value(index_object_hit), -4), 15);
third_four_bits = bitand(bitshift(supp_value(index_object_hit), -8), 15);
final_four_bits = bitand(bitshift(supp_value(index_object_hit), -12), 15);
object_hit_channel_matrix=[index_object_hit third_four_bits final_four_bits first_four_bits second_four_bits]; %Third four bits come first because unlike BKIN I think Left should come before Right.

% object_hit_channel_matrix=OHA.correct_for_improper_hits(data,ocm,object_hit_channel_matrix_all_hits); %Removes the hits that were not hit away from the subject.

ogh_matrix=sparse(length(event_code),(length(index_target_created)*n_sparse_col));

for counter=1:length(index_target_created)
    disp(num2str(counter));
    
    ogh_matrix=sparse(length(event_code),n_sparse_col);
    channel_of_object=ocm(counter,4);
    
    % Finds the range of values over which each object is in the work space.
    row_of_object=ocm(counter,:);
    object_x_minus_1_in_channel_N=ocm_sorted(find(ismember(ocm_sorted,row_of_object,'rows')'),:);
    if find(ismember(ocm_sorted,row_of_object,'rows')')<length(index_target_created)
        object_x_in_channel_N=ocm_sorted(find(ismember(ocm_sorted,row_of_object,'rows')')+1,:);
    elseif find(ismember(ocm_sorted,row_of_object,'rows')')==length(index_target_created)
        object_x_in_channel_N=[length(event_code) 0 0 100 0];  %Arbitrarily Large Channel No.
    end
    
    if isequal(object_x_minus_1_in_channel_N(1,4),object_x_in_channel_N(1,4))
        temp_a=eval(strcat('find(data.CH',num2str(channel_of_object),'_x(object_x_minus_1_in_channel_N(1):object_x_in_channel_N(1)-1)~=-1000),'));
        last_time_point_of_x_minus_1_object=temp_a(end)-1;
        
        indices_of_interest=strcat('ocm(counter,1):ocm(counter,1)+last_time_point_of_x_minus_1_object');
    else
        indices_of_interest=strcat('ocm(counter,1):ocm(counter,1)+','find(data.CH',...
            num2str(channel_of_object),'_x(ocm(counter,1):end)==-1000,1)-2');
    end
    
%     if counter == length(index_target_created)
        temp_check = eval(strcat('data.CH',num2str(channel_of_object),'_x'));
        if sum(temp_check(ocm(counter,1):end)==-1000) < 1
            current_channel = ['CH' num2str(channel_of_object) '_x'];
            data.(current_channel)(end)= -1000;
        end
%% Column 1-2 for Left and Right Hand Contacts with Target
%     ogh_matrix(eval(indices_of_interest)',1)=zeros;    %For Left Hit
    try
    ogh_matrix(eval(indices_of_interest)',2)=zeros;    %For Right Hit
    catch
        keyboard;
    end
    subset_object_hit_channel_matrix=object_hit_channel_matrix(find(object_hit_channel_matrix(:,1)>=min(eval(indices_of_interest)) &...
        object_hit_channel_matrix(:,1)<=max(eval(indices_of_interest))),:);
    
    Left_Hit_Index=subset_object_hit_channel_matrix(find(subset_object_hit_channel_matrix(:,2)==channel_of_object),1);
    Right_Hit_Index=subset_object_hit_channel_matrix(find(subset_object_hit_channel_matrix(:,4)==channel_of_object),1);
    
    % Small Twist if people double hit an object
    if length(Left_Hit_Index)>1
        Left_Hit_Index=Left_Hit_Index(1);
    end
    if length(Right_Hit_Index)>1
        Right_Hit_Index=Right_Hit_Index(1);
    end
    if ~isempty(Left_Hit_Index) && isempty(Right_Hit_Index)
        ogh_matrix(Left_Hit_Index,1)=1;
    end
    if ~isempty(Right_Hit_Index) && isempty(Left_Hit_Index)
        ogh_matrix(Right_Hit_Index,2)=1;
    end
    if ~isempty(Right_Hit_Index) && ~isempty(Left_Hit_Index) && ((Left_Hit_Index-Right_Hit_Index)>0)
        ogh_matrix(Right_Hit_Index,2)=1;
    elseif ~isempty(Right_Hit_Index) && ~isempty(Left_Hit_Index) && ((Left_Hit_Index-Right_Hit_Index)<0)
        ogh_matrix(Left_Hit_Index,1)=1;
    end
%% Columns 3-12 are left and right hand positions, Cartesian velocities. 
ogh_matrix(eval(indices_of_interest)',3)=eval(strcat('hand_kinematics.Left_HandX(','eval(indices_of_interest))'));
ogh_matrix(eval(indices_of_interest)',4)=eval(strcat('hand_kinematics.Left_HandY(','eval(indices_of_interest))'));
ogh_matrix(eval(indices_of_interest)',5)=eval(strcat('hand_kinematics.Left_HandXVel(','eval(indices_of_interest))'));
ogh_matrix(eval(indices_of_interest)',6)=eval(strcat('hand_kinematics.Left_HandYVel(','eval(indices_of_interest))'));
ogh_matrix(eval(indices_of_interest)',7)=eval(strcat('hand_kinematics.Left_HandVel(','eval(indices_of_interest))'));

ogh_matrix(eval(indices_of_interest)',8)=eval(strcat('hand_kinematics.Right_HandX(','eval(indices_of_interest))'));
ogh_matrix(eval(indices_of_interest)',9)=eval(strcat('hand_kinematics.Right_HandY(','eval(indices_of_interest))'));
ogh_matrix(eval(indices_of_interest)',10)=eval(strcat('hand_kinematics.Right_HandXVel(','eval(indices_of_interest))'));
ogh_matrix(eval(indices_of_interest)',11)=eval(strcat('hand_kinematics.Right_HandYVel(','eval(indices_of_interest))'));
ogh_matrix(eval(indices_of_interest)',12)=eval(strcat('hand_kinematics.Right_HandVel(','eval(indices_of_interest))'));
%%                                                                           
%%
ALLogh_matrix(:,((counter-1)*n_sparse_col)+1:n_sparse_col*counter)=ogh_matrix;
    
end  %End of For Statement

sparse_OHA=ndSparse(ALLogh_matrix,[length(event_code),n_sparse_col,length(index_target_created)]);
% hit matrix = [obj_createdINDEX, obj_isTarg, obj_isDist, obj_hitINDEX, obj_hitLEFT, obj_hitRIGHT];
for i=1:length(ocm)
    if ~isempty(find( sparse_OHA(:,1,i)==1)) && isempty(find(sparse_OHA(:,2,i)==1)) %obj HIT with LEFT
        hit_matrix(i,1) = ocm(i,1);
        hit_matrix(i,2) = ocm(i,2);
        hit_matrix(i,3) = ocm(i,3);
        hit_matrix(i,4) = find(sparse_OHA(:,1,i) == 1);
        hit_matrix(i,5) = 1;
        hit_matrix(i,6) = 0;  
    elseif isempty(find(sparse_OHA(:,1,i)==1)) && ~isempty(find(sparse_OHA(:,2,i)==1)) % obj HIT with RIGHT
        hit_matrix(i,1) = ocm(i,1);
        hit_matrix(i,2) = ocm(i,2);
        hit_matrix(i,3) = ocm(i,3);
        hit_matrix(i,4) = find(sparse_OHA(:,2,i) == 1);
        hit_matrix(i,5) = 0;
        hit_matrix(i,6) = 1; 
    elseif isempty(find(sparse_OHA(:,1,i) == 1)) && isempty(find(sparse_OHA(:,2,i)==1)) % obj HIT with NEITHER
        hit_matrix(i,1) = ocm(i,1);
        hit_matrix(i,2) = ocm(i,2);
        hit_matrix(i,3) = ocm(i,3);
        hit_matrix(i,4) = NaN;
        hit_matrix(i,5) = 0;
        hit_matrix(i,6) = 0; 
    elseif ~isempty(find(sparse_OHA(:,1,i)==1)) && ~isempty(find(sparse_OHA(:,2,i)==1))
        hit_matrix(i,1)=NaN;
        hit_matrix(i,2)=NaN;
        hit_matrix(i,3)=ocm(i,2);
        hit_matrix(i,4)=ocm(i,3);
        error('myApp:argChk', 'Both hands cannot make contact with an object');
    end
end

OHA_parameters.left_hit_targets=length(find(hit_matrix(find(hit_matrix(:,2)),5)));
OHA_parameters.right_hit_targets=length(find(hit_matrix(find(hit_matrix(:,2)),6)));
OHA_parameters.left_hit_distractors=length(find(hit_matrix(find(hit_matrix(:,3)),5)));
OHA_parameters.right_hit_distractors=length(find(hit_matrix(find(hit_matrix(:,3)),6)));
end
