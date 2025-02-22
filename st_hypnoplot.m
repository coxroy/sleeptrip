function [fh, axh] = st_hypnoplot(cfg, scoring)

% ST_HYPNOPLOT plots a hypnogram from the scoring
%
%   Note that for Matlab versions of 2014b to 2017a (but not later or
%   earlier versions) there will appear artifact lines in pdf and eps
%   vector graphics export. This is a 'Matlab bug' (https://www.mathworks.com/matlabcentral/answers/162257-problem-with-patch-graphics-in-2014b-splits-in-two-along-diagonal) of those versions in plotting.
%   Please use earlier or later versions to export plots properly or see
%   https://github.com/Conclusio/matlab-epsclean
%
% Use as
%   [fh axh] = st_hypnoplot(cfg,scoring)
%
%   scoring is a structure provided by ST_READ_SCORING
%   it returns the figure handle (fh) and the axis handle (axh
%
%   config file can be empty, e.g. cfg = []
%
% Optional configuration parameters are
%   cfg.plottype               = string, the type of
%                                plot 'classic' plots the line graph as typical
%                                or 'colorbar' for only one bar of colors
%                                or 'colorblocks' plots the colorbocks
%                                   (colorbars separated by sleep stage)
%                                or 'colorblocksN3S4' plots the colorbocks with N3 and S4 merged on same y-level
%                                or 'colorblocksN2N3S4' plots the colorbocks with N2, N3 and S4 merged on same y-level
%                                or 'colorblocksN1N2N3S4' plots the colorbocks colorbocks with N1, N2, N3 and S4 merged on same y-level
%                                   (colorbars separated by sleep stage)
%                                or 'deepcolorblocks' plots like colorbocks but the deeper non-REM sleep states are taller blocks
%                               (default = 'classic')
%                                or  'feige'
%   cfg.colorscheme            = srting, indicating the color schemes:
%                                'bright' or 'dark' or 'restless' or 'default'
%                                 (default = 'default') see ST_EPOCH_COLORS
%                                 for details
%   cfg.classiccolor           = a 1x3 color vector with 3 RGB values from
%                                0 to 1 color for the color of the line of
%                                the cfg.plottype = 'classic'
%                                (default = [0 0 0])
%   cfg.figurehandle           = overwrite the figure handle
%   cfg.figureaxishandle       = overwrite the figure axis handle
%   cfg.colorblocksconnect     = string, either 'yes' or 'no' if lines between colorblocks should be shown
%                                only has effect for cfg.plottype = 'colorblocks'(default = 'no')
%   cfg.plotlegend             = string, if the legend should be plotted either 'yes' or 'no' (default = 'yes')
%   cfg.plotsleeponset         = string, plot an indicator of sleep onset either 'yes' or 'no' (default = 'yes')
%   cfg.plotsleepoffset        = string, plot an indicator of sleep offset either 'yes' or 'no' (default = 'yes')
%   cfg.plotsleepopon          = string, plot an indicator of sleep opportunity onset offset either 'yes' or 'no' (default = 'yes')
%   cfg.plotsleepopoff         = string, plot an indicator of sleep opportunity off onset either 'yes' or 'no' (default = 'yes')
%   cfg.plotlightsoff          = string, plot an indicator of lights off either 'yes' or 'no' (default = 'yes')
%   cfg.plotlightson           = string, plot an indicator of lights on either 'yes' or 'no' (default = 'yes')
%   cfg.plotindicatorssoutsidescoringtimes = string, plot the indicators (lightsoff, lightson, sleepopon, sleepopoff) outside of the scoring if necessary (default = 'yes')
%   cfg.plotunknown            = string, plot unscored/unkown epochs or not either 'yes' or 'no' (default = 'yes')
%   cfg.plotexcluded           = string, plot excluded epochs 'yes' or 'no' (default = 'yes')
%   cfg.sleeponsetdef          = string, sleep onset either 'N1' or 'N1_NR' or 'N1_XR' or
%                                'NR' or 'N2R' or 'XR' or 'AASM' or 'X2R' or
%                                'N2' or 'N3' or 'SWS' or 'S4' or 'R',
%                                see ST_SLEEPONSET for details (default = 'N1_XR')
%   cfg.allowsleeponsetbeforesleepopon   = srting, if possible, allow sleep onset before sleep
%                                opportunity (or lights off moment if former is not present)
%                                either 'yes' or 'no' see ST_SLEEPONSET for details (default = 'no')
%   cfg.title                  = string, title of the figure to export the figure
%   cfg.xlabel                 = relabel the x-axis (Time)
%   cfg.ylabel                 = relabel the y-axis (Sleep stage)
%   cfg.timeticksdiff          = scalar, time difference in minutes the ticks are places from each other (default = 30);
%   cfg.timemin                = scalar, minimal time in minutes the ticks
%                                have, e.g. 480 min, will plot tick at least to 480 min (default = 0);
%   cfg.timerange              = vector, [mintime maxtime] of the time axis
%                                limits in minutes, overwrites all the
%                                other contraints
%                                have, e.g. 480 min, will plot tick at least to 480 min (default = display all);
%   cfg.timeunitdisplay        = string, time unit for display in the x-axis labels
%                                either 'minutes' or 'seconds' or 'hours' or 'days'
%                                if 'time' is provided then the
%                                scoring.startdatetime will be used to plot
%                                time on the clock in a 24 hours format
%                                Note: this will not affect the other parameters like cfg.timerange to be given in minutes
%                                (default = 'minutes')
%   cfg.scoringstartdatetime   = provide a datetime for the start of the
%                                scoring (not the data start)
%                                Note: this will overwrite the scoring.startdatetime
%                                Note: to display, this will need cfg.timeunitdisplay = 'time'
%   cfg.considerdataoffset     = string, 'yes' or 'no' if dataoffset is represented in time axis (default = 'yes');
%
%   cfg.relabelstages          = relabel of the sleep stages y-axis as seen
%                                without the relabling and event names
%  Events can be plotted using the following options
%
%   cfg.eventtimes             = a Nx1 cell containing 1x? vectors of event
%                                  time points (in seconds) representing N
%                                  event types of ? instances to be
%                                  plotted. e.g.
%                                 {[1.5, 233.2, 455.6]; ...
%                                  [98, 3545.9]; ...
%                                  [393.4, 425.8, 900.0, 4001.01]}
%   cfg.eventdurations          = optional, but if set events are given a duration with
%                                 cfg.eventtimes being the start of the
%                                 event and the respctive duration in
%                                 seconds added to that. The event
%                                 durations then needs to match the number
%                                 of event times for each event type or be
%                                 empty, i.e. having no duration for all
%                                 events of that event type. e.g.
%                                {[30, 120, 600]; ...
%                                             []; ...
%                                    [0, 0, 0, 1]}
%   cfg.eventlabels            = Nx1 cellstr with the labels to the events corresponding to the rows in cfg.eventstimes
%   cfg.eventheight            = one number or Nx1 vector of numbers with N corresponding
%                                to the rows in cfg.eventstimes (i.e. the
%                                event types) to set the height taken by
%                                the plot for each event type.
%                                (default = 0.4)
%   cfg.eventminscale          = one number or Nx1 vector of numbers with N corresponding
%                                to the rows in cfg.eventstimes (i.e. the
%                                event types) to set the minimum event scaling of the height taken by
%                                the plot for each event type.
%                               (default = 0.1) i.e. at least plotted 10%
%                                of the height of the maximal even range
%   cfg.eventvalues            = a Nx1 cell containing 1x? vectors of event
%                                values (e.g. amplitude)
%                                 {[20.3, 23.2, 45.6]; ...
%                                  [18, 35.9]; ...
%                                  [39.1, 42.5, 80.0, 42.1]}
%   cfg.eventvalueranges       = a Nx1 cell containing 1x2 vectors of event
%                                values ranges (e.g. min and max of amplitude)
%                                 {[20 40]; ...
%                                  [18, 36]; ...
%                                  [39, 80.0]}
%   cfg.eventvalueranges_plot  = a Nx1 logical vector of event
%                                values ranges being plotted or not
%                                 [1; ...
%                                  0; ...
%                                  1]
%   cfg.eventvaluerangesrnddec = round event ranges to that amount of decimal (default = 2)
%   cfg.eventcolors            = a Nx3 color matrix with 3 RGB values from 0 to 1 color for each of
%                                 the N event types, (default = lines(N))
%   cfg.eventcolorsbystagecolor = string, if even colors should follow the sleep state
%                                 that they are in or start in, either 'yes' or 'no'.
%                                 if 'yes' cfg.eventcolors will be ignored
%                                  (default = 'no')
%    cfg.eventalign             = string, either align event to the
%                                 'center', 'bottom' or 'top' or 'stack' or a cellstring of dimension Nx1
%                                 with such a string for every of the N event types defined in cfg.eventlabels (default = 'center')
%    cfg.eventsmoothing         = string, if events should be smoothed either 'yes' or 'no'
%                                 or a cellstr of dimension Nx1 with the N event types defined
%                                 in cfg.eventlabels (default = 'no')
%    cfg.eventsmoothing_windowseconds = one number or Nx1 vector of numbers with N corresponding
%                                to the rows in cfg.eventstimes (i.e. the
%                                event types) to set the time window for smooting in seconds.
%                               (default = scoring.epochlength)
%    cfg.eventsmoothing_timestepseconds = one number or Nx1 vector of numbers with N corresponding
%                                to the rows in cfg.eventstimes (i.e. the
%                                event types) to set the time step in seconds for each window to slide
%                                for smoothing of events. (default = scoring.epochlength)
%    cfg.eventsmoothing_choose  = string, which values to plot from the smoothing the actual
%                                'value' or the 'count' of events in the time windows or a cellstr
%                                 of dimension Nx1 with the N event types defined in cfg.eventlabels
%                                (default = 'value')
%    cfg.eventsmoothing_starttimeseconds = one number or Nx1 vector of numbers with N corresponding
%                                to the rows in cfg.eventstimes (i.e. the
%                                event types) to set the start time in
%                                seconds when smoothing should start
%                                relative to dataoffset (if dataoffset is considered)
%                                (default = scoring.dataoffset or 0 if cfg.considerdataoffset is 'no')
%    cfg.eventsmoothing_endtimeseconds = one number or Nx1 vector of numbers with N corresponding
%                                to the rows in cfg.eventstimes (i.e. the
%                                event types) to set the start time in
%                                seconds when smoothing should end
%                                relative to dataoffset (if dataoffset is considered)
%                                (default = time point the last epoch in the scoring ends in the hypnogram)
%   cfg.eventmask               = a Nx1 cell containing 1x? vectors logical
%                                  values if corresponding event
%                                  time points should be masked, while N is
%                                  the event types of ? instances to be
%                                  masked in scoring. 1 means masked 0 means not masked event.
%                                  this should have the same size as cfg.eventtimes. e.g.
%                                 {[0, 1, 1]; ...
%                                  [1, 1]; ...
%                                  [0, 1, 1, 1]}
%  cfg.eventmaskcolor          = a 1x3 color matrix with 3 RGB values from
%                                 0 to 1 color for the mask color
%                                 default = [1 1 1] i.e. white
%  cfg.offset_event_y          = offset in the y-axis of the events being
%                                plotted. 0 means default above hypnogram,
%                                negative numbers mean lower, positive mean higher (default = 0)
%  cfg.ploteventboundaryticks = a Nx1 logical vector for each event
%                                if the minor ticks (indicating event boundaries/range) should be plotted or not
%                                 [1; ...
%                                  1; ...
%                                  1] (default = true for every event type)
%
% If you wish to export the figure then define also the following
%   cfg.figureoutputfile       = string, file to export the figure
%   cfg.figureoutputformat     = string, either 'png' or 'epsc' or 'svg' or 'tiff' or
%                                'pdf' or 'bmp' or 'fig' (default = 'png')
%   cfg.figureoutputunit       = string, dimension unit (1 in = 2.54 cm) of hypnograms.
%                                either 'points' or 'normalized' or 'inches'
%                                or 'centimeters' or 'pixels' (default =
%                                'inches')
%   cfg.figureoutputwidth      = scalar, choose format dimensions in inches
%                                (1 in = 2.54 cm) of hypnograms. (default = 9)
%   cfg.figureoutputheight     = scalar, format dimensions in inches (1 in = 2.54 cm) of hypnograms. (default = 3)
%   cfg.figureoutputresolution = scalar, choose resolution in pixesl per inches (1 in = 2.54 cm) of hypnograms. (default = 300)
%   cfg.figureoutputfontsize   = scalar, Font size in units stated in
%                                parameter cfg.figureoutputunit (default = 0.1)
%   cfg.figureoutputfontname   = change the figure font (e.g. 'Times' or
%                                'Arial' or 'Helvetica'. For a list of
%                                available fonts use the matlab function
%                                listfonts. (default = 'Arial')
%   cfg.timestamp              = either 'yes' or 'no' if a time stamp should be
%                                added to filename (default = 'yes')
%   cfg.folderstructure        = either 'yes' or 'no' if a folder structure should
%                                be created with the result origin and type
%                                all results will be stored in "/res/..." (default = 'yes')
%
%   cfg.legacymode             = either 'yes' or 'no' if the plotting is
%                                slow and in legacy mode (pre 2021)
%
%
% See also ST_READ_SCORING

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
%dt = now;

ttic = tic;
mtic = memtic;
functionname = getfunctionname();
fprintf([functionname ' function started\n']);

legacymode = true;

% set the defaults
cfg.plottype                = ft_getopt(cfg, 'plottype', 'classic');
cfg.plotlegend              = ft_getopt(cfg, 'plotlegend', 'yes');
cfg.title                   = ft_getopt(cfg, 'title', '');
cfg.timeticksdiff           = ft_getopt(cfg, 'timeticksdiff', 30);
cfg.timemin                 = ft_getopt(cfg, 'timemin', 0);
cfg.timerange               = ft_getopt(cfg, 'timerange', [], true);
cfg.timeunitdisplay         = ft_getopt(cfg, 'timeunitdisplay', 'minutes');
cfg.considerdataoffset      = ft_getopt(cfg, 'considerdataoffset', 'yes');
cfg.plotsleeponset          = ft_getopt(cfg, 'plotsleeponset', 'yes');
cfg.plotsleepoffset         = ft_getopt(cfg, 'plotsleepoffset', 'yes');
cfg.plotsleepopon           = ft_getopt(cfg, 'plotsleepopon', 'yes');
cfg.plotsleepopoff          = ft_getopt(cfg, 'plotsleepopoff', 'yes');
cfg.plotlightsoff           = ft_getopt(cfg, 'plotlightsoff', 'yes');
cfg.plotlightson            = ft_getopt(cfg, 'plotlightson', 'yes');
cfg.plotindicatorssoutsidescoringtimes = ft_getopt(cfg, 'plotindicatorssoutsidescoringtimes', 'yes');
cfg.plotunknown             = ft_getopt(cfg, 'plotunknown', 'yes');
cfg.plotexcluded            = ft_getopt(cfg, 'plotexcluded', 'yes');
cfg.plotcycles            = ft_getopt(cfg, 'plotcycles', 'no');
cfg.plotepisodes            = ft_getopt(cfg, 'plotepisodes', 'no');

cfg.sleeponsetdef           = ft_getopt(cfg, 'sleeponsetdef', 'N1_XR');
cfg.classiccolor            = ft_getopt(cfg, 'classiccolor', [0 0 0]);
cfg.colorscheme             = ft_getopt(cfg, 'colorscheme', 'default');
cfg.colorblocksconnect      = ft_getopt(cfg, 'colorblocksconnect', 'no');

cfg.eventvaluerangesrnddec  = ft_getopt(cfg, 'eventrangernddec', 2);

cfg.eventmaskcolor         = ft_getopt(cfg, 'eventmaskcolor', [1 1 1]);



cfg.figureoutputformat      = ft_getopt(cfg, 'figureoutputformat', 'png');
cfg.figureoutputunit        = ft_getopt(cfg, 'figureoutputunit', 'inches');
cfg.figureoutputwidth       = ft_getopt(cfg, 'figureoutputwidth', 9);
cfg.figureoutputheight      = ft_getopt(cfg, 'figureoutputheight', 3);
cfg.figureoutputresolution  = ft_getopt(cfg, 'figureoutputresolution', 300);
cfg.figureoutputfontsize    = ft_getopt(cfg, 'figureoutputfontsize', 0.1);
cfg.figureoutputfontname    = ft_getopt(cfg, 'figureoutputfontname', 'Arial');
cfg.timestamp               = ft_getopt(cfg, 'timestamp', 'yes');
cfg.folderstructure         = ft_getopt(cfg, 'folderstructure', 'yes');
cfg.legacymode              = ft_getopt(cfg, 'legacymode', 'no');

cfg.eventcolorsbystagecolor = ft_getopt(cfg, 'eventcolorsbystagecolor', 'no');
cfg.eventheight             = ft_getopt(cfg, 'eventheight', 0.4);
cfg.eventalign              = ft_getopt(cfg, 'eventalign', 'center');
cfg.eventminscale           = ft_getopt(cfg, 'eventminscale', 0.1);
cfg.eventsmoothing          = ft_getopt(cfg, 'eventsmoothing', 'no');
cfg.offset_event_y          = ft_getopt(cfg, 'offset_event_y', 0);


if (scoring.epochlength ~= round(scoring.epochlength)) && strcmp(cfg.plottype,'classic')
    ft_error('non-integer numbers not supported for plotting of cfg.plottype = ''classic''. please round the scoring.epochlength or choose another plottype.')
end

if strcmp(cfg.considerdataoffset, 'yes')
    offsetseconds = scoring.dataoffset;
else
    offsetseconds = 0;
end

hasDT = false;
if isfield(scoring,'startdatetime')
    hasDT = true;
    startdatetime = scoring.startdatetime;
end

if isfield(cfg,'scoringstartdatetime')
    hasDT = true;
    startdatetime = cfg.scoringstartdatetime;
end

cfg.eventsmoothing_windowseconds = ft_getopt(cfg, 'eventsmoothing_windowseconds', scoring.epochlength);
cfg.eventsmoothing_timestepseconds = ft_getopt(cfg, 'eventsmoothing_timestepseconds', scoring.epochlength);
cfg.eventsmoothing_choose = ft_getopt(cfg, 'eventsmoothing_choose', 'value');
cfg.eventsmoothing_starttimeseconds = ft_getopt(cfg, 'eventsmoothing_starttime', offsetseconds);
cfg.eventsmoothing_endtimeseconds = ft_getopt(cfg, 'eventsmoothing_starttime', scoring.epochlength*numel(scoring.epochs)+offsetseconds);

%                                or 'colorblocksN3S4' plots the colorbocks
%                                or 'colorblocksN2N3S4' plots the colorbocks
%                                or 'colorblocksN1N2N3S4'

%if istrue(cfg.colorblocksconnect) && istrue(cfg.plotlegend) && (strcmp(cfg.plottype,'colorblocks') || strcmp(cfg.plottype,'colorblocksN3S4') || strcmp(cfg.plottype,'colorblocksN2N3S4') || strcmp(cfg.plottype,'colorblocksN1N2N3S4') || strcmp(cfg.plottype,'deepcolorblocks'))
%    ft_warning('cfg.colorblocksconnect = ''yes'' currently does not support the legend with cfg.plottype = ''colorblocks'' or ''deepcolorblocks'' and thus legend is DISABLED!')
%    cfg.plotlegend = 'no';
%end

if isfield(cfg, 'eventranges'), ft_error('Changed naming convention, use cfg.eventvalueranges instead of cfg.eventvalueranges'); end


% if strcmp(cfg.plottype,'colorbar') || strcmp(cfg.plottype,'colorblocks') || strcmp(cfg.plottype,'deepcolorblocks')
%     if isfield(cfg,'yaxdisteqi')
%         if ~istrue(cfg.yaxdisteqi)
%             ft_warning('cfg.yaxdisteqi is set to ''yes'' because of the cfg.plottype = %s',cfg.plottype)
%             cfg.yaxdisteqi = 'yes';
%         end
%     else
%          cfg.yaxdisteqi = 'yes';
%     end
% else
%     cfg.yaxdisteqi = ft_getopt(cfg, 'yaxdisteqi', 'no');
% end

hasEvents = false;
if isfield(cfg, 'eventtimes')
    hasEvents = true;
end

% if (isfield(cfg, 'eventtimes') && ~isfield(cfg, 'eventlabels')) || (~isfield(cfg, 'eventtimes') && isfield(cfg, 'eventlabels'))
%     ft_error('both cfg.eventtimes and cfg.eventlabels have to be defined togehter.');
% end

if (isfield(cfg, 'eventtimes') && ~isfield(cfg, 'eventlabels'))
    ft_warning('both cfg.eventtimes defined but not cfg.eventlabels aribrary event labels will be created.');
    cfg.eventlabels = arrayfun(@(s) ['ev' num2str(s)],(1:numel(cfg.eventtimes))','UniformOutput',false);
end

if (~isfield(cfg, 'eventtimes') && isfield(cfg, 'eventlabels'))
    ft_error(' cfg.eventtimes needs to be defined for the cfg.eventlabels and  have to be defined togehter.');
end




if isfield(cfg, 'eventtimes')
    nEventTypes = numel(cfg.eventtimes);
    if numel(cfg.eventtimes) ~=  numel(cfg.eventlabels)
        ft_error('dimensions of cfg.eventtimes and cfg.eventlabels do not match.');
    end
    if numel(cfg.eventheight)  > 1
        if numel(cfg.eventheight) ~=  numel(cfg.eventlabels)
            ft_error('dimensions of cfg.eventheight and cfg.eventlabels do not match.');
        end
    end
    if numel(cfg.eventminscale)  > 1
        if numel(cfg.eventminscale) ~=  numel(cfg.eventlabels)
            ft_error('dimensions of cfg.eventminscale and cfg.eventlabels do not match.');
        end
    end

    if iscell(cfg.eventalign)
        if numel(cfg.eventalign) ~=  numel(cfg.eventlabels)
            ft_error('dimensions of cfg.eventalign and cfg.eventlabels do not match.');
        end
        eventalign = cfg.eventalign;
    else
        eventalign = repmat({cfg.eventalign},nEventTypes,1);
    end

    if iscell(cfg.eventsmoothing)
        if numel(cfg.eventsmoothing) ~=  numel(cfg.eventlabels)
            ft_error('dimensions of cfg.eventsmoothing and cfg.eventlabels do not match.');
        end
    else
        eventsmoothing = repmat({cfg.eventsmoothing},nEventTypes,1);
    end


    if numel(cfg.eventsmoothing_windowseconds)  > 1
        if numel(cfg.eventsmoothing_windowseconds) ~=  numel(cfg.eventlabels)
            ft_error('dimensions of cfg.eventsmoothing_windowseconds and cfg.eventlabels do not match.');
        end
    else
        eventsmoothing_windowseconds = repmat(cfg.eventsmoothing_windowseconds,nEventTypes,1);
    end

    if numel(cfg.eventsmoothing_timestepseconds)  > 1
        if numel(cfg.eventsmoothing_timestepseconds) ~=  numel(cfg.eventlabels)
            ft_error('dimensions of cfg.eventsmoothing_timestepseconds and cfg.eventlabels do not match.');
        end
    else
        eventsmoothing_timestepseconds = repmat(cfg.eventsmoothing_timestepseconds,nEventTypes,1);
    end

    if numel(cfg.eventsmoothing_starttimeseconds)  > 1
        if numel(cfg.eventsmoothing_starttimeseconds) ~=  nEventTypes
            ft_error('dimensions of cfg.eventsmoothing_starttimeseconds and cfg.eventlabels do not match.');
        end
    else
        eventsmoothing_starttimeseconds = repmat(cfg.eventsmoothing_starttimeseconds,nEventTypes,1);
    end

    if numel(cfg.eventsmoothing_endtimeseconds)  > 1
        if numel(cfg.eventsmoothing_endtimeseconds) ~=  nEventTypes
            ft_error('dimensions of cfg.eventsmoothing_endtimeseconds and cfg.eventlabels do not match.');
        end
    else
        eventsmoothing_endtimeseconds = repmat(cfg.eventsmoothing_endtimeseconds,nEventTypes,1);
    end

    if iscell(cfg.eventsmoothing_choose)
        if numel(cfg.eventsmoothing_choose) ~=  nEventTypes
            ft_error('dimensions of cfg.eventsmoothing_choose and cfg.eventlabels do not match.');
        end
    else
        eventsmoothing_choose = repmat({cfg.eventsmoothing_choose},nEventTypes,1);
    end


end

if (isfield(cfg, 'eventvalues') && ~isfield(cfg, 'eventtimes'))
    ft_error('both cfg.eventvalues needs a cfg.eventtimes to be defined.');
end

if (~isfield(cfg, 'eventvalues') && isfield(cfg, 'eventvalueranges'))
    ft_error('cfg.eventvalues needs to be defined when cfg.eventvalueranges is defined.');
end

if isfield(cfg, 'eventvalues')
    if numel(cfg.eventtimes) ~=  numel(cfg.eventvalues)
        ft_error('dimensions of cfg.eventtimes and cfg.eventvalues do not match.');
    end
end

if isfield(cfg, 'eventdurations')
    if numel(cfg.eventtimes) ~=  numel(cfg.eventdurations)
        ft_error('dimensions of cfg.eventtimes and cfg.eventdurations do not match.');
    end

    for iEvent = 1:numel(cfg.eventtimes)
        err = false;
        size_evt = size(cfg.eventtimes{iEvent});
        size_evd = size(cfg.eventdurations{iEvent});
        if ~isempty(cfg.eventdurations{iEvent})
            if ~all(size_evt == size_evd)
                err = true;
                ft_warning('some event types in cfg.eventtimes do not match with the ones in cfg.eventdurations, for the %d event type and times (%d %d) not matching dimension of duratoins (%d %d).',iEvent,size_evt(1),size_evt(2),size_evd(1),size_evd(2))
            end
            if err
                ft_error('some event types in cfg.eventtimes do not match with the ones in cfg.eventdurations, see prior warning to find out which.');
            end
        end
    end
end



if isfield(cfg, 'eventvalueranges')
    if numel(cfg.eventtimes) ~=  numel(cfg.eventvalueranges)
        ft_error('dimensions of cfg.eventtimes and cfg.eventvalueranges do not match.');
    end
end

if isfield(cfg, 'eventvalueranges_plot')
    if numel(cfg.eventtimes) ~=  numel(cfg.eventvalueranges_plot)
        ft_error('dimensions of cfg.eventtimes and cfg.eventvalueranges_plot do not match.');
    end
end

if isfield(cfg, 'ploteventboundaryticks')
    if numel(cfg.eventtimes) ~=  numel(cfg.ploteventboundaryticks)
        ft_error('dimensions of cfg.eventtimes and cfg.ploteventboundaryticks do not match.');
    end
end

if isfield(cfg, 'eventtimes') && ~isfield(cfg, 'eventvalueranges_plot')
    cfg.eventvalueranges_plot = logical(ones(numel(cfg.eventtimes),1));
end

if isfield(cfg, 'eventtimes') && ~isfield(cfg, 'ploteventboundaryticks')
    cfg.ploteventboundaryticks = logical(ones(numel(cfg.eventtimes),1));
end

if isfield(cfg, 'eventcolors') && istrue(cfg.eventcolorsbystagecolor)
    ft_warning('cfg.eventcolors will be ignored because cfg.eventcolorsbystagecolor = ''yes''.')
end


if isfield(cfg, 'eventtimes')
    nEventsTypes = numel(cfg.eventtimes);
    if ~istrue(cfg.eventcolorsbystagecolor)
        if isfield(cfg, 'eventcolors')
            nEventColors = size(cfg.eventcolors,1);
            if(nEventColors ~= nEventsTypes)
                ft_error('number of rows in cfg.eventcolors %d does not match with number of event types %d.',nEventsTypes,nEventColors);
            end
        else %set default colors
            cfg.eventcolors = lines(nEventsTypes);
        end
    end
end


if isfield(cfg, 'eventmask')
    if numel(cfg.eventtimes) ~=  numel(cfg.eventmask)
        ft_error('dimensions of cfg.eventtimes and cfg.eventmask do not match.');
    end
end


if hasEvents
    if any(ismember(eventsmoothing,{'yes'}))
        if ~isfield(cfg,'eventtimes')
            ft_error('Need to define cfg.eventtimes for cfg.eventsmoothing = ''�es''')
        end

        nEvents = numel(cfg.eventtimes);

        for iEventTypes = 1:nEvents
            if istrue(eventsmoothing{iEventTypes})
                if ~isfield(cfg,'eventvalues')
                    if ~strcmp(eventsmoothing_choose{iEventTypes},'count')
                        ft_error('if no cfg.eventvalues are defined and cfg.eventsmoothing = ''�es'' this will only work for cfg.eventsmoothing_choose = ''count''')
                    else
                        ft_warning('No cfg.eventvalues defined for cfg.eventsmoothing = ''�es'' but with cfg.eventsmoothing_choose = ''count'' will not need them')

                    end
                end

                if ~isempty(cfg.eventtimes{iEventTypes})
                    if ~isfield(cfg,'eventdurations') || isempty(cfg.eventdurations{iEventTypes})
                        switch eventsmoothing_choose{iEventTypes}
                            case 'value'
                                evv = cfg.eventvalues{iEventTypes};
                            case 'count'
                                evv = cfg.eventtimes{iEventTypes}; %% dummy values for the count only
                        end
                        [times, windowEventsCount, property] = eventSmoother(cfg.eventtimes{iEventTypes},evv,eventsmoothing_windowseconds(iEventTypes),eventsmoothing_timestepseconds(iEventTypes),eventsmoothing_starttimeseconds(iEventTypes),eventsmoothing_endtimeseconds(iEventTypes));
                        cfg.eventtimes{iEventTypes} = times;
                        switch eventsmoothing_choose{iEventTypes}
                            case 'value'
                                cfg.eventvalues{iEventTypes} = property;
                            case 'count'
                                cfg.eventvalues{iEventTypes} = windowEventsCount;
                        end
                    end
                end
            end
        end
    end
end


saveFigure   = false;
if isfield(cfg, 'figureoutputfile')
    saveFigure = true;
end

%check whether markers were provided (could be NaN etc)
hasLightsOff = false;
if isfield(scoring, 'lightsoff')
    hasLightsOff = true;
end

hasLightsOn = false;
if isfield(scoring, 'lightson')
    hasLightsOn = true;
end

hasSleepOpportunityOn = false;
if isfield(scoring, 'sleepopon')
    hasSleepOpportunityOn = true;
end

hasSleepOpportunityOff = false;
if isfield(scoring, 'sleepopoff')
    hasSleepOpportunityOff = true;
end

fprintf([functionname ' function initialized\n']);

dummySampleRate = 100;
epochLengthSamples = scoring.epochlength * dummySampleRate;
nEpochs = numel(scoring.epochs);

% if hasLightsOff
%     lightsOffSample = scoring.lightsoff*dummySampleRate;
% else
%     lightsOffSample = 0;
% end

%convert the sleep stages to hypnogram numbers
%hypn = [cellfun(@(st) sleepStage2hypnNum(st,~istrue(cfg.plotunknown),istrue(cfg.yaxdisteqi)),scoring.epochs','UniformOutput',1) scoring.excluded'];
hypn = [cellfun(@(st) sleepStage2hypnNum(st,~istrue(cfg.plotunknown),true),scoring.epochs','UniformOutput',1) scoring.excluded'];



hypnStages = [cellfun(@sleepStage2str,scoring.epochs','UniformOutput',0) ...
    cellfun(@sleepStage2str_alt,scoring.epochs','UniformOutput',0) ...
    cellfun(@sleepStage2str_alt2,scoring.epochs','UniformOutput',0)...
    cellfun(@sleepStage2str_alt3,scoring.epochs','UniformOutput',0)];


hypnEpochs = 1:numel(scoring.epochs);
hypnEpochsBeginsSamples = (((hypnEpochs - 1) * epochLengthSamples) + 1)';

%get sleep onset according to provided definition (or default)
[onsetCandidateIndex, lastsleepstagenumber, onsetepoch, lastsleepstage, allowedsleeponsetbeforesleepopon] = st_sleeponset(cfg,scoring);

if isempty(lastsleepstagenumber)
    lastsleepstagenumber = nEpochs;
end

%get sleep cycles according to provided definition (or default)
%res_cycle = st_sleepcycles(cfg,scoring);
%cycle_table=res_cycle.table;

if istrue(cfg.plotcycles)
[cycle_table,episode_table]=st_find_cycles(cfg,scoring);
end
%combine
%res_period={res_episodeNR,res_episodeR};

%--------SET UP Y PLOTTING RANGE------

switch scoring.standard
    %center Wake at y=0, other stages negative, unknown and MT positive
    case 'aasm'
        yTick      = [1        0     -1  -2   -3   -4 ];
        yTickLabel = {'?'      'W'    'R'  'N1' 'N2' 'N3'};

    case 'rk'
        yTick      = [2   1  0     -1  -2   -3   -4   -5 ];
        yTickLabel = {'?' 'MT' 'W' 'R' 'S1' 'S2' 'S3' 'S4'};

    otherwise
        ft_error('scoring standard ''%s'' not supported for ploting.\n Maybe use ST_SCORINGCONVERT to convert the scoring first.', scoring.standard);
end

yTickLabel_mod = yTickLabel;
switch cfg.plottype
    case 'colorblocksN1N2N3S4'
        switch scoring.standard
            case 'aasm'
                yTick = yTick(1:(end-2));
                yTickLabel_mod = yTickLabel_mod(1:(end-2));
            case 'rk'
                yTick = yTick(1:(end-3));
                yTickLabel_mod = yTickLabel_mod(1:(end-3));
        end
        yTickLabel_mod{end} = 'non-REM';

    case 'colorblocksN2N3S4'
        switch scoring.standard
            case 'aasm'
                yTick = yTick(1:(end-1));
                yTickLabel_mod = yTickLabel_mod(1:(end-1));
            case 'rk'
                yTick = yTick(1:(end-2));
                yTickLabel_mod = yTickLabel_mod(1:(end-2));
        end
        yTickLabel_mod{end} = 'deeper non-REM';

    case 'colorblocksN3S4'
        switch scoring.standard
            case 'aasm'
                %yTick = yTick(1:(end-1));
                %yTickLabel = yTickLabel(1:(end-1));
            case 'rk'
                yTick = yTick(1:(end-1));
                yTickLabel_mod = yTickLabel_mod(1:(end-1));
        end
        yTickLabel_mod{end} = 'SWS';
end

%remove unknown ("?") from ytick/yticklabel if not requested
if ~istrue(cfg.plotunknown)
    tempremind = strcmp(yTickLabel_mod,'?');
    yTickLabel_mod(tempremind) = [];
    yTick(tempremind) = [];
    tempremind = strcmp(yTickLabel,'?');
    yTickLabel(tempremind) = [];
end

switch cfg.plottype
    case 'colorbar'
        %plot_exclude_offset = 1;
        yTick = [3];
        yTickLabel = {'Stage'};
        yTickLabel_mod = yTickLabel;

    otherwise

end


%----regular y plotting range---
height = 1;
yTick_Stages_range = [min(yTick)-height/2 max(yTick)+height/2]; %ytick range plus padding of half height
yTick_Stages_range_mask = [min(yTick)-height/2 (max(yTick)+min(0,cfg.offset_event_y+1.25))+height/2]; %as above, but positive val decreased when offset_event_y<-1.25

%adjust for sleep cycles
plot_cycles_offset = min(yTick) - 1.5;
if istrue(cfg.plotcycles)
    yTickLabel_mod{end+1} = 'Cycle';
    yTick(end+1) = plot_cycles_offset;
end

%adjust for periods
plot_periods_offset = min(yTick) - 1.5;
if istrue(cfg.plotepisodes)
    yTickLabel_mod{end+1} = 'Episode';
    yTick(end+1) = plot_periods_offset;
end

%adjust for excluded stages
plot_exclude_offset = min(yTick) -1.5;
if istrue(cfg.plotexcluded)
    yTickLabel_mod{end+1} = 'Excl';
    yTick(end+1) = plot_exclude_offset;
end

switch cfg.plottype
    case 'colorbar'
        if isfield(cfg,'relabelstages')
            if numel(cfg.relabelstages)==1
                if ~iscell(cfg.relabelstages)
                    cfg.relabelstages = {cfg.relabelstages};
                end
                yTickLabel_mod = cfg.relabelstages;
            else
                ft_error('the number of relabels ''%s'' must be a cell of with one string in it.',strjoin(cfg.relabelstages),strjoin(yTickLabel_mod))
            end
        end
    otherwise
        if isfield(cfg,'relabelstages')
            if numel(cfg.relabelstages)==numel(yTickLabel_mod)
                yTickLabel_mod = cfg.relabelstages;
            else
                ft_error('the relabels ''%s'' need to match the size and order of ''%s''',strjoin(cfg.relabelstages),strjoin(yTickLabel_mod))
            end
        end
end

%---------INITIALIZE FIGURE------
if isfield(cfg, 'figurehandle')
    hhyp = cfg.figurehandle;
    if ~isfield(cfg, 'figureaxishandle')
        axh = axes('Parent',hhyp);
    else
        axh = cfg.figureaxishandle;
    end
else
    hhyp = figure;
    if isfield(cfg, 'figureaxishandle')
        axh = cfg.figureaxishandle;
    else
        axh = gca;
    end
end

set(hhyp,'color',[1 1 1]);
set(axh,'FontUnits',cfg.figureoutputunit)
set(axh,'Fontsize',cfg.figureoutputfontsize);


%--------------PLOT HYPNOGRAM--------
%if istrue(cfg.colorblocksconnect)
temp_x1x2y1y2 = [];
%end

switch cfg.plottype
    case 'classic'
        %[hypn_plot_interpol hypn_plot_interpol_exclude] = interpolate_hypn_for_plot(hypn,epochLengthSamples,plot_exclude_offset,istrue(cfg.yaxdisteqi));
        [hypn_plot_interpol hypn_plot_interpol_exclude] = interpolate_hypn_for_plot(hypn,epochLengthSamples,plot_exclude_offset,true);

        x_time = (1:length(hypn_plot_interpol))/(dummySampleRate)  - 1/dummySampleRate;
        x_time = x_time + offsetseconds;
        x_time = x_time/60; % minutes
        x_time_hyp = x_time(1:length(hypn_plot_interpol));
        plot(axh,x_time_hyp,hypn_plot_interpol,'Color',cfg.classiccolor)
        hold(axh,'on');

    case {'colorblocks', 'colorbar', 'deepcolorblocks', 'colorblocksN1N2N3S4', 'colorblocksN2N3S4', 'colorblocksN3S4'}
        x_time = (0:numel(scoring.epochs)) * scoring.epochlength; %number of epochs +1
        x_time = x_time + offsetseconds;
        x_time = x_time/60; % minutes
        x_time_hyp = x_time;

        hp = [];

        labels = scoring.label;

        % swich cfg.plottype
        %     case 'colorblocksN1N2N3S4'
        %         labels = labels{ismember(labels,{''})}
        %     case 'colorblocksN2N3S4'
        %     case 'colorblocksN3S4'
        %
        % end

        [lables_colors_topdown labels_ordered] = st_epoch_colors(labels, cfg.colorscheme);
        idxUsedLabels = [];

        incLabel = 1;


        offset_y = -0.5;%(iScoring-0.5);
        %height = 1;
        heightmult = 1;
        y_hyp_pos_prev = [];


        if istrue(cfg.legacymode)
            [epoch_colors labels_ordered] = st_epoch_colors(scoring.epochs, cfg.colorscheme);

            for iEpoch = 1:numel(scoring.epochs)

                x1 = x_time(iEpoch);
                x2 = x_time(iEpoch+1);
                epoch = scoring.epochs(iEpoch);

                switch cfg.plottype
                    case 'deepcolorblocks'
                        heightmult = 1;
                        [isDeep tempepoch] = isdeep(epoch,1);
                        y_hyp_pos_S1N1 = yTick(ismember(yTickLabel,tempepoch));
                        y_hyp_pos = yTick(ismember(yTickLabel,epoch));
                        if isDeep
                            heightmult = height*(abs(y_hyp_pos_S1N1-y_hyp_pos)+1);
                        end
                    case 'colorblocks'
                        y_hyp_pos = yTick(ismember(yTickLabel,epoch));
                    case 'colorblocksN1N2N3S4'
                        [isDeep tempepoch] = isdeep(epoch,1);
                        if isDeep
                            y_hyp_pos = yTick(ismember(yTickLabel,tempepoch));
                        else
                            y_hyp_pos = yTick(ismember(yTickLabel,epoch));
                        end
                    case 'colorblocksN2N3S4'
                        [isDeep tempepoch] = isdeep(epoch,2);
                        if isDeep && ismember(epoch,{'N2','S2','N3','S3','S4'})
                            y_hyp_pos = yTick(ismember(yTickLabel,tempepoch));
                        else
                            y_hyp_pos = yTick(ismember(yTickLabel,epoch));
                        end
                    case 'colorblocksN3S4'
                        [isDeep tempepoch] = isdeep(epoch,3);
                        if isDeep && ismember(epoch,{'N3','S3','S4'})
                            y_hyp_pos = yTick(ismember(yTickLabel,tempepoch));
                        else
                            y_hyp_pos = yTick(ismember(yTickLabel,epoch));
                        end
                    case 'colorbar'
                        y_hyp_pos = yTick(1);
                end


                %if isfield(cfg,'plotunknown')
                if ~(~istrue(cfg.plotunknown) && strcmp(epoch,'?'))
                    %h = ft_plot_patch([x1 x2 x2 x1], [offset_y offset_y offset_y+height offset_y+height], 'facecolor',epoch_colors(iEpoch,:));
                    if istrue(cfg.colorblocksconnect) && ~isempty(y_hyp_pos_prev) && (y_hyp_pos_prev ~= y_hyp_pos)
                        %hold(axh,'on');
                        temp_x1x2y1y2 = cat(1,temp_x1x2y1y2,[x1 x1 y_hyp_pos+offset_y y_hyp_pos_prev+offset_y]);
                        %htmp = plot(axh,[temp_x1x2y1y2(:,1) temp_x1x2y1y2(:,2)]',[temp_x1x2y1y2(:,3) temp_x1x2y1y2(:,4)]','Color',[0.8 0.8 0.8]);
                        %htmp = plot(axh,[x1 x1],[y_hyp_pos+offset_y y_hyp_pos_prev+offset_y],'Color',[0.8 0.8 0.8]);
                        %hold(axh,'on');
                    end
                    y_hyp_pos_prev = y_hyp_pos;
                    h = patch([x1 x2 x2 x1], [y_hyp_pos+offset_y y_hyp_pos+offset_y y_hyp_pos+offset_y+height*heightmult y_hyp_pos+offset_y+height*heightmult],epoch_colors(iEpoch,:),'edgecolor','none');
                    member = find(ismember(labels,epoch),1,'first');
                    if ~ismember(member,idxUsedLabels)
                        hp(incLabel) = h;
                        incLabel = incLabel + 1;
                        idxUsedLabels = [idxUsedLabels member];
                    end
                end
                %end

                if isfield(cfg,'plotexcluded')
                    if istrue(cfg.plotexcluded) && scoring.excluded(iEpoch)
                        y_hyp_pos = yTick(end);
                        he = patch([x1 x2 x2 x1], [y_hyp_pos+offset_y y_hyp_pos+offset_y y_hyp_pos+offset_y+height y_hyp_pos+offset_y+height],[1 0 0],'edgecolor','none');
                    end
                end


            end
        else
            patches_label_x1x2y1y2 = cell(numel(labels),4);
            patches_label_x1x2y1y2_excluded = cell(1,3);
            for iEpoch = 1:numel(scoring.epochs)

                x1 = x_time(iEpoch);
                x2 = x_time(iEpoch+1);
                epoch = scoring.epochs(iEpoch);
                iLabel = find(ismember(labels,epoch),1,'first');

                switch cfg.plottype
                    case 'deepcolorblocks'
                        heightmult = 1;
                        [isDeep tempepoch] = isdeep(epoch,1);
                        y_hyp_pos_S1N1 = yTick(ismember(yTickLabel,tempepoch));
                        y_hyp_pos = yTick(ismember(yTickLabel,epoch));
                        if isDeep
                            heightmult = height*(abs(y_hyp_pos_S1N1-y_hyp_pos)+1);
                        end
                    case 'colorblocks'
                        y_hyp_pos = yTick(ismember(yTickLabel,epoch));
                    case 'colorblocksN1N2N3S4'
                        [isDeep tempepoch] = isdeep(epoch,1);
                        if isDeep
                            y_hyp_pos = yTick(ismember(yTickLabel,tempepoch));
                        else
                            y_hyp_pos = yTick(ismember(yTickLabel,epoch));
                        end
                    case 'colorblocksN2N3S4'
                        [isDeep tempepoch] = isdeep(epoch,2);
                        if isDeep && ismember(epoch,{'N2','S2','N3','S3','S4'})
                            y_hyp_pos = yTick(ismember(yTickLabel,tempepoch));
                        else
                            y_hyp_pos = yTick(ismember(yTickLabel,epoch));
                        end
                    case 'colorblocksN3S4'
                        [isDeep tempepoch] = isdeep(epoch,3);
                        if isDeep && ismember(epoch,{'N3','S3','S4'})
                            y_hyp_pos = yTick(ismember(yTickLabel,tempepoch));
                        else
                            y_hyp_pos = yTick(ismember(yTickLabel,epoch));
                        end
                    case 'colorbar'
                        y_hyp_pos = yTick(1);
                end


                %if isfield(cfg,'plotunknown')
                if ~(~istrue(cfg.plotunknown) && strcmp(epoch,'?'))
                    %h = ft_plot_patch([x1 x2 x2 x1], [offset_y offset_y offset_y+height offset_y+height], 'facecolor',epoch_colors(iEpoch,:));
                    if istrue(cfg.colorblocksconnect) && ~isempty(y_hyp_pos_prev) && (y_hyp_pos_prev ~= y_hyp_pos)
                        %hold(axh,'on');
                        temp_x1x2y1y2 = cat(1,temp_x1x2y1y2,[x1 x1 y_hyp_pos+offset_y y_hyp_pos_prev+offset_y]);
                        %htmp = plot(axh,[temp_x1x2y1y2(:,1) temp_x1x2y1y2(:,2)]',[temp_x1x2y1y2(:,3) temp_x1x2y1y2(:,4)]','Color',[0.8 0.8 0.8]);
                        %htmp = plot(axh,[x1 x1],[y_hyp_pos+offset_y y_hyp_pos_prev+offset_y],'Color',[0.8 0.8 0.8]);
                        %hold(axh,'on');
                    end
                    y_hyp_pos_prev = y_hyp_pos;
                    patches_label_x1x2y1y2{iLabel,1} = cat(2,patches_label_x1x2y1y2{iLabel,1},x1);
                    patches_label_x1x2y1y2{iLabel,2} = cat(2,patches_label_x1x2y1y2{iLabel,2},x2);
                    patches_label_x1x2y1y2{iLabel,3} = cat(2,patches_label_x1x2y1y2{iLabel,3},y_hyp_pos+offset_y);
                    patches_label_x1x2y1y2{iLabel,4} = cat(2,patches_label_x1x2y1y2{iLabel,4},y_hyp_pos+offset_y+height*heightmult);
                end
                %end

                if isfield(cfg,'plotexcluded')
                    if istrue(cfg.plotexcluded) && scoring.excluded(iEpoch)
                        y_hyp_pos = yTick(end);
                        patches_label_x1x2y1y2_excluded{1,1} = cat(2,patches_label_x1x2y1y2_excluded{1,1},x1);
                        patches_label_x1x2y1y2_excluded{1,2} = cat(2,patches_label_x1x2y1y2_excluded{1,2},x2);
                        patches_label_x1x2y1y2_excluded{1,3} = cat(2,patches_label_x1x2y1y2_excluded{1,3},y_hyp_pos+offset_y);
                    end
                end


            end

            for iLabel = 1:numel(labels)
                if ~isempty(patches_label_x1x2y1y2{iLabel,1})
                    h = patch([patches_label_x1x2y1y2{iLabel,1}' patches_label_x1x2y1y2{iLabel,2}' patches_label_x1x2y1y2{iLabel,2}' patches_label_x1x2y1y2{iLabel,1}']', ...
                        [patches_label_x1x2y1y2{iLabel,3}' patches_label_x1x2y1y2{iLabel,3}' patches_label_x1x2y1y2{iLabel,4}' patches_label_x1x2y1y2{iLabel,4}']',...
                        lables_colors_topdown(iLabel,:),'edgecolor','none');
                    if ~ismember(iLabel,idxUsedLabels)
                        hp(incLabel) = h;
                        incLabel = incLabel + 1;
                        idxUsedLabels = [idxUsedLabels iLabel];
                    end
                end
            end

            if isfield(cfg,'plotexcluded')
                if istrue(cfg.plotexcluded)
                    hex = patch([patches_label_x1x2y1y2_excluded{1,1}' patches_label_x1x2y1y2_excluded{1,2}' patches_label_x1x2y1y2_excluded{1,2}' patches_label_x1x2y1y2_excluded{1,1}']', ...
                        [patches_label_x1x2y1y2_excluded{1,3}' patches_label_x1x2y1y2_excluded{1,3}' patches_label_x1x2y1y2_excluded{1,3}'+height patches_label_x1x2y1y2_excluded{1,3}'+height]',...
                        [1 0 0],'edgecolor','none');
                end
            end
        end

        collabels = labels;
        for iLabel = 1:numel(labels)
            collabels{iLabel} = sprintf(['\\color[rgb]{%.4f,%.4f,%.4f}' labels{iLabel}],lables_colors_topdown(iLabel,1),lables_colors_topdown(iLabel,2),lables_colors_topdown(iLabel,3));
        end
        collabels = collabels(idxUsedLabels);
        [b, idx_ori_labels] = sort(idxUsedLabels);
        if istrue(cfg.plotlegend)
            hLegend = legend(hp(idx_ori_labels),collabels(idx_ori_labels),'Location','northoutside','Orientation','horizontal','Box','off');
        end
        hold(axh,'on');
    otherwise
        ft_error('cfg.plottype = %s is unknown, please see the help for available options.', cfg.plottype)
end

%plot sleep cycles
if istrue(cfg.plotcycles)


    numCycles=size(cycle_table,1);

    cycle_bar_height=0.5;
    cycle_y_hyp_pos = yTick(ismember(yTickLabel_mod ,'Cycle'));

    for cycle_i = 1:numCycles

        %start and end time
        x1 = x_time(cycle_table{cycle_i,'startepoch'});
        x2 = x_time(cycle_table{cycle_i,'endepoch'}+1);

        %patches
        XData=[x1,x1,x2,x2];
        yLow=cycle_y_hyp_pos-(cycle_bar_height/2);
        yHigh=cycle_y_hyp_pos+(cycle_bar_height/2);
        YData=[yLow,yHigh,yHigh,yLow];

        CData = [repmat([0.5, 0.5, 0.5],2,1); repmat([1, 1, 1],2,1)];
        Vertices = [XData', YData'];
        Faces = 1:size(Vertices, 1);

        %plot cycles. mark incomplete with outline
        if cycle_table{cycle_i,'complete'}==true
            patch('Faces', Faces, 'Vertices', Vertices, 'FaceVertexCData', CData, ...
                'LineStyle', '-', ...
                'LineWidth',0.5,...
                'EdgeColor',[0 0 0],...
                'FaceColor', 'interp')
        else
            patch('Faces', Faces, 'Vertices', Vertices, 'FaceVertexCData', CData, ...
                'LineStyle', '--', ...
                'LineWidth',0.5,...
                'EdgeColor',[0 0 0],...
                'FaceColor', 'interp')
        end

    end

end

%plot sleep periods
if istrue(cfg.plotepisodes)

    episodePlotOrder={'epW','epWst','epR','epNR','epNRtr','epNRfr','epNRst'};
    episode_labels=unique(episode_table.episode_label);

    episode_labels= intersect(episodePlotOrder,episode_labels,'stable');
    numEpisodeTypes=length(episode_labels);


    cycle_bar_height=1/numEpisodeTypes;
    cycle_bar_interval=1/numEpisodeTypes;

    for episode_type_i=1:numEpisodeTypes

        episode_label=episode_labels{episode_type_i};

        switch episode_label
            case 'epNR'
                startCol=st_epoch_colors({'N2'},cfg.colorscheme);
            case 'epNRst'
                startCol=st_epoch_colors({'N3'},cfg.colorscheme);
            case 'epNRfr'
                startCol=st_epoch_colors({'N1'},cfg.colorscheme);
            case 'epNRtr'
                startCol=st_epoch_colors({'N1'},cfg.colorscheme);
            case 'epR'
                startCol=st_epoch_colors({'R'},cfg.colorscheme);
            case 'epW'
                startCol=st_epoch_colors({'W'},cfg.colorscheme);
            case 'epWst'
                startCol=st_epoch_colors({'W'},cfg.colorscheme);
            otherwise
                startCol=[0 0 0 ];
        end


        current_episode_table=episode_table(strcmp(episode_table.episode_label,episode_label),:);
        numCycles=size(current_episode_table,1);

        cycle_y_hyp_pos = yTick(ismember(yTickLabel_mod ,'Episode'))+0.5-(episode_type_i)*cycle_bar_interval;


        for cycle_i = 1:numCycles

            %start and end time
            x1 = x_time(current_episode_table{cycle_i,'startepoch'});
            x2 = x_time(current_episode_table{cycle_i,'endepoch'}+1);

            %patches
            XData=[x1,x1,x2,x2];
            yLow=cycle_y_hyp_pos-(cycle_bar_height/2);
            yHigh=cycle_y_hyp_pos+(cycle_bar_height/2);
            YData=[yLow,yHigh,yHigh,yLow];

            %startCol=startCols(episode_type_i,:);
            endCol=[1 1 1 ];
            CData = [repmat(startCol,2,1); repmat(endCol,2,1)];
            Vertices = [XData', YData'];
            Faces = 1:size(Vertices, 1);

            %plot cycles. mark incomplete with outline

            patch('Faces', Faces, 'Vertices', Vertices, 'FaceVertexCData', CData, ...
                'LineStyle', '-', ...
                'LineWidth',0.5,...
                'EdgeColor',[0 0 0],...
                'FaceColor', 'interp')


        end

    end

end


%-----------------PLOT EVENTS-----------
eventTimeMaxSeconds = cfg.timemin*60;
% eventHeight = cfg.eventheight;
% offset_step = eventHeight*1.25; %0.5
offset_step_prev = 0.5;
offset_event_y = max(yTick) + cfg.offset_event_y;

switch cfg.plottype
    case {'colorbar', 'colorblocks', 'deepcolorblocks', 'colorblocksN1N2N3S4', 'colorblocksN2N3S4', 'colorblocksN3S4'}
        offset_event_y = offset_event_y - offset_y;
end


%find the maximal time of all events
max_temp_x_all = 0;
if isfield(cfg, 'eventtimes')
    for iEvent = 1:numel(cfg.eventtimes)
        if ~isempty(cfg.eventtimes{iEvent})
            if isfield(cfg, 'eventdurations')
                if ~isempty(cfg.eventdurations{iEvent})
                    max_temp_x_all = max(max_temp_x_all,max(max(cfg.eventtimes{iEvent}+cfg.eventdurations{iEvent})));
                else
                    max_temp_x_all = max(max_temp_x_all,max(max(cfg.eventtimes{iEvent})));
                end
            else
                max_temp_x_all = max(max_temp_x_all,max(max(cfg.eventtimes{iEvent})));
            end
        end
    end
end
max_temp_x_all = max_temp_x_all/60;


plotYMinorTicks = false;
eventYMinorTicks = [];
if isfield(cfg, 'eventtimes')
    nEvents = numel(cfg.eventtimes);
    if istrue(cfg.eventcolorsbystagecolor)
        [epoch_colors_unknown labels_ordered] = st_epoch_colors({'?'},cfg.colorscheme);
        [epoch_colors labels_ordered] = st_epoch_colors(scoring.epochs,cfg.colorscheme);
    else
        tempcolors = cfg.eventcolors;
    end

    for iEventTypes = 1:nEvents
        if numel(cfg.eventheight) > 1
            eventHeight = cfg.eventheight(iEventTypes);
        else
            eventHeight = cfg.eventheight;
        end
        currEvents = cfg.eventtimes{iEventTypes};
        if isfield(cfg, 'eventmask')
            currEventsMask = logical(cfg.eventmask{iEventTypes});
        end
        currEventsDurations = [];
        if isfield(cfg,'eventdurations')
            currEventsDurations = cfg.eventdurations{iEventTypes};
        end
        if ~isempty(currEvents)

            plotYMinorTicks = true;


            if numel(cfg.eventminscale) > 1
                eventminscale = cfg.eventminscale(iEventTypes);
            else
                eventminscale = cfg.eventminscale;
            end

            if istrue(eventsmoothing{iEventTypes})
                if strcmp(eventsmoothing_choose{iEventTypes},'count')
                    eventminscale = 0;
                end
            end

            offset_step = eventHeight*1.25; %0.5


            offset_event_y = offset_event_y + offset_step_prev + offset_step;
            upper_Yboundary = offset_event_y + eventHeight/2;
            lower_Yboundary = offset_event_y - eventHeight/2;
            if cfg.ploteventboundaryticks(iEventTypes)
                eventYMinorTicks = cat(2, eventYMinorTicks, [lower_Yboundary upper_Yboundary]);
            end
            offset_step_prev = offset_step;
            currEventLabel = cfg.eventlabels{iEventTypes};

            yTick = [offset_event_y yTick];
            yTickLabel_mod = {currEventLabel yTickLabel_mod{:}};

            eventTimeMaxSeconds = max([eventTimeMaxSeconds currEvents]);
            temp_x1 = (currEvents/60)';
            if ~isempty(currEventsDurations)
                temp_x2 = ((currEvents+currEventsDurations)/60)';
            else
                temp_x2 = temp_x1;
            end
            temp_y = repmat(offset_event_y,numel(currEvents),1);
            if isfield(cfg, 'eventvalues')
                currEventValues = cfg.eventvalues{iEventTypes};
                if isfield(cfg,'eventvalueranges')
                    currEventValueRanges = cfg.eventvalueranges{iEventTypes};
                    if isempty(currEventValueRanges)
                        currEventValueRanges = [min(currEventValues) max(currEventValues)];
                    end
                else
                    currEventValueRanges = [min(currEventValues) max(currEventValues)];
                end
                currEventValueRanges = round(currEventValueRanges,cfg.eventvaluerangesrnddec);
                event_scale = fw_normalize(currEventValues, min(currEventValueRanges),  max(currEventValueRanges), eventminscale, 1)';
                event_scale_null = fw_normalize(currEventValues, min(currEventValueRanges),  max(currEventValueRanges), 0, 1)';
                event_scale = event_scale(:);
                event_scale_null = event_scale_null(:);
                if cfg.eventvalueranges_plot(iEventTypes)
                    text(max_temp_x_all+1,temp_y(1),['[' num2str(min(currEventValueRanges)) ' ' num2str(max(currEventValueRanges)) ']']);
                end
            else
                event_scale = ones(1,numel(currEvents))';
            end

            if istrue(cfg.eventcolorsbystagecolor)
                iEpochs = floor(((currEvents-offsetseconds)/scoring.epochlength))+1;
                [epoch_colors labels_ordered] = st_epoch_colors(scoring.epochs,cfg.colorscheme);

                colorevs = repmat(epoch_colors_unknown,numel(iEpochs),1);
                remprepind = (iEpochs>=1) & (iEpochs<=numel(scoring.epochs));
                colorevs(remprepind,:) = epoch_colors(iEpochs(remprepind),:);

                for iEv = 1:numel(temp_x1)
                    colorev = colorevs(iEv,:);
                    switch eventalign{iEventTypes}
                        case 'center'
                            temp_plot_y = [temp_y(iEv)-(eventHeight.*event_scale(iEv))/2 temp_y(iEv)+(eventHeight.*event_scale(iEv))/2];
                        case 'bottom'
                            temp_plot_y = [temp_y(iEv)-eventHeight/2 temp_y(iEv)-eventHeight/2+(eventHeight.*event_scale(iEv))];
                        case 'top'
                            temp_plot_y = [temp_y(iEv)+eventHeight/2 temp_y(iEv)+eventHeight/2-(eventHeight.*event_scale(iEv))];
                        case 'stack'
                            temp_plot_y = [temp_y(iEv)-eventHeight/2+(eventHeight.*event_scale_null(iEv))-0.1 temp_y(iEv)-eventHeight/2+(eventHeight.*event_scale_null(iEv))+0.1];
                    end
                    if ~isempty(currEventsDurations)
                        %plot(axh,[temp_x1 temp_x2]',temp_plot_y,'Color',color)

                        %                 for iDurEv = 1:numel(temp_x1)
                        %                     hev = patch([temp_x1(iDurEv) temp_x2(iDurEv) temp_x2(iDurEv) temp_x1(iDurEv)], [temp_plot_y(1,iDurEv) temp_plot_y(1,iDurEv) temp_plot_y(2,iDurEv) temp_plot_y(2,iDurEv)],color,'edgecolor','none');
                        %                 end
                        hev = patch([temp_x1(iEv) temp_x2(iEv) temp_x2(iEv) temp_x1(iEv)]', [temp_plot_y(:,1) temp_plot_y(:,1) temp_plot_y(:,2) temp_plot_y(:,2)]',colorev,'edgecolor','none');
                        if isfield(cfg, 'eventmask')
                            if currEventsMask(iEv)
                                hev = patch([temp_x1(iEv) temp_x2(iEv) temp_x2(iEv) temp_x1(iEv)]', [yTick_Stages_range_mask(1) yTick_Stages_range_mask(1) yTick_Stages_range_mask(2) yTick_Stages_range_mask(2)]',cfg.eventmaskcolor,'edgecolor','none');
                                %hev = patch([temp_x1(iEv) temp_x2(iEv) temp_x2(iEv) temp_x1(iEv)]', [temp_plot_y(iEv,1) temp_plot_y(iEv,1) temp_plot_y(iEv,2) temp_plot_y(iEv,2)]',cfg.eventmaskcolor,'edgecolor','none');
                            end
                        end
                    else
                        plot(axh,[temp_x1(iEv) temp_x2(iEv)]',temp_plot_y,'Color',colorev)
                        %scatter([temp_x1(iEv) temp_x1(iEv)]',temp_plot_y,25,'MarkerEdgeColor','none','MarkerFaceColor',colorev,'Parent',axh)
                        if isfield(cfg, 'eventmask')
                            if currEventsMask(iEv)
                                plot(axh,[temp_x1(iEv) temp_x2(iEv)]',temp_plot_y,'Color',cfg.eventmaskcolor)
                            end
                        end
                    end
                end

            else
                color = tempcolors(iEventTypes,:);

                switch eventalign{iEventTypes}
                    case 'center'
                        temp_plot_y = [temp_y-(eventHeight.*event_scale)/2 temp_y+(eventHeight.*event_scale)/2];
                    case 'bottom'
                        temp_plot_y = [temp_y-eventHeight/2 temp_y-eventHeight/2+(eventHeight.*event_scale)];
                    case 'top'
                        temp_plot_y = [temp_y+eventHeight/2 temp_y+eventHeight/2-(eventHeight.*event_scale)];
                    case 'stack'
                        temp_plot_y = [temp_y-eventHeight/2+(eventHeight.*event_scale)-0.1 temp_y-eventHeight/2+(eventHeight.*event_scale)+0.1];
                end
                if ~isempty(currEventsDurations)
                    %plot(axh,[temp_x1 temp_x2]',temp_plot_y,'Color',color)

                    %                 for iDurEv = 1:numel(temp_x1)
                    %                     hev = patch([temp_x1(iDurEv) temp_x2(iDurEv) temp_x2(iDurEv) temp_x1(iDurEv)], [temp_plot_y(1,iDurEv) temp_plot_y(1,iDurEv) temp_plot_y(2,iDurEv) temp_plot_y(2,iDurEv)],color,'edgecolor','none');
                    %                 end
                    hev = patch([temp_x1 temp_x2 temp_x2 temp_x1]', [temp_plot_y(:,1) temp_plot_y(:,1) temp_plot_y(:,2) temp_plot_y(:,2)]',color,'edgecolor','none');
                    if isfield(cfg, 'eventmask')
                        if any(currEventsMask)
                            hev = patch([temp_x1(currEventsMask) temp_x2(currEventsMask) temp_x2(currEventsMask) temp_x1(currEventsMask)]', [(repmat(yTick_Stages_range_mask(1),numel(temp_plot_y(currEventsMask,1)),1)) (repmat(yTick_Stages_range_mask(1),numel(temp_plot_y(currEventsMask,1)),1)) (repmat(yTick_Stages_range_mask(2),numel(temp_plot_y(currEventsMask,1)),1))  repmat(yTick_Stages_range_mask(2),numel(temp_plot_y(currEventsMask,2)),1)]',cfg.eventmaskcolor,'edgecolor','none');
                            %hev = patch([temp_x1(currEventsMask) temp_x2(currEventsMask) temp_x2(currEventsMask) temp_x1(currEventsMask)]', [temp_plot_y(currEventsMask,1) temp_plot_y(currEventsMask,1) temp_plot_y(currEventsMask,2) temp_plot_y(currEventsMask,2)]',cfg.eventmaskcolor,'edgecolor','none');

                        end
                    end
                else
                    plot(axh,[temp_x1 temp_x1]',temp_plot_y','Color',color)
                    if isfield(cfg, 'eventmask')
                        if any(currEventsMask)
                            plot(axh,[temp_x1(currEventsMask) temp_x2(currEventsMask)]', [(repmat(yTick_Stages_range_mask(1),numel(temp_plot_y(currEventsMask,1)),1)) repmat(yTick_Stages_range_mask(2),numel(temp_plot_y(currEventsMask,2)),1)]','Color',cfg.eventmaskcolor)
                            %plot(axh,[temp_x1(currEventsMask) temp_x2(currEventsMask)]', temp_plot_y(currEventsMask,:)','Color',cfg.eventmaskcolor)
                        end;
                    end
                end
            end
        end
    end
end


if istrue(cfg.colorblocksconnect)
    if ~isempty(temp_x1x2y1y2)
        hold(axh,'on');
        htmp = plot(axh,[temp_x1x2y1y2(:,1) temp_x1x2y1y2(:,2)]',[temp_x1x2y1y2(:,3) temp_x1x2y1y2(:,4)]','Color',[0.8 0.8 0.8]);
    end
end


lightsoff_time = NaN;
if strcmp(cfg.plotlightsoff, 'yes')
    if hasLightsOff
        lightsoff_time = (scoring.lightsoff/60);%in minutes
        switch cfg.plottype
            case 'classic'
                onset_y_coord_offset = 0.2;
                onset_y_coord = 0+onset_y_coord_offset;
            case {'colorblocks', 'deepcolorblocks', 'colorblocksN1N2N3S4', 'colorblocksN2N3S4', 'colorblocksN3S4'}
                onset_y_coord_offset = 0.5;
                onset_y_coord =  yTick_Stages_range(2)+onset_y_coord_offset;
            case 'colorbar'
                onset_y_coord_offset = 0.5;
                onset_y_coord =  yTick_Stages_range(2)+onset_y_coord_offset;
        end
        hold(axh,'on');
        scatter(axh,lightsoff_time,onset_y_coord,'filled','s','MarkerFaceColor',[0.38 0.38 0.38],'MarkerEdgeColor',[0 0 0])
    end
end

lightson_time = NaN;
if strcmp(cfg.plotlightson, 'yes')
    if hasLightsOn
        lightson_time = (scoring.lightson/60);%in minutes
        switch cfg.plottype
            case 'classic'
                onset_y_coord_offset = 0.2;
                onset_y_coord = 0+onset_y_coord_offset;
            case {'colorblocks', 'deepcolorblocks', 'colorblocksN1N2N3S4', 'colorblocksN2N3S4', 'colorblocksN3S4'}
                onset_y_coord_offset = 0.5;
                onset_y_coord =  yTick_Stages_range(2)+onset_y_coord_offset;
            case 'colorbar'
                onset_y_coord_offset = 0.5;
                onset_y_coord =  yTick_Stages_range(2)+onset_y_coord_offset;
        end
        hold(axh,'on');
        scatter(axh,lightson_time,onset_y_coord-0.25,'filled','s','MarkerFaceColor',[1 1 0],'MarkerEdgeColor',[0 0 0])
    end
end


sleepopon_time = NaN;
if strcmp(cfg.plotsleepopon, 'yes')
    hold(axh,'on');

    switch cfg.plottype
        case 'classic'
            onset_y_coord_offset = 0.2;
            onset_y_coord = 0+onset_y_coord_offset;
        case {'colorblocks', 'deepcolorblocks', 'colorblocksN1N2N3S4', 'colorblocksN2N3S4', 'colorblocksN3S4'}
            onset_y_coord_offset = 0.5;
            onset_y_coord =  yTick_Stages_range(2)+onset_y_coord_offset;
        case 'colorbar'
            onset_y_coord_offset = 0.5;
            onset_y_coord =  yTick_Stages_range(2)+onset_y_coord_offset;
    end
    if hasSleepOpportunityOn
        sleepopon_time = (scoring.sleepopon/60);%in minutes
        scatter(axh,sleepopon_time,onset_y_coord-0.25,'filled','v','MarkerFaceColor',[0.38 0.38 0.38],'MarkerEdgeColor',[0 0 0])
    else %plot marker at start of scoring
        sleepopon_time = 0;%in minutes
        scatter(axh,sleepopon_time,onset_y_coord-0.25,'filled','v','MarkerFaceColor',[0.38 0.38 0.38],'MarkerEdgeColor',[1 0 0])
    end
end

sleepopoff_time = NaN;
if strcmp(cfg.plotsleepopoff, 'yes')
    hold(axh,'on');

    switch cfg.plottype
        case 'classic'
            onset_y_coord_offset = 0.2;
            onset_y_coord = 0+onset_y_coord_offset;
        case {'colorblocks', 'deepcolorblocks', 'colorblocksN1N2N3S4', 'colorblocksN2N3S4', 'colorblocksN3S4'}
            onset_y_coord_offset = 0.5;
            onset_y_coord =  yTick_Stages_range(2)+onset_y_coord_offset;
        case 'colorbar'
            onset_y_coord_offset = 0.5;
            onset_y_coord =  yTick_Stages_range(2)+onset_y_coord_offset;
    end

    if hasSleepOpportunityOff
        sleepopoff_time = (scoring.sleepopoff/60);%in minutes
        scatter(axh,sleepopoff_time,onset_y_coord-0.25,'filled','^','MarkerFaceColor',[0.83 0.83 0.83],'MarkerEdgeColor',[0 0 0])
    else %plot marker at end of scoring
        sleepopoff_time = ((nEpochs*scoring.epochlength)/60);%in minutes
        scatter(axh,sleepopoff_time,onset_y_coord-0.25,'filled','^','MarkerFaceColor',[0.83 0.83 0.83],'MarkerEdgeColor',[1 0 0])
    end
end

if strcmp(cfg.plotsleeponset, 'yes')
    if onsetCandidateIndex ~= -1
        onset_time = (onsetCandidateIndex-1)*(scoring.epochlength/60) + (offsetseconds/60);%in minutes
        switch cfg.plottype
            case 'classic'
                onset_y_coord_offset = 0.2;
                onset_y_coord = hypn_plot_interpol(find(x_time >=onset_time,1,'first'))+onset_y_coord_offset;
            case {'colorblocks', 'deepcolorblocks', 'colorblocksN1N2N3S4', 'colorblocksN2N3S4', 'colorblocksN3S4'}
                onset_y_coord_offset = 0.5;
                onset_y_coord =  yTick(ismember(yTickLabel_mod,scoring.epochs{onsetCandidateIndex}))+onset_y_coord_offset;
            case 'colorbar'
                onset_y_coord_offset = 0.5;
                onset_y_coord =  yTick(1)+onset_y_coord_offset;
        end
        hold(axh,'on');
        scatter(axh,onset_time,onset_y_coord+0.1,'filled','v','MarkerFaceColor',[0 1 0],'MarkerEdgeColor',[0 0 0]);
    end
end


offset_time = max(x_time);
if strcmp(cfg.plotsleepoffset, 'yes')
    if onsetCandidateIndex ~= -1
        offset_time = (lastsleepstagenumber)*(scoring.epochlength/60)+(offsetseconds/60);%in minutes
        switch cfg.plottype
            case 'classic'
                offset_y_coord_offset = 0.2;
                offset_y_coord = hypn_plot_interpol(find(x_time <=offset_time,1,'last'))+offset_y_coord_offset;
            case {'colorblocks', 'deepcolorblocks', 'colorblocksN1N2N3S4', 'colorblocksN2N3S4', 'colorblocksN3S4'}
                onset_y_coord_offset = 0.5;
                offset_y_coord =  yTick(ismember(yTickLabel_mod,scoring.epochs{lastsleepstagenumber}))+onset_y_coord_offset;
            case 'colorbar'
                onset_y_coord_offset = 0.5;
                offset_y_coord =  yTick(1)+onset_y_coord_offset;
        end
        hold(axh,'on');
        scatter(axh,offset_time,offset_y_coord+0.1,'filled','^','MarkerFaceColor',[0 0 1],'MarkerEdgeColor',[0 0 0]);
    end
end


switch cfg.plottype
    case 'classic'
        temp_max_y = max(yTick);

        if istrue(cfg.plotexcluded)
            temp_min_y = plot_exclude_offset;
        else
            temp_min_y = min(yTick) - 1;
        end
    case {'colorbar', 'colorblocks', 'deepcolorblocks', 'colorblocksN1N2N3S4', 'colorblocksN2N3S4', 'colorblocksN3S4'}
        temp_max_y = max(yTick)+0.5;
        temp_min_y = min(yTick)-0.5-0.25;

end



if isfield(cfg, 'eventtimes')
    temp_max_y = temp_max_y + eventHeight;
end


if isfield(cfg,'plotexcluded')
    if istrue(cfg.plotexcluded)
        if strcmp(cfg.plottype,'classic')
            plot(axh,x_time_hyp,hypn_plot_interpol_exclude,'Color',[1 0 0])
        end
    end
end

if ~isempty(cfg.timerange)
    xlim_range = [min(cfg.timerange) max(cfg.timerange)];
else
    if istrue(cfg.plotindicatorssoutsidescoringtimes)
        xlim_range = [min([0 lightsoff_time, lightson_time, sleepopon_time, sleepopoff_time]) (max([max(x_time), cfg.timemin, eventTimeMaxSeconds/60, offset_time, lightsoff_time, lightson_time, sleepopon_time, sleepopoff_time]))];
    else
        xlim_range = [min([0]) (max([max(x_time), cfg.timemin, eventTimeMaxSeconds/60, offset_time]))];
    end
end

xlim(axh,xlim_range)

ylabel(axh,'Stages');
ylim(axh,[temp_min_y temp_max_y+0.5])

[yTick,iyTick] = sort(yTick,'descend');
yTickLabel_mod = yTickLabel_mod(iyTick);
[yTick,iyTick,iyTickold] = unique(yTick,'stable');
yTickLabel_mod = yTickLabel_mod(iyTick);
set(axh, 'yTick', flip(yTick));
set(axh, 'yTickLabel', flip(yTickLabel_mod));
set(axh, 'TickDir','out');

negext = [];
if xlim_range(1) < 0
    negext = 0:-cfg.timeticksdiff:xlim_range(1);
    negext(1) = [];
    negext = flip(negext);
end
xTick = [negext 0:cfg.timeticksdiff:(max([max(x_time),cfg.timemin,eventTimeMaxSeconds/60]))];

set(axh, 'xTick', xTick);
timeunit = cfg.timeunitdisplay;
switch cfg.timeunitdisplay
    case {'m' 'min' 'minute' 'minutes'}
        timeunit = 'minutes';
    case {'s' 'sec' 'seconds'}
        set(axh, 'xTickLabel', arrayfun(@num2str,round(xTick*60),'UniformOutput',false));
        timeunit = 's';
    case {'h' 'hour' 'hours'}
        set(axh, 'xTickLabel', arrayfun(@num2str,round(xTick/60,2),'UniformOutput',false));
        timeunit = 'h';
    case {'d' 'day' 'days'}
        set(axh, 'xTickLabel', arrayfun(@num2str,round(xTick/(60*24),3),'UniformOutput',false));
        timeunit = 'd';
    case {'t' 'time' 'Time'}
        if hasDT && strcmp(cfg.timeunitdisplay, 'time')
            dt_xlim_start = startdatetime - seconds(offsetseconds);
            dt_xlim_end = (dt_xlim_start+minutes(diff(xlim_range)));
            dt_xlim_tick_temp = dateshift(dt_xlim_start,'start','hour'):minutes(cfg.timeticksdiff):dateshift(dt_xlim_end,'end','hour');
            dt_xlim_tick_temp = dt_xlim_tick_temp((dt_xlim_tick_temp >= dt_xlim_start) & (dt_xlim_end <= dt_xlim_end));

            dt_xlim_tick_temp_minutes_in_range = minutes(dt_xlim_tick_temp-dt_xlim_start);
            dt_xlim_tick_temp_minutes_in_range_labels = datestr(dt_xlim_tick_temp,'HH:MM');
            set(axh, 'xTick', dt_xlim_tick_temp_minutes_in_range);
            set(axh, 'xTickLabel', dt_xlim_tick_temp_minutes_in_range_labels);

        else
            ft_error('using cfg.timeunitdisplay = ''time'' you need to provide a datetime in either the scoring with scoring.startdatetime or cfg.scoringstartdatetime ')
        end

        timeunit = '';
end

set(axh, 'box', 'off')

if plotYMinorTicks && istrue(any(cfg.ploteventboundaryticks))
    axh.YAxis.MinorTick = 'on';
    axh.YAxis.MinorTickValues = eventYMinorTicks;
end

%     begsample = 0;
%     endsample = 0;
%     x_pos_begin = x_time(begsample);
%     x_pos_end = x_time(endsample);
%     x_pos = [x_pos_begin x_pos_end x_pos_end x_pos_begin];
%     y_pos = [plot_exclude_offset plot_exclude_offset 1 1];
%     pos_now = patch(x_pos,y_pos,[0.5 0.25 1],'parent',axh);
%     set(pos_now,'FaceAlpha',0.4);
%     set(pos_now,'EdgeColor','none');

%     line([x_pos_begin x_pos_begin],[plot_exclude_offset temp_max_y],'color',[0.25 0.125 1],'parent',axh);

%titleName = sprintf('Hypnogram_datasetnum_%d_file_%d',iData,iHyp);

if isfield(cfg,'xlabel')
    xlabel(axh,cfg.xlabel)
else
    if isempty(timeunit)
        xlabel(axh,['Time']);
    else
        xlabel(axh,['Time [' timeunit ']']);
    end
end

if isfield(cfg,'ylabel')
    ylabel(axh,cfg.ylabel)
else
    ylabel(axh,'Sleep stage');
end

cfg = st_adjustfigure(cfg, hhyp);

if isfield(cfg, 'figureoutputfontname')
    set(axh,'fontname',cfg.figureoutputfontname)
end
%listfonts

hold(axh,'off')

if saveFigure
    cfg.functionname = functionname;
    cfg.subfolder = 'hypnograms';
    cfg = st_savefigure(cfg, hhyp);
end
fh = hhyp;

%%% plot hypnogram figure end

fprintf([functionname ' function finished\n']);
toc(ttic)
memtoc(mtic)
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % SUBFUNCTION
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [hypn_plot_interpol hypn_plot_interpol_exclude] = interpolate_hypn_for_plot(hypn,epochLengthSamples,plot_exclude_offset, plot_yaxequidist)

if plot_yaxequidist
    remY = -1;
else
    remY  = -0.5;
end


hypn_plot = hypn;
hypn_plot_exclude = hypn_plot(:,2) ;
%hypn_plot_exclude = hypn_plot_exclude*0.5;
%hypn_plot_exclude(hypn_plot_exclude > 1) = 1.35;
hypn_plot = hypn_plot(:,1) ;
hypn_plot_interpol = [];
hypn_plot_interpol_exclude = [];
for iEp = 1:length(hypn_plot)
    temp_samples = repmat(hypn_plot(iEp),epochLengthSamples,1);
    if (hypn_plot(iEp) == remY) %REM
        if plot_yaxequidist
            temp_samples(1:2:end) = -0.5;
            temp_samples(2:2:end) = -1.5;
        else
            temp_samples(1:2:end) = -0.3;
            temp_samples(2:2:end) = -0.7;
        end

        %                 for iSamp = 1:length(temp_samples)
        %                     if mod(iSamp,2) == 0
        %                         temp_samples(iSamp) = -0.20;
        %                     else
        %                         temp_samples(iSamp) = -0.70;
        %                     end
        %                 end
    end

    hypn_plot_interpol = [hypn_plot_interpol; temp_samples];

    temp_samples_exclude = repmat(plot_exclude_offset+hypn_plot_exclude(iEp),epochLengthSamples,1);
    if (hypn_plot_exclude(iEp) > 0) %excluded
        for iSamp = 1:length(temp_samples_exclude)
            if mod(iSamp,2) == 1
                temp_samples_exclude(iSamp) = plot_exclude_offset;
            end
        end
    end
    hypn_plot_interpol_exclude = [hypn_plot_interpol_exclude; temp_samples_exclude];
end

end

function [isdeep, epoch] = isdeep(epoch, epochl)

isdeep = false;
if ismember(epoch,{'N2','N3','N4'})
    epoch = ['N' num2str(epochl)];
    isdeep = true;
end
if ismember(epoch,{'S2','S3','S4'})
    epoch = ['S1' num2str(epochl)];
    isdeep = true;
end
end
