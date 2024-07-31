
%% Analysis of electrophysiological data recorded via Intan RSD2000 and an implanted ECoG array from the rat medial prefrontal cortex

%options/tasks

%pre-processing
filterData = 0; %filter Data (1) or not (0)
epochData = 0; %cut files into single time intervals (1) or not (0)
baselineCorrecture = 0; %remove baseline (1) or not (0)
artifactRejection = 0; %remove epochs with artifacts (1) or not (0)
averageData = 0; %average epochs for each trigger and each subject (1) or not (0)

%analysis & visualisation
plotAverage = 0; %plot averaged ERP data for each trigger and single subject (1) or not (0)
peakLatencies = 0; %find peak latencies and peak amplitudes of ERP in defined time windows (1) or not (0)
TimeFreq = 0; %calculate and plot time-frequency decomposition of ERO of averaged epochs for each rat(1) or not (0)
plotGrandAverage = 0; %average and plot ERP and ERO data for each trigger and all subjects (1) or not (0)

%directories

%Controls
eeglabPath = 'C:\eeglab_current\eeglab2019_0';
eegAnalysisDir = 'C:\\eeglab_current\\eeglab2019_0\\Data\\Controls\\sham\\';
eegAnalysisDir_filtered = 'C:\\eeglab_current\\eeglab2019_0\\Data\\Controls\\sham\\Control_sham_filtered';
eegAnalysisDir_epochs = 'C:\\eeglab_current\\eeglab2019_0\\Data\\Controls\\sham\\Control_sham_epochs';
eegAnalysisDir_artifacts = 'C:\\eeglab_current\\eeglab2019_0\\Data\\Controls\\sham\\Control_sham_artifacts';
eegAnalysisDir_average = 'C:\\eeglab_current\\eeglab2019_0\\Data\\Controls\\sham\\Control_sham_average';
%likewise for treatment groups

%parameters
RatID = ['12_sham']; %exemplary data

srate = 3000; %sampling rate in Hz
channelNames2plot = {'f3';'fz';'f4';'c3';'cz';'c4';'p3';'pz';'p4'}; %channels to plot, if empty: plot all channels
epochRange = [-100 700]; %epoch range relative to sound onset in ms (with trigger at time zero)

addpath(eeglabPath);

if filterData
    for iRat = 1:size(RatID,1)  
    %load data in eeglab format
        [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        EEG = pop_loadset('filename',['Rat' RatID(iRat,:) '.set'],'filepath',eegAnalysisDir);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    %filter settings: windowed sinc FIR filter
    %passband: 0.1 - 45 Hz
    %0.001 passband deviation/ripple (= -60 dB)
    %Kaiser beta = 5.65
    %0.2 Hz transition bandwith
        EEG = pop_firws(EEG, 'fcutoff', [0.1 45], 'ftype', 'bandpass', 'wtype', 'kaiser', 'warg', 5.65326, 'forder', 54330, 'minphase', 0);
    %save filtered file with new name
       [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'savenew',['Rat' RatID(iRat,:) '_filtered'],'gui','off'); 
       EEG = eeg_checkset( EEG );
       EEG = pop_saveset( EEG, 'filename',['Rat' RatID(iRat,:) '_filtered.set'],'filepath', eegAnalysisDir_filtered);
       [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
    end
end

%epoch separately for standards and deviants
if epochData
    %standard
     for iRat = 1:size(RatID,1) 
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename',['Rat' RatID(iRat,:) '_filtered.set'],'filepath',eegAnalysisDir_filtered);
    [ALLEEG, EEG, ~] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );
    EEG = pop_epoch( EEG, {  '1'  },[-0.1         0.7], 'newname', ['Rat' RatID(iRat,:) '_standard'], 'epochinfo', 'yes');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
    EEG = eeg_checkset( EEG );
    if baselineCorrecture
    EEG = pop_rmbase( EEG, [-100    0],[]); %remove baseline
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 
    end
    %save file
    EEG = eeg_checkset( EEG );
    EEG = pop_saveset( EEG, 'filename',['Rat' RatID(iRat,:) '_standard.set'],'filepath',eegAnalysisDir_epochs);
     end
     
    %deviant
     for iRat = 1:size(RatID,1) 
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename',['Rat' RatID(iRat,:) '_filtered.set'],'filepath',eegAnalysisDir_filtered);
    [ALLEEG, EEG, ~] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );
    EEG = pop_epoch( EEG, {  '2'  },[-0.1         0.7], 'newname', ['Rat' RatID(iRat,:) '_deviant'], 'epochinfo', 'yes');
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
    EEG = eeg_checkset( EEG );
    if baselineCorrecture
    EEG = pop_rmbase( EEG, [-100    0],[]); %remove baseline
    [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 
    end
    %save file
    EEG = eeg_checkset( EEG );
    EEG = pop_saveset( EEG, 'filename',['Rat' RatID(iRat,:) '_deviant.set'],'filepath',eegAnalysisDir_epochs);
     end
end

%Artifact rejection of epoched data using delta method
%eeg_rejdelta.m by A. Widmann (2006): https://github.com/widmann/erptools/blob/master/eeg_rejdelta.m

deltaThresh = 600;
if artifactRejection
    for iRat = 1:size(RatID,1) 
%standards
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename',['Rat' RatID(iRat,:) '_standard.set'],'filepath',eegAnalysisDir_epochs);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );

    EEG = eeg_rejdelta(EEG,'thresh',deltaThresh); %mark epochs
    EEG = eeg_rejsuperpose(EEG,1,1,1,1,1,1,1,1); %join all results
 
    %plot for visual inspection
    EEG.reject.rejmanual = EEG.reject.rejglobal; %copy marked epochs for plotting
    EEG = eeg_checkset(EEG);
    pop_eegplot(EEG,1,1,1); %plot - channel data(scroll)
    input('check, (un-)mark epochs and confirm with ENTER');
    EEG = pop_rejepoch(EEG,find(EEG.reject.rejglobal), 0); %reject
     
    %save file with new name
    EEG = eeg_checkset( EEG );
    EEG = pop_saveset( EEG, 'filename',['Rat' RatID(iRat,:) '_standard_artifacts.set'],'filepath',eegAnalysisDir_artifacts);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); 
    
% deviants
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename',['Rat' RatID(iRat,:) '_deviant.set'],'filepath',eegAnalysisDir_epochs);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );

    EEG = eeg_rejdelta(EEG,'thresh',deltaThresh); %mark epochs
    EEG = eeg_rejsuperpose(EEG,1,1,1,1,1,1,1,1); %join all results
 
    %plot for visual inspection
    EEG.reject.rejmanual = EEG.reject.rejglobal; %copy marked epochs for plotting
    EEG = eeg_checkset(EEG);
    pop_eegplot(EEG,1,1,1); %plot - channel data(scroll)
    input('check, (un-)mark epochs and confirm with ENTER');
    EEG = pop_rejepoch(EEG,find(EEG.reject.rejglobal), 0); %reject
     
    %save file with new name
    EEG = eeg_checkset( EEG );
    EEG = pop_saveset( EEG, 'filename',['Rat' RatID(iRat,:) '_deviant_artifacts.set'],'filepath',eegAnalysisDir_artifacts);
    [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET); 
    end
end

if averageData
    
%standards 
  for iRat = 1:size(RatID,1)  
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename',['Rat' RatID(iRat,:) '_standard_artifacts.set'],'filepath',eegAnalysisDir_artifacts);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    singleSubjectERP = mean(EEG.data,3);
    EEG.data = singleSubjectERP;
    EEG = pop_saveset( EEG, 'filename',['Rat' RatID(iRat,:) '_standard_average.set'],'filepath',eegAnalysisDir_average);
  end
 
% deviants
  for iRat = 1:size(RatID,1)  
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename',['Rat' RatID(iRat,:) '_deviant_artifacts.set'],'filepath',eegAnalysisDir_artifacts);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    singleSubjectERP = mean(EEG.data,3);
    EEG.data = singleSubjectERP;
    EEG = pop_saveset( EEG, 'filename',['Rat' RatID(iRat,:) '_deviant_average.set'],'filepath',eegAnalysisDir_average);
  end
end

if plotAverage
for iRat = 1:size(RatID,1)  
    
    channelNames2plot = {'f3';'fz';'f4';'c3';'cz';'c4';'p3';'pz';'p4'};

        EEG = pop_loadset('filename',['Rat12_sham_standard_average.set'],'filepath',eegAnalysisDir_average);
        %find indices of channels to plot
        if isempty(channelNames2plot)
            channels2plot = 1:length(EEG.chanlocs); %plot all channels
        else
            channels2plot = zeros(1,size(channelNames2plot,1));
            for ne = 1:size(channelNames2plot,1)
                disp(' ');
                %find relevant channel
                iChannel = strmatch(channelNames2plot{ne}, {EEG.chanlocs(:).labels});
                %mark for plotting
                switch numel(iChannel)
                    case 0
                        disp(['requested channel ' channelNames2plot{ne} ' not found']);
                        disp('cannot plot this channel');
                        error('try again');
                    case 1
                        disp(['choosing channel number ' num2str(iChannel) ' (' channelNames2plot{ne} ') for plotting']);
                        channels2plot(ne) = iChannel;
                    otherwise
                        disp(['more than one channel ' channelNames2plot{ne} ' found']);
                        disp(['cannot unambiguously plot']);
                        error('try again');
                end
            end %loop for channels to plot
        end

 %get the data
    EEGsta = pop_loadset('filename',['Rat' RatID(iRat,:) '_standard_average.set'],'filepath',eegAnalysisDir_average);
    EEGdev = pop_loadset('filename',['Rat' RatID(iRat,:) '_deviant_average.set'],'filepath',eegAnalysisDir_average);
    EEGdiff = EEGsta;
    EEGdiff.data = EEGdev.data - EEGsta.data;
    EEG = pop_saveset(EEGdiff,'filename',['Rat' RatID(iRat,:) '_diff_average.set'],'filepath',eegAnalysisDir_average);
    figure; hold on;
      set(gcf,'Name',['Single ERP average of subject:'   'Rat' RatID(iRat,:)]);
  for iChannel = 1:numel(channels2plot)
        minmaxAmpl = [-80 80]; %minimum/maximum range for plot in microVolt
        subplot(ceil(sqrt(numel(channels2plot))),ceil(sqrt(numel(channels2plot))),iChannel); hold on;
        text(0.8*EEGsta.times(end),0.8*minmaxAmpl(1),EEG.chanlocs(channels2plot(iChannel)).labels); %write channel name
        axis([EEGsta.times(1) EEGsta.times(end) minmaxAmpl]);
        xlabel('Time (ms)');
        ylabel('Voltage (µV)');
        %plot standards
        plot(EEGsta.times,EEGsta.data(channels2plot(iChannel),:,:),'b'); %standard average of subjects
        %plot deviants
        plot(EEGdev.times,EEGdev.data(channels2plot(iChannel),:,:),'r'); %deviant average of subjects
        %plot difference wave
        plot(EEGdiff.times,EEGdiff.data(channels2plot(iChannel),:,:),'k'); %difference average of subjects
        %plot zero lines
        hl = line([EEGsta.times(1) EEGsta.times(end)],[0 0]);
        vl = line([0 0],minmaxAmpl);
        set(hl,'Color',[0 0 0],'LineStyle',':','linewidth',0.5);
        set(vl,'Color',[0 0 0],'LineStyle',':','linewidth',0.5);
  end
  legend({'Standard';'Deviant';'Deviant minus Standard'});
