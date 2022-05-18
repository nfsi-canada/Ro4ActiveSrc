% obsloc_hor.m
% Output file save the following variable:
% reloc_x, reloc_y - UTM of relocated position
% min1 - residual time of relocated position
% min2 - residual degree of relocated position
%
% The online position is first determined by the least error between
% predicted and observed direct wave travel times. The offline
% position can then be determined either by the least error between predicted
% and observed source-receiver orientation or the maximum correlation
% between the two. The method of least error is usually preferred. If the 
% resulted relocated position seems wrong, there is an option to handpick a 
% position from the contour map. 

% Software Ro4ActiveSrc written by Helen Lau (Dalhousie University), kwhlau@dal.ca
% v1.0 Initial release at Mar. 25, 2021

clear
ifprint=1;  % 1 for saving plot
is_max_correlation=0; % 1 if using correlation values for best fit
is_handpick=1; % 1 if handpick relocated position from figure

iobs=18;  % OBS #

%% Input file and parameters
indir_nav="..";
figdir="../fig_relocation/";
r_utmfile=indir_nav+"/obs_utm_L2.txt";
dwfile=sprintf('%s/obs%02d_dw_result.mat',indir_nav,iobs);
pickfile=sprintf('%s/dtime_%02d.pick',indir_nav,iobs);
depthfile=indir_nav+"/obs_depth_L2.txt";
sdist=5000;                  % search distance from pre-relocated OBS position in m

%% Output file
matname=sprintf('obs%02d_relo_pos.mat',iobs);

%% load input files
r_utm=load(r_utmfile);
r_utm=r_utm(iobs,:);
data=load(dwfile);

addpath('../Reorientation')
dtime=load(pickfile);
dtime=dtime(:,2)./1000;
sp_pick=data.sp_pick;

%% Input depth
depth=load(depthfile);
depth=depth(iobs);
%% Calculate observed geo s-r orientation
s_r_angle=data.OBS_az+str2double(data.r_az);
s_r_angle=wrapTo360(s_r_angle);

%% Make search grid
dint=100;
x=r_utm(1)-sdist:dint:r_utm(1)+sdist;
y=r_utm(2)-sdist:dint:r_utm(2)+sdist;
[X,Y]=meshgrid(x,y);
error1=nan(size(X));

%% Error using direct wave timing
f = waitbar(0,'Iterating through grid ...');
for n=1:length(X(:))
    df=nan(size(s_r_angle));
    rec=[X(n) Y(n) depth];
    for m=1:length(s_r_angle)
        s=[data.pick_utm(m,:) 0];
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
[p]=polyfit(data.pick_utm(:,1),data.pick_utm(:,2),1);
pick_y = polyval(p,data.pick_utm(:,1));
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

%% Error using azimuth
% Define search point on bestfit line
switch Line
    case 'EW'
        bf_y=r_utm(2)-sdist:dint:r_utm(2)+sdist;
        bf_x=(bf_y-p2(2))./p2(1);
    case 'NS'
        bf_x=r_utm(1)-sdist:dint:r_utm(1)+sdist;
        bf_y=polyval(p2,bf_x);
end

error2=nan(size(bf_y));
correl=error2;
m_sr_ang=nan(length(bf_y),length(s_r_angle));

