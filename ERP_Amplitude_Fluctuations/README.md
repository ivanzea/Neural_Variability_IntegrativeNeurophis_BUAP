ERP AMPLITUDE FLUCTUATIONS
============================
>The pipeline is used to convert several .cnt files into matlab variables that contain eeg signals that correspond to specific evoked potentials. Folder and file structure are important for the main script to run.
### FOLDER STRUCTURE
>Folder structure should **NOT** be altered.
```
ERP_Amplitude_Fluctuations
├──src
│  ├──Preprocessing
│  └──Analysis
├──ext
│  ├──eeglab
│  └──...
├──RawData      
│  ├──SubjectID ──┐
│  │  ├──*.cnt    │
│  │  ├──*.mat    │
│  │  └──...      │ 
│  ├──SubjectID   ├"SubjectFolders"
│  │  ├──*.cnt    │
│  │  ├──*.mat    │
│  │  └──...      │ 
│  └──...       ──┘
├──RawData
│  └──"SubjectFolders"
└──FinalData
   └──*.mat
```
### DATA NAMING CONVENTIONS
>SubjectFirstName_ExpermentTag_YYMMDD###(3 digit block_number).Extension(cnt/mat)

    Ex: Pedro_random_181101002.cnt
        Pedro_random_181101002.mat

All files to be processed and analyzed under the ERP Amplitude Fluctutations paradigm should be saved under **/RawData** and use the Subject Folders structure convention as showed above.

### PREPROCESSING METHODS
>Most methods used are built in fuctions or libraries associeted with eeglab

**_STEP 1_**

Convert neuroscan ***.cnt** files to eeglab standard ***.set** matlab structures

    input: \RawData\SubjectID\*.cnt
    output: \PipelineData\SubjectID\*_raw.set

**_STEP 2_**

Given that our system is not very relaible when it comes to trigger/timestamp consistensy, we will cross check latency information with the MATLAB file generated in the stimulation controller system.
    
1. Delete spontaneous events... sporeous events and others using a minimum ISI threshold between each event **(100ms)**
2. Delete timestamp located at the end of the run that is not part of the stimulus triggers using a maximum ISI threshold **(3sec)**
3. Use Dynamic Time Warpping (DTW) to flag timestamps as matches with the ***.mat** controller file.
    - Retain matches
    - Find missing triggers and add them
    - Filter matches with a maximun deviation threshold and eliminate the ones above it **(10ms)**
4. Use the ***.mat** controller file to transfer the stimulation type information from to the eeglab structure
5. If a correction table is provided with entries, use that information to correct known timming issues

        input:  \PipelineData\SubjectID\*_raw.set
                \RawData\SubjectID\*.mat
        output: \PipelineData\SubjectID\*_eventcor.set

**_STEP 3_**

Do an initial cleaning of the data by changin the signal properties with downsampling and bandpass filtering.

