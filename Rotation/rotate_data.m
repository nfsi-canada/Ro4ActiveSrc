function [radial,tra]=rotate_data(x_in,y_in,OBS_az)

%% Perform rotation
radial=x_in.*(cos(OBS_az))+y_in.*(sin(OBS_az)); radial=radial';
tra=-x_in.*(sin(OBS_az))+y_in.*(cos(OBS_az)); tra=tra';