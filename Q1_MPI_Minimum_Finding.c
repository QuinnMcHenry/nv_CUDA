#include <stdio.h>
#include <mpi.h>
#include <stdlib.h>
#include <stdint.h>
#include <time.h>

#define LENGTH 8000000
#define RMAX 1000000000


int main(int argc, char** argv)
{
	srand(time(NULL));
	MPI_Init(&argc, &argv); 
	
	int rank, size;
	MPI_Comm_rank(MPI_COMM_WORLD, &rank);
	MPI_Comm_size(MPI_COMM_WORLD, &size);

	int* nums = (int *)malloc(sizeof(int) * LENGTH);// vals can be 8 billion
	int local_min = RMAX;
	int global_min = RMAX;

	if (rank == 0)
	{
		for (int i = 0; i < LENGTH; i++)
		{
			nums[i] = rand() % RMAX; // should be fine becasue GCC RAND_MAX is 2bil
		}
	}
	MPI_Bcast(nums, LENGTH, MPI_INT, 0, MPI_COMM_WORLD);
	int chunk = LENGTH / size;
	int start = rank * chunk;
	int end = start + chunk;

	for (int i = start; i < end; i++)
	{
		if (nums[i] < local_min)
		{
			local_min = nums[i];
		}
	}
	MPI_Reduce(&local_min, &global_min, 1, MPI_INT, MPI_MIN, 0, MPI_COMM_WORLD);
	if (rank == 0)
	{
		int check = RMAX;
		printf("The global min is: %d\n", global_min);
		printf("Now checking sequentially...\n");
		for (int i = 0; i < LENGTH; i++)
		{
			if (nums[i] < check)
			{
				check = nums[i];
			} 
		}
		printf("Sequential min: %d\n", check);
		if (check == global_min)
		{
			printf("The mins match!\n");
		} else { printf("The mins do not match.\n");}
	}
	
	free(nums);
	MPI_Finalize();
	return 0;
}

