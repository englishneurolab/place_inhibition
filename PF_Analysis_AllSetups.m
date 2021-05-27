%PF_Analysis_AllSetups
%For LT, VR, OF comparison analysis
%% Set Paths
    basePath = 'F:\Data\PlaceTuning_VR_OF_LT\m247\m247_210421_083423';
    basename = bz_BasenameFromBasepath(basePath);
    animalPath = 'F:\Data\AnimalSpecs_ExperimentalParadigms';
% Add paths
    addpath(genpath(basePath));
    addpath(genpath('E:\Reagan\Packages\npy-matlab'));
    addpath(genpath('E:\Reagan\Packages\Kilosort2'));
    addpath(genpath('E:\Reagan\Packages\utilities'));
    addpath(genpath('E:\Reagan\Packages\buzcode'));
    addpath(genpath('E:\Reagan\Packages\TStoolbox'));
    addpath(genpath('E:\Reagan\Code'));
    SetGraphDefaults;
%% Run ONLY Once 
% *DO HAVE TO OPEN* kilosort script in PF_Preprocessing_Pipeline and change path :)

% Run over kilosort, get spikes, lfp, analogin, digitalin, ripples
    PF_Preprocessing_Pipeline
% Make mat analysis files, mat files made by English lab code
    PF_Preprocessing_MakeMatFiles
%% Load Mat Files Commonly Used
    cd([basePath]);
% Load in start and stop times of each sleep and experimental segment
    load([basename '_TimeSegments.analysis.mat']);
    load([basename '_wheelTrials.analysis.mat']);
%% LFP Analysis - Define and Load Mat files
    lfp_channel = 21; %Change this per experiment
    cd([animalPath]);
    load('Maze_Characteristic_Analog_Positions.mat');
    cd([basePath]);
    load([basename '_analogin_VR.analysis.mat']);
%%  LFP Analysis - Power Spectra
% Power Spectra without fractals: Compares each setup to previous sleep, also compares all
% sleep parts to all experimental parts in one figure, compares all sleep
% in one figure, compares all experimental parts in one figure
    [IRASA] = getPowerSpectrum_PlaceInhibition(basePath, lfp_channel, Time, 'doLFPClean', false, 'doSplitLFP', false)
    %[runEpochs] = getRunEpochs(basePath, vel_ep);
    save([basename '_IRASA.analysis.mat'], 'IRASA');
% Subset of section IRASA - same amount of time 30 min (or specified
% below)
    sub_time_min = 30;%how many minutes to take from each segment
    sub_start_time_min = 20; %how many minutes after sleep to start your sub segment
    Time_sub.Sleep1.start = Time.Sleep1.start + (sub_start_time_min*60);
    Time_sub.Sleep1.stop = Time_sub.Sleep1.start + (sub_time_min*60);
    Time_sub.Sleep2.start = Time.Sleep2.start + (sub_start_time_min*60);
    Time_sub.Sleep2.stop = Time_sub.Sleep2.start + (sub_time_min*60);
    Time_sub.Sleep3.start = Time.Sleep3.start + (sub_start_time_min*60);
    Time_sub.Sleep3.stop = Time_sub.Sleep3.start + (sub_time_min*60);
    Time_sub.Sleep4.start = Time.Sleep4.start + (sub_start_time_min*60);
    Time_sub.Sleep4.stop = Time_sub.Sleep4.start + (sub_time_min*60);
    Time_sub.VR.start = Time.VR.start;
    Time_sub.VR.stop = Time_sub.VR.start + (sub_time_min*60);
    Time_sub.LT.start = Time.LT.start;
    Time_sub.LT.stop = Time_sub.LT.start + (sub_time_min*60);
    Time_sub.OF.start = Time.OF.start;
    Time_sub.OF.stop = Time_sub.OF.start + (sub_time_min*60);
    
    [IRASA_subset] = getPowerSpectrum_PlaceInhibition(basePath, lfp_channel, Time_sub, 'doLFPClean', false, 'doSplitLFP', false)
    %[runEpochs] = getRunEpochs(basePath, vel_ep);
    save([basename '_IRASA_sub.analysis.mat'], 'IRASA_subset');
    
% Velocity Power Spectra: Compares power spectra for VR - for data that has velocity over and under a certain threshold
%fix velocity code, runEpochs work?
    [IRASA_velocity] = getPowerSpectrum_Velocity(basePath, lfp_channel, Time.VR, 'doLFPClean', false, 'doSplitLFP', false);
%% LFP Analysis - Power Spec over many recordings
% this script requires you to have each session you want to look at already
% ran over the getPowerSpectrum_PlaceInhibition Script - needs some work
    getStdErrorPowerSpectra.m
%% LFP Analysis - PowerSpectra and Wavespec for specified periods
% Get wavespecs around different events - currently stim location, reward
% location, and grating change

