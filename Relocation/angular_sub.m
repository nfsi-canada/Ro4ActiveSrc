function [ad]=angular_sub(ang1,ang2)
% This function return the absolute angular differences between two angles.
% This solved the problem of wrap around. Angles are in degree.

if size(ang1)~=size(ang2)
    error("ang2 and ang3 not of the same size")
end
d1=abs(ang1-ang2); d2=abs(ang1-ang2+360);
d3=abs(ang1-ang2-360);
ad=nan(1,length(ang1));
for m=1:length(ang1)
    ad(m)=min(abs(wrapTo180([d1(m) d2(m) d3(m)])));
end