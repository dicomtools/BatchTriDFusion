function BatchTriDFusion(varargin)
%function BatchTriDFusion(varargin)
%Batch TriDFusion (3DF) Image Viewer main function.
%
%  DESCRIPTION:
%  This script facilitates batch processing of medical imaging data using
%  TriDFusion. It processes DICOM files, extracts relevant metadata, and
%  executes multiple instances of TriDFusion for parallelized analysis.
%
%  FUNCTIONALITY:
%  - Parses input arguments for workflow name, DICOM directories, and settings.
%  - Extracts patient and study information from DICOM files.
%  - Identifies and pairs corresponding PET and CT studies based on 
%    user-defined conditions.
%  - Launches multiple TriDFusion instances asynchronously for parallel
%    processing.
%  - Provides a user-friendly GUI to monitor progress.
%  - Logs processing progress and errors for troubleshooting.
%
%  USAGE:
%  This script is executed as part of a batch workflow. Parameters can be
%  provided as command-line arguments to control its behavior.
%
%  PARAMETERS:
%  - `-w`  : Workflow name (TriDFusion processing workflow).
%  - `-e`  : Number of parallel processing elements.
%  - `-p`  : TriDFusion executable path.
%  - `-c`  : Conditions file for study matching.
%  - `-l`  : Log file for progress tracking.
%
%  REQUIREMENTS:
%  - MATLAB with DICOM support.
%  - TriDFusion installed in the specified path.
%  - A valid conditions file in XML format for study matching.
%
%Author: Daniel Lafontaine, lafontad@mskcc.org
%
%Last specifications modified:
%
% Copyright 2025, Daniel Lafontaine, on behalf of the BatchTriDFusion development team.
% 
% This file is part of The Batch TriDFuison (BatchTriDFusion).
% 
% BatchTriDFusion development has been led by: Daniel Lafontaine
% 
% BatchTriDFusion is distributed under the terms of the Lesser GNU Public License. 
% 
%     This version of BatchTriDFusion is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
% BatchTriDFusion is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
% without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% See the GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with BatchTriDFusion.  If not, see <http://www.gnu.org/licenses/>.
    
    try