end
end        
    
    
if peakLatencies
    for iRat = 1:size(RatID,1)  
 %find peak latencies in a data-driven manner
  disp(['Rat:' {RatID(iRat,:)}]); 
    comps = {'P1';'N1';'P2';'N2';'P3'}; 
    searchWindows = [
        40 70 1; %P1 (positive)
        60 105 -1; %N1 (negative)
        105 125 1; %P2 (positive)
        130 190 -1; %N2 (negative)
        200 450 1; %P3 (positive)
        ];
    peakLatMs = zeros(size(searchWindows,1),1);
    compRange = zeros(size(searchWindows,1),2);
    
%standards  
  figure; hold on;
      set(gcf,'Name',['Single standard ERP average of subject:'   'Rat' RatID(iRat,:)]);
  for iChannel = 1:numel(channels2plot)
        minmaxAmpl = [-80 80]; %minimum/maximum range for plot in microVolt
        subplot(ceil(sqrt(numel(channels2plot))),ceil(sqrt(numel(channels2plot))),iChannel); hold on;
        text(0.8*EEGsta.times(end),0.8*minmaxAmpl(1),EEG.chanlocs(channels2plot(iChannel)).labels); %write channel name
        axis([EEGsta.times(1) EEGsta.times(end) minmaxAmpl]);
        xlabel('Time (ms)');
        ylabel('Voltage (µV)');
        %plot standards
        plot(EEGsta.times,EEGsta.data(channels2plot(iChannel),:,:),'Color',[0 0 1]); %standard average of subjects
        
        hl = line([EEGsta.times(1) EEGsta.times(end)],[0 0]);
        vl = line([0 0],minmaxAmpl);
        set(hl,'Color',[0 0 0],'LineStyle',':','linewidth',0.5);
        set(vl,'Color',[0 0 0],'LineStyle',':','linewidth',0.5);
        
    disp(['Channel:' {EEG.chanlocs(channels2plot(iChannel)).labels}]);
    try
    
    for iCo = 1:size(searchWindows,1)
        searchPnts = (searchWindows(iCo,1:2)-epochRange(1))/1000*srate+1;
        LatData = EEGsta.data(channels2plot(iChannel),:,:);
        peakAmp = max(searchWindows(iCo,3)*LatData(:,searchPnts(1):searchPnts(2)));
        peakLatPnts = find(LatData(:,searchPnts(1):searchPnts(2))==searchWindows(iCo,3)*peakAmp);
        if numel(peakLatPnts) > 1
            disp('more than one maximum found');
            error('please check data and try again');
        end
        peakLatPnts = peakLatPnts+searchPnts(1)-1;
        peakLatMs(iCo) = (peakLatPnts-1)/srate*1000 + epochRange(1); %convert to ms
        disp([comps{iCo,:} ' standard component peak at ' num2str(peakLatMs(iCo)) ' ms']);
        disp('Peakamplitude:');
        disp(peakAmp);
        %for visual confirmation, mark max. voltage value within ERP search
        %window
        %adjust ERP search windows if peak amplitude has not been found
        
        %since standard sounds did not induce pronounced ERP amplitudes,
        %peak amplitudes were derived from the deviant-minus-standard data
        %plot(peakLatMs(iCo),peakAmp,'k*') 
    end
    end
  end

  %deviants
  figure; hold on;
      set(gcf,'Name',['Single deviant ERP average of subject:'   'Rat' RatID(iRat,:)]);
  for iChannel = 1:numel(channels2plot)
        minmaxAmpl = [-80 80]; %minimum/maximum range for plot in microVolt
        subplot(ceil(sqrt(numel(channels2plot))),ceil(sqrt(numel(channels2plot))),iChannel); hold on;
        text(0.8*EEGdev.times(end),0.8*minmaxAmpl(1),EEG.chanlocs(channels2plot(iChannel)).labels); %write channel name
        axis([EEGdev.times(1) EEGdev.times(end) minmaxAmpl]);
        xlabel('Time (ms)');
        ylabel('Voltage (µV)');
        %plot deviants
        plot(EEGdev.times,EEGdev.data(channels2plot(iChannel),:,:),'Color',[1 0 0]); %deviant average of subjects
        
        hl = line([EEGdev.times(1) EEGdev.times(end)],[0 0]);
        vl = line([0 0],minmaxAmpl);
        set(hl,'Color',[0 0 0],'LineStyle',':','linewidth',0.5);
        set(vl,'Color',[0 0 0],'LineStyle',':','linewidth',0.5);
        
    disp(['Channel:' {EEG.chanlocs(channels2plot(iChannel)).labels}]);
    try
    
    for iCo = 1:size(searchWindows,1)
        searchPnts = (searchWindows(iCo,1:2)-epochRange(1))/1000*srate+1;
        LatData = EEGdev.data(channels2plot(iChannel),:,:);
        peakAmp = max(searchWindows(iCo,3)*LatData(:,searchPnts(1):searchPnts(2)));
        peakLatPnts = find(LatData(:,searchPnts(1):searchPnts(2))==searchWindows(iCo,3)*peakAmp);
        if numel(peakLatPnts) > 1
            disp('more than one maximum found');
            error('please check data and try again');
        end
        peakLatPnts = peakLatPnts+searchPnts(1)-1;
        peakLatMs(iCo) = (peakLatPnts-1)/srate*1000 + epochRange(1); %convert to ms
        disp([comps{iCo,:} ' deviant component peak at ' num2str(peakLatMs(iCo)) ' ms']);
        disp('Peakamplitude:');
        disp(peakAmp);
        %for visual confirmation, mark max. voltage value within ERP search
        %window
        %adjust ERP search windows if peak amplitude has not been found
        
        %since standard sounds did not induce pronounced ERP amplitudes,
        %peak amplitudes were derived from the deviant-minus-standard data
        %plot(peakLatMs(iCo),peakAmp,'k*')
    
    end
    end
  end
  
  %difference
  figure; hold on;
      set(gcf,'Name',['Single ERP difference average of subject:'   'Rat' RatID(iRat,:)]);
  for iChannel = 1:numel(channels2plot)
        minmaxAmpl = [-80 80]; %minimum/maximum range for plot in microVolt
        subplot(ceil(sqrt(numel(channels2plot))),ceil(sqrt(numel(channels2plot))),iChannel); hold on;
        text(0.8*EEGdiff.times(end),0.8*minmaxAmpl(1),EEG.chanlocs(channels2plot(iChannel)).labels); %write channel name
        axis([EEGdiff.times(1) EEGdiff.times(end) minmaxAmpl]);
        xlabel('Time (ms)');
        ylabel('Voltage (µV)');
        %plot difference
        plot(EEGdiff.times,EEGdiff.data(channels2plot(iChannel),:,:),'Color',[0 0 0]); %difference average of subjects
        
        hl = line([EEGdiff.times(1) EEGdiff.times(end)],[0 0]);
        vl = line([0 0],minmaxAmpl);
        set(hl,'Color',[0 0 0],'LineStyle',':','linewidth',0.5);
        set(vl,'Color',[0 0 0],'LineStyle',':','linewidth',0.5);

    disp(['Channel:' {EEG.chanlocs(channels2plot(iChannel)).labels}]);
    try
    
    for iCo = 1:size(searchWindows,1)
        searchPnts = (searchWindows(iCo,1:2)-epochRange(1))/1000*srate+1;
        LatData = EEGdiff.data(channels2plot(iChannel),:,:);
        peakAmp = max(searchWindows(iCo,3)*LatData(:,searchPnts(1):searchPnts(2)));
        peakLatPnts = find(LatData(:,searchPnts(1):searchPnts(2))==searchWindows(iCo,3)*peakAmp);
        if numel(peakLatPnts) > 1
            disp('more than one maximum found');
            error('please check data and try again');
        end
        peakLatPnts = peakLatPnts+searchPnts(1)-1;
        peakLatMs(iCo) = (peakLatPnts-1)/srate*1000 + epochRange(1); %convert to ms
        disp([comps{iCo,:} ' difference component peak at ' num2str(peakLatMs(iCo)) ' ms']);
        disp('Peakamplitude:');
        disp(peakAmp);
        peakAmp2(iCo)=peakAmp;
        %for visual confirmation, mark max. voltage value within ERP search
        %window
        %adjust ERP search windows if peak amplitude has not been found
        
        %since standard sounds did not induce pronounced ERP amplitudes,
        %peak amplitudes were derived from the deviant-minus-standard data
        plot(peakLatMs(iCo),peakAmp,'k*')
    
    end
    end
    T_diff(iChannel,1)= channels2plot(iChannel)';
    T_diff(iChannel,2:6)= peakLatMs.';
    T_diff(iChannel,7:11)= peakAmp2.';
  end
   input('check data and confirm with ENTER');
    end
