function [data, disc_input] = analyzeFromGUI(data, disc_input, indices, analyze_all)
% Operate the Analyze & Analyze All Buttons & runDISC with provided input
%
% Authors: Owen Rafferty & David S. White
% Contact: dwhite7@wisc.edu

% Updates: 
% --------
% 2018-12-02    OMR     Wrote the code 
% 2019-02-21    DSW     Comments added.  
% 2019-20-20    DSW     Added in AIC_GMM and HQC_GMM as clustering options
% 2019-04-10    DSW     updated to new disc_fit structure
% 2021-01-26    AKB     Updated to make compatible with
%                       runAutoOCDISC.m

% input variables
% analyze_all = 0 -> this trace only
%             = 1 -> all traces in channel
roi_idx = indices(1);
ch_idx = indices(2);

% init dialog window
d = dialog('Position',[620 400 400 260],'Name','DISC Parameters');

% create aesthetic panels
rpanel = uipanel(d,'Position',[0.37 0.24 0.61 0.71]);
llowerpanel = uipanel(d,'Position',[0.02 0.24 0.35 0.35]);

% create button group/panel for threshold type selection
bg_threshold = uibuttongroup(d,'Position',[0.02 0.6 0.35 0.38],'Title','Threshold Value',...
    'Visible','off','SelectionChangedFcn',@thresholdSelection);

% create threshold edit box and radio from selection of threshold type                         
uicontrol(bg_threshold,'Style','edit','Position',[6 53 60 20],...
    'String',disc_input.input_value,...
    'Horizontalalignment','left','Callback',@edit_threshold_callback);
radio_alpha_threshold = uicontrol(bg_threshold,'Style','radiobutton','Position',[6 26 120 20],...
    'String','Alpha Value','HandleVisibility','off');
radio_critical_threshold = uicontrol(bg_threshold,'Style','radiobutton','Position',[6 6 120 20],...
    'String','Critical Value','HandleVisibility','off');

% check if last run altered default threshold type, and use altered value if so
switch disc_input.input_type
    case 'alpha_value'
        set(bg_threshold,'SelectedObject',radio_alpha_threshold);
    case 'critical_value'
        set(bg_threshold,'SelectedObject',radio_critical_threshold);
end
% and make the group visible
bg_threshold.Visible = 'on';                   

% create viterbi iterations label and input
uicontrol(llowerpanel,'Style','text','Position',[6 65 110 20],...
    'String','Viterbi Iterations','HorizontalAlignment','left');
uicontrol(llowerpanel,'Style','edit','Position',[6 50 60 20],...
    'String',disc_input.viterbi,'HorizontalAlignment','left',...
    'Callback',@edit_iterations_callback);

% create k states check and edit. check is selected if previous runs had
% any nonzero values in edit
uicontrol(llowerpanel,'style','checkbox','string','Return k States','Position',[6 30 150 20],...
   'Value',logical(disc_input.return_k),'callback',@check_return_k_callback);
edit_return_k = uicontrol(llowerpanel,'style','edit','string',disc_input.return_k,'Position',[6 10 60 20],...
    'Visible','off','HorizontalAlignment','left','callback',@edit_return_k_callback);
% make edit visible if previous run had check selected
if disc_input.return_k
    edit_return_k.Visible = 'on';
end

% create BIC_GMM vs. BIC_RSS Decision Boundary label and
% checkbox
choicestr = sprintf("Automate Optimal Choice of\nBIC-RSS vs. AIC-GMM?");
txt_decisionboundary = uicontrol(rpanel, 'Style','text', 'Position', [10 155 200 25],...
                                'String', choicestr,'HorizontalAlignment', 'left');
checkbox_decisionboundary = uicontrol(rpanel, 'Style', 'checkbox', 'Position', [10 135 80 20],...
                                     'String', 'AutoDISC', 'HorizontalAlignment', 'left',...
                                     'Callback', @checkbox_decisionboundary_callback);
checkbox_decisionboundary.Value = 1;

% line makes this panel easier to look at it
txt_line = uicontrol(rpanel, 'Style', 'text', 'Position', [10 115 200 20],...
                    'String', '--------------------------------------------------');

% create slope and intercept labels and text inputs
dbstr = sprintf("Decision Boundary Equation:\nlog10(numsamples) = slope*SNR + intercept");
txt_db = uicontrol(rpanel, 'Style', 'text', 'Position', [10 90 245 30],...
                  'String', dbstr, 'HorizontalAlignment', 'left');
txt_dbslope = uicontrol(rpanel, 'Style', 'text', 'Position', [10 65 100 20],...
                       'String', 'Slope', 'HorizontalAlignment', 'left');
edit_dbslope = uicontrol(rpanel, 'Style', 'edit', 'Position', [10 50 75 20],...
                        'String', disc_input.dbslope, 'HorizontalAlignment', 'left',...
                        'Callback', @edit_dbslope_callback);