% NOTE: Stim location changed from 1.5 to 1.1 on 5/25/21. 
% Experiments BEFORE this date, should use the variable
% 'stim_pos_old' - go into the script and change the input variable to
% such.
    getWavespecsAroundEvents_VR

% Ripples
    % Detect ripples bz_FindRipples
    % Validate in Neuroscope if ripples are correctly detected
%% Spiking Analysis - Define and load mat files
    cd([basePath]);
    load([basename '.spikes.cellinfo.mat']);
    load([basename '.cell_metrics.cellinfo.mat']);
    load([basename '_pulseEpochs_splitPerSetup.analysis.mat']);
    cell_idx = 1;
    exper_paradigm = 'VR'; %'LT' 'OF'
    pulseEpochs_exper = pulseEpch.VR; %'.OF' '.LT' pulseEpochs
    trial_exper = tr_ep; %trial start and stop times for exper
    
%% Spiking Analysis - Single Cell Characteristics for one Unit
% Creates a group of plots about one cell: autocorrelations in and out of
% pulse for specified experiment, raw waveform,raster, and PETH around pulse

% Plot raw waveform
     subplot(3,2,1);
     plot(.195*spikes.rawWaveform{cell_idx});
     xlabel('Time (ms)');
     ylabel('Amplitude (uV)');
     xticks([0 20 40 60 80 100 120 140]);
     xticklabels({'0','1','2','3','4','5','6','7'})
     title(['Cell ' num2str(cell_idx) ':Raw Waveform']);
     box off;
     axis square;
% Spike count Plot around opto stim
     subplot(3,2,3);
     getPSTHplots_PlaceInhibition(basePath, pulseEpochs_exper, exper_paradigm, cell_idx)
% Plot raster over cell for each trial - need to align to pulses
    subplot(3,2,4);
    getRasterPlots_PlaceInhibition(basePath, pulseEpochs_exper, exper_paradigm, cell_idx);  
% Plot CCG
     [ccginout] = getCCGinout(basePath, spikes.times, pulseEpochs_exper); %I changed this function to have spikes as an input\
     if ccginout.ccgIN >0
        subplot(3,2,5);
        plot(ccginout.ccgIN(:,cell_idx, cell_idx)); %in pulse
        title('CCG In Pulse');
        xlabel('Time(ms)');
        ylabel('Correlation');
        axis square;
     end
     if ccginout.ccgOUT > 0
        subplot(3,2,6);
        plot(ccginout.ccgOUT(:,cell_idx, cell_idx));  %out of pulse
        axis square;
        title('CCG Out Pulse');
        xlabel('Time(ms)');
        ylabel('Correlation');
        axis square;
     end     
  
%% Spiking Analysis - Single Cell characteristics for all units
% Gets out PETH and Raster around stim for each cell and saves each to a
% figure. Also calculate auto corr and cross corr for each cell and saves
% to pdf.

% Group all Interneurons and Pyramidal cells together (get indexes of each
% cell type)
    IN_count = 1;
    PYR_count = 1;
    for icell = 1:length(spikes.times)
        if (cell_metrics.putativeCellType{icell}(1:4) == 'Narr')
            IN_Cell(1,IN_count) = icell;
            IN_count = IN_count+1;
        elseif (cell_metrics.putativeCellType{icell}(1:4) == 'Pyra')
            PYR_Cell(1,PYR_count) = icell;
            PYR_count = PYR_count+1;
        end
    end
