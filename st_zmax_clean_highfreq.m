function data=st_zmax_clean_highfreq(data)
cfg=[];
cfg.bsfilter='yes';
cfg.bsfreq=[28.44 28.48];

data=ft_preprocessing(cfg,data);

% dat=data.trial{1}';
%
% for chan_i=1:size(dat,2)
%     dat(:,chan_i)=bandstop(dat(:,chan_i),[28.44 28.48],data.fsample);
% end
% data.trial{1}=dat';