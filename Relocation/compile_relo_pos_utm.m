% compile_relo_pos_utm.m

ux=zeros(1,21);
uy=ux;
fileID = fopen('relo_pos_utm_s.txt','w');
for iobs=1:21
    r_utmfile=sprintf('obs%02d_relo_pos.mat',iobs);
    try
        load(r_utmfile,'reloc_x', 'reloc_y')
        ux(iobs)=reloc_x;
        uy(iobs)=reloc_y;
    catch
        ux(iobs)=NaN;
        uy(iobs)=NaN;
    end
end

fprintf(fileID,'%6f %6f\n',[ux; uy]);
fclose(fileID);

