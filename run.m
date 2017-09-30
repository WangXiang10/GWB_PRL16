% % demo for GWB
% @article{wang2016geodesic,
%   title={Geodesic Weighted Bayesian Model for Saliency Optimization},
%   author={Wang, Xiang and Ma, Huimin and Chen, Xiaozhi},
%   journal={Pattern Recognition Letters},
%   volume={75},
%   pages={1--8},
%   year={2016},
%   publisher={Elsevier}
% }
% @inproceedings{icip15gwb,
%   author    = {Wang, Xiang and Ma, Huimin and Chen, Xiaozhi},
%   title     = {Geodesic Weighted {B}ayesian Model for Salient Object Detection},
%   booktitle = {IEEE ICIP},
%   year      = {2015},
%   pages	    = {397-401},
%   doi	    = {10.1109/ICIP.2015.7350828}
% }
%%
clear all;
close all;
clc;

addpath(genpath('Funcs'));
addpath('..');
addpath('include');
addpath([fileparts(mfilename('fullpath')) filesep 'include']);

vlpath = '';
mexopencvpath = '';
addpath(vlpath);
addpath(mexopencvpath);
%%
srcSuffix = '.jpg';
Src = 'Imgs';

SrcPsal = 'UnarySalMap';
Psal_suffix = '_RBD.png';
IniSalRegion = 'IniSalRegion';
if ~exist(IniSalRegion,'dir')
    mkdir(IniSalRegion);
end
crfSuffix = '_crf.png';

OriSalMaps = 'OriSalMaps';
OriSauffix = '_RC.png';


Result = 'ResultsImproved';
if ~exist(Result, 'dir')
    mkdir(Result);
end

%%
files = dir(fullfile(Src, strcat('*', srcSuffix)));
len = 3;
get_initial_salreg;
improve_via_bayesian;