% Make a figure for each Interneuron: plot of PETH and Raster around stim
    for iUnit = 1:length(IN_Cell)
        fig = figure,
        % PSTH of one cell around opto stim time (can specify which pulses)
        subplot(2,1,1)
        getPSTHplots_PlaceInhibition(basePath, pulseEpochs_exper, exper_paradigm,IN_Cell(iUnit)) %'runAllInterneurons', True);
        % Plot Raster of one cell around opto stim time (can specify which pulses)
        subplot(2,1,2)
        getRasterPlots_PlaceInhibition(basePath, pulseEpochs_exper, exper_paradigm, IN_Cell(iUnit));
        % Plot autocorrelation of specified cell inside and outside opto stim
        % epochs
        cd([basePath '\Figures\OptoStim'])
        savefig(cd,['Raster/PETH IN Cell: ' num2str(IN_Cell(iUnit)]);
        delete(fig);
    end
% Make a figure for each Pyramidal cell: plot of PETH and Raster around stim
    for iUnit = 1:length(PYR_Cell)
        fig = figure,
        % PSTH of one cell around opto stim time (can specify which pulses)
        subplot(2,1,1)
        getPSTHplots_PlaceInhibition(basePath, pulseEpochs_exper, exper_paradigm,PYR_Cell(iUnit)) %'runAllInterneurons', True);
        % Plot Raster of one cell around opto stim time (can specify which pulses)
        subplot(2,1,2)
        getRasterPlots_PlaceInhibition(basePath, pulseEpochs_exper, exper_paradigm, PYR_Cell(iUnit));
        % Plot autocorrelation of specified cell inside and outside opto stim
        % epochs
        cd([basePath '\Figures\OptoStim'])
        savefig(cd,['Raster/PETH PYR Cell: ' num2str(PYR_Cell(iUnit)]);
        delete(fig);
    end
    cd(basePath);
    
% CCG: Auto corr in black and cross corr in blue (for each neuron a
% different figure)saved to a pdf
    ccg = ccginout.ccgOUT;
    t = ccginout.t;   
        for iUnit = 1:size(ccg,2)
            numPanels = ceil(sqrt(size(ccg,2)));
            
            figure
            set(gcf,'Position',[50 50 1200 800]);
            set(gcf,'PaperOrientation','landscape');
            
            for nPlot = 1:size(ccg,3)
                subplot(numPanels,numPanels,nPlot)
                if iUnit == nPlot
                    bar(t,ccg(:,iUnit,nPlot),'k')
                else
                    bar(t,ccg(:,iUnit,nPlot))
                end
                title(num2str(spikes.cluID(nPlot)));
            end
             unitStr = [basePath '\Figures\' num2str(iUnit)];
             savefig(gcf,[unitStr '.fig'])
             print(gcf,[unitStr '.pdf'],'-dpdf','-bestfit')
            append_pdfs([basePath '\Figures\allCCG.pdf'],[unitStr '.pdf'])
            delete([unitStr '.pdf'])
            close gcf
        end 
%% Virtual Reality - Load and define
    icell = 1;
    load('m247_210421_083423.spikes.cellinfo.mat');
    load('m247_210421_083423_analogin_VR.analysis.mat');
    
%% Virtual Reality Place Fields
    
%sanity check - do not quite get how
%     [SpkVoltage, SpkTime, VelocityatSpk] = rastersToVoltage(analogin_VR, spikes)
%     plot(SpkTime{2}, SpkVoltage{2})
   
% Get the corresponding voltage position of each spike timestamp
      [spkEpVoltIdx, spkEpVoltage] = getWheelPositionPerSpike(basePath, tr_ep);
% Singular place field over many trials (x = position, y = trials, color =
% spikes per spatial bin)
      [fig, fr_position] = getPlaceField_VR(basePath, icell, spkEpVoltage, tr_ep, len_ep, ts_ep, analogin_VR);
      savefig(['Cell' num2str(icell) '_PlaceField.fig'])
      delete(fig);

% Multiple place cells averaged over multiple trials (x = position, y =
% cell, color = averaged over trials spikes per spatial bin)
    getPopulationPlaceField_VR(basePath, tr_ep_all, len_ep, ts_ep_all, spikes, analogin_VR)
         
 % Colorful Raster of all cells over position (y trials, x position) dots different color for
 % different cells
    getRasterOverPosition(spikes, VR_BL1_Trials);
    getRasterOverPosition(spikes, VR_VR_Trials);
    getRasterOverPosition(spikes, VR_BL2_Trials);
        
%% Videos with spiking on top
    
    cell_idx = 1; %define what cell to map
    %%%%%%%%%%%%%%%%% OPEN FIELD %%%%%%%%%%%%%%%%%%%%%%%%
    cd([basePath '\Videos_CSVs']);
    v = VideoReader([basename(1:12) 'VideoOpenField.avi']);
    vw = VideoWriter('VideoOpenFieldMarked.avi','MOTION JPEG AVI');
    vw.FrameRate = v.FrameRate;
    open(vw);
    positionEstimate_file = csvread([basename(1:12) 'PositionEstimate.csv']);
    x = positionEstimate_file(:,1);
    y = positionEstimate_file(:,2);
    fid = fopen([basename(1:12) 'PositionTimestamps.csv']);
    C = textscan(fid,'%s','HeaderLines',8,'Delimiter',',','EndOfLine','\r\n','ReturnOnError',false);
    fclose(fid);
    positionTimes = C{1}(5:5:end);
    positionTimes = cell2mat(positionTimes);
    positionTimes = positionTimes(:,15:27);
    % for 21 session:  frames = 35831, estimates = 35372
  
    % Frames to which marker must be inserted
    %markFrames = spikes.times{cell_idx};
    %frameidx = 0;
    videoPlayer = vision.VideoPlayer;
    
    numFrames = 0;
    frameidx = 0;
    %get number of frames
     while hasFrame(v)
        frame = readFrame(v);
        frameidx = frameidx + 1;
        numFrames = numFrames + 1;
     end
    
    spikes_of = spikes.times{cell_idx}(find(spikes.times{cell_idx}> OF.start & spikes.times{cell_idx} < OF.stop));
    t = spikes_of(1):.001:spikes_of(end); %binning in 1 ms... 
    [spikes_logical, edges_spikes] = histcounts(spikes_of,t);
    nDataPoints = length(t); % Number of time points
    step = round((nDataPoints/numFrames));
    bin2video = 1:step:nDataPoints;
    spikesPerFrame = zeros(length(bin2video)-1,1)
    for ibin = 1:length(bin2video)-1
        spikesPerFrame(ibin,1) = sum(spikes_logical(1,(bin2video(ibin):bin2video(ibin+1))));
    end
    spikesPerFrame(spikesPerFrame(:,1) >=1,1) = 1;
    
 
    numFrames = 0;
    frameidx = 0;
     %videoWriter = 'VideoOpenField_cell_marked.avi'
   %  open(videoWriter)
   
    while hasFrame(v)
        frame = readFrame(v);
        frameidx = frameidx + 1;
        numFrames = numFrames + 1;
          
        if spikesPerFrame >= 1
            markedFrame = insertMarker(frame, [x(i) y(i)], '*','Size', 10, 'Color','r');
            videoPlayer(markedFrame);
            writeVideo(vw, markedFrame);
        else
            videoPlayer(frame);
             writeVideo(vw, frame)
        end
    end
    close(vw);
 %%%%%%%%%%%%%%%%%%% Open field with plot on one side and video on other%%
 %start and stop times need to line up for video and spikes
 % Setup the subplots
ax1 = subplot(2,1,1); % For video
ax2 = subplot(2,1,2); % For raster plot
% Setup VideoReader object
v = VideoReader([basename(1:12) 'VideoOpenField.avi']);
nFrames = v.Duration*v.FrameRate; % Number of frames
% Display the first frame in the top subplot
vidFrame = readFrame(v);
image(vidFrame, 'Parent', ax1);
ax1.Visible = 'off';
% Load the spiking data
%t = 0:0.01:v.Duration; % Cooked up for this example, use your actual data
spikes_of = spikes.times{cell_idx}(find(spikes.times{cell_idx}> OF.start & spikes.times{cell_idx} < OF.stop));
t = spikes_of(1):.001:spikes_of(end); %binning in 1 ms... 
[spikes_logical, edges_spikes] = histcounts(spikes_of,t);
nDataPoints = length(t); % Number of time points
step = round((nDataPoints/nFrames));
bin2video = 1:step:nDataPoints;
spikesPerFrame = zeros(length(bin2video)-1,1)
for ibin = 1:length(bin2video)-1
   spikesPerFrame(ibin,1) = sum(spikes_logical(1,(bin2video(ibin):bin2video(ibin+1))));
end
spikesPerFrame(spikesPerFrame(:,1) >=1,1) = 1;
    %bin spiking data into frame 

i = 2;
% Diplay the plot corresponds to the first frame in the bottom subplot
h = plot(ax2,bin2video(1:index(i)),cell_idx,'-k');
% Fix the axes
ax2.XLim = [t(1) t(end)];
ax2.YLim = [0 5];
% Animate
while hasFrame(v)
    pause(1/v.FrameRate);
    
    vidFrame = readFrame(v);
    image(vidFrame, 'Parent', ax1);
    ax1.Visible = 'off';
    
    i = i + 1;
    set(h,'YData',cell_idx, 'XData', bin2video(1:index(i)))
end
 %%%%%%%%%%%%%%%%%%% Linear Track %%%%%%%%%%%%%%%%%%%%%%%%%%%%
 %run over dlc - get estimated position with timestamps
 %have a raster plot above the video with cells on y axis, and position on
 %x axis - dots appear when the cell fires for 1 second
 

 %%%%%%%%%%%%%%%%%%% Virtual Reality %%%%%%%%%%%%%%%%%%%%%%%%%

 
%%
%1D Linear Track
    % First run DLC (also on Blink Light)

% Align video to intan
    Vtracking = AlignVidDLC(basepath,varargin);

% Make place fields again as per 1D VR STIM and NO STIM


% 2D STIM and NO STIM
    % still needs to be made
    [livePositionOF] = gtOpenFieldPosition(basePath, 'PositionEstimate.csv');
    TotalOFTime = OF.stop - OF.start;
    OFframespersec = length(livePositionOF.xpos)/TotalOFTime;
    openFieldPulseEpochs = pulseEpochs(:,:)> OF.start & pulseEpochs(:,:) < OF.stop;

%Define pyramidal cells
    % vector of spike timestamps, position, and position timestamps
    % everytime a cell fires, grab location,add 1 to the bin for that
    % location. then use imagesc(matrix of spikes per bin)


disp("kachow: you have solved the brain");
