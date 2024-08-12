function [comp,comp_probs]=st_run_ica(cfg,data)

%---input checks and defaults----
ft_checkconfig(cfg,'required',{'elec','scoring'});

cfg.preclean=ft_getopt(cfg, 'preclean', 'yes'); %default: preclean
cfg.stages_ica_train=ft_getopt(cfg, 'stages_ica_train', cfg.scoring.label); %default: all available stages
cfg.runica_opts=ft_getopt(cfg, 'runica_opts', {}); %default: no special runica options
cfg.iclabel=ft_getopt(cfg,'iclabel','yes'); %default: run IClabel


if istrue(cfg.preclean)

    %get standard detector set if nothing supplied
    if ~isfield(cfg,'detector_set')
        cfg_tmp=[];
        cfg_tmp.elec=cfg.elec;
        cfg_tmp.fsample=data.fsample;
        cfg_tmp.include='default_ica';
        cfg_detector_set=st_get_default_detector_set(cfg_tmp);

        %limit artifact detection to desired stages
        for detector_i=1:cfg_detector_set.number
            cfg_detector_set.detectors{detector_i}.stages=cfg.stages_ica_train;
        end

        %add the scoring
        cfg_detector_set.scoring=cfg.scoring;
    end

    %use user-supplied detector set, otherwise default for ICA
    cfg.detector_set  = ft_getopt(cfg, 'detector_set', cfg_detector_set);

    %%%

    %detect artifacts (across stages used for ICA training)
    cfg_artifacts=st_run_detector_set(cfg.detector_set,data);

    %process the artifacts
    cfg_artifacts.scoring=cfg.scoring;

    cfg_artifacts.channelexpandthresh=Inf;%never expand artifacts to neigbors
    cfg_artifacts.segmentrejectthresh=0.5; %exclude segment if >= half of channels are artifactual

    %channels being artifactual for 10% of ica-data are considered poor
    proportion_ica_stages=mean(ismember(cfg.scoring.epochs,cfg.stages_ica_train));
    cfg_artifacts.badchannelthresh=0.1*proportion_ica_stages; %normally 0.5:

    cfg_artifacts=st_process_detector_results(cfg_artifacts);

    %adjust the repair grid
    segment_expansion_grid=cfg_artifacts.artifacts.grid.artifact_grid_segment_expansion;
    ica_interpolation_grid=false(size(segment_expansion_grid));

    %set to interpolate aross ENTIRE recording
    chansInterpolate=any(segment_expansion_grid,2);
    ica_interpolation_grid(chansInterpolate,:)=true;
    cfg_artifacts.artifacts.grid.ica_grid=ica_interpolation_grid;


    %interpolate
    cfg_artifacts.gridtypeforrepair='ica_grid';
    cfg_artifacts.repairmethod='interpolate';
    data=st_repair_artifacts(cfg_artifacts,data);


    %contains segments marked for exclusion
    scoring_for_selection=cfg_artifacts.scoring_artifact_level;
else
    scoring_for_selection=cfg.scoring;
end

%select desired data for ICA (segments, stages);
cfg_select=[];
cfg_select.scoring=scoring_for_selection;
cfg_select.minlength=30;
cfg_select.stages=cfg.stages_ica_train;
cfg_select.usescoringexclusion='yes';
cfg_select.makecontinuous='yes';

data_ica=st_select_data(cfg_select, data);

%extract data
dat=data_ica.trial{1};

data_minutes=round(size(dat,2)/data.fsample)/60;
fprintf('%.1f min of data available for ICA...\n', data_minutes)

minDataSamples=length(data.label)^2 * 20;
minDataMinutes=minDataSamples/data.fsample/60;

if data_minutes<minDataMinutes
    ft_warning('only %.1f min of data available whereas %.1f min is suggested!\nconsider providing more data or fewer channels\n',data_minutes,minDataMinutes)
end

%----determine rank and adjust settings---
dat_rank=rank(dat);

if dat_rank<size(dat,1)
    ft_warning('data is not full rank\nrunning ICA with pca option\n')
    pca_flag= find(strcmp(cfg.runica_opts,'pca'));
    if isempty(pca_flag)

        new_pca=dat_rank;
    else
        previous_pca=cfg.runica_opts{pca_flag+1};

        new_pca=min(previous_pca,dat_rank);

        %clear previous pca setting
        cfg.runica_opts(pca_flag:pca_flag+1)=[];

    end

    %add updated pca setting
    cfg.runica_opts=[cfg.runica_opts 'pca' new_pca];
end


%run ICA (with options from cfg.runica_opts)
[weights, sphere] = runica(dat, cfg.runica_opts{:});

% calculate mixing/unmixing matrices
unmixing = weights * sphere; %comp x chan
mixing = pinv(unmixing); %chan x comp



%---Fieldtrip---

cfg_comp = [];
cfg_comp.demean    = 'no';           % This has to be explicitly stated, as the default is to demean.
cfg_comp.unmixing  = unmixing;  % Supply the matrix necessary to 'unmix' the channel-series data into components
cfg_comp.topolabel = data.label(:); % Supply the original channel label information

%---output---

comp = ft_componentanalysis(cfg_comp, data); %calculate component time courses for entire data
comp_probs=table;       %iitialize empty table

%--IClabel----
if istrue(cfg.iclabel)

    %----initialize EEGLAB struct---
    EEG=eeg_emptyset;
    EEG.srate=data_ica.fsample;
    EEG.data=dat; %concatenated data
    EEG.chanlocs=elec2chanlocs(cfg.elec); %custom func
    EEG.nbchan= length(data.label);
    EEG.trials=1;
    EEG.pnts=size(dat,2);

    %ICA (icaact not needed: eeg_checkset will remove)
    EEG.icachansind=1:length(data.label);
    EEG.icaweights=weights;
    EEG.icasphere=sphere;
    EEG.icawinv=mixing;

    EEG=eeg_checkset(EEG);

    %----IClabel------
    EEG=iclabel(EEG); %will rereference to average, recalculate component time courses


    %get classification tables
    ic_classification=EEG.etc.ic_classification.ICLabel;
    [m,maxInd]=max(ic_classification.classifications,[],2);
    compLabelTable=table(ic_classification.classes(maxInd)',m,'VariableNames',{'classLabel','prob'});
    comp_probs=array2table(ic_classification.classifications,'VariableNames',ic_classification.classes);

    %adjust FieldTrip component names
    for k = 1:size(comp.topo,2)
        comp.label{k,1} = sprintf('%03d_%s_%.2f', k,compLabelTable{k,'classLabel'}{1}(1:3),compLabelTable{k,'prob'});
    end

end



