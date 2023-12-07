function freq_data=st_welch(cfg,data)

% ST_WELCH runs Matlab's pwelch function on (optionally trial-based) data,
% and returns the spectrum (power spectral density or power)
%
% Use as:
%     freq_data=st_welch(cfg,data)
%
% Optional configuration parameters:
%     cfg.method      =  spectrumtype for pwelch ('psd' [default] or 'power')
%     cfg.windowlength    = pwelch window length (in sec). default: 5
%     cfg.windowoverlap = pwelch window overlap proportion (between 0 and 1). default: 0.5
%
%     cfg.channel = cell array of channel labels to consider
%
% Output:
%     freq_data = Fieltrip-like structure of spectral estimates
%

% Copyright (C) 2023-, Roy Cox, Frederik D. Weber
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

%use ft_selectdata for channel selection
data = ft_selectdata(cfg, data);

%pwelch options
cfg.method = ft_getopt(cfg, 'method','psd');
cfg.windowlength=ft_getopt(cfg, 'windowlength',5);
cfg.windowoverlap=ft_getopt(cfg, 'windowoverlap',0.5);


sRate=data.fsample;

%Matlab's pwelch function
[pow_psd,freq_welch]=pwelch(cell2mat(data.trial)',sRate*cfg.windowlength,cfg.windowoverlap*sRate*cfg.windowlength,[],sRate,cfg.method);

freq_data.label=data.label;
freq_data.dimord='chan_freq';
freq_data.freq=freq_welch';
freq_data.powspctrm=pow_psd';