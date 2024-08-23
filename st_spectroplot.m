function fh=st_spectroplot(cfg,data)


cfg.channel      = ft_getopt(cfg, 'channel', data.label); %all channels by default
cfg.title        = ft_getopt(cfg, 'title', []);
%cfg.timescale =ft_getopt(cfg,'tick','hour');
%cfg.length = 
%%
%calculate spectrogram
%cfg_pow = [];
cfg.approach = 'spectrogram'; % 'spectrogram' 'mtmfft_segments' 'mtmconvol_memeff'
cfg.taper  = 'dpss'; % 'hanning' 'hanning_proportion' 'dpss'
cfg.transform  = 'log10'; % 'none' 'db' 'db(p+1)' 'log10' 'log10(p+1)'
cfg.channel = cfg.channel;
cfg.powvalue = 'power';
freq_continous = st_tfr_continuous(cfg, data);

%%

numChan=length(freq_continous.label);
numPlotCols=[numChan*2 1];

fh=figure('Position',[744 630 1220 420]);

if ~isempty(cfg.title)
    sgtitle(strrep(cfg.title,'_','\_'))
end

plotPosition=1;
for k=1:numChan

    %--------------spectrogram----------
    plotRange=plotPosition:plotPosition+numPlotCols(1)-1;

    subplot(numChan,sum(numPlotCols),plotRange)
    time = freq_continous.time;
    freq = freq_continous.freq;
    powColRange=[-3 0];

    imagesc(time,freq,squeeze(freq_continous.powspctrm(k,:,:)),powColRange)

    set(gca, 'YDir','normal')

    title(sprintf('%s',freq_continous.label{k}))


    %x axis

    timeticksdiff = 3600;
    xTick = min(time):timeticksdiff:max(time);
    set(gca, 'xTick', xTick);

    if k==numChan
        set(gca, 'xTickLabel', arrayfun(@num2str,round(xTick/3600,2),'UniformOutput',false));
        timeunit = 'h';
        xlabel(['time (' timeunit ')']);
    else
        set(gca, 'xTickLabel', {})
    end

    %-y axis
    freqticksdiff=4;
    yTick=min(freq):freqticksdiff:max(freq);
    set(gca, 'yTick', yTick);
    set(gca, 'yTickLabel', arrayfun(@num2str,round(yTick,0),'UniformOutput',false));

    if k==1
        ylabel('frequency (Hz)');
    end

    set(gca,'TickDir','out');
    set(gca, 'box', 'off')

    %-z axis
    powticksdiff=1;
    zTick=min(powColRange):powticksdiff:max(powColRange);

    c=colorbar;
    ylabel(c,'log(pow)','Rotation',270)
    c.Label.Position(1) = 3;

    set(c,'yTick',zTick)

    if k~=1
        c.Visible = 'off';
    end


    plotPosition=plotPosition++numPlotCols(1);

    %-regular power spectrum

    plotRange=plotPosition:plotPosition+numPlotCols(2)-1;
    subplot(numChan,sum(numPlotCols),plotRange)

    plot(freq,squeeze(mean(freq_continous.powspctrm(k,:,:),3)),'lineWidth',2,'color','k');


    set(gca,'TickDir','out');
    set(gca, 'box', 'off')

    %x axis
    set(gca, 'xTick', yTick);
    if k==numChan
        set(gca, 'xTickLabel', arrayfun(@num2str,round(yTick,0),'UniformOutput',false));
        xlabel('frequency (Hz)');
    else
        set(gca, 'xTickLabel',{})
    end


    %y axis
    set(gca, 'yTick', zTick);
    ylim(powColRange)

    plotPosition=plotPosition++numPlotCols(2);

end

colormap(fh,'parula')
set(fh,'color','w')