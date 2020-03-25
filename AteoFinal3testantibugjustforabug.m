
warning off all
clear all;close all;clc;
% addpath(genpath('/Users/mateo/Documents/MATLAB'))
%here change the folder for easier selection of your data file
%cd('/Users/mateo/Documents/DATA/RAW')
%cd('/Users/mateo/Documents/Figures hopefully lasts/Test MatLab traces export')
% cd('/Volumes/maateo/Synology/Mateo 2016 rig1/Juin/juin 9')
% Ask the user for directory
selectedDir=uigetdir;
% change path
cd(selectedDir);
% get directory name and path separately
[pathToDirName dirName] = fileparts(selectedDir);
%Can change it if you want F instead of df/f
df_over_f=1;
%That will store whether or not the file contains Ca imaging data or not
ca=[];
%That will store the current length of the line to make sure it does not
%change
c_line=[];
%Load xml file to get info about the linescan protocol
% make a variable for a name of .xml files containing the information about the sequence
fileName = [strcat(dirName) '.xml'];
%transform into structure
[s] = xml2struct(fileName);
%Get number of cycle
ncycle= size(s.PVScan.Sequence,2);
%if you want to cut some bugging cycles at the end of the XP, put here the
%ncycle arbitrairement
%ncycle=16
%% Get ephys and fluorescence signal for each cycle
V_recordings={};
% % C_command={};
Vpara={};
fluo_recordings={};
Fpara={};
boundaries=[];
%If only one cycle, it is slightly different
if ncycle==1
    %Get ephys voltage recording
    v_recording = [strcat(dirName, '_Cycle00001_VoltageRecording_001') '.csv'];
    TempData =  csvread(v_recording, 1,0);
    VoltageValues = TempData(:,2);
    %Adjust gain (get millivolts
    VoltageValues=100*VoltageValues;
    %Get timestamps in milliseconds
    TimeValues = TempData(:,1);
    V_recordings{1}=[TimeValues VoltageValues]; 
    %Get uncaging data
    nomark(1)=0;
    try
        Uncaging{1} = markpoints([strcat(dirName, '_Cycle00001_MarkPoints') '.xml']);
    catch
        Uncaging{1}={};
        Uncaging{1}.InterPointDelay=1000;
        nomark(1)=1;
    end   
    %Get linescan xml file
    tempo = s.PVScan.Sequence;a

    %Get prior ROI boundaries if existent, otherwise start with generic [20
    %50]
    try
        B=[str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x0) str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x1)];
    catch
        B=[5 10];
    end
    %Get fluo image
    image = imread([strcat(dirName, '_Cycle00001_Ch1_000001') '.ome.tif']);
    
    if size(image,1)>10 & Uncaging{1}.InterPointDelay<20
        ca(1)=1;
        %Get fluo data
        [fluo_recordings{1} Fpara{1} boundaries]=line_Ca_first(tempo,image, B);
    else
        ca(1)=0;
    end

    %Between 2 and 9 cycles
else if ncycle<10
        %Get ephys voltage recording
        v_recording = [strcat(dirName, '_Cycle00001_VoltageRecording_001') '.csv'];
        TempData =  csvread(v_recording, 1,0);
        VoltageValues = TempData(:,2);
        %Adjust gain (get millivolts
        VoltageValues=100*VoltageValues;
        %Get timestamps in milliseconds
        TimeValues = TempData(:,1);
        V_recordings{1}=[TimeValues VoltageValues];
            
        %Get uncaging data
        nomark(1)=0;
        try
            Uncaging{1} = markpoints([strcat(dirName, '_Cycle00001_MarkPoints') '.xml']);
        catch
            Uncaging{1}={};
            Uncaging{1}.InterPointDelay=1000;
            nomark(1)=1;
        end
        
        %Get linescan xml file
        tempo = s.PVScan.Sequence {1};
        
        %Get prior ROI boundaries if existent, otherwise start with generic [20
        %50]
        try
            B=[str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x0) str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x1)];
        catch
            B=[10 20];
        end
              
        %Get fluo image
        image = imread([strcat(dirName, '_Cycle00001_Ch1_000001') '.ome.tif']);
        c_line=size(image,2);
        if size(image,1)>10 & Uncaging{1}.InterPointDelay<20
            ca(1)=1;
            %Get fluo data
            [fluo_recordings{1} Fpara{1} boundaries]=line_Ca_final_Mateo(tempo,image, B);
        else
            ca(1)=0;
            boundaries=B;
        end
        
        for i=2:ncycle
            % Get the files
      
            v_recording = [strcat(dirName, '_Cycle0000',num2str(i),'_VoltageRecording_001') '.csv'];
            
            TempData =  csvread(v_recording, 1,0);
            VoltageValues = TempData(:,2);
            %Adjust gain (get millivolts
            VoltageValues=100*VoltageValues;
            %Get timestamps in milliseconds
            TimeValues = TempData(:,1);
            V_recordings{i}=[TimeValues VoltageValues];
            
            %Get uncaging data
            nomark(i)=0;
            try
                Uncaging{i} = markpoints([strcat(dirName, '_Cycle0000',num2str(i),'_MarkPoints') '.xml']);
            catch
                Uncaging{i}={};
                Uncaging{i}.InterPointDelay=1000;
                nomark(i)=1;
            end
            
            
            %Get linescan xml file
            tempo = s.PVScan.Sequence {i};
            
            %Get fluo image
            image = imread([strcat(dirName, '_Cycle0000',num2str(i),'_Ch1_000001') '.ome.tif']);
            
            if size(image,1)>10 & Uncaging{i}.InterPointDelay<20
                ca(i)=1;
                %Get fluo data
                [fluo_recordings{i} Fpara{i} boundaries]=line_Ca_final_Mateo(tempo,image, boundaries);
                c_line=size(image,2);
                
            else
                ca(i)=0;
            end
     
            
        end
        
        %IF more than 9 cycles
    else
        % Get the files
        v_recording = [strcat(dirName, '_Cycle00001_VoltageRecording_001') '.csv'];
        TempData =  csvread(v_recording, 1,0);
        VoltageValues = TempData(:,2);
        %Adjust gain (get millivolts
        VoltageValues=100*VoltageValues;
        %Get timestamps in milliseconds
        TimeValues = TempData(:,1);
        V_recordings{1}=[TimeValues VoltageValues];
        
        %Get uncaging data
        nomark(1)=0;
        try
            Uncaging{1} = markpoints([strcat(dirName, '_Cycle00001_MarkPoints') '.xml']);
        catch
            Uncaging{1}={};
            Uncaging{1}.InterPointDelay=1000;
            nomark(1)=1;
            
        end
        
        %Get linescan xml file
        tempo = s.PVScan.Sequence {1};
        
        %Get prior ROI boundaries if existent, otherwise start with generic [20
        %50]
        try
            B=[str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x0) str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x1)];
        catch
            B=[10 20];
        end
        
        %Get fluo image
        image = imread([strcat(dirName, '_Cycle00001_Ch1_000001') '.ome.tif']);
        if size(image,1)>10 & Uncaging{1}.InterPointDelay<20
            ca(1)=1;
            c_line=size(image,2);
            %Get fluo data
            [fluo_recordings{1} Fpara{1} boundaries]=line_Ca_final_Mateo(tempo,image, B);
        else
            ca(1)=0;
            boundaries=B;
        end

        
        for i=2:9
            v_recording = [strcat(dirName, '_Cycle0000',num2str(i),'_VoltageRecording_001') '.csv'];

            TempData =  csvread(v_recording, 1,0);
            VoltageValues = TempData(:,2);
            %Adjust gain (get millivolts
            VoltageValues=100*VoltageValues;
            %Get timestamps in milliseconds
            TimeValues = TempData(:,1);
            V_recordings{i}=[TimeValues VoltageValues];
            
            %Get uncaging data
            nomark(i)=0;
            try
                Uncaging{i} = markpoints([strcat(dirName, '_Cycle0000',num2str(i),'_MarkPoints') '.xml']);
            catch
                Uncaging{i}={};
                Uncaging{i}.InterPointDelay=1000;
                nomark(i)=1;
            end
            
            
            %Get linescan xml file
            tempo = s.PVScan.Sequence {i};
            %Get fluo image
            image = imread([strcat(dirName, '_Cycle0000',num2str(i),'_Ch1_000001') '.ome.tif']);
        
            if size(image,1)>10 & Uncaging{i}.InterPointDelay<20
                ca(i)=1;
                %Get fluo data
                
                [fluo_recordings{i} Fpara{i} boundaries]=line_Ca_final_Mateo(tempo,image, boundaries);
                c_line=size(image,2);
            
            else
                ca(i)=0;
            end

            
        end
        for i=10:ncycle
    
            v_recording = [strcat(dirName, '_Cycle000',num2str(i),'_VoltageRecording_001') '.csv'];
            
            try
                TempData =  csvread(v_recording, 1,0);
            catch
                TempData=[0 -0.6;0 -0.6];
            end
            
            VoltageValues = TempData(:,2);
            %Adjust gain (get millivolts
            VoltageValues=100*VoltageValues;
            %Get timestamps in milliseconds
            TimeValues = TempData(:,1);
            V_recordings{i}=[TimeValues VoltageValues];
            
            %Get uncaging data
            nomark(i)=0;
            try
                Uncaging{i} = markpoints([strcat(dirName, '_Cycle000',num2str(i),'_MarkPoints') '.xml']);
            catch
                Uncaging{i}={};
                Uncaging{i}.InterPointDelay=1000;
                nomark(i)=1;
            end
            
            %Get linescan xml file
%             s.PVScan.Sequence {17}=s.PVScan.Sequence {16};
%             s.PVScan.Sequence {18}=s.PVScan.Sequence {16};
%             s.PVScan.Sequence {19}=s.PVScan.Sequence {16};
%             s.PVScan.Sequence {20}=s.PVScan.Sequence {16};
%             s.PVScan.Sequence {21}=s.PVScan.Sequence {16};
            
            tempo = s.PVScan.Sequence {i};
            %Get fluo image
            image = imread([strcat(dirName, '_Cycle000',num2str(i),'_Ch1_000001') '.ome.tif']);
            
            
            if size(image,1)>10 & Uncaging{i}.InterPointDelay<20
                ca(i)=1;
                try
                [fluo_recordings{i} Fpara{i} boundaries]=line_Ca_final_Mateo(tempo,image, boundaries);
                catch
                end
                c_line=size(image,2);
                
            else
                ca(i)=0;
                
            end
      
        end
    end
end
%stupid random picture of the man of the years
%Pink noise one dimensional interpolation

%change back


%Remove uncaging artefact
%Store indices of the break in here
artefact_break={};

for i=1:ncycle
    if ca(i)==1
        %Compute uncaging generous limits
        limit1=floor((Uncaging{i}.InitialDelay)/(Fpara{i}.scanLinePeriod))-5;
        limit2= ceil((Uncaging{i}.InitialDelay+Uncaging{i}.Total)/(Fpara{i}.scanLinePeriod));
        
        %Compute sd
        sd=std(fluo_recordings{i}(1:limit1,2));
        
        %Get indice of first point below 3 sds
        threshold1=mean(fluo_recordings{i}(1:limit1,2))-3*sd;
        indices1=[];
        for j=limit1:limit2
            if fluo_recordings{i}(j,2)<threshold1 & fluo_recordings{i}(j+1,2)<threshold1
                indices1=j-1;
                break;
            end
        end
        
        %Get indice of first point resurfacing above -3sd
        threshold2=mean(fluo_recordings{i}(1:limit1,2))-3*sd;
        indices2=[];
        for j=limit2:limit2+100
            if fluo_recordings{i}(j,2)>threshold2 & fluo_recordings{i}((j+1),2)>threshold2
                indices2=j;
                break;
            end
            if j==limit2+100
                indices2=limit2;
                ca(i)=0;
                
            end
        end
        
        if isempty(indices1)
            indices1=limit1;
            indices2=limit2;
            
        end
        %Get beginning and end of points to remove
        artefact=[ indices1 indices2];
        temp=fluo_recordings{i};
        fluo_recordings{i}=[];
        try
fluo_recordings{i}= temp([1:artefact(1) artefact(2):end],:);
        catch
        end
        artefact_break{i}=artefact(1);
    end
    
end


%Compute df/f and store it in the third column of fluo_recording
try
for i=1:ncycle
    if ca(i)==1
        %Compute mean only on baseline before current injection
        %get last point before uncaging
        limit=floor((Uncaging{i}.InitialDelay)/(Fpara{i}.scanLinePeriod))-10;
        %GEt mean
        temp2=mean(fluo_recordings{i}(1:limit,2));
        
        fluo_recordings{i}(:,3)= (fluo_recordings{i}(:,2)-temp2)./temp2;
    end
    clearvars temp2
end

catch
end

%% extract power and test
try
for i=1:ncycle
LaserPowa(i)=Uncaging{i}.UncagingLaserPower
end

if mean(size(unique(LaserPowa)))~=1
    display ('Ya un laser powa change pendant la manip, fait gaffe a ce que tu fais bordel')
end
catch
end
%% Plot ephys and fluo data
%one figure per cycle
try
    for i=1:ncycle
    if ca(i)==1
        FAT=figure(i);
        FAT.Position=[0 500-(i*20) 300 300];
        %Plot voltage
        subplot(2,1,1)
        h=plot(V_recordings{i}(:,1),V_recordings{i}(:,2));
        hold on;
        h.LineWidth=1.5;
        h.Color='b';
        xlabel('ms')
        ylabel('mV')
        title('Voltage recording')
        
        %Add uncaging info on plot
        dim = [0.65 0.6 0.3 0.3];
        str = {strcat('Cycle = ',num2str(i)),strcat('Laser Power = ',num2str((Uncaging{i}.UncagingLaserPower))),strcat('Number of points = ',num2str((Uncaging{i}.nPoints))),strcat('Duration = ',num2str((Uncaging{i}.Duration))),strcat('InterPointDelay = ',num2str((Uncaging{i}.InterPointDelay)))};
        a=annotation('textbox',dim,'String',str,'FitBoxToText','on');
        a.FontSize=8;
        
        %Add arrows indicating uncaging times
        x =Uncaging{i}.InitialDelay;
        xarray=[x];
        for j=2:Uncaging{i}.nPoints
            x=x+(Uncaging{i}.Duration+Uncaging{i}.InterPointDelay);
            xarray=[xarray x];
        end
        y=min(V_recordings{i}(:,2));
        
        for j=1:Uncaging{i}.nPoints
            str1 = strcat('\uparrow ');%, num2str(j));
            t=text(xarray(j),y,str1);
            t.FontSize=10;
        end
        
        if ca(i)==1;
            %Plot calcium signal
            if df_over_f==1
                %Plot df/f
                subplot(2,1,2)
                h=plot(fluo_recordings{i}(1:artefact_break{i},1),fluo_recordings{i}(1:artefact_break{i},3));
                h.LineWidth=1.5;
                h.Color='g';
                
                hold on
                h=plot(fluo_recordings{i}((artefact_break{i}+1):end,1),fluo_recordings{i}((artefact_break{i}+1):end,3));
                h.LineWidth=1.5;
                h.Color='g';
                
                
                xlabel('ms')
                ylabel('df/f')
                title('Fluorescence')
                try
                    xlim([0 max(V_recordings{i}(:,1))])
                catch
                    lou=[];
                end
                
                %Add arrows indicating uncaging times
                x =Uncaging{i}.InitialDelay;
                xarray=[x];
                for j=2:Uncaging{i}.nPoints
                    x=x+(Uncaging{i}.Duration+Uncaging{i}.InterPointDelay);
                    xarray=[xarray x];
                end
                y=min(fluo_recordings{i}(:,3));
                for j=1:Uncaging{i}.nPoints
                    str1 = strcat('\uparrow ');%, num2str(j));
                    t=text(xarray(j),y,str1);
                    t.FontSize=10;
                end
            else
                %Plot fluo
                subplot(2,1,2)
                h=plot(fluo_recordings{i}(1:artefact_break{i},1),fluo_recordings{i}(1:artefact_break{i},2));
                h.LineWidth=1.5;
                h.Color='g';
                
                hold on
                h=plot(fluo_recordings{i}((artefact_break{i}+1):end,1),fluo_recordings{i}((artefact_break{i}+1):end,2));
                h.LineWidth=1.5;
                h.Color='g';
                
                xlabel('ms');
                ylabel('F');
                title('Fluorescence');
                xlim([0 max(V_recordings{i}(:,1))]);
                
                %Add arrows indicating uncaging times
                x =Uncaging{i}.InitialDelay;
                xarray=[x];
                for j=2:Uncaging{i}.nPoints
                    x=x+(Uncaging{i}.Duration+Uncaging{i}.InterPointDelay);
                    xarray=[xarray x];
                end
                y=min(fluo_recordings{i}(:,2));
                for j=1:Uncaging{i}.nPoints
                    str1 = strcat('\uparrow ');%, num2str(j));
                    t=text(xarray(j),y,str1);
                    t.FontSize=10;
                end
            end
        end
    end
    
    end
    catch
end



%% Get ref image and plot it with freehand on it

% Change folder to get ref image
try
    selectedDir1=[selectedDir '\References'];
    % change path
    cd(selectedDir1);
    %Get ref image
    try
        ref_image = im2double(imread([strcat(dirName, '-Cycle00002-Window1-Ch1-Ch2-8bit-Reference') '.tif']));
    catch
        ref_image = im2double(imread([strcat(dirName, '-Cycle00002-Window1-Ch1-8bit-Reference') '.tif']));
    end
    
catch
    selectedDir1=[selectedDir '/References'];
    % change path
    cd(selectedDir1);
    %Get ref image
    try
        ref_image = im2double(imread([strcat(dirName, '-Cycle00002-Window1-Ch1-Ch2-8bit-Reference') '.tif']));
    catch
        ref_image = im2double(imread([strcat(dirName, '-Cycle00002-Window1-Ch1-8bit-Reference') '.tif']));
    end
end

Ref=figure(999);
Ref.Name=('Reference Image');
Ref.Position=[1440   378   560   420];
imagesc(ref_image(:,:,1:3));
title('Reference image');
axis off;

%% Ask user to select cycles with same intensity but increasing number of points

% %% Plot all cycles with same number of points together
sele=[1];
try
%while ~isempty(sele)
    %ucycles = input('balance la sauce');
    ucycles=[1:ncycle];
    
    
    for k=1:50
        
        
        index=[];
        for j=ucycles
            if Uncaging{j}.nPoints==k;
                if ca(j)==1
                    index=[index j];
                end
            end
        end
        
        if ~isempty(index)
            color = varycolor(length(index));
             dooo=figure(1000+k);
            leg={};
            for i=index
                 dooo.Position=[(k*11)-250 500-(k*20) 500 380];
                %Plot voltage
                subplot(2,1,1)
                hold on
                h=plot(V_recordings{i}(:,1),V_recordings{i}(:,2));
                h.LineWidth=1;
                h.Color=color(find(index==i),:);
              
                xlabel('ms')
                ylabel('mV')
                a=strcat([num2str(k), ' points / Voltage']);
                title(a)
                
                %Legend
                leg{(find(index==i))}=strcat(['Cycle ' ,num2str(i)]);
                if i==index(end)
                    l=legend(leg);
                    l.LineWidth=0.05;
                    l.FontSize=5;
                end
                
           title('Current command')
                
                if ca(i)==1
                    %Plot calcium signal
                    %Plot df/f
                    if df_over_f
                        subplot(2,1,2)
                        hold on
                        h=plot(fluo_recordings{i}(1:artefact_break{i},1),fluo_recordings{i}(1:artefact_break{i},3));
                        h.LineWidth=1.5;
                        h.Color=color(find(index==i),:);
                        
                        hold on
                        h=plot(fluo_recordings{i}((artefact_break{i}+1):end,1),fluo_recordings{i}((artefact_break{i}+1):end,3));
                        h.LineWidth=1.5;
                        h.Color=color(find(index==i),:);
                        xlabel('ms')
                        ylabel('DF/F')
                        a=strcat([num2str(k), ' points / Fluorescence']);
                        
                        title(a)
                        try
                            xlim([0 max(V_recordings{i}(:,1))])
                        catch
                            lou=[];
                        end
                        
                    else
                        subplot(2,1,2)
                        hold on
                        h=plot(fluo_recordings{i}(1:artefact_break{i},1),fluo_recordings{i}(1:artefact_break{i},2));
                        h.LineWidth=1.5;
                        h.Color=color(find(index==i),:);
                        
                        hold on
                        h=plot(fluo_recordings{i}((artefact_break{i}+1):end,1),fluo_recordings{i}((artefact_break{i}+1):end,2));
                        h.LineWidth=1.5;
                        h.Color=color(find(index==i),:);
                        xlabel('ms')
                        ylabel('F')
                        a=strcat([num2str(k), ' points / Fluorescence']);
                        
                        title(a)
                        xlim([0 max(V_recordings{i}(:,1))])
                        
                    end
                end
            end
        end
    end
    
    %sele = input('Press enter if ok, anything else otherwise ');
    
    
