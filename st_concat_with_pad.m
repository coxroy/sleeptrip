function data_concat = st_concat_with_pad(cfg)

% ST_CONCAT_WITH_PAD concatenates two or more continuous datasets, (optionally) adding custom amounts of zero-padding in between (convenient for stitching recording
% parts with missing data in between back together)
%
% Use as
%   data_concat = st_concat_with_pad(cfg)
%
%   cfg.datas = [required] a cell array containing at least two FieldTrip datasets that are consistently organized (e.g., channels, sample rate)
%   cfg.postpadseconds = [optional] vector with number of seconds to zero-pad after each dataset (should match number of datasets in cfg.datas, default: all 0 -> direct concatenation)
%
% See also ST_TRIAL_TO_CONTINUOUS, FT_APPENDDATA

% perform checks and set the defaults

%cfg.datas should always exist
ft_checkconfig(cfg,'required',{'datas'});
datas_ori = cfg.datas;
num_data_sets=length(datas_ori);

if num_data_sets < 2
    ft_error('cfg.datas should be a cell containing a minimum of two FieldTrip datasets')
end

cfg.postpadseconds = ft_getopt(cfg, 'postpadseconds', zeros(1,num_data_sets)); %default: add 0 seconds of data (direct concatenation)
pad_seconds = cfg.postpadseconds;
num_pad_seconds=length(pad_seconds);

if num_data_sets ~= num_pad_seconds
    ft_error('the number of elements in cfg.datas and cfg.postpadseconds don''t match')
end


%take first dataset as reference to extract some properties
data=datas_ori{1};
Nchans   = length(data.label);
fsample = data.fsample;

%get amount of padding in samples
pad_samples= pad_seconds.*fsample;

%create zero-padded datasets of requested lengths
datas_pad={};
for data_i=1:num_data_sets

    %raw data
    Nsamples=pad_samples(data_i);
    dat = zeros(Nchans,Nsamples);

    %generate minimal FieldTrip dataset
    data_pad=[];
    data_pad.label=data.label;

    data_pad.trial={dat};
    data_pad.sampleinfo=[1 Nsamples];
    data_pad.time={((1:Nsamples)-1)./fsample};
    data_pad.fsample=fsample;

    %add to cell
    datas_pad{end+1}=data_pad;
end

%interleave original and padded data
datas_all=[datas_ori(:)';datas_pad(:)'];
datas_all=datas_all(:)';

num_data_sets_all=length(datas_all);

%concatenate into single dataset (but separate trials)
cfg=[];
cfg.keepsampleinfo='yes';
data_concat=ft_appenddata(cfg,datas_all{:});

%merge the trials
cfg=[];
data_concat=st_trial_to_continuous(cfg,data_concat);

%handle the events
datas_all_Nsamples = cellfun(@(X) length(X.time{1}),datas_all);
sumSamples=cumsum(datas_all_Nsamples);

events_add=[];
for dat_i=1:num_data_sets_all

    if isfield(datas_all{dat_i},'event')
        events_tmp=datas_all{dat_i}.event;
        %from second dataaset onward...
        if dat_i>1
            %..shift each event sample
            for i=1:length(events_tmp)
                events_tmp(i).sample=events_tmp(i).sample + sumSamples(dat_i-1);
            end
        end
        %append to previous
        events_add=cat(2,events_add,events_tmp);
    end
end

%check timing
%events_add_table=struct2table(events_add);
%events_add_table.time_min=(events_add_table.sample-1)/fsample/60;

%add new events, otherwise remove old events to prevent confusion
if ~isempty(events_add)
    data_concat.event=events_add;
else
    if isfield(data_concat,'event')
        data_concat=rmfield(data_concat,'event');
    end
end
