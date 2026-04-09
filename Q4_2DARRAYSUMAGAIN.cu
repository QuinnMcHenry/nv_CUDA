/*
Modify your solution to the previous program but make the 2D array a square.
  Make the dimension be a power of 2 (you can use an 8x8 array).
This time, assign a block to each row and a thread to each column in that row. 
 Implement the reduction algorithm to compute the sum of each block,
 then sum the sum of each block on the host to get the total sum.
Although you only need to run this on an 8x8 array your solution should scale
 up to larger (or smaller) square arrays with minimal changes (e.g. only
 change the initial values and dimension).

*/

#include <stdio.h>
#define DIM 8

__global__ void add(int* mat, int* blockSums)
{
	__shared__ int rowSum[DIM]; // low-latency shared mem within one block. 
	// !!!! each block gets its own rowSum

	int row = blockIdx.x; // 0-7
        int column = threadIdx.x; // 0-7
	
	rowSum[column] = mat[row * DIM + column]; // flattening of mat for index
	__syncthreads(); // wait for threads in their block

	// reduction: factory workers (threads) at tables (blocks). each thread now has gotten a single
	// value  from mat and stored it in that block's rowSum.
	// now we pair up rowSum vals and sum them until rowSum[0] holds the total sum.
	for (int stride = DIM / 2; stride > 0; stride /= 2)     
	{
		if (column < stride)
		{
			rowSum[column] += rowSum[column + stride];
		}
		__syncthreads(); // dont start again till reduction is done for that block
	}
	if (column == 0) // now we can get each block's rowSum
	{
		blockSums[row] = rowSum[0];
	}
}


int main()
{
	//matrix memory
	int mat[DIM][DIM];
	int* dev_mat;
	//result array memory
	int blockSums[DIM];
	int* dev_blockSums;
	//allocate space for square matrix of DIM on device
	cudaMalloc((void**)&dev_mat, (DIM*DIM) * sizeof(int));
	//its square so i know there will be DIM sums (mmm dim sum)
	cudaMalloc((void**)&dev_blockSums, DIM * sizeof(int));

	// fill array
	printf("Matrix: \n");
	for (int i = 0; i < DIM; i++)
	{
		for (int j = 0; j < DIM; j++)
		{
			mat[i][j] = i * j + 1; // just random nums
			printf("%d ", mat[i][j]);
		}
		printf("\n");
	}
	// copy mat from cpu to dev_mat on gpu
	cudaMemcpy(dev_mat, mat, (DIM*DIM) * sizeof(int), cudaMemcpyHostToDevice);
	
	// call __global__ add with DIM blocks (rows) DIM threads(columns)
	add<<<DIM, DIM>>>(dev_mat, dev_blockSums);

	// copy the array of blocksums back to host
	cudaMemcpy(blockSums, dev_blockSums, DIM * sizeof(int), cudaMemcpyDeviceToHost);

	int finalSum = 0;
	for (int i = 0; i < DIM; i++)
	{
		printf("Block %d sum: %d\n", i, blockSums[i]);
		finalSum += blockSums[i];
	}

 
	cudaFree(dev_mat);
	cudaFree(dev_blockSums);
	printf("Final sum of all blockSums: %d\n", finalSum);
	return 0;
}
