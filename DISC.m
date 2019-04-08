function DISC()
% DISC GUI
% Authors: David S. White  & Owen Rafferty
% contact: dwhite7@wisc.edu

% Updates:
% ---------
% 2019-04-07    DSW    Version 1.0
%
%--------------------------------------------------------------------------
% Overview:
% ---------
% This program is a graphical front end for the time series idealization 
% algorithm 'DISC' by David S. White.
% Requires MATLAB Statistics and Machine Learning Toolbox
% see src/DISC/runDISC.m for more details. 
%
% Input Variables:
% ----------------
% data = structure to be analyzed. Requires: 
%   data.zproj = observed emission sequence. 
%
% References:
% -----------
% White et al., 2019, (in preparation)

global data p

% Init data and some fields
p.fp = ''; p.guiHandle = ''; p.channelPopupObject = '';
if isempty(data)
    loadData()
end
% check if previous operation cancelled to avoid error msg
if isempty(data)
    disp('Action Aborted.')
    return;
end

% init GUI
p.guiHandle = roiViewerGUI();

% define default analysis parame�ters to be called later in dialog
p.inputParameters.thresholdValue = 0.05;
p.inputParameters.thresholdType = 'alpha_value';
p.inputParameters.divisiveIC = 'BIC-GMM';
p.inputParameters.agglomerativeIC = 'BIC-GMM';
p.inputParameters.hmmIterations = 1;

end