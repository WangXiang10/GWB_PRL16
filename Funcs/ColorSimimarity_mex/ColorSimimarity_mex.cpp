#include <math.h>
#include <matrix.h>
#include <mex.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
// ColorSim = ColorSimimaritySpeedUp(SrcImgLab, pixelList, 32);
void mexFunction(int nlhs, 		    /* number of expected outputs */
        mxArray        *plhs[],	    /* mxArray output pointer array */
        int            nrhs, 		/* number of inputs */
        const mxArray  *prhs[]		/* mxArray input pointer array */)
{
    const mwSize *dims;
    mwSize total_num_of_cells;
    const mxArray *cellArray;
    mwIndex jcell;
    
    const double * image  = (double*)mxGetPr(prhs[0]);
    const mxArray *cell = prhs[1];
    double * bins_d  = (double*)mxGetPr(prhs[2]);
    int bins = (int)bins_d[0];
    double * w_d  = (double*)mxGetPr(prhs[3]);
    int w = (int)w_d[0];
    double * h_d  = (double*)mxGetPr(prhs[4]);
    int h = (int)h_d[0];
    double * L = image;
    double * A = image + w * h;
    double * B = image + 2 * w * h;
    
//     for(int i = 0; i< 360900; i++){
//         if(i % 300 == 0){
//             printf("\n");}
//         if(i % (300*401) == 0){
//             printf("\n New Channel \n");}
//             printf("%f ",image[i]);
//         }
    for(int i = 0; i < dims[0]; i++){
        
    

   
    dims = mxGetDimensions(prhs[1]);
    for (jcell=0; jcell<dims[0]; jcell++) {
        cellArray = mxGetCell(cell,jcell);
        total_num_of_cells = mxGetNumberOfElements(cellArray);
//         mexPrintf("total num of cells = %d\n", total_num_of_cells);
//         mexPrintf("\n");
//         p = (double*)mxGetData(cellArray);
//         for(int i = 0; i< total_num_of_cells; i++){
//             printf("%f ",p[i]);
//         }
//         for (index=0; index<1; index++)  {
//             mexPrintf("\n\n\t\tCell Element: ");
//             cellElement = mxGetCell(cellArray, index);
//             p = mxGetPr(cellElement);
//             printf("%g ",*p);
//         }
//         printf("\n ");
    }
    return;
}
