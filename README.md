# PolyHok Benchmarks

This repository contains a collection of benchmarks developed for [PolyHok](https://github.com/lups-ufpel/poly_hok), a DSL for GPU programming in Elixir.

The benchmarks are designed to evaluate the performance of PolyHok in various scenarios, including matrix multiplication, image processing, and other computationally intensive tasks. Each benchmark is implemented in Elixir using the PolyHok DSL, allowing for easy experimentation and performance analysis.

We also included native versions of the benchmarks implemented in C++/OpenCL and C++/CUDA (folder `natives/`) for comparison purposes. This allows us to measure the overhead imposed by the PolyHok DSL and assess its performance relative to traditional GPU programming approaches.

## Usage

1. Clone and navigate to the repository:

   ```bash
   git clone https://github.com/lups-ufpel/poly_hok_benchmarks.git
   cd poly_hok_benchmarks
   ```

2. Install the required dependencies and compile them:

   ```bash
    mix deps.get
    mix compile
   ```

3. Choose and run a benchmark:

   ```bash
   mix run elixir/julia.exs 512
   ```

By default, PolyHok is configured to use OpenCL. If you want to use CUDA, you can modify the `mix.exs` file to pull the CUDA backend and change the `:backend` option in the `config/runtime.exs` file to `CudaBackend`. After making these changes, recompile the project and run the benchmarks again.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.