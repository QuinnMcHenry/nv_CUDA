/*
Write a CUDA C program that computes the sum of all values in a 2D array
 with 3 rows and 4 columns.  Assign one thread to compute the sum of all
 the values in column 0, another thread to compute the sum of all values
 in column 1, etc.  Then have the host add up all of the column sums
 computed by each thread
*/


#include <stdio.h>

__global__ void add(int* mat, int* res)
{
        int column = threadIdx.x;
        int colSum = 0;
        for (int row = 0; row < 3; row++)
        {
                colSum += mat[(4 * row) + column];
        }
        res[column] = colSum;
}


int main()
{
	//matrix memory
	int mat[3][4];
	int* dev_mat;
	//result array memory
	int res[4];
	int* dev_res;
	//allocate space for 12 elements on device
	cudaMalloc((void**)&dev_mat, 12 * sizeof(int));
	//i want to put sums in an array and send that back to cpu
	cudaMalloc((void**)&dev_res, 4 * sizeof(int));
	
	// fill arrays
	printf("Matrix: \n");
	for (int i = 0; i < 3; i++)
	{
		for (int j = 0; j < 4; j++)
		{
			mat[i][j] = i + j;
			printf("%d ", mat[i][j]);
		}
		printf("\n");
	}
	// copy mat from cpu to dev_mat on gpu
	cudaMemcpy(dev_mat, mat, 12 * sizeof(int), cudaMemcpyHostToDevice);
	
	add<<<1, 4>>>(dev_mat, dev_res);
	
	cudaMemcpy(res, dev_res, 4 * sizeof(int), cudaMemcpyDeviceToHost);
	
	int finalSum = 0;
	for (int i = 0; i < 4; i++)
	{
		printf("Column total [%d]: %d\n", i, res[i]);
		finalSum += res[i];
	}
	printf("\nTotal of all columns, calculated by host: %d\n", finalSum);
	cudaFree(dev_mat);
	cudaFree(dev_res);
	return 0;
}

