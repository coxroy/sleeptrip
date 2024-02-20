%%
%The code below provides a basic tour of SleepTrip's ICA functionality.
%Note that many functions offer additional options. Inspect individual functions for currently accepted arguments and available options.

%%
%-----general setup----
%perform basic setup of Matlab paths (only needs to be run once in a Matlab session)
st_defaults
%%
%---------load data-----------
%Load one of the included mat files, containing:
% -data: ~8 h of 64-channel data sampled at 250 Hz, referenced to linked mastoids, 0.5 Hz high-pass and 50 Hz notch-filtered.
% -elec: corresponding channel locations
% -scoring: corresponding sleep scores

%It is essential that the variables 'data', 'elec', and 'scoring' match each other (which is the case for the included example data).


%select recording
useRecording='p3'; %primary example for ICA
%useRecording='p1';
%useRecording='p2';


prefix = fileparts(which('st_defaults'));
loadPath=fullfile(prefix,'tutorial','tutorial_data',useRecording,'data_scoring_elec.mat');

load(loadPath)

%to save space 'data' was originally saved with single precision (32 bit)
%use FieldTrip's "ft_struct2double" to convert single into double/64 bit (and "ft_struct2single" for the reverse)
data=ft_struct2double(data);
%%
%-----inspect raw (pre-ICA) channel data---

%see tutorial_cleaning.m for additional options

%set up cfg
cfg=[];
cfg.ylim=[-20 20]; %y-range
cfg.epochlength=30;
cfg.scoring = scoring; %add the scoring to see each epoch's sleep stage

%plot
st_scorebrowser(cfg,data);
%%
%----perform ICA----

%set up cfg
cfg=[];
cfg.elec=elec;
cfg.scoring=scoring;
cfg.preclean='yes'; % "preclean data" by interpolating bad channels and ignoring temporal intervals containing noisy data (default="yes")
cfg.stages_ica_train= {'W','N1','R'}; %train algorithm on specified stages (default: all available stages)
cfg.iclabel='yes'; %run IClabel following ICA (default="yes")

%various other options are available, e.g.:
%cfg.detector_set= [myCustomDetectorSet]; %when cfg.preclean="yes", use a user-supplied detector set instead of the built-in one for precleaning data
%cfg.preclean='no'; %do not preclean (= use raw data)
%cfg.stages_ica_train= {'W','N1','N2','N3','R'}; %supply other stages to ICA algorithm

%it is possible to provide addtional arguments recognized by the low-level ICA algorithm (see runica.m), e.g.:
%cfg.runica_opts={'pca',32}; %run principal component analysis (PCA) prior to ICA
%cfg.runica_opts={'extended',1}; %run "extended" form ICA


%run ICA
[comp,compLabelProbsTable]=st_run_ica(cfg,data);

% - "comp" contains the returned components (in FieldTrip format)
% - "compLabelProbsTable" contains the component class probabilities returned by IClabel

%%
%-----inspect components-----

%Use FieldTrip's "ft_databrowser" to inspect timecourses and topographies of components.
%Consult that function for all available options.
cfg = [];
cfg.elec=elec;
cfg.viewmode = 'component';
cfg.compscale='local';
cfg.continuous = 'yes';
cfg.blocksize = 30; %window size. set to e.g. 60 or 300 for faster scrolling
cfg.ylim =[-5 5];
cfg.channel = comp.label; %names of components to display. here we plot all components at once. set to e.g. comp.label(1:20) for better visibility of topographies

ft_databrowser(cfg,comp);

%- use the "segment" and adjacent arrow buttons to select time windows and scroll horizontally through the recording
%- use the "component" and adjacent arrow buttons to select components and scroll vertically through components
%%
%---remove components--

%specify a list of components to remove: the ones below are usually stable
%for the default example recording and ICA options specified above. Any
%changes will result in other components and/or component order. Check to
%make sure.
removeCompInds=[3 6 7 8 10 12 13 42];

%set up cfg
cfg=[];
cfg.component=removeCompInds;

%remove the components
data_clean=ft_rejectcomponent(cfg, comp);

%%
% ----inspect clean (post-ICA) channel data ----
cfg=[];
cfg.ylim=[-20 20]; %y-range
cfg.epochlength=30;
cfg.scoring = scoring; %add the scoring to see each epoch's sleep stage

st_scorebrowser(cfg,data_clean);

%%
%Note that it is possible to keep the two scorebrowsers (pre-ICA and
%post-ICA) and the databrowser (components) open at the same time to relate
%signals to each other (multiple screens advisable).
