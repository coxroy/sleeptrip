# Introduction

The first stage of artifact detection is specifying a so-called **detector set**: a collection of individual detectors each sensitive to different kinds of artifact (e.g., low-frequency noise, high-frequency noise, signal jumps, and so on). SleepTrip offers different ways of creating detector sets, ranging from using a default detector set, to building a set of fully customized detectors.

# Default Detector Set

The simplest approach is to make use of the built-in default detector set, by calling _st_get_default_detector_set_. At present, the default detector set contains six detectors:

*  _absamp_: absolute amplitude > 300 microV (sweat potentials, large eye movements/blinks)
*  _lowfreq_: 2-15 Hz filtered envelope > z-score of 8 (sweat potentials, large eye movements/blinks)
*  _highfreq_: 60-120 Hz filtered envelope > z-score of 3 (muscle activity)
*  _jump_: median-filtered absolute gradient > z-score of 25 (signal jumps)
*  _flatline_: absolute gradient < 0.5 microV (no connection, saturation)
*  _deviant_: correlation < 0.3 with > 0.5 of neighboring channels (poor/no connection)

Detector parameters have been set to reasonable values based on extensive visual inspection of both low- and high-density EEG. However, no single set of parameters will be able to accommodate all datasets. **It's advisable to always inspect the results of artifact detection in your own data.**

## Retrieve Default Detector Set

Assuming you have the (properly prepared) _data_ and _elec_ variables available, specify a cfg:

> cfg=[];
>
> cfg.elec=elec;
>
> cfg.fsample=data.fsample; %the sample rate is needed to determine which detectors to include

Use this cfg to obtain the default detector set:

> detector_set_default_all=st_get_default_detector_set(cfg);

This should result in something like this:

> detector_set_default_all = 
>
>   struct with fields:
>
>        number: 6
>         label: {'absamp'  'lowfreq'  'highfreq'  'jump'  'flatline'  'deviant'}
>     detectors: {[1×1 struct]  [1×1 struct]  [1×1 struct]  [1×1 struct]  [1×1 struct]  [1×1 struct]}
>          elec: [1×1 struct]

It's also possible to specify which of the default detectors you wish to include:

> cfg=[];
>
> cfg.elec=elec;
>
> cfg.fsample=data.fsample;
>
> cfg.include={'absamp','flatline','deviant'}; %use the names of desired detectors
>
> detector_set_default_custom=st_get_default_detector_set(cfg);

Note: the information provided in _cfg_ influences which detectors are returned and some of their details:

* _cfg.fsample_ affects the frequency range of the _highfreq_ detector (considering Nyquist frequency). If _fsample_ is too low, the _highfreq_ detector is not returned
* _cfg.elec_ affects which channels are considered neighbors for the _deviant_ detector. If there are fewer than 3 channels, the _deviant_ detector is not returned (i.e., with only 1 or 2 channels, meaningful comparisons to neigboring channels cannot be performed)

# Custom Detector Sets

## Individual Detectors

Before demonstrating how to build a custom detector set, it's helpful to consider how individual detectors are organized. Each detector contains specifications on how to process the data. Let's inspect detector 2 of our default detector set:

> detector_set_default_all.detectors{2}
>
> ans = 
>
>   struct with fields:
>
>     label: 'lowfreq'
>        ft: [1×1 struct]
>        st: [1×1 struct]

We can further inspect the _ft_ field:

> detector_set_default_all.detectors{2}.ft
>
> ans = 
>
>   struct with fields:
>
>     bpfilter: 'yes'
>       bpfreq: [0.3000 15]
>      hilbert: 'yes'
>       boxcar: 0.2000

And the _st_ field:

> detector_set_default_all.detectors{2}.st
>
> ans = 
>
>   struct with fields:
>
>                 method: 'threshold'
>                 zscore: 'yes'
>     thresholddirection: 'above'
>         thresholdvalue: 8
>        paddingduration: 3
>          mergeduration: 1

