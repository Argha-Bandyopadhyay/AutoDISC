function goToROI(roiIdx)
% Navigate to new ROI
%
% Author: Owen Rafferty
% Contact: dwhite7@wisc.edu
%
% Updates: 
% --------
% 2018-07-11    OR      Wrote the code.     
% 2019-02-21    DSW     Addded comments. Updated plotting with new function
%                       names 

% input variables 
global p data

% if there is no input variable, open dialog
if ~exist('roiIdx', 'var')
    answer = inputdlg('Go to ROI:','Custom ROI', 1, {num2str(p.roiIdx)});
    roiIdx = str2double(answer{1});
end
% do nothing if input variable exceeds bounds
if roiIdx < 1 || roiIdx > size(data.rois, 1)
    return;
end
p.roiIdx = roiIdx;

% Update all 3 plots in GUI

% 1. time series data (and fit)
plotTrajectory();

% 2. time series histogram (and fit)
plotHistogram()

% 3. information criterion values of the fit
plotMetric();