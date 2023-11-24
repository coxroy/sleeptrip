# Versions
At present, there are two main versions (or forks) of SleepTrip in existence:
- a primary version developed and maintained by Frederik D Weber: [https://github.com/Frederik-D-Weber/sleeptrip](https://github.com/Frederik-D-Weber/sleeptrip)
- a version maintained by Roy Cox with added functionality, primarily automated artifact detection: [https://github.com/coxroy/sleeptrip](https://github.com/coxroy/sleeptrip)

While we strive to keep the two versions synchronized, there will likely be instances where the versions diverge.

# Download
Follow the links above to the version of your choice, and go to the green `<> Code` button for cloning/downloading options:
- `Open With GitHub Desktop`: this is the recommended option, as it allows you to instantly get the latest fixes and new functionality without re-downloading. (Make sure GitHub Desktop is installed and you have a GitHub account.)
- `Download ZIP`: download the current SleepTrip version the classical way. Don't forget to unzip.

# Install
In order for Matlab to have access to SleepTrip's functions, the SleepTrip folder needs to be added to the Matlab search path. For basic ionformation about the Matlab path, see [https://www.mathworks.com/help/matlab/matlab_env/what-is-the-matlab-search-path.html](https://www.mathworks.com/help/matlab/matlab_env/what-is-the-matlab-search-path.html).

Do NOT add SleepTrip and all its subfolders to the Matlab path, as this may cause conflicts with Matlab's builtin code and/or other toolboxes (particularly FieldTrip and EEGLAB). See this FieldTrip page for more information: [https://www.fieldtriptoolbox.org/faq/should_i_add_fieldtrip_with_all_subdirectories_to_my_matlab_path/](https://www.fieldtriptoolbox.org/faq/should_i_add_fieldtrip_with_all_subdirectories_to_my_matlab_path/).

Instead, add only the top-level folder to the Matlab path, followed by a call to the function `st_defaults`:
```
addpath(myPathToSleepTrip);
st_defaults; %initialization function that sets up SleepTrip and adds the necessary paths
```

Now all SleepTrip functions should be accessible.

Tip: place this code in `startup.m` to ensure it's executed every time you start Matlab. If you often need to switch between (potentially conflicting) toolboxes, consider writing dedicated scripts that add/remove paths as required.