Briefly, the _ft_ field is itself a _cfg_ that specifies how FieldTrip's _ft_preprcessing_ should transform the data. Similarly, the _st_ field is a _cfg_ that specifies further processing details for SleepTrip. We discuss available options in more detail below.

### FieldTrip options (_ft_)

Since FieldTrip offers extensive data processing capabilities useful for artifact detection, SleepTrip provides direct access to this functionality. Specifically, if a detector _cfg_ contains an _ft_ field, the content of this field is passed in its entirety to _ft_preprocessing_.

In principle, all valid options for _ft_preprocessing_ are supported. See [https://github.com/fieldtrip/fieldtrip/blob/release/ft_preprocessing.m](https://github.com/fieldtrip/fieldtrip/blob/release/ft_preprocessing.m) for full details. However, in practice only a subset of options will be of use for artifact detection. See the example above (_detector_set_default_all.detectors{2}.ft_) for the complete _ft_ specification of the _lowfreq_ detector.

For illustration, these are _ft_ processing options used within the default detector set (most requiring setting multiple parameters):
* band-pass filter (used for default detectors _lowfreq_, _highfreq_)
* median filter [with absdiff] (used for default detector _jump_)
* (magnitude of) Hilbert transform (used for default detectors _lowfreq_, _highfreq_)
* boxcar [for smoothing] (used for default detectors _lowfreq_, _highfreq_)

Note that:
* the _ft_ field is always evaluated before the _st_ field
* the _ft_ field is optional: if not provided processing will proceed to the _st_ field directly
* _ft_preprocessing_ sets several fields to defaults if not explicitly provided (e.g., filtering)

In sum, _ft_ field instructions transform the original data into a processed form (e.g., filtered, envelope) that is useful for subsequent artifact detection.

### SleepTrip options (_st_)

Following (optional) processing by _ft_preprocessing_, resulting data are processed according to instructions from the (required) _st_ field. This will result in actual start/end times for individual artifacts. Below, we list the most important options.

timing parameters:
 * _st.minduration_: minimum duration of event, in seconds (default: 0)
 * _st.maxduration_: maximum duration of event, in seconds (default: inf)
 * _st.paddingduration_: amount of padding/extension on both sides of event, in seconds (default: 0 [=no padding])
 * _st.mergeduration_: interval between events (after padding) within which events are merged, in seconds (default: 0 [=no merging])

method:
* _st.method_: basic detection approach. Can have values 'threshold' (= compare signal to threshold(s)) or 'compareToNeighbors' (=compare signal to neighbors)

In case _st.method_ is 'threshold', the following are required:
* _st.thresholddirection_: 'above', 'below' or 'between' (e.g., 'above' means that signal above _thresholdvalue_ is considered artifact)
* _st.thresholdvalue_: single number ('above'/'below') or vector of 2 ('between') to compare data against

In case _st.method_ is 'threshold', the following are optional data processing steps (evaluated in the following order):
* _st.diff_: 'yes, 'no' (default). Takes signal gradient/derivative (_diff_ function)
* _st.abs_: 'yes, 'no' (default). Takes absolute value of signal (_abs_ function)
* _st.zscore_: 'yes, 'no' (default). Takes z-score of signal (_zscore_ function)

## Adjusting a Detector of an Existing Detector Set

We can simply adjust particular settings of the default detector set.

First make a copy of the default set:
> my_detector_set=detector_set_default_all;

Suppose we want to change the bandpass filter frequencies of the low-frequency filter (detector 2). they're set here:
> my_detector_set.detectors{2}.ft.bpfreq %vector of length 2
>
> ans =
>
>     0.3000   15.0000
>
Simply change to new values and you're done:
> my_detector_set.detectors{2}.ft.bpfreq = [1 10];

## Creating a Custom Detector Set (1)

We can also specify individual detectors, and then combine them into a detector set. To simplify, we'll take the 'absamp' detector from the default set as a starting point:

> cfg=[];
>
> cfg.elec=elec;
>
> cfg.fsample=data.fsample;
>
> cfg.include={'absamp'}; %even with one detector, name should be inside a cell
>
> detector_set_absamp=st_get_default_detector_set(cfg); 

Note that this is still a detector set: we need to extract the (first) detector from the field 'detectors':

>dtct_absamp=detector_set_absamp.detectors{1}
>
> dtct_absamp = 
>
>   struct with fields:
>
>     label: 'absamp'
>        st: [1×1 struct]

The _st_ field contains firther details:

> dtct_absamp.st
>
> ans = 
>
>   struct with fields:
>
>                 method: 'threshold'
>                    abs: 'yes'
>     thresholddirection: 'above'
>         thresholdvalue: 300
>        paddingduration: 0.1000
>          mergeduration: 1

Suppose we want evaluate the effect of different amplitude thresholds on our artifact detection: for example 200/300/400 microV. We make copies of our detector and adjust setting(s) as needed (also provide a unique name).

200 microV:
> dtct_absamp_200=dtct_absamp;
>
> dtct_absamp_200.label='absamp_200';
>
> dtct_absamp_200.st.thresholdvalue=200;

300 microV:
> dtct_absamp_300=dtct_absamp;
>
> dtct_absamp_300.label='absamp_300';
>
> dtct_absamp_300.st.thresholdvalue=300;
 
400 microV:
> dtct_absamp_400=dtct_absamp;
>
> dtct_absamp_400.label='absamp_400';
>
> dtct_absamp_400.st.thresholdvalue=400;

Now we can use _st_combine_detectors_ to turn these into a custom detector set. The detector cfgs should be provided inside a cell:

> detector_set_different_amplitudes=st_combine_detectors({dtct_absamp_200,dtct_absamp_300,dtct_absamp_400})
>
> detector_set_different_amplitudes = 
>
> struct with fields:
>
>       number: 3
>        label: {'absamp_200'  'absamp_300'  'absamp_400'}
>     detectors: {[1×1 struct]  [1×1 struct]  [1×1 struct]}

## Creating a Custom Detector Set (2)

It's not required to use default detectors as starting points: detectors can be built from scratch, provided they contain valid _st_ and _ft_ fields (see _Individual Detectors_ above).

As a brief example, let's assume we're specifically interested in 60-80 Hz artifacts:

> my_custom_detector=[]; %intialize (will become a structure)
>
> my_custom_detector.label='mydetector'; %provide a name

We'll perform filtering using _ft_preprocessing_. Create a substructure "ft" with valid options for _ft_preprocessing_:

> my_custom_detector.ft.bpfilter='yes'; %specify (default) bandpass filter
>
> my_custom_detector.ft.bpfreq=[60 80]; %frequency range
>
> my_custom_detector.ft.hilbert='yes'; %extract the amplitude envelope of the filtered signal
>
> my_custom_detector.ft.boxcar = 0.2; %smooth the amplitude envelope using specified window size

Now create a substructure "st":

> my_custom_detector.st.method='aboveZ'; %we'll be looking at the z-score of the provided signal (here, amplitude envelope)
>
> my_custom_detector.st.maxZ = 2.5; %we consider an artifact when Z > 2.5
>
> my_custom_detector.st.minduration=1; %only consider artifact if duration > 1 s
>
> my_custom_detector.st.paddingduration = 1; %extend detected artifact by 1 s (on both sides)
>
> my_custom_detector.st.mergeduration = 0.5; %merge artifacts if inter-artifact gap is < 0.5 s

Finally, remember that we need a detector SET (even when we only have one detector in there):

>my_custom_detector_set=st_combine_detectors({my_custom_detector})

> my_custom_detector_set = 
>
>   struct with fields:
>
>        number: 1
>         label: {'mydetector'}
>     detectors: {[1×1 struct]}
