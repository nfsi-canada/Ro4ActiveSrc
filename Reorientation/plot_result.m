% plot_result.m

r=get(groot);
scr_width=r.ScreenSize(3);
scr_height=r.ScreenSize(4);
figure('Position',[50 50 scr_width*0.9 scr_height*0.85],'defaultaxesfontsize',8,'defaultaxestickdir',...
'out','paperpositionmode','auto');

ax1=axes('position',[0.03 0.04 0.45 0.28]);
wiggle(1:length(sp_pick),time,Data2.z','VA2',1)
hold on
plot(1:length(sp_pick),dtime2,'+')
set(gca,'xtick',[])
ylabel('time(s)')
title('Vertical Geophone (Z)')

ax2=axes('position',[0.03 0.04+0.3 0.45 0.28]);
wiggle(1:length(sp_pick),time,Data2.y','VA2',1)
hold on
plot(1:length(sp_pick),dtime2,'+')
ylabel('time(s)')
title('Horizontal Geophone (Y)')
set(gca,'xtick',[])

ax3=axes('position',[0.03 0.04+0.3*2 0.45 0.28]);
wiggle(1:length(sp_pick),time,Data2.x','VA2',1)
hold on
plot(1:length(sp_pick),dtime2,'+')
ylabel('time(s)')
xlabel('Pick #')
title('Horizontal Geophone (X)')
set(gca,'XAxisLocation','top')

ax4=axes('position',[0.52 0.04+0.3*2 0.45 0.28]);
wiggle(1:length(sp_pick),time,Data2.r','VA2',1)
hold on
plot(1:length(sp_pick),dtime2,'+')
ylabel('time(s)')
xlabel('Pick #')
title('Radial Component (R)')
set(gca,'XAxisLocation','top')

ax5=axes('position',[0.52 0.04+0.3 0.45 0.28]);
wiggle(1:length(sp_pick),time,Data2.t','VA2',1)
hold on
plot(1:length(sp_pick),dtime2,'+')
ylabel('time(s)')
title('Transverse Component (T)')
set(gca,'xtick',[])
x1=xlim;

ax6=axes('position',[0.52 0.04 0.45 0.28]);
plot(1:length(sp_pick),OBS_az,'k+')
hold on
plot(1:length(sp_pick),s_r_angle,'r+')
plot(1:length(sp_pick),cor_OBS_az,'ro')
plot(1:length(sp_pick),ones(size(cor_OBS_az))*mean_OBS_az,'g-')
ylabel('Azimuth(degree)')
xlabel('Pick #')
xlim(ax6,x1)
title("Direct Water Water Analysis for OBS "+num2str(iobs))
legend({'Local-OBS-X','S2R','Geo-OBS-X','Mean-geo-X'},'Location','best')


%% Save figure
if ifprint
    figname=sprintf('%s/obs%02d_dw_result.jpg',figdir,iobs);
    print(figname,'-djpeg','-opengl','-r300');
end