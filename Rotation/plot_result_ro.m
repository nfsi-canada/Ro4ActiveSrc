% plot_result.m

rt=get(groot);
scr_width=rt.ScreenSize(3);
scr_height=rt.ScreenSize(4);
fig=figure('Position',[0 50 scr_width*0.95 scr_height*0.85],'defaultaxesfontsize',12);
ax1=axes('position',[0.03 0.68 0.45 0.28]);
wiggle(offset,time,Old_cut(:,:,1),'VA2',1)
set(gca,'xtick',[])
ylabel('time(s)')
title('Horizontal Geophone (X)')

ax2=axes('position',[0.03 0.37 0.45 0.28]);
wiggle(offset,time,Old_cut(:,:,2),'VA2',1)
set(gca,'xtick',[])
ylabel('time(s)')
title('Horizontal Geophone (Y)')

ax3=axes('position',[0.03 0.06 0.45 0.28]);
wiggle(offset,time,Old_cut(:,:,3),'VA2',1)
% set(gca,'xtick',[])
ylabel('time(s)')
xlabel('offset (m)')
title('Vertical Geophone (Z)')

ax4=axes('position',[0.52 0.68 0.45 0.28]);
wiggle(offset,time,New_cut(:,:,1),'VA2',1)
set(gca,'xtick',[])
ylabel('time(s)')
title('Radial Component')

ax5=axes('position',[0.52 0.37 0.45 0.28]);
wiggle(offset,time,New_cut(:,:,2),'VA2',1)
% set(gca,'xtick',[])
ylabel('time(s)')
xlabel('offset (m)')
title('Transverse Component')

annotation(fig,'textbox',...
    [0.52 0.04 0.45 0.28],...
    'String',{'QC Plots for Horizontal Component Rotation -',"OBS "+num2str(iobs)},...
    'HorizontalAlignment','center',...
    'FontSize',48,...
    'FitBoxToText','off',...
    'EdgeColor','none');

if ifprint
    figname=sprintf('%s/obs%02d_qc_rotate.jpg',figdir,iobs);
    print(figname,'-djpeg','-opengl','-r300');
end
