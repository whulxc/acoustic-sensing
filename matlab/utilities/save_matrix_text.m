function save_matrix_text(file_path, matrix_value)
%SAVE_MATRIX_TEXT Save a numeric matrix as a space-separated text file.

fid = fopen(file_path, 'w');
if fid < 0
    error('Unable to open output file: %s', file_path);
end

cleanup = onCleanup(@() fclose(fid));
[num_rows, num_cols] = size(matrix_value);
for row = 1:num_rows
    for col = 1:num_cols
        if col == num_cols
            fprintf(fid, '%f\n', matrix_value(row, col));
        else
            fprintf(fid, '%f ', matrix_value(row, col));
        end
    end
end

delete(cleanup);
end
