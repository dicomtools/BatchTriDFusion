function scanType = classifyBatchDicomScan(tinfo)
%function scanType = classifyBatchDicomScan(tinfo)
%Classifies a DICOM scan based on modality and attributes.
%  DESCRIPTION:
%  This function determines the scan type of a given DICOM file by analyzing 
%  its metadata. It classifies scans into different categories such as:
%  - PET AC (Attenuation Corrected)
%  - PET Non-AC (Non-Attenuation Corrected)
%  - CT AC (Attenuation Corrected)
%  - CT Non-AC (Non-Attenuation Corrected)
%  - Unknown (if classification criteria are not met)
%
%  PARAMETERS:
%  - `tinfo` (struct): A structure containing DICOM metadata obtained from 
%    `dicominfo()`. This structure should include fields like `Modality` 
%    and `SeriesDescription` for accurate classification.
%
%  FUNCTIONALITY:
%  - Identifies whether the scan is PET (`Modality = 'PT'`) or CT (`Modality = 'CT'`).
%  - Analyzes the `SeriesDescription` field to check for keywords indicating 
%    attenuation correction (e.g., `NAC`, `Uncorrected`, `Fused`, `DX`, `Scout`).
%  - Assigns the appropriate scan classification based on modality and correction type.
%
%  RETURN VALUE:
%  - `scanType` (string): The classification of the scan, which can be one of:
%      - 'PET AC'
%      - 'PET Non-AC'
%      - 'CT AC'
%      - 'CT Non-AC'
%      - 'Unknown' (if classification criteria are not met)
%
%  USAGE EXAMPLE:
%     tinfo = dicominfo('example.dcm');
%     scanType = classifyDicomScan(tinfo);
%     fprintf('DICOM Scan Type: %s\n', scanType);
%
%  ERROR HANDLING:
%  - If `tinfo` does not contain the necessary fields, the function defaults 
%    to returning 'Unknown'.
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

    % Default classification
    scanType = 'Unknown';

    % Check if 'Modality' exists in tinfo
    if isfield(tinfo, 'Modality')
        modality = tinfo.Modality;
        
        if strcmp(modality, 'PT')  % PET Scan
            % If SeriesDescription exists and contains either 'NAC' or 'Uncorrected'
            if isfield(tinfo, 'SeriesDescription') && ...
               (contains(tinfo.SeriesDescription, 'NAC', 'IgnoreCase', true) || ...
                contains(tinfo.SeriesDescription, 'Uncorrected', 'IgnoreCase', true) || ...
                contains(tinfo.SeriesDescription, 'Fused', 'IgnoreCase', true))

                scanType = 'PET Non-AC';
            else
                % Default to PET AC if above condition is not met
                scanType = 'PET AC';
            end

        elseif strcmp(modality, 'CT')  % CT Scan
            if isfield(tinfo, 'SeriesDescription') && ...
               (contains(tinfo.SeriesDescription, 'DX', 'IgnoreCase', true) || ...
                contains(tinfo.SeriesDescription, 'Scout', 'IgnoreCase', true) || ...
                contains(tinfo.SeriesDescription, 'NAC', 'IgnoreCase', true) || ...
                contains(tinfo.SeriesDescription, 'Uncorrected', 'IgnoreCase', true))

                scanType = 'CT Non-AC';
            else
                % Default to CT AC if none of the conditions match
                scanType = 'CT AC';
            end
        end        
    end
end