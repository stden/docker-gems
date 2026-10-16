#!/usr/bin/env bash
set -euo pipefail

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
cd "$work_dir"

nvcc --version
cmake --version
ninja --version
git --version
ccache --version

cat > kernel.cu <<'CUDA'
#include <cuda_runtime.h>

__global__ void increment(int *value) { *value += 1; }

int main() {
    int *value = nullptr;
    if (cudaMalloc(&value, sizeof(int)) != cudaSuccess) return 1;
    if (cudaMemset(value, 0, sizeof(int)) != cudaSuccess) return 1;
    increment<<<1, 1>>>(value);
    if (cudaDeviceSynchronize() != cudaSuccess) return 1;
    return cudaFree(value) == cudaSuccess ? 0 : 1;
}
CUDA
# Compile and link a real kernel. Do not run it without a CUDA device.
nvcc --std=c++17 kernel.cu -o kernel
test -s kernel

cat > host.cpp <<'CPP'
#include <iostream>
#include <numeric>
#include <vector>

int main() {
    const std::vector<int> values{1, 2, 3};
    const int sum = std::accumulate(values.begin(), values.end(), 0);
    std::cout << "Host C++ sum: " << sum << '\n';
    return sum == 6 ? 0 : 1;
}
CPP
g++ -std=c++17 -Wall -Wextra -Werror host.cpp -o host
./host
echo "CUDA compile and link checks passed. GPU runtime was not tested."
