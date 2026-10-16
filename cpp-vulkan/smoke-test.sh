#!/usr/bin/env bash
set -euo pipefail

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT
cd "$work_dir"

cmake --version
ninja --version
git --version
ccache --version
glslc --version
spirv-val --version

cat > smoke.comp <<'GLSL'
#version 450
layout(local_size_x = 1) in;
layout(set = 0, binding = 0) buffer Values { uint value[]; } values;
void main() { values.value[gl_GlobalInvocationID.x] += 1; }
GLSL
glslc --target-env=vulkan1.2 smoke.comp -o smoke.spv
spirv-val --target-env vulkan1.2 smoke.spv

cat > smoke.cpp <<'CPP'
#include <vulkan/vulkan.h>
#include <iostream>
#include <vector>

int main() {
    VkInstanceCreateInfo info{};
    info.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
    VkInstance instance{};
    if (vkCreateInstance(&info, nullptr, &instance) != VK_SUCCESS) return 1;
    uint32_t count = 0;
    if (vkEnumeratePhysicalDevices(instance, &count, nullptr) != VK_SUCCESS) {
        vkDestroyInstance(instance, nullptr);
        return 1;
    }
    std::vector<VkPhysicalDevice> devices(count);
    bool found_cpu = false;
    if (count && vkEnumeratePhysicalDevices(instance, &count, devices.data()) == VK_SUCCESS) {
        for (const auto device : devices) {
            VkPhysicalDeviceProperties properties{};
            vkGetPhysicalDeviceProperties(device, &properties);
            std::cout << "Vulkan device: " << properties.deviceName << '\n';
            found_cpu |= properties.deviceType == VK_PHYSICAL_DEVICE_TYPE_CPU;
        }
    }
    vkDestroyInstance(instance, nullptr);
    return found_cpu ? 0 : 1;
}
CPP
cat > CMakeLists.txt <<'CMAKE'
cmake_minimum_required(VERSION 3.20)
project(vulkan_smoke LANGUAGES CXX)
find_package(Vulkan REQUIRED)
add_executable(smoke smoke.cpp)
target_compile_features(smoke PRIVATE cxx_std_17)
target_link_libraries(smoke PRIVATE Vulkan::Vulkan)
CMAKE
cmake -S . -B build -G Ninja
cmake --build build

# Select Mesa's CPU driver, so that the test can run without a GPU.
drivers=(/usr/share/vulkan/icd.d/lvp*.json)
test -f "${drivers[0]}"
export VK_DRIVER_FILES="${drivers[0]}"
export VK_ICD_FILENAMES="$VK_DRIVER_FILES"
export XDG_RUNTIME_DIR="$work_dir"
./build/smoke
echo "Vulkan shader and CPU device checks passed. Physical GPU runtime was not tested."
