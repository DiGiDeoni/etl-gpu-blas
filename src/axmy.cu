//=======================================================================
// Copyright (c) 2017 Baptiste Wicht
// Distributed under the terms of the MIT License.
// (See accompanying file LICENSE or copy at
//  http://opensource.org/licenses/MIT)
//=======================================================================

#include "egblas/axmy.hpp"

template <typename T>
__global__ void axmy_kernel(size_t n, T alpha, const T* x, size_t incx, T* y, size_t incy) {
    auto index  = threadIdx.x + blockIdx.x * blockDim.x;
    auto stride = blockDim.x * gridDim.x;

    for (; index < n; index += stride) {
        y[incy * index] = alpha * x[incx * index] * y[incy * index];
    }
}

template <>
__global__ void axmy_kernel(size_t n, cuComplex alpha, const cuComplex* x, size_t incx, cuComplex* y, size_t incy) {
    auto index  = threadIdx.x + blockIdx.x * blockDim.x;
    auto stride = blockDim.x * gridDim.x;

    for (; index < n; index += stride) {
        y[incy * index] = cuCmulf(cuCmulf(alpha, x[incx * index]), y[incy * index]);
    }
}

template <>
__global__ void axmy_kernel(size_t n, cuDoubleComplex alpha, const cuDoubleComplex* x, size_t incx, cuDoubleComplex* y, size_t incy) {
    auto index  = threadIdx.x + blockIdx.x * blockDim.x;
    auto stride = blockDim.x * gridDim.x;

    for (; index < n; index += stride) {
        y[incy * index] = cuCmul(cuCmul(alpha, x[incx * index]), y[incy * index]);
    }
}

template <typename T>
__global__ void axmy_kernel1(size_t n, const T* x, size_t incx, T* y, size_t incy) {
    auto index  = threadIdx.x + blockIdx.x * blockDim.x;
    auto stride = blockDim.x * gridDim.x;

    for (; index < n; index += stride) {
        y[incy * index] = x[incx * index] * y[incy * index];
    }
}

template <>
__global__ void axmy_kernel1(size_t n, const cuComplex* x, size_t incx, cuComplex* y, size_t incy) {
    auto index  = threadIdx.x + blockIdx.x * blockDim.x;
    auto stride = blockDim.x * gridDim.x;

    for (; index < n; index += stride) {
        y[incy * index] = cuCmulf(x[incx * index], y[incy * index]);
    }
}

template <>
__global__ void axmy_kernel1(size_t n, const cuDoubleComplex* x, size_t incx, cuDoubleComplex* y, size_t incy) {
    auto index  = threadIdx.x + blockIdx.x * blockDim.x;
    auto stride = blockDim.x * gridDim.x;

    for (; index < n; index += stride) {
        y[incy * index] = cuCmul(x[incx * index], y[incy * index]);
    }
}

template <typename T>
__global__ void axmy_kernel0(size_t n, T* y, size_t incy) {
    auto index  = threadIdx.x + blockIdx.x * blockDim.x;
    auto stride = blockDim.x * gridDim.x;

    for (; index < n; index += stride) {
        y[incy * index] = T(0);
    }
}

template <>
__global__ void axmy_kernel0(size_t n, cuComplex* y, size_t incy) {
    auto index  = threadIdx.x + blockIdx.x * blockDim.x;
    auto stride = blockDim.x * gridDim.x;

    for (; index < n; index += stride) {
        y[incy * index] = make_cuComplex(0, 0);
    }
}

template <>
__global__ void axmy_kernel0(size_t n, cuDoubleComplex* y, size_t incy) {
    auto index  = threadIdx.x + blockIdx.x * blockDim.x;
    auto stride = blockDim.x * gridDim.x;

    for (; index < n; index += stride) {
        y[incy * index] = make_cuDoubleComplex(0, 0);
    }
}

template <typename T>
void axmy_kernel_run(size_t n, T alpha, const T* x, size_t incx, T* y, size_t incy) {
    int blockSize;
    int minGridSize;

    cudaOccupancyMaxPotentialBlockSize(&minGridSize, &blockSize, axmy_kernel<T>, 0, 0);

    int gridSize = ((n / incy) + blockSize - 1) / blockSize;

    axmy_kernel<T><<<gridSize, blockSize>>>(n, alpha, x, incx, y, incy);

    cudaDeviceSynchronize();
}

template <typename T>
void axmy_kernel1_run(size_t n, const T* x, size_t incx, T* y, size_t incy) {
    int blockSize;
    int minGridSize;

    cudaOccupancyMaxPotentialBlockSize(&minGridSize, &blockSize, axmy_kernel1<T>, 0, 0);

    int gridSize = ((n / incy) + blockSize - 1) / blockSize;

    axmy_kernel1<T><<<gridSize, blockSize>>>(n, x, incx, y, incy);

    cudaDeviceSynchronize();
}

template <typename T>
void axmy_kernel0_run(size_t n, T* y, size_t incy) {
    int blockSize;
    int minGridSize;

    cudaOccupancyMaxPotentialBlockSize(&minGridSize, &blockSize, axmy_kernel0<T>, 0, 0);

    int gridSize = ((n / incy) + blockSize - 1) / blockSize;

    axmy_kernel0<T><<<gridSize, blockSize>>>(n, y, incy);

    cudaDeviceSynchronize();
}

void egblas_saxmy(size_t n, float alpha, const float* x, size_t incx, float* y, size_t incy) {
    if (alpha == 1.0f) {
        axmy_kernel1_run(n, x, incx, y, incy);
    } else if (alpha == 0.0f) {
        axmy_kernel0_run(n, y, incy);
    } else {
        axmy_kernel_run(n, alpha, x, incx, y, incy);
    }
}

void egblas_daxmy(size_t n, double alpha, const double* x, size_t incx, double* y, size_t incy) {
    if (alpha == 1.0) {
        axmy_kernel1_run(n, x, incx, y, incy);
    } else if (alpha == 0.0) {
        axmy_kernel0_run(n, y, incy);
    } else {
        axmy_kernel_run(n, alpha, x, incx, y, incy);
    }
}

void egblas_caxmy(size_t n, cuComplex alpha, const cuComplex* x, size_t incx, cuComplex* y, size_t incy) {
    if (alpha.x == 1.0f && alpha.y == 0.0f) {
        axmy_kernel1_run(n, x, incx, y, incy);
    } else if (alpha.x == 0.0f && alpha.y == 0.0f) {
        axmy_kernel0_run(n, y, incy);
    } else {
        axmy_kernel_run(n, alpha, x, incx, y, incy);
    }
}

void egblas_zaxmy(size_t n, cuDoubleComplex alpha, const cuDoubleComplex* x, size_t incx, cuDoubleComplex* y, size_t incy) {
    if (alpha.x == 1.0 && alpha.y == 0.0) {
        axmy_kernel1_run(n, x, incx, y, incy);
    } else if (alpha.x == 0.0 && alpha.y == 0.0) {
        axmy_kernel0_run(n, y, incy);
    } else {
        axmy_kernel_run(n, alpha, x, incx, y, incy);
    }
}
