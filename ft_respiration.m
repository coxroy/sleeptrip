function [dataout] = ft_respiration(cfg, datain)

% FT_RESPIRATION estimates the respiration rate from a respiration belt, temperature
% sensor, movement sensor or from the heart rate. It returns a new data structure
% with a continuous representation of the rate and phase.
%
% Use as
%   dataout = ft_respiration(cfg, data)
% where the input data is a structure as obtained from FT_PREPROCESSING.
%
% The configuration structure has the following options
%   cfg.channel          = selected channel for processing, see FT_CHANNELSELECTION
%   cfg.peakseparation   = scalar, time in seconds
%   cfg.envelopewindow   = scalar, time in seconds
%   cfg.feedback         = 'yes' or 'no'
% The input data can be preprocessed on the fly using
%   cfg.preproc.bpfilter = 'yes' or 'no' (default = 'yes')
%   cfg.preproc.bpfreq   = [low high], filter frequency in Hz
%
% See also FT_HEARTRATE, FT_ELECTRODERMALACTIVITY, FT_HEADMOVEMENT, FT_REGRESSCONFOUND

% Copyright (C) 2018, Robert Oostenveld, DCCN
%
% This file is part of FieldTrip, see http://www.fieldtriptoolbox.org
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the initial part deals with parsing the input options and data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% these are used by the ft_preamble/ft_postamble function and scripts
ft_revision = '$Id$';
ft_nargin   = nargin;
ft_nargout  = nargout;

% the ft_preamble function works by calling a number of scripts from
% fieldtrip/utility/private that are able to modify the local workspace

ft_defaults
ft_preamble init
ft_preamble debug
ft_preamble loadvar    datain
ft_preamble provenance datain
ft_preamble trackconfig

% the ft_abort variable is set to true or false in ft_preamble_init
if ft_abort
  % do not continue function execution in case the outputfile is present and the user indicated to keep it
  return
end

% check if the input data is valid for this function, the input data must be raw
datain = ft_checkdata(datain, 'datatype', 'raw', 'feedback', 'yes');

% check if the input cfg is valid for this function
cfg = ft_checkconfig(cfg, 'forbidden',  {'channels'}); % prevent accidental typos, see issue 1729

% set the default options
cfg.channel          = ft_getopt(cfg, 'channel', {});
cfg.envelopewindow   = ft_getopt(cfg, 'envelopewindow', []);  % in seconds
cfg.peakseparation   = ft_getopt(cfg, 'peakseparation', 3);   % in seconds
cfg.feedback         = ft_getopt(cfg, 'feedback', 'yes');
cfg.preproc          = ft_getopt(cfg, 'preproc', []);

% the expected respiration rate is around 0.40 Hz
cfg.preproc.bpfilter    = ft_getopt(cfg.preproc, 'bpfilter', 'yes');
cfg.preproc.bpfilttype  = ft_getopt(cfg.preproc, 'bpfilttype', 'but');
cfg.preproc.bpfiltdir   = ft_getopt(cfg.preproc, 'bpfiltdir', 'twopass');
cfg.preproc.bpfiltord   = ft_getopt(cfg.preproc, 'bpfiltord', 2);
cfg.preproc.bpfreq      = ft_getopt(cfg.preproc, 'bpfreq', [1/3 3] * 0.40);  % in Hz

% copy some of the fields over to the new data structure
dataout = keepfields(datain, {'time', 'fsample', 'sampleinfo', 'trialinfo'});
dataout.label = {'respirationrate', 'respirationphase', 'respirationonset'};
dataout.trial = {};  % this is to be determined in the main code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the actual computation is done in the middle part
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

cfg.channel = ft_channelselection(cfg.channel, datain.label);
assert(numel(cfg.channel)==1, 'you should specify exactly one channel');

chansel = strcmp(datain.label, cfg.channel{1});
fsample = datain.fsample;

