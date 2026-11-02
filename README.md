# parallelki-cuda

Задача 9 (CUDA): перебор 9-значного пароля по SipHash на GPU.

- `9_cuda.cu` — target передаётся аргументом кернела, пароль печатает нашедший поток через device `printf`.
- `9a_cuda.cu` — target в `__constant__` памяти (`cudaMemcpyToSymbol`), результат забирается назад через `cudaMemcpyFromSymbol`.
- `siphash.h` — SipHash-2-4, общий для хоста и девайса (`__host__ __device__`).
- `params.h` — `TOTAL` (размер перебора) и `make_password`.

## Kaggle

1. New Notebook → Settings: Accelerator = GPU, Internet = on.
2. File → Import Notebook → из этого репозитория `run.ipynb`, либо просто выполнить ячейки оттуда.
3. Ячейки: clone → build → run.

## Локально (с nvcc)

```bash
nvcc -O3 -std=c++17 9_cuda.cu  -o 9_cuda
nvcc -O3 -std=c++17 9a_cuda.cu -o 9a_cuda
echo 123456789 | ./9_cuda
echo 123456789 | ./9a_cuda
```