1. Downsample the signal to reduce amount of data to work with **(128Hz)**
2. Bandpass filter **(1-40Hz)**
     The 1Hz high pass is used to achieve better ICA regection in an ERP experiment paradigm. The 40Hz low pass filter is used because ERP signal compnent are almost always bellow that frequency as well as it eliminates 50/60Hz line noise.

    **Filtering**
    [Winkler I, Debener S, Muller KR, Tangermann M. 2015. On the influence of high-pass filtering on ICA-based artifact reduction in EEG-ERP. Conf Proc IEEE Eng Med Biol Soc. 2015 Aug;2015:4101-5.](https://ieeexplore.ieee.org/document/7319296)

    **Downsampling + filtering**
    [Pre-Processing for ERP analysis. Le Centre de Ressources Experimentales du Brain and Language Research Institute. https://blricrex.hypotheses.org/ressources/eeg/pre-processing-for-erps](https://blricrex.hypotheses.org/ressources/eeg/pre-processing-for-erps)   

       input:  \PipelineData\SubjectID\*_eventcor.set
       output: \PipelineData\SubjectID\*_filtered.set

**_STEP 4_**

Use non-stationary methods to clean data artifacts with spatial and temporal signal components.

1. Add location data to each channel. Eliminate channels without spatial information and without ERP signal
2. Apply Artifact Subspace Reconstruction (**ASR**)
    - Find calibration data
    - Reject channels using a neighbor channels correlation threshold **(0.8)**
    - Reconstruct high variance subspace using a standard deviation thresholds to mark 1s windows for reconstruction **(10)**
    - Apply window rejection post reconstruction, if channels are still very noisy in a specific window, reject it based on % of bad channels in the same 1s window **(0.5)**
    - Interpolate rejected channels
3. Use PREP pipeline robust average
    Estimate the true signal mean by finding bad channels by deviation, correlation, predictability, and noisiness criterions. Using these metrics bad channels are interpolated using Legendre polynomials. A mean is calculated and applyed as reference, then the same process is repeated until there are no further changes in bad channel detection.

    **ASR**
    [Chang C-Y, Hsu S-H, Pion-Tonachini L, Jung T-P. 2018. Evaluation of Artifact Subspace Reconstruction for Automatic EEG Artifact Removal. Conf Proc IEEE Eng Med Biol Soc.](https://ieeexplore.ieee.org/document/8512547/)

    **Visual depiction of ASR!**
    [Miyakoshi M, Chang C-Y, Hsu S-H, Pion-Tonachini L, Jung T-P, Jung T-P, Kothe C. ASR for Dummies. https://sccn.ucsd.edu/mediawiki/images/c/c5/AsrForDummies_ver21_web.pdf](https://sccn.ucsd.edu/mediawiki/images/c/c5/AsrForDummies_ver21_web.pdf)

    **PREP**
    [Bigdely-Shamlo N, Mullen T, et. al. 2015. The PREP pipeline: standardized prepocessing for large-scale EEG analysis](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4471356/#!po=86.4486)


        input:  \PipelineData\SubjectID\*_filtered.set
        output: \PipelineData\SubjectID\*_nonstationaryclean.set

**_STEP 5_**

Clean the data using stationary methods specifically by rejecting artifacts through Independent Componet Analysis (ICA)

1. Apply ICA using Second Order Blind Identification (SOBI) algorithm
    SOBI is fast and accurate but uses more memory than other algorithms, definetely a great trade-off
2. Use the Multiple Artifact Rejection Algorithm (MARA) to automatically detect and reject artifact components from ICA results. Reconstruct signals without artifactual components.

    **SOBI** 
    [Sahonero-alvarez G and Calderon H. 2017. A comparison of SOBI, FastICA, JADE and Infomax Algorithms. Proceeding of hte 8th international multi-conference on complexity, informatics and cybernetics.](http://www.iiis.org/CDs2017/CD2017Spring/papers/ZA832BA.pdf)

    **SOBI ALGORITHM - _look at section 'D. Implementation of the SOBI Algorithm'_**
    [Abed-Meraim, Cardoso J-F, and Moulines E. 1997. A Blind Source Separation Technique Using Second-Order Statistics IEEE Transactions on signal processing.](http://www.bsp.brain.riken.jp/ICApub/A97-434.pdf)

    **MARA**
    [Winkler I, Haufe S, and Tangermann M. 2011. Automatic classification of artifactual ICA-components for artifact removal in EEG signals. Behavioral and Brain Functions](https://behavioralfunctions.biomedcentral.com/articles/10.1186/1744-9081-7-30)

    **MARA**
    [Winkler I, Brandl S, et. al. 2014. Robust artifactual independent component classification for BCI practitioners. Journal of Neural Engineering](https://iopscience.iop.org/article/10.1088/1741-2560/11/3/035013/meta)

        input:  \PipelineData\SubjectID\*_nonstationaryclean.set
        output: \PipelineData\SubjectID\*_stationaryclean.set

**_STEP 6_**

For every event type (different stimulus type), epoch data around it **(-0.2 : 0.5 s)** and apply base line correction using its prestimulus signal **(-200 : 0 ms)**. Allocate all the data in a matlab structure file.

    input:  \PipelineData\SubjecID\*_stationaryclean.set
    output: \FinalData\SubjectID\*_epochs.mat