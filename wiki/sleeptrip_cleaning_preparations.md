Before cleaning can commence, several pieces of information need to be assembled and loaded into Matlab's memory. Specifically, three variables will be needed:
1. _data_ [required]
2. _elec_ [required]
3. _scoring_ [recommended]

(These variables can be named differently in your code, but we'll try to stick to these names in this Wiki.)

# _data_

_data_ is a FieldTrip structure containing continuous data, typically read in using _ft_preprocessing_ from various formats (see [https://www.fieldtriptoolbox.org/tutorial/continuous/](https://www.fieldtriptoolbox.org/tutorial/continuous/)).

_data_ typically looks something like this (here, 11 channels):

> data = 
>
>   struct with fields:
>
>            hdr: [1×1 struct]
>        fsample: 250
>     sampleinfo: [1 9035370]
>           elec: [1×1 struct]
>          trial: {[11×9035370 double]}
>           time: {[0 0.0040 0.0080 0.0120 0.0160 0.0200 0.0240 0.0280 0.0320 0.0360 0.0400 0.0440 0.0480 0.0520 0.0560 0.0600 0.0640 0.0680 … ]}
>          label: {11×1 cell}
>            cfg: [1×1 struct] 


Some remarks:
* _data_ should be continuous (and not contain multiple trials/epochs), as data cleaning does not handle epoched data.
* all channels in _data_ should be of the same modality (e.g., EEG), and (for EEG) have the same reference. Mixing different signal types (EEG/MEG/ECG/respiration/etc.) is not supported.
* signal units are assumed to be in microV. If not, this may lead to unexpected behavior from detectors relying on amplitude.
* _data_ should typically have undergone desired preprocessing steps (e.g., channel selection, rereferencing, filtering, and so on) before artifact detection.
* sample rate _(data.fsample_) significantly affects time required to clean (as well as memory used). If you have very high sample rates (e.g. 500 Hz or above), consider downsampling to 250/256 Hz, which is more than adequate for most sleep EEG purposes (see [https://www.fieldtriptoolbox.org/faq/resampling_lowpassfilter/](https://www.fieldtriptoolbox.org/faq/resampling_lowpassfilter/)).

# _elec_

_elec_ is a FieldTrip structure of channel coordinates, matching the channels in _data_. This channel information is required by various functions.

_elec_ typically looks something like this (though fields present can vary widely for different data formats):

> elec = 
>
>   struct with fields:
>
>      chanpos: [11×3 double]
>     chantype: {11×1 cell}
>     chanunit: {11×1 cell}
>      elecpos: [11×3 double]
>        label: {11×1 cell}
>         type: 'egi256'
>         unit: 'cm'

It is critical that _elec.label_ and _data.label_ are identical (reflecting the same channels). Also note how the first dimension of _elec_'s _chanpos/chantype/chanunit/elecpos/label_ fields (11) matches that of _elec.label_ (and _data.label_).

Generating a proper _elec_ structure may require some steps and thought. The good news is that this typically needs to be performed only once per study (at least when using fixed channel coordinates).

## Getting _elec_ information from an EEG file

FieldTrip offers some functionality to read in channel coordinates directly from various EEG file formats (see [https://github.com/fieldtrip/fieldtrip/blob/master/fileio/ft_read_sens.m](https://github.com/fieldtrip/fieldtrip/blob/master/fileio/ft_read_sens.m)). However FieldTrip may not accommodate your specific format, or your EEG file may not contain accurate (or any) channel information.

In case reading from an EEG file using _ft_read_sens_ doesn't work, you can try your luck with _ft_read_header_, EEGlab functions, or external Matlab plugins (though the latter options will probably require some further conversions).

## Getting _elec_ information from a custom file

In case you have your coordinates elsewhere (e.g., txt, csv, xls), you'll have to import this information manually. Something like the code below may offer inspiration (assuming Cartesian coordinates):

* read the raw file into Matlab using _readtable_ or similar. End up with a table like this:

> elecTable =
>
>   257×4 table
>
>       label          X           Y         Z   
>     _________    __________    ______    ______
>
>     {'E1'   }         6.962     5.382    -2.191
>     {'E2'   }         6.484     6.404     -0.14
>     {'E3'   }         5.699     7.208     1.791
>     {'E4'   }         4.811     7.773      3.65
>     {'E5'   }          3.62     7.478     5.509
>
>         :            :           :         :   
>
>     {'E253' }        -7.627     3.248    -4.405
>     {'E254' }        -7.556     2.526     -6.27
>     {'E255' }         -7.38     1.357    -7.849
>     {'E256' }        -6.861    -0.142    -9.149
>     {'E1001'}    5.9291e-16         0     9.683

* convert the table to a rudimentary _elec_ variable (ensuring fields and dimensions are organized similarly to _elec_ example above):

> elec=struct('chanpos',elecTable{:,{'X','Y','Z'}},'label',{elecTable{:,'label'}})
>
> elec = 
>
>   struct with fields:
>
>     chanpos: [257×3 double]
>       label: {257×1 cell}

Although containing only two fields, this is sufficient for further processing.

## Matching _elec_ to _data_

Even when _elec_ perfectly reflects your **RAW** _data_, it may no longer do so after removal of unnecessary channels, rereferencing, reordering, and so on. Often, the channels in your final _data_ will be a subset of the channels contained in _elec_.

In this case, the function _st_match_elec_to_data_ can be used to produce a new _elec_ structure matching the channels in _data_. This only works if ALL channel labels in _data_ can be found in _elec_ (no typos allowed), otherwise _elec_reduced_ will be empty.

Build a cfg:
> cfg=[];
>
> cfg.data=data;
>
> cfg.elec=elec_original; %provide the original (typically larger) elec struct

Call _st_match_elec_to_data_ to create a new elec struct matching the data:
> elec_reduced=st_match_elec_to_data(cfg);

Compare the labels from data and elec_reduced side by side:
> [data.label elec_reduced.label]
>
>   15×2 cell array
>
>     {'E36'  }    {'E36'  }
>     {'E21'  }    {'E21'  }
>     {'E224' }    {'E224' }
>     {'E59'  }    {'E59'  }
>     {'E1001'}    {'E1001'}
>     {'E183' }    {'E183' }
>     {'E87'  }    {'E87'  }
>     {'E101' }    {'E101' }
>     {'E153' }    {'E153' }
>     {'E116' }    {'E116' }
>     {'E150' }    {'E150' }
>     {'E94'  }    {'E94'  }
>     {'E83'  }    {'E83'  }
>     {'E190' }    {'E190' }
>     {'E191' }    {'E191' }

## Verifying channel coordinates

Use the function _st_plot_elec_ to check that an _elec_'s channel information yields correctly drawn topographical plots within SleepTrip/FieldTrip. Columns in _elec.chanpos_ may need to be swapped, multiplied by -1, and so on, to account for different coordinate conventions.

%build a cfg
> cfg=[];
>
> cfg.elec=elec;

Call _st_plot_elec_:
> st_plot_elec(cfg)

![layout_257](https://user-images.githubusercontent.com/26691793/194935067-4e9948ba-f109-4cac-a880-3504134567cc.jpg)

Comparing this plot to information from the manufacturer or physical cap, we can check whether channels are plotted correctly (they are).

# _scoring_

_scoring_ is a SleepTrip structure of sleep scores, typically read in using _st_read_scoring_. Generally, the start of _scoring_ should correspond to the start of _data_ (though it's possible to provide a _dataoffset_ to the scoring if this is not the case). Although not strictly required, _scoring_ is used for ICA and to provide artifact information broken down by sleep stage.

> scoring = 
>
>   struct with fields:
>
>             ori: [1×1 struct]
>          epochs: {1×360 cell}
>        excluded: [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 … ]
>           label: {6×1 cell}
>             cfg: [1×1 struct]
>     epochlength: 30
>      dataoffset: 0
>        standard: 'aasm'
>       lightsoff: 15
>        lightson: 27585
>       sleepopon: 8.4510
>      sleepopoff: 2.7593e+04