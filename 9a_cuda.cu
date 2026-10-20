#include <iostream>
#include <iomanip>
#include <string>
#include <cuda_runtime.h>
#include "siphash.h"
#include "params.h"

__constant__ uint64_t d_target;
__device__ long long d_found;

__global__ void crack(long long n) {
    long long index = blockIdx.x * (long long)blockDim.x + threadIdx.x;
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

int main() {
    std::string pass;
    std::cout << "password: ";
    std::cin >> pass;
    uint64_t target = siphash24(pass);
    std::cout << "hash: " << std::hex << std::setw(16) << std::setfill('0') << target << std::dec << "\n";

    long long init = -1;
    cudaMemcpyToSymbol(d_target, &target, sizeof(uint64_t));
    cudaMemcpyToSymbol(d_found, &init, sizeof(long long));

    int group = 256;
    long long grid = (TOTAL + group - 1) / group;
    crack<<<grid, group>>>(TOTAL);
    cudaDeviceSynchronize();

    long long found;
    cudaMemcpyFromSymbol(&found, d_found, sizeof(long long));

    if (found < 0) {
        std::cout << "not found\n";
    } else {
        std::string pw(9, '0');
        make_password(found, pw);
        std::cout << pw << "\n";
    }
}