end

    %write to excel file
    filename_ERP = sprintf('%s_ERP.xlsx', RatID);
    writematrix(T_diff,filename_ERP,'Sheet',1,'Range','A1');

if TimeFreq
for iRat = 1:size(RatID,1)  
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    EEG = pop_loadset('filename',['Rat' RatID(iRat,:) '_diff_average.set'],'filepath',eegAnalysisDir_average);
    [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
    EEG = eeg_checkset( EEG );
   
    channelNames2plot = {'f3';'fz';'f4';'c3';'cz';'c4';'p3';'pz';'p4'};
    
        if isempty(channelNames2plot)
            channels2plot = 1:length(EEG.chanlocs); %plot all channels
        else
            channels2plot = zeros(1,size(channelNames2plot,1));
            for ne = 1:size(channelNames2plot,1)
                disp(' ');
                %find relevant channel
                iChannel = strmatch(channelNames2plot{ne}, {EEG.chanlocs(:).labels});
                %mark for plotting
                switch numel(iChannel)
                    case 0
                        disp(['requested channel ' channelNames2plot{ne} ' not found']);
                        disp('cannot plot this channel');
                        error('try again');
                    case 1
                        disp(['choosing channel number ' num2str(iChannel) ' (' channelNames2plot{ne} ') for plotting']);
                        channels2plot(ne) = iChannel;
                    otherwise
                        disp(['more than one channel ' channelNames2plot{ne} ' found']);
                        disp(['cannot unambiguously plot']);
                        error('try again');
                end
            end %loop for channels to plot
        end
     
    figure, hold on;
    set(gcf,'Name',['ERO of subject:'   'Rat' RatID(iRat,:)]);
    
    for iChannel = 1:numel(channels2plot)
        try
        EEG = eeg_checkset( EEG );        
        subplot(ceil(sqrt(numel(channels2plot))),ceil(sqrt(numel(channels2plot))),iChannel); hold on;

        %dB Power values
        [ersp itc powbase times frequencies] = pop_newtimef(EEG, 1, channels2plot(iChannel), [-100  700], [0] , 'topovec', 1, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'baseline',[NaN], 'freqs', [1 45],'erspmax', [0 30],'plotitc' , 'off','plotphase', 'off', 'scale', 'log', 'ntimesout', 400, 'padratio', 64);
 
        title(channelNames2plot(iChannel));
    
    %frequency bands: delta=1-4, theta=4-8, alpha=8-12, beta=12-30, gamma=30-45 Hz.
     delta = find(frequencies>=0 & frequencies<4);
     theta = find(frequencies>=4 & frequencies<8);
     alpha = find(frequencies>=8 & frequencies<12);
     beta  = find(frequencies>=12 & frequencies<30);
     gamma = find(frequencies>=30 & frequencies<=45);
   
    %Max band powers
     deltaPowerMax = max(max(ersp(delta,:)));
     thetaPowerMax = max(max(ersp(theta,:)));
     alphaPowerMax = max(max(ersp(alpha,:)));
     betaPowerMax  = max(max(ersp(beta,:)));
     gammaPowerMax = max(max(ersp(gamma,:)));
    
    %Time and freq with max power within each band 
     [xdelta,ydelta]=find(ersp==max(max(ersp(delta,:))));
     maxTimedelta=times(:,ydelta);
     maxFreqdelta=frequencies(:,xdelta);
     
     [xtheta,ytheta]=find(ersp==max(max(ersp(theta,:))));
     maxTimetheta=times(:,ytheta);
     maxFreqtheta=frequencies(:,xtheta);
     
     [xalpha,yalpha]=find(ersp==max(max(ersp(alpha,:))));
     maxTimealpha=times(:,yalpha);
     maxFreqalpha=frequencies(:,xalpha);
     
     [xbeta,ybeta]=find(ersp==max(max(ersp(beta,:))));
     maxTimebeta=times(:,ybeta);
     maxFreqbeta=frequencies(:,xbeta);
     
     [xgamma,ygamma]=find(ersp==max(max(ersp(gamma,:))));
     maxTimegamma=times(:,ygamma);
     maxFreqgamma=frequencies(:,xgamma);
     
    %Time and freq with max power over whole frequency spectrum 
     [x,y]=find(ersp==max(max(ersp)));
     maxTime=times(:,y);
     maxFreq=frequencies(:,x);
        end
     bandspectra(iChannel, 1) = channels2plot(iChannel)';
     bandspectra(iChannel,2:6) = [deltaPowerMax thetaPowerMax alphaPowerMax betaPowerMax gammaPowerMax].';
     bandspectra(iChannel,7:16) = [maxTimedelta maxFreqdelta maxTimetheta maxFreqtheta maxTimealpha maxFreqalpha maxTimebeta maxFreqbeta maxTimegamma maxFreqgamma].';
     bandspectra(iChannel,17:19) = [max(max(ersp)) maxTime maxFreq];
    end
end
end
              
    %write to excel file
    filename_ERO = sprintf('%s_ERO.xlsx', RatID);
    writematrix(bandspectra,filename_ERO,'Sheet',1,'Range','A1');

if plotGrandAverage
      %define channels for plotting
      channelNames2plot = {'f3';'fz';'f4';'c3';'cz';'c4';'p3';'pz';'p4'}; %channels to plot, if empty: plot all channels
  
      [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
        EEG = pop_loadset('filename',['Rat12_sham_standard_average.set'],'filepath',eegAnalysisDir_average);
        [ALLEEG, EEG, CURRENTSET] = eeg_store( ALLEEG, EEG, 0 );
        %find indices of channels to plot
        if isempty(channelNames2plot)
            channels2plot = 1:length(EEG.chanlocs); %plot all channels
        else
            channels2plot = zeros(1,size(channelNames2plot,1));
            for ne = 1:size(channelNames2plot,1)
                disp(' ');
                %find relevant channel
                iChannel = strmatch(channelNames2plot{ne}, {EEG.chanlocs(:).labels});
                %mark for plotting
                switch numel(iChannel)
                    case 0
                        disp(['requested channel ' channelNames2plot{ne} ' not found']);
                        disp('cannot plot this channel');
                        error('try again');
                    case 1
                        disp(['choosing channel number ' num2str(iChannel) ' (' channelNames2plot{ne} ') for plotting']);
                        channels2plot(ne) = iChannel;
                    otherwise
                        disp(['more than one channel ' channelNames2plot{ne} ' found']);
                        disp(['cannot unambiguously plot']);
                        error('try again');
                end
            end %loop for channels to plot
        end

       % standard
        grandAverageERP_standard = zeros(size(EEG.data,1),size(EEG.data,2),size(RatID,1)); %initialize
        for iRat = 1:size(RatID,1)
            %load
            EEG = pop_loadset('filename',['Rat' RatID(iRat,:) '_standard_average.set'],'filepath',eegAnalysisDir_average);
            grandAverageERP_standard(:,:,iRat) = mean(EEG.data,3,'omitnan'); %average across epochs
        end
        grandAverageERP_standard_new=zeros(size(EEG.data,1),size(EEG.data,2));
        grandAverageERP_standard_new=mean(grandAverageERP_standard,3,'omitnan');
        EEG.data = grandAverageERP_standard_new;
        EEG = pop_saveset( EEG, 'filename',['Control_standard_average.set'],'filepath',eegAnalysisDir_average);
        
        % deviant
        grandAverageERP_deviant = zeros(size(EEG.data,1),size(EEG.data,2),size(RatID,1)); %initialize
        for iRat = 1:size(RatID,1)
            %load
            EEG = pop_loadset('filename',['Rat' RatID(iRat,:) '_deviant_average.set'],'filepath',eegAnalysisDir_average);
            grandAverageERP_deviant(:,:,iRat) = mean(EEG.data,3,'omitnan'); %average across epochs
        end
        grandAverageERP_deviant_new=zeros(size(EEG.data,1),size(EEG.data,2));
        grandAverageERP_deviant_new=mean(grandAverageERP_deviant,3,'omitnan');
        EEG.data = grandAverageERP_deviant_new;
        EEG = pop_saveset( EEG, 'filename',['Control_deviant_average.set'],'filepath',eegAnalysisDir_average);
        
    %get the data, calculate difference wave
    EEGsta = pop_loadset('filename',['Control_standard_average.set'],'filepath',eegAnalysisDir_average);
    EEGdev = pop_loadset('filename',['Control_deviant_average.set'],'filepath',eegAnalysisDir_average);
    EEGdiff = EEGsta;
    EEGdiff.data = EEGdev.data - EEGsta.data;
    EEG = pop_saveset(EEGdiff,'filename',['Control_diff_average.set'],'filepath',eegAnalysisDir_average);
    figure; hold on;
    set(gcf,'Name',['Grand average ERP of Controls']);
    for iChannel = 1:numel(channels2plot)
        minmaxAmpl = [-40 40]; %minimum/maximum range for plot in microVolt
        subplot(ceil(sqrt(numel(channels2plot))),ceil(sqrt(numel(channels2plot))),iChannel); hold on;
        text(0.8*EEGsta.times(end),0.8*minmaxAmpl(1),EEG.chanlocs(channels2plot(iChannel)).labels); %write channel name
        axis([EEGsta.times(1) EEGsta.times(end) minmaxAmpl]);
        set(gca,'ytick',[-40:20:40]);
        xlabel('Time (ms)');
        ylabel('Voltage (µV)');
        %plot standards
        plot(EEGsta.times,EEGsta.data(channels2plot(iChannel),:,:),'b');
        %plot deviants
        plot(EEGdev.times,EEGdev.data(channels2plot(iChannel),:,:),'r');
        %plot difference wave
        plot(EEGdiff.times,EEGdiff.data(channels2plot(iChannel),:,:),'k');
        %plot zero lines
        hl = line([EEGsta.times(1) EEGsta.times(end)],[0 0]);
        vl = line([0 0],minmaxAmpl);
        set(hl,'Color',[0 0 0],'LineStyle',':','linewidth',0.5);
        set(vl,'Color',[0 0 0],'LineStyle',':','linewidth',0.5);
       
    figure, hold on;
    set(gcf,'Name',['Grand average ERO of Controls']);
    
    for iChannel = 1:numel(channels2plot)
        try
        EEG = eeg_checkset( EEG );        
        subplot(ceil(sqrt(numel(channels2plot))),ceil(sqrt(numel(channels2plot))),iChannel); hold on;

        %dB Power values
        [ersp itc powbase times frequencies] = pop_newtimef(EEG, 1, channels2plot(iChannel), [-100  700], [0] , 'topovec', 1, 'elocs', EEG.chanlocs, 'chaninfo', EEG.chaninfo, 'baseline',[NaN], 'freqs', [1 45],'erspmax', [0 30],'plotitc' , 'off','plotphase', 'off', 'scale', 'log', 'ntimesout', 400, 'padratio', 64);
 
        title(channelNames2plot(iChannel));
        end
    end
    end   
end
