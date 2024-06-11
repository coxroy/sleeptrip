function data=st_repair_artifacts(cfg_artifacts,data)

% ST_REPAIR_ARTIFACTS repairs channels segment-wise, as specified by
% a repair grid (typically created by ST_PROCESS_DETECTOR_RESULTS). Repair methods are interpolation, replace with zeros, or replace with NaNs).
%
% Use as:
%     data=st_repair_artifacts(cfg_artifacts,data)
%
% Required configuration parameters:
%     cfg_artifacts.artifacts.grid      = structure containing segment-based artifact grids (including repair grid)
%     data          =  data structure to be cleaned
%
% Optional configuration parameters:
%    cfg_artifacts.gridtypeforrepair = name of grid to use as the repair matrix. All grids present in cfg_artifacts.artifacts.grid are valid, including grids created manually. (default: 'repair_grid')
%    cfg_artifacts.repairmethod = repair options 'interpolate','replacewithzero','replacewithnan'. (default: 'interpolate')
%    cfg_artifacts.smoothafterinterpolation = when repairmethod is 'interpolate', whether to smooth discontinuities across segment boundaries (default: 'yes')
%    cfg_artifacts.smoothdatawindow = length of window centered on segment boundary, in seconds (default: 0.2 s)
%    cfg_artifacts.smoothmethod = method used for smoothing: see Matlab's smoothdata options (default: 'gaussian')
%    cfg_artifacts.smoothwindow = length of smoothing window, in seconds (default: 0.1 s).
%
% Output:
%     data =  segment-wise interpolated data
%
% See also ST_PROCESS_DETECTOR_RESULTS ST_GET_DEFAULT_DETECTOR_SET ST_RUN_DETECTOR_SET

% Copyright (C) 2022-, Roy Cox, Frederik D. Weber
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
st_defaults

%---input checks----
ft_checkconfig(cfg_artifacts,'required',{'artifacts'});
ft_checkconfig(cfg_artifacts.artifacts,'required',{'grid'});
cfg_grid=cfg_artifacts.artifacts.grid;

%----defaults----
%default grid to use for repairing
cfg_artifacts.gridtypeforrepair  = ft_getopt(cfg_artifacts, 'gridtypeforrepair', 'repair_grid');
repair_grid=cfg_grid.(cfg_artifacts.gridtypeforrepair); %get the requested grid

%default repair method
cfg_artifacts.repairmethod= ft_getopt(cfg_artifacts,'repairmethod','interpolate');
repair_method=cfg_artifacts.repairmethod;

%smoothing options
cfg_artifacts.smoothafterinterpolation= ft_getopt(cfg_artifacts,'smoothafterinterpolation','yes');
cfg_artifacts.smoothmethod=ft_getopt(cfg_artifacts,'smoothmethod','gaussian');

%window surrounding boundary taken for smoothing
cfg_artifacts.smoothdatawindow=ft_getopt(cfg_artifacts,'smoothdatawindow',0.2); %0.2 s surrounding segment boundary
wnd_data_smooth_sample=round((cfg_artifacts.smoothdatawindow/2)*data.fsample); %convert to samples

%smoothing window
cfg_artifacts.smoothwindow=ft_getopt(cfg_artifacts,'smoothwindow',0.1);
wnd_smooth_sample=round((cfg_artifacts.smoothwindow)*data.fsample); %convert to samples
%----end defaults---


[numChan,numSegments]=size(repair_grid);

elec=cfg_artifacts.elec;

segmentLengthSample=round(cfg_grid.segment_length*data.fsample);

repairSegment_inds=find(any(repair_grid,1));

fprintf('repairing %i of %i segments using method %s\n',length(repairSegment_inds),numSegments,repair_method)

for segment_i=repairSegment_inds

    %get segment start/ends
    segment_start_sample=(segment_i-1)*segmentLengthSample+1;
    segment_end_sample=segment_i*segmentLengthSample;

    %check we're inside the data range
    if segment_end_sample>data.sampleinfo(2)
        segment_end_sample=data.sampleinfo(2);
    end

    badInds=find(repair_grid(:,segment_i)==1);
    goodInds=find(repair_grid(:,segment_i)==0);

    switch repair_method
        case 'interpolate'

            %reimplementation of Fieldtrip's channel interpolation
            repair  = eye(numChan, numChan); %set diagonals to 1

            for bad_i=1:length(badInds)
                repair(badInds(bad_i),badInds(bad_i))=0; %set diagonal of bad chan to 0
                distance = sqrt(sum((elec.chanpos(goodInds, :) - repmat(elec.chanpos(badInds(bad_i), :), length(goodInds), 1)).^2, 2));

                repair(badInds(bad_i), goodInds) = (1./distance);
                repair(badInds(bad_i), goodInds) = repair(badInds(bad_i), goodInds) ./ sum(repair(badInds(bad_i), goodInds));
            end

            %replace original data with repair*original (matrix multiplication)
            segment_dat=data.trial{1}(:,segment_start_sample:segment_end_sample);
            segment_dat_interp=repair*segment_dat;

            data.trial{1}(:,segment_start_sample:segment_end_sample)=segment_dat_interp;

            %smooth across interpolation boundaries
            if istrue(cfg_artifacts.smoothafterinterpolation) && segment_i>1 %smoothing "backwards", so segment needs to be >1

                %find channels interpolated in previous or current segment
                badInds_prev=find(repair_grid(:,segment_i-1)==1);
                badInds_all=union(badInds_prev,badInds);

                smooth_start_sample=segment_start_sample-wnd_data_smooth_sample;
                smooth_end_sample=segment_start_sample+wnd_data_smooth_sample;

                %check we're inside the data range
                if smooth_start_sample<data.sampleinfo(1)
                    smooth_start_sample=data.sampleinfo(1);
                end

                if smooth_end_sample>data.sampleinfo(2)
                    smooth_end_sample=data.sampleinfo(2);
                end

                %extract data
                segment2_dat=data.trial{1}(badInds_all,smooth_start_sample:smooth_end_sample);

                %smooth
                segment2_dat_smth=smoothdata(segment2_dat,2,cfg_artifacts.smoothmethod,wnd_smooth_sample);

                %assign back to data
                data.trial{1}(badInds_all,smooth_start_sample:smooth_end_sample)=segment2_dat_smth;


            end

        case 'replacewithzero'
            data.trial{1}(badInds,segment_start_sample:segment_end_sample)=0;
        case 'replacewithnan'
            data.trial{1}(badInds,segment_start_sample:segment_end_sample)=NaN;

    end

end

fprintf([functionname ' function finished\n']);
toc(ttic)
memtoc(mtic)