for trllop=1:numel(datain.trial)
  dat   = datain.trial{trllop}(chansel,:);
  label = datain.label(chansel);
  time  = datain.time{trllop};
  
  if ~isempty(cfg.peakseparation)
    [yupper,ylower] = envelope(dat, round(cfg.peakseparation*fsample), 'peaks');
  elseif ~isempty(cfg.envelopewindow)
    [yupper,ylower] = envelope(dat, round(cfg.envelopewindow*fsample), 'rms');
  end
  
  if istrue(cfg.feedback)
    figure
    subplot(5,1,1)
    hold on
    plot(time, dat)
    plot(time, yupper, 'g');
    plot(time, ylower, 'g');
    xlim([min(time) max(time)])
    xlabel('time (s)');
    title(sprintf('original, trial %d', trllop))
  end
  
  if ~isempty(cfg.preproc)
    % apply the preprocessing to the selected channel
    [dat, label, time, cfg.preproc] = preproc(dat, label, time, cfg.preproc, 0, 0);
  end
  
  if ~isempty(cfg.peakseparation)
    [yupper,ylower] = envelope(dat, round(cfg.peakseparation*fsample), 'peaks');
  elseif ~isempty(cfg.envelopewindow)
    [yupper,ylower] = envelope(dat, round(cfg.envelopewindow*fsample), 'rms');
  end
  
  if istrue(cfg.feedback)
    subplot(5,1,2)
    hold on
    plot(time, dat)
    plot(time, yupper, 'g');
    plot(time, ylower, 'g');
    xlim([min(time) max(time)])
    xlabel('time (s)');
    title('filtered')
  end
  
  dat = (dat - ylower) ./ (yupper - ylower);
  
  if ~isempty(cfg.peakseparation)
    [yupper,ylower] = envelope(dat, round(cfg.peakseparation*fsample), 'peaks');
  elseif ~isempty(cfg.envelopewindow)
    [yupper,ylower] = envelope(dat, round(cfg.envelopewindow*fsample), 'rms');
  end
  
  if istrue(cfg.feedback)
    subplot(5,1,3)
    hold on
    plot(time, dat)
    plot(time, yupper, 'g');
    plot(time, ylower, 'g');
    xlim([min(time) max(time)])
    xlabel('time (s)');
    title('locally rescaled')
  end
  
  x = angle(hilbert(dat));
  % apply the same preprocessing to the phase timeseries
  y = preproc(x, label, time, cfg.preproc, 0, 0);
  % find the downward going zero-crossings
  onset = findzerocrossing(y, fsample/10);
  
  % construct a continuous channel with the rate and the phase
  rate  = nan(size(dat));
  phase = nan(size(dat));
  for i=1:length(onset)-1
    begsample = onset(i);
    endsample = onset(i+1);
    rate(begsample:endsample)  = fsample/(endsample-begsample);
    phase(begsample:endsample) = linspace(-pi, pi, (endsample-begsample+1));
  end
  % also construct a boolean channel with a pulse at the respiration onset
  tmp = zeros(size(dat));
  tmp(onset) = 1;
  
  % add the continuous channels to the output structure
  dataout.trial{trllop} = [rate; phase; tmp];
  
  if istrue(cfg.feedback)
    subplot(5,1,4)
    plot(time, rate)
    xlim([min(time) max(time)])
    xlabel('time (s)');
    ylabel('rate (Hz)');
  end
  
  if istrue(cfg.feedback)
    subplot(5,1,5)
    plot(time, phase)
    xlim([min(time) max(time)])
    xlabel('time (s)');
    ylabel('phase');
  end
  
  ft_info('breathing rate in trial %d: mean=%.2f, min=%.2f, max=%.2f\n', trllop, nanmean(rate), nanmin(rate), nanmax(rate));
  
end % for trllop

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% deal with the output
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ft_postamble debug
ft_postamble trackconfig
ft_postamble previous   datain
ft_postamble provenance dataout
ft_postamble history    dataout
ft_postamble savevar    dataout

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUBFUNCTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function indx = findzerocrossing(x, n)
bool = x(1:(end-n))>0 & x((1+n):end)<0;
indx = find(diff([0 bool])>0);
indx = indx + ceil(n/2);