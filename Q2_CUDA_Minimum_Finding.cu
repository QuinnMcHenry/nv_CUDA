#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define LENGTH 8000000
#define RMAX 1000000000

__global__ void findMin(int* nums, int* minimums)
{
	int min = RMAX;
	int range = LENGTH / 8;
	int start = threadIdx.x * range;
	int end = start + range;
	for (int i = start; i < end; i++)
	{
		if (nums[i] < min)
		{
			min = nums[i];
		}
	}
	minimums[threadIdx.x] = min;
}


int main()
{
	//populate array on host
	srand(time(NULL));
	int* nums = (int*)malloc(sizeof(int) * LENGTH);
	for (int i = 0; i < LENGTH; i++)
	{
		nums[i] = rand() % RMAX;
	}	

	// dev_nums array
	int* dev_nums;

	int minimums[8];
	int* dev_minimums;

	cudaMalloc((void**)&dev_minimums, 8 * sizeof(int));	
	cudaMalloc((void**)&dev_nums, LENGTH * sizeof(int));

	// copy to device
	cudaMemcpy(dev_nums, nums, LENGTH * sizeof(int), cudaMemcpyHostToDevice);
	findMin<<<1, 8>>>(dev_nums, dev_minimums);
	
	cudaMemcpy(minimums, dev_minimums, 8 * sizeof(int), cudaMemcpyDeviceToHost);
	cudaFree(dev_nums);
	cudaFree(dev_minimums);
	
	int min = RMAX;
	for (int i = 0; i < 8; i++)
	{
		if (minimums[i] < min){min = minimums[i];} 
	}
	printf("Host: min from threads = %d\n", min);
	int newmin = RMAX;
	printf("Host: checking if min matches sequentially/n");
	for (int i = 0; i < LENGTH; i++)
	{
		if (nums[i] < newmin) {newmin = nums[i];}
	}
	printf("min sequentially: %d\n", newmin);
	if (newmin == min)
	{
		printf("Mins match!\n");
	} else {
		printf("Mins dont match.\n)");
	}
	return 0;
}

