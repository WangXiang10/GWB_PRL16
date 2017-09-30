#include "meanfield.h"
#include "solvers.h"
#include <memory>
#include "mex.h"
#include <time.h>
#include <stdio.h>
double timer;

// Catch errors
static void erfunc(char *err) {
  mexErrMsgTxt(err);
}

void mexFunction(int nlhs, 		    /* number of expected outputs */
        mxArray        *plhs[],	    /* mxArray output pointer array */
        int            nrhs, 		/* number of inputs */
        const mxArray  *prhs[]		/* mxArray input pointer array */)
{
    //startTime();

    // Parsing data from MATLAB
    if (nrhs != 6)
        mexErrMsgTxt("Expected 5 inputs");

    const matrix<float> im_matrix(prhs[0]);
    const matrix<float>  lbp_matrix(prhs[1]);
	const matrix<float>  unary_matrix(prhs[2]);
	const matrix<float> px(prhs[3]);
	const matrix<float> py(prhs[4]);
	
    //Structure to hold and parse additional parameters
    MexParams params(1, prhs + 5);

    // Weights used to define the energy function
    PairwiseWeights pairwiseWeights(params);
    const bool debug = params.get<bool>("debug", false);
    const int iterations = params.get<int>("iterations", 20);
	const int Lbpbins = params.get<int>("Lbpbins", 8);

    // Used only for TRW-S
    const double min_pairwise_cost = params.get<double>("min_pairwise_cost", 0);
    string solver = params.get<string>("solver", "Not set");

    // The image
    const int M = px.numel();
	const int N = 1;
	const int C = 1;
	const int numVariables = M;
	// Calculate number of labels
    //const int UC = unary_matrix.numel();
    const int numberOfLabels = 2;

    // Read image and unary
    const float * image  = im_matrix.data;
    const float * lbp  = lbp_matrix.data;
	float * unary_array  = unary_matrix.data;
	const float * spx = px.data;
	const float * spy = py.data;
	
    // Oracle function to get cost
	LinearIndex unaryLinearIndex(M, N, numberOfLabels);
	LinearIndex OneChannelLinearIndex(M, N, 1);
	LinearIndex imageLinearIndex(M, M, C);
	LinearIndex lbpLinearIndex(M, M, C);

    Linear2sub linear2sub(M,N);
    UnaryCost unaryCost(unary_array, unaryLinearIndex);

    if (debug)
    {
      mexPrintf("min_pairwise_cost: %g \n", min_pairwise_cost);
      mexPrintf("Problem size: %d x %d \n", M,N);

      //endTime("Reading data.");
    }
	 //endTime("Reading data.");

	  //startTime();
    matrix<double> result(M,N);
    matrix<double> energy(1);
    matrix<double> bound(1);

    plhs[0] = result;
    plhs[1] = energy;
    plhs[2] = bound;

    PairwiseCost pairwiseCost(image, lbp, spx, spy, pairwiseWeights, imageLinearIndex, OneChannelLinearIndex);
    EnergyFunctor energyFunctor(unaryCost, pairwiseCost, M,N, numberOfLabels);

    // Mean field
    if(!solver.compare("mean_field"))  {
      //if (debug)
        //endTime("Solving using mean field approximation and approximate gaussian filters.");

      // Setup the CRF model
      extendedDenseCRF2D crf(M,N,numberOfLabels);
      Eigen::Map<Eigen::MatrixXf> unary(unary_array, numberOfLabels, numVariables);

      crf.setUnaryEnergy( unary );

      KernelType kerneltype = CONST_KERNEL;
      NormalizationType normalizationtype = parseNormalizationType(params);
	  PottsCompatibility * PottsCompa = new PottsCompatibility(pairwiseWeights.bilateral_weight);
      // Setup  pairwise cost
      crf.addPairwiseGaussian(pairwiseWeights.gaussian_x_stddev,
                              pairwiseWeights.gaussian_y_stddev,
							  spx,
							  spy,
                              new PottsCompatibility(pairwiseWeights.gaussian_weight),
                              kerneltype,
                              normalizationtype);

      crf.addPairwiseBilateral(pairwiseWeights.bilateral_x_stddev,
                               pairwiseWeights.bilateral_y_stddev,
                               pairwiseWeights.bilateral_r_stddev,
                               pairwiseWeights.bilateral_g_stddev,
                               pairwiseWeights.bilateral_b_stddev,
							   pairwiseWeights.bilateral_lbp_stddev,
							   pairwiseWeights.bilateral_com_stddev,
                               image,
							   lbp,
							   Lbpbins,
							   spx,
							   spy,
                               new PottsCompatibility(pairwiseWeights.bilateral_weight),
                               kerneltype,
                               normalizationtype);

      // Do map inference
      VectorXs map = crf.map(iterations);

      //Packing data in the same way as input
      for (int i = 0; i < numVariables; i++ ) {
           result(i) = (double)map[i];
      }

      energy(0) = crf.energy(map);
      bound(0) = lowestUnaryCost( unary_array, M,N,numberOfLabels );

	   //endTime("Inference");


    } else if (!solver.compare("mean_field_explicit"))  {

     // if (debug)
        //endTime("Solving using mean field approximation by explicit summation");
      // Init
      matrix<double> Q(M,N,numberOfLabels);
      matrix<double> addative_sum(M,N,numberOfLabels);
	  float tmp4;
	  for (int x = 0; x < M; x++) {
		  for (int y = 0; y < N; y++) {
			  for (int l = 0; l < numberOfLabels; l++) {
				  tmp4 = unaryCost(x,y,l);
				  Q(x,y,l) = exp(-unaryCost(x,y,l));
			  }
		  }
	  }

      normalize(Q);
	  float tmp1, tmp2, tmp3;
      for (int i = 0; i < iterations; i++)
      {
        // Pairwise count negative when equal (faster)
        for (int label = 0; label < numberOfLabels; label++) {
			for (int x = 0; x < M; x++) {
				for (int y = 0; y < N; y++) {

					addative_sum(x,y,label) = unaryCost(x,y,label);
					tmp3 = addative_sum(x,y,label);
					for (int x_target = 0; x_target < M; x_target++) {
						for (int y_target = 0; y_target < N; y_target++) {
							tmp1 = pairwiseCost(x, y, x_target, y_target);
							tmp2 = Q( x_target, y_target, label );

							addative_sum(x,y,label) -=
								pairwiseCost(x, y, x_target, y_target)*
								Q( x_target, y_target, label );
						}
					}
				}
			}
		}

        for (int i = 0; i < Q.numel(); i++)
          Q(i) = exp( - addative_sum(i) );

        normalize(Q);
      }

      matrix<double> result(M,N);
      matrix<double> energy(1);
      matrix<double> bound(1);

      double max_prob;
      for (int x = 0; x < M; x++) {
      for (int y = 0; y < N; y++) {
        max_prob = Q(x,y,0);
        result(x,y) = 0;

        for (int l = 1; l < numberOfLabels; l++)
        {
          if (Q(x,y,l) > max_prob)
          {
            max_prob = Q(x,y,l);
            result(x,y) = l;
          }
        }
      }
      }

      energy(0) = std::numeric_limits<double>::quiet_NaN();
      bound(0) = std::numeric_limits<double>::quiet_NaN();


    } else if(!solver.compare("trws")) {

      //if (debug)
        //endTime("Convergent Tree-reweighted Message Passing");

      TypePotts::REAL TRWSenergy, TRWSlb;
      TRWSOptions options;
      options.m_iterMax = iterations;
      options.m_eps = 0;

      if (!debug)
        options.m_printMinIter = iterations+2;

      TRWS * mrf = new TRWS(TypePotts::GlobalSize(numberOfLabels),erfunc);
      TRWSNodes * nodes = new TRWSNodes[numVariables];

      std::vector<TypePotts::REAL> D(numberOfLabels);

      for (int i = 0; i < numVariables; i++)
      {
        for(int s = 0; s < numberOfLabels; ++s)
        {
          std::pair<int,int> p = linear2sub(i);
          D[s] = unaryCost( p, s );
        }

        nodes[i] = mrf->AddNode(TypePotts::LocalSize(),
                                TypePotts::NodeData(&D[0]));
      }

      // Pairwise cost
      for (int i = 0; i < numVariables; i++) {
      for (int j = i+1; j < numVariables; j++) {
        std::pair<int,int> p0 = linear2sub(i);
        std::pair<int,int> p1 = linear2sub(j);

        double pcost = pairwiseCost( p0, p1 );

        if (pcost >= min_pairwise_cost)
            mrf->AddEdge(nodes[i], nodes[j], TypePotts::EdgeData(pcost));
      }
      }

      mrf->Minimize_TRW_S(options, TRWSlb, TRWSenergy);

      for (int i = 0; i < numVariables; i++)
        result(i) = mrf->GetSolution(nodes[i]);

      energy(0) = TRWSenergy;
      bound(0) = TRWSlb;

      delete mrf;
      delete nodes;

      return;
    } else if (!solver.compare("graph_cuts")) {
        int numEdges = numVariables*(numVariables-1)/2;
        std::auto_ptr<GraphType> g (new GraphType(numVariables, numEdges));
        g -> add_node(numVariables); 
          
        // Unary cost
        for (int i = 0; i < numVariables; ++i) {
          std::pair<int,int> p = linear2sub(i);
          g->add_tweights(i, unaryCost( p, 1), unaryCost( p, 0));
        }

        // Pairwise cost
        for (int i = 0; i < numVariables; i++) {
        for (int j = i+1; j < numVariables; j++) {
          std::pair<int,int> p0 = linear2sub(i);
          std::pair<int,int> p1 = linear2sub(j);

          double pcost = pairwiseCost( p0, p1 );
          if (pcost >= min_pairwise_cost) g->add_edge(i ,j , pcost, pcost);
        }
        }

        energy(0) = g->maxflow();
        bound(0) = energy(0);

        for (int i = 0; i < numVariables; ++i) {
          result(i) = g->what_segment(i);
        }

    } else {
      mexErrMsgTxt("Unkown solver.");
    }
}