function scoring=st_scoringdummy(cfg)

% ST_SCORINGDUMMY returns a dummy/fake scoring structure. By default, it
% returns 1000 epochs of stage unknown (?) with an epoch length of 30 s
%
% Use as
%   scoring = st_scoringdummy(cfg)
%
%   cfg may be empty (use defaults), or specify one or more of the
%   following:
%   cfg.epochlength = length op epochs in seconds (default: 30)
%   cfg.epochnumber = number of epochs (default: 1000)
%   cfg.label       = aasm stage label to apply to all epochs (one of 'W', 'N1', 'N2', 'N3', 'R' or '?'; default: '?')

cfg.label=ft_getopt(cfg, 'label', {'?'});
if ~iscell(cfg.label)
    cfg.label={cfg.label};
end
cfg.epochnumber=ft_getopt(cfg, 'epochnumber', 1000);
cfg.epochlength=ft_getopt(cfg, 'epochlength', 30);

epochlength=cfg.epochlength;

%simple stage table
tableScoring=table(repmat(cfg.label,[cfg.epochnumber,1]),'VariableNames',{'Stage'});

%set up scoremap
scoremap = [];
scoremap.labelold  = {'W', 'N1', 'N2', 'N3', 'R'};
scoremap.labelnew  = {'W', 'N1', 'N2', 'N3', 'R'};
scoremap.unknown   = '?';

%read the scoring
cfg = [];
cfg.standard='custom';
cfg.to='aasm';
cfg.scoremap=scoremap;
cfg.epochlength=epochlength;

scoring=st_read_scoring(cfg,tableScoring);