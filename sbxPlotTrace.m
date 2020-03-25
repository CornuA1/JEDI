function sbxPlotTrace()

    % load datafile and extract data
    try
        [sbxName, sbxPath] = uigetfile('.sbx', 'Please select file containing imaging data.');
    catch
        waitfor(msgbox('Error: Please select valid .sbx file.'));
        error('Please select valid .sbx file.');
    end
    sbxName = strtok(sbxName, '.');
    Info = sbxInfo([sbxPath, sbxName]);
    
    % load frames
    frames = sbxgrabframe(sbxName,15,-1);
    frames = squeeze(frames);
    frames = cast(frames, 'uint16');

    motion_correct = true;
    Parameters.frameCrop = [0,0,0,0];
    if motion_correct == true
        Parameters.frameCrop = [91,0,0,0];
        Parameters.subpixelFactor = 1;
        Parameters.passes = 3;
        Parameters.gaussianFilter = 2;
        Parameters.threshold = 1500;
        Parameters.GUI = false;
        Parameters.sampleSize = 1000;
        [phaseDifferences, rowShifts, columnShifts, result] = sbxRigid(Info, Parameters);
        
    else
        Parameters.frameCrop = [91,0,0,0];
        Parameters.subpixelFactor = 1;
        Parameters.passes = 3;
        Parameters.gaussianFilter = 2;
        Parameters.threshold = 1500;
        Parameters.GUI = false;
        Parameters.sampleSize = 1000;
        phaseDifferences = zeros(1,size(frames,3));
        rowShifts = zeros(1,size(frames,3));
        columnShifts = zeros(1,size(frames,3));
       
    end
    % crop left 91 pixels (bidirectional scanning artifact)

    
    GUI = figure('Units', 'Normalized', 'Position', [0.1,0.1,0.8,0.8]);
    GUIHandles = guihandles(GUI);
    
    
    GUIHandles.frames = frames;
    
    GUIHandles.disp_image = 'mean';
    GUIHandles.cur_frame = 1;
    GUIHandles.Parameters = Parameters;
    GUIHandles.phaseDifferences = phaseDifferences;
    GUIHandles.rowShifts = rowShifts;
    GUIHandles.columnShifts = columnShifts;
    GUIHandles.roiSet = false;
    
    guidata(GUI, GUIHandles);
    
    for i=1:size(frames,3)
        frames(:,:,i) = applyMotionCorrection(GUI, i, []);
    end
    
    frames = frames(:,92:end,:);
    mean_frame = cast(mean(frames,3), 'uint16');
    
    GUIHandles.frames = GUIHandles.frames(:,92:end,:);
    GUIHandles.mean_frame = mean_frame;
       
    GUIHandles.frameAxis = axes('Units', 'Normalized', 'Position', [0.05, 0.75, 0.8, 0.2]);
