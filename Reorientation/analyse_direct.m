% analyse_direct.m

% This is the first step of rotating the horizontal component to the raidal
% and the transverse component. Output file can be used for relocation step
% or diectly for rotation step. If relocation is required as a second step,
% it is recommended to redo this analysis to revise orientation
% estimation (set is_re_analyse=1 in this case). Estimate the OBS
% orientation from the plot using the green horizontal line as a guide when
% prompted at the end of the run.
%
% This module requires SegyMAT installed in the path. SegyMat can be
% download from here: http://segymat.sourceforge.net/

% Software Ro4ActiveSrc written by Helen Lau (Dalhousie University), kwhlau@dal.ca
% v1.0 Initial release at Mar. 25, 2021

clear

is_re_analyse=1;    % 0 to use obs_utm_L2.txt; 1 to use relocated output
ifprint=1;    % 1 for saving plot

iobs=18;  % OBS ID number

indir_data='..\Segy\Data_input';   % Directory of input segy data files
indir_nav="..";  % Directory of navigation files
figdir="../fig_dw_analysis";
s_utmfile=indir_nav+"/shot_utm_L2.txt";  % Filename of shot utm navigation
if is_re_analyse
    r_utmfile=sprintf('../Relocation/obs%02d_relo_pos.mat',iobs);
else
    r_utmfile=indir_nav+"/obs_utm_L2.txt"; % Filename of OBS utm navigation
end
pickfile=sprintf('%s/dtime_%02d.pick',indir_nav,iobs); % Filename of direct wave time file
parmfile=indir_nav+"/OBS_hor_assign.txt";  % Filename of OBS horizontal component channel specification file
depthfile=indir_nav+"/obs_depth_L2.txt";   % Filename of OBS depth navigation file
sp_head='FieldRecord';   % Header for shotpoints

%% Channel number
obs_parm=load(parmfile); ch_assign=obs_parm(iobs,1);
% channels for the x- and y-component (2 options)
switch ch_assign
    case 34
        x_ch=3;
        y_ch=4;
    case 43
        x_ch=4;
        y_ch=3;
end
z_ch=2; % vertical component channel number

t_len=obs_parm(iobs,2); % length of time window in second to include water wave
weight=obs_parm(iobs,3); % relative weight at beginning of traces

%% Input pick file
dtime=load(pickfile);
sp_pick=dtime(:,1);
dtime=dtime(:,2)./1000;

%% Input depth
depth=load(depthfile);
depth=depth(iobs);

%% Input navigation files
s_utm=load(s_utmfile);
if is_re_analyse
    rdata=load(r_utmfile);
    r_utm=[rdata.reloc_x rdata.reloc_y];
else
    r_utm=load(r_utmfile); r_utm=r_utm(iobs,:);
end

%% Find geometry for pick
i_pick=arrayfun(@(x) find(s_utm(:,1)==x,1),sp_pick);
pick_utm=s_utm(i_pick,2:3);
s_r_angle=nan(size(sp_pick));
for n=1:length(sp_pick)
    s_r_angle(n)=atan2(r_utm(2)-pick_utm(n,2),r_utm(1)-pick_utm(n,1));
end

s_r_angle=rad2deg(s_r_angle); s_r_angle=wrapTo360(s_r_angle);

%% Input segy data
segyfile_x=sprintf('%s/s2%02dch%1d.sgy',indir_data,iobs,x_ch);
segyfile_y=sprintf('%s/s2%02dch%1d.sgy',indir_data,iobs,y_ch);
segyfile_z=sprintf('%s/s2%02dch%1d.sgy',indir_data,iobs,z_ch);

[Data.x,SegyTraceHeaders,SegyHeader]=ReadSegy(segyfile_x);
sp_all=extractfield(SegyTraceHeaders,sp_head);

tr_pick=arrayfun(@(x) find(sp_all==x,1),sp_pick); % find trace numbers for picks
Data.x=Data.x(:,tr_pick);  % extract data 
[Data.y,~,~]=ReadSegy(segyfile_y);
Data.y=Data.y(:,tr_pick);
[Data.z,~,~]=ReadSegy(segyfile_z);
Data.z=Data.z(:,tr_pick);

%% Apply time window based on picks and analyse for azimuth
dt=SegyHeader.dt/1000/1000;
n_leng=floor(t_len/dt);
time=(0:n_leng-1).*dt;
Data2.x=zeros(length(dtime),n_leng);
Data2.y=Data2.x;
Data2.z=Data2.x;
Data2.r=Data2.x;
Data2.t=Data2.x;
OBS_az=nan(size(dtime));

shift_adjust=-1; % shift the traces down by this # of point (otherwise starts at picked time)
dtime2=dtime;
for n=1:length(dtime)
    n_shift=floor((dtime(n))/dt)+1+shift_adjust;
    t_shift=(n_shift-1)*dt;
    dtime2(n)=dtime(n)-t_shift;
    Data2.x(n,:)=Data.x(n_shift:n_shift+n_leng-1,n);   
    Data2.y(n,:)=Data.y(n_shift:n_shift+n_leng-1,n);
    Data2.z(n,:)=Data.z(n_shift:n_shift+n_leng-1,n);   
    max_amp=max(abs(Data2.z(n,:)));
    Data2.x(n,:)=Data2.x(n,:)./max_amp;       % Normalized amplitude
    Data2.y(n,:)=Data2.y(n,:)./max_amp;
    Data2.z(n,:)=Data2.z(n,:)./max_amp;
    old.x=Data2.x(n,:); old.y=Data2.y(n,:); old.z=Data2.z(n,:);
    [OBS_az(n),Data2.r(n,:),Data2.t(n,:)]=get_OB_azim(old, weight);
end
% Calculate true OBS azimuth with respect to the geographical east
cor_OBS_az=wrapTo360(s_r_angle-OBS_az);

mean_OBS_az=angular_mean(deg2rad(cor_OBS_az));
mean_OBS_az=rad2deg(mean_OBS_az);

%% Visualization
plot_result

%% Save result
if 1
    matfile=sprintf('%s/obs%02d_dw_result.mat',indir_nav,iobs);
    save(matfile,'sp_pick','OBS_az','pick_utm');
    r_az=input('Enter best OBS geo. orientation:','s');
    save(matfile,'r_az','-append')
end