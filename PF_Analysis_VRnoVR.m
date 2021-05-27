%PF_Analysis_VRnoVR
%% Run Every Time
% Define Recording session path
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
    VRnoVR_Preprocessing_MakeMatFiles
    
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
%%  LFP Analysis - Power Spec 
% Power Spectra: Compares each setup to previous sleep, also compares all
% sleep parts to all experimental parts in one figure, compares all sleep
% in one figure, compares all experimental parts in one figure
    [IRASA] = getPowerSpectrum_VRnoVR(basePath, lfp_channel, Time, 'doLFPClean', false, 'doSplitLFP', false)
    %[runEpochs] = getRunEpochs(basePath, vel_ep);
    save([basename '_IRASA_rz.mat'], 'IRASA');
% Subset of section IRASA - same amount of time 30 min (or specified
% below)
    sub_time_min = 30;%how many minutes to take from each segment
    sub_start_time_min = 20; %how many minutes after sleep to start your sub segment
    Time_sub.Sleep1.start = Sleep1_Time.start + (sub_start_time_min*60);
    Time_sub.Sleep1.stop = Time_sub.Sleep1.start + (sub_time_min*60);
    Time_sub.Sleep2.start = Sleep2_Time.start + (sub_start_time_min*60);
    Time_sub.Sleep2.stop = Time_sub.Sleep2.start + (sub_time_min*60);
    Time_sub.VR.start = VR_Time.start;
    Time_sub.VR.stop = Time_sub.VR.start + (sub_time_min*60);
    Time_sub.noVR.start = noVR_Time.start;
    Time_sub.noVR.stop = Time_sub.noVR.start + (sub_time_min*60);
    [IRASA_subset] = getPowerSpectrum_VRnoVR(basePath, lfp_channel, Time_sub, 'doLFPClean', false, 'doSplitLFP', false)
     save([basename '_IRASA_subset_rz.mat'], 'IRASA_subset');
% Velocity Power Spectra: Compares power spectra for VR - for data that has velocity over and under a certain threshold
%fix velocity code, runEpochs work?
    [IRASA_VR_velocity] = getPowerSpectrum_Velocity(basePath, lfp_channel, Time.VR, 'doLFPClean', false, 'doSplitLFP', false);
    [IRASA_noVR_velocity] = getPowerSpectrum_Velocity(basePath, lfp_channel, Time.noVR, 'doLFPClean', false, 'doSplitLFP', false);
%% Velocity analysis
    
    [vel_VR] = getVelocity(analogin_VR,'circDisk',236, 'doFigure', true);%236cm/unity lap
    mean_vel_VR = mean(vel_VR.vel_cm_s);

    [vel_noVR] = getVelocity(analogin_noVR,'circDisk',236, 'doFigure', true);%236cm/unity lap

    [vel] = getVelocity(analogin,'circDisk',236, 'doFigure', true);%236cm/unity lap


    save('Velocity_rz.mat','vel_VR','vel_noVR');

    [runEpochs_VR] = getRunEpochs(basePath, vel_VR);

    [runEpochs_noVR] = getRunEpochs(basePath, vel_noVR);
%% LFP Analysis - WaveSpec - VR
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
%% LFP Analysis - WaveSpec - NO VR
     getWavespecsAroundEvents_noVR
  
% Ripples
    % Detect ripples bz_FindRipples
    % Validate in Neuroscope if ripples are correctly detected
%% Spiking Analysis - Define and load mat files
    cd([basePath]);
    load([basename '.spikes.cellinfo.mat']);
    load([basename '.cell_metrics.cellinfo.mat']);
    load([basename '_pulseEpochs_splitPerSetup.analysis.mat']);
    cell_idx = 1;
    exper_paradigm = 'VR'; 
    pulseEpochs_exper = pulseEpch.VR; 
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
    icell_idx = 1;
    load('m247_210421_083423.spikes.cellinfo.mat');
    load('m247_210421_083423_analogin_VR.analysis.mat');
    
        %% Virtual Reality - Place Fields
%sanity check - do not quite get how
%     [SpkVoltage, SpkTime, VelocityatSpk] = rastersToVoltage(analogin_VR, spikes)
%     plot(SpkTime{2}, SpkVoltage{2})
    
% Get the corresponding voltage position of each spike timestamp
      [spkEpVoltIdx] = getWheelPositionPerSpike(basePath, tr_ep);
% Singular place field over many trials (x = position, y = trials, color =
% spikes per spatial bin) **FIGURE OUT CM OF TRACK VR*
      [fig, fr_position] = getPlaceField_VR(basePath, cell_idx, spkEpVoltage, tr_ep, len_ep, ts_ep, analogin_VR);
% Multiple place cells averaged over multiple trials (x = position, y =
% cell, color = averaged over trials spikes per spatial bin)
      getPopulationPlaceField_VR(basePath, tr_ep_all, len_ep, ts_ep_all, spikes, analogin_VR)
       
 % Colorful Raster of all cells over position (y trials, x position) dots different color for
 % different cells
    getRasterOverPosition(spikes, VR_BL1_Trials);
    getRasterOverPosition(spikes, VR_VR_Trials);
    getRasterOverPosition(spikes, VR_BL2_Trials);