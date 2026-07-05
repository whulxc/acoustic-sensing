%% mat数组保存为txt %%
function []=save_matrix_text(DirPath,mat)
fid=fopen(DirPath,'w');
[m,n]=size(mat);
for i=1:m
   for j=1:n
      if j==n
         fprintf(fid,'%f\n',mat(i,j));
      else
         fprintf(fid,'%f ',mat(i,j));
      end
   end 
end
fclose(fid);
end