%end
catch
end
%%
if ucycles~=0'
      
   
    %Get number of points for those cycles and sort them
    for i=1:size(ucycles,2)
        try
        ucycles(2,i)=Uncaging{ucycles(1,i)}.nPoints;
        catch
        end
    end
    ucycles=sortrows(ucycles',2)';
    
    %Compute peak for EPSP and fluo and store them in the third and fourth rows
    for i=1:size(ucycles,2)
        %EPSP amplitude
        %Compute index of last point before uncaging
        try
        limit=floor((Uncaging{ucycles(1,i)}.InitialDelay)/(0.05))-1;
        catch
        end
        %GEt mean of baseline
        try
        temp=mean(V_recordings{ucycles(1,i)}(1:limit,2));
        catch
        end
        %Get max of EPSP, look only after stimmulus is presented and look at
        %the following 300ms only
        try
        timelimits=(Uncaging{ucycles(1,i)}.InitialDelay/.05):(((Uncaging{ucycles(1,i)}.InitialDelay+80)/.05));
        catch
        end
        try
            ss=smooth(V_recordings{ucycles(1,i)}(timelimits,2),11);
            ucycles(3,i)=max(ss)-temp;
        catch
            ss=smooth(V_recordings{ucycles(1,i)}(:,2),11);
            ucycles(3,i)=max(ss)-temp;
        end
        
        
        %EPSP area
        %look only after stimmulus is presented and look at
        %the following 300ms only
        try
            ucycles(5,i)=trapz(V_recordings{ucycles(1,i)}(timelimits,1),(V_recordings{ucycles(1,i)}(timelimits,2)-temp));
        catch
            ucycles(5,i)=trapz(V_recordings{ucycles(1,i)}(:,1),(V_recordings{ucycles(1,i)}(:,2)-temp));
            
        end
  
        %Calcium
        if ca(ucycles(1,i))==1
            if df_over_f
                
                %period
                pp=Fpara{1,ucycles(1,i)}.scanLinePeriod;
                %smoothing bins
                if pp>0.5
                    bin=5;
                else
                    bin=3;
                end
                
                timelimits=ceil(Uncaging{ucycles(1,i)}.InitialDelay/pp);
                %peak
                try
                    ss=smooth(fluo_recordings{ucycles(1,i)}(timelimits:end,3),bin);
                catch
                    ss=smooth(fluo_recordings{ucycles(1,i)}(:,3),bin);
                end
                ucycles(4,i)=max(ss);
                
                
                %Area
                lim=(ceil(Uncaging{ucycles(1,i)}.InitialDelay/Fpara{ucycles(1,i)}.scanLinePeriod));
                try
                    
                    ucycles(6,i)=trapz(fluo_recordings{ucycles(1,i)}(lim:end,1),(fluo_recordings{ucycles(1,i)}(lim:end,3)));
                catch
                    ucycles(6,i)=trapz(fluo_recordings{ucycles(1,i)}(:,1),(fluo_recordings{ucycles(1,i)}(:,3)));
                    
                end
     
            else
                
                %period
                pp=Fpara{1,ucycles(1,i)}.scanLinePeriod;
                %smoothing bins
                if pp>0.5
                    bin=5;
                else
                    bin=3;
                end
                
                timelimits=ceil(Uncaging{ucycles(1,i)}.InitialDelay/pp)
                %peak
                ss=smooth(fluo_recordings{ucycles(1,i)}(timelimits,2),bin);
                ucycles(4,i)=max(ss);
                
                %Area
                %get last point before uncaging
                limit=floor((Uncaging{ucycles(1,i)}.InitialDelay)/(Fpara{ucycles(1,i)}.scanLinePeriod))-10;
                %GEt mean
                temp3=mean(fluo_recordings{ucycles(1,i)}(1:limit,2));
                
                lim=(ceil(Uncaging{ucycles(1,i)}.InitialDelay/Fpara{ucycles(1,i)}.scanLinePeriod));
                try
                    ucycles(6,i)=trapz(fluo_recordings{ucycles(1,i)}(lim:end,1),(fluo_recordings{ucycles(1,i)}(lim:end,2)-temp3));
                catch
                    ucycles(6,i)=trapz(fluo_recordings{ucycles(1,i)}(:,1),(fluo_recordings{ucycles(1,i)}(:,2)-temp3));
                    
                end
           
            end
        
        end   
    end
 
  
    %% Plot figure with voltage traces, calcium traces, and input/output relationship
    color = varycolor(size(ucycles,2));
    figure(2000);
    leg={};
    try
    for i=1:size(ucycles,2)
        
        %Plot voltage
        subplot(2,2,1)
        hold on
        h=plot((V_recordings{ucycles(1,i)}(:,1)-Uncaging{ucycles(1,i)}.InitialDelay),V_recordings{ucycles(1,i)}(:,2));
        h.LineWidth=1;
        h.Color=color(i,:);
        xlabel('Time from onset (ms)')
        ylabel('mV')
        title('Voltage recording')
        xlim([(-50) (200)])
        
        
        %Legend
        leg{i}=strcat([num2str(ucycles(2,i)), '(',num2str(ucycles(1,i)),')']);
        if i==size(ucycles,2)
            l=legend(leg);
            l.LineWidth=0.05;
            l.FontSize=5;
        end
 
        if ca(ucycles(1,i))==1
            %Plot df/f
            if df_over_f
                subplot(2,2,3)
                hold on
                
                h=plot(fluo_recordings{ucycles(1,i)}(1:artefact_break{ucycles(1,i)},1)-Uncaging{ucycles(1,i)}.InitialDelay,fluo_recordings{ucycles(1,i)}(1:artefact_break{ucycles(1,i)},3));
                h.LineWidth=1.5;
                h.Color=color(i,:);
                hold on
                h=plot((fluo_recordings{ucycles(1,i)}((artefact_break{ucycles(1,i)}+1):end,1)-Uncaging{ucycles(1,i)}.InitialDelay),fluo_recordings{ucycles(1,i)}((artefact_break{ucycles(1,i)}+1):end,3));
                h.LineWidth=1.5;
                h.Color=color(i,:);
                
                xlabel('Time from onset (ms)')
                ylabel('DF/F')
                title('Fluorescence')
                xlim([(-50) (200)])
            else
                subplot(2,2,3)
                hold on
                h=plot(fluo_recordings{ucycles(1,i)}(1:artefact_break{ucycles(1,i)},1)-Uncaging{ucycles(1,i)}.InitialDelay,fluo_recordings{ucycles(1,i)}(1:artefact_break{ucycles(1,i)},2));
                h.LineWidth=1.5;
                h.Color=color(i,:);
                
                hold on
                h=plot(fluo_recordings{ucycles(1,i)}((artefact_break{ucycles(1,i)}+1):end,1)-Uncaging{ucycles(1,i)}.InitialDelay,fluo_recordings{ucycles(1,i)}((artefact_break{ucycles(1,i)}+1):end,2));
                h.LineWidth=1.5;
                h.Color=color(i,:);
                
                
                xlabel('Time from onset (ms)')
                ylabel('F')
                title('Fluorescence')
                xlim([(-50) (200)])
            end      
        end
    end
    catch
    end
    try
    %Add arrows indicating uncaging times
    subplot(2,2,1)
    x =0;
    y=min(V_recordings{ucycles(1,1)}(:,2))-1;
    str1 = strcat('\uparrow ');%, num2str(j));
    t=text(x,y,str1);
    t.FontSize=14;
    
    subplot(2,2,3)
    x =0;
    if df_over_f==1
        try
