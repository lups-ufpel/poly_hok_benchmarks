require PolyHok

PolyHok.defmodule NBodies do
  defd gpu_nBodies(p, c, n) do
    softening = 0.000000001
    dt = 0.01
    fx = 0.0
    fy = 0.0
    fz = 0.0

    for j in range(0, n) do
      dx = c[6 * j] - p[0]
      dy = c[6 * j + 1] - p[1]
      dz = c[6 * j + 2] - p[2]
      distSqr = dx * dx + dy * dy + dz * dz + softening
      invDist = 1.0 / sqrt(distSqr)
      invDist3 = invDist * invDist * invDist

      fx = fx + dx * invDist3
      fy = fy + dy * invDist3
      fz = fz + dz * invDist3
    end

    p[3] = p[3] + dt * fx
    p[4] = p[4] + dt * fy
    p[5] = p[5] + dt * fz
  end

  defd gpu_integrate(p, dt, n) do
    p[0] = p[0] + p[3] * dt
    p[1] = p[1] + p[4] * dt
    p[2] = p[2] + p[5] * dt
  end

  defk map_step_2_para_no_resp_kernel(d_array, step, par1, par2, size, f) do
    globalId = blockDim.x * (gridDim.x * blockIdx.y + blockIdx.x) + threadIdx.x
    id = step * globalId

    if globalId < size do
      f(d_array + id, par1, par2)
    end
  end

  def map_2_para_no_resp(d_array, par1, par2, size, f) do
    block_size = 128
    {_l, step} = PolyHok.get_shape_gnx(d_array)
    nBlocks = floor((size + block_size - 1) / block_size)

    PolyHok.spawn(
      &NBodies.map_step_2_para_no_resp_kernel/6,
      {nBlocks, 1, 1},
      {block_size, 1, 1},
      [d_array, step, par1, par2, size, f]
    )

    d_array
  end
end

[arg] = System.argv()

user_value = String.to_integer(arg)
nBodies = user_value
size_body = 6

h_buf = PolyHok.new_nx_from_function(nBodies, size_body, {:f, 64}, fn -> :rand.uniform() end)

prev = System.monotonic_time()

d_buf = PolyHok.new_gnx(h_buf)

_resp =
  d_buf
  |> NBodies.map_2_para_no_resp(d_buf, nBodies, nBodies, &NBodies.gpu_nBodies/3)
  |> NBodies.map_2_para_no_resp(0.01, nBodies, nBodies, &NBodies.gpu_integrate/3)
  |> PolyHok.get_gnx()

next = System.monotonic_time()

IO.puts("PolyHok\t#{user_value}\t#{System.convert_time_unit(next - prev, :native, :millisecond)}")
