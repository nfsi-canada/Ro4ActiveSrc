%run_rotation_segy.m

% This module rotate the two horizontal components of an OBS to its radial
% and transverse component for the whole commone receiver record. The
% vertical component will be expected for plotting. This is the last step
% of the whole process. It expects file output from the relocation step. If
% no relocation is needed, the script should be modified to reflect that 
% (see analyse_direct.m). However, it does not update the OBS positions 
% relocated in the relocation step. Modification of the script will be needed 
% to do so.
%
% This module requires SegyMAT installed in the path. SegyMat can be
% download from here: http://segymat.sourceforge.net/

% Software Ro4ActiveSrc written by Helen Lau (Dalhousie University), kwhlau@dal.ca
% v1.0 Initial release at Mar. 25, 2021

clear

ifplot=1;  % 1 for visual
ifprint=1; % 1 for saving plot
ifwrite=1; % 1 for saving segy output
indir_data='..\Segy\Data_input'; % Directory of input segy data files
indir_nav='..'; % Directory of navigation files
figdir='../fig_rotate_QC';
outdir="..\Segy\Data_rotate";  % Directory of output segy data files
chfile=indir_nav+"/OBS_hor_assign.txt";
depthfile=indir_nav+"/obs_depth_L2.txt";

s_utmfile=indir_nav+"/shot_utm_L2.txt"; % Filename of shot utm navigation
sp_head='FieldRecord';

% addpath("../Reorientation/")

for iobs=18 %[1:4 6:21]
    %% Input files
    azfile=sprintf('%s/obs%02d_dw_result.mat',indir_nav,iobs);
    pickfile=sprintf('%s/dtime_%02d.pick',indir_nav,iobs);
    r_utmfile=sprintf('../Relocation/obs%02d_relo_pos.mat',iobs);
    r_az=load(azfile,'r_az'); r_az=str2double(r_az.r_az);
    s_utm=load(s_utmfile);
    load(r_utmfile)
    r_utm=[reloc_x reloc_y];
        
    %% Channel number
    ch_assign=load(chfile); ch_assign=ch_assign(iobs,1);
    switch ch_assign
        case 34
            x_ch=3;
            y_ch=4;
        case 43
            x_ch=4;
            y_ch=3;
    end
    z_ch=2;

    %% Input depth
    depth=load(depthfile);
    depth=depth(iobs);
    
    %% Input segy data
    segyfile_x=sprintf('%s/s2%02dch%1d.sgy',indir_data,iobs,x_ch);
    segyfile_y=sprintf('%s/s2%02dch%1d.sgy',indir_data,iobs,y_ch);
    [Data.x,SegyTraceHeaders,SegyHeader]=ReadSegy(segyfile_x);
    [Data.y,~,~]=ReadSegy(segyfile_y);
    sp_all=extractfield(SegyTraceHeaders,sp_head);
    offset=[SegyTraceHeaders(:).offset]/1000;
    
    %% Find geometry for pick
    i_tr=arrayfun(@(x) find(s_utm(:,1)==x,1),sp_all);
    tr_utm=s_utm(i_tr,2:3);
    s_r_angle=nan(size(sp_all));
    s_r_diag=s_r_angle;
    for n=1:length(sp_all)
        s_r_diag(n)=norm([r_utm depth]-[tr_utm(n,:) 0]);
        s_r_angle(n)=atan2(r_utm(2)-tr_utm(n,2),r_utm(1)-tr_utm(n,1));
    end
    az=s_r_angle-deg2rad(r_az); az=wrapTo2Pi(az);
    dtime=s_r_diag./1500;
    
    %% Rotate to get radial and tranverse component
    R=nan(size(Data.x)) ; T=R;
    for n=1:length(sp_all)
       [R(:,n),T(:,n)]=rotate_data(Data.x(:,n),Data.y(:,n),az(n));
    end

    %% Output segy
    if ifwrite
        % Azimuth (radian) text file for undoing rotation
        az=az';
        az_file=sprintf('%s/obs%02d_azimuth_rad.txt',outdir,iobs);
        saveascii(az,az_file,'%f');
        
        % Segy files
        segyfile_r=sprintf('%s/obs%02d_radial.sgy',outdir,iobs);
        segyfile_t=sprintf('%s/obs%02d_transverse.sgy',outdir,iobs);
        WriteSegyStructure(segyfile_r,SegyHeader,SegyTraceHeaders(:),R);
        WriteSegyStructure(segyfile_t,SegyHeader,SegyTraceHeaders(:),T);       
    end
 
    %% Visualization
    if ifplot
        % Input vertical comp.
        segyfile_z=sprintf('%s/s2%02dch%1d.sgy',indir_data,iobs,z_ch);
        [Data.z,~,~]=ReadSegy(segyfile_z);

        % Combine all components into one
        Old=nan([size(Data.x) 3]);
        New=nan([size(Data.x) 2]);
        Old(:,:,1)=Data.x; Old(:,:,2)=Data.y; Old(:,:,3)=Data.z;
        New(:,:,1)=R; New(:,:,2)=T;
        clear Data R T

        cmap=gray;
        time=SegyHeader.time;
        dt=SegyHeader.dt/1000/1000;
        %% Reduce data using dtime
        new_length=floor(1/dt);
        first=floor((dtime)./dt)+1;  % Top of time window in points
        first=first-min([15 min(first)-1]);
        good_tr=find(abs(offset)<15);  % Offset limits
        Old=Old(:,good_tr,:);
        New=New(:,good_tr,:);
        first=first(good_tr);
        offset=offset(good_tr);
        time=time(1:1+new_length);
        Old_cut=nan(length(time),length(good_tr),3);
        New_cut=nan(length(time),length(good_tr),2);

        for n=1:length(good_tr)
            Old_cut(:,n,:)=Old(first(n):first(n)+new_length,n,:);
            New_cut(:,n,:)=New(first(n):first(n)+new_length,n,:);
        end
        clear Old New
        % Normalize amplitude
        max_z=max(abs(Old_cut(:,:,3)));
        max_z2=repmat(max_z,size(Old_cut,1),1,3);
        Old_cut=Old_cut./max_z2;
        max_z2(:,:,3)=[];
        New_cut=New_cut./max_z2;

        plot_result_ro
    end
end
