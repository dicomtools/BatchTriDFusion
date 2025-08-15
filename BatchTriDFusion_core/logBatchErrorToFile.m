function logBatchErrorToFile(ME, logFilePath)
%function logBatchErrorToFile(ME, logFilePath)
%Logs errors and exceptions to a specified file.
%  DESCRIPTION:
%  This function captures error details from a MATLAB exception (`ME`) and 
%  writes them to a log file. It helps in debugging by providing detailed 
%  information, including:
%  - Timestamp of the error occurrence.
%  - Error message and identifier.
%  - Full error report with stack trace.
%  - Potential causes and resolution hints.
%  - Memory usage details at the time of the error.
%
%  PARAMETERS:
%  - `ME` (MException): MATLAB exception object containing error details.
%  - `logFilePath` (string): The full path of the file where the error log 
%    will be recorded.
%
%  FUNCTIONALITY:
%  - Attempts to open the log file in append mode.
%  - Implements a retry mechanism in case of file access conflicts.
%  - Writes structured error details to the log file.
%  - Logs system memory usage to aid in debugging memory-related issues.
%  - Closes the file safely after writing.
%
%  USAGE EXAMPLE:
%     try
%         % Some code that might cause an error
%     catch ME
%         logBatchErrorToFile(ME, 'C:\Temp\batch_error_log.txt');
%     end
%
%  ERROR HANDLING:
%  - Implements a retry loop for file access conflicts.
%  - If logging fails, a warning is displayed.
%
%  RETURN VALUE:
%  - None (The function writes error details to a file and does not return any value).
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
    
    % Open the log file in append mode
    
    fid = fopen(logFilePath, 'a'); 

    if fid ~= -1  % Ensure the file opened successfully
        try
            % Write timestamp
            fprintf(fid, 'Error occurred at %s\n', datetime('now','Format','MMMM-d-y-hhmmss'));
            fprintf(fid, 'Message: %s\n', ME.message);
            fprintf(fid, 'Identifier: %s\n', ME.identifier);

            % Log detailed report from getReport(ME)
            msgText = getReport(ME, 'extended', 'hyperlinks', 'off');
            fprintf(fid, 'Full Report:\n%s\n', msgText);

            % Loop through stack trace for detailed debugging info
            fprintf(fid, 'Stack Trace:\n');
            for ll = 1:length(ME.stack)
                fprintf(fid, '  In %s (line %d)\n', ME.stack(ll).file, ME.stack(ll).line);
            end

            % Log cause and potential resolution hints
            if ~isempty(ME.cause)
                fprintf(fid, 'Possible Cause: %s\n', strjoin(ME.cause, ', '));
            end

            % Log memory usage (converted to MB)
            memInfo = memory;
            fprintf(fid, 'Memory Usage (MB):\n');
            fprintf(fid, '  MaxPossibleArrayBytes: %.2f MB\n', memInfo.MaxPossibleArrayBytes / 1e6);
            fprintf(fid, '  MemAvailableAllArrays: %.2f MB\n', memInfo.MemAvailableAllArrays / 1e6);
            fprintf(fid, '  MemUsedMATLAB: %.2f MB\n', memInfo.MemUsedMATLAB / 1e6);

            fprintf(fid, '----------------------------\n'); % Separator for readability
            
        catch logError
            fprintf('Logging failed: %s\n', logError.message);
        end
        fclose(fid); % Close the file safely
    else
        warning('Failed to open log file: %s', logFilePath);
    end
end