txt_dbintercept = uicontrol(rpanel, 'Style', 'text', 'Position', [10 25 100 20],...
                       'String', 'Intercept', 'HorizontalAlignment', 'left');
edit_dbintercept = uicontrol(rpanel, 'Style', 'edit', 'Position', [10 10 75 20],...
                        'String', disc_input.dbintercept, 'HorizontalAlignment', 'left',...
                        'Callback', @edit_dbintercept_callback);
push_dbdefaults = uicontrol(rpanel, 'Style', 'pushbutton', 'Position', [120 30 75 20],...
                            'String', 'Use Defaults', 'HorizontalAlignment', 'left',...
                            'Callback', @push_dbdefaults_callback);
% make group visible 
txt_db.Visible = 'on';
txt_dbslope.Visible = 'on';
edit_dbslope.Visible = 'on';
txt_dbintercept.Visible = 'on';
edit_dbintercept.Visible = 'on';
push_dbdefaults.Visible = 'on';

% create divisive IC label and popup                 
txt_divisiveIC = uicontrol(rpanel,'Style','text','Position',[10 90 100 20],...
                           'String','Divisive IC','HorizontalAlignment','left');
popup_divisiveIC = uicontrol(rpanel,'Style','popup','Position',[10 70 100 20],...
                             'String',{'AIC-GMM';'BIC-GMM';'BIC-RSS';'HQC-GMM';'MDL'},'Visible','off',...
                             'Callback',@popup_divisiveIC_callback);
                         
% check if last run altered default divIC parameters, and use altered values if so
switch disc_input.divisive
    case {'AIC-GMM' 'AIC_GMM'}
        set(popup_divisiveIC,'Value',1)
    case {'BIC-GMM' 'BIC_GMM'}
        set(popup_divisiveIC,'Value',2)
    case {'BIC-RSS' 'BIC_RSS'}
        set(popup_divisiveIC,'Value',3)
    case {'HQC-GMM' 'HQC_GMM'}
        set(popup_divisiveIC,'Value',4)
    case 'MDL'
        set(popup_divisiveIC,'Value',5)
    case 'none'
        set(popup_divisiveIC,'Value',6)
end

% and make the group invisible
txt_divisiveIC.Visible = 'off';
popup_divisiveIC.Visible = 'off';

% create agglomerative IC label and popup
txt_agglomerativeIC = uicontrol(rpanel,'Style','text','Position',[10 45 120 20],...
                                'String','Agglomerative IC','HorizontalAlignment','left');
popup_agglomerativeIC = uicontrol(rpanel,'Style','popup','Position',[10 25 100 20],...
                                  'String',{'AIC-GMM';'BIC-GMM';'BIC-RSS';'HQC-GMM';'MDL';'none'},'Visible','off',...
                                  'Callback',@popup_agglomerativeIC_callback);

% check if last run altered default aggIC parameters, and use altered values if so
switch disc_input.agglomerative
    case {'AIC-GMM' 'AIC_GMM'}
        set(popup_agglomerativeIC,'Value',1)
    case {'BIC-GMM' 'BIC_GMM'}
        set(popup_agglomerativeIC,'Value',2)
    case {'BIC-RSS' 'BIC_RSS'}
        set(popup_agglomerativeIC,'Value',3)
    case {'HQC-GMM' 'HQC_GMM'}
        set(popup_agglomerativeIC,'Value',4)
    case 'MDL'
        set(popup_agglomerativeIC,'Value',5)
    case 'none'
        set(popup_agglomerativeIC,'Value',6)
        
end
% and make the group invisible 
txt_agglomerativeIC.Visible = 'off';
popup_agglomerativeIC.Visible = 'off';

% create cancel and go buttons
uicontrol('Parent',d,'Position',[65 25 100 30],'String','Cancel',...
    'Callback','delete(gcf)');
uicontrol('Parent',d,'Position',[185 25 100 30],'String','Go',...
    'Callback',@goAnalyze);

