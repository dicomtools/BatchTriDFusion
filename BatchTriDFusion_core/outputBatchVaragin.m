function outputBatchVaragin(inputedVarargin, outputFile)
%function outputBatchVaragin(inputedVarargin, outputFile)
%Writes input arguments to a file for debugging/tracking.
%  DESCRIPTION:
%  This function captures and logs the input arguments provided to a script 
%  or function, writing them to a specified output file. It is useful for 
%  debugging, tracking, or documenting the parameters used during execution.
%
%  PARAMETERS:
%  - 'inputedVarargin' (cell array): A variable-length input argument list 
%    (varargin), containing the parameters to be logged.
%  - 'outputFile' (string): The full path of the file where the arguments 
%    will be recorded.
%
%  FUNCTIONALITY:
%  - Attempts to open the specified output file for writing.
%  - Implements a retry mechanism in case the file is temporarily unavailable.
%  - Writes each argument to the file, including its index and value.
%  - If an argument is numeric, it is converted to a string before logging.
%  - Closes the file safely after writing.
%
%  USAGE EXAMPLE:
%     outputVaragin(varargin, 'C:\Temp\BatchTriDFusion_arguments.txt');
%
%  ERROR HANDLING:
%  - Implements a retry loop to avoid write conflicts.
%  - If the file cannot be opened within the retry limit, logging is skipped.
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

    % Retry parameters
    maxRetryTime = 5;    % Maximum total retry time in seconds
    retryDelay   = 0.1;  % Delay between retries in seconds
    startTime    = tic;
    fid          = -1;
    
    % Attempt to open the file until successful or until the timeout is reached
    while fid == -1 && toc(startTime) < maxRetryTime
       
        fid = fopen(outputFile, 'w');

        if fid == -1
            pause(retryDelay);
        end
    end
    
    if fid ~= -1

        % Loop through each input argument and write it to the file
        for ee = 1:length(inputedVarargin)
            % Convert the argument to a string representation.
            if ischar(inputedVarargin{ee})
                argStr = inputedVarargin{ee};
            else
                argStr = mat2str(inputedVarargin{ee});
            end
            
            % Write the argument number and value to the file
            fprintf(fid, 'Argument %d: %s\n', ee, argStr);
        end
    
        % Close the file
        fclose(fid);
        
        % Optionally, display the file contents in the command window
        type(outputFile);
    end

end