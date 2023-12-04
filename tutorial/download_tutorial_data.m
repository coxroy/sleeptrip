%location of current file
thisFile=mfilename('fullpath');
tutorialFolder=fileparts(thisFile);

%location where tutorial_data should end up
tutorialDataFolder=fullfile(tutorialFolder,'tutorial_data');

if ~isfolder(tutorialDataFolder)

    % dataset doi (resolves to latest version)
    initialDOI='10.5281/zenodo.10256036';
    initialURL=['https://zenodo.org/doi/' initialDOI];

    % determine where DOI resolves to
    redirectedURL = webread(initialURL);

    % Extract DOI from the redirected URL
    doiPattern = '10.\d+\/zenodo.\d+';
    doi = regexp(redirectedURL, doiPattern, 'match');
    if isempty(doi)
        error('Failed to extract DOI from the URL.');
    end
    doi = doi{1};

    %extract doi number
    doiSimplePattern='\d+$'; %final numbers
    doiSimple=regexp(doi,doiSimplePattern,'match');
    doiSimple=doiSimple{1};

    %download link
    fileURL='tutorial_data.zip';
    downloadURL=['https://zenodo.org/records/' doiSimple '/files/tutorial_data.zip?download=1'];


    % Use the websave function to download the zip file
    mkdir(tutorialDataFolder)

    fprintf('downloading %s...\n',fileURL)
    targetPath=fullfile(tutorialDataFolder,fileURL);
    websave(targetPath, downloadURL);

    %unzip
    fprintf('unzipping...\n')
    unzip(targetPath,tutorialDataFolder)

    %remove zip
    fprintf('removing zip...\n')
    delete(targetPath)

    % Inform the user that the download is complete
    fprintf('finished\n');

end

