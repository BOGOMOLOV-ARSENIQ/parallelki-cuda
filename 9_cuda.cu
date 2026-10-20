#include <iostream>
#include <iomanip>
#include <string>
#include <cstdio>
#include <cuda_runtime.h>
#include "siphash.h"
#include "params.h"

__global__ void crack(uint64_t target, long long n) {
    long long index = blockIdx.x * (long long)blockDim.x + threadIdx.x;
    if (index >= n)
        return;

    uint8_t pw[9];
    long long v = index;
    for (int p = 8; p >= 0; p--) {
        pw[p] = (uint8_t)('0' + v % 10);
        v /= 10;
    }
    if (siphash24(pw, 9) == target)
        printf("%09lld\n", index);
}

int main() {
    std::string pass;
    std::cout << "password: ";
    std::cin >> pass;
    uint64_t target = siphash24(pass);
    std::cout << "hash: " << std::hex << std::setw(16) << std::setfill('0') << target << std::dec << "\n";

    int group = 256;
    long long grid = (TOTAL + group - 1) / group;
    crack<<<grid, group>>>(target, TOTAL);
    cudaDeviceSynchronize();
}
