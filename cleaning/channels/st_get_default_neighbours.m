function neighbours=st_get_default_neighbours(cfg)

ft_checkconfig(cfg,'required',{'elec'});
cfg.minchanforneighbors  = ft_getopt(cfg, 'minchanforneighbors', 3);

numChan=size(cfg.elec.chanpos,1);

minChansForNeighbors=cfg.minchanforneighbors;
if numChan>128
    min_neighb=3;
elseif numChan>=minChansForNeighbors
    min_neighb=2; %even in case of 3 channels, consider all remaining channels as neighbors
    if numChan==2
        min_neighb=1;
    end

else
    ft_warning('only %i channels in data whereas %i are required: no neighbourhood structure created.\n',numChan,minChansForNeighbors)
    neighbours=[];
    return
end

%call function creating neighbourhood such that every channel has at least
%min_neighb neighbours
cfg.minimumneighbours=min_neighb;
neighbours=st_get_minimum_neighbours(cfg);