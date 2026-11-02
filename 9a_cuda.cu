#include <iostream>
#include <string>
#include <format>
#include <cuda_runtime.h>
#include "siphash.h"
#include "params.h"

#define GROUP_SIZE 256

struct WorkSize {
    long long group;
    long long global;
    WorkSize(long long group_size, long long n) : group(group_size), global(n) {}
    long long gridSize() const { return (global + group - 1) / group; }
    long long blockSize() const { return group; }
};

#define CUDA_CHECK_KERNEL()                                                   \
    do {                                                                      \
        cudaError_t err = cudaDeviceSynchronize();                            \
        if (err != cudaSuccess) {                                             \
            std::cerr << "cuda error: " << cudaGetErrorString(err) << "\n";   \
            std::exit(1);                                                     \
        }                                                                     \
    } while (0)

__constant__ uint64_t d_target;
__device__ long long d_found;

__global__ void crack(long long n) {
    const long long index = blockIdx.x * (long long)blockDim.x + threadIdx.x;
    if (index >= n)
        return;

    uint8_t pw[9];
    long long v = index;
    for (int p = 8; p >= 0; p--) {
        pw[p] = (uint8_t)('0' + v % 10);
        v /= 10;
    }
    if (siphash24(pw, 9) == d_target)
        d_found = index;
}

namespace cuda {
long long crack(const WorkSize &ws, uint64_t target, long long n) {
    long long init = -1;
    cudaMemcpyToSymbol(d_target, &target, sizeof(uint64_t));
    cudaMemcpyToSymbol(d_found, &init, sizeof(long long));
    ::crack<<<ws.gridSize(), ws.blockSize()>>>(n);
    CUDA_CHECK_KERNEL();
    long long found;
    cudaMemcpyFromSymbol(&found, d_found, sizeof(long long));
    return found;
}
}

int main() {
    std::string pass;
    std::cout << "password: ";
    std::cin >> pass;
    uint64_t target = siphash24(pass);
    std::cout << "hash: " << std::format("{:016x}", target) << "\n";

    WorkSize ws(GROUP_SIZE, TOTAL);
    long long found = cuda::crack(ws, target, TOTAL);

    if (found < 0) {
        std::cout << "not found\n";
    } else {
        std::string pw(9, '0');
        make_password(found, pw);
        std::cout << pw << "\n";
    }
}