%     GUIHandles.movieAxis = axes('Units', 'Normalized', 'Visible', 'off', 'Position', [0.05, 0.75, 0.8, 0.2]);
    GUIHandles.traceAxes = axes('Units', 'normalized', 'Position', [0.05, 0.40, 0.8, 0.30]);
    GUIHandles.sigAxes = axes('Units', 'normalized', 'Position', [0.05, 0.05, 0.8, 0.30]);
    
    GUIHandles.imageTypeButtonGroup = uibuttongroup('Title', 'Display', 'TitlePosition', 'lefttop', 'Units', 'normalized', 'Position', [0.9, 0.85, 0.08, 0.1], 'SelectionChangedFcn', @imageTypeButtonGroupSelectionFunction);
    GUIHandles.meanButton = uicontrol('Parent', GUIHandles.imageTypeButtonGroup, 'Style', 'radiobutton', 'String', 'Mean image', 'Units', 'normalized', 'Position', [0.05, 0.5, 0.9, 0.4]);
    GUIHandles.framebyframeButton = uicontrol('Parent', GUIHandles.imageTypeButtonGroup, 'Style', 'radiobutton', 'String', 'Frame by frame', 'Units', 'normalized', 'Position', [0.05, 0.1, 0.9, 0.4]);
    GUIHandles.frameSlider = uicontrol('Parent', GUI, 'Style', 'slider', 'Visible', false, 'Min', 1, 'Max', size(frames,3), 'Value', 1, 'SliderStep', [1/(size(frames,3)), 50/(size(frames,3))], 'Units', 'normalized', 'Position', [0.05, 0.725, 0.8, 0.02], 'Callback', @frameSliderCallback);
    GUIHandles.frameDisplay = uicontrol('Parent', GUI, 'Style', 'text', 'Visible', false, 'String', 'Frame: 1', 'Units', 'normalized', 'Position', [0.88, 0.828, 0.08, 0.02]);
    
    GUIHandles.roiButton = uicontrol('Style', 'pushbutton', 'String', 'set ROI', 'Units', 'normalized', 'Position', [0.9, 0.6, 0.08, 0.2], 'Callback', @setROI);
    GUIHandles.updateTrace = uicontrol('Style', 'pushbutton', 'String', 'update Trace', 'Units', 'normalized', 'Position', [0.9, 0.4, 0.08, 0.2], 'Callback', @updateTrace);
    GUIHandles.clearROI = uicontrol('Style', 'pushbutton', 'String', 'clear ROI', 'Units', 'normalized', 'Position', [0.9, 0.2, 0.08, 0.2], 'Callback', @updateTrace);

    set(GUIHandles.frameAxis,'YTickLabel',[]);
    set(GUIHandles.frameAxis,'XTickLabel',[]);

    guidata(GUI, GUIHandles);
    updateImage(GUI)
end

function imageTypeButtonGroupSelectionFunction(GUI, eventdata)
    GUIHandles = guidata(GUI);
    switch eventdata.NewValue.String
        case 'Mean image'
            GUIHandles.disp_image = 'mean';
            GUIHandles.frameSlider.Visible = 'off';
            GUIHandles.frameDisplay.Visible = 'off';
        case 'Frame by frame'
            GUIHandles.disp_image = 'framebyframe';
            GUIHandles.frameSlider.Visible = 'on';
            GUIHandles.frameDisplay.Visible = 'on';
    end
    guidata(GUI, GUIHandles);
    updateImage(GUI)
end

function frameSliderCallback(GUI, ~)
    GUIHandles = guidata(GUI);
    GUIHandles.cur_frame = round(GUIHandles.frameSlider.Value);
    guidata(GUI, GUIHandles);
    updateImage(GUI)
end

function updateImage(GUI)
    GUIHandles = guidata(GUI);
    switch GUIHandles.disp_image
        case 'mean'
            imagesc(GUIHandles.mean_frame, 'Parent', GUIHandles.frameAxis, [0,30000]);
        case 'framebyframe'
            adjustedImage = applyMotionCorrection(GUI, GUIHandles.cur_frame, []);
            imagesc(adjustedImage, 'Parent', GUIHandles.frameAxis, [0,40000]);
            if GUIHandles.roiSet
                GUIHandles.line_handle = updateLiveLine(GUI);
            end
    end
    guidata(GUI, GUIHandles);
end

function cur_line = updateLiveLine(GUI)
    GUIHandles = guidata(GUI);
    if isfield(GUIHandles, 'line_handle')
        delete(GUIHandles.traceAxes.Children(1));
        delete(GUIHandles.sigAxes.Children(1));
    end
    
    line_x = [GUIHandles.cur_frame, GUIHandles.cur_frame];
    line_y = ylim(GUIHandles.traceAxes);
    cur_line = line(line_x, line_y, 'Color', 'r', 'Parent', GUIHandles.traceAxes);
    
    line_x_sig = [GUIHandles.cur_frame, GUIHandles.cur_frame];
    line_y_sig = ylim(GUIHandles.sigAxes);
    line(line_x_sig, line_y_sig, 'Color', 'r', 'Parent', GUIHandles.sigAxes);
    
    guidata(GUI, GUIHandles);
end

function setROI(GUI, eventdata)
    GUIHandles = guidata(GUI);
    GUIHandles.roi = drawrectangle(GUIHandles.frameAxis);
    GUIHandles.roiSet = true;
    guidata(GUI, GUIHandles);
    updateTrace(GUI, eventdata);
end

function updateTrace(GUI, ~)
    GUIHandles = guidata(GUI);
    if isfield(GUIHandles,'roi')
        roi_coords = GUIHandles.roi.Position;
        % convert image coordinate to matrix coordinates
        r2m = [ceil(roi_coords(2)), ceil(roi_coords(2)+roi_coords(4)), ceil(roi_coords(1)), ceil(roi_coords(1)) + floor(roi_coords(3))];
        GUIHandles.roiTrace = mean(mean(GUIHandles.frames(r2m(1):r2m(2),r2m(3):r2m(4),:),1),2);
        GUIHandles.roiTrace = squeeze(squeeze(GUIHandles.roiTrace));
        
        x = 1:1:length(GUIHandles.roiTrace);
        x = x';
        f = fit(x,GUIHandles.roiTrace,'exp2');
        
        axes(GUIHandles.traceAxes);
        plot(f,'r',x,GUIHandles.roiTrace,'-');
        
        axes(GUIHandles.sigAxes);
        baseline_brightness = mean(GUIHandles.roiTrace);
        adjusted_trace = (GUIHandles.roiTrace - f(x)) + baseline_brightness;
        dff = ((adjusted_trace - mean(adjusted_trace))/mean(adjusted_trace));
%         dff = bandpass(dff, [20,150], 991);
        plot(x, dff);

        guidata(GUI, GUIHandles);
    else
        disp('no ROI detected');
    end
end

function adjustedImage = applyMotionCorrection(GUI, index, excludeFrames)

    GUIHandles = guidata(GUI);

%     frame = sbxRead(GUIHandles.Info, index);
    frame = GUIHandles.frames(:,:,index);

%     if any(GUIHandles.frameCrop > 0)
%         frame = frame(GUIHandles.frameCrop(3) + 1:GUIHandles.Info.sz(1) - GUIHandles.frameCrop(4), GUIHandles.frameCrop(1) + 1:GUIHandles.Info.sz(2) - GUIHandles.frameCrop(2));
%     end
    
    phaseDifference = GUIHandles.phaseDifferences(index + 1);
    rowShift = GUIHandles.rowShifts(index + 1);
    columnShift = GUIHandles.columnShifts(index + 1);
    
    % check if frame shifts are crazy
    if excludeFrames
        large = abs(rowShift) > 20 || abs(columnShift) > 20;
        
        if index == 0
            jagged = abs(rowShift - GUIHandles.rowShifts(index + 2)) > 10 || abs(columnShift - GUIHandles.columnShifts(index + 2)) > 10;
        else
            jagged = abs(rowShift - GUIHandles.rowShifts(index)) > 10 || abs(columnShift - GUIHandles.columnShifts(index)) > 10;
        end
        
        if large || jagged
            adjustedImage = nan(size(frame));
            return
        end
    end
            
    if phaseDifference ~= 0 || rowShift ~= 0 || columnShift ~= 0
        adjustedImage = fft2(frame);

        [numberOfRows, numberOfColumns] = size(adjustedImage);
        Nr = ifftshift(-fix(numberOfRows/2):ceil(numberOfRows/2) - 1);
        Nc = ifftshift(-fix(numberOfColumns/2):ceil(numberOfColumns/2) - 1);
        [Nc, Nr] = meshgrid(Nc, Nr);

        adjustedImage = adjustedImage.*exp(2i*pi*(-rowShift*Nr/numberOfRows - columnShift*Nc/numberOfColumns));
        adjustedImage = adjustedImage*exp(1i*phaseDifference);

        adjustedImage = abs(ifft2(adjustedImage));
        
        % adjust values just in case
        originalMinimum = double(min(frame(:)));
        originalMaximum = double(max(frame(:)));
        adjustedMinimum = min(adjustedImage(:));
        adjustedMaximum = max(adjustedImage(:));
        
        adjustedImage = uint16((adjustedImage - adjustedMinimum)/(adjustedMaximum - adjustedMinimum)*(originalMaximum - originalMinimum) + originalMinimum);
    else
        adjustedImage = frame;
    end

end