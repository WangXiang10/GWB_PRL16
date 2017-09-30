/*
    Copyright (c) 2013, Philipp Krähenbühl
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:
        * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
        * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution.
        * Neither the name of the Stanford University nor the
        names of its contributors may be used to endorse or promote products
        derived from this software without specific prior written permission.

    THIS SOFTWARE IS PROVIDED BY Philipp Krähenbühl ''AS IS'' AND ANY
    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL Philipp Krähenbühl BE LIABLE FOR ANY
    DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
    (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
    ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
    (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "..\include\densecrf.h"
#include "..\include\permutohedral.h"
#include "util.h"
#include "..\include\pairwise.h"
#include <cmath>
#include <cstring>
#include <iostream>

/////////////////////////////
/////  Alloc / Dealloc  /////
/////////////////////////////
DenseCRF::DenseCRF(int N, int M) : N_(N), M_(M), unary_(0) {
}
DenseCRF::~DenseCRF() {
	if (unary_)
		delete unary_;
	for( unsigned int i=0; i<pairwise_.size(); i++ )
		delete pairwise_[i];
}
DenseCRF2D::DenseCRF2D(int W, int H, int M) : DenseCRF(W*H,M), W_(W), H_(H) {
}
DenseCRF2D::~DenseCRF2D() {
}
/////////////////////////////////
/////  Pairwise Potentials  /////
/////////////////////////////////
void DenseCRF::addPairwiseEnergy (const Eigen::MatrixXf & features, LabelCompatibility * function, KernelType kernel_type, NormalizationType normalization_type) {
	assert( features.cols() == N_ );
	addPairwiseEnergy( new PairwisePotential( features, function, kernel_type, normalization_type ) );
}
void DenseCRF::addPairwiseEnergy ( PairwisePotential* potential ){
	pairwise_.push_back( potential );
}
void DenseCRF2D::addPairwiseGaussian ( float sx, float sy, const float * spx, const float * spy, LabelCompatibility * function, KernelType kernel_type, NormalizationType normalization_type ) {
	Eigen::MatrixXf feature( 2, N_ );
	
		for( int i=0; i<N_; i++ ){
			feature(0,i) = spx[i] / sx;
			feature(1,i) = spy[i] / sy;
		}
	addPairwiseEnergy( feature, function, kernel_type, normalization_type );
}
void DenseCRF2D::addPairwiseBilateral ( float sx, float sy, float sr, float sg, float sb, float slbp, float scom, const float * im, const float * lbp, const int Lbpbins, const float * spx, const float * spy, LabelCompatibility * function, KernelType kernel_type, NormalizationType normalization_type ) {
	Eigen::MatrixXf feature( 5 + Lbpbins, N_ );
	for( int i=0; i<W_; i++ ){
			feature(0,i) = spx[i] / sx;
			feature(1,i) = spy[i] / sy;
			feature(2,i) = im[i * 3] / sr;
			feature(3,i) = im[i * 3 + 1] / sr;
			feature(4,i) = im[i * 3 + 2] / sr;
			for (int l = 0; l < Lbpbins; l++)
			{
				feature(5 + l,i) = lbp[i * Lbpbins + l] / slbp;
			}
		}
	addPairwiseEnergy( feature, function, kernel_type, normalization_type );
}
//////////////////////////////
/////  Unary Potentials  /////
//////////////////////////////
void DenseCRF::setUnaryEnergy ( UnaryEnergy * unary ) {
	if( unary_ ) delete unary_;
	unary_ = unary;
}
void DenseCRF::setUnaryEnergy( const Eigen::MatrixXf & unary ) {
	setUnaryEnergy( new ConstUnaryEnergy( unary ) );
}
void  DenseCRF::setUnaryEnergy( const Eigen::MatrixXf & L, const Eigen::MatrixXf & f ) {
	setUnaryEnergy( new LogisticUnaryEnergy( L, f ) );
}
///////////////////////
/////  Inference  /////
///////////////////////
void expAndNormalize ( Eigen::MatrixXf & out, const Eigen::MatrixXf & in ) {
	out.resize( in.rows(), in.cols() );
	for( int i=0; i<out.cols(); i++ ){
		Eigen::VectorXf b = in.col(i);
		b.array() -= b.maxCoeff();
		b = b.array().exp();
		out.col(i) = b / b.array().sum();
	}
}
void sumAndNormalize( Eigen::MatrixXf & out, const Eigen::MatrixXf & in, const Eigen::MatrixXf & Q ) {
	out.resize( in.rows(), in.cols() );
	for( int i=0; i<in.cols(); i++ ){
		Eigen::VectorXf b = in.col(i);
		Eigen::VectorXf q = Q.col(i);
		out.col(i) = b.array().sum()*q - b;
	}
}
Eigen::MatrixXf DenseCRF::inference ( int n_iterations ) const {
	Eigen::MatrixXf Q( M_, N_ ), tmp1, unary( M_, N_ ), tmp2;
	unary.fill(0);
	if( unary_ )
		unary = unary_->get();
	expAndNormalize( Q, -unary );
	
	for( int it=0; it<n_iterations; it++ ) {
		tmp1 = -unary;
		for( unsigned int k=0; k<pairwise_.size(); k++ ) {
			pairwise_[k]->apply( tmp2, Q );
			tmp1 -= tmp2;
		}
		expAndNormalize( Q, tmp1 );
	}
	return Q;
}
VectorXs DenseCRF::map ( int n_iterations ) const {
	// Run inference
	Eigen::MatrixXf Q = inference( n_iterations );
	// Find the map
	return currentMap( Q );
}
///////////////////
/////  Debug  /////
///////////////////
Eigen::VectorXf DenseCRF::unaryEnergy(const VectorXs & l) {
	//assert( l.cols() == N_ );
	Eigen::VectorXf r( N_ );
	r.fill(0.f);
	if( unary_ ) {
		Eigen::MatrixXf unary = unary_->get();
		
		for( int i=0; i<N_; i++ )
			if ( 0 <= l[i] && l[i] < M_ )
				r[i] = unary( l[i], i );
	}
	return r;
}
Eigen::VectorXf DenseCRF::pairwiseEnergy(const VectorXs & l, int term) {
	//assert( l.cols() == N_ );
	Eigen::VectorXf r( N_ );
	r.fill(0.f);
	
	if( term == -1 ) {
		for( unsigned int i=0; i<pairwise_.size(); i++ )
			r += pairwiseEnergy( l, i );
		return r;
	}
	
	Eigen::MatrixXf Q( M_, N_ );
	// Build the current belief [binary assignment]
	for( int i=0; i<N_; i++ )
		for( int j=0; j<M_; j++ )
			Q(j,i) = (l[i] == j);
	pairwise_[ term ]->apply( Q, Q );
	for( int i=0; i<N_; i++ )
		if ( 0 <= l[i] && l[i] < M_ )
			r[i] =-0.5*Q(l[i],i );
		else
			r[i] = 0;
	return r;
}
Eigen::MatrixXf DenseCRF::startInference() const{
	Eigen::MatrixXf Q( M_, N_ );
	Q.fill(0);
	
	// Initialize using the unary energies
	if( unary_ )
		expAndNormalize( Q, -unary_->get() );
	return Q;
}
void DenseCRF::stepInference( Eigen::MatrixXf & Q, Eigen::MatrixXf & tmp1, Eigen::MatrixXf & tmp2 ) const{
	tmp1.resize( Q.rows(), Q.cols() );
	tmp1.fill(0);
	if( unary_ )
		tmp1 -= unary_->get();
	
	// Add up all pairwise potentials
	for( unsigned int k=0; k<pairwise_.size(); k++ ) {
		pairwise_[k]->apply( tmp2, Q );
		tmp1 -= tmp2;
	}
	
	// Exponentiate and normalize
	expAndNormalize( Q, tmp1 );
}
VectorXs DenseCRF::currentMap( const Eigen::MatrixXf & Q ) const{
	VectorXs r(Q.cols());
	// Find the map
	for( int i=0; i<N_; i++ ){
		int m;
		Q.col(i).maxCoeff( &m );
		r[i] = m;
	}
	return r;
}

// Compute the KL-divergence of a set of marginals
double DenseCRF::klDivergence( const Eigen::MatrixXf & Q ) const {
	double kl = 0;
	// Add the entropy term
	for( int i=0; i<Q.cols(); i++ )
		for( int l=0; l<Q.rows(); l++ )
			kl += Q(l,i)*log(std::max( Q(l,i), 1e-20f) );
	// Add the unary term
	if( unary_ ) {
		Eigen::MatrixXf unary = unary_->get();
		for( int i=0; i<Q.cols(); i++ )
			for( int l=0; l<Q.rows(); l++ )
				kl += unary(l,i)*Q(l,i);
	}
	
	// Add all pairwise terms
	Eigen::MatrixXf tmp;
	for( unsigned int k=0; k<pairwise_.size(); k++ ) {
		pairwise_[k]->apply( tmp, Q );
		kl += (Q.array()*tmp.array()).sum();
	}
	return kl;
}

// Gradient computations
double DenseCRF::gradient( int n_iterations, const ObjectiveFunction & objective, Eigen::VectorXf * unary_grad, Eigen::VectorXf * lbl_cmp_grad, Eigen::VectorXf * kernel_grad) const {
	// Run inference
	std::vector< Eigen::MatrixXf > Q(n_iterations+1);
	Eigen::MatrixXf tmp1, unary( M_, N_ ), tmp2;
	unary.fill(0);
	if( unary_ )
		unary = unary_->get();
	expAndNormalize( Q[0], -unary );
	for( int it=0; it<n_iterations; it++ ) {
		tmp1 = -unary;
		for( unsigned int k=0; k<pairwise_.size(); k++ ) {
			pairwise_[k]->apply( tmp2, Q[it] );
			tmp1 -= tmp2;
		}
		expAndNormalize( Q[it+1], tmp1 );
	}
	
	// Compute the objective value
	Eigen::MatrixXf b( M_, N_ );
	double r = objective.evaluate( b, Q[n_iterations] );
	sumAndNormalize( b, b, Q[n_iterations] );

	// Compute the gradient
	if(unary_grad && unary_)
		*unary_grad = unary_->gradient( b );
	if( lbl_cmp_grad )
		*lbl_cmp_grad = 0*labelCompatibilityParameters();
	if( kernel_grad )
		*kernel_grad = 0*kernelParameters();
	
	for( int it=n_iterations-1; it>=0; it-- ) {
		// Do the inverse message passing
		tmp1.fill(0);
		int ip = 0, ik = 0;
		// Add up all pairwise potentials
		for( unsigned int k=0; k<pairwise_.size(); k++ ) {
			// Compute the pairwise gradient expression
			if( lbl_cmp_grad ) {
				Eigen::VectorXf pg = pairwise_[k]->gradient( b, Q[it] );
				lbl_cmp_grad->segment( ip, pg.rows() ) += pg;
				ip += pg.rows();
			}
			// Compute the kernel gradient expression
			if( kernel_grad ) {
				Eigen::VectorXf pg = pairwise_[k]->kernelGradient( b, Q[it] );
				kernel_grad->segment( ik, pg.rows() ) += pg;
				ik += pg.rows();
			}
			// Compute the new b
			pairwise_[k]->applyTranspose( tmp2, b );
			tmp1 += tmp2;
		}
		sumAndNormalize( b, tmp1.array()*Q[it].array(), Q[it] );
		
		// Add the gradient
		if(unary_grad && unary_)
			*unary_grad += unary_->gradient( b );
	}
	return r;
}
Eigen::VectorXf DenseCRF::unaryParameters() const {
	if( unary_ )
		return unary_->parameters();
	return Eigen::VectorXf();
}
void DenseCRF::setUnaryParameters( const Eigen::VectorXf & v ) {
	if( unary_ )
		unary_->setParameters( v );
}
Eigen::VectorXf DenseCRF::labelCompatibilityParameters() const {
	std::vector< Eigen::VectorXf > terms;
	for( unsigned int k=0; k<pairwise_.size(); k++ )
		terms.push_back( pairwise_[k]->parameters() );
	int np=0;
	for( unsigned int k=0; k<pairwise_.size(); k++ )
		np += terms[k].rows();
	Eigen::VectorXf r( np );
	for( unsigned int k=0,i=0; k<pairwise_.size(); k++ ) {
		r.segment( i, terms[k].rows() ) = terms[k];
		i += terms[k].rows();
	}	
	return r;
}
void DenseCRF::setLabelCompatibilityParameters( const Eigen::VectorXf & v ) {
	std::vector< int > n;
	for( unsigned int k=0; k<pairwise_.size(); k++ )
		n.push_back( pairwise_[k]->parameters().rows() );
	int np=0;
	for( unsigned int k=0; k<pairwise_.size(); k++ )
		np += n[k];
	
	for( unsigned int k=0,i=0; k<pairwise_.size(); k++ ) {
		pairwise_[k]->setParameters( v.segment( i, n[k] ) );
		i += n[k];
	}	
}
Eigen::VectorXf DenseCRF::kernelParameters() const {
	std::vector< Eigen::VectorXf > terms;
	for( unsigned int k=0; k<pairwise_.size(); k++ )
		terms.push_back( pairwise_[k]->kernelParameters() );
	int np=0;
	for( unsigned int k=0; k<pairwise_.size(); k++ )
		np += terms[k].rows();
	Eigen::VectorXf r( np );
	for( unsigned int k=0,i=0; k<pairwise_.size(); k++ ) {
		r.segment( i, terms[k].rows() ) = terms[k];
		i += terms[k].rows();
	}	
	return r;
}
void DenseCRF::setKernelParameters( const Eigen::VectorXf & v ) {
	std::vector< int > n;
	for( unsigned int k=0; k<pairwise_.size(); k++ )
		n.push_back( pairwise_[k]->kernelParameters().rows() );
	int np=0;
	for( unsigned int k=0; k<pairwise_.size(); k++ )
		np += n[k];
	
	for( unsigned int k=0,i=0; k<pairwise_.size(); k++ ) {
		pairwise_[k]->setKernelParameters( v.segment( i, n[k] ) );
		i += n[k];
	}	
}
