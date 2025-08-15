function sRootPath = getBatchRootPath()
%function sRootPath = getBatchRootPath()
% Determines the root path of the BatchTriDFusion application.
%  DESCRIPTION:
%  This function retrieves the root directory where the BatchTriDFusion 
%  application is running. It considers different environments, including:
%  - Standalone deployed applications (MATLAB compiled mode).
%  - Windows, Mac, and Linux platforms.
%  - Standard MATLAB execution mode (non-compiled).
%
%  PARAMETERS:
%  - None (This function does not require any input parameters).
%
%  RETURN VALUE:
%  - `sRootPath` (string): The absolute path to the BatchTriDFusion root directory.
%    - If the application is deployed, it attempts to extract the execution 
%      directory from system-specific methods.
%    - If running inside MATLAB, it defaults to the current working directory.
%
%  FUNCTIONALITY:
%  - Detects if the function is running as a deployed (compiled) application.
%  - Uses system commands to determine the correct path based on the OS:
%      - MacOS: Extracts path using `ps` and `awk` commands.
%      - Windows: Extracts path using `set PATH`.
%      - Linux: Defaults to the current directory.
%  - Ensures the returned path ends with a directory separator (`/` or `\`).
%  - Checks if the `logo.png` file exists in the identified root path to verify correctness.
%  - Updates the `viewerRootPath` if necessary.
%
%  USAGE EXAMPLE:
%     rootDir = getBatchRootPath();
%     fprintf('Application Root Path: %s\n', rootDir);
%
%  ERROR HANDLING:
%  - If the root path cannot be determined, it defaults to the current directory.
%  - If running in a compiled mode and unable to extract the path, a warning is 
%    displayed.
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

    sRootPath = [];

    if isdeployed % User is running an executable in standalone mode. 
        
        if ismac % Mac
            
            sNameOfDeployedApp = 'BatchTriDFusion'; % do not include the '.app' extension
            [~, result] = system(['top -n100 -l1 | grep ' sNameOfDeployedApp ' | awk ''{print $1}''']);
            result=strtrim(result);
            [status, result] = system(['ps xuwww -p ' result ' | tail -n1 | awk ''{print $NF}''']);
            if status==0
                diridx=strfind(result,[sNameOfDeployedApp '.app']);
                sRootPath=result(1:diridx-2);
            else
                msgbox({'realpwd not set:',result})
            end     
            
        elseif ispc % Windows       
            
            [~, result] = system('set PATH'); % Windows
            sRootPath = char(regexpi(result, 'Path=(.*?);', 'tokens', 'once'));
            
        else % Linux
            
            sRootPath = pwd;           
        end        
        
        if sRootPath(end) ~= '\' || ...
           sRootPath(end) ~= '/'     
            sRootPath = [sRootPath '/'];
        end

        if isfile(sprintf('%slogo.png', sRootPath))
            viewerRootPath('set', sRootPath);
        else
            if integrateToBrowser('get') == true
                if isfile(sprintf('%sBatchTriDFusion/logo.png', sRootPath))
                    viewerRootPath('set', sprintf('%sBatchTriDFusion/', sRootPath) );
                end
            else    
                sRootPath = fileparts(mfilename('fullpath'));
                sRootPath = erase(sRootPath, 'BatchTriDFusion_core');        

                if isfile(sprintf('%slogo.png', sRootPath))
                    viewerRootPath('set', sRootPath);
                end

                if isfile(sprintf('%sBatchTriDFusion/logo.png', sRootPath))
                    viewerRootPath('set', sprintf('%sBatchTriDFusion/', sRootPath) );
                end
            end
        end

    else               
        sRootPath = pwd;
        if sRootPath(end) ~= '\' || ...
           sRootPath(end) ~= '/'     
            sRootPath = [sRootPath '/'];
        end   

        if isfile(sprintf('%slogo.png', sRootPath))
            viewerRootPath('set', sRootPath);
        else
            if integrateToBrowser('get') == true
                if isfile(sprintf('%sBatchTriDFusion/logo.png', sRootPath))
                    viewerRootPath('set', sprintf('%sBatchTriDFusion/', sRootPath) );
                end
            else    
                sRootPath = fileparts(mfilename('fullpath'));
                sRootPath = erase(sRootPath, 'BatchTriDFusion_core');        

                if isfile(sprintf('%slogo.png', sRootPath))
                    viewerRootPath('set', sRootPath);
                end
            end
        end    
    end
end