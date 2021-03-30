% obsloc_just_time.m

% Output file save the following variable:
% reloc_x, reloc_y - UTM of relocated position
%
% This module is a modified version of obsloc_hor.m.
% This is for handpicking position from the contour plot according to the
% direct wave pick (which is plotted alongside). This is only useful for
% shallow water depth such that the on bottom position is likely right on
% the shot line where it was deployed. 

% Software Ro4ActiveSrc written by Helen Lau (Dalhousie University), kwhlau@dal.ca
% v1.0 Initial release at Mar. 25, 2021

clear
ifprint=1;
is_handpick=1; % 1 if handpick relocated position from figure
iobs=18;

%% Input file and parameters
indir_nav="..";
figdir="../fig_relocation/";
s_utmfile=indir_nav+"/shot_utm_L2.txt";
r_utmfile=indir_nav+"/obs_utm_L2.txt";
pickfile=sprintf('%s/dtime_%02d_m.pick',indir_nav,iobs);
depthfile=indir_nav+"/obs_depth_L2.txt";
sdist=1000;                  % search distance from old OBS position in m

%% Output file
matname=sprintf('obs%02d_relo_pos.mat',iobs);

%% load input files
r_utm=load(r_utmfile);
r_utm=r_utm(iobs,:);
s_utm=load(s_utmfile);
dtime=load(pickfile);
sp_pick=dtime(:,1);
dtime=dtime(:,2)./1000;

%% Input depth
depth=load(depthfile);
depth=depth(iobs);

%% Find geometry for pick
i_pick=arrayfun(@(x) find(s_utm(:,1)==x,1),sp_pick);
pick_utm=s_utm(i_pick,2:3);

%% Make search grid
dint=100;
x=r_utm(1)-sdist:dint:r_utm(1)+sdist;
y=r_utm(2)-sdist:dint:r_utm(2)+sdist;
[X,Y]=meshgrid(x,y);
error1=nan(size(X));

%% Error using direct wave timing
f = waitbar(0,'Iterating through grid ...');
for n=1:length(X(:))
    df=nan(1,length(pick_utm));
    rec=[X(n) Y(n) depth];
    for m=1:length(pick_utm)
        s=[pick_utm(m,:) 0];
        mdtime=norm(rec-s)./1500;
        df(m)=abs(mdtime-dtime(m));
    end
    error1(n)=rms(df);
    if rem(n,100)==0
        waitbar(n/length(X(:)),f,'Processing your data');
    end
end

% Find best fit point
min1=min(error1(:));
max1=max(error1(:));

% Find bestfit lines
[p]=polyfit(pick_utm(:,1),pick_utm(:,2),1);
pick_y = polyval(p,pick_utm(:,1));
slope1=p(1);
slope2=-1/slope1;
[row,col] = find(error1==min1);
reloc_t_x=X(row,col); reloc_t_y=Y(row,col);
p2=[slope2,reloc_t_y-slope2*reloc_t_x];

%% Find shot line orientation
SA=atand(slope1);
if abs(SA) < 45
    Line='EW';
else
    Line='NS';
end

% Define search point on bestfit line
switch Line
    case 'EW'
        bf_y=r_utm(2)-sdist:dint:r_utm(2)+sdist;
        bf_x=(bf_y-p2(2))./p2(1);
    case 'NS'
        bf_x=r_utm(1)-sdist:dint:r_utm(1)+sdist;
        bf_y=polyval(p2,bf_x);
end

close(f)

%% Plot
r=get(groot);
scr_width=r.ScreenSize(3);
switch Line
    case 'EW'
        f1=figure('Position',[50 30 scr_width*0.4 scr_width*0.45], ...
            'defaultaxesfontsize',10,'name','The Relocated  OBS Position', ...
            'NumberTitle','off');
        
        % Plot azimuth results
        ax1=axes;
        set(ax1, 'Units', 'pixels', 'Position', [80, 700, 600, 140]);
        plot(pick_utm(:,1)',dtime,'-+')
        xlabel('x(utm)')
        ylabel('Time(s)')
        xlim([min(X(1,:)) max(X(1,:))])
        title("OBS "+num2str(iobs+"Direct Wave Traveltime"))
        grid

        % Plot timing results
        ax2=axes;
        set(ax2, 'Units', 'pixels', 'Position', [80, 50, 600, 600]);
        C=contour(X,Y,error1,10);
        clabel(C);
        hold on
        plot(pick_utm(:,1),pick_utm(:,2),'+')
        plot(bf_x,bf_y)
        h1=plot(reloc_t_x,reloc_t_y,'r+');
        h2=plot(reloc_t_x,reloc_t_y,'ro');
        plot(r_utm(1),r_utm(2),'k+')
        plot(r_utm(1),r_utm(2),'ko')
        text(r_utm(1)+10,r_utm(2)+10,'original')
        h3=text(reloc_t_x+10,reloc_t_y+10,'relocated');
        title('RMS residual for direct time (s)')
        xlim([min(X(1,:)) max(X(1,:))])
        ylim([min(Y(:,1)) max(Y(:,1))])
        grid
        
    case 'NS'
        f1=figure('Position',[50 50 scr_width*0.5 scr_width*0.4], ...
            'defaultaxesfontsize',10,'name','The Relocated  OBS Position', ...
            'NumberTitle','off');
       
        % Plot azimuth results
        ax1=axes;
        set(ax1, 'Units', 'pixels', 'Position', [820, 50, 100, 700]);
        plot(dtime,pick_utm(:,2)','-+')
        ylim([min(Y(:,1)) max(Y(:,1))])
        ylabel('y(utm)')
        xlabel('Time(s)')
        grid

        % Plot timing results
        ax2=axes;
        set(ax2, 'Units', 'pixels', 'Position', [60, 50, 700, 700]);
        C=contour(X,Y,error1,10);
        clabel(C);
        hold on
        plot(pick_utm(:,1),pick_utm(:,2),'+')
        plot(bf_x,bf_y)
        h1=plot(reloc_t_x,reloc_t_y,'r+');
        h2=plot(reloc_t_x,reloc_t_y,'ro');
        plot(r_utm(1),r_utm(2),'k+')
        plot(r_utm(1),r_utm(2),'ko')
        text(r_utm(1)+10,r_utm(2)+10,'original')
        h3=text(reloc_t_x+10,reloc_t_y+10,'relocated');
        title("OBS "+num2str(iobs)+" - RMS residual for direct time (s)")
        xlim([min(X(1,:)) max(X(1,:))])
        ylim([min(Y(:,1)) max(Y(:,1))])
        grid
end

if any(iobs==[99])
    reloc_x=r_utm(1);
    reloc_y=r_utm(2);
    disp("Saved original position as new position.")
end

retry=1;
if is_handpick
    while retry
       [reloc_x,reloc_y]=ginput(1);      
       delete(h1); delete(h2); delete(h3);
       h1=plot(reloc_x,reloc_y,'r+');
       h2=plot(reloc_x,reloc_y,'ro');
       h3=text(reloc_x+10,reloc_y+10,'relocated');
       retry=input('Retry picking?: [1 or 0]');
    end  
end
save(matname,'reloc_x','reloc_y')

%% Save figure
if ifprint==1
    figname=sprintf('%s/obs%02d_obsloc_hor_result.jpg',figdir,iobs);
    print(figname,'-djpeg','-opengl','-r300');
end
