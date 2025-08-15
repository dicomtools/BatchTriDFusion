function is3D = isBatchDicom3D(tinfo)
%function is3D = isBatchDicom3D(tinfo)
%Determines if a DICOM image represents a 3D volumetric scan.
%  DESCRIPTION:
%  This function analyzes DICOM metadata to determine whether the scan 
%  consists of multiple frames, slices, or volumetric imaging data, 
%  indicating a 3D dataset.
%
%  PARAMETERS:
%  - `tinfo` (struct): A structure containing DICOM metadata obtained 
%    from `dicominfo()`. Relevant fields include:
%      - `NumberOfFrames`
%      - `NumberOfSlices`
%      - `SliceThickness`
%      - `SpacingBetweenSlices`
%
%  FUNCTIONALITY:
%  - Checks if the `NumberOfFrames` field is present and non-empty, 
%    which typically indicates a multi-frame 3D dataset.
%  - Checks if the `NumberOfSlices` field is present and non-empty, 
%    which also suggests a volumetric scan.
%  - Evaluates `SliceThickness` and `SpacingBetweenSlices`, which 
%    indicate the presence of multiple stacked slices forming a volume.
%  - If any of the above conditions are met, the scan is classified as 3D.
%
%  RETURN VALUE:
%  - `is3D` (logical): Returns `true` if the DICOM scan is 3D, otherwise `false`.
%
%  USAGE EXAMPLE:
%     tinfo = dicominfo('example.dcm');
%     if isDicom3D(tinfo)
%         disp('The DICOM scan is a 3D volume.');
%     else
%         disp('The DICOM scan is a 2D slice.');
%     end
%
%  ERROR HANDLING:
%  - If the `tinfo` structure lacks the necessary fields, the function defaults 
%    to returning `false`.
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

    % Default to false
    is3D = false;

    % Check for multi-frame data (3D DICOM)

    if isfield(tinfo, 'NumberOfFrames') 
        
        % it's likely a 3D volume
        if ~isempty(tinfo.NumberOfFrames) 
            is3D = true;
            return;
        end
    end

    % Check for nummber of slices data (3D DICOM)

    if isfield(tinfo, 'NumberOfSlices') 

        % it's likely a 3D volume
        if ~isempty(tinfo.NumberOfSlices) 
            is3D = true;
            return;
        end
    end

    % Check for volumetric imaging data

    if isfield(tinfo, 'SliceThickness')

        % it's likely a 3D volume
        if ~isempty(tinfo.SliceThickness) 
            is3D = true;
            return;
        end
    end
    
    if isfield(tinfo, 'SpacingBetweenSlices')

        % it's likely a 3D volume
        if ~isempty(tinfo.SpacingBetweenSlices) 
            is3D = true;
            return;
        end
    end       
end