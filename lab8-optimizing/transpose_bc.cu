/*
 *  Copyright 2014 NVIDIA Corporation
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

#include <stdio.h>
#include <math.h>

#ifdef DEBUG
#define CUDA_CALL(F)  if( (F) != cudaSuccess ) \
  {printf("Error %s at %s:%d\n", cudaGetErrorString(cudaGetLastError()), \
   __FILE__,__LINE__); exit(-1);} 
#define CUDA_CHECK()  if( (cudaPeekAtLastError()) != cudaSuccess ) \
  {printf("Error %s at %s:%d\n", cudaGetErrorString(cudaGetLastError()), \
   __FILE__,__LINE__-1); exit(-1);} 
#else
#define CUDA_CALL(F) (F)
#define CUDA_CHECK() 
#endif

/* definitions of threadblock size in X and Y directions */

#define THREADS_PER_BLOCK_X 32
#define THREADS_PER_BLOCK_Y 32

/* definition of matrix linear dimension */

#define SIZE 4096

/* macro to index a 1D memory array with 2D indices in column-major order */

#define INDX( row, col, ld ) ( ( (col) * (ld) ) + (row) )

/**
 * @brief CUDA kernel for shared memory matrix transpose.
 * 
 * This kernel transposes a matrix using shared memory to optimize memory coalescing.
 * The matrix is indexed in a column-major order, and each thread block loads a tile of the 
 * matrix into shared memory, performs the transpose, and writes back the result to global memory.
 * 
 * @param m      The number of rows/columns in the square matrix.
 * @param a      The input matrix in device memory.
 * @param c      The output matrix in device memory.
 */
__global__ void smem_cuda_transpose( const int m, 
                                     double const * const a, 
                                     double * const c )
{
	
  /* 
   * TODO: Declare a shared memory array for a tile of the matrix.
   * Add +1 to avoid bank conflicts when writing and reading.
   */

  /* TODO: Calculate the row and column index for this thread */
  const int myRow = ;
  const int myCol = ;

  /* TODO: Calculate the starting row and column indices for the current tile */
  const int tileX = ;
  const int tileY = ;

  /* TODO: Ensure the thread is within the matrix bounds */
  if(  )
  {
    /* TODO: Load the matrix tile from global memory into shared memory */

  } 

  /* TODO: Synchronize threads within the block to ensure all data is loaded into shared memory */
  
		
  /* TODO: Ensure the thread is within the matrix bounds */
  if(  )
  {
    /* TODO: Write the transposed tile back to global memory */

  } 
  return;

} /* end smem_cuda_transpose */

void host_transpose( const int m, double const * const a, double * const c )
{
	
/* 
 *  naive matrix transpose goes here.
 */
 
  for( int j = 0; j < m; j++ )
  {
    for( int i = 0; i < m; i++ )
    {
      c[INDX(i,j,m)] = a[INDX(j,i,m)];
    } /* end for i */
  } /* end for j */

} /* end host_dgemm */

int main( int argc, char *argv[] )
{

  int size = SIZE;

  fprintf(stdout, "Matrix size is %d\n",size);

/* declaring pointers for array */

  double *h_a, *h_c;
  double *d_a, *d_c;
 
  size_t numbytes = (size_t) size * (size_t) size * sizeof( double );

/* allocating host memory */

  h_a = (double *) malloc( numbytes );
  if( h_a == NULL )
  {
    fprintf(stderr,"Error in host malloc h_a\n");
    return 911;
  }

  h_c = (double *) malloc( numbytes );
  if( h_c == NULL )
  {
    fprintf(stderr,"Error in host malloc h_c\n");
    return 911;
  }

/* allocating device memory */

  CUDA_CALL( cudaMalloc( (void**) &d_a, numbytes ) );
  CUDA_CALL( cudaMalloc( (void**) &d_c, numbytes ) );

/* set result matrices to zero */

  memset( h_c, 0, numbytes );
  CUDA_CALL( cudaMemset( d_c, 0, numbytes ) );

  fprintf( stdout, "Total memory required per matrix is %lf MB\n", 
     (double) numbytes / 1000000.0 );

/* initialize input matrix with random value */

  for( int i = 0; i < size * size; i++ )
  {
    h_a[i] = double( rand() ) / ( double(RAND_MAX) + 1.0 );
  } /* end for */

/* copy input matrix from host to device */

  CUDA_CALL( cudaMemcpy( d_a, h_a, numbytes, cudaMemcpyHostToDevice ) );

/* create and start timer */

  cudaEvent_t start, stop;
  CUDA_CALL( cudaEventCreate( &start ) );
  CUDA_CALL( cudaEventCreate( &stop ) );
  CUDA_CALL( cudaEventRecord( start, 0 ) );

/* call naive cpu transpose function */

  host_transpose( size, h_a, h_c );

/* stop CPU timer */

  CUDA_CALL( cudaEventRecord( stop, 0 ) );
  CUDA_CALL( cudaEventSynchronize( stop ) );
  float elapsedTime;
  CUDA_CALL( cudaEventElapsedTime( &elapsedTime, start, stop ) );

/* print CPU timing information */

  fprintf(stdout, "Total time CPU is %f sec\n", elapsedTime / 1000.0f );
  fprintf(stdout, "Performance is %f GB/s\n", 
    8.0 * 2.0 * (double) size * (double) size / 
    ( (double) elapsedTime / 1000.0 ) * 1.e-9 );

  /* 
   * TODO: Setup threadblock size and grid sizes 
   * The block size should match the THREADS_PER_BLOCK_X and THREADS_PER_BLOCK_Y dimensions.
   */

  dim3 threads( , , 1 );
  dim3 blocks( , , 1 );

/* start timers */
  CUDA_CALL( cudaEventRecord( start, 0 ) );

/* call smem GPU transpose kernel */

  smem_cuda_transpose<<< blocks, threads >>>( size, d_a, d_c );
  CUDA_CHECK();
  CUDA_CALL( cudaDeviceSynchronize() );

/* stop the timers */

  CUDA_CALL( cudaEventRecord( stop, 0 ) );
  CUDA_CALL( cudaEventSynchronize( stop ) );
  CUDA_CALL( cudaEventElapsedTime( &elapsedTime, start, stop ) );

/* print GPU timing information */

  fprintf(stdout, "Total time GPU is %f sec\n", elapsedTime / 1000.0f );
  fprintf(stdout, "Performance is %f GB/s\n", 
    8.0 * 2.0 * (double) size * (double) size / 
    ( (double) elapsedTime / 1000.0 ) * 1.e-9 );

/* copy data from device to host */

  CUDA_CALL( cudaMemset( d_a, 0, numbytes ) );
  CUDA_CALL( cudaMemcpy( h_a, d_c, numbytes, cudaMemcpyDeviceToHost ) );

/* compare GPU to CPU for correctness */

  for( int j = 0; j < size; j++ )
  {
    for( int i = 0; i < size; i++ )
    {
      if( h_c[INDX(i,j,size)] != h_a[INDX(i,j,size)] ) 
      {
        printf("Error in element %d,%d\n", i,j );
        printf("Host %f, device %f\n",h_c[INDX(i,j,size)],
                                      h_a[INDX(i,j,size)]);
        printf("FAIL\n");
        goto end;
      }
    } /* end for i */
  } /* end for j */

/* free the memory */
  printf("PASS\n");

  end:
  free( h_a );
  free( h_c );
  CUDA_CALL( cudaFree( d_a ) );
  CUDA_CALL( cudaFree( d_c ) );

  CUDA_CALL( cudaDeviceReset() );

  return 0;
}
