function [gngc_eventcodes] = gen_gngc_events(hit_matrix, task_length)
task_duration = [1:5:(task_length*5)];

% ocl & ohl = [time_stamp , event_code]
ocl = table('Size', [length(hit_matrix) 3], 'VariableTypes', {'double', 'double', 'string'}, 'VariableNames', {'Time', 'Code', 'Label'});
for i = 1:length(hit_matrix)
    ocl.Time(i) = task_duration(hit_matrix(i,1));
    if hit_matrix(i,2) == 1
        ocl.Code(i) = 10; % EC 3 = Target Created
        ocl.Label(i) = 'Targ_on';
    elseif hit_matrix(i,3) == 1
        ocl.Code(i) = 11; % EC 5 = Distractor Created
        ocl.Label(i) = 'Dist_on';
    end
end

obj_hit = find(hit_matrix(:,4) > 0);
ohl = table('Size', [length(obj_hit) 3], 'VariableTypes', {'double', 'double', 'string'}, 'VariableNames', {'Time', 'Code', 'Label'});

for k = 1:length(obj_hit)
    ohl.Time(k) = task_duration(hit_matrix(obj_hit(k),4));
    if hit_matrix(obj_hit(k),2) == 1
        ohl.Code(k) = 24; % EC 24 = Target Hit
        ohl.Label(k) = 'Targ_hit';
   elseif hit_matrix(obj_hit(k),3) == 1
        ohl.Code(k) = 35; % EC 35 = Distractor Hit
        ohl.Label(k) = 'Dist_hit';
   end
end

gngc_eventcodes = [ocl ; ohl];
gngc_eventcodes = sortrows(gngc_eventcodes);

end