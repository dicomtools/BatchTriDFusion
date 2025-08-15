function sOrientation = getBatchDicomOrientation(tinfo)
%function sOrientation = getBatchDicomOrientation(tinfo)
%Determines the orientation of a DICOM image.
%  DESCRIPTION:
%  This function analyzes the `ImageOrientationPatient` field of a DICOM file 
%  to classify the scan orientation as:
%  - Axial
%  - Coronal
%  - Sagittal
%  - Unknown (if orientation cannot be determined)
%
%  PARAMETERS:
%  - `tinfo` (struct): A structure containing DICOM metadata obtained from 
%    `dicominfo()`. The function specifically requires the `ImageOrientationPatient` 
%    field to determine orientation.
%
%  FUNCTIONALITY:
%  - Extracts the `ImageOrientationPatient` vector (6 elements).
%  - Computes the normal vector of the image plane using the cross product 
%    of the row and column direction vectors.
%  - Identifies the dominant axis of the normal vector:
%      - X-axis → Sagittal
%      - Y-axis → Coronal
%      - Z-axis → Axial
%  - Returns 'Unknown' if the required metadata is missing or invalid.
%
%  RETURN VALUE:
%  - `sOrientation` (string): The determined orientation of the DICOM image, 
%    which can be one of:
%      - 'Axial'
%      - 'Coronal'
%      - 'Sagittal'
%      - 'Unknown'
%
%  USAGE EXAMPLE:
%     tinfo = dicominfo('example.dcm');
%     sOrientation = getDicomOrientation(tinfo);
%     fprintf('DICOM Orientation: %s\n', sOrientation);
%
%  ERROR HANDLING:
%  - If `ImageOrientationPatient` is missing or incorrectly formatted, the 
%    function defaults to returning 'Unknown'.
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

    % Default to unknown orientation
    sOrientation = 'Unknown';

    % Check if the DICOM contains ImageOrientationPatient data
    if isfield(tinfo, 'ImageOrientationPatient')
        % Extract the ImageOrientationPatient values (6-element vector)
        iop = tinfo.ImageOrientationPatient;
        
        % Ensure it's a valid 6-element vector
        if numel(iop) == 6
            % Extract the row and column direction vectors
            rowVec = iop(1:3);
            colVec = iop(4:6);
            
            % Compute the normal vector using the cross-product
            normalVec = cross(rowVec, colVec);
            
            % Normalize the normal vector
            normalVec = normalVec / norm(normalVec);
            
            % Determine the orientation based on the dominant axis
            [~, maxIdx] = max(abs(normalVec));  % Find the dominant axis
            
            if maxIdx == 1  % X-axis dominant
                sOrientation = 'Sagittal';
            elseif maxIdx == 2  % Y-axis dominant
                sOrientation = 'Coronal';
            elseif maxIdx == 3  % Z-axis dominant
                sOrientation = 'Axial';
            end
        end
    end
end