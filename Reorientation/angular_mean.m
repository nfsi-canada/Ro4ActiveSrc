function a_mean=angular_mean(in_array)

mean_sin=mean(sin(in_array));
mean_cos=mean(cos(in_array));
if (mean_sin > 0) && (mean_cos > 0)
    a_mean=atan(mean_sin/mean_cos);
elseif mean_cos < 0
    a_mean=atan(mean_sin/mean_cos)+pi; 
elseif (mean_sin < 0) && (mean_cos > 0)
    a_mean=atan(mean_sin/mean_cos)+2*pi;
end
