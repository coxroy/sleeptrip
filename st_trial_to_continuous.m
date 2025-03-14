function data=st_trial_to_continuous(cfg,data)

% ST_TRIAL_TO_CONTINUOUS converts trial-based data into a (pseudo-)continuous dataset by concatenating the trials. By default, the time vector of the
% resulting data is reset to start at t = 0 and increases continuously. Set cfg.resettime = 'no' to keep the original time vectors of the trials.
%
% Use as
%   data = st_trial_to_continuous(cfg,data)
% 
%   cfg.resettime = 'yes' (default) or 'no'
%
% See also ST_CONCAT_WITH_PAD, FT_APPENDDATA

cfg.resettime=ft_getopt(cfg, 'resettime', 'yes'); %remove gaps in time vector

Nchans   = length(data.label);
Ntrials  = length(data.trial);

Nsamples = zeros(1,Ntrials);
for trial=1:Ntrials
    Nsamples(trial) = size(data.trial{trial},2);
end


%intialize data matrix
dat = zeros(Nchans, sum(Nsamples));
for trial=1:Ntrials

    begsample = sum(Nsamples(1:(trial-1))) + 1;
    endsample = sum(Nsamples(1:trial));

    dat(:,begsample:endsample) = data.trial{trial};

end

data.trial={dat};
data.sampleinfo=[1 sum(Nsamples)];

%setup time vector
if istrue(cfg.resettime)
    time_vect=((data.sampleinfo(1):data.sampleinfo(2))-1)/data.fsample;
else
    time_vect=cell2mat(data.time);
end

data.time={time_vect};