% callback functions for dialog. these functions are unused if the default
% values are unchanged
uiwait(d);
    function edit_threshold_callback(H,~) % called by a custom threshold value
        disc_input.input_value = str2double(get(H,'string'));
    end
    function thresholdSelection(~,event) % called by a threshold type
        switch event.NewValue.String
            case 'Alpha Value'
                disc_input.input_type = 'alpha_value';
            case 'Critical Value'
                disc_input.input_type = 'critical_value';
        end
    end

    function edit_iterations_callback(H,~) % called by a custom number of iterations
        disc_input.viterbi = str2double(get(H,'string'));
    end
    function checkbox_decisionboundary_callback(checkbox, ~)
        % Only want to allow user choice of OC if they
        % choose to not automate
        switch checkbox.Value
            case 0
                txt_divisiveIC.Visible = 'on';
                popup_divisiveIC.Visible = 'on';
                txt_agglomerativeIC.Visible = 'on';
                popup_agglomerativeIC.Visible = 'on';
                txt_db.Visible = 'off';
                txt_dbslope.Visible = 'off';
                edit_dbslope.Visible = 'off';
                txt_dbintercept.Visible = 'off';
                edit_dbintercept.Visible = 'off';
                push_dbdefaults.Visible = 'off';
                disc_input.automate = 0;
            case 1 
                txt_divisiveIC.Visible = 'off';
                popup_divisiveIC.Visible = 'off';
                txt_agglomerativeIC.Visible = 'off';
                popup_agglomerativeIC.Visible = 'off';
                txt_db.Visible = 'on';
                txt_dbslope.Visible = 'on';
                edit_dbslope.Visible = 'on';
                txt_dbintercept.Visible = 'on';
                edit_dbintercept.Visible = 'on';
                push_dbdefaults.Visible = 'on';
                disc_input.automate = 1;
        end
    end

    function edit_dbslope_callback(H,~) % called by a custom decision boundary slope
        disc_input.dbslope = str2double(get(H,'string'));
    end

    function edit_dbintercept_callback(H,~) % called by a custom decision boundary intercept
        disc_input.dbintercept = str2double(get(H,'string'));
    end

    function push_dbdefaults_callback(~,~) % called by pushing default button 
        disc_input.dbslope = -0.4877;
        disc_input.dbintercept = 4.6939;
        edit_dbslope.String = num2str(disc_input.dbslope);
        edit_dbintercept.String = num2str(disc_input.dbintercept);
    end

    function popup_divisiveIC_callback(popup,~) % called by a change in divIC type
        idx = popup.Value;
        popup_items = popup.String;
        disc_input.divisive = char(popup_items(idx,:));
    end

    function popup_agglomerativeIC_callback(popup,~) % called by a change in aggIC type
        idx = popup.Value;
        popup_items = popup.String;
        disc_input.agglomerative = char(popup_items(idx,:));
    end
    
    function check_return_k_callback(H,~) % called by change in k_states check
        if H.Value
            edit_return_k.Visible = 'on';
        else
            edit_return_k.Visible = 'off';
            disc_input.return_k = 0;
        end
    end
    function edit_return_k_callback(H,~) % called by change in # of states to force
        disc_input.return_k = str2double(get(H, 'String'));
    end

    % called by "Go" button to gather parameters to send to runDISC and check for their validity.
    function goAnalyze(~,~)
        
        % round non-integers and/or set negative values to 0.
        disc_input.viterbi = uint8(disc_input.viterbi);
        disc_input.return_k = uint8(disc_input.return_k);
        
        switch disc_input.input_type
            case 'alpha_value'
                % Error check for alpha values not between 0 and 1
                if disc_input.input_value > 1 || disc_input.input_value < 0
                    msgbox('Alpha Value must be between 0 and 1', 'Error','error');
                    return
                end
            case 'critical_value'
                % Error check for negative critical values 
                if disc_input.input_value < 0
                    msgbox('Critical Value must be between greater than 0', 'Error','error');
                    return
                end
        end
        delete(gcf)
        
        % run DISC at current ROI and channel
        if ~analyze_all
            if disc_input.automate
                % runAutoOCDISC
                data.rois(roi_idx, ch_idx).disc_fit =  ...
                    runAutoDISC(data.rois(roi_idx, ch_idx).time_series, disc_input);
            else
                % runDISC
                data.rois(roi_idx, ch_idx).disc_fit =  ...
                    runDISC(data.rois(roi_idx, ch_idx).time_series, disc_input);
            end

      
        % run DISC on all ROIs at current channel
        elseif analyze_all
            n_rois = size(data.rois,1);
            % init waitbar and its window name
            wait_name = sprintf('Running DISC on ''%s'' ...', data.names{ch_idx});
            f = waitbar(0,'1','Name',wait_name,...
                'CreateCancelBtn','setappdata(gcbf,''canceling'',1)');
            setappdata(f,'canceling',0);
            for ii = 1:n_rois
                % if the FOR loop cannot finish for whatever reason, the 
                % waitbar will remain open without any way of closing it 
                % besides force killing all MATLAB processes, so we need 
                % error handling
                try
                    % stop analysis if cancel is clicked
                    if getappdata(f,'canceling')
                        break
                    end
                    % recall waitbar and display progress
                    waitbar(ii/n_rois, f, sprintf("ROI %u of %u", ii, n_rois))
                    if disc_input.automate
                        % runAutoOCDISC
                        data.rois(ii, ch_idx).disc_fit = ...
                            runAutoDISC(data.rois(ii, ch_idx).time_series, disc_input);    
                    else
                        % runDISC
                        data.rois(ii, ch_idx).disc_fit = ...
                            runDISC(data.rois(ii, ch_idx).time_series, disc_input);                        
                    end

                catch ME
                    delete(f); % close waitbar if error occurs
                    rethrow(ME);
                end
            end
            delete(f); % close waitbar
        end       
    end
end