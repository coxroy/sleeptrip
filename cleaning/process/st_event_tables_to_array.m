function cfg_artifacts=st_event_tables_to_array(cfg_artifacts)

% ST_EVENT_TABLES_TO_ARRAY converts continuous artifacts (as detected by ST_RUN_DETECTOR_SET) to segment-based artifact grids
%
% Use as:
%     cfg=st_event_tables_to_array(cfg)
%
% Required configuration parameters (all automatically supplied by ST_RUN_DETECTOR_SET):
%     cfg.continuous      = structure containing continuous artifact event tables
%
% Optional configuration parameters (subfield grid):
%     cfg.segment_length = length of grid segments in seconds (default: 5)
%     cfg.minimum_segment_coverage = proportion of segment that needs to be covered by event in order to label grid element as artifact (default: 0 ->
%     always label, even if single sample)
%     cfg.merge_detectors = cell array of strings, with names of each detector to include for compuation of artifact grid. (default: 'all' [string])
%
% Output:
%     cfg = artifact configuration with added artifact grids:
%     - cfg.grid.artifact_grid_merged
%     - cfg.grid.artifact_grid_by_type
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

%---input checks and defaults----
ft_checkconfig(cfg_artifacts.artifacts,'required',{'raw_events'});

%grid field may or may not exist
if isfield(cfg_artifacts.artifacts,'grid')
    cfg_grid=cfg_artifacts.artifacts.grid;
else
    cfg_grid=[];
end

%---set defaults--
cfg_artifacts.segment_length  = ft_getopt(cfg_artifacts, 'segment_length', 5);%5 s window
cfg_artifacts.minimum_segment_coverage = ft_getopt(cfg_artifacts, 'minimum_segment_coverage', 0);
cfg_artifacts.merge_detectors=ft_getopt(cfg_artifacts,'merge_detectors','all');


cfg_grid.segment_length=cfg_artifacts.segment_length; %copy over to grid

%extract event tables of requested artifact types
detectorLabelsAvailable=fieldnames(cfg_artifacts.artifacts.raw_events)';
if strcmp(cfg_artifacts.merge_detectors,'all')
    %select artifacts from all detectors
    includeDetectorLabels=detectorLabelsAvailable;
else
    %include only artifacts from requested detectors
    includeDetectorLabels=intersect(detectorLabelsAvailable,cfg_artifacts.merge_detectors);
end


cfg_grid.label=includeDetectorLabels;
numArtifactTypes=length(includeDetectorLabels);

data=cfg_artifacts.data;
numSample=data.sampleinfo(2)-data.sampleinfo(1)+1;

segment_length=cfg_artifacts.segment_length;
segment_length_sample=segment_length*data.fsample;

numSeg  = ceil(numSample/segment_length_sample); %includes final, incomplete segment (handled later)
cfg_grid.segment_number=numSeg;

chanLabels=cfg_artifacts.data.label;
numChan=length(chanLabels);

cfg_grid.channel_number=numChan;

%ignore designated segments
cfg_artifacts.segment_ignore=ft_getopt(cfg_artifacts, 'segment_ignore', false(1,numSeg));


%initalize logical artifact matrix
artifact_grid_by_type = false(numArtifactTypes,numChan,numSeg);
segment_time_offset=(data.sampleinfo(1)-1)/data.fsample; %in case event tables were created from data not starting at t=0
for artType_i=1:numArtifactTypes
    event_table=cfg_artifacts.artifacts.raw_events.(includeDetectorLabels{artType_i}).events;
    numEvents=size(event_table,1);

    for ev_i=1:numEvents

        evStart=event_table{ev_i,{'start'}}-segment_time_offset; %in sec since start of current data
        evEnd=event_table{ev_i,{'stop'}}-segment_time_offset;

        evChan=event_table{ev_i,{'channel'}};
        chan_ind=find(strcmp(chanLabels,evChan));

        segStart=floor(evStart/segment_length)+1;
        segEnd=floor(evEnd/segment_length)+1;

        %segments covered by event
        seg_inds=segStart:segEnd;

        if numel(seg_inds)>1 %separate start and end segments
            startSeg_covered=1-(rem(evStart,segment_length)/segment_length);
            endSeg_covered=rem(evEnd,segment_length)/segment_length;

            if startSeg_covered<cfg_artifacts.minimum_segment_coverage
                seg_inds(1)=[];
            end

            if endSeg_covered<cfg_artifacts.minimum_segment_coverage
                seg_inds(end)=[];
            end

        else %single segment
            seg_covered=(evEnd-evStart)/segment_length;

            if seg_covered<cfg_artifacts.minimum_segment_coverage
                seg_inds=[];
            end

        end

        artifact_grid_by_type(artType_i,chan_ind,seg_inds)= true;
    end



end

%mask with segments to ignore
artifact_grid_by_type=artifact_grid_by_type & ~permute(repmat(cfg_artifacts.segment_ignore,[numArtifactTypes,1,numChan]),[1 3 2]);

%merge all remaining event types
artifact_grid_merged=squeeze(any(artifact_grid_by_type,1));

%assign to cfg
cfg_grid.artifact_grid_by_type=artifact_grid_by_type;
cfg_grid.artifact_grid_merged=artifact_grid_merged;

cfg_artifacts.artifacts.grid=cfg_grid;

fprintf([functionname ' function finished\n']);
toc(ttic)
memtoc(mtic)