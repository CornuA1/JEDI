function JEDI_linescan()
% load datafile and extract data
    try
        [fName, fPath] = uigetfile('.xml', 'Please LineScan file');
    catch
        waitfor(msgbox('Error: Please select valid .sbx file.'));
        error('Please select valid .sbx file.');
    end
    
    % load info about LineScan
    GUIHandles.s = xml2struct(strcat(fPath,fName));
    
    % grab number of cycles
    GUIHandles.num_cycles = length(GUIHandles.s.PVScan.Sequence);
    
    % pseudo constants for respective channels
    GUIHandles.GREEN_CHAN = 1; 
    GUIHandles.RED_CHAN = 2;
    
    % crop suffix since we don't want it anymore
    GUIHandles.fName = strtok(fName, '.');
    GUIHandles.fPath = fPath;
    
    % current linescan cycle
    GUIHandles.curCycle = 1;
    
    % Reference paths
    GUIHandles.ref_path = strcat(fPath,'References',filesep);
    
    % loop through every cycle, display reference image and linescan data.
    GUI = figure('Units', 'Nor malized', 'Position', [0.1,0.4,0.8,0.5]);
    
    GUIHandles.prevButton = uicontrol('Style', 'pushbutton', 'String', '<<', 'Units', 'normalized', 'Position', [0.0245, 0.95, 0.04, 0.05], 'Callback', @prevCycle);
    GUIHandles.nextButton = uicontrol('Style', 'pushbutton', 'String', '>>', 'Units', 'normalized', 'Position', [0.065, 0.95, 0.04, 0.05], 'Callback', @nextCycle);
    GUIHandles.calcMeanButton = uicontrol('Style', 'pushbutton', 'String', 'Calculate Mean', 'Units', 'normalized', 'Position', [0.1955, 0.95, 0.08, 0.05], 'Callback', @calculateMean);
    GUIHandles.excludeCycle = uicontrol('Style', 'checkbox', 'String', 'Exclude', 'Units', 'normalized', 'Position', [0.15, 0.95, 0.04, 0.05], 'Callback', @excludeCallback);
     
    GUIHandles.refAxes = axes('Units', 'Normalized', 'Position', [0.025, 0.05, 0.25, 0.9]);
    set(GUIHandles.refAxes,'YTickLabel',[]);
    
    GUIHandles.lsAxes_green = axes('Units', 'Normalized', 'Position', [0.3, 0.05, 0.1, 0.9]);
    GUIHandles.lsAxes_red = axes('Units', 'Normalized', 'Position', [0.415, 0.05, 0.1, 0.9]);
    set(GUIHandles.lsAxes_red,'YTickLabel',[]);
    
    GUIHandles.VOutput = axes('Units', 'Normalized', 'Position', [0.55, 0.7, 0.44, 0.25]);
    GUIHandles.VRecording = axes('Units', 'Normalized', 'Position', [0.55, 0.4, 0.44, 0.25]);
    GUIHandles.LScanJEDI = axes('Units', 'Normalized', 'Position', [0.55, 0.07, 0.44, 0.25]);
    
    linkaxes([GUIHandles.VOutput,GUIHandles.VRecording,GUIHandles.LScanJEDI],'x');
    
    GUIHandles = displayCycle(GUIHandles);
   

    % set lines demarcating start and end of the linescan used to extract
    % brightness signal
%     GUIHandles.linePixels = 
    GUIHandles.startLine = 0;
%     GUIHandles.endLine = 
  

    guidata(GUI, GUIHandles);
end

function GUIHandles = displayCycle(GUIHandles)
    colormap(parula)
    % load and display reference image
    num_chans = length(GUIHandles.s.PVScan.Sequence{GUIHandles.curCycle}.Frame.File);
    if num_chans > 1
        ref_fstring = sprintf('%sReferences\\%s-Cycle%05u-Window1-Ch1-Ch2-8bit-Reference.tif',GUIHandles.fPath,GUIHandles.fName,GUIHandles.curCycle+1);
        ls_image_green = strcat(GUIHandles.fPath, GUIHandles.s.PVScan.Sequence{GUIHandles.curCycle}.Frame.File{1}.Attributes.filename);
        ls_image_red = strcat(GUIHandles.fPath, GUIHandles.s.PVScan.Sequence{GUIHandles.curCycle}.Frame.File{2}.Attributes.filename);
    else
        ref_fstring = sprintf('%sReferences\\%s-Cycle%05u-Window1-Ch1-8bit-Reference.tif',GUIHandles.fPath,GUIHandles.fName,GUIHandles.curCycle+1);
        ls_image_green = strcat(GUIHandles.fPath, GUIHandles.s.PVScan.Sequence{GUIHandles.curCycle}.Frame.File.Attributes.filename);
        ls_image_red = false;
    end
    ref_image = im2double(imread(ref_fstring));
    ref_image = ref_image(:,:,1:3); % the last layer doesn't contain any information
    imagesc(ref_image, 'Parent', GUIHandles.refAxes);

    % display JEDI
    GUIHandles.ls_image_green = im2double(imread(ls_image_green));
    imagesc(GUIHandles.ls_image_green, 'Parent', GUIHandles.lsAxes_green);
    title('JEDI', 'Parent', GUIHandles.lsAxes_green);

    % display STRUCTURAL
    if ls_image_red
        GUIHandles.ls_image_red = im2double(imread(ls_image_red));
        imagesc(GUIHandles.ls_image_red, 'Parent', GUIHandles.lsAxes_red);
        title('STRUCTURAL', 'Parent', GUIHandles.lsAxes_red);
        set(GUIHandles.lsAxes_red,'YTickLabel',[]);
    end
    
    % load voltage recording trace
    if isfield(GUIHandles.s.PVScan.Sequence{GUIHandles.curCycle},'VoltageRecording')
        vRecording_trace_file = strcat(GUIHandles.fPath, GUIHandles.s.PVScan.Sequence{GUIHandles.curCycle}.VoltageRecording.Attributes.dataFile);
        GUIHandles.vRec_trace = readtable(vRecording_trace_file,'Delimiter',',');
        plot(GUIHandles.vRec_trace.Time_ms_,GUIHandles.vRec_trace.Input1*10000,'Parent',GUIHandles.VOutput);
        plot(GUIHandles.vRec_trace.Time_ms_,GUIHandles.vRec_trace.Input0*100,'Parent',GUIHandles.VRecording);
    end
    
    % plot JEDI linescan trace
    ls_profile_file = strcat(GUIHandles.fPath, GUIHandles.s.PVScan.Sequence{GUIHandles.curCycle}.PVLinescanDefinition.LineScanProfiles.Attributes.DataFile);
    GUIHandles.ls_profile_trace = readtable(ls_profile_file,'Delimiter',',');
%     plot(mean(ls_image_green,2));
    if length(GUIHandles.ls_profile_trace.Prof1Time_ms_) == length(mean(GUIHandles.ls_image_green,2))
        plot(GUIHandles.ls_profile_trace.Prof1Time_ms_,mean(GUIHandles.ls_image_green,2),'Parent',GUIHandles.LScanJEDI);
    else
        plot(mean(GUIHandles.ls_image_green,2),'Parent',GUIHandles.LScanJEDI);
    end
    
    ylabel('pA', 'Parent',GUIHandles.VOutput);
    ylabel('mV', 'Parent',GUIHandles.VRecording);
    ylabel('brightness', 'Parent',GUIHandles.LScanJEDI);
    xlabel('ms', 'Parent',GUIHandles.LScanJEDI);
   
end

function calculateMean(GUI, ~)
    GUIHandles = guidata(GUI);
    
    figure();
   
    traces_VRecording = subplot(2,1,1);
    mean_LScanJEDI = subplot(2,1,2);
    
    v_traces = false;
    mean_trace = false;  
    
    for i=1:GUIHandles.num_cycles
        
        vRecording_trace_file = strcat(GUIHandles.fPath, GUIHandles.s.PVScan.Sequence{i}.VoltageRecording.Attributes.dataFile);
        vRec_data = readtable(vRecording_trace_file,'Delimiter',',');
        if ~v_traces
            v_traces = vRec_data.Input0*100;
            v_times = vRec_data.Time_ms_;
        else
            v_traces = horzcat(v_traces, vRec_data.Input0*100); %#ok<AGROW>
            v_times = horzcat(v_times, vRec_data.Time_ms_); %#ok<AGROW>
        end
   
        num_chans = length(GUIHandles.s.PVScan.Sequence{i}.Frame.File);
        if num_chans > 1
            ls_image_green_fname = strcat(GUIHandles.fPath, GUIHandles.s.PVScan.Sequence{i}.Frame.File{1}.Attributes.filename);
        else
            ls_image_green_fname = strcat(GUIHandles.fPath, GUIHandles.s.PVScan.Sequence{i}.Frame.File.Attributes.filename);
        end
        ls_image_green = im2double(imread(ls_image_green_fname));
        if ~mean_trace
            mean_trace = mean(ls_image_green,2);
        else
            mean_trace = horzcat(mean_trace, mean(ls_image_green,2)); %#ok<AGROW>
        end
    end
    
    plot(v_times(:,1),v_traces, 'Parent', traces_VRecording);    
    xlim(traces_VRecording, [0,max(v_times(:,1))]);
    plot(mean(mean_trace,2), 'Parent', mean_LScanJEDI);
    xlim(mean_LScanJEDI, [0, length(mean(mean_trace,2))]);
    guidata(GUI, GUIHandles);
end
    
function prevCycle(GUI, ~)
    GUIHandles = guidata(GUI);
    
    if GUIHandles.curCycle > 1
        GUIHandles.curCycle = GUIHandles.curCycle - 1;
        GUIHandles = displayCycle(GUIHandles);
    end
    
    guidata(GUI, GUIHandles);
end

function nextCycle(GUI, ~)
    GUIHandles = guidata(GUI);
    
    if GUIHandles.curCycle < GUIHandles.num_cycles
        GUIHandles.curCycle = GUIHandles.curCycle + 1;
        GUIHandles = displayCycle(GUIHandles);
    end
    
    guidata(GUI, GUIHandles);
end