%     outputBatchVaragin(varargin, 'c:\Temp\BatchTriDFusion_arguments.txt');

    asMainDirArg = cell(1, 1000);
    sWorkflowName = [];
    sOutputPath = [];
    sConditionFile = [];
    sLogProgressFile = [];
    dNbParallelElements = 1;        

    bSkipNextArgument = false;
    argLoop=1;
    for k = 1 : length(varargin)

        sSwitchAndArgument = char(varargin{k});

        sSwitchAndArgument = replace(sSwitchAndArgument, '"', '');
        sSwitchAndArgument = replace(sSwitchAndArgument, ']', '');
        sSwitchAndArgument = replace(sSwitchAndArgument, '[', '');

        switch lower(sSwitchAndArgument)
            
            case '-r' % Output directory

                sOutputPath = char(varargin{k+1});
                sOutputPath = strrep(strrep(strrep(sOutputPath, '"', ''), '[', ''), ']', '');

                if ~endsWith(sOutputPath, '/') && ~endsWith(sOutputPath, '\')

                    sOutputPath = sprintf('%s/', sOutputPath);   
                end

                bSkipNextArgument = true;                                    

            case '-w' % TriDFusion Workflow name

                sWorkflowName = char(varargin{k+1});
                sWorkflowName = strrep(strrep(strrep(sWorkflowName, '"', ''), '[', ''), ']', '');
           
                bSkipNextArgument = true;                                    

            case '-e' % Number of parallel elements

                sNbParallelElements = char(varargin{k+1});
                sNbParallelElements = strrep(strrep(strrep(sNbParallelElements, '"', ''), '[', ''), ']', '');

                dNbParallelElements = str2double(sNbParallelElements);

                bSkipNextArgument = true;                                    

            case '-p' % TriDFusion Path
                    
                sTriDFusionPath = char(varargin{k+1});
                sTriDFusionPath = strrep(strrep(strrep(sTriDFusionPath, '"', ''), '[', ''), ']', '');

                if ~endsWith(sTriDFusionPath, '/') && ~endsWith(sTriDFusionPath, '\')
                    sTriDFusionPath = sprintf('%s/', sTriDFusionPath);                     
                end
                bSkipNextArgument = true;                                  

            case '-c' % Conditions file
                
                sConditionFile = char(varargin{k+1});
                sConditionFile = strrep(strrep(strrep(sConditionFile, '"', ''), '[', ''), ']', '');
                
                bSkipNextArgument = true;                                    

            case '-l' % Log progress

                sLogProgressFile = char(varargin{k+1});
                sLogProgressFile = strrep(strrep(strrep(sLogProgressFile, '"', ''), '[', ''), ']', '');

                bSkipNextArgument = true; 

            otherwise
                
                if bSkipNextArgument == false % The output dir is set before

                    asMainDirArg{argLoop} = sSwitchAndArgument;

                     if ~endsWith(asMainDirArg{argLoop}, '/') && ~endsWith(asMainDirArg{argLoop}, '\')

                        asMainDirArg{argLoop} = sprintf('%s/',asMainDirArg{argLoop});                     
                    end
                    argLoop = argLoop+1;                     
                else
                    bSkipNextArgument = false;
                end
        end
    end            

    % Remove all empty cell

    asMainDirArg = asMainDirArg(~cellfun(@isempty, asMainDirArg)); 

    % Set up initial figure size.
    figWidth  = 640;
    figHeight = 480;

    % Get screen size (note the property is 'ScreenSize' with a capital S)
    aScreenSize = get(groot, 'ScreenSize');
    xPosition = (aScreenSize(3) / 2) - (figWidth / 2);
    yPosition = (aScreenSize(4) / 2) - (figHeight / 2);

    % Create a new uifigure with a SizeChangedFcn callback.
    uiBatchMainFigure = uifigure('Name'              , 'Batch TriDFusion', ...
                                 'NumberTitle'       , 'off', ...
                                 'Units'             , 'pixels', ...
                                 'Position'          , [xPosition, ...
                                                        yPosition, ...
                                                        figWidth, ...
                                                        figHeight], ...
                                 'AutoResizeChildren', 'off', ...
                                 'SizeChangedFcn'    , @resizeListbox);

    sRootPath = getBatchRootPath();
    
    if ~isempty(sRootPath)

        sLogoFile = fullfile(sRootPath, 'logo.png');

        if isfile(sLogoFile)

            uiBatchMainFigure.Icon = sLogoFile;
        end
    end

    drawnow;
    drawnow;
    
    % Get initial dimensions.

    aPosition = uiBatchMainFigure.Position;
    H = aPosition(4);
    W = aPosition(3);

    % Calculate component heights.
    % uiDisplay occupies the bottom 1/3 of the figure.
    % The remaining 2/3 is equally split among three list boxes: each gets (2H/3)/3 = 2H/9.
    
    % Create lbFileAssociation (top of the three listboxes).
    lbFileAssociation = uilistbox(uiBatchMainFigure, ...
                                  'Position'   , [0, H/3 + 4*H/9, W, 2*H/9], ...
                                  'Items'      , {''}, ...
                                  'FontSize'   , 13, ...
                                  'FontWeight' , 'bold', ...
                                  'FontName'   , 'Monospaced', ...
                                  'Multiselect', 'on');

    % Create lbFileDescription (middle listbox).
    lbFileDescription = uilistbox(uiBatchMainFigure, ...
                                  'Position'   , [0, H/3 + 2*H/9, W, 2*H/9], ...
                                  'Items'      , {''}, ...
                                  'FontSize'   , 13, ...
                                  'FontWeight' , 'bold', ...
                                  'FontName'   , 'Monospaced', ...
                                  'Multiselect', 'on');

    % Create lbFileList (bottom listbox above uiDisplay).
    lbFileList = uilistbox(uiBatchMainFigure, ...
                           'Position'   , [0, H/3, W, 2*H/9], ...
                           'Items'      , asMainDirArg, ...
                           'FontSize'   , 13, ...
                           'FontWeight' , 'bold', ...
                           'FontName'   , 'Monospaced', ...
                           'Multiselect', 'on');

    % Create uiDisplay as a uilabel (bottom 1/3 of the figure).
    uiDisplay = uilabel(uiBatchMainFigure, ...
                        'Text', '', ...
                        'HorizontalAlignment', 'left', ...
                        'Position', [0, 0, W, H/3]);

    acDICOM = cell(1, 1000000);
    dOffset = 1;

    for i=1:numel(asMainDirArg)

        sCurrentDir = asMainDirArg{i};

        asfileList = dir(fullfile(sCurrentDir, '*.*')); % Get all files
        
        
        % Count only files (exclude directories)
        dTotalNbFiles = numel(asfileList(~[asfileList.isdir]));

        %[tSpacial,dDimension] = getBatchDicomSpacial(sCurrentDir);
        % 
        % if isempty(dDimension) || isempty(tSpacial)
        %     continue;
        % end
          
        for j = 1:numel(asfileList)

            if asfileList(j).isdir

                continue; % Skip directories, only check files
            end  

            sFilePath = fullfile(asfileList(j).folder, asfileList(j).name);

            tinfo = getBatchDicomInfo(sFilePath);

            % Check if the file is a valid DICOM file
            if ~isempty(tinfo) % Found a vild DICOM file.

                % Robustly extracts key DICOM information from tinfo.
                tDicomEntry = parseBatchDicomInfo(tinfo); 

                acDICOM{dOffset}.PatientName         = tDicomEntry.PatientName;
                acDICOM{dOffset}.PatientID           = tDicomEntry.PatientID;
                acDICOM{dOffset}.Accession           = tDicomEntry.Accession;
                acDICOM{dOffset}.StudyInstanceUID    = tDicomEntry.StudyInstanceUID;
                acDICOM{dOffset}.SeriesInstanceUID   = tDicomEntry.SeriesInstanceUID;
                acDICOM{dOffset}.FrameOfReferenceUID = tDicomEntry.FrameOfReferenceUID;
                acDICOM{dOffset}.Modality            = tDicomEntry.Modality;
                acDICOM{dOffset}.ScanType            = classifyBatchDicomScan(tinfo);
                acDICOM{dOffset}.Orientation         = getBatchDicomOrientation(tinfo);
                acDICOM{dOffset}.Is3D                = isBatchDicom3D(tinfo);
                acDICOM{dOffset}.FilesFolder         = asfileList(j).folder;
                if isfield(tDicomEntry, 'NumberOfSlices')
                    acDICOM{dOffset}.NumberOfSlices = tDicomEntry.NumberOfSlices;
                else
                    acDICOM{dOffset}.NumberOfSlices = dTotalNbFiles;
                end
                dOffset = dOffset+1;
                break;
            end
        end
    end

    acDICOM = acDICOM(~cellfun(@isempty, acDICOM)); 

    % Convert struct array to cell array of strings for display
    lbFileDescription.Items = cellfun(@(x) sprintf('%s - %s - %s - %s - %s - %s - %s - %s - %d', x.PatientName, x.PatientID,  x.Accession, x.StudyInstanceUID, x.SeriesInstanceUID, x.Modality, x.ScanType, x.Orientation, x.Is3D), acDICOM, 'UniformOutput', false);

    if isempty(sConditionFile)
        sConditionFile = sprintf('%sconditions.xml',sRootPath);
    end

    acMatching = findBatchMatchingStudies(acDICOM, sConditionFile);
    % lbFileAssociation.Items = cellfun(@(x) sprintf('%s - %s - %s - %s - %s', x.PatientName, x.PatientID, x.Accession, x.StudyInstanceUID, x.PTSeriesInstanceUID, x.CTSeriesInstanceUID), acMatching, 'UniformOutput', false);
    lbFileAssociation.Items = cellfun(@(x) sprintf(...
        '%s - %s - %s - %s - %s - %s', ...
        x.PatientName, ...
        x.PatientID, ...
        x.Accession, ...
        x.StudyInstanceUID, ...
        x.PTSeriesInstanceUID, ...
        x.CTSeriesInstanceUID), ...
        acMatching, ...
        'UniformOutput', false);
    
    % Initialize an empty cell array to store the last 5 messages
    asRecentMessages = repmat({''}, 5, 1); % Create a cell array of empty strings
    
    dNbElements = numel(acMatching);
    hh = 1;

    % Continue looping while there are still elements to process OR any TriDFusion.exe is running
    while hh <= dNbElements || checkRunningProcesses()
        
        % Check how many TriDFusion processes are running
        numRunning = countTriDFusionProcesses();
        
        % If there are elements left and we haven't reached the maximum concurrent limit, launch a new instance
        if hh <= dNbElements && numRunning < dNbParallelElements

            if ~isempty(acMatching{hh}.PTSeriesInstanceUID) && ~isempty(acMatching{hh}.CTSeriesInstanceUID)
                
                % Create the current message
                sCurrentMessage = sprintf('Processing %d/%d PT %s with CT %s', hh, dNbElements, ...
                    acMatching{hh}.PTSeriesInstanceUID, acMatching{hh}.CTSeriesInstanceUID);
                
                % Shift messages down and insert the new message at the top
                asRecentMessages = [{sCurrentMessage}; asRecentMessages(1:end-1)];
                
                % Update the UI label with the last 5 messages (using \n for line breaks)
                uiDisplay.Text = sprintf('%s\n%s\n%s\n%s\n%s', asRecentMessages{:});
                
                % Refresh the UI
                drawnow;
                
                % Prepare optional arguments
                wArg = '';
                if ~isempty(sWorkflowName)
                    wArg = [' -w ' sWorkflowName];
                end
                oArg = '';
                if ~isempty(sOutputPath)
                    oArg = [' -r ' sOutputPath];
                end
                
                % Launch TriDFusion.exe asynchronously
                system(['start "" "', sTriDFusionPath, 'TriDFusion.exe" "', acMatching{hh}.PTFilesFolder, '" "', acMatching{hh}.CTFilesFolder, '"', wArg, oArg]);
                
                % Log successful progress
                logBatchProgress(acMatching{hh}, sLogProgressFile, 1);
            else
                % Log failure or missing data
                logBatchProgress(acMatching{hh}, sLogProgressFile, 2);
            end
            
            % Move to the next element
            hh = hh + 1;
            
        else
            % If we have reached the concurrency limit, wait a bit before rechecking
            pause(1);
        end
    end

    catch ME    

        logBatchProgress(acMatching{hh}, sLogProgressFile, 3);               

        if isempty(sRootPath)

            sRootPath = 'c:\Temp\';
        end

        logBatchErrorToFile(ME, sprintf('%sbatch_error_log.txt', sRootPath));
    end

    function tinfo = getBatchDicomInfo(sFilePath)
        try
            tinfo = dicominfo(sFilePath);
        catch
            tinfo =[];   
        end
    end

    % function [tSpatial,dDim] = getBatchDicomSpacial(asfileList)
    % 
    %     try
    %         [~,tSpatial,dDim] = dicomreadVolume(asfileList);
    %     catch
    %         tSpatial = [];
    %         dDim     = [];
    %     end
    % 
    % end

    % Callback function for resizing the figure.
    function resizeListbox(fig, ~)
        % Get the updated figure size.
        aPosition = fig.Position;
        H = aPosition(4);
        W = aPosition(3);
        
        % uiDisplay: bottom 1/3 of the figure.
        uiDisplay.Position = [0, 0, W, H/3];
        
        % lbFileList: occupies the next 2*H/9 above uiDisplay.
        lbFileList.Position = [0, H/3, W, 2*H/9];
        
        % lbFileDescription: above lbFileList.
        lbFileDescription.Position = [0, H/3 + 2*H/9, W, 2*H/9];
        
        % lbFileAssociation: at the top of the 2/3 region.
        lbFileAssociation.Position = [0, H/3 + 4*H/9, W, 2*H/9];
    end
    
    % This function checks if any TriDFusion.exe processes are running.
    function running = checkRunningProcesses()
        [~, taskList] = system('tasklist /FI "IMAGENAME eq TriDFusion.exe"');
        running = contains(taskList, 'TriDFusion.exe');
    end
    
    % This function counts the number of running TriDFusion.exe processes.
    function count = countTriDFusionProcesses()
        [~, taskList] = system('tasklist /FI "IMAGENAME eq TriDFusion.exe"');
        % Use regular expressions to find all occurrences
        tokens = regexp(taskList, 'TriDFusion.exe', 'match');
        count = numel(tokens);
    end
end