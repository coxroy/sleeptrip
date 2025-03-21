function [scoring] = st_append_scoring(varargin)

% ST_APPEND_SCORING append matching scroing structures,
% the original scoring and cfg is stored in a new cells as fields oris and
% cfgs respectively
%
% Use as
%   [scoring] = st_append_scoring(scoring,...)
%
% See also ST_READ_SCORING, ST_SCORINGDESCRIPTIVES

% Copyright (C) 2019-, Frederik D. Weber
%
% This file is part of SleepTrip, see http://www.sleeptrip.org
% for the documentation and details.
%
%    SleepTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    SleepTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    SleepTrip is a branch of FieldTrip, see http://www.fieldtriptoolbox.org
%    and adds funtionality to analyse sleep and polysomnographic data. 
%    SleepTrip is under the same license conditions as FieldTrip.
%
%    You should have received a copy of the GNU General Public License
%    along with SleepTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

ttic = tic;
mtic = memtic;
functionname = getfunctionname();
fprintf([functionname ' function started\n']);

% these are used by the ft_preamble/ft_postamble function and scripts
ft_revision = '$Id$';
ft_nargin   = nargin;
ft_nargout  = nargout;

% do the general setup of the function
ft_defaults
%ft_preamble init
%ft_preamble debug
%ft_preamble loadvar data
%ft_preamble provenance data
%ft_preamble trackconfig

% the ft_abort variable is set to true or false in ft_preamble_init
% if ft_abort
%     return
% end

% check if some are empty


scorings = {};
iE = 0;
for iArg = 1:nargin
    if ~isempty(varargin{iArg})
        iE = iE + 1;
        scorings{iE} = varargin{iArg};
    else
        ft_warning('scoring number %d is empty and is thus ignored. Continous numbering is also ignoring this scoring',iArg)
    end
end

if isempty(scorings)
    ft_error('no scorings for appending')
end


nScorings = numel(scorings);


if iscell(scorings)
scoring = scorings{1};
if numel(scorings) > 1
    scoring.oris = {};
    scoring.oris{1} = scoring.ori;
    scoring.cfgs = {};
    scoring.cfgs{1} = scoring.cfgs;
    for iScoring = 2:numel(varargin)
        
        scoring_app = varargin{iScoring};
        
        %check consistency
        if (scoring.epochlength ~= scoring_app.epochlength)
            ft_error(['epochlength of scoring number ' num2str(iScoring) ' does not match the previous, will not concatenate.']);
        end
        
        if ~strcmp(scoring.standard,scoring_app.standard)
            ft_error(['scoring standard of scoring number ' num2str(iScoring) ' does not match the previous, will not concatenate.']);
        end
        
        scoring.epochs = cat(2,scoring.epochs,scoring_app.epochs);
        scoring.excluded = cat(2,scoring.excluded,scoring_app.excluded);
        
        if isfield(scoring,'numbers') && isfield(scoring_app,'numbers')
        	scoring.numbers = cat(2,scoring.numbers,scoring_app.numbers);
        end
        
        if isfield(scoring,'prob') && isfield(scoring_app,'prob')
        	scoring.prob = cat(2,scoring.prob,scoring_app.prob);
        end
        
        if isfield(scoring,'arousals') && isfield(scoring_app,'arousals')
        	scoring.arousals = cat(1,scoring.arousals,scoring_app.arousals);
        end
        
        if isfield(scoring,'events') && isfield(scoring_app,'events')
        	scoring.events = cat(1,scoring.events,scoring_app.events);
        end

        
        scoring.oris{iScoring} = scoring_app.ori;
        scoring.cfgs{iScoring} = scoring_app.cfg;
        
        
    end
    rmfield(scoring,'ori');
    %rmfield(scoring,'cfg');
end
    
end

fprintf([functionname ' function finished\n']);
toc(ttic)
memtoc(mtic)
end
