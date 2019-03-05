function [new_input_file_list, new_output_file_list] = newfiles_check(input_path, output_path, input_naming, output_naming)
%{
newfiles_check(input_path, output_path, input_naming, output_naming)

Calculate which exist already and return only the input and output files
that do not exist and are new.

Given the path of the folder containing files that are going to be used for
a pipeline, the destination folder of the final processed files, and the
extentions of the files as input and output, check which files going
through a specific change in extension alredy exist and return a list of
which ones are new.

Input:
    input_path       String with the full path of the folder containing the
                     input files

    output_path      String with the full path of the folder containing the
                     output files and/or file destination

    input_naming     String of the extention of the input files

    output_naming    String of the extention modifier and identifier the 
                     input files extention is replaced with

Output:
    new_input_file_list     Cell array containing the string names of the 
                            files from the input_path folder that are not 
                            in the output_path folder with their names 
                            modified from their original input_naming 
                            extension to the output_naming form.

    new_output_file_list    Cell array containing the string names of the 
                            expected output files from the input ones.

Example:
    newfiles_check('~\SubjectI_RAW', '~\SubjectI_PROC', ...
                   '.cnt', '_proc.set')

    --Folder and file structure:
    SubjectI_RAW (input_path)  ------>  SubjectI_PROC (output_path)
        |__ s1.cnt                          |__ s1_proc.set
        |__ s2.cnt                          |__ s2_proc.set (output_naming)
        |__ s3.cnt (input_naming)

    --Output the new files that are not in the output_path already
    new_input_file_list = {'s3.cnt'}
    new_output_file_list = {'s3_proc.set'}
%}

% Check input arguments
minArgs=4;
maxArgs=4;
narginchk(minArgs,maxArgs)

% What files should exist already?
temp = dir([input_path '\*' input_naming]);
input_file_list = {temp.name}; % list of input files

% Calculate expected files in output_path
matchpattern = ['(.+)' regexprep(input_naming, '\.', '\\\.')];
replacepattern = ['$1' regexprep(output_naming, '\.', '\\\.')];
expected_output_file_list = regexprep(input_file_list, matchpattern, replacepattern); % expected output files

% Which files already exist?
temp = dir([output_path '\*' output_naming]);
output_file_list = {temp.name}; % list of existing output files

% Compare the expected output files and the existing ones to determine
% which expected output files are new to the set
[~, new_output_index] = setdiff(expected_output_file_list, output_file_list);

% Return the files that are new
new_input_file_list = input_file_list(new_output_index);
new_output_file_list = expected_output_file_list(new_output_index);