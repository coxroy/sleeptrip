function scoring_events=st_scoringevents2scoring(cfg,scoring)

% ST_SCORINGEVENTS2SCORING converts events (from scoring.events) into a pseudo-scoring with a particular epoch/bin size. This enables comparing
% different event scorings using st_scoringcomp
%
% Available configuration parameters:
% cfg.event : name of event type, as found in scoring.events.event 
% cfg.epochlength_events : target epoch/bin size in seconds (e.g. 3 s for arousals)

selectedEvent=cfg.event;
num_epochs_scoring=length(scoring.epochs);
epochlength_scoring=scoring.epochlength;

scoring_duration=num_epochs_scoring*epochlength_scoring;

epochlength_events=cfg.epochlength_events;

num_epochs_events=ceil(scoring_duration/epochlength_events);

%create scoring_events (using placeholder stage scores)
label_absent='?';
label_present='W';

% initialize scoring dummy
cfg=[];
cfg.epochlength=epochlength_events;
cfg.epochnumber=num_epochs_events;

scoring_events=st_scoringdummy(cfg);

%assign score '?'
scoring_events.epochs(:) = {label_absent};
scoring_events.dataoffset=scoring.dataoffset;

if isfield(scoring,'events')
    selectedEvents=scoring.events(strcmp(scoring.events.event,selectedEvent),:);
    selectedEvents.start_epoch=floor((selectedEvents.start-scoring_events.dataoffset)/epochlength_events)+1;
    selectedEvents.stop_epoch=floor((selectedEvents.stop-scoring_events.dataoffset)/epochlength_events)+1;

    tmp=table2cell(selectedEvents(:,{'start_epoch','stop_epoch'}));

    event_present=cellfun(@(x,y) x:y,tmp(:,1),tmp(:,2),'UniformOutput',false);
    event_present = unique([event_present{:}]);

    %assign score 'W' if event present
    scoring_events.epochs(event_present) = {label_present};

end



% scoremap=[];
% scoremap.labelnew= {sprintf('%s_absent',selectedEvent), sprintf('%s_present',selectedEvent)};
% scoremap.labelold=scoremap.labelnew;
% scoring_events.scoremap=scoremap;
%
% scoring_events.standard='custom';
