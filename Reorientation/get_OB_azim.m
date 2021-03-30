function [OBS_az,radial,tra]=get_OB_azim(old,weight)
% Data of the three components of variable old are analyzed and the OBS
% orientation with respect to the source-to-receiver path is output. OBS_az is
% the angle from the x component (east) to the source-receiver vector and
% positive anti-clockwise. Note that this code only works for water waves
% going downward (-ve z). OBSs data are assumed upward (z), eastward (x) and 
% northward (y) positive in right-handed coordinates.

% Software Ro4ActiveSrc written by Helen Lau (Dalhousie University), kwhlau@dal.ca
% v1.0 Initial release at Mar. 25, 2021

az=0:5:180;
A=deg2rad(az);

new.r=nan(length(old.x),length(az));
new.t=new.r;

for n=1:length(az)
   r=old.x.*(cos(A(n)))+old.y.*(sin(A(n)));
   t=-old.x.*(sin(A(n)))+old.y.*(cos(A(n)));
   new.r(:,n)=r';
   new.t(:,n)=t';
end

% Weigh up earlier part of trace (Because later time may have more noise)
w=linspace(weight,1,length(old.x));
w=repmat(w',1,length(az));
new_g.r=new.r.*w;
new_g.t=new.t.*w;
ratio=sum(abs(new_g.r))./sum(abs(new_g.t));
[M,I]=max(ratio);

% Check with vertical component
R=corr([new.r(:,I) old.z']);
if R(1,2) < 0
    OBS_az=az(I);
    radial=new.r(:,I)';
    tra=new.t(:,I)';
else
    OBS_az=az(I)+180;
    radial=new.r(:,I)'*-1;
    tra=new.t(:,I)'*-1;
end

% plot(radial)
% hold on
% plot(tra)
  