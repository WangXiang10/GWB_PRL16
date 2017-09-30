# Geodesic Weighted Bayesian Model for Saliency Optimization(GWB)
Copyright 2016 Xiang Wang (wangxiang14@mails.tsinghua.edu.cn).

## Introduction

GWB can be used to improve the quality of most existing salient object detection models with little computation overhead.
**0.36s** per image.
If you use GWB, please cite the following papers:


@article{wang2016geodesic,
  title={Geodesic Weighted Bayesian Model for Saliency Optimization},
  author={Wang, Xiang and Ma, Huimin and Chen, Xiaozhi},
  journal={Pattern Recognition Letters},
  volume={75},
  pages={1--8},
  year={2016},
  publisher={Elsevier}
}


@inproceedings{icip15gwb,
  author    = {Wang, Xiang and Ma, Huimin and Chen, Xiaozhi},
  title     = {Geodesic Weighted {B}ayesian Model for Salient Object Detection},
  booktitle = {IEEE ICIP},
  year      = {2015},
  pages	    = {397-401},
  doi	    = {10.1109/ICIP.2015.7350828}
}

\
## Installation

* vlfeat toolbox is required. Download vlfeat from http://www.vlfeat.org/ and addpath('\path\to\vlfeat')
* mexopencv is required. Download mexopencv from https://github.com/kyamagu/mexopencv and  addpath('\path\to\mexopencv')
* Please refer to http://www.philkr.net/ for compiling the dense crf code.

@misc{vedaldi08vlfeat,
 Author = {A. Vedaldi and B. Fulkerson},
 Title = {{VLFeat}: An Open and Portable Library
          of Computer Vision Algorithms},
 Year  = {2008},
 Howpublished = {\url{http://www.vlfeat.org/}}


---------------------------------------------------------------------------
## Demo for GWB

GWB can be integrated into any existing salient object detection models. 
Run 'run.m' which using an image as source image and a saliency map as prior distribution, 
this demo will first generate a initial salient region via dense CRF,
and then generate a improved saliency map using GWB, and save it in the ResultsImproved path.
A comparison will also be shown.


---------------------------------------------------------------------------
## Acknowledgements

We use or modify: 
* K. van de Sande's code for colorspaces conversion, 
* Wangjiang Zhu's code for calculating geodesic distance
* Yulin Xie's code for calculating probabilities
* P. Felzenszwalb's code for graph-based segmentation. 
* Philipp Kr¨ahenb¨uhl's code for dense CRF inference.
