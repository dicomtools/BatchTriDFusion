function acMatching = findBatchMatchingStudies(acDICOM, sConditionFile)
%function acMatching = findBatchMatchingStudies(acDICOM, sConditionFile)
%Matches PET and CT studies based on XML conditions.
%  DESCRIPTION:
%  This function processes a list of DICOM studies and identifies matching 
%  PET and CT scans based on predefined conditions specified in an XML file.
%  The matching criteria include modality, scan type, orientation, and whether
%  the scan is 3D.
%
%  PARAMETERS:
%  - 'acDICOM' (cell array): A list of structures containing parsed DICOM metadata, 
%    including:
%      - 'PatientName', 'PatientID', 'Accession'
%      - 'StudyInstanceUID', 'SeriesInstanceUID'
%      - 'Modality', 'ScanType', 'Orientation', 'Is3D', 'FilesFolder'
%  - 'sConditionFile' (string): Path to an XML file specifying the matching criteria 
%    for PET and CT studies.
%
%  FUNCTIONALITY:
%  - Loads and parses the XML condition file to extract matching rules for PET and CT.
%  - Iterates through unique 'StudyInstanceUID's in 'acDICOM'.
%  - Checks for PET and CT scans that match the extracted XML conditions.
%  - If both a PET and CT scan satisfy the conditions within the same study, they are paired.
%  - Stores matched PET/CT studies in an output structure.
%
%  RETURN VALUE:
%  - 'acMatching' (cell array): A structured list of matched PET/CT studies.
%    Each entry contains:
%      - 'PatientName', 'PatientID', 'Accession'
%      - 'StudyInstanceUID'
%      - 'PTSeriesInstanceUID', 'CTSeriesInstanceUID'
%      - 'PTFilesFolder', 'CTFilesFolder'
%
%  USAGE EXAMPLE:
%     acDICOM = {...}; % Preloaded DICOM metadata
%     sConditionFile = 'conditions.xml';
%     acMatching = findMatchingStudies(acDICOM, sConditionFile);
%
%  XML FILE STRUCTURE EXAMPLE:
%  xml
%  <Conditions>
%      <PET>
%          <Modality>PT</Modality>
%          <ScanType>AC</ScanType>
%          <Orientation>Axial</Orientation>
%          <Is3D>True</Is3D>
%      </PET>
%      <CT>
%          <Modality>CT</Modality>
%          <ScanType>AC</ScanType>
%          <Orientation>Axial</Orientation>
%          <Is3D>True</Is3D>
%      </CT>
%  </Conditions>
%
%  ERROR HANDLING:
%  - If 'sConditionFile' is missing or invalid, the function returns an empty list.
%  - If no valid matches are found, 'acMatching' remains empty.
%  - If any required fields are missing in 'acDICOM', the study is skipped.
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

    % Load conditions from an XML file
    docNode = xmlread(sConditionFile);
    
    % Parse PET conditions
    petNode = docNode.getElementsByTagName('PET').item(0);
    petModality = char(petNode.getElementsByTagName('Modality').item(0).getTextContent());
    petScanType = char(petNode.getElementsByTagName('ScanType').item(0).getTextContent());
    petOrientation = char(petNode.getElementsByTagName('Orientation').item(0).getTextContent());
    petIs3D = char(petNode.getElementsByTagName('Is3D').item(0).getTextContent());
    if strcmpi(petIs3D, 'True')
        petIs3D = true;
    end  

    % Parse CT conditions
    ctNode = docNode.getElementsByTagName('CT').item(0);
    ctModality = char(ctNode.getElementsByTagName('Modality').item(0).getTextContent());
    ctScanType = char(ctNode.getElementsByTagName('ScanType').item(0).getTextContent());
    ctOrientation = char(ctNode.getElementsByTagName('Orientation').item(0).getTextContent());
    ciIs3D = char(ctNode.getElementsByTagName('Is3D').item(0).getTextContent());
    if strcmpi(ciIs3D, 'True')
        ciIs3D = true;
    end
 
    % Initialize output structure
    acMatching = cell(1, 10000);
    
    % Extract unique StudyInstanceUIDs from the DICOM data
    uniqueStudies = unique(cellfun(@(x) x.StudyInstanceUID, acDICOM, 'UniformOutput', false));

    dNbDicomImages = numel(acDICOM);

    acModalityInfo = cell(1, dNbDicomImages);
    for nn = 1:dNbDicomImages

        if strcmpi(acDICOM{nn}.Modality, petModality)
            acModalityInfo{nn}.Modality          = petModality;
            acModalityInfo{nn}.SeriesInstanceUID = acDICOM{nn}.SeriesInstanceUID;
            acModalityInfo{nn}.FrameOfReferenceUID = acDICOM{nn}.FrameOfReferenceUID;
        end

        if strcmpi(acDICOM{nn}.Modality, ctModality)
            acModalityInfo{nn}.Modality          = ctModality;
            acModalityInfo{nn}.SeriesInstanceUID = acDICOM{nn}.SeriesInstanceUID;
            acModalityInfo{nn}.FrameOfReferenceUID = acDICOM{nn}.FrameOfReferenceUID;
        end
    end

    acModalityInfo = acModalityInfo(~cellfun(@isempty, acModalityInfo)); 
    dNbSlices  = numel(acModalityInfo);

    dMatching = 1;
    % Loop through each unique StudyInstanceUID
    for ii = 1:numel(uniqueStudies)

        % Initialize default empty values

        PTAssociatedCT  = cell(1, 10000);
        CTAssociatedPT  = cell(1, 10000);

        PTSeriesInstanceUID = cell(1, 10000);
        CTSeriesInstanceUID = cell(1, 10000);
    
        PTFilesFolder = cell(1, 10000);
        CTFilesFolder = cell(1, 10000);

        PTNumberOfSlices = cell(1, 10000);
        CTNumberOfSlices = cell(1, 10000);

        PTFrameOfReferenceUID = cell(1, 10000);
        CTFrameOfReferenceUID = cell(1, 10000);

        dPTOffset = 1;
        dCTOffset = 1;

        studyUID = uniqueStudies{ii};

        % Loop through acDICOM to find entries matching this StudyInstanceUID
        for jj = 1:dNbDicomImages

            if strcmp(acDICOM{jj}.StudyInstanceUID, studyUID)

                for mm=1:dNbSlices

                    % Check for PET AC using XML-based conditions
                    if strcmpi(acDICOM{jj}.Modality, petModality) && ...
                       strcmpi(acDICOM{jj}.ScanType, petScanType) && ...
                       strcmpi(acDICOM{jj}.Orientation, petOrientation) && ...
                       acDICOM{jj}.Is3D == petIs3D && ...
                       strcmpi(acModalityInfo{mm}.Modality,ctModality) && ... % We need the same FrameOfReferenceUID than the CT
                       strcmpi(acModalityInfo{mm}.FrameOfReferenceUID, acDICOM{jj}.FrameOfReferenceUID) 
    
                        PTSeriesInstanceUID{dPTOffset}   = acDICOM{jj}.SeriesInstanceUID;
                        PTFilesFolder{dPTOffset}         = acDICOM{jj}.FilesFolder;
                        PTAssociatedCT{dPTOffset}        = acModalityInfo{mm}.SeriesInstanceUID;
                        PTNumberOfSlices{dPTOffset}      = acDICOM{jj}.NumberOfSlices;
                        PTFrameOfReferenceUID{dPTOffset} = acDICOM{jj}.FrameOfReferenceUID;

                        dPTOffset = dPTOffset+1;
                    end
                        
                    % Check for CT AC using XML-based conditions
                    if strcmpi(acDICOM{jj}.Modality, ctModality) && ...
                       strcmpi(acDICOM{jj}.ScanType, ctScanType) && ...
                       strcmpi(acDICOM{jj}.Orientation, ctOrientation) && ...
                       acDICOM{jj}.Is3D == ciIs3D && ...
                       strcmpi(acModalityInfo{mm}.Modality, petModality) && ... % We need the same FrameOfReferenceUID than the PC
                       strcmpi(acModalityInfo{mm}.FrameOfReferenceUID, acDICOM{jj}.FrameOfReferenceUID) 
                       
                        CTSeriesInstanceUID{dCTOffset}   = acDICOM{jj}.SeriesInstanceUID;
                        CTFilesFolder{dCTOffset}         = acDICOM{jj}.FilesFolder;
                        CTAssociatedPT{dCTOffset}        = acModalityInfo{mm}.SeriesInstanceUID;
                        CTNumberOfSlices{dCTOffset}      = acDICOM{jj}.NumberOfSlices;
                        CTFrameOfReferenceUID{dCTOffset} = acDICOM{jj}.FrameOfReferenceUID;
                        
                        dCTOffset = dCTOffset+1;
                    end                                       
                end                 
            end
        end      
    
        PTSeriesInstanceUID   = PTSeriesInstanceUID(~cellfun(@isempty, PTSeriesInstanceUID));
        PTFilesFolder         = PTFilesFolder(~cellfun(@isempty, PTFilesFolder));
        PTAssociatedCT        = PTAssociatedCT(~cellfun(@isempty, PTAssociatedCT));
        PTNumberOfSlices      = PTNumberOfSlices(~cellfun(@isempty, PTNumberOfSlices));
        PTFrameOfReferenceUID = PTFrameOfReferenceUID(~cellfun(@isempty, PTFrameOfReferenceUID));

        CTSeriesInstanceUID   = CTSeriesInstanceUID(~cellfun(@isempty, CTSeriesInstanceUID));
        CTFilesFolder         = CTFilesFolder(~cellfun(@isempty, CTFilesFolder));
        CTAssociatedPT        = CTAssociatedPT(~cellfun(@isempty, CTAssociatedPT));
        CTNumberOfSlices      = CTNumberOfSlices(~cellfun(@isempty, CTNumberOfSlices));
        CTFrameOfReferenceUID = CTFrameOfReferenceUID(~cellfun(@isempty, CTFrameOfReferenceUID));

        for tt = 1:numel(PTAssociatedCT)

            for rr = 1:numel(CTAssociatedPT)

                if strcmpi(PTAssociatedCT{tt}, CTSeriesInstanceUID{rr})
                    
                    % Check if this PT or CT is already matched
                    alreadySetPT = false;
                    alreadySetCT = false;

                    if exist('acMatching', 'var') && ~isempty(acMatching)

                        for idx = 1:length(acMatching)

                            % Check if current PTSeriesInstanceUID is already used
                            if isfield(acMatching{idx}, 'PTSeriesInstanceUID') && ...
                               strcmpi(acMatching{idx}.PTSeriesInstanceUID, PTSeriesInstanceUID{tt})
                                alreadySetPT = true;
                            end

                            % Check if current CTSeriesInstanceUID is already used
                            if isfield(acMatching{idx}, 'CTSeriesInstanceUID') && ...
                               strcmpi(acMatching{idx}.CTSeriesInstanceUID, CTSeriesInstanceUID{rr})
                                alreadySetCT = true;
                            end
                        end
                    end
                    
                    % Only add a new match if neither has been set before

                    if ~alreadySetPT && ~alreadySetCT
                        % For patient information, we use one of the matching acDICOM entries
                        % (ensure this is appropriate for your application)
                        ptUID = PTSeriesInstanceUID{tt};
                        ptIdx = find( ...
                            cellfun(@(x) strcmp(x.SeriesInstanceUID, ptUID), acDICOM), ...
                            1, 'first' ...
                        );
                        
                        % now use that to populate your patient fields:
                        acMatching{dMatching}.PatientName      = acDICOM{ptIdx}.PatientName;
                        acMatching{dMatching}.PatientID        = acDICOM{ptIdx}.PatientID;
                        acMatching{dMatching}.Accession        = acDICOM{ptIdx}.Accession;
                        acMatching{dMatching}.StudyInstanceUID    = studyUID;
                        acMatching{dMatching}.PTSeriesInstanceUID = PTSeriesInstanceUID{tt};
                        acMatching{dMatching}.CTSeriesInstanceUID = CTSeriesInstanceUID{rr};
                        acMatching{dMatching}.PTFilesFolder       = PTFilesFolder{tt};
                        acMatching{dMatching}.CTFilesFolder       = CTFilesFolder{rr};  
                        acMatching{dMatching}.PTNumberOfSlices    = PTNumberOfSlices{tt};  
                        acMatching{dMatching}.CTNumberOfSlices    = CTNumberOfSlices{rr};  
                        acMatching{dMatching}.PTFrameOfReferenceUID = PTFrameOfReferenceUID{tt};  
                        acMatching{dMatching}.CTFrameOfReferenceUID = CTFrameOfReferenceUID{rr};  
                     
                        dMatching = dMatching + 1;
                    end
                end
            end
        end
    end
    
    % Remove any empty cells from the output
    acMatching = acMatching(~cellfun(@isempty, acMatching));

    % --- Verification Step ---

    % Loop over each pair of matches in acMatching

    nMatches = numel(acMatching);
    for i = 1:nMatches-1
        for j = i+1:nMatches
            
            % Check if these two matching entries share the same identifier fields
            if strcmp(acMatching{i}.PatientName, acMatching{j}.PatientName) && ...
               strcmp(acMatching{i}.PatientID, acMatching{j}.PatientID) && ...
               strcmp(acMatching{i}.Accession, acMatching{j}.Accession) && ...
               strcmp(acMatching{i}.StudyInstanceUID, acMatching{j}.StudyInstanceUID) && ...
               strcmp(acMatching{i}.PTFrameOfReferenceUID, acMatching{j}.PTFrameOfReferenceUID) && ...
               strcmp(acMatching{i}.CTFrameOfReferenceUID, acMatching{j}.CTFrameOfReferenceUID)
           
                % For clarity, define local variables for the slice counts:
                PTSlices_i = acMatching{i}.PTNumberOfSlices;
                CTSlices_i = acMatching{i}.CTNumberOfSlices;
                PTSlices_j = acMatching{j}.PTNumberOfSlices;
                CTSlices_j = acMatching{j}.CTNumberOfSlices;
                
                % Compute differences between expected matching fields
                % We assume that in a correctly paired match, the PTNumberOfSlices of one 
                % should be numerically similar to the PTNumberOfSlices of the other,
                % and likewise for CTNumberOfSlices. If the PTNumberOfSlices of one is closer
                % to the CTNumberOfSlices of the other, that suggests that the CT numbers need to swap.
                diffPT_i_vs_CT_j = abs(PTSlices_i - CTSlices_j);
                diffPT_i_vs_PT_j = abs(PTSlices_i - PTSlices_j);
                diffCT_i_vs_PT_j = abs(CTSlices_i - PTSlices_j);
                diffCT_i_vs_CT_j = abs(CTSlices_i - CTSlices_j);
                
                % If the PT slice count of the first is closer to the second's CT count,
                % and the CT slice count of the first is closer to the second's PT count,
                % we assume that the CT fields in the two matches are swapped.
                if (diffPT_i_vs_CT_j < diffPT_i_vs_PT_j) && (diffCT_i_vs_PT_j < diffCT_i_vs_CT_j)
                    % Swap CT fields between the two instances:
                    tempCTSeriesInstanceUID = acMatching{i}.CTSeriesInstanceUID;
                    tempCTFilesFolder       = acMatching{i}.CTFilesFolder;
                    tempCTNumberOfSlices    = acMatching{i}.CTNumberOfSlices;
                    
                    acMatching{i}.CTSeriesInstanceUID = acMatching{j}.CTSeriesInstanceUID;
                    acMatching{i}.CTFilesFolder       = acMatching{j}.CTFilesFolder;
                    acMatching{i}.CTNumberOfSlices    = acMatching{j}.CTNumberOfSlices;
                    
                    acMatching{j}.CTSeriesInstanceUID = tempCTSeriesInstanceUID;
                    acMatching{j}.CTFilesFolder       = tempCTFilesFolder;
                    acMatching{j}.CTNumberOfSlices    = tempCTNumberOfSlices;
                    
                    %fprintf('Swapped CT fields between match %d and %d\n', i, j);
                end
            end
        end
    end

end