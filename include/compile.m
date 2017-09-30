% Compile files only if needed
function compile(cpp_file, out_file, sources, extra_arguments, ifg)
if nargin < 5
    ifg = 0;
end
% Process
my_name = mfilename('fullpath');
my_path = [fileparts(my_name)];
mex_file_name = [my_path filesep out_file '.' mexext];
cpp_file_name = [my_path filesep cpp_file];

mex_file = dir(mex_file_name);
cpp_file = dir(cpp_file_name);

if length(mex_file) == 1
    mex_modified = mex_file.datenum;
else
    mex_modified = 0;
end

cpp_modified   = cpp_file.datenum;

% If modified ocd r not existant compile
compile_file = false;
if ~exist(mex_file_name, 'file')
    compile_file = true;
elseif mex_modified < cpp_modified
    compile_file = true;
end

include_folders = {};

% Append current folder to sources
for i = 1 : length(sources);
	include_folders{i} = ['-I' my_path filesep fileparts(sources{i}) filesep];
	sources{i} = [my_path filesep sources{i}];
end

% Check all dependend files
for i = 1 : length(sources)
	cpp_file = dir(sources{i});
	cpp_modified = cpp_file.datenum;
	if mex_modified < cpp_modified
		compile_file = true;
	end
end

args = {extra_arguments{:},include_folders{:},sources{:}};

if compile_file
    if ifg
        mex(cpp_file_name,'-g', '-outdir',my_path, args{:});
    else
        mex(cpp_file_name, '-outdir',my_path, args{:});
    end
end