for n=1:length(bf_y)    
    for m=1:length(s_r_angle)
        % Fit with orientation
        m_sr_ang(n,m)=atan2(bf_y(n)-data.pick_utm(m,2),bf_x(n)-data.pick_utm(m,1));
        m_sr_ang(n,m)=wrapTo360(rad2deg(m_sr_ang(n,m))); 
    end
    df2=angular_sub(m_sr_ang(n,:),s_r_angle');
    tmp=corr([m_sr_ang(n,:)' s_r_angle]);
    correl(n)=tmp(1,2);
    error2(n)=rms(df2);
end

%% Find best fit
min2=min(error2);
if is_max_correlation
    max2=max(correl);
    [row3,col3] = find(correl==max2);
else    
    [row3,col3] = find(error2==min2);    
end
reloc_x=bf_x(col3); reloc_y=bf_y(col3);

%% remove bad points from analysis of direct wave
df3=angular_sub(m_sr_ang(col3,:),s_r_angle');
bad_pt=find((abs(df3)>100));

if ~isempty(bad_pt)
    s_r_angle(bad_pt)=[];
    data.pick_utm(bad_pt,:)=[];
    sp_pick(bad_pt)=[];
    % rerun error calculations
    error2=nan(size(bf_y));
    correl=error2;
    m_sr_ang=nan(length(bf_y),length(s_r_angle));
    for n=1:length(bf_y) 
        for m=1:length(s_r_angle)
            % Fit with orientation
            m_sr_ang(n,m)=atan2(bf_y(n)-data.pick_utm(m,2),bf_x(n)-data.pick_utm(m,1));
            m_sr_ang(n,m)=wrapTo360(rad2deg(m_sr_ang(n,m)));      
        end
        df2=angular_sub(m_sr_ang(n,:),s_r_angle');
        tmp=corr([m_sr_ang(n,:)' s_r_angle]);
        correl(n)=tmp(1,2);
        error2(n)=rms(df2);
    end
    min2=min(error2);
    if is_max_correlation
        max2=max(correl);
        [row3,col3] = find(correl==max2);
    else        
        [row3,col3] = find(error2==min2);       
    end
    reloc_x=bf_x(col3); reloc_y=bf_y(col3);
end

close(f)

%% Plot
r=get(groot);
scr_width=r.ScreenSize(3);
switch Line
    case 'NS'
        f1=figure('Position',[50 30 scr_width*0.4 scr_width*0.5], ...
            'defaultaxesfontsize',10,'name','The Relocated  OBS Position', ...
            'NumberTitle','off');
        % Plot Correlation results
        ax3=axes;
        set(ax3, 'Units', 'pixels', 'Position', [80, 850, 600, 100]);
        plot(bf_x,correl,'k+')
        hold on
        plot(bf_x,correl)
        plot(reloc_x,correl(col3),'r+','linewidth',2)
        xlim([min(X(1,:)) max(X(1,:))])
        xlabel('x(utm)')
        ylabel('Correlation')
        grid
        
        % Plot azimuth results
        ax1=axes;
        set(ax1, 'Units', 'pixels', 'Position', [80, 700, 600, 100]);
        plot(bf_x,error2,'k+')
        hold on
        plot(bf_x,error2)
        plot(bf_x(col3),error2(col3),'r+','linewidth',2)
        xlim([min(X(1,:)) max(X(1,:))])
        xlabel('x(utm)')
        ylabel('RMS residual (degree)')
        title("OBS "+num2str(iobs)+" - Bestfit using source-receiver azimuthal results")
        grid

        % Plot timing results
        ax2=axes;
        set(ax2, 'Units', 'pixels', 'Position', [80, 50, 600, 600]);
        C=contour(X,Y,error1,10);
        clabel(C);
        hold on
        plot(data.pick_utm(:,1),data.pick_utm(:,2),'+')
        plot(bf_x,bf_y)
        h1=plot(reloc_x,reloc_y,'r+')
        h2=plot(reloc_x,reloc_y,'ro')
        plot(r_utm(1),r_utm(2),'k+')
        plot(r_utm(1),r_utm(2),'ko')
        text(r_utm(1)+10,r_utm(2)+10,'original')
        h3=text(reloc_x+10,reloc_y+10,'relocated')
        title('RMS residual for direct time (s)')
        xlim([min(X(1,:)) max(X(1,:))])
        ylim([min(Y(:,1)) max(Y(:,1))])
        grid
        
    case 'EW'
        f1=figure('Position',[50 50 scr_width*0.60 scr_width*0.4], ...
            'defaultaxesfontsize',10,'name','The Relocated  OBS Position', ...
            'NumberTitle','off');
        % Plot Correlation results
        ax3=axes;
        set(ax3, 'Units', 'pixels', 'Position', [830, 50, 100, 700]);
        plot(correl,bf_y,'k+')
        hold on
        plot(correl,bf_y)
        plot(correl(col3),reloc_y,'r+','linewidth',2)
        ylim([min(Y(:,1)) max(Y(:,1))])
        ylabel('y(utm)')
        xlabel('Correlation')
        grid
        
        % Plot azimuth results
        ax1=axes;
        set(ax1, 'Units', 'pixels', 'Position', [980, 50, 100, 700]);
        plot(error2,bf_y,'k+')
        hold on
        plot(error2,bf_y)
        plot(error2(col3),bf_y(col3),'r+','linewidth',2)
        ylim([min(Y(:,1)) max(Y(:,1))])
        ylabel('y(utm)')
        xlabel('RMS residual azimuth (degree)')
        grid

        % Plot timing results
        ax2=axes;
        set(ax2, 'Units', 'pixels', 'Position', [60, 50, 700, 700]);
        C=contour(X,Y,error1,10);
        clabel(C);
        hold on
        plot(data.pick_utm(:,1),data.pick_utm(:,2),'+')
        plot(bf_x,bf_y)
        plot(reloc_x,reloc_y,'r+')
        plot(reloc_x,reloc_y,'ro')
        plot(r_utm(1),r_utm(2),'k+')
        plot(r_utm(1),r_utm(2),'ko')
        text(r_utm(1)+10,r_utm(2)+10,'original')
        text(reloc_x+10,reloc_y+10,'relocated')
        title("OBS "+num2str(iobs)+" - RMS residual for direct time (s)")
        xlim([min(X(1,:)) max(X(1,:))])
        ylim([min(Y(:,1)) max(Y(:,1))])
        grid
end

if any(iobs==[2 3 4 7 13 21])
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
save(matname,'reloc_x','reloc_y','min1','min2')

%% Save figure
if ifprint==1
    figname=sprintf('%s/obs%02d_obsloc_hor_result.jpg',figdir,iobs);
    print(figname,'-djpeg','-opengl','-r300');
end