y=min(fluo_recordings{ucycles(1,1)}(:,3));
        catch
        end
    else
        y=min(fluo_recordings{ucycles(1,1)}(:,2));
    end
    str1 = strcat('\uparrow ');%, num2str(j));
    t=text(x,y,str1);
    t.FontSize=14;
    
    
    %Plot EPSP amplitude
    subplot(4,2,2)
    hold on
    h=plot(ucycles(2,:), ucycles(3,:),'b--o');
    
    bmat = num2str(ucycles(1,:)'); cmat = cellstr(bmat);
    
    scatter(ucycles(2,:), ucycles(3,:))
    text(ucycles(2,:), ucycles(3,:), cmat)
    h.LineWidth=1;
    h.Color='b';
    xlabel('Number of inputs','FontSize',8)
    ylabel('EPSP amplitude (mV)','FontSize',8)
    xlim([0 (10*ceil(max(ucycles(2,:)')/10))])
  
    %Plot EPSP area
    subplot(4,2,4)
    hold on
    h=plot(ucycles(2,:), ucycles(5,:),'b--o');
    h.LineWidth=1;
    h.Color='b';
    xlabel('Number of inputs','FontSize',8)
    ylabel('EPSP area (mV*ms)','FontSize',8)
    xlim([0 (10*ceil(max(ucycles(2,:)')/10))])
    
    %Plot calcium signal
    if ca(ucycles(1,i))==1
        %Plot df/f peak
        %Plot calcium amplitude
        subplot(4,2,6)
        hold on
        h=plot(ucycles(2,:), ucycles(4,:),'b--o');
        h.LineWidth=1;
        h.Color='g';
        xlim([0 (10*ceil(max(ucycles(2,:)')/10))])
        xlabel('Number of inputs','FontSize',8)
        
        if df_over_f==1
            ylabel('DF/F peak','FontSize',8)
        else
            ylabel('F amplitude','FontSize',8)
        end
        
        %Plot df/f area
        %Plot calcium amplitude
        subplot(4,2,8)
        hold on
        h=plot(ucycles(2,:), ucycles(6,:),'b--o');
        h.LineWidth=1;
        h.Color='g';
        xlim([0 (10*ceil(max(ucycles(2,:)')/10))])
        xlabel('Number of inputs','FontSize',8)
        
        if df_over_f==1
            ylabel('DF/F area','FontSize',8)
        else
            ylabel('F area','FontSize',8)
        end
        
        
    end
    
    catch
    
end

end
%%
try
hmat=figure(2998);
hmat.Name=('Check Amplitude');
scatter(ucycles(2,:), ucycles(3,:), 150, 'r', 'filled');
    text(ucycles(2,:)+0.2, ucycles(3,:)+0.2, cmat);
hmat1=figure(2999);
hmat1.Name=('Check Calcium');
    scatter(ucycles(2,:), ucycles(4,:), 150, 'g', 'filled');
    text(ucycles(2,:)+0.02, ucycles(4,:)+0.02, cmat);
    
hmat.Position=[0 380 1000 800];
hmat1.Position=[50 330 1000 800];
catch
    display('probleme avec la figure pour checker les cycles')
end
%% PLot spreadout uncaging...
for i=1:ncycle
    if ca(i)==0 && nomark(i)==0
        
        Findividual=figure(i+100);
        Findividual.Position=[400 400-(i*20) 400 400];
        %Plot voltage
        %     subplot(2,1,1)
        h=plot(V_recordings{i}(:,1),V_recordings{i}(:,2));
        hold on;
        h.LineWidth=1.5;
        h.Color='b';
        xlabel('ms')
        ylabel('mV')
        a=strcat(['Cycle ', num2str(i)]);
        title(a)
        
        try
        %Add uncaging info on plot
        dim = [0.65 0.6 0.3 0.3];
        str = {strcat('Cycle = ',num2str(i)),strcat('Laser Power = ',num2str((Uncaging{i}.UncagingLaserPower))),strcat('Number of points = ',num2str((Uncaging{i}.nPoints))),strcat('Duration = ',num2str((Uncaging{i}.Duration))),strcat('InterPointDelay = ',num2str((Uncaging{i}.InterPointDelay)))};
        a=annotation('textbox',dim,'String',str,'FitBoxToText','on');
        a.FontSize=8;
        catch
        end
        try
        %Add arrows indicating uncaging times
        x =Uncaging{i}.InitialDelay;
        xarray=[x];
        for j=2:Uncaging{i}.nPoints
            x=x+(Uncaging{i}.Duration+Uncaging{i}.InterPointDelay);
            xarray=[xarray x];
        end
        y=min(V_recordings{i}(:,2));
        
        for j=1:Uncaging{i}.nPoints
            str1 = strcat('\uparrow ');%, num2str(j));
            t=text(xarray(j),y,str1);
            t.FontSize=10;
        end
        catch
        end
        
    end
end

%% Ask user to select cycles where the uncaging points are spread out and the uncaging power is constant
%Make sure they have the same number of uncaging points, won't work
%otherwise

ucycles2 = input('Les Units por favor :-) ');
if ucycles2~=0
    
    %GEt voltage traces from these cycles and interpolate data so that the
    %jumps are 0.01 instead of 0.05
    for i=1:size(ucycles2,2)
        xi=0:0.01:(max(V_recordings{ucycles2(1,i)}(:,1)));
        ind_V{i}=[xi' (interp1(V_recordings{ucycles2(1,i)}(:,1),V_recordings{ucycles2(1,i)}(:,2),xi))'];
    end

    clear xi
    %Get parameters in number of points in the voltage trace (divide by
    %1/acquisition frequency)
    points=Uncaging{ucycles2(1,1)}.nPoints;
    dur=Uncaging{ucycles2(1,1)}.Duration/.01;
    delay=Uncaging{ucycles2(1,1)}.InterPointDelay/.01;
    init_delay=Uncaging{ucycles2(1,1)}.InitialDelay/.01;
    totdelay=dur+delay; 
    %create matrix where each row is the voltage trace for each point
    %Begin 1/5 of the totaldelay time and end 4/5 of it
    ind_points={};
    %first point stuff
    start1=init_delay-(0.2*totdelay);
    end1=init_delay+(0.8*totdelay)-1;
    
    for i=1:size(ucycles2,2)
        for j=1:points
            st=start1+((j-1)*totdelay);
            et=(end1+((j-1)*totdelay));
            temp=ind_V{i}(st:et,2);
            %Remove baseline
            temp_m=mean(temp(1:((0.2*totdelay)-1)));
            temp2=temp-temp_m;
            ind_points{j}(:,i)= temp2;
        end
    end
    
    %Compute mean and sd for each uncaging site
    m_points={};
    
    for j=1:points
        m_points{j}(:,1)= mean(ind_points{j}')';
        m_points{j}(:,2)= std(ind_points{j}')';
    end
    
%     m_points{1,21}=m_points{1,12}
%     m_points{1,22}=m_points{1,14}
%     m_points{1,23}=m_points{1,15}
%     m_points{1,24}=m_points{1,16}
%     
%      ind_points{1,21}=ind_points{1,12}
%     ind_points{1,22}=ind_points{1,14}
%     ind_points{1,23}=ind_points{1,15}
%     ind_points{1,24}=ind_points{1,16}
    
    %Compute mean and sd for total (average)
    temp=[];
    for j=1:24
        temp=[temp m_points{j}(:,1)];
    end
    t_points=[mean(temp')' std(temp')'];
    
    %Compute average EPSP for each uncaging site
    upeak=[];
    for j=1:24
        temp=ind_points{j};
        for k=1:size(ucycles2,2)
            temp(:,k)=smooth(temp(:,k),11);
        end
        tempo=max(temp);
        upeak(j)=mean(tempo);
        ustd(j)=std(tempo);
    end
 
    %Compute mean and std peak total
    m_peak=mean(upeak')';
    m_std=std(upeak);

    %Get x axis
    xxx=-totdelay*0.2:0.8*totdelay-1;
    xxx=xxx*0.01;

    %Plot average for each uncaging site in subplots
    figure(3000)
    k=1;
    try
    for i=1:24
        %Restart new figure
        if ismember(i,[7 13 19 25])
            figure(3000+i);k=1;
        end
        
        subplot(2,3,k)
        try
        shadedErrorBar(xxx,m_points{i}(:,1),m_points{i}(:,2),'b')
        catch
        end
        xlabel('Time from onset (ms)')
        ylabel('mV')
        tt=strcat('Uncaging site ',num2str(i));
        title(tt)
        xlim([(min(xxx)) (max(xxx))])
        ylim([-0.5 2])
        k=k+1;
    end
    catch
    end

    %PLot average of all sites
    figure(3500)
    try
    shadedErrorBar(xxx,t_points(:,1),t_points(:,2),'b')
    catch
    end
    xlabel('Time from onset (ms)')
    ylabel('mV')
    
    title('Average of all uncaging sites')
    xlim([(min(xxx)) (max(xxx))])
    ylim([-0.5 2])
clearvars t_points
    %Plot average of the traces that were averaged
    try
        
        
        travg=V_recordings{ucycles2(1,1)}(:,2);
        for i=2:size(ucycles2,2)
            travg=travg+V_recordings{ucycles2(1,i)}(:,2);
        end
        travg=travg/size(ucycles2,2);
        figure(4000)
        hold on
        plot(V_recordings{ucycles2(1,1)}(:,1),travg,'b')
        xlabel('ms')
        ylabel('mV')
        title('Average of the traces')
        
        %Add arrows indicating uncaging times
        %Add arrows indicating uncaging times
        x =Uncaging{ucycles2(1,1)}.InitialDelay;
        xarray=[x];
        for j=2:Uncaging{ucycles2(1,1)}.nPoints
            x=x+(Uncaging{ucycles2(1,1)}.Duration+Uncaging{ucycles2(1,1)}.InterPointDelay);
            xarray=[xarray x];
        end
        y=min(V_recordings{ucycles2(1,1)}(:,2));
        
        for j=1:Uncaging{ucycles2(1,1)}.nPoints
            str1 = strcat('\uparrow ');%, num2str(j));
            t=text(xarray(j),y,str1);
            t.FontSize=10;
        end
        
    catch
        yo=[];
    end

    try
    %PLot summary statistics
    figure(4001)
    subplot(1,3,1)
    bar(1:points,upeak(1,:))
    hold on
    e=errorbar(1:points,upeak(1,:),ustd(1,:));
    e.LineStyle='none';
    title('Individual EPSP amplitude')
    ylabel('mV')
    xlim([0 points])
    
    subplot(1,3,2)
    h=histogram(upeak(1,:));
    h.BinWidth=floor(100*(max(upeak(1,:))/(0.5*points)))/100;
    title('Distribution of EPSP amplitude')
    ylabel('mV')
    
    subplot(1,3,3)
    bar(1,m_peak(1,:))
    hold on
    e=errorbar(1,m_peak,m_std/sqrt(points));
    e.LineStyle='none';
    title('Average EPSP amplitude')
    ylabel('mV')
    catch
        flag='bug au units'
    end
    
    %%

    %Compute expected EPSP, in order to plot observed vs expected EPSP, and
    %DF/F as a function of expected EPSP.
  
    %GEt total delay between each point (interpoint delay+uncaging time) for
    %first cycle of ucycles
    try
    expdelay=(Uncaging{ucycles(1,1)}.Duration/.01)+(Uncaging{ucycles(1,1)}.InterPointDelay/.01);
    catch
        expdelay=0.32
    end
    %Compute expected waveform for 1:points
   
    %GEt last index that can be summed up
    m_ind=size(m_points{1},1);
    expwave=[];
    expwave(:,1)=m_points{1}(1:m_ind,1);
    
    for i=2:24
        %first index to sum up
        i1=1+((i-1)*expdelay);
        %Transfer to next waveform
        expwave(:,i)=expwave(:,(i-1));
        %Sum up only when there are points to sum up
        expwave(i1:m_ind,i)=expwave(i1:m_ind,i)+m_points{i}(1:(m_ind-i1+1),1);
    end

%     expwave(:,21)=expwave(:,20)
%      expwave(:,22)=expwave(:,20)
%       expwave(:,23)=expwave(:,20)
%        expwave(:,24)=expwave(:,20)
    %Compute peak and area of each expected waveform
    temp=expwave;
    for i=1:24
        temp(:,i)=smooth(temp(:,i),11);
    end
    
    exppeak=max(temp);
  
    %EPSP area
    limit2=0.2*totdelay+1;
    timelimits2=limit2:totdelay;
    exparea=trapz(xxx(timelimits2),expwave(timelimits2,:));

    try
    %Get exp stuff only about the number of points that were used in the actual
    %experiments
    exp2w=[];
    for i=1:size(ucycles,2)
        exp2w=[exp2w expwave(:,ucycles(2,i))];
    end
    
    exp2p=[];
    for i=1:size(ucycles,2)
        exp2p=[exp2p exppeak(:,ucycles(2,i))];
    end
    
    exp2a=[];
    for i=1:size(ucycles,2)
        exp2a=[exp2a exparea(:,ucycles(2,i))];
    end
    catch
    end
    
    %% Plot observed versus expected stuff
    color = varycolor(size(ucycles,2));
    figure(5000)
    leg={};
    
    for i=1:size(ucycles,2)
        
        %Plot observed voltage traces
        subplot(3,2,1)
        %Compute index of last point before uncaging
        try
        limit=floor((Uncaging{ucycles(1,i)}.InitialDelay)/(0.05))-1;
        catch
        end
        %GEt mean of baseline
        try
        temp=mean(V_recordings{ucycles(1,i)}(1:limit,2));
        catch
            display('whaaaa')
        end
        hold on
        try
        h=plot((V_recordings{ucycles(1,i)}(:,1)-Uncaging{ucycles(1,i)}.InitialDelay),(V_recordings{ucycles(1,i)}(:,2)-temp));
        h.LineWidth=1;
        h.Color=color(i,:);
        xlabel('Time from onset (ms)')
        ylabel('mV')
        title('Voltage recording')
        xlim([(-20) (80)])
        catch
        end
        %Legend
        leg{i}=strcat([num2str(ucycles(2,i))]);
        
        if i==size(ucycles,2)
            l=legend(leg);
            l.LineWidth=0.05;
            l.FontSize=5;
        end
        
        %Plot expected voltage traces
        try
        subplot(3,2,2)
        hold on
        h=plot(xxx,exp2w(:,i));
        h.LineWidth=1;
        h.Color=color(i,:);
        xlabel('Time from onset (ms)')
        ylabel('mV')
        title('Expected voltage')
        xlim([(-20) (80)])
        
        %Legend
        leg2{i}=num2str(ucycles(2,i));
        if i==size(ucycles,2)
            l=legend(leg2);
            l.LineWidth=0.05;
            l.FontSize=5;
        end
        catch
        end
        
    end
    
    %Plot observed vs expected EPSP amplitude
    try
    subplot(3,2,3)
    hold on
    h=plot(exp2p,ucycles(3,:),'b--o');
    h.LineWidth=1;
    h.Color='b';
    xlabel('Expected EPSP amplitude (mV)','FontSize',8)
    ylabel('Observed EPSP amplitude (mV)','FontSize',8)
    top=ceil(max(exp2p));
    t=plot(0:1:top,0:1:top);
    t.LineStyle='--';
    t.Color=[0.5 0.5 0.5];
    xlim([0 top])
    
    %Plot observed vs expected EPSP area
    subplot(3,2,4)
    hold on
    h=plot(exp2a, ucycles(5,:),'b--o');
    h.LineWidth=1;
    h.Color='b';
    xlabel('Expected EPSP area (mV*ms)','FontSize',8)
    ylabel('Observed EPSP area (mV*ms)','FontSize',8)
    top=ceil(max(exp2a));
    t=plot(0:1:top,0:1:top);
    t.LineStyle='--';
    t.Color=[0.5 0.5 0.5];
    xlim([0 top])

    %Plot calcium signal versus expected EPSP amplitude
    if ca(ucycles(1,i))==1
        %Plot df/f
        %Plot calcium amplitude
        subplot(3,2,5)
        hold on
        
        h=plot(exp2p, ucycles(4,:),'b--o');
        h.LineWidth=1;
        h.Color='g';
        
        xlabel('Expected EPSP amplitude (mV)','FontSize',8)
        top=ceil(max(exp2p));
        
        xlim([0 top])

        if df_over_f==1
            ylabel('DF/F peak','FontSize',8)
        else
            ylabel('F amplitude','FontSize',8)
        end
        
        %Plot df/f
        %Plot calcium amplitude
        subplot(3,2,6)
        hold on
        h=plot(exp2p, ucycles(6,:),'b--o');
        h.LineWidth=1;
        h.Color='g';
        
        xlabel('Expected EPSP amplitude (mV)','FontSize',8)
        top=ceil(max(exp2p));
        
        xlim([0 top])
  
        if df_over_f==1
            ylabel('DF/F area','FontSize',8)
        else
            ylabel('F area','FontSize',8)
        end
    end
    
    %Add arrows indicating uncaging times
    subplot(3,2,1)
    x =0;
    y=min(V_recordings{ucycles(1,1)}(:,2))-1;
    str1 = strcat('\uparrow ');%, num2str(j));
    t=text(x,y,str1);
    t.FontSize=14;
    
    subplot(3,2,2)
    x =0;
    y=min(V_recordings{ucycles(1,1)}(:,2))-1;
    str1 = strcat('\uparrow ');%, num2str(j));
    t=text(x,y,str1);
    t.FontSize=14;
    catch
    end
end

%% Final figure
finalf = figure(10000);
finalf.Position=[300,50,1200,700];
try
    subplot(3,3,2:3)
    %Plot average of the traces that were averaged
    
    hold on
    plot(V_recordings{ucycles2(1,1)}(:,1),travg,'b')
    xlabel('ms')
    ylabel('mV')
    title('Average of the traces')
    
    %Add arrows indicating uncaging times
    %Add arrows indicating uncaging times
    x =Uncaging{ucycles2(1,1)}.InitialDelay;
    xarray=[x];
    for j=2:Uncaging{ucycles2(1,1)}.nPoints
        x=x+(Uncaging{ucycles2(1,1)}.Duration+Uncaging{ucycles2(1,1)}.InterPointDelay);
        xarray=[xarray x];
    end
    y=min(V_recordings{ucycles2(1,1)}(:,2));
    
    for j=1:Uncaging{ucycles2(1,1)}.nPoints
        str1 = strcat('\uparrow ');%, num2str(j));
        t=text(xarray(j),y,str1);
        t.FontSize=10;
    end
    set(gca,'FontSize',8);
    
    % Ref image
    subplot(3,3,1)
    imagesc(ref_image(:,:,1:3))
    title('Reference image')
    axis off;
    set(gca,'FontSize',8);
    
    %V as function of input
    subplot(3,4,5)
    h=plot(ucycles(2,:), ucycles(3,:),'b--o');
    h.LineWidth=1;
    h.Color='b';
    xlabel('Number of inputs','FontSize',8)
    ylabel('EPSP (mV)','FontSize',8)
    xlim([0 (10*ceil(max(ucycles(2,:)')/10))])
    set(gca,'FontSize',8);
    box off
    
    %Ca signal
    subplot(3,4,6)
    h=plot(ucycles(2,:), ucycles(4,:),'b--o');
    h.LineWidth=1;
    h.Color='g';
    xlim([0 (10*ceil(max(ucycles(2,:)')/10))])
    xlabel('Number of inputs','FontSize',8)
    
    if df_over_f==1
        ylabel('DF/F peak','FontSize',8)
    else
        ylabel('F amplitude','FontSize',8)
    end
    set(gca,'FontSize',8);
    box off

    %Plot observed vs expected EPSP amplitude
    subplot(3,4,7)
    hold on
    h=plot(exp2p,ucycles(3,:),'b--o');
    h.LineWidth=1;
    h.Color='b';
    xlabel('Expected EPSP (mV)','FontSize',8)
    ylabel('Observed EPSP (mV)','FontSize',8)
    top=ceil(max(exp2p));
    t=plot(0:1:top,0:1:top);
    t.LineStyle='--';
    t.Color=[0.5 0.5 0.5];
    xlim([0 top])
    set(gca,'FontSize',8);
 
    %Plot calcium
    subplot(3,4,8)
    hold on
    
    h=plot(exp2p, ucycles(4,:),'b--o');
    h.LineWidth=1;
    h.Color='g';
    
    xlabel('Expected EPSP (mV)','FontSize',8)
    top=ceil(max(exp2p));
    
    xlim([0 top])
  
    if df_over_f==1
        ylabel('DF/F peak','FontSize',8)
    else
        ylabel('F amplitude','FontSize',8)
    end
    set(gca,'FontSize',8);
   
    %Average traces
    % Plot observed versus expected stuff
    color = varycolor(size(ucycles,2));
    leg={};
    
    for i=1:size(ucycles,2)
        
        %Plot observed voltage traces
        subplot(3,2,5)
        %Compute index of last point before uncaging
        limit=floor((Uncaging{ucycles(1,i)}.InitialDelay)/(0.05))-1;
        %GEt mean of baseline
        temp=mean(V_recordings{ucycles(1,i)}(1:limit,2));
        hold on
        h=plot((V_recordings{ucycles(1,i)}(:,1)-Uncaging{ucycles(1,i)}.InitialDelay),(V_recordings{ucycles(1,i)}(:,2)-temp));
        h.LineWidth=1;
        h.Color=color(i,:);
        xlabel('Time from onset (ms)')
        ylabel('mV')
        title('Voltage recording')
        xlim([(-20) (80)])
        set(gca,'FontSize',8);
        
        %Legend
        leg{i}=strcat([num2str(ucycles(2,i))]);
        
        if i==size(ucycles,2)
            l=legend(leg);
            l.LineWidth=0.05;
            l.FontSize=5;
        end
        
        %Plot expected voltage traces
        
        subplot(3,2,6)
        hold on
        h=plot(xxx,exp2w(:,i));
        h.LineWidth=1;
        h.Color=color(i,:);
        xlabel('Time from onset (ms)')
        ylabel('mV')
        title('Expected voltage')
        xlim([(-20) (80)])
        set(gca,'FontSize',8);
        
        %Legend
        leg2{i}=num2str(ucycles(2,i));
        if i==size(ucycles,2)
            l=legend(leg2);
            l.LineWidth=0.05;
            l.FontSize=5;
        end
        
    end
    
    clear exp2w
    %Add arrows indicating uncaging times
    subplot(3,2,5)
    x =0;
    y=min(V_recordings{ucycles(1,1)}(:,2))-1;
    str1 = strcat('\uparrow ');%, num2str(j));
    t=text(x,y,str1);
    t.FontSize=14;
    
    subplot(3,2,6)
    x =0;
    y=min(V_recordings{ucycles(1,1)}(:,2))-1;
    str1 = strcat('\uparrow ');%, num2str(j));
    t=text(x,y,str1);
    t.FontSize=14;
    
  
catch
    
end

clearvars xarray travg
%% purification

%regroupe les fluo et voltage recording dans une bonne vieille matrice et
%pas une structure de merde qui casse les couilles
fluo=[]
fluooa=[]
for i=1:length(fluo_recordings)
    try
fluo{i}=fluo_recordings{1,i}(:,3);
    catch
        prompt='ya un truc qui cloche'
        
    end
end
for i=1:length(fluo_recordings)
        minilen{i}=length(fluo{1,i});
        
            
end
 minilen2=cell2mat( minilen);
 for i=1:length(minilen2)
   if minilen2(i)==0  
     minilen2(i)=20005674;
   end
 end
     
MINfluoDUR=min(minilen2)
try
    for i=1:length(fluo_recordings);
       
        if length(fluo{1,1})<2
        
        fluo{1,1}=fluo_recordings{1,11}(:,3)
       
        end
        
        if length(fluo{1,i})<2
            ARG=1;
            fluo{1,i}=fluo{1,i-1};
            
        end
            
    fluoo{i}=(fluo{1,i}(1:MINfluoDUR));
    %fluooa{i}=fluoo{i}(1:length(fluo_recordings{1,1})-10);
    indexcycleS{i}=i;
    end
catch
end
fluoob=cell2mat(fluoo);
indexcycles=cell2mat(indexcycleS);
indexcycles=[0 indexcycles];
 
% attention ca prend la timeline du premier cycle, si cest un cycle sans calcium beeee cest la merde ...
% ca bugge pas assez souvent pour que ca vaille la peine de le corriger 
try
Tfluo = fluo_recordings{1,1}(1:MINfluoDUR,1);
catch
    Tfluo = fluo_recordings{1,9}(1:MINfluoDUR,1);
end
%Tfluo=Tfluo(1:length(fluo_recordings{1,1})-10);
allFluo=[Tfluo fluoob];
allFluoI=[indexcycles; allFluo];
ARG=0;
volt=[]
for i=1:length(V_recordings)
    try
volt{i}=V_recordings{1,i}(:,2);
    catch
    end
end

    for i=1:length(V_recordings)
   
    volto{i}=(volt{1,i});
    %if length(volto{1,i})>25000
        %volto{1,i}=[]
        
        %penser a faireune correction au casou le voltage recording soit
        %plus petit que 10000 quand ca bugge sur prairie
        try 
            voldo{i}=volto{i}(1:10000);
        catch
            voldo{i}=[1:10000]'
        end
    end

voldoo=cell2mat(voldo);
Tvolt = V_recordings{1,1}(:,1);
Tvolt = Tvolt(1:10000);
allVolt = [Tvolt voldoo];

clearvars fluo fluooa fluoob MINfluoDUR minilen2
%wantedcycles=ucycles(1,:);
%legendtest=unique(ucycles(2,:));
%%
 Goodcycles = input('Enter the cycles you dream about')
 %un+1 aux cycles a cause de la time scale qui utilise la premiere colonne
 Goodcycles =Goodcycles + 1;
 %on garde que les bons cycles dans la variable Good Volt et Fluo
GoodVolt=allVolt(:,Goodcycles);
aGoodVolt=[Tvolt GoodVolt];
GoodFluo=allFluo(:,Goodcycles);
aGoodFluo=[Tfluo GoodFluo];

temp=[ucycles(2:6,:);exp2p;exp2a];
    un=unique(temp(1,:));
    
GandF=temp';

clearvars allFluo allVolt GoodVolt GoodFluo voldoo voldo TFluo TVolt volt volto 

%on remet Goodcycles bien, pasque ca fait chier
Goodcycles=Goodcycles-1;
%%  cycle number Vs inputs number
%attention au cas ou on vire des cycles depuis letape du code de lou,
%mettre les donnees dans lordre ne suffit pas car 
i=1
for i=1:length(Goodcycles)
Goodinputscycleorder{i}=Uncaging{1,Goodcycles(i)}.nPoints;
end
%useless just here to keep the computer warm
% Rwanted=ucycles(1:2,:);
% RwanteT=Rwanted';
% Rwanted2=sortrows(RwanteT,1);
% RwanteT2=Rwanted2';
% Rwan=Rwanted(Goodcycles);
% Rwan=[NaN Rwan];

clearvars Uncaging
%%
%on aligne et calcule gain et on le place en dernieres colonnes
aliGG = input('Cest quand quil arrive le calcium ? mmmm ? alors ??? si ya pas de calcium balance zero, tranquille ')
ali= GandF(:,1)-aliGG;
GandF=[ali GandF];
Gain = GandF(:,3)./GandF(:,7);
GainArea = GandF(:,5)./GandF(:,8);
GandF=[GandF Gain GainArea];
%%
%on va virer les pas Goodcycles du tableau de resultats
%tout un bordel de transpose a cause du sortsrow qui range par row et pas
%colonnes et il doit rester des operations inutiles dans le tas et on
%enleve le +1 aux goodcycles pasque ya pas de timeline sur le tableau de
%result
YOUcycle=ucycles(1,:);
YOUcycle=YOUcycle';
GandF=[GandF YOUcycle];
Goodcycles=Goodcycles;
Gaf=GandF';
GFa= sortrows(GandF,11);
bGoodplot=GFa';
aGoodplot=bGoodplot(:,Goodcycles);
aGoodplot=aGoodplot';
%on remet goodplot dans lordre, mieux pour plotter dans prism direct et une
%petite legende aussi
aGoodplot=sortrows(aGoodplot,2);
bli={'aligned inputs#' 'inputs#' 'EPSP amplitude', 'DF-F', 'EPSP Area', 'DF-F Area', 'Expected EPSP Amplitude', 'Expected EPSP Area', 'GAIN amplitude', 'GAIN Area', 'corresponding cycles'} ;
tocopy=num2cell (aGoodplot);
aGoodplotleg=vertcat(bli,tocopy);

clear bGoodplot GandF Gaf Gain GainArea ali
%% calculate derivative
% dvdt =[]
% for i=1:9999
%     for j=1:length(aGoodVolt(1,:))-1
%     dvdt{i,j}=aGoodVolt(i+1,j)-aGoodVolt(i,j);
%     end
clear SmthVolt
clear SmthVolt2
for j=2:length(aGoodVolt(1,2:end))+1
for i=1:length(aGoodVolt)-(512+1)
        MvAv=mean(aGoodVolt(i:i+512,j));
        SmthVolt{i,j}=MvAv;  
end  
end
SmthVolt2=cell2mat(SmthVolt);
DVDT=diff(SmthVolt2);


%% calculate max gain and max calcium to describe the branch in two numbers
MaxGain=max(aGoodplot(:,9));
MaxDF=max(aGoodplot(:,4));
%%
%generation of matrix to align all experiemnts
%i index du nombre de spines
%j pour parcourir les lignes de agoodplot 
%  aliSPACE=linspace(-60,60 ,121);
%  aliSPACE=aliSPACE';
 clear aliMAT
 aliMAT={}
 for jj=1:length (aGoodplot(:,1))
     for i=1:max(aGoodplot(:,2)) 
 
     if aGoodplot(jj,2)==i
         aliMAT{i,1}=aGoodplot(jj,4);
         aliMAT{i,2}=aGoodplot(jj,9);
         aliMAT{i,3}=i;
         aliMAT{i,4}=aliMAT{i,3}-aliGG;
         
     end
     end
 end
 %%
 %creation dune matrice vide pour caler avec aliMAT pour rentrer dans allXPmat
 %finding nemo
 ABC=cell2mat(aliMAT);
 miniali=min(ABC(:,3));
 AB=nan(61-aliGG,4)
 maxinput=max(ABC(:,3));
 ab=nan(maxinput-1,4);
 %change aliMat pour mettre des nan a la place des empty
 aliMATsave=aliMAT

 ix=cellfun(@isempty,aliMAT);
     aliMAT(ix)={nan}; 
     disp(aliMAT);
     aliMATa=cell2mat(aliMAT);
aliMat2=[AB; aliMATa];
aliMat2=[aliMat2; ab];
%check here probleme longueyr aliMat2
aliMat2=aliMat2(1:end,:);
legALI={'DF-F' 'Gain' 'Total input' 'Aligned Inputs'};
cellALI=num2cell(aliMat2);
cellALI=[legALI; cellALI];

clearvars ab AB ABC miniali 


Alignedplot=figure('Name',strcat('Aligned to Calcium treshold at:',num2str(aliGG), ' inputs'));
Alignedplot.Position=[2801           1         559         479];
whitebg([1 1 1])
hold on
subplot(2,1,1)
scatter(aliMat2(:,4),aliMat2(:,1),130,'g','filled')
xlabel 'aligned inputs #'
legend('DF-F','Location','best')
ylabel 'DF-F'
hold on
plot(-20:1:10,ones(1,31)/2,'g-')

subplot(2,1,2)
hold on
scatter(aliMat2(:,4),aliMat2(:,2),130,'b','filled')
legend('Gain','Location','best')
plot(-20:1:10,ones(1,31),'b-')


xlabel 'aligned inputs #'
ylabel 'Gain'
%%
%creation dun truc que jaurais du faire des le debut, simple matrice de
%nbrinput vs cycles

INvsCY=[GFa(:,2) GFa(:,11)];
INvsCY=INvsCY';

 PtsGrp=INvsCY(1,[Goodcycles]);
figure;
aGoodExp=expwave(:,INvsCY(1,[Goodcycles]));
 plot(xxx,aGoodExp);
 aGoodExp=[xxx' aGoodExp];


%% Transformer les matrices de travail en structure avec legendes facilement collables dans Prism
Goodinputscycleorderm=cell2mat(Goodinputscycleorder)
Inputs=[NaN Goodinputscycleorderm]
zVolt=[Inputs; aGoodVolt]
%attention pour expected estceque cest dans lordre des inputs cycles ou par
%ordre croissant dinputs hein ?? he ouais mon gars, bon en fait on dirait
%que ca va, fuck faut pas se poser trop de questions non plus
zExp=[Inputs; aGoodExp]
zFluo=[Inputs; aGoodFluo]
%on va faire la meme chose avec les Downsampled pasque bon cest celles la
%quon va plotter a la fin
try
zipVolt=[Inputs; aGoodVoltdwsp];
zipFluo=[Inputs; aGoodFluodwsp];
zipExp=[Inputs; aGoodExpdwsp];
smthVolt=[Inputs; aGoodVoltSmth];
smthFluo=[Inputs; aGoodFluoSmth];
smthExp=[Inputs; aGoodFluoSmth];
catch
end

%% hey analyse des units un peu differente

%on va couper la trace en bouts qui se superposent de 150ms
%parametres a mettre en variables

%initial delay ID
%interpointdelay IPD
%taille baseline BL
%taille du smooth SW
%delay de mimicuncaging UD
%ca serait superbe de les mettre avec des curseurs et davoir un plot
%auto-updated

% 
% %on va commencer par demander a l'user
% fligg=1
% while fligg==1
% switche=input('/1 Vieux parametres (ID=100ms IPD=100ms) /2 nouveaux (ID=50ms IPD=200ms) ')
% if switche~=1 && switche~=2
%     display ('Mais tes vraiment trop con ma parole...')
%     switche=input('/1 Vieux parametres (ID=100ms IPD=100ms) /2 nouveaux (ID=50ms IPD=200ms) ')
% end
% %clear P
%     P={}
% if switche==1   
% 
% for j=[ucycles2]
%     for h=1:points
%         i=(h-1)*2000;
%        try 
%       P{j,h}=V_recordings{1,j}(1001+i:4001+i,2);
%        catch
%         display('probleme avec le dernier point, pas assez de temps mou')
%         
%        P{j,h}=P{j,h-1}
%     end
% end
% end
% end
% 
% if switche==2
%    for j=[ucycles2]
%     for h=1:points
%         i=(h-1)*4000;
%       P{j,h}=V_recordings{1,j}(1+i:5001+i,2);
%     end
% end
% end
% 
% %% on cree un matrice de 3 dimensions, time, cycle et point
% clear Ph
% for pts=1:points
% for cy=[ucycles2]
% Ph(:,cy,pts)=P{cy,pts};
% end
% end
% %on vire les zeros
% aPhi=Ph(:,ucycles2,:);
% %on prend la moyenne dans la dimension des cycles
% Aver=mean(aPhi,2);
% 
% 
% Aver2=mean(Aver,3);
% 
% %% average de tous les points pour voir la difference entre les cycles
% AveragePts=mean(aPhi,3);
% Funits=figure('Color',[0.8 0.8 0.4],'Name', 'Mateo units');
% Funits.Position=[2698         565         560         820]
% 
% subplot(3,2,1)
% 
% plot(AveragePts)
% title('differents cycles all inputs')
% xlabel 'Time (sampling)'
% ylabel 'mV'
% % average de tous les cycles pour voir la diff de points
% AverageCy=mean(aPhi,2);
% subplot(3,2,2)
% plot(AverageCy(:,:))
% title('differents points all cycles')
% xlabel 'Time (sampling)'
% ylabel 'mV'
% 
% %voyons en prenant differents maximum pour laverage de toutes les units
% Max1=max(AveragePts);
% baseline1=mean(AveragePts(1:950,:));
% Ampli1=baseline1-Max1;
% MeanUnits1=mean(Ampli1);
% %
% Max2=max(AverageCy(:,:));
% baseline2=mean(AverageCy(1:950,:));
% Ampli2=baseline2-Max2;
% MeanUnits2=mean(Ampli2);
% 
% subplot(3,2,3)
% histogram(Ampli1,length(Ampli1))
% title('average units between cycles')
% xlabel 'mV'
% ylabel '#'
% 
% subplot(3,2,4)
% histogram(Ampli2,length(Ampli2))
% title('average unit between synaptic input')
% xlabel 'mV'
% ylabel '#'
% 
% Ampli2(1,1)
% 
% subplot(3,2,5)
% 
% plot (Aver2)
% %AAR=mean(AveragePts,2)-Aver2;
% xlim([800, 3000])
% title(['Mean unit size' num2str(MeanUnits2)])
% xlabel 'Time (Sampling units)'
% ylabel 'mV'
% 
% subplot(3,2,6)
% 
% plot(mean(AveragePts,2))
% xlim([800, 3000])
% title(['Mean unit size' num2str(MeanUnits1)])
% xlabel 'Time (Sampling units)'
% ylabel 'mV'
% 
% clearvars Aver2 Aver aPhi Ph AveragePts P
% %%
% 
% Funits0=figure('Color',[0.8 0.8 0.6],'position',[3400 300 500 500]);
% title 'Mateo units'
% hold on
% subplot(2,2,1)
% pl1=plot (Ampli2,'o')
% title 'individual units amplitude'
% set(pl1,'MarkerEdgeColor','none','MarkerFaceColor','b')
% subplot(2,2,2)
% histogram (abs(Ampli2))
% title 'distribution of units size'
% %bon les expected maintenant, disons pour 10 15 20 25
% %dabord dune facon con en sommant le max de chaque input
% Sum10a=sum(Ampli2(1:10));
% %ensuite en faisant la moyenne des traces puis prendre le max de celle la
% %averagecy me fait chier a cause de sa troisieme dimension
% AverageCy2=AverageCy(:,:);
% 
% subplot(2,2,4)
% plot(AverageCy2)
% title 'all units'
% %Mean10=mean(AverageCy2([1:10],2));
% 
% avy=AverageCy2;
% clearvars AverageCy2 AverageCy
% %avy10=avy(:,1:10);
% %ave10avy=mean(avy10,2);
% %subplot(2,2,3)
% %plot(ave10avy)
% %title 'average unit'
% %%
% for i=1:points
% avywanted{i}=avy(:,1:i); 
% end
% 
% %creation de la trace somme pour tous
% BAseline=[]
% aPeak=[]
% 
% for i=1:points
%     aSuMexp{i}=sum(avywanted{1,i},2);
%     BAseline(i)=mean(aSuMexp{1,i}(1:950));
%     aPeak(i)=max(aSuMexp{1,i});
%     
% end
% 
% %BAseline=cell2mat(BAseline)
% %aPeak=cell2mat(aPeak)
% aAmpli=BAseline-aPeak;
% aRB=BAseline/BAseline(1);
% 
% aDB=BAseline-BAseline(1);
% aSumXP=cell2mat(aSuMexp);
% 
% %test de retirer la diff de baseline juste
% aDB=BAseline-BAseline(1);
% 
% for i=1:points
%     
% aSumXPR(:,i)=aSumXP(:,i)-aDB(1,i);
% end
% %figure;
% %plot(aSumXPR)
% %figure;
%  %plot(aSumXPR(:,Goodinputscycleorderm))   
% %test peak si pareil que lautre
% % Aeee=max(aSumXPR);
% % AeB=mean(aSumXPR(1:950,:)); 
% % AE=AeB-Aeee; 
% %ok c bon
% 
% %  Expp=max(aSumXPR(:,Goodinputscycleorderm));
% %  Expb=mean(aSumXPR(1:950,Goodinputscycleorderm));
% %  Exp4=Expb-Expp;
% clearvars aSumXP aDB BAseline aPeak aAmpli aRB
%  
% for i=ucycles2
%  ptaa(:,i)=V_recordings{1,i}(:,2);
% end
% ptaa2=ptaa(:,ucycles2);
% AverageIndividualTrace=mean(ptaa2,2);
% 
% AVindTrace=figure('Name', 'All units cycles together')
% plot(AverageIndividualTrace)
% 
% clearvars Expp AverageIndividualTrace ptaa ptaa2
% %% voyons comment ajjuster le decalage de la somme
% flog=1
% while flog==1
%     flog=input('alors, pour le decalage push ONE pour continuer')
% UD=input('decalage, 7=0,3ms')
% 
% %il faut repartir de avywanted
% %facile grace a delayseq,
% clear aDelay
% clear aOD
% clear aSuMDelay
% clear aSuMDelayR
% clear BAselineD
% aSumD=avywanted;
% 
% 
% for j=1:points
% for i=1:j
%     aOD(:,i,j)=delayseq(aSumD{1,j}(:,i),UD*i);
% end
% end
% 
% %comme ca pas bien faut couper au plus grand decalage de tous a maxpoints
% %nice ca marche pour un example maintenant faut supplementer
% 
% %encore une fois la 3d aOD est en(:,:,nombres de points)
% %A4=aOD(:,:,5);
% %on cut au maxdelay
% 
% %A5=aOD(UD*points+1:end,:,5);
% %variable aDelay regroupe les units decalees pretes a etre sommees et avec
% %le debut de la trace coupee pour pas avoir de vilains zeros
% aDelay=aOD(UD*points+1:end,:,:);
% 
% %A26=aDelay(:,:,3);
% 
% %figure
% %plot(A26)
% %ylim([(-68) (-65)])
% 
% % for i=1:points
% %    A8=sum(aDelay,2);
% % end
% % A9=A8(:,:);
% 
% 
% % Good way of summing
% for i=1:points
%     aSuMDelay(:,i)=sum(aDelay(:,:,i),2);
%        BAselineD(i)=mean(aSuMDelay(1:950,i));
%      aPeakD(i)=max(aSuMDelay(:,i));
% end
% 
% aAmpliD=BAselineD-aPeakD;
% 
% %
% 
% for i=1:points
% aSuMDelayR(:,i)=aSuMDelay(:,i)-BAselineD(1,i);
% end
% 
% %plot la comparaison entre avec et sans delay
% figure('Name','Comparaison Avec Sans Delai');
% deldel=subplot(2,2,4)
% plot(aSuMDelayR)
% title 'Expected with Delay all'
% subplot(2,2,1)
% plot(aSumXPR(:,Goodinputscycleorderm))   
% title 'Expected without Delay'
% subplot(2,2,3)
% plot(aSumXPR)
% title 'Expected without Delay all'
% subplot(2,2,2)
% plot(aSuMDelayR(:,Goodinputscycleorderm))
% title 'Expected with Delay'
% 
% %saveas(deldel,'subplotte','jpg')
% XPexpLou=[Inputs; aGoodExp];
% 
% aGoodExpM=aSuMDelayR(:,aGoodplot(:,2));
% 
% Tvoltexp=Tvolt(1:size(aGoodExpM));
% aGoodExpMleg=[Tvoltexp aGoodExpM];
% XPexpMateo=[Inputs; aGoodExpMleg];  
% 
% figure('Name','comparaison expected');
% hold on
% plot (XPexpMateo(:,1),XPexpMateo(:,2:end), 'r')
% plot (XPexpLou(:,1),XPexpLou(:,2:end), 'b')
% title ('comparaison expected')
% 
% 
% xlswrite('Expected M4',XPexpMateo)
% end
% %petit ajout pour le calcul du gain de isi
% 
% 
% 
% %mettons des legendes aux fluo traces et measured epsp, jarrive pas a mettre un string dans ce bordel donc: 0='time' et si t pas content cest pareil 
% 
% XPfluo=[Inputs; aGoodFluo];
% XPvolt=[Inputs; aGoodVolt];
% XPexpLou=[Inputs; aGoodExp];
% 
% aGoodExpM=aSuMDelayR(:,aGoodplot(:,2));
% 
% Tvoltexp=Tvolt(1:size(aGoodExpM));
% aGoodExpMleg=[Tvoltexp aGoodExpM];
% XPexpMateo=[Inputs; aGoodExpMleg];   
% 
% figure('Name','comparaison expected');
% hold on
% plot (XPexpMateo(:,1),XPexpMateo(:,2:end), 'r')
% plot (XPexpLou(:,1),XPexpLou(:,2:end), 'b')
% title ('comparaison expected')
% 
% %encore un truc pour esssayer de faire le gain des tsp
% xlswrite('Expected M2',XPexpMateo)
% 
% 
% 
% clear aSuMDelayR 
% %lets do a plot for my expected (that are obviously more acurate than the
% %ones of the crazy quebequois)
% MaxExp=max(aGoodExpM);
% MaxExp=MaxExp';
% 
% %% finalisation de aGoodplot et transformation en cell avec legende: aGoodplotlegend
% aGoodplot1=[aGoodplot MaxExp];
% GainMateo=aGoodplot1(:,3)./MaxExp;
% aGoodplot2=[aGoodplot1 GainMateo];
% aGoodplotcell=num2cell(aGoodplot2);
% resultlegend={'aligned inputs' 'inputs' 'measured EPSP Ampl' 'DF/F' 'measured EPSP Area' 'expected EPSP Area' 'expected EPSP Ampl Lou' 'expected EPSP Area Lou' 'Gain Area' 'Gain Amplitude' 'Corresponding Cycle' 'expected EPSP Ampl Mateo' 'Gain Mateo(aMplitude)'};
% 
% aGoodplotlegend=[resultlegend; aGoodplotcell];
% 
% clearvars aGoodplotleg aGoodplotcell  aGoodplot1 
% clearvars aGoodExpM
% %calcul des units moyennes avec mon programme
% 
% %% transformer a goodvolt en epsp, tout remis a zero enfonction de sa propre
% %%baseline (cache un peu les chg de voltage au cours de la manip
% baS=mean(aGoodVolt(1:1999,2:end));
% if switche==2
%     baS=mean(aGoodVolt(1:999,2:end));
% end
% clear aGoodVoltbase
% for i=1:length(aGoodVolt)
%     for j=2:length(aGoodVolt(1,:))
%     aGoodVoltbase(i,j)=aGoodVolt(i,j)-baS(j-1);
% end
% end
% 
% aGoodVoltbase=[aGoodVolt(:,1) aGoodVoltbase];
% XPvoltbase=aGoodVoltbase;
% 
% %% Smooffage
% clear aGoodFluoSmth
% clear SmthFluo
% smoo=1
% while smoo==1
% smoo=input('Tu veux smouffer ?? hesite pas cest gratuit ONE-pour oui')
% if smoo==1
% %smth voltage recording traces
% av1=input('taille MvAv pour recorded voltage traces')
% for j=2:length(aGoodVolt(1,2:end))+1
% for i=1:length(aGoodVolt)-(av1+1)
%         MvAv=mean(aGoodVolt(i:i+av1,j));
%         SmthVolt{i,j}=MvAv;  
% end  
% end
% 
% dvdt =[]
% for i=1:8999
%     for j=1:length(aGoodVolt(1,:))-1
%     dvdt{i,j}=SmthVolt{i+1,j}-SmthVolt{i,j};
%     end
% end
% dvdt1=cell2mat(dvdt);
% figure('Name','DVDT');
% p4=get(gcf,'Position');
% hold on
% for k=1:length(dvdt1(1,:))
% plot (aGoodVolt(500:3500,1),dvdt1(500:3500,k))
% end
% title ('dvdt')
% 
% aGoodVoltSmth=cell2mat(SmthVolt);
% aGoodVoltSmth=[aGoodVolt(1:length(aGoodVoltSmth),1) aGoodVoltSmth];
% figure('Name','smth EPSPS','Position',p4+[0 -60 0 0]);
% p4=p4+[0 -60 0 0];
% plot (aGoodVoltSmth(:,1),aGoodVoltSmth(:,2:end))
% title ('smth epsp')
% %smth fluo recording traces
% av2=input('taille MvAv pour recorded fluo traces')
% for j=2:length(aGoodFluo(1,2:end))+1
% for i=1:length(aGoodFluo)-(av2+1)
%         MvAv=mean(aGoodFluo(i:i+av2,j));
%         SmthFluo{i,j}=MvAv;       
% end
% end  
% aGoodFluoSmth=cell2mat(SmthFluo);
% aGoodFluoSmth=[aGoodFluo(1:length(aGoodFluoSmth),1) aGoodFluoSmth];
% figure('Name','smth DF','Position',p4+[0 -60 0 0]);
% p4=p4+[0 -60 0 0];
% plot (aGoodFluoSmth(:,1),aGoodFluoSmth(:,2:end))
% title ('smth DF')
% %smth expected traces
% av3=input('taille MvAv pour expected voltage traces')
% try
% for j=INvsCY(1,Goodcycles)
% for i=1:length(expwave)-(av3+1)
%         MvAv=mean(expwave(i:i+av3,j));
%         SmthExp{i,j}=MvAv;       
% end  
% end
% catch
% end
% av4=input('taille MvAv pour expected voltage traces Mateo')
% SmthExpMateo={}
% for j=1:length(XPexpMateo(1,:))-1
% for i=1:length(XPexpMateo(:,1))-(av4+1)
%         MvAv=mean(XPexpMateo(i:i+av4,j+1));
%         SmthExpMateo1{i,j}=MvAv;       
% end  
% end
% 
% SmthExpMateo=cell2mat(SmthExpMateo1)
% 
% % for j=1:length(XPexpMateo(1,:))-1
% % SmthExpMateo(:,:)=smooth(XPexpMateo(:,:),av4);
% % end
% figure('Name','smth expected Mateo','Position',p4+[0 -60 0 0]);
% p4=p4+[0 -60 0 0]
% plot(SmthExpMateo)
% title ('smth expected Mateo')
% 
% 
% aGoodExpSmth=cell2mat(SmthExp);
% %creer une ligne de temps pour les exp
% TimeExp=xxx'+20.04;
% %et la caler
% aGoodExpSmth=[TimeExp(1:length(aGoodExpSmth)) aGoodExpSmth];
% figure('Name','smth expected Lou','Position',p4+[0 -60 0 0]);
% p4=p4+[0 -60 0 0];
% title 'smth expected Lou';
% plot (aGoodExpSmth(:,1),aGoodExpSmth(:,2:end))
% 
% end
% clearvars expwave xxx;
% clearvars avywanted;
% end
%  %% downsampling
%  dwsp=1
%  while dwsp==1
%  dwsp=input('Tu veux downsampling ?? hesite pas cest gratuit ONE-pour oui')
%  if dwsp==1
%   dwspN1=input('De combien tu veux downsampler les traces de voltages??')
%   try 
%       aGoodVoltdwsp=downsample(aGoodVoltSmth,dwspN1);
%   catch
%       aGoodVoltdwsp=downsample(aGoodVolt,dwspN1);
%   end
%   figure;
%   plot(aGoodVoltdwsp(:,1),aGoodVoltdwsp(:,2:end))
% dwspN2=input('De combien tu veux downsampler les traces de voltages expected??') 
%  try 
%       aGoodExpdwsp=downsample(aGoodExpSmth,dwspN2);
%   catch
%       aGoodExpdwsp=downsample(aGoodExp,dwspN2);
%   end
%   figure;
%   plot(aGoodExpdwsp(:,1),aGoodExpdwsp(:,2:end))
%  dwspN3=input('De combien tu veux downsampler les traces de Fluo??') 
%  try 
%       aGoodFluodwsp=downsample(aGoodFluoSmth,dwspN3);
%   catch
%       aGoodFluodwsp=downsample(aGoodFluo,dwspN3);
%   end
%   figure;
%   plot(aGoodFluodwsp(:,1),aGoodFluodwsp(:,2:end))
% end
% end
% %% Plot les aligned avec mon Gain
% 
% %aliSPACE=linspace(-60,60 ,121);
%  %aliSPACE=aliSPACE';
%  clear aliMAT;
%  aliMAT={};
%  for jj=1:length (aGoodplot2(:,1));
%      for i=1:max(aGoodplot2(:,2)); 
%  
%      if aGoodplot2(jj,2)==i
%          aliMAT{i,1}=aGoodplot2(jj,4);
%          aliMAT{i,2}=aGoodplot2(jj,9);
%          aliMAT{i,3}=i;
%          aliMAT{i,4}=aliMAT{i,3}-aliGG;
%          aliMAT{i,5}=aGoodplot2(jj,13);
%      end
%      end
%  end
%  
%  Li=length(aliMAT)
%  rempl1=cell(50,5)
%  rempl2=cell(50-Li,5)
%  aliMat2=[rempl1;aliMAT;rempl2]
%  Li2=length(aliMat2)
%  
%  ix=cellfun(@isempty,aliMat2);
%      aliMat2(ix)={nan}; 
%  
%% DATE
Ccc = strsplit(dirName,{'-'});
sprintf('%c',Ccc{1,2});

y=num2str(Ccc{1,2});
mois=str2num(y(1:2));
jour=str2num(y(3:4));
annee=str2num(y(5:8));
DateVector=[annee mois jour 0 0 0];
Date=datestr(DateVector);

%%
% legALI2={Date Ccc{1,4} Date Ccc{1,4} Date };
% legALI={'DF-F' 'Gain' 'Total input' 'Aligned Inputs' 'Gain Mateo'};
% %celALI=num2cell(aliMat2);
% %cellALI=[legALI2;legALI; celALI];
% 
% inpouts=aliMat2(:,3:4);
% Gali=[inpouts aliMat2(:,2) aliMat2(:,5)];
% GaliM=[inpouts aliMat2(:,5)];
% GaliL=[inpouts aliMat2(:,2)];
% Dali=[inpouts aliMat2(:,1)];
% 
% 
% %celALIo=num2cell(aliMat2)
% %cellALIo=[legALI2;legALI; celALI]
% 
% inpoutso=aliMat2(:,3:4);
% Galio=[inpouts aliMat2(:,2) aliMat2(:,5)];
% GaliMo=[inpouts aliMat2(:,5)];
% GaliLo=[inpouts aliMat2(:,2)];
% Dalio=[inpouts aliMat2(:,1)];
% 
% legGALIM={Ccc{1,1} Date Ccc{1,4};'Total input' 'Aligned Inputs' 'Gain Mateo'};
% legGALIL={Ccc{1,1} Date Ccc{1,4};'Total input' 'Aligned Inputs' 'Gain Lou'};
% legDALI={Ccc{1,1} Date Ccc{1,4};'Total input' 'Aligned Inputs' 'DF-F'};
% legGALI={Ccc{1,1} Ccc{1,2} Date Ccc{1,4};'Total input' 'Aligned Inputs' 'Gain Lou' 'Gain Mateo'};
% 
% %XPGaliM1=num2cell(GaliM);
% %XPGali1=mat2cell(Gali,1);
% %XPGali1=num2cell(Gali,[100 5]);
% %XPGali2=cell2num(XPGali1);
% 
% %XPGaliL1=num2cell(GaliL);
% %XPDali1=num2cell(Dali);
% 
% XPGaliM=[legGALIM; GaliM];
% XPGali=[legGALI; Gali];
% XPGaliL=[legGALIL; GaliL];
% XPDali=[legDALI; Dali];
% 
% %repeAT DES COMMANDES DAPRES
% legallALI={Ccc{1,1} Ccc{1,2} Date Ccc{1,4} 'XX';'DF-F' 'Gain Lou' 'Total input' 'Aligned Inputs' 'Gain Mateo'};
% %aliMat22=num2cell(aliMat2)bad command dont
% XPalicell=[legallALI; aliMat2];
% 
% 
% %coupe XPali pour que le gain et dans un ordre interessant avec juste les
% %input aligned en prems
% AliGainXP=aliMat2(:,[4 5 2]) 
% %pareil avec la cellule mais on va surement PAS sen servir par la suite
% AliGainXPcell=XPalicell(:,[4 5 2]) 
% AliGainXPcellnoLEG=XPalicell(3:end,[4 5 2]) 
% AliG1=[cell(aliGG,3);AliGainXPcellnoLEG]
% AliG2=[AliG1;cell(100-aliGG,3)]
% 
% AliG3=XPalicell(3:end,[4 5 2])
% AliG4=[cell(100-aliGG,3);AliG3;cell(aliGG,3)]
% 
% %on rajjoute le bon nombre de case vides pour que tout le monde soit aligne
% %sur larrive du calcium Le but etant davoir le CA threshold qui arrive en
% %100eme ligne
% AliFluoXPcellnoLEG=XPalicell(3:end,[4 1])
% AliF1=[cell(aliGG,2);AliFluoXPcellnoLEG]
% AliF2=[AliF1;cell(100-aliGG,2)]
% 
% AliF3=[cell(100-aliGG,2);AliFluoXPcellnoLEG]
% AliF4=[AliF3;cell(aliGG,2)]
% 
% 
% %AliGainXPAli=[NaN(aliGG,3);AliGainXP]
% %AliGainXPcellAli=[cell(aliGG,3);AliGainXPcell]
% %il va falloir maintenant sassurer de remplir la fin des colonnes par des
% %cases vides pour que toutes les matrices de tipe AliXXXAli soient de meme
% %taille entre toutes les experiences
% %AliGainXPAli2=[AliGainXPAli;NaN(100-aliGG,3)]
% %AliGainXPcellAli2=[AliGainXPcellAli;cell(100-aliGG,3)]
% %Exactement pareil avec la fluo
% %AliFluoXP=XPali(:,[4 1]) 
% %AliFluoXPcell=XPalicell(:,[4 1]) 
% 
% %AliFluoXPAli=[NaN(aliGG,2);AliFluoXP]
% %AliFluoXPcellAli=[cell(aliGG,2);AliFluoXPcell]
% %AliFluoXPAli2=[AliFluoXPAli;NaN(100-aliGG,2)]
% %AliFluoXPcellAli2=[AliFluoXPcellAli;cell(100-aliGG,2)]
% %nice name xp
% niceNameXP=strcat(Date,'-','L',Ccc{1,4})
% legFluoAli=strcat(niceNameXP,'Fluo ')
% %nice name xp number
% niceNameXPxl=[str2num(Ccc{1,2});str2num(Ccc{1,4})]
% 
% 
% legendALIG={niceNameXP niceNameXP niceNameXP;'Aligned Inputs' 'Mateo' 'Lou'}
% AliG5=[legendALIG;AliG4]
% %AliG6=AliG5(:,[2 3])
% clearvars AliG3 AliG1 AliG2 AliG4 AliGainXPcellnoLEG
% % AliFluoXPAli3=AliFluoXPAli2(:,2)
% % AliFluoXPAli4=num2cell(AliFluoXPAli3)
% % AliFluoXPAlilegendado=[niceNameXPxl;AliFluoXPAli3]
% % 
% % AliGainXPAli3=AliGainXPAli2(:,[2 3])
% % AliGainXPAli4=num2cell(AliGainXPAli3)
% % AliGainXPAlilegendado=[niceNameXPxl';AliGainXPAli3]
% %AliGainXPAlilegendadoCELL=[{niceNameXP 'Gain L'}; AliGainXPAli4]
% %oioi={Date  Ccc{1,4}}
% %oaoa={'Gain M' 'Gain L'}
% %AliGainXPAlilegendadoCELL=[oioi; oaoa ;AliGainXPAli4]
% 
% %WgainCaAlimat=AliGainXPAlilegendado
% %ZgainCaAli=AliGainXPAlilegendadoCELL
% 
% ZgainInAli=XPGali(:,[3 4])
% inAliG=XPGali(:,[3 4])
% %WgainInAlicell=XPGali(:,[4 3])
% 
% hioa={Date; Ccc{1,4}}
% hiof={Date Ccc{1,4}}
% %ZfluoCaAli=[hioa; AliFluoXPAli4]
% 
% ZfluoInAli=[hioa;XPDali(3:end,3)]
% inAliF=[hioa;XPDali(3:end,3)]
% 
% legAliF2={niceNameXP niceNameXP ;'Aligned inputs' 'Fluo'}
% AliFIN=[legAliF2;XPDali(3:end,[1 3])]
% %ZallGainCa=linspace(-101,100,202)'
% %ZallGainCa=num2cell(ZallGainCa)
% %ZallGainCa=[ZallGainCa ZgainCaAli]
% 
% %ZallGainIn=linspace(-51,50,102)'
% %ZallGainIn=num2cell(ZallGainIn)
% %ZallGainIn=[ZallGainIn ZgainInAli]
% 
% %%load 'GAIN Aligned to Ca++'
% 
% %load 'FLUO Aligned to Inputs'
% %load 'FLUO Aligned to Ca++'
% %ZallFluoCa=linspace(-101,100,202)'
% %ZallFluoCa=num2cell(ZallFluoCa)
% %ZallFluoCa=[ZallFluoCa ZfluoCaAli]
% 
% %ZallFluoIn=linspace(-51,50,102)'
% %ZallFluoIn=num2cell(ZallFluoIn)
% %ZallFluoIn=[ZallFluoIn ZfluoInAli]
% 
% % size(awwa)
% % size(AliFIN)
% % 
% % 
% % %AllFIN=cell(102,1)
% % save('AllFIN','AllFIN')
% % %AllFCA=linspace(-151,50,202)'
% % %AllFCAsanity=linspace(-151,50,202)'
% % %AllFCAsanity=num2cell(AllFCAsanity)
% % save('AllFCAsanity','AllFCAsanity')
% % 
% % load AllGCA
% % %AllGCA=linspace(-151,50,202)'
% % %AllGCA=num2cell(AllGCA)
% % 
% % AllGCA=[AllGCA AliG6]
% % 
% % AllGCAsanity=[AllGCAsanity AliG5]
% % save('AllGCA','AllGCA')
% 
% %%
% % error('stop la')
% 
% %%
% 
% %test dun algniement pas malin du tout
% % cd('/Users/mateo/Documents/DATA/Absolute/Updated/Rate')
% % load 'GAIN Aligned to Inputs'
% % load 'GAIN Aligned to Ca++'
% % 
% % load 'FLUO Aligned to Inputs'
% % load 'FLUO Aligned to Ca++'
% % 
% % % linspace(-151,50,202)'
% % % ZallFluoCa=linspace(-101,100,202)'
% % % ZallFluoCa=num2cell(ZallFluoCa)
% % % ZallGainCa=ZallFluoCa
% % % AllFCA=num2cell(linspace(-101,100,202)')
% % % save ('AllFCA','AllFCA')
% % 
% % 
% % 
% % ZallFluoCa=[ZallFluoCa ZfluoCaAli]
% % ZallGainCa=[ZallGainCa ZgainCaAli]
% % 
% % %ZallFluoIn=linspace(-51,50,102)'
% % %ZallFluoIn=num2cell(ZallFluoIn)
% % ZallFluoIn=[ZallFluoIn ZfluoInAli]
% % ZallGainIn=[ZallGainIn ZgainInAli]
% % 
% % 
% % save ('GAIN Aligned to Ca++', 'ZallGainCa')
% % 
% % %save ('GAIN Aligned to Inputs', 'ZallGainIn')
% % 
% % %load 'GAIN Aligned to Inputs'
% % %load 'GAIN Aligned to Ca++'
% % 
% % 
% % save ('FLUO Aligned to Ca++', 'ZallFluoCa')
% % 
% % %save ('FLUO Aligned to Inputs', 'ZallFluoIn')
% 
% 
% %% IMPORTANT ON VA FAIRE 2 matrices differentes UNE alignee sur les total inputs, LAUTRE sur le calcium threshold
% 
% %calcul du resting membrane potential en faisant la moyenne de differentes
% %baselines prises depuis les voltages recordings et les units recordings
% v1=mean(baseline1)
% v2=mean(baseline2)
% v3=mean(baS)
% VmV=[v1 v2 v3]
% Vm=mean(VmV)
% 
% aliMat2=cell2mat(aliMat2)
% 
% Alignedplot=figure('Name',strcat('Aligned to Calcium treshold at:',num2str(aliGG), ' inputs'));
% Alignedplot.Position=[2810           -20         550         550];
% Alignedplot.Color=[0.9 0.4 0];
% hold on
% subplot(3,1,1)
% scatter(aliMat2(:,4),aliMat2(:,1),130,'g','filled')
% xlabel 'Aligned inputs #'
% legend('DF-F','Location','best','boxoff')
% legend('boxoff')
% ylabel 'DF-F'
% hold on
% plot(-20:1:10,ones(1,31)/2,'g-')
% 
% subplot(3,1,2)
% hold on
% scatter(aliMat2(:,4),aliMat2(:,2),130,'b','filled')
% legend('Gain Lou','Location','best')
% legend('boxoff')
% plot(-20:1:10,ones(1,31),'b-')
% xlabel 'Aligned inputs #'
% ylabel 'Gain Lou'
% 
% subplot(3,1,3)
% hold on
% scatter(aliMat2(:,4),aliMat2(:,5),130,'r','filled')
% legend('Gain Mateo','Location','northwest','boxoff')
% legend('boxoff')
% plot(-20:1:10,ones(1,31),'r-')
% xlabel 'Aligned inputs #'
% ylabel 'Gain Mateo'
% 
% 
% %% PLOT TRACES
% %creation dune variable en string pour la legende
% stupidinputs=XPexpMateo(1,2:end);
% for i=1:length(stupidinputs);
% stupidinputs2{i}=num2str(stupidinputs(i));
% end
% 
% Inputstr=num2str(Inputs);
% Inputstr2=strsplit(Inputstr);
% Inputstr3=Inputstr2(2:end);
% 
% TracesF = figure('Name','Beautiful Traces','NumberTitle','off','Color',[0.5 0.5 0.5]);
% colormap winter;
% TracesF.Position=[1440,0,1200,400];
% subplot(1,5,3);
% hold on
% 
% plot(aGoodVoltbase(:,1),aGoodVoltbase(:,3:end));
% xlim([80, 250]);
% if switche==2
%     xlim([30,200]);
% end
% 
% title ('EPSP measured (mV)', 'Color','w')
% xlabel ('time (ms)', 'Color','w')
% ylabel ('EPSP measured (mV)', 'Color','w')
% [~,icons,~,~] = legend(Inputstr3, 'Location', 'NorthEast');
% set(icons,'LineWidth',6);
% subplot(1,5,4);
% hold on
% for hh=1:length (Goodcycles)
% p=plot(aGoodFluo(:,1),aGoodFluo(:,hh+1));
% %p.LineWidth=1
% 
% end
% title ('DF-F', 'Color','w')
% xlabel ('time (ms)', 'Color','w')
% ylabel ('DF-F', 'Color','w')
% [~,icons,~,~] = legend(Inputstr3, 'Location', 'NorthEast');
% set(icons,'LineWidth',6);
% subplot(1,5,1);
% hold on
% 
% %plot((xxx+20)',expwave(:,INvsCY(1,:)))
% plot(aGoodExp(:,1),aGoodExp(:,2:end));
% title ('Lou expected', 'Color','w');
% xlabel ('time (ms)', 'Color','w');
% ylabel ('EPSP expected (mV)', 'Color','w');
% [~,icons,~,~] = legend(Inputstr3, 'Location', 'NorthEast');
% set(icons,'LineWidth',6);
% 
% subplot(1,5,2);
% 
% plot (XPexpMateo(2:end,1),XPexpMateo(2:end,2:end));
% 
% 
% [~,icons,~,~] = legend(Inputstr3, 'Location', 'NorthEast');
% set(icons,'LineWidth',6);
% title ('Mateo Expected', 'Color','w')
% xlabel ('Time (ms)', 'Color','w')
% ylabel ('mV', 'Color','w')
% 
% 
% subplot(1,5,5);
% plot(aGoodVolt(500:3500,1),DVDT(500:3500,1:end));
% [~,icons,~,~] = legend(Inputstr3, 'Location', 'NorthEast');
% set(icons,'LineWidth',6);
% title ('dVdt', 'Color','w')
% xlabel ('Time (ms)', 'Color','w')
% ylabel ('mV/ms', 'Color','w')
% 
% %% PLOTS
% finalF = figure('Name','GAIN and DF-F','NumberTitle','off','Color',[0.6 0.3 0.3]);
% finalF.Position=[1440,400,1200,580];
% 
% subplot(2,3,1);
% hold on
% plot(aGoodplot2(:,2), aGoodplot2(:,4) ,'g-o','MarkerSize', 12,'MarkerFaceColor','g','MarkerEdgeColor','k')
% title('DF vs input#')
% xlabel 'Input #'
% ylabel 'DF-F'
% 
% subplot(2,3,6)
% hold on
% %plot(aGoodplot(:,12), aGoodplot(:,4),'g-o','MarkerSize', 12,'MarkerFaceColor','g','MarkerEdgeColor','r')
% title('DF vs Expected Mateo#')
% xlabel 'Expected EPSPs (mV) #'
% ylabel 'DF-F'
% 
% subplot(2,3,2)
% hold on
% plot(aGoodplot2(:,2), aGoodplot2(:,9),'b-O','MarkerSize', 12,'MarkerFaceColor','auto')
% %axis([10 30 0 3])
% title('Gain vs input#')
% xlabel 'Input #'
% ylabel 'Gain'
% 
% subplot(2,3,2)
% hold on
% plot(aGoodplot2(:,2), aGoodplot2(:,13),'r-O','MarkerSize', 12,'MarkerFaceColor','auto')
% %axis([10 30 0 3])
% title('Gain vs input#')
% xlabel 'Input #'
% ylabel 'Gain'
% legend 'Lou' 'Mateo' 'Location' 'best'
% 
% subplot(2,3,3)
% hold on
% plot(aGoodplot2(:,7), aGoodplot2(:,3) ,'b--O','MarkerSize', 12,'MarkerFaceColor','b')
% plot([0,max(aGoodplot2(:,7))],[0,max(aGoodplot2(:,7))],'-')
% title('Measured vs Exp lou')
% xlabel 'Expected EPSP (mV)'
% ylabel 'Measured EPSP (mV)'
% 
% subplot(2,3,6)
% 
% plot(aGoodplot2(:,12), aGoodplot2(:,3) ,'r--O','MarkerSize', 12,'MarkerFaceColor','r')
% plot([0,max(aGoodplot2(:,12))],[0,max(aGoodplot2(:,12))],'-')
% title('Measured vs Exp Mateo')
% xlabel 'Expected EPSP (mV)'
% ylabel 'Measured EPSP (mV)'
% 
% subplot(2,3,4)
% hold on
% plot(aGoodplot2(:,7), aGoodplot2(:,4) ,'g--O','MarkerSize', 12,'MarkerFaceColor','g','MarkerEdgeColor','b')
% plot(aGoodplot2(:,12), aGoodplot2(:,4),'g-o','MarkerSize', 12,'MarkerFaceColor','g','MarkerEdgeColor','r')
% legend 'Lou' 'Mateo' 'Location' 'northwest'
% title('DF vs expected')
% xlabel 'Expected EPSP (mV)'
% ylabel 'DF-F'
% 
% subplot(2,3,5)
% hold on
% plot(aGoodplot(:,2), aGoodplot(:,3),'k--O', aGoodplot(:,2), aGoodplot(:,7),'b-O',aGoodplot(:,2), aGoodplot2(:,12),'r-o', 'MarkerSize', 12,'MarkerFaceColor','w')
% title('Measured-Exp Inputs#')
% xlabel 'Input #'
% ylabel 'EPSP (mV)'
% legend 'Measured' 'Exp Lou' 'Exp Mateo' 'Location' 'northwest'



fligg=input('push ONE pour tester une nouvelle combi de units cycles, sinon ca va tout sauver dans DATA/analyse')
if fligg==1
    ucycles2=input('envoie la nouvelle sauce')
end
    
%end


%% Ask the user WHERE he wants to save >>>>SAVE ONLY LA MANIP
    %prompt='choisi ou tu veux garder cette magnifique manip'
    %selectedDir3=uigetdir;
    % change path
    %cd(selectedDir3);
    cd('/Users/mateo/Documents/DATA/analyse')
    %Ask the user for the name of the file if he wants to save
    %prompt='une petite description de la manip si cest pas trop demander ';
    %namefile = input(prompt,'s');
    Cc=strsplit(Date,'-')
    Date2=strcat(num2str(Ccc{1,2}),num2str(Ccc{1,1}))%,'--',num2str(Cc{1,3}));
    nameXP=strcat(Date2,'-', num2str(Ccc{1,4}),'--',num2str(Ccc{1,3}))
    mkdir(nameXP);
    cd(nameXP)
    
    Int=strcat('--',Date2,'-',num2str(Ccc{1,4}))
      mkdir('Traces')
      mkdir('Results')
      mkdir('Figures')
       cd('Results')
    save(strcat('Results',Date2,'-',num2str(Ccc{1,4})), 'aGoodplotlegend')
    save(strcat('Results Aligned',Date2,'-',num2str(Ccc{1,4})), 'cellALI')
  
    
xlswrite(strcat('ResultsXL',Int),aGoodplot2)
xlswrite(strcat('Results Aligned XL',Int),aliMat2)

    cd ..
      cd('Traces')
    mkdir('SmithTraces')
    mkdir('DownTraces')
    mkdir('Rawtraces')
    cd('RawTraces')
    %la trace pure
    %on corrige XP volt qui avait les mauvais inputs
    save(strcat('Measured Vm',Date2,'-',num2str(Ccc{1,4})), 'XPvolt')
    %remise a sa baseline
    darF1=[XPvolt(1,:); aGoodVoltbase(:,1) aGoodVoltbase(:,3:end)];
    
    
    save(strcat('EPSPs',Date2,'-',num2str(Ccc{1,4})), 'darF1')
    save(strcat('Expected M',Date2,'-',num2str(Ccc{1,4})), 'XPexpMateo')
    save(strcat('Expected L',Date2,'-',num2str(Ccc{1,4})), 'XPexpLou')
    save(strcat('DF-F',Date2,'-',num2str(Ccc{1,4})), 'XPfluo')
    
    xlswrite(strcat('traces EPSPs', Int),darF1) 
xlswrite(strcat('Expected M',Int),XPexpMateo) 
xlswrite(strcat('Expected L',Int),XPexpLou) 
xlswrite(strcat('traces Fluo',Int),XPfluo) 
clearvars darF1
    cd ..
    cd('DownTraces')
      
    try
     save(strcat('Measured Vm Smith',Int), 'zipVolt')
     save(strcat('DF Smith',Int), 'zipFluo')
      save(strcat('Expected Smith Lou',Int), 'zipExp')
      save(strcat('Expected Smith Mateo',Int), 'XPexpMateo')
      
     xlswrite(strcat('traces EPSPs', Int),zipVolt) 
xlswrite(strcat('Expected M',Int),XPexpMateo) 
xlswrite(strcat('Expected L',Int),zipExp) 
xlswrite(strcat('traces Fluo',Int),zipFluo)  
      
    catch
    end
    
    cd ..
    cd('SmithTraces')
    
    try
     save(strcat('Measured Vm Smith',Int), 'smthVolt')
     save(strcat('DF Smith',Int), 'smthFluo')
      save(strcat('Expected Smith Lou',Int), 'smthExp')
      save(strcat('Expected Smith Mateo',Int), 'XPexpMateo')
      
         xlswrite(strcat('traces EPSPs', Int),smthVolt) 
xlswrite(strcat('Expected M',Int),XPexpMateo) 
xlswrite(strcat('Expected L',Int),smthExp) 
xlswrite(strcat('traces Fluo',Int),smthFluo)  
      
    catch
    end
    
cd ..
cd ..
  
cd('Figures')

saveas(finalF, strcat('Gain and DF',Int),'jpg');
saveas(finalF, strcat('Gain and DF',Int),'pdf');
% saveas(TracesF, 'Traaces','jpg')
% saveas(TracesF, 'Traces','pdf')
%saveas(strcat('Expected Smith Mateo',Int), 'XPexpMateo','xml')
saveas(Alignedplot, strcat('Aligned Plot',Int), 'jpg');
saveas(Alignedplot, strcat('Aligned Plot',Int), 'pdf'); 

saveas(finalf, strcat('Resume',Int), 'pdf');
saveas(finalf, strcat('Resume',Int), 'jpg');

saveas(Alignedplot, 'Aligned Plot', 'pdf');

Fepsp=figure;
plot(XPvolt(:,1),XPvolt(:,2:end))
title ('EPSP measured (mV)', 'Color','w')
xlabel ('time (ms)', 'Color','w')
ylabel ('EPSP measured (mV)', 'Color','w')
[~,icons,~,~] = legend(Inputstr3, 'Location', 'NorthEast');
set(icons,'LineWidth',6);

Fepspbase=figure;

plot(aGoodVoltbase(:,1),aGoodVoltbase(:,3:end))
xlim([80, 250])
if switche==2
    xlim([30,200])
end

title ('EPSP measured (mV)', 'Color','w')
xlabel ('time (ms)', 'Color','w')
ylabel ('EPSP measured (mV)', 'Color','w')
[~,icons,~,~] = legend(Inputstr3, 'Location', 'NorthEast');
set(icons,'LineWidth',6);

Ffluo=figure;
hold on
for hh=1:length (Goodcycles)
p=plot(aGoodFluo(:,1),aGoodFluo(:,hh+1));
p.LineWidth=1;

end
title ('DF-F', 'Color','w');
xlabel ('time (ms)', 'Color','w');
ylabel ('DF-F', 'Color','w');
[~,icons,~,~] = legend(Inputstr3, 'Location', 'NorthEast');
set(icons,'LineWidth',6);


FexpL=figure;
%plot((xxx+20)',expwave(:,INvsCY(1,:)));
plot(aGoodExp(:,1),aGoodExp(:,2:end));
title ('Lou expected', 'Color','w');
xlabel ('time (ms)', 'Color','w');
ylabel ('EPSP expected (mV)', 'Color','w');
[~,icons,~,~] = legend(Inputstr3, 'Location', 'NorthEast');
set(icons,'LineWidth',6);


FexpM=figure;
plot (XPexpMateo(2:end,1),XPexpMateo(2:end,2:end));
[~,icons,~,~] = legend(Inputstr3, 'Location', 'NorthEast');
set(icons,'LineWidth',6);
title ('Mateo Expected', 'Color','w');
xlabel ('Time (ms)', 'Color','w');
ylabel ('mV', 'Color','w');


Fdvdt=figure;
plot(aGoodVolt(500:3500,1),DVDT(500:3500,1:end));
[~,icons,~,~] = legend(Inputstr3, 'Location', 'NorthEast');
set(icons,'LineWidth',6);
title ('dVdt', 'Color','w');
xlabel ('Time (ms)', 'Color','w');
ylabel ('mV/ms', 'Color','w');

saveas(Fepsp, strcat('Fepsp',Int), 'pdf');
saveas(Fepsp, strcat('Fepsp',Int), 'jpg');

saveas(Fepspbase, strcat('Fepspbase',Int), 'pdf');
saveas(Fepspbase, strcat('Fepspbase',Int), 'jpg');

saveas(FexpL, strcat('FexpL',Int), 'pdf');
saveas(FexpL, strcat('FexpL',Int), 'jpg');

saveas(FexpM, strcat('FexpM',Int), 'pdf');
saveas(FexpM, strcat('FexpM',Int), 'jpg');

saveas(Ffluo, strcat('Ffluo',Int), 'pdf');
saveas(Ffluo, strcat('Ffluo',Int), 'jpg');

saveas(Fdvdt, strcat('Fdvdt',Int), 'pdf');
saveas(Fdvdt, strcat('Fdvdt',Int), 'jpg');


 %% test interne de valeurs calculees differements qui doivent etre egales
 if PtsGrp~=cell2mat(Goodinputscycleorder)
     display('ya un putain de probleme dans les putains de cycles')
 else
     display('tout va bien copain')
 end  
   
%% INFOS
   
display('donne moi des infos sur la manip')

prompt='layer'
layer=input(prompt)

prompt='cell'
celll=input(prompt)

prompt='Zstack of the branch ZOOM'
zoom=input(prompt)

prompt='Zstack centered on the branch'
centerZ=input(prompt)

prompt='distance from soma'
dfs=input(prompt)

prompt='branchlength'
branchlength=input(prompt)

prompt='what kind of branch, 1basal 2oblique 3trunk 4tuft'
kind=input(prompt)

prompt='branch generation'
Bgen=input(prompt)

prompt='bAps associated'
bAp=input(prompt)

prompt='VR associated'
VR=input(prompt)

prompt='Obvious Sodium Spiklet?? ONE pour oui comme toujours'
Naspiklet=input(prompt)

prompt='Quality of the experiment, ONE = good'
Qlity=input(prompt)

prompt='Any drugs ? just put the name of it'
DRUGS=input(prompt)

prompt='un commentaire ?, genre cest une oblique qui cest une oblique qui se comporte comme une basale'
commm=input(prompt)

totalnumberpoints=maxinput
try
maxdVdT=max(max(DVDT))
catch
end

unitsMean=mean(upeak)

XPinfo={jour mois annee Ccc{1,4} celll zoom centerZ dfs branchlength kind Bgen MaxGain MaxDF unitsMean MeanUnits2 maxdVdT totalnumberpoints bAp VR Vm LaserPowa layer}
legendXPinfo={'jour' 'mois' 'Year' 'LineScan' '5Cell' 'branchZstack' 'centeredZstack' 'distance from soma' 'branch length' '10kind of branch' 'generation of branch' 'Max Gain' 'Max DF/F' 'unitsMeanLou' '15unitsMeanMateo' 'Max dVdT' 'number of spines' 'bAp LineScans associated' 'Voltage Recordings associated' 'Resting Membrane Potential' 'Laser power' 'Layer'}
XPinfoleg=[legendXPinfo; XPinfo]
%allXPinfo={'jour' 'mois' 'Year' 'LineScan' '5Cell' 'branchZstack' 'centeredZstack' 'distance from soma' 'branch length' '10kind of branch' 'generation of branch' 'Max Gain' 'Max DF/F' 'unitsMeanLou' '15unitsMeanMateo' 'Max dVdT' 'number of spines' 'bAp LineScans associated' 'Voltage Recordings associated' 'Resting Membrane Potential'}
%save('allXPinfo','allXPinfo')

%% AUTO ANALYSE VR et bAp

Gool=input('already analysed the VR for this cell ?? (yes=ONE)')
if Gool==1
    cd('/Users/mateo/Documents/DATA/Absolute/All/VR/Temp')
    
   load bline
load maxAPs
  load maxHsag
  load Inputresistance
end
vrr=input('any current injection steps to add ?? you better say yes ! (yes=ONE)')
if vrr==1
    dual=1;
    cd('/Users/mateo/Documents/DATA/RAW');
% Ask the user for directory
alldirs=uipickfiles;
ncycle=length(alldirs);

for electrode=dual
    


V_recordings={};
C_command={};
Vpara={};

k=1;
for i=1:ncycle
    selectedDir=char(alldirs(i));
% change path
cd(selectedDir);
% get directory name and path separately 
[pathToDirName dirName] = fileparts(selectedDir);


% Get ephys and fluorescence signal for each cycle
   % Get the files
    %Get ephys xml file
    v_output = dir('*xml');
    v_output=v_output(2).name;%[strcat(dirName, '_Cycle00001_VoltageOutput_001') '.xml'];
    %Get ephys voltage recording
    v_recording = dir('*csv');
    v_recording=v_recording(1).name;%[strcat(dirName, '_Cycle00001_VoltageRecording_001') '.csv'];
    
    
   % [V_recordings{i} C_command{i} Vpara{i}]=ephysIOcurves(v_output,v_recording);
       
    %%ephys function modified and integrated here
xmlfile=v_output;
csvfile=v_recording;
%%Get voltage recording from csv file as there is no info in the xml file
%%that can't be found in the v output
%Read csv file to get voltage recording
TempData = csvread(csvfile, 1,0);
VoltageValues = TempData(:,(2));
%Adjust gain (get millivolts
VoltageValues=100*VoltageValues;
%Get timestamps in milliseconds
TimeValues = TempData(:,1);

V=[TimeValues VoltageValues];



%GEt xml file to get info about the ephys protocol
%transform into structure
[s] = xml2struct(xmlfile);

%Extract info from s (in pA)and store it in P

if strcmp(s.Experiment.Waveform{1,electrode}.Enabled.Text,'true')
Pvr.Current_Units = s.Experiment.Waveform{1,electrode}.Units.Text;
Pvr.UnitScaleFactor = str2num(s.Experiment.Waveform{1,electrode}.UnitScaleFactor.Text);
Pvr.UnitVoltageOffset = str2num(s.Experiment.Waveform{1,electrode}.UnitVoltageOffset.Text);
Pvr.UnitScaleOffset = str2num(s.Experiment.Waveform{1,electrode}.UnitScaleOffset.Text);
Pvr.ExperimentState = s.Experiment.Waveform{1, electrode}.Enabled.Text;
Pvr.PulseCount = str2num(s.Experiment.Waveform{1, electrode}.WaveformComponent_PulseTrain.PulseCount.Text);
Pvr.PulseWidth = str2num(s.Experiment.Waveform{1, electrode}.WaveformComponent_PulseTrain.PulseWidth.Text);
Pvr.PulseSpacing = str2num(s.Experiment.Waveform{1, electrode}.WaveformComponent_PulseTrain.PulseSpacing.Text);
Pvr.PulsePotentialStart = 1000*str2num(s.Experiment.Waveform{1, electrode}.WaveformComponent_PulseTrain.PulsePotentialStart.Text);
Pvr.PulsePotentialDelta = 1000*str2num(s.Experiment.Waveform{1, electrode}.WaveformComponent_PulseTrain.PulsePotentialDelta.Text);
Pvr.RestPotential = 1000*str2num(s.Experiment.Waveform{1, electrode}.WaveformComponent_PulseTrain.RestPotential.Text);
Pvr.FirstPulseDelay = str2num(s.Experiment.Waveform{1, electrode}.WaveformComponent_PulseTrain.FirstPulseDelay.Text);
Pvr.Repetitions = str2num(s.Experiment.Waveform{1, electrode}.WaveformComponent_PulseTrain.Repetitions.Text);
Pvr.DelayBetweenReps = str2num(s.Experiment.Waveform{1, electrode}.WaveformComponent_PulseTrain.DelayBetweenReps.Text);

if Pvr.PulseCount==1
C=[Pvr.RestPotential*ones(Pvr.FirstPulseDelay,1); Pvr.PulsePotentialStart*ones(Pvr.PulseWidth,1); Pvr.RestPotential*ones(ceil(TimeValues(end)-(P.FirstPulseDelay+P.PulseWidth)),1)];
V_recordings{k}=V;
C_command{k}=C;
Vpara{k}=Pvr;
Vpara{k}.delay=Vpara{k}.FirstPulseDelay;
k=k+1;

else
  %set delay
    if Pvr.FirstPulseDelay>=100 & Pvr.PulseSpacing>200
        Pvr.delay=100;
    else
        Pvr.delay=Pvr.FirstPulseDelay;
    end
    
    %
    %Set lenght of segment that I will use
    seglength=2*Pvr.delay+Pvr.PulseWidth;
    
        %Set lenght of segment that I will use
    pulselength=Pvr.PulseSpacing+Pvr.PulseWidth;
        
    
    %Find of number of pulses and Adjust if not recorded long enough
      limit=size(V,1)/20;
%       pulselimit=P.FirstPulseDelay+P.PulseCount*(P.PulseWidth+P.PulseSpacing);
       cyclimit=floor((limit-Pvr.FirstPulseDelay-Pvr.delay)/((Pvr.PulseWidth+Pvr.PulseSpacing)));
      if Pvr.PulseCount<=cyclimit
          pulses=Pvr.PulseCount;
      else
          pulses=cyclimit;
      end
      
      %compute time vector
      VT=0:0.05:(seglength);
   for j=1:pulses
       %find first and last points
      t1=Pvr.FirstPulseDelay-Pvr.delay+(j-1)*pulselength;
      t2=t1+seglength;
      t1=20*t1+1;
      t2=20*t2+1;
      %get only relevant V for this cycle
   V_recordings{k}=[VT' V(t1:t2,2)];
   
   %Get parameter and adjust pulsepotentialstart (name is not changed so
   %slightly confusing but whatever)
   Vpara{k}=Pvr;   
   Vpara{k}.PulsePotentialStart=Vpara{k}.PulsePotentialStart+((j-1)*Vpara{k}.PulsePotentialDelta);
   
   
   C=[ Vpara{k}.RestPotential*ones(Pvr.delay,1);  Vpara{k}.PulsePotentialStart*ones(Pvr.PulseWidth,1); Vpara{k}.RestPotential*ones(Pvr.delay,1)];
C_command{k}=C;

k=k+1;
    
end
end
end
end

ntraces=k-1;
%Parse inputs to get single pulses...

%% Plot ephys and fluo data
ucycles=[];
for i=1:ntraces
figure

    %Plot voltage
subplot(2,1,1)
h=plot(V_recordings{i}(:,1),V_recordings{i}(:,2));
h.LineWidth=1.5;
h.Color='y';
xlabel('ms')
ylabel('mV')
title('Voltage recording')


    
%Plot command current
subplot(2,1,2)
h=plot(C_command{i});
h.LineWidth=3;
h.Color='k';
%ylim([Vpara{i}.RestPotential-100 Vpara{i}.PulsePotentialStart+200])
xlabel('ms')
ylabel('pA')
title('Current command')
    %Legend
    l=legend(num2str(Vpara{i}.PulsePotentialStart));
    l.LineWidth=0.05;
    l.FontSize=5;
    
    usselect = input('Press enter if good, press 0 otherwise');
    if isempty(usselect)
        ucycles(i)=1;
    else
        ucycles(i)=0;
    end
    
    
end

%% Plot all cycle together
color = varycolor(ntraces);
figure
k=1;
for i=1:ntraces
if ucycles(i)==1;
    %Plot voltage
subplot(2,1,1)
hold on
h=plot(V_recordings{i}(:,1),V_recordings{i}(:,2));
h.LineWidth=1;
h.Color=color(i,:);
xlabel('ms')
ylabel('mV')
title('Voltage recording')

%Plot command current
subplot(2,1,2)
hold on
h=plot(C_command{i});
h.LineWidth=1;
h.Color=color(i,:);
%ylim([Vpara{i}.RestPotential-100 Vpara{i}.PulsePotentialStart+200])
xlabel('ms')
ylabel('pA')
title('Current command')


    %Legend
    leg{k}=num2str(Vpara{i}.PulsePotentialStart);
     k=k+1;
    if i==ntraces
    l=legend(leg);
    l.LineWidth=0.05;
    l.FontSize=5;
   
    end
end
end

%%
%Ask user for AP threshold
APthresh = input('Enter action potential threshold (default=0)');
if isempty(APthresh)
    APthresh=0;
end

goodcycles=find(ucycles==1);
APcycles=[];
RINcycles=[];
for i=goodcycles
%Comput region of interest
toi1=ceil(Vpara{i}.delay/0.05);
toi2=floor((Vpara{i}.delay+Vpara{i}.PulseWidth)/0.05);

    if max(smooth(V_recordings{i}(toi1:toi2,2),11)>0)
    APcycles=[APcycles i];
    else
        RINcycles=[RINcycles i];
    end
end


%% Compute spikes
kk=1;
for i=APcycles
%Comput region of interest
toi1=ceil(Vpara{i}.delay/0.05);
toi2=floor((Vpara{i}.delay+Vpara{i}.PulseWidth)/0.05);


temp=V_recordings{i}(toi1:toi2,2);
APcount=1;
yo=find(temp>(APthresh));
for j=1:(length(yo)-1)
if yo(j+1)>yo(j)+20
    APcount=APcount+1;
end
end
APfreq=1000*APcount/Vpara{i}.PulseWidth;
spikeresults(kk,:)=[Vpara{i}.PulsePotentialStart APfreq];
kk=kk+1;
end


spikeresults=sortrows(spikeresults,1);

%GEt unique number of spikes 
temp=spikeresults';
    un=unique(temp(1,:));
    yo=[];
    %Average data when number of uncaging sites is the same
    for i=1:size(un,2)
        idx=find(temp(1,:)==un(i));
        nn(i)=mean(temp(2,idx));
    end
    spiketable=[un;nn]


%% Compute IV curve
kk=1;
hhh=1;
for i=RINcycles
    %baseline
    bline=mean(V_recordings{i}(1:floor(Vpara{i}.delay/0.05),2));
   
      if max(V_recordings{i}(1:floor(Vpara{i}.delay/0.05),2))>-40
      figure
      h=plot(V_recordings{i}(:,1),V_recordings{i}(:,2));
h.LineWidth=1;
h.Color=color(i,:);
xlabel('ms')
ylabel('mV')
title('Voltage recording')

bline = input('Enter proper baseline');
    end
    
    
    toi1=ceil((Vpara{i}.delay+(0.66*Vpara{i}.PulseWidth))/0.05);
toi2=floor((Vpara{i}.delay+(Vpara{i}.PulseWidth))/0.05);

    %steadystate
    plateau=mean(V_recordings{i}(toi1:toi2,2));
    deltaV=plateau-bline;
    RINresults(kk,:)=[Vpara{i}.PulsePotentialStart deltaV];
    
        
    %Hsag
    if Vpara{i}.PulsePotentialStart<0
       toi2=ceil((Vpara{i}.delay)/0.05);
toi3=floor((Vpara{i}.delay+(0.33*Vpara{i}.PulseWidth))/0.05);
     hpeak=min(smooth(V_recordings{i}(toi2:toi3,2),5))-bline;
    Hresults(hhh,:)=[Vpara{i}.PulsePotentialStart deltaV hpeak];
    hhh=hhh+1;
    end
    
    
    kk=kk+1;
end
    
%Sort those tables

%IV
RINresults=sortrows(RINresults,1);
%GEt unique 
temp=RINresults';
    Run=unique(temp(1,:));
    yo=[];
    %Average data whencurrent is the same
    for i=1:size(Run,2)
        idx=find(temp(1,:)==Run(i));
        Rnn(i)=mean(temp(2,idx));
    end
   RINtable=[Run;Rnn]

   %Hsag
   Hresults=sortrows( Hresults,1);
%GEt unique 
temp=Hresults';
    Hun=unique(temp(1,:));
    yo=[];
    %Average data whencurrent is the same
    for i=1:size(Hun,2)
        idx=find(temp(1,:)==Hun(i));
        Hnn(i)=mean(temp(2,idx));
        HHnn(i)=mean(temp(3,idx));
    end
   Htable=[Hun;Hnn;HHnn;((HHnn-Hnn)./HHnn)];

   clearvars un nn Run Rnn Hun Hnn HHnn 
    
        
 %Comput RIN in megaohm
%Only consider points with current injections lower or equal to zero
 RINindex=find(RINtable(1,:)<=0)
  Inputresistance=1000*regress(RINtable(2,RINindex)',RINtable(1,RINindex)')




%% Final figure
warning('off')
finalf=figure;
% Plot all cycle together
color = varycolor(ntraces);
k=1;
for i=1:ntraces
if ucycles(i)==1;
    %Plot voltage
subplot(2,2,1)
hold on
h=plot(V_recordings{i}(:,1),V_recordings{i}(:,2));
h.LineWidth=1;
h.Color=color(i,:);
xlabel('ms')
ylabel('mV')
title('Voltage recording')
end
end



subplot(2,2,2)
title('Action potentials')
   h=plot(spiketable(1,:),spiketable(2,:),'b--o');
     h.LineWidth=1;
    h.Color='r';
    xlabel('Injected current (pA)','FontSize',8)
    ylabel('Firing rate (Hz)','FontSize',8)
        set(gca,'FontSize',8);
        
        
subplot(2,2,3)
title('IV curve')
   h=plot(RINtable(1,:),RINtable(2,:),'b--o');
     h.LineWidth=1;
    h.Color='b';
    xlabel('Injected current (pA)','FontSize',8)
    ylabel('Delta V','FontSize',8)
        set(gca,'FontSize',8);
       %Add uncaging info on plot
        dim = [0.15 0.15 0.3 0.3];
       str = {strcat('R=',num2str(round(Inputresistance)),'M?')};
        a=annotation('textbox',dim,'String',str,'FitBoxToText','on');
        a.FontSize=8; 
        hold on
        %Plot regression curve
          xreg=floor(min(RINtable(1,:))):1:ceil(max(RINtable(1,:)));
          yreg=Inputresistance*xreg/1000;
          
    t=plot(xreg,yreg);
    t.LineStyle='--';
    t.Color=[0.5 0.5 0.5];
           
subplot(2,2,4)
title('H sag')
   h=plot(Htable(1,:),Htable(4,:),'b--o');
     h.LineWidth=1;
    h.Color='g';
    xlabel('Injected current (pA)','FontSize',8)
    ylabel('H sag','FontSize',8)
        set(gca,'FontSize',8);
        
        
% put in the figure
%  save in meaningful way
%  test out
%  incorporate lnger recordings and duals

 
 %% Ask the user if he wants to save

    %Create variables storing everything
        %spikes
    tosave{1}=spiketable;
    %IV curve
     tosave{2}=RINtable;
     %hsag
     tosave{3}=Htable;
     %input resistance
     tosave{4}=Inputresistance;
     %rheobase
     tosave{5}=min(spiketable(1,:));
     if tosave{5}<25
         tosave{25}=25;
     end
     
     
     
%     %     % Ask the user for directory where to save
%     selectedDir4=uigetdir;
%     % change path
%     cd(selectedDir4);
    
    
    cd(strcat('/Users/mateo/Documents/DATA/analyse/',nameXP))
    mkdir('Caracterisation')
    cd('Caracterisation')

    save 'caracterisation' tosave
    save(strcat('caracterisation',Int), 'tosave')
    %too=cell2mat(tosave)
    saveas(finalf,'caracterisation.jpeg')

    maxAPs=max(spiketable(2,:));
    maxHsag=max(Htable(4,:));
    
    %save aussi dans les all VR pour avoir toutes les carac regroupees
    cd('/Users/mateo/Documents/DATA/Absolute/All/VR')
    mkdir(nameXP)
    cd(nameXP)

    save 'caracterisation' tosave
    save(strcat('caracterisation',Int), 'tosave')
    %too=cell2mat(tosave)
    saveas(finalf,'caracterisation.jpeg')
    
    cd('/Users/mateo/Documents/DATA/Absolute/All/VR/Temp')
    
    save('bline','bline')
    save('maxAPs','maxAPs')
    save('maxHsag','maxHsag')
    save('Inputresistance','Inputresistance')
    
end











end 
%%

prompt='some Time spread experiments for this branch ? (0NE pour dire oui)'
alOrstsp=input(prompt)

if alOrstsp==1

   
    
    cd('/Users/mateo/Documents/DATA/RAW')
% Ask the user for directory
selectedDir=uigetdir;
% change path
cd(selectedDir);
% get directory name and path separately
[pathToDirName dirName] = fileparts(selectedDir);

%Can change it if you want F instead of df/f
df_over_f=1;

%That will store whether or not the file contains Ca imaging data or not
ca=[];
%That will store the current length of the line to make sure it does not
%change
c_line=[];

%Load xml file to get info about the linescan protocol
% make a variable for a name of .xml files containing the information about the sequence
fileName = [strcat(dirName) '.xml'];
%transform into structure
[s] = xml2struct(fileName);
%Get number of cycle
ncycle= size(s.PVScan.Sequence,2);

%% Get ephys and fluorescence signal for each cycle
V_recordings={};
% % C_command={};
Vpara={};
fluo_recordings={};
Fpara={};
boundaries=[];

%If only one cycle, it is slightly different
if ncycle==1

    v_recording = [strcat(dirName, '_Cycle00001_VoltageRecording_001') '.csv'];
    TempData =  csvread(v_recording, 1,0);
    VoltageValues = TempData(:,2);
    %Adjust gain (get millivolts
    VoltageValues=100*VoltageValues;
    %Get timestamps in milliseconds
    TimeValues = TempData(:,1);
    V_recordings{1}=[TimeValues VoltageValues];
    
    %Get uncaging data
    nomark(1)=0;
    try
        Uncaging{1} = markpoints([strcat(dirName, '_Cycle00001_MarkPoints') '.xml']);
    catch
        Uncaging{1}={};
        Uncaging{1}.InterPointDelay=1000;
        nomark(1)=1;
    end
    
    %Get linescan xml file
    tempo = s.PVScan.Sequence;
 
    try
        B=[str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x0) str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x1)];
    catch
        B=[5 10];
    end
    %Get fluo image
    image = imread([strcat(dirName, '_Cycle00001_Ch1_000001') '.ome.tif']);
    
    if size(image,1)>10 & Uncaging{1}.InterPointDelay<20
        ca(1)=1;
        %Get fluo data
        [fluo_recordings{1} Fpara{1} boundaries]=line_Ca_first(tempo,image, B);
    else
        ca(1)=0;
    end

else if ncycle<10

        v_recording = [strcat(dirName, '_Cycle00001_VoltageRecording_001') '.csv'];
        TempData =  csvread(v_recording, 1,0);
        VoltageValues = TempData(:,2);
        %Adjust gain (get millivolts
        VoltageValues=100*VoltageValues;
        %Get timestamps in milliseconds
        TimeValues = TempData(:,1);
        V_recordings{1}=[TimeValues VoltageValues];
        
        
        %Get uncaging data
        nomark(1)=0;
        try
            Uncaging{1} = markpoints([strcat(dirName, '_Cycle00001_MarkPoints') '.xml']);
        catch
            Uncaging{1}={};
            Uncaging{1}.InterPointDelay=1000;
            nomark(1)=1;
        end
        
        %Get linescan xml file
        tempo = s.PVScan.Sequence {1};
        
        %Get prior ROI boundaries if existent, otherwise start with generic [20
        %50]
        try
            B=[str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x0) str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x1)];
        catch
            B=[10 20];
        end
        
        
        %Get fluo image
        image = imread([strcat(dirName, '_Cycle00001_Ch1_000001') '.ome.tif']);
        c_line=size(image,2);
        if size(image,1)>10 & Uncaging{1}.InterPointDelay<20
            ca(1)=1;
            %Get fluo data
            [fluo_recordings{1} Fpara{1} boundaries]=line_Ca_final_Mateo(tempo,image, B);
        else
            ca(1)=0;
            boundaries=B;
        end
     
        for i=2:ncycle
       
            v_recording = [strcat(dirName, '_Cycle0000',num2str(i),'_VoltageRecording_001') '.csv'];
            
            TempData =  csvread(v_recording, 1,0);
            VoltageValues = TempData(:,2);
            %Adjust gain (get millivolts
            VoltageValues=100*VoltageValues;
            %Get timestamps in milliseconds
            TimeValues = TempData(:,1);
            V_recordings{i}=[TimeValues VoltageValues];
            
            %Get uncaging data
            nomark(i)=0;
            try
                Uncaging{i} = markpoints([strcat(dirName, '_Cycle0000',num2str(i),'_MarkPoints') '.xml']);
            catch
                Uncaging{i}={};
                Uncaging{i}.InterPointDelay=1000;
                nomark(i)=1;
            end
            
         
            %Get linescan xml file
            tempo = s.PVScan.Sequence {i};
            
            %Get fluo image
            image = imread([strcat(dirName, '_Cycle0000',num2str(i),'_Ch1_000001') '.ome.tif']);
            
            if size(image,1)>10 & Uncaging{i}.InterPointDelay<20
                ca(i)=1;
                %Get fluo data
                [fluo_recordings{i} Fpara{i} boundaries]=line_Ca_final_Mateo(tempo,image, boundaries);
                c_line=size(image,2);
                
            else
                ca(i)=0;
            end
        
            
        end
        
        %IF more than 9 cycles
    else

        v_recording = [strcat(dirName, '_Cycle00001_VoltageRecording_001') '.csv'];
        TempData =  csvread(v_recording, 1,0);
        VoltageValues = TempData(:,2);
        %Adjust gain (get millivolts
        VoltageValues=100*VoltageValues;
        %Get timestamps in milliseconds
        TimeValues = TempData(:,1);
        V_recordings{1}=[TimeValues VoltageValues];
        
        %Get uncaging data
        nomark(1)=0;
        try
            Uncaging{1} = markpoints([strcat(dirName, '_Cycle00001_MarkPoints') '.xml']);
        catch
            Uncaging{1}={};
            Uncaging{1}.InterPointDelay=1000;
            nomark(1)=1;
            
        end
        
        %Get linescan xml file
        tempo = s.PVScan.Sequence {1};
        
        %Get prior ROI boundaries if existent, otherwise start with generic [20
        %50]
        try
            B=[str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x0) str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x1)];
        catch
            B=[10 20];
        end
        
        %Get fluo image
        image = imread([strcat(dirName, '_Cycle00001_Ch1_000001') '.ome.tif']);
        if size(image,1)>10 & Uncaging{1}.InterPointDelay<20
            ca(1)=1;
            c_line=size(image,2);
            %Get fluo data
            [fluo_recordings{1} Fpara{1} boundaries]=line_Ca_final_Mateo(tempo,image, B);
        else
            ca(1)=0;
            boundaries=B;
        end

        for i=2:9

            v_recording = [strcat(dirName, '_Cycle0000',num2str(i),'_VoltageRecording_001') '.csv'];
            
            TempData =  csvread(v_recording, 1,0);
            VoltageValues = TempData(:,2);
            %Adjust gain (get millivolts
            VoltageValues=100*VoltageValues;
            %Get timestamps in milliseconds
            TimeValues = TempData(:,1);
            V_recordings{i}=[TimeValues VoltageValues];
            
            %Get uncaging data
            nomark(i)=0;
            try
                Uncaging{i} = markpoints([strcat(dirName, '_Cycle0000',num2str(i),'_MarkPoints') '.xml']);
            catch
                Uncaging{i}={};
                Uncaging{i}.InterPointDelay=1000;
                nomark(i)=1;
            end
      
            %Get linescan xml file
            tempo = s.PVScan.Sequence {i};
            %Get fluo image
            image = imread([strcat(dirName, '_Cycle0000',num2str(i),'_Ch1_000001') '.ome.tif']);
            
            
            if size(image,1)>10 & Uncaging{i}.InterPointDelay<20
                ca(i)=1;
                %Get fluo data
                
                [fluo_recordings{i} Fpara{i} boundaries]=line_Ca_final_Mateo(tempo,image, boundaries);
                c_line=size(image,2);
                
                
                
            else
                ca(i)=0;
            end
    
            
        end
        for i=10:ncycle
   
            v_recording = [strcat(dirName, '_Cycle000',num2str(i),'_VoltageRecording_001') '.csv'];
            
            try
                TempData =  csvread(v_recording, 1,0);
            catch
                TempData=[0 -0.6;0 -0.6];
            end
            
            VoltageValues = TempData(:,2);
            %Adjust gain (get millivolts
            VoltageValues=100*VoltageValues;
            %Get timestamps in milliseconds
            TimeValues = TempData(:,1);
            V_recordings{i}=[TimeValues VoltageValues];
            
            %Get uncaging data
            nomark(i)=0;
            try
                Uncaging{i} = markpoints([strcat(dirName, '_Cycle000',num2str(i),'_MarkPoints') '.xml']);
            catch
                Uncaging{i}={};
                Uncaging{i}.InterPointDelay=1000;
                nomark(i)=1;
            end
            
            %Get linescan xml file
            tempo = s.PVScan.Sequence {i};
            %Get fluo image
            image = imread([strcat(dirName, '_Cycle000',num2str(i),'_Ch1_000001') '.ome.tif']);
            
            
            if size(image,1)>10 & Uncaging{i}.InterPointDelay<20
                ca(i)=1;
                
                [fluo_recordings{i} Fpara{i} boundaries]=line_Ca_final_Mateo(tempo,image, boundaries);
                c_line=size(image,2);
                
            else
                ca(i)=0;
                
            end
        end
    end
end
   %cycle3 = input('Enter the cycles you dont want to include in this format [1 2 3 4]: (Enter [0] to skip) ');
    
%%
figure

clear MaX
clear Bas

for i=1:ncycle
    
    hold on
    plot (V_recordings{1,i}(:,1),V_recordings{1,i}(:,2));
   MaX{i}=min(V_recordings{1,i}(:,2));
    Bas{i}=mean(V_recordings{1,i}(1:999,2));
    Volt{i}=(V_recordings{1,i}(:,2))-Bas{i}
    IpD{i}=Uncaging{1,i}.InterPointDelay;
    if MaX{i}>0
        MaX{i}=NaN
    end
    
end

Volt1=cell2mat(Volt)
% FtspTrace=figure('Name','Time spread Traces','Color', [0 0.5 0.5])
% plot(Volt1)
%   [~,icons,~,~] = legend(legtsp, 'Location', 'NorthEast');
% set(icons,'LineWidth',6);
% title ('Time spread', 'Color','w')
% xlabel ('Inter Point Delay(ms)', 'Color','w')
% ylabel ('EPSP Amplitude (mV)', 'Color','w')

realmax=min(-Volt1)
realmax1=realmax'

% baseVolt=V_recordings{1,cycle3}(:,1)

% V_recordings{1,cycle3}(:,2))]
%     figure
%     plot
%     
    
    MAX=MaX';
    bas=cell2mat(Bas)
     maximat=cell2mat(MaX)
     
   AmplitudeTSP=maximat-bas
   
    IPD=IpD';
     MAXX=cell2mat(MAX)
     IPDD=cell2mat(IPD)
     legtsp=num2str(IPDD)
     Timespread=[IPDD -realmax1]
     
     FtspTrace=figure('Name','Time spread Traces','Color', [0 0.5 0.5])
plot(Volt1)
  [~,icons,~,~] = legend(legtsp, 'Location', 'NorthEast');
set(icons,'LineWidth',6);
title ('Time spread', 'Color','w')
xlabel ('Inter Point Delay(ms)', 'Color','w')
ylabel ('EPSP Amplitude (mV)', 'Color','w')

     %%
    Ftsp=figure('Name','Time spread','Color', [0 0.5 0.5])
    hold on
     scatter(Timespread(:,1),Timespread(:,2),180,'r')
     
     plot(Timespread(:,1),Timespread(:,2),'r--o')
%   [~,icons,~,~] = legend(legtsp, 'Location', 'NorthEast');
% set(icons,'LineWidth',6);
 title ('Time spread', 'Color','w')
 xlabel ('Inter Point Delay(ms)', 'Color','w')
 ylabel ('EPSP Amplitude (mV)', 'Color','w')

% figure
% plot(IPDD,MAXX,'o')
% 
%   figure
%   scatter(IPDD,AmplitudeTSP,130,'filled')


%% SAVE TIME SPREAD ANALise
 cd(strcat('/Users/mateo/Documents/DATA/analyse/',nameXP))
 mkdir('Time spread')
 cd('Time spread')
 save(strcat('timespread',Int),'Timespread')
 xlswrite(strcat('timespread',Int),Timespread)
 
saveas(Ftsp, strcat('Time spread',Int), 'jpg')
saveas(Ftsp, strcat('Time spread',Int), 'pdf')
saveas(FtspTrace, strcat('Time spread Traces',Int), 'jpg')
saveas(FtspTrace, strcat('Time spread Traces',Int), 'pdf')

%on pool sans demander, pauvre user il en a marre de repondre a des
%questions, et l'user cest moi alors respect bordel
%changement de plan, en fait on va juste regrouper les differents tsp
 cd('/Users/mateo/Documents/DATA/Absolute/All/Tsp')
 %starter and reset
 save(strcat('timespread',Int),'Timespread')
 xlswrite(strcat('timespread',Int),Timespread)

maxxttsp=max(Timespread)
maxIPD=maxxttsp(1)
end

  %% BACK PROPAGATING TA MERE
prompt='some bAps for this branch ? (0NE pour dire oui)'
alOrsbap=input(prompt)

cd('/Users/mateo/Documents/DATA/RAW');

if alOrsbap==1
cd(strcat('/Users/mateo/Documents/DATA/analyse/',nameXP))
mkdir('bAPs')

%acopier pour plus tard pour sauver les fichiers
cd(strcat('/Users/mateo/Documents/DATA/analyse/',nameXP,'/bAPs'))

%on place le current folder la ou sont la raw data pour pas avoir a trop se
%faire chier
cd('/Users/mateo/Documents/DATA/RAW');
% Ask the user for directory
alldirs=uipickfiles;
ncycle=length(alldirs);

V_recordings={};
C_command={};
Vpara={};

k=1;
for iii=1:ncycle
    selectedDir=char(alldirs(iii));
% change path
cd(selectedDir);
% get directory name and path separately 
[pathToDirName dirName] = fileparts(selectedDir);


% Get ephys and fluorescence signal for each cycle
   % Get the files
    %Get ephys xml file
    v_output = dir('*xml');
    v_output=v_output(2).name;%[strcat(dirName, '_Cycle00001_VoltageOutput_001') '.xml'];
    %Get ephys voltage recording
    v_recording = dir('*csv');
    v_recording=v_recording(1).name;%[strcat(dirName, '_Cycle00001_VoltageRecording_001') '.csv'];
    
    
   % [V_recordings{i} C_command{i} Vpara{i}]=ephysIOcurves(v_output,v_recording);
       
    %%ephys function modified and integrated here
xmlfile=v_output;
csvfile=v_recording;
%%Get voltage recording from csv file as there is no info in the xml file
%%that can't be found in the v output
%Read csv file to get voltage recording
TempData = csvread(csvfile, 1,0);
VoltageValues = TempData(:,(2));
%Adjust gain (get millivolts
VoltageValues=100*VoltageValues;
%Get timestamps in milliseconds
TimeValues = TempData(:,1);

V=[TimeValues VoltageValues];



%GEt xml file to get info about the ephys protocol
%transform into structure
[s] = xml2struct(xmlfile);

%Extract info from s (in pA)and store it in P

fileName = [strcat(dirName) '.xml'];
%transform into structure
[s] = xml2struct(fileName);
%Get number of cycle
ncycle= size(s.PVScan.Sequence,2);


%% Get ephys and fluorescence signal for each cycle
V_recordings={};
C_command={};
Vpara={};
fluo_recordings={};
Fpara={};
boundaries=[];

%If only one cycle, it is slightly different
if ncycle==1
    % Get the files
    %Get ephys xml file
    v_output = [strcat(dirName, '_Cycle00001_VoltageOutput_001') '.xml'];
    %Get ephys voltage recording
    v_recording = [strcat(dirName, '_Cycle00001_VoltageRecording_001') '.csv'];
    %Get linescan xml file
    tempo = s.PVScan.Sequence;
    
    %Get prior ROI boundaries if existent, otherwise start with generic [20
    %50]
    try
    B=[str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x0) str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x1)];
    catch
        B=[20 50];
    end
    %Get fluo image
    image = imread([strcat(dirName, '_Cycle00001_Ch1_000001') '.ome.tif']);
    %Call ephys and line_Ca functions
    [V_recordings{1} C_command{1} Vpara{1}]=ephys_spiketrains(v_output,v_recording);
    [fluo_recordings{1} Fpara{1} boundaries]=line_Ca_first(tempo,image, B);
else if ncycle<10
    % Get the files
        %Get ephys xml file
        v_output = [strcat(dirName, '_Cycle00001_VoltageOutput_001') '.xml'];
        %Get ephys voltage recording
        v_recording = [strcat(dirName, '_Cycle00001_VoltageRecording_001') '.csv'];
        %Get linescan xml file
        tempo = s.PVScan.Sequence {1};
        %Get prior ROI boundaries
        B=[str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x0) str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x1)];
        %Get fluo image
        image = imread([strcat(dirName, '_Cycle00001_Ch1_000001') '.ome.tif']);
        %Call ephys and line_Ca functions
        [V_recordings{1} C_command{1} Vpara{1}]=ephys_spiketrains(v_output,v_recording);
        [fluo_recordings{1} Fpara{1} boundaries]=line_Ca_final_Mateo(tempo,image, B);
    
    for i=2:ncycle
        % Get the files
        %Get ephys xml file
        v_output = [strcat(dirName, '_Cycle0000',num2str(i),'_VoltageOutput_001') '.xml'];
        %Get ephys voltage recording
        v_recording = [strcat(dirName, '_Cycle0000',num2str(i),'_VoltageRecording_001') '.csv'];
        %Get linescan xml file
        tempo = s.PVScan.Sequence {i};
        %Get fluo image
        image = imread([strcat(dirName, '_Cycle0000',num2str(i),'_Ch1_000001') '.ome.tif']);
        %Call ephys and line_Ca functions
        [V_recordings{i} C_command{i} Vpara{i}]=ephys_spiketrains(v_output,v_recording);
        
        [fluo_recordings{i} Fpara{i}]=line_Ca_final_Mateo(tempo,image, boundaries);
    end
    %If more than 9 cycles
 else 
    % Get the files
        %Get ephys xml file
        v_output = [strcat(dirName, '_Cycle00001_VoltageOutput_001') '.xml'];
        %Get ephys voltage recording
        v_recording = [strcat(dirName, '_Cycle00001_VoltageRecording_001') '.csv'];
        %Get linescan xml file
        tempo = s.PVScan.Sequence {1};
        %Get prior ROI boundaries
        B=[str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x0) str2num(tempo.PVLinescanDefinition.LineScanProfiles.Profile.Attributes.x1)];
        %Get fluo image
        image = imread([strcat(dirName, '_Cycle00001_Ch1_000001') '.ome.tif']);
        %Call ephys and line_Ca functions
        [V_recordings{1} C_command{1} Vpara{1}]=ephys_spiketrains(v_output,v_recording);
        [fluo_recordings{1} Fpara{1} boundaries]=line_Ca_first(tempo,image, B);
    
    for i=2:9
        % Get the files
        %Get ephys xml file
        v_output = [strcat(dirName, '_Cycle0000',num2str(i),'_VoltageOutput_001') '.xml'];
        %Get ephys voltage recording
        v_recording = [strcat(dirName, '_Cycle0000',num2str(i),'_VoltageRecording_001') '.csv'];
        %Get linescan xml file
        tempo = s.PVScan.Sequence {i};
        %Get fluo image
        image = imread([strcat(dirName, '_Cycle0000',num2str(i),'_Ch1_000001') '.ome.tif']);
        %Call ephys and line_Ca functions
        [V_recordings{i} C_command{i} Vpara{i}]=ephys_spiketrains(v_output,v_recording);
        [fluo_recordings{i} Fpara{i}]=line_Ca_final_Mateo(tempo,image, boundaries);
    end  
    
    for i=10:ncycle
        % Get the files
        %Get ephys xml file
        v_output = [strcat(dirName, '_Cycle000',num2str(i),'_VoltageOutput_001') '.xml'];
        %Get ephys voltage recording
        v_recording = [strcat(dirName, '_Cycle000',num2str(i),'_VoltageRecording_001') '.csv'];
        %Get linescan xml file
        tempo = s.PVScan.Sequence {i};
        %Get fluo image
        image = imread([strcat(dirName, '_Cycle000',num2str(i),'_Ch1_000001') '.ome.tif']);
        %Call ephys and line_Ca functions
        [V_recordings{i} C_command{i} Vpara{i}]=ephys_spiketrains(v_output,v_recording);
        [fluo_recordings{i} Fpara{i}]=line_Ca_final_Mateo(tempo,image, boundaries);
    end   
    
end
end

%Compute df/f and store it in the third column of fluo_recording
for i=1:ncycle
    %Compute mean only on baseline before current injection
    %get last point before current injection
    limit=floor((Vpara{i}.FirstPulseDelay)/(Fpara{i}.scanLinePeriod))-10;
    %GEt mean
    temp2=mean(fluo_recordings{i}(1:limit,2));
   
    fluo_recordings{i}(:,3)= (fluo_recordings{i}(:,2)-temp2)./temp2;
clearvars temp2
end





%% Plot ephys and fluo data
%one figure per cycle
ucycles=[];
for i=1:ncycle
figure
%identify which figure is for which cycle??

    %Plot voltage
subplot(3,1,1)
h=plot(V_recordings{i}(:,1),V_recordings{i}(:,2));
h.LineWidth=1.5;
h.Color='b';
xlabel('ms')
ylabel('mV')
title('Voltage recording')

    %Legend
    leg{i}=num2str(i);
    if i==ncycle
    l=legend(leg);
    l.LineWidth=0.05;
    l.FontSize=5;
    end
    
    
%Plot command current
subplot(3,1,2);
h=plot(C_command{i});
h.LineWidth=1;
h.Color='r';
ylim([Vpara{i}.RestPotential-100 Vpara{i}.PulsePotentialStart+200])
xlabel('ms')
ylabel('pA')
title('Current command')

%Plot calcium signal

%Plot df/f
subplot(3,1,3);
h=plot(fluo_recordings{i}(:,1),fluo_recordings{i}(:,3));
h.LineWidth=1.5;
h.Color='g';
xlabel('ms')
ylabel('DF/F')
title('Fluorescence')
%xlim([0 max(V_recordings{i}(:,1))])

    %Plot fluo
% subplot(3,1,3)
% h=plot(fluo_recordings{i}(:,1),fluo_recordings{i}(:,2));
% h.LineWidth=1.5;
% h.Color='g';
% xlabel('ms')
% ylabel('F')
% title('Fluorescence')
% xlim([0 max(V_recordings{i}(:,1))])


usselect = input('Press enter if good, press 0 otherwise');
    if isempty(usselect)
        ucycles(i)=1;
    else
        ucycles(i)=0;
    end
    



end


%% Get only the desired cycles
goodcycles=find(ucycles==1);
ncycle=length(goodcycles);

%% Plot all cycle together
color = varycolor(goodcycles(end));
figure;
for i=goodcycles

    %Plot voltage
subplot(3,1,1)
hold on
h=plot(V_recordings{i}(:,1),V_recordings{i}(:,2));
h.LineWidth=1;
h.Color=color(i,:);
xlabel('ms')
ylabel('mV')
title('Voltage recording')

%Plot command current
subplot(3,1,2)
hold on
h=plot(C_command{i});
h.LineWidth=1;
h.Color=color(i,:);
%ylim([Vpara{i}.RestPotential-100 Vpara{i}.PulsePotentialStart+200])
xlabel('ms')
ylabel('pA')
title('Current command')

%Plot calcium signal
%Plot df/f

    subplot(3,1,3)
    hold on
    h=plot(fluo_recordings{i}(:,1),fluo_recordings{i}(:,3));
    h.LineWidth=1;
    h.Color=color(i,:);
    xlabel('ms')
    ylabel('DF/F')
    title('Fluorescence')
    %xlim([0 max(V_recordings{i}(:,1))])
       

    subplot(3,1,3)
    hold on
    h=plot(fluo_recordings{i}(:,1),fluo_recordings{i}(:,2));
    h.LineWidth=1;
    h.Color=color(i,:);
    xlabel('ms')
    ylabel('F')
    title('Fluorescence')
    %xlim([0 max(V_recordings{i}(:,1))])

end

%% Compute peak and area for calcium signal
%variables to store peak and area
smoothedsignal={};

indpeak=[];
indarea=[];
%GO through each selected cycles to compute those things
for i=goodcycles
    
                
                %period
                pp=Fpara{1,i}.scanLinePeriod;
                %smoothing bins
                if pp>0.5
                    bin=5;
                else
                    bin=3;
                end
                
                timelimits=floor((Vpara{i}.FirstPulseDelay)/(Fpara{i}.scanLinePeriod));
                %peak
                try
                    smoothedsignal{i}=smooth(fluo_recordings{i}(timelimits:end,3),bin);
                catch
                    smoothedsignal{i}=smooth(fluo_recordings{i}(:,3),bin);
                end
                indpeak(i)=max(smoothedsignal{i});
                
                
                %Area
                try
                    
                    indarea(i)=trapz(fluo_recordings{i}(timelimits:end,1),(smoothedsignal{i}));
                catch
                    indarea(i)=trapz(fluo_recordings{i}(:,1),(smoothedsignal{i}));
                    
                end
                
    
                disp('Viva el Mateo')
          
            
            
end

%% Arrange everything in a useful table
resulttable=goodcycles;
for i=1:length(goodcycles)
    resulttable(2,i)=indpeak(goodcycles(i));
    resulttable(3,i)=indarea(goodcycles(i));
end


%% average signals
%ephys trace

%fin shorter trace
tempmin=9999999999999999999999;
for i=1:length(goodcycles)
    temp=size(V_recordings{goodcycles(i)},1);
    if temp<tempmin
        tempmin=temp;
    end
end

tempsum=[];
for i=1:length(goodcycles)
    temp=V_recordings{goodcycles(i)}(1:tempmin,2);
    if i==1
        tempsum=temp;
    else
        tempsum=tempsum+temp;
    end
end
vmean=tempsum/(length(goodcycles));
vmeanx=V_recordings{goodcycles(i)}(1:tempmin,1);


%Calcium

%find shorter trace
tempmin=9999999999999999999999;
for i=1:length(goodcycles)
    temp=fluo_recordings{goodcycles(i)}(end,1);
    if temp<tempmin
        tempmin=temp;
    end
end
%Round down
tempmin=floor(tempmin);

%interpolate signals to a period of 0.5ms, then sum and average them
querypts=0:0.5:tempmin;

tempsum=[];
for i=1:length(goodcycles)
    temp=interp1(fluo_recordings{goodcycles(i)}(:,1),fluo_recordings{goodcycles(i)}(:,3),querypts);
    if i==1
        tempsum=temp;
    else
        tempsum=tempsum+temp;
    end
end
camean=tempsum/(length(goodcycles));
cameanx=querypts;


%% Plot summmary figure


%Get ref image and plot it with freehand on it
figure
subplot(2,2,1)

% Change folder to get ref image
selectedDir=[selectedDir '/References'];
% change path
cd(selectedDir);
%Get ref image 
ref_image = im2double(imread([strcat(dirName, '-Cycle00002-Window1-Ch1-Ch2-8bit-Reference') '.tif']));

%Get ref image 
imagesc(ref_image(:,:,1:3))
title('Reference image')
axis off;

subplot(2,2,2)
h=plot(vmeanx,vmean);
h.LineWidth=1;
h.Color='b';
xlabel('ms')
ylabel('mV')
title('Voltage recording')

subplot(2,1,2)
h=plot(cameanx,camean);
    h.LineWidth=1;
    h.Color='g';
    xlabel('ms')
    ylabel('DF/F')
    title('Calcium signal')
    xlim([0 max(V_recordings{i}(:,1))])
    

%xuserlim = input('Enter desired x limit');

%PLot again with those limits
finalf = figure(10000+iii);
finalf.Position=[300,50,1200,700];
subplot(2,2,1)
%Get ref image 
imagesc(ref_image(:,:,1:3))
title('Reference image')
axis off;

subplot(2,2,2)
h=plot(vmeanx,vmean);
h.LineWidth=1;
h.Color='b';
xlabel('ms')
ylabel('mV')
title('Voltage recording')
%xlim([0 xuserlim])

subplot(2,1,2)
h=plot(cameanx,camean);
    h.LineWidth=1;
    h.Color='g';
    xlabel('ms')
    ylabel('DF/F')
    title('Calcium signal')
    %xlim([0 xuserlim])
%% save chaque loop(ou fichier) dans lexperience de IO analysee just avant    
cd(strcat('/Users/mateo/Documents/DATA/analyse/',nameXP,'/bAPs'))
saveas(finalf,strcat('bAp',num2str(iii),Int),'jpg')
save(strcat('bAp',num2str(iii),Int),'resulttable')
allbap{iii}=mean(resulttable(2,:))
save(strcat('allbAps',Int),'allbap')
xlswrite('bapXL',allbap)

end

tata=figure
allbap1=cell2mat(allbap)
allbapsorder=sortrows(allbap1,1)
maxfluobap=max(allbap1)
plot(allbap1,'o')
xlabel('APs number')
ylabel('Average Peak DF-F')
saveas(tata,strcat('5 3 1 bAps',Int),'jpg')

dote1=str2num(Ccc{1,2})
dote2=str2num(Ccc{1,4})
tbone=allbapsorder'

clear ref_image
if length(tbone)==1
    tbone=[tbone; NaN;NaN]
end  
%tbone=tbone(1:3,:)
if length(tbone)==2    
    tbone=[tbone; NaN]
end

end
%% Remplissage des cases au cas ou il ny ait pas de data

if ~exist('maxfluobap','var') 
    maxfluobap=0
end 
if ~exist('maxIPD','var') 
    maxIPD=0
end 
if ~exist('Inputresistance','var') 
    Inputresistance=0
end 
if ~exist('maxAPs','var') 
    maxAPs=0
end 
if ~exist('maxHsag','var') 
    maxHsag=0
end 
if ~exist('bline','var') 
    bline=0
end 
if ~exist('tbone','var')
    tbone=0
end    
if ~exist('Timespread','var')
    Timespread=0
end 

%%
prompt='tu veux continuer et pooler cette manip avec les autres ????? (ONE pour OUI)'
alors=input(prompt)
if alors~=1
    error('ok.. va te faire foutre malagradecido!')
end

%%pool les bAps si ca existe

if alOrsbap==1
cd('/Users/mateo/Documents/DATA/Absolute/Updated/bAPs')


AbsXPbapcell={Date; Ccc{1,4}; tbone(1,1);tbone(2,1);tbone(3,1) ;dfs;Bgen ;layer;kind}
load AbsoluteBapcell
AbsoluteBapcell=[AbsoluteBapcell AbsXPbapcell]
save('AbsoluteBapcell','AbsoluteBapcell')
 
%update and save the matrix
   
  AbsXPbap=[niceNameXPxl; tbone;dfs;Bgen ;layer;kind]
 load AbsoluteBap
 AbsoluteBap=[AbsoluteBap AbsXPbap]
  %AbsoluteBap=ones(9,1)
  save('AbsoluteBap','AbsoluteBap')
  xlswrite('AbsoluteBap',AbsoluteBap)   
  
  
  load AbsoluteBapVRcell
AbsXPbapVRcell={Date; Ccc{1,4}; tbone(1,1);tbone(2,1);tbone(3,1) ;dfs;Bgen ;layer;kind;Inputresistance;maxAPs;maxHsag;bline}
AbsoluteBapVRcell=[AbsoluteBapVRcell AbsXPbapVRcell]
   save  AbsoluteBapVRcell AbsoluteBapVRcell

end


%last version of XPinfo avec les infos tirees des baps, time spread and VR
legendXPinfo2={'jour' 'mois' 'Year' 'LineScan' '5Cell' 'branchZstack' 'centeredZstack' 'distance from soma' 'branch length' '10kind of branch' 'generation of branch' 'Max Gain' 'Max DF/F' 'unitsMeanLou' '15unitsMeanMateo' 'Max dVdT' 'number of spines' 'bAp LineScans associated' 'Voltage Recordings associated' '20Resting Membrane Potential' 'Laser power' 'bAps DF-F' 'Time spread' 'Input Resistance' '25max APs number' 'max SAG' 'Calcium appears' 'Layer' 'Obvious Na spkilet' 'Vm VR' 'DRUGS' 'Empty spot' 'Qlity'}
%legendXPinfo3={'jour' 'mois' 'Year' 'LineScan' '5Cell' 'branchZstack' 'centeredZstack' 'distance from soma' 'branch length' '10kind of branch' 'generation of branch' 'Max Gain' 'Max DF/F' 'unitsMeanLou' '15unitsMeanMateo' 'Max dVdT' 'number of spines' 'bAp LineScans associated' 'Voltage Recordings associated' '20Resting Membrane Potential' 'Laser power' 'bAps DF-F' 'Time spread' 'Input Resistance' '25max APs number' 'max SAG' 'Calcium appears' 'Layer' 'Obvious Na spkilet' 'Vm VR' 'DRUGS' 'Qlity' 'CA aligned' 'IN aligned' 'bAps table' 'Tsp table' 'first point' 'commm'}

 
%% juste un test pour lupdate
%dabord les calcium aligned
cd('/Users/mateo/Documents/DATA/Absolute/Updated/Calcium Aligned')
%GAIN
load AllGCA
load AllGCAsanity
AliG6=AliG5(:,[2 3])

AllGCA=[AllGCA AliG6]
AllGCAsanity=[AllGCAsanity AliG5]
save('AllGCAsanity','AllGCAsanity')
save('AllGCA','AllGCA')

%FLUO
load AllFCAsanity
load AllFCA

legAliF2={niceNameXP niceNameXP ;'Aligned inputs' 'Fluo'}
AliF2=[legAliF2; AliF2]
AliF4=[legAliF2; AliF4]
AliF5=AliF4(:,2)
AllFCA=[AllFCA AliF5]
AllFCAsanity=[AllFCAsanity AliF4]

clearvars AliF3 AliF2 AliF1 AliFluoXPcellnoLEG
save('AllFCA','AllFCA')
save('AllFCAsanity','AllFCAsanity')
% size(AllFCA)
% size(AliF4)
% size (AllGCA)

%apres les total inputs aligned
cd('/Users/mateo/Documents/DATA/Absolute/Updated/Inputs Aligned')
load AllFIN
load AllFINsanity
load AllGIN
load AllGINsanity
% awwa=[-51:1:50]'
% awwa=num2cell(awwa)

AllFIN=[AllFIN XPDali(:,3)]
AllFINsanity=[AllFINsanity XPDali(:,[1 3])]
AllGIN=[AllGIN XPGali(:,[4 3])]
AllGINsanity=[AllGINsanity XPGali(:,[1 4 3])]


save('AllFIN','AllFIN')
save('AllFINsanity','AllFINsanity')
save('AllGIN','AllGIN')
save('AllGINsanity','AllGINsanity')
%%
legallALI={Ccc{1,1} Ccc{1,2} Date Ccc{1,4} 'XX';'DF-F' 'Gain Lou' 'Total input' 'Aligned Inputs' 'Gain Mateo'};
aliCell=[legallALI; aliMAT];
%legendXPinfo3={'jour' 'mois' 'Year' 'LineScan' '5Cell' 'branchZstack' 'centeredZstack' 'distance from soma' 'branch length' '10kind of branch' 'generation of branch' 'Max Gain' 'Max DF/F' 'unitsMeanLou' '15unitsMeanMateo' 'Max dVdT' 'number of spines' 'bAp LineScans associated' 'Voltage Recordings associated' '20Resting Membrane Potential' 'Laser power' 'bAps DF-F' 'Time spread' 'Input Resistance' '25max APs number' 'max SAG' 'Calcium appears' 'Layer' 'Obvious Na spkilet' 'Vm VR' 'DRUGS' 'Qlity' 'Fluo CA aligned' 'Gain CA aligned' 'IN aligned' 'bAps table' 'Tsp table'}
legendXPinfo3={'jour' 'mois' 'Year' 'LineScan' '5Cell' 'branchZstack' 'centeredZstack' 'distance from soma' 'branch length' '10kind of branch' 'generation of branch' 'Max Gain' 'Max DF/F' 'unitsMeanLou' '15unitsMeanMateo' 'Max dVdT' 'number of spines' 'bAp LineScans associated' 'Voltage Recordings associated' '20Resting Membrane Potential' 'Laser power' 'bAps DF-F' 'Time spread' 'Input Resistance' '25max APs number' 'max SAG' 'Calcium appears' 'Layer' 'Obvious Na spkilet' 'Vm VR' 'DRUGS' 'Qlity' 'CA aligned fluo' 'CA aligned gain' 'IN aligned' 'bAps table' 'Tsp table' 'first point' 'commentaire'}

XPinfo3={jour mois annee Ccc{1,4} celll zoom centerZ dfs branchlength kind Bgen MaxGain MaxDF unitsMean MeanUnits2 maxdVdT totalnumberpoints bAp VR Vm LaserPowa maxfluobap maxIPD Inputresistance maxAPs maxHsag aliGG layer Naspiklet bline DRUGS Qlity AliF4 AliG5 aliCell tbone Timespread Ampli2(1,1) commm}

XPinfo2={jour mois annee Ccc{1,4} celll zoom centerZ dfs branchlength kind Bgen MaxGain MaxDF unitsMean MeanUnits2 maxdVdT totalnumberpoints bAp VR Vm LaserPowa maxfluobap maxIPD Inputresistance maxAPs maxHsag aliGG layer Naspiklet bline DRUGS 'ideas' Qlity}
XPinfoWleg=[legendXPinfo2; XPinfo2]
XPinfoFinal=[legendXPinfo3; XPinfo3]
length(legendXPinfo3)
length(XPinfo3)
cd('/Users/mateo/Documents/DATA/Absolute/All/XPinfos')
Int2=strcat(Date,'L-',Ccc{1,4});
save(strcat(Int2,'Infos'),'XPinfoWleg');

Int2=strcat(Date,'L-',Ccc{1,4});
save(strcat(Int2,'Infos3'),'XPinfoFinal');

%load update and save allXPinfo
cd('/Users/mateo/Documents/DATA/Absolute/Updated')
load allXPinfo2
load allXPinfo
load allXPinfo3
%allXPinfo=[allXPinfo; XPinfo]
allXPinfo3=[allXPinfo3; XPinfo3];
allXPinfo2=[allXPinfo2; XPinfo2];
allXPinfo=[allXPinfo; XPinfo];
save('allXPinfo2', 'allXPinfo2')
save('allXPinfo', 'allXPinfo')
save('allXPinfo3', 'allXPinfo3') 
 
%RESET ALL XP INFO reset
% cd('/Users/mateo/Documents/DATA/Absolute/Updated')
% allXPinfo=legendXPinfo
% save('allXPinfo', 'allXPinfo')

cd('/Users/mateo/Documents/DATA/Absolute/Updated/MatLab/old')
%load allXPali;
load allGainAli;
load allFluoAli;

%update 
allGainAli=[allGainAli XPGali];
allFluoAli=[allFluoAli XPDali];

%aliMat22=num2cell(aliMat2,1);
legallALI={Ccc{1,1} Ccc{1,2} Date Ccc{1,4} 'XX';'DF-F' 'Gain Lou' 'Total input' 'Aligned Inputs' 'Gain Mateo'};
aliCell=[legallALI; aliMAT]
% XPalicell=[legallALI; aliMat22];
% size(legallALI)
% size(aliMat22)
% size(XPalicell)

% allXPali=[allXPali aliCell];

%et save
save('allGainAli','allGainAli');
save('allFluoAli','allFluoAli');
%save('allXPali','allXPali');

%lets do the matlab separate xp, on sauve le fichier individuel avec le
%nomm de la manip et on va sauver les bien alignes aussi tant qu faire
cd('/Users/mateo/Documents/DATA/Absolute/All/MatLab');
save(strcat('GainGood',Int),'AliG6');
save(strcat('FluoGood',Int),'AliF4');


cd('/Users/mateo/Documents/DATA/Absolute/All/MatLab/old');
save(strcat('Gain',Int),'XPGali');
save(strcat('Fluo',Int),'XPDali');
save(strcat('All',Int),'XPalicell');


%% only Excel Files
%lets put a numerique legend pour la date pour la manip du jour
%creation de XLfiles, tous numerique et avec legende
dote1=str2num(Ccc{1,2});
dote2=str2num(Ccc{1,4});

GaliXLlegend=[dote1 dote2 dote1 dote2];
Galinum=cell2mat(Gali);
GaliXL=[GaliXLlegend; Galinum];

DaliXLlegend=[dote1 dote2 dote1];
Dalinum=cell2mat(Dali);
DaliXL=[DaliXLlegend; Dalinum];

XPali=aliMat2;
XPalilegend=[dote1 dote2 dote1 dote2 dote1];
XPaliXL=[XPalilegend; XPali];

%lets save dans all avec un intitule

cd('/Users/mateo/Documents/DATA/Absolute/All/XL')
xlswrite(strcat('Gain Aligned',Int),GaliXL)
xlswrite(strcat('Fluo Aligned',Int),DaliXL)
xlswrite(strcat('All Aligned',Int),XPaliXL)

%lets update 
cd('/Users/mateo/Documents/DATA/Absolute/Updated/XL')
load allGainXL
load allFluoXL
load allXL
%create et RESET
% size(GaliXL)
% size(allGainXL)
allGainXL=[allGainXL GaliXL]
allFluoXL=[allFluoXL DaliXL]
allXL=[allXL XPaliXL]

%un petit save de la matrice updated au cas ou yaurait une merde avec excel
%et meme si ya pas demerde cest necessaire pour pas avoir a reloader le
%faitchier csv.

save('allGainXL','allGainXL')
save('allFluoXL','allFluoXL')
save('allXL','allXL')

% %allShort=ones(1,101)'
cd('/Users/mateo/Documents/DATA/Absolute/Updated/MatLab')
load allShort
allShort=[allShort XPaliXL]
save ('allShort','allShort')

%STARTER DONT DO IT AGAIN
% allGainXL=ones(101,1)
% allFluoXL=ones(101,1)
% allXL=ones(101,1)

%and save les fichiers excel updated
cd('/Users/mateo/Documents/DATA/Absolute/Updated/XL')
xlswrite('All Gain Aligned',allGainXL)
xlswrite('All Fluo Aligned',allFluoXL)
xlswrite('All Aligned',allXL)


%% STARTERS OF BASAL OBLIQUE TRUNK AND TUFT DONT RUN AGAIN !!
% cd('/Users/mateo/Documents/DATA/Absolute/Updated')
% 
% basalALI=ones(100,1)
% obliqueALI=ones(100,1)
% trunkALI=ones(100,1)
% tuftALI=ones(100,1)
% 
% basalALIcell=cell(102,1)
% obliqueALIcell=cell(102,1)
% trunkALIcell=cell(102,1)
% tuftALIcell=cell(102,1)
% 
% save('basalALI','basalALI')
% save('obliqueALI','obliqueALI')
% save('trunkALI','trunkALI')
% save('tuftALI','tuftALI')
% 
% save('basalALIcell','basalALIcell')
% save('obliqueALIcell','obliqueALIcell')
% save('trunkALIcell','trunkALIcell')
% save('tuftALIcell','tuftALIcell')

cd('/Users/mateo/Documents/DATA/Absolute/Updated/groups Inputs Aligned')

if XPinfo{1,10}==1
   load basalALI
    load basalALIcell
   basalALI=[basalALI XPali]
   basalALIcell=[basalALIcell XPalicell]
   save basalALI basalALI
   save basalALIcell basalALIcell
   
end

if XPinfo{1,10}==2
     load obliqueALIcell
       load obliqueALI
   obliqueALI=[obliqueALI XPali]
   obliqueALIcell=[obliqueALIcell XPalicell]
   save obliqueALI obliqueALI
   save obliqueALIcell obliqueALIcell
end

if XPinfo{1,10}==3
    load trunkALI
    load trunkALIcell
   trunkALI=[trunkALI XPali]
   trunkALIcell=[trunkALIcell XPalicell]
   save trunkALI trunkALI
   save trunkALIcell trunkALIcell
end

if XPinfo{1,10}==4
    load tuftALI
      load tuftALIcell
   tuftALI=[tuftALI XPali]
   tuftALIcell=[tuftALIcell XPalicell]
   save tuftALI tuftALI
   save tuftALIcell tuftALIcell
end

cd('/Users/mateo/Documents/DATA/Absolute/Updated/groups Calcium aligned')
%AliF5=AliF4(:,2)
if XPinfo{1,10}==1
    cd('basal')
   load basalKagain
   load basalKafluo
   load basalKagainfluo
basalKagain =[basalKagain AliG6]
basalKafluo=[basalKafluo AliF5]
basalKagainfluo=[basalKagainfluo AliG6 AliF5] 
display(strcat('there are',num2str(size(basalKafluo,2)),'inthe group'))
   save basalKafluo basalKafluo
   save  basalKagainfluo  basalKagainfluo
   save basalKagain basalKagain
end

if XPinfo{1,10}==2
     
   cd('oblique')
   load obliqueKagain
   load obliqueKafluo
   load obliqueKagainfluo
obliqueKagain =[obliqueKagain AliG6]
obliqueKafluo=[obliqueKafluo AliF5]
obliqueKagainfluo=[obliqueKagainfluo AliG6 AliF5] 
display(strcat('there are',num2str(size(obliqueKafluo,2)),'inthe group'))
   save obliqueKafluo obliqueKafluo
   save  obliqueKagainfluo  obliqueKagainfluo
   save obliqueKagain obliqueKagain
end

if XPinfo{1,10}==3
    
   cd('trunk')
   load trunkKagain
   load trunkKafluo
   load trunkKagainfluo
trunkKagain =[trunkKagain AliG6]
trunkKafluo=[trunkKafluo AliF5]
trunkKagainfluo=[trunkKagainfluo AliG6 AliF5] 
display(strcat('there are',num2str(size(trunkKafluo,2)),'in the group'))
   save trunkKafluo trunkKafluo
   save  trunkKagainfluo  trunkKagainfluo
   save trunkKagain trunkKagain
end

if XPinfo{1,10}==4
    
    
      cd('tuft')
   load tuftKagain
   load tuftKafluo
   load tuftKagainfluo
   
tuftKagain =[tuftKagain AliG6]
tuftKafluo=[tuftKafluo AliF5]
tuftKagainfluo=[tuftKagainfluo AliG6 AliF5] 

display(strcat('there are',num2str(size(tuftKafluo)),'inthe group'))
   save tuftKafluo tuftKafluo
   save  tuftKagainfluo  tuftKagainfluo
   save tuftKagain tuftKagain
end

%% Display le numbre de manip pooled together pour le moment


% load tuftKafluo
% load trunkKagain
%    load obliqueKagain
% load basalKagain

%Bsize=length(tuftKafluo)



er1=size(allXPinfo)
er2=size(XPinfo)
er3=er1-er2

e1=size(allXPinfo2)
e2=size(XPinfo2)
e3=e1-e2

if XPinfo{1,10}==4
koak4=size(tuftALI)
display(strcat('There are : ', num2str((koak4(1,2)-1)/5), 'experiments pooled in the TUFT group'))
end

if XPinfo{1,10}==3
koak3=size(trunkALI)
display(strcat('There are : ', num2str((koak3(1,2)-1)/5), 'experiments pooled in the TRUNK group'))
end

if XPinfo{1,10}==2
koak2=size(obliqueALI)
display(strcat('There are : ', num2str((koak2(1,2)-1)/5), 'experiments pooled in the OBLIQUE group'))
end

if XPinfo{1,10}==1
koak1=size(basalALI)
display(strcat('There are : ', num2str((koak1(1,2)-1)/5), 'experiments pooled in the BASAL group'))
end

display(strcat('There are : ', num2str(e3(1,1)), 'experiments pooled in allXPinfo2'))
display(strcat('There are : ', num2str(er3(1,1)), 'experiments pooled in allXPinfo'))
%%
prompt='tu veux compter le nombre de manip ????? (ONE pour OUI)'
alorsss=input(prompt)
if alors==1
  %% count experiments for sanity

cd('/Users/mateo/Documents/DATA/Absolute/Updated/groups Inputs Aligned') 

load basalALI      
load trunkALIcell 
load tuftALIcell
load obliqueALI
load trunkALI
load tuftALI
load basalALIcell
load obliqueALIcell

sb=size(basalALI);
so=size(obliqueALI);
str=size(trunkALI);
stf=size(tuftALI);

display(strcat('there are',{' '},num2str((sb(1,2)-1)/5),{' '},'XP in the basal group'))
display(strcat('there are',{' '},num2str((so(1,2)-1)/5),{' '},'XP in the oblique group'))
display(strcat('there are',{' '},num2str((str(1,2)-1)/5),{' '},'XP in the trunk group'))
display(strcat('there are',{' '},num2str((stf(1,2)-1)/5),{' '},'XP in the tuft group'))

sb1= size(basalALIcell);
so1=size(obliqueALIcell);
str1=size(trunkALIcell);
stf1=size(tuftALIcell);

display(strcat('there are',{' '},num2str((sb1(1,2)-1)/5),{' '},'XP in the basal group'))
display(strcat('there are',{' '},num2str((so1(1,2)-1)/5),{' '},'XP in the oblique group'))
display(strcat('there are',{' '},num2str((str1(1,2)-1)/5),{' '},'XP in the trunk group'))
display(strcat('there are',{' '},num2str((stf1(1,2)-1)/5),{' '},'XP in the tuft group'))


cd('/Users/mateo/Documents/DATA/Absolute/Updated')
 load allXPinfo
 load allXPinfo2
 load allXPinfo3
 
 x1=size(allXPinfo);
 x2=size(allXPinfo2);
 x3=size(allXPinfo3);
 
 
 display(strcat('there are',{' '},num2str(x1(1,1)-1),{' '},'XP in the info1'))
display(strcat('there are',{' '},num2str(x2(1,1)-1),{' '},'XP in the info2'))
display(strcat('there are',{' '},num2str(x3(1,1)-1),{' '},'XP in the info3'))



 
 cd('/Users/mateo/Documents/DATA/Absolute/Updated/XL')
 load allGainXL 
 load allFluoXL 
 load allXL
gx=size(allGainXL);
fx=size(allFluoXL);
allx=size(allXL);

display(strcat('there are',{' '},num2str((gx(1,2)-1)/4),{' '},'XP in the allGain XL'))
display(strcat('there are',{' '},num2str((fx(1,2)-1)/3),{' '},'XP in the allFluo XL'))
display(strcat('there are',{' '},num2str((allx(1,2)-1)/5),{' '},'XP in the all XL'))

cd('/Users/mateo/Documents/DATA/Absolute/Updated/MatLab/old')
 load allFluoAli 
 load allGainAli %allXPali 
af=size(allFluoAli);
ag=size(allGainAli);
%aal=size(allXPali)

display(strcat('there are',{' '},num2str((af(1,2)-1)/3),{' '},'XP in the allFluoAli'))
display(strcat('there are',{' '},num2str((ag(1,2)-1)/4),{' '},'XP in the allGainAli'))
%display(strcat('there are',{' '},num2str((aal(1,2)-1)),{' '},'XP in the allXPali'))

 cd('/Users/mateo/Documents/DATA/Absolute/Updated/bAPs')
 load AbsoluteBap 
 load AbsoluteBapcell 
 load AbsoluteBapVR 
 load AbsoluteBapVRcell
 
 bbs1=size(AbsoluteBap);
 bbs2=size(AbsoluteBapcell);
 %bbs3=size(AbsoluteBapVR);
 bbs4=size(AbsoluteBapVRcell);
 
 display(strcat('there are',{' '},num2str((bbs1(1,2)-1)),{' '},'XP in the simple bap'))
 display(strcat('there are',{' '},num2str((bbs2(1,2)-1)),{' '},'XP in the simple bap'))
  %display(strcat('there are',{' '},num2str((bbs3(1,2)-1)),{' '},'XP in the VR bap'))
   display(strcat('there are',{' '},num2str((bbs4(1,2)-1)),{' '},'XP in the VR bap'))
 
 cd('/Users/mateo/Documents/DATA/Absolute/Updated/Calcium Aligned')
%calcium aligned
load AllFCA
load AllFCAsanity
load AllGCA
load AllGCAsanity

qw=size(AllFCA);
qww=(qw(1,2)-1);
display (strcat('There are',' : ', num2str(qww),{' '},' experiements in allFCA'))
qw1=size(AllGCA);
qw2=(qw1(1,2)-1)/2;
display (strcat('There are ',' : ', num2str(qw2),{' '},' experiements in allGCA'))

qw3=size (AllFCAsanity);
qw4=size (AllGCAsanity);
 display(strcat('there are',{' '},num2str((qw3(1,2)-1)/2),{' '},'XP in the allFCAsanity group'))
 display(strcat('there are',{' '},num2str((qw4(1,2)-1)/3),{' '},'XP in the allGCAsanity group'))
 

 cd('/Users/mateo/Documents/DATA/Absolute/Updated/Inputs Aligned')

load AllFINsanity
load AllGIN 
load AllGINsanity 
load AllFIN

 aio1=size(AllFINsanity);
 aio2=size(AllGIN);
 aio3=size(AllGINsanity);
 aio4=size(AllFIN);

display(strcat('there are',{' '},num2str((aio1(1,2)-1)/2),{' '},'XP in the fluo sanity  group'))
display(strcat('there are',{' '},num2str((aio2(1,2)-1)/2),{' '},'XP in the gain group'))
display(strcat('there are',{' '},num2str((aio3(1,2)-1)/3),{' '},'XP in the  gain sanity group'))
display(strcat('there are',{' '},num2str((aio4(1,2)-1)),{' '},'XP in the fluo group'))
 
 

 
 cd('/Users/mateo/Documents/DATA/Absolute/Updated/groups Calcium aligned')
cd('basal')
  load basalKafluo 
  load basalKagainfluo 
  load basalKagain
bbb1=size(basalKafluo);
bbb2=size(basalKagainfluo);
bbb3=size(basalKagain);
display(strcat('there are',{' '},num2str((bbb1(1,2)-1)),{' '},'XP in the basal fluo group'))
display(strcat('there are',{' '},num2str((bbb2(1,2)-1)/3),{' '},'XP in the basal all group'))
display(strcat('there are',{' '},num2str((bbb3(1,2)-1)/2),{' '},'XP in the basal gain group'))
cd ..

cd('oblique')
load obliqueKafluo 
load obliqueKagainfluo 
load obliqueKagain 
bb11=size(obliqueKafluo);
bb22=size(obliqueKagainfluo);
bb33=size(obliqueKagain);
display(strcat('there are',{' '},num2str((bb11(1,2)-1)),{' '},'XP in the oblique fluo group'))
display(strcat('there are',{' '},num2str((bb22(1,2)-1)/3),{' '},'XP in the oblique all group'))
display(strcat('there are',{' '},num2str((bb33(1,2)-1)/2),{' '},'XP in the oblique gain group'))
cd ..

cd('trunk')

load trunkKafluo 
load trunkKagainfluo 
load trunkKagain 
bb11=size(trunkKafluo);
bb22=size(trunkKagainfluo);
bb33=size(trunkKagain);
display(strcat('there are',{' '},num2str((bb11(1,2)-1)),{' '},'XP in the trunk fluo group'))
display(strcat('there are',{' '},num2str((bb22(1,2)-1)/3),{' '},'XP in the trunk all group'))
display(strcat('there are',{' '},num2str((bb33(1,2)-1)/2),{' '},'XP in the trunk gain group'))
cd ..

cd('tuft')
load tuftKafluo 
load tuftKagainfluo 
load tuftKagain 
bb11=size(tuftKafluo);
bb22=size(tuftKagainfluo);
bb33=size(tuftKagain);
display(strcat('there are',{' '},num2str((bb11(1,2)-1)),{' '},'XP in the tuft fluo group'))
display(strcat('there are',{' '},num2str((bb22(1,2)-1)/3),{' '},'XP in the tuft all group'))
display(strcat('there are',{' '},num2str((bb33(1,2)-1)/2),{' '},'XP in the tuft gain group'))
cd ..

%clear all

  
end



