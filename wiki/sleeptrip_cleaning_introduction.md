# Introduction

SleepTrip offers a set of functions for fully automated artifact detection and repair, along with visualization options. Cleaning functionality was developed with several principles in mind:
* artifacts should be detected _channel-wise_, as different subsets of channels may be bad at different times (due to e.g. sleeper changing position, electrode gel drying out). This differs from most algorithms that detect artifacts "globally" across all channels.
* adequate detection of various kinds of artifacts encountered across different sleep/wake stages (while limiting false positives)
* ease-of-use and customization: setting up a cleaning pipeline should be relatively straightforward using default settings, while also allowing extensive customization of detection and repair settings
* cleaning routines should accommodate both low- and high-density EEG setups, with acceptable processing times and memory demands even for 256-channel EEG

**Important**: although the current approach works satisfactorily in many cases, it is not guaranteed that it performs "better" (however defined) than other algorithms or manual/visual cleaning, or that it performs well under all circumstances. Rather, given limitations of other algorithms and the time-consuming nature of manual cleaning, the current approach offers a fast (and reproducible) alternative that can accelerate sleep EEG analysis.

# Cleaning Overview
To clean your data the following are needed:
* EEG data (continuous, not epoched)
* channel/electrode coordinates
* sleep scoring information

Conceptually, the following steps are performed:

### 1. Independent Component Analysis (ICA) [experimental] 
* ICA identifies and removes components reflecting non-neural activity (eye movements, ECG, line noise)
 
### 2. Artifact Detection
* detect continuous artifacts of various kinds on a channel-by-channel basis

At present, the following default detectors are available:
1. highamp: excessive amplitude
2. lowfreq: low-frequency (0.3-15 Hz) noise
3. highfreq: high-frequency (60-120 Hz) noise
4. jump: signal jumps
5. flatline: flatline (including amplifier saturation)
6. lowamp: implausibly low amplitude
7. deviant: channel very dissimilar from neigbors
8. similar: channel very similar to neigbors

* convert continuous artifacts to a discrete channel-by-segment grid (default segment length: 5 s), where each channel-segment element indicates the presence/absence of artifact 

* apply various rules to discrete artifact grid to specify:
1. rejection grid (segments to reject entirely). Most downstream SleepTrip functions can be instructed to ignore these rejected segments.
2. repair grid (channel-segment elements that need repairing)

### 3. Artifact Repair
* use repair grid to repair marked channels _by segment_ using weighted interpolation. That is, for each 5-s segment all bad channels are repaired at once from all remaining intact channels.

# Visualization Overview
### Low-level artifact inspection
output from artifact processing can be overlaid on (pre- or post-cleaning) EEG in different ways:
* visualize specific or all continuous artifacts to inspect what was and was not detected
![ep468_continuous_artifacts_preclean](https://user-images.githubusercontent.com/26691793/194853463-f23323e2-9e52-4366-8df4-61aa3253e50e.PNG)

* visually compare results of different detector settings (e.g., 40-80 Hz vs. 60-80 Hz high-frequency detector)
* visualize discrete rejection or repair grids
![ep468_discrete_repairReject_preclean](https://user-images.githubusercontent.com/26691793/194853574-b45edf90-41e4-42b6-89ff-739ea6c54ad8.PNG)

### High-level data quality
* information from the rejection and repair grids can be used to provide a high-level overview of data quality, allowing the user to monitor overall performance and/or exclude data from analysis

![data_qual_HD](https://user-images.githubusercontent.com/26691793/194856348-71036165-b62e-413e-a870-55df8a3697f3.png)

