%%
%The code below provides a basic tour of SleepTrip's ICA functionality.
%Note that many functions offer additional options. Inspect individual functions for currently accepted arguments and available options.

%%
%-----general setup----
%perform basic setup of Matlab paths (only needs to be run once in a Matlab session)
st_defaults

%%
%---------load data-----------
%Load the included mat file, containing:
% -data: ~8 h of 64-channel data sampled at 250 Hz, referenced to linked mastoids, 0.5 Hz high-pass and 50 Hz notch-filtered.
% -elec: corresponding channel locations
% -scoring: corresponding sleep scores

%It is essential that the variables 'data', 'elec', and 'scoring' match each other (which is the case for these example data).

prefix = fileparts(which('st_defaults'));
loadPath=fullfile(prefix,'tutorial','tutorial_data','tutorial_data06','data_scoring_elec.mat');
load(loadPath)

%to save space 'data' was originally saved with single precision (32 bit)
%use FieldTrip's "ft_struct2double" to convert single into double (and "ft_struct2single" for the reverse)
data=ft_struct2double(data);
%%


cfg=[];
cfg.elec=elec;
cfg.scoring=scoring;
cfg.stages_ica_train= {'W','N1','R'};
%cfg.stages_ica_train= {'N1','R'};
%cfg.stages_ica_train= {'W'};
%cfg.preclean='yes';
%cfg.ica_opts={'pca',32};
%cfg.ica_opts={'extended',1};

[comp,compLabelProbsTable]=st_run_ica(cfg,data);

%%
 %-----inspect components-----

 %We use FieldTrip's "ft_databrowser" to inspect timecourses and topographies of components.
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
%---add scorebrowser
myY=10;
     cfg=[];
        cfg.ylim=[-myY myY];
        cfg.epochlength=30;
        cfg.scoring = scoring;
%cfg.channel=elecInfo{cellfun(@(X) ~isempty(X) & ~contains(X,'-'),elecInfo{:,'label_alternative_2'}),'label'};
            st_scorebrowser(cfg, data);