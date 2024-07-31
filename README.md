## Application of a multimodal neural interface for monitoring and  relapse prevention in alcohol use disorders
Conventional pharmacotherapies of mental disorders have just moderate effects; the probability of relapse remains high. This project, therefore, introduces bioelectronic devices as an alternative toolbox to target neuropsychiatric diseases.

We apply 3D-bioprinting to develope soft neural interfaces offering multimodal functionality by combining electrocorticographic measurements and electrical/pharmacological modulation. We implant the neuroprosthesis epidurally above the medial prefrontal cortex of rats. A two-tone auditory oddball paradigm evokes neural activity patterns indicating stimulus perception, attentive processing, and behavioural control known to be affected in neuropsychiatric disorders such as alcohol addiction. 

This script provides the steps involved in our analyses of diverse neural biomarkers related to auditory event-related brain potentials (ERP) and event-related oscillatory (ERO) activity as used in:

#### 1) A Multimodal Neuroprosthetic Interface to Record, Modulate and Classify Electrophysiological Biomarkers Relevant to Neuropsychiatric Disorders: https://doi.org/10.3389/fbioe.2021.770274
#### 2) Prefrontal Electrophysiological Biomarkers and Mechanism-Based Drug Effects in a Rat Model of Alcohol Addiction: https://doi.org/10.21203/rs.3.rs-3905152/v1  
#
### Prerequisites
> This script has been developed in Windows 10, Matlab R2019b and EEGLAB v2019.0<br />
> https://www.mathworks.com/<br />
>https://github.com/sccn/eeglab<br />


To analyse data in EEGLab, data must be available in set/fdt-file formats 
requiring some preparatory steps: 
- upload Intan recording data containing neural data and the applied auditory stimuli into Matlab using read_Intan_RHD2000_file.m provided from Intan Technologies: https://intantech.com/downloads.html?tabSelect=Software&yPos=0
- open EEGLAB and add sound trigger information using FindMarkers.m and channel labels (channel_labels.ced)

Save the files via EEGLAB to get the required file formats incl. all necessary information for subsequent data processing and analysis.

### Contents

Directory **1_ERP_ERO** contains all necessary algorithms for ERP/ERO analysis and exemplary data of the animal represented in Figure S2a of manuscript 2 (currently under revision).


### Licenses

This project is licensed under the MIT License - see the LICENSE_MIT for details. Also check LICENSE_eeglab.
