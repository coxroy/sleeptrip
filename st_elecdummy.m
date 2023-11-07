function elec=st_elecdummy(data)

%basic elec struct
chanpos=repmat([0 0 0],[length(data.label) 1]);
elec=struct('chanpos',chanpos,'label',{data.label});

%call st_match_elec_to_data to add other fields
cfg=[];
cfg.elec=elec;
cfg.data=data;
elec=st_match_elec_to_data(cfg);