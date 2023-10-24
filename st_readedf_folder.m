function data=st_readedf_folder(edf_folder,varargin)

%handle situation of (nested) cells
while iscell(edf_folder)
    edf_folder=edf_folder{:};
end

if ~isfolder(edf_folder)
    ft_error('%s does not appear to be a folder',edf_folder)
end

%locate edf files in folder
edfChannelFiles=dir([edf_folder,filesep,'*.edf']);

if nargin>1
    requestedChannelsFileNames=varargin{1};

    %check whether requested channels exist
    [isM, fileInd]=ismember(requestedChannelsFileNames,erase({edfChannelFiles.name},'.edf'));

    edfChannelFiles=edfChannelFiles(fileInd);
end

%loop across edf files and read
fileData={};
for chan_i=1:length(edfChannelFiles)
    channelName=edfChannelFiles(chan_i).name;
    
    %read
    fprintf('reading file %s\n',channelName)
    file_data=st_readedf(fullfile(edf_folder,channelName));

    %fix for handling identical channel names
    [~,filebase]=fileparts(channelName);
    file_data.label=strcat(file_data.label, '-', filebase); %name as "channel name-file name"

    fileData{end+1}=file_data;

end

%inlcude only channels/files with common sample rate
srate_Files=cellfun(@(X) X.fsample,fileData);

srate_identical=srate_Files==max(srate_Files);
if ~all(srate_identical)
    ft_warning('dropping %i channel(s) with inconsistent sample rate',length(find(~srate_identical)))
    fileData=fileData(srate_identical);
end


%combine channels
data=ft_appenddata([],fileData{:});
hdr=ft_fetch_header(data);
data.hdr=hdr;