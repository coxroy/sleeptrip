function fw_write_edf_define(filename, hdr, data);
% WRITE_EDF(filename, header, data)
% Writes a EDF file from the given header (only label, Fs, nChans are of interest)
% and the data (unmodified). Digital and physical limits are derived from the data
% via min and max operators. The EDF file will contain N records of 1 sample each,
% where N is the number of columns in 'data'.
%
% For sampling rates > 1 Hz, this means that the duration of one data "record"
% is less than 1s, which some EDF reading programs might complain about. At the
% same time, there is an upper limit of how big (in bytes) a record should be,
% which we could easily violate if we write the whole data as *one* record.

% Copyright (C) 2010, Stefan Klanke
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
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
% $Id: write_edf.m 7123 2012-12-06 21:21:38Z roboos $

[nChans,N] = size(data);
if hdr.nChans ~= nChans
    error 'Data dimension does not match header information';
end
fSample = real(hdr.Fs(1)); % make sure this is a scalar + real

if nChans > 9999
    error 'Cannot write more than 9999 channels to an EDF file.';
end
if N > 99999999
    error 'Cannot write more than 99999999 data records (=samples) to an EDF file.';
end

labels = char(32*ones(nChans, 16));
% labels
for n=1:nChans
    ln = length(hdr.label{n});
    if ln > 16
        fprintf(1, 'Warning: truncating label %s to %s\n', hdr.label{n}, hdr.label{n}(1:16));
        ln = 16;
    end
    labels(n,1:ln) = hdr.label{n}(1:ln);
end

if ~isreal(data)
    error 'Cannot write complex-valued data.';
end


if ~isfield(hdr,'edf_accuracy')
    hdr.edf_accuracy = 1;
end

if ~isfield(hdr,'edf_doautoscale')
    hdr.edf_doautoscale = false;
end

if ~isfield(hdr,'edf_docutoff')
    hdr.edf_docutoff = false;
end

if ~hdr.edf_doautoscale
    
    uV_accuracy = hdr.edf_accuracy;
    scaling_factor = 1/uV_accuracy;
    data = scaling_factor*data;
    
else % do auto scaling
    maxV_temp = max(data, [], 2);
    minV_temp = min(data, [], 2);
    
    scaling_factor = (32767 + 32768 - 2)./(2*max(abs(maxV_temp), abs(minV_temp)));
    uV_accuracies = 1/scaling_factor;
    uV_accuracy = min(uV_accuracies);
    for iCh = 1:size(data,1)
        data(iCh,:) = scaling_factor(iCh).*data(iCh,:);
    end
end

if hdr.edf_docutoff || hdr.edf_doautoscale
    data(find(data > 32767)) = 32767;
    data(find(data < -32768)) = -32768;
end

maxV = max(data, [], 2);
minV = min(data, [], 2);


if ~strcmp(class(data),'int16')
    warning('Warning: data type is not int16, saving to EDF might introduce round-off errors.');
    if max(maxV) > 32767 | min(minV) < -32768
        error('Data cannot be represented as signed 16-bit integers');
    end
    data = int16(data);
end

maxV = double(max(data, [], 2));
minV = double(min(data, [], 2));

% the following lines avoid issue of not being able to open due to digital or
% physical minimum and maximum being the same, e.g. in EDFbrowser

digMin = minV;
digMax = maxV;

iDigMinEqMax = (digMin == digMax);
if any(iDigMinEqMax)
   digMin(iDigMinEqMax) = max(-32768, digMin(iDigMinEqMax) - 1);
   digMax(iDigMinEqMax) = min(32767, digMax(iDigMinEqMax) + 1);
end

physMin = int32(digMin./scaling_factor);
physMax = int32(digMax./scaling_factor);

iPhysMinEqMax = (physMin == physMax);
if any(iPhysMinEqMax)
   physMin(iPhysMinEqMax) = physMin(iPhysMinEqMax) - 1;
   physMax(iPhysMinEqMax) = physMax(iPhysMinEqMax) + 1;
end

digMin = sprintf('%-8i', digMin);
digMax = sprintf('%-8i', digMax);
physMin = sprintf('%-8i', physMin);
physMax = sprintf('%-8i', physMax);


fid = fopen(filename, 'wb', 'ieee-le');
% first write fixed part
fprintf(fid, '0       ');   % version
fprintf(fid, '%-80s', '<no patient info>');
fprintf(fid,'%-80s', '<no local recording info>');

c = clock;
fprintf(fid, '%02i.%02i.%02i', c(3), c(2), mod(c(1),100)); % date as dd.mm.yy
fprintf(fid, '%02i.%02i.%02i', c(4), c(5), round(c(6))); % time as hh.mm.ss

fprintf(fid, '%-8i', 256*(1+nChans));  % number of bytes in header
fprintf(fid, '%44s', ' '); % reserved (44 spaces)
fprintf(fid, '%-8i', N);  % number of data records
fprintf(fid, '%8f', 1/hdr.Fs);  % duration of data record (=1/Fs)
fprintf(fid, '%-4i', nChans);  % number of signals = channels

fwrite(fid, labels', 'char*1'); % labels
fwrite(fid, 32*ones(80,nChans), 'uint8'); % transducer type (all spaces)
fwrite(fid, 32*ones(8,nChans), 'uint8'); % phys dimension (all spaces)
fwrite(fid, physMin', 'char*1'); % physical minimum
fwrite(fid, physMax', 'char*1'); % physical maximum
fwrite(fid, digMin', 'char*1'); % digital minimum
fwrite(fid, digMax', 'char*1'); % digital maximum
fwrite(fid, 32*ones(80,nChans), 'uint8'); % prefiltering (all spaces)
for k=1:nChans
    fprintf(fid, '%-8i', 1); % 1 sample pre record (each channel)
end
fwrite(fid, 32*ones(32,nChans), 'uint8'); % reserverd (32 spaces / channel)

% now write data
fwrite(fid, data, 'int16');
fclose(fid);
