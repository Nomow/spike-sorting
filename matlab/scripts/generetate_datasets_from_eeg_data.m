load('/home/vtpc/Documents/Alvils/spike-sorting/data/BOU_JO_Localizer6Hz_sessions','femicro','micros2');
path_to_save = "/home/vtpc/Documents/Alvils/spike-sorting/data/recording_datasets";

sess = 2;
fs = femicro;
new_fs = 24000 / fs;
infer_rec = [];
train =u = 1 [];
for i = 1:size(micros2, 1)
    recording = micros2(i, :, sess);
    recording_gpu = gpuArray(recording);
    index = gpuArray(0:size(recording, 2) - 1);
    new_index = gpuArray(0:new_fs:size(recording, 2) - 1);
    new_recording = gather(interp1(index,recording_gpu,new_index));
    
    save_path_data = fullfile(path_to_save, "eeg_rec_2_" + i + ".npy");
    writeNPY(new_recording, save_path_data)
    
    result1 = detect1(new_recording, 24000);
    result2 = detect2(new_recording, 24000);
    spikes_in_both_datasets = find(ismember(result1, result2) == 1);
    spikes = result1(spikes_in_both_datasets);
    spikes1 = result1(find(ismember(result1, result2) == 0));
    spikes2 = result2(find(ismember(result2, result1) == 0));
    spikes3 = [spikes1, spikes2];
    rnd = randi([1 size(spikes3, 2)],1, floor(size(spikes3, 2) * 0.25));
    spikes = [spikes, spikes3(rnd)];
    gd = ones(size(spikes));
    concat_spikes = [size(infer_rec, 2) + spikes; gd];
    infer_rec = [infer_rec, new_recording];
    train = [train, concat_spikes];
end

Fb=100;
[b,a]=butter(1,[2*Fb/24000], 'high'); % femicro: sampling frequency (24kHz)
%bdata = data * - 1;
% filtrage du signal:
LFPh=filtfilt(b,a,new_recording')';

mov_mean = movmean(LFPh,1000);
mov_std = movstd(LFPh,1000);
normalized = (LFPh - mov_mean) ./ mov_std;
index = train(1,:);
s = size(LFPh, 2);
d = 1;
train_set = index(find( abs(normalized(1, index)) >= 3.5));

figure
plot(normalized)
hold
plot( train_set(find(temp_gd < s & train_set > d)) -d  - 1, normalized(1, train_set(find(train_set < s & train_set > d))), '*')

temp_gd = train_set;
% removes adjacent indices
[mini,imini]=min(diff(temp_gd));
while (mini<72)
    [~,isuppr]=min(abs(LFPh(1,temp_gd(imini:imini+1))));
    temp_gd(imini+isuppr-1)=[];
    [mini,imini]=min(diff(temp_gd));
end
[r, c] = ind2sub(size(micros2), temp_gd);

for i =1:size(micros2, 1)
    neuron = ones(size(find(r == i)));
    position = c(find(r == i)) - 1;
    save_path_gd = fullfile(path_to_save, "eeg_gd_single_rec_" + i +".npy");
    writeNPY([position; neuron], save_path_gd);
end
spike_train = [temp_gd - 1; ones(size(temp_gd))];
path_to_save = "/home/vtpc/Documents/Alvils/spike-sorting/data/recording_datasets";
save_path_gd = fullfile(path_to_save, "eeg_ground_truth_dataset2.npy");
writeNPY(spike_train, save_path_gd)
save_path_data = fullfile(path_to_save, "eeg_recording_dataset2.npy");
writeNPY(infer_rec, save_path_data)
