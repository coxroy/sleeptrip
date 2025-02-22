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

cfg = [];
cfg.renderer = 'opengl';
bg_options = {'white', 'dark'};
[indx,tf] = listdlg('PromptString',{'Select a background color.'},...
    'SelectionMode','single','ListString',bg_options, 'InitialValue',1);
cfg.bgcolor = 'white'; %'dark' or 'white'
if tf
    cfg.bgcolor = bg_options{indx};
end
cfg.datainteractive = 'yes';
cfg.colorgroups = 'jet';
cfg.colorgroups = 'jet';
cfg_new = st_scorebrowser(cfg);