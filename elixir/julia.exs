require PolyHok

PolyHok.defmodule Julia do
  defd julia(x, y, dim) do
    scale = 0.1
    jx = scale * (dim - x) / dim
    jy = scale * (dim - y) / dim

    cr = -0.8
    ci = 0.156
    ar = jx
    ai = jy

    for i in range(0, 200) do
      nar = ar * ar - ai * ai + cr
      nai = ai * ar + ar * ai + ci

      if nar * nar + nai * nai > 1000.0 do
        return(0)
      end

      ar = nar
      ai = nai
    end

    return(1)
  end

  defd julia_function(ptr, x, y, dim) do
    offset = x + y * dim
    juliaValue = julia(x, y, dim)

    ptr[offset * 4 + 0] = 255 * juliaValue
    ptr[offset * 4 + 1] = 0
    ptr[offset * 4 + 2] = 0
    ptr[offset * 4 + 3] = 255
  end

  defk mapgen2D_xy_1para_noret_ker(resp, arg1, size, f) do
    x = blockIdx.x * blockDim.x + threadIdx.x
    y = blockIdx.y * blockDim.y + threadIdx.y

    if(x < size && y < size) do
      f(resp, x, y, arg1)
    end
  end

  def mapgen2D_step_xy_1para_noret(result_gpu, arg1, size, f) do
    block_size = 16
    grid_size = div(size + block_size - 1, block_size)

    PolyHok.spawn(
      &Julia.mapgen2D_xy_1para_noret_ker/4,
      {grid_size, grid_size, 1},
      {block_size, block_size, 1},
      [
        result_gpu,
        arg1,
        size,
        f
      ]
    )

    result_gpu
  end
end

[arg] = System.argv()
m = String.to_integer(arg)

dim = m

prev = System.monotonic_time()

result_gpu = PolyHok.new_gnx({dim * dim, 4}, {:s, 32})

image =
  result_gpu
  |> Julia.mapgen2D_step_xy_1para_noret(dim, dim, &Julia.julia_function/4)
  |> PolyHok.get_gnx()

next = System.monotonic_time()

IO.puts("PolyHok\t#{dim}\t#{System.convert_time_unit(next - prev, :native, :millisecond)}")

Bmp.gen_bmp_int("julia.bmp", dim, image)
