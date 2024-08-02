%Script contributed by D. Afanasenkau (2021): https://github.com/Dimarfin

%Load board_adc_data.mat from Intan recording file then
%run in command line: event = FindMarkers_test(board_adc_data);
%and then EEG.event=event
function event = FindMarkers(sound)
sound=board_adc_data;
plot(sound)
hold on
    %sound=smooth(sound,10)';  %Switch it off if the noise is low 
    %plot(sound)
    Smax=max(sound);
    
    %Find indices of all sound trains
    TrainsAll_index=find(sound>0.2*Smax);% 0.2*Smax is a threshold to define both sound types
    a=diff(TrainsAll_index);
    b=horzcat([1],a);
    c=find(b>100);%100 - interval between steps, Dt/dt where Dt - time between sounds, dt - sampling rate
    MarkersAll=horzcat(TrainsAll_index(1),TrainsAll_index(c));
    plot(MarkersAll,0.3*ones(size(board_adc_data(MarkersAll))),'r*')    %Find indices of all sound trains
    
    %Find indices of High sound trains
    TrainsAll_index=find(sound>0.75*Smax);% 0.75*Smax is a threshold to define High sound
    a=diff(TrainsAll_index);
    b=horzcat([1],a);
    c=find(b>100);%100 - interval between steps, Dt/dt where Dt - time between sounds, dt - sampling rate
    MarkersHigh=horzcat(TrainsAll_index(1),TrainsAll_index(c));
    plot(MarkersHigh,ones(size(board_adc_data(MarkersHigh))),'g*')
    
    MarkersSmall=MarkersAll;
    for i=1:length(MarkersHigh)
        MarkersSmall=MarkersSmall(find(abs(MarkersSmall-MarkersHigh(i))>60));
    end
    TypeSmall=ones(size(MarkersSmall));
    TypeHigh=2*ones(size(MarkersHigh));
    Markers=horzcat(MarkersSmall,MarkersHigh);
    Types=horzcat(TypeSmall,TypeHigh);
    for i=1:length(Markers)
        event(i)=struct('type',Types(i),'latency',Markers(i),'urevent',0);
    end
    [x,idx]=sort([event.latency]);
    event=event(idx);
    for i=1:length(event)
        event(i).urevent=i;
    end
%end
