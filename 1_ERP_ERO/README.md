### Contents

Directory **1_ERP_ERO** contains all necessary algorithms for analysis of event-related potentials (ERP) and event-related oscillations (ERO). The provided exemplary data** stems from the animal whose ERP curves are displayed in Figure S2a of manuscript 2 (currently under revision).

By choosing "1" or "0" in the task list, the ERP_ERO_Analysis.m script enables a flexible choice of pre-processing and analysis sections to be run.

Pre-processing steps include:
1. Filtering the data: here 0.1 - 45 Hz bandpass FIR filter
2. Epoching the data: here from 100 ms before to 700 ms after sound onset
3. Here, a baseline correcture using the time interval of 100 ms before sound onset has been applied to reduce temporal drifting of the signal
4. Noisy epochs with artifacts have been excluded 1) automatically using eeg_rejdelta.m, here with a threshold exceeding 600 µV and 2) manually after visual inspection to detect noisy signals (e.g. due to gnawing) not exceeding the delta threshold but un-related to the task, i.e. auditory perception
5. Averaging of all remaining, clean epochs per sound and animal 

Analysis & Visualisation include:
1. Plotting averaged data separately for each sound or their difference per animal or over all animals of the respective group (grand average) 
2. Detection of ERP peak latencies and amplitudes in pre-defined time windows. Depending on the data, these time windows might need adjustments if peaks are located out of range. The script adds markers of the detected maximum voltage to allow visually double checking. Since ERP files of frequently applied standard sounds did not display pronounced ERP amplitudes (indicating a habituation effect), we performed analysis on the deviant-minus-standard difference signals.
3. A time-frequency analysis giving event-related spectral perturbation (ERSP) based on EEGLAB´s pop_newtimef.m (https://github.com/sccn/eeglab/blob/develop/functions/popfunc/pop_newtimef.m) allows analysing and plotting ERO activity that we extended by more detailed determination of various parameters, e.g. spec. frequencies with max. power.

#
_**due to large file sizes of raw data and files generated during pre-processing, we are restricted to provide averaged data here, which, however, still allow running all steps of analysis & visualisation_

