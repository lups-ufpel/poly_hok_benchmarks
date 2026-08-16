require PolyHok

PolyHok.defmodule RayTracer do
  defd raytracing(image, width, spheres, x, y) do
    ox = 0.0
    oy = 0.0
    ox = x - width / 2
    oy = y - width / 2

    r = 0.0
    g = 0.0
    b = 0.0

    maxz = -99999.0

    for i in range(0, 20) do
      sphereRadius = spheres[i * 7 + 3]

      dx = ox - spheres[i * 7 + 4]
      dy = oy - spheres[i * 7 + 5]
      n = 0.0
      t = -99999.0
      dz = 0.0

      if dx * dx + dy * dy < sphereRadius * sphereRadius do
        dz = sqrtf(sphereRadius * sphereRadius - dx * dx - dy * dy)
        n = dz / sqrtf(sphereRadius * sphereRadius)
        t = dz + spheres[i * 7 + 6]
      else
        t = -99999.0
        n = 0.0
      end

      if t > maxz do
        fscale = n
        r = spheres[i * 7 + 0] * fscale
        g = spheres[i * 7 + 1] * fscale
        b = spheres[i * 7 + 2] * fscale
        maxz = t
      end
    end

    image[0] = r * 255
    image[1] = g * 255
    image[2] = b * 255
    image[3] = 255
  end

  defk mapxy_2D_step_2_para_no_resp_kernel(d_array, step, par1, par2, size, f) do
    x = threadIdx.x + blockIdx.x * blockDim.x
    y = threadIdx.y + blockIdx.y * blockDim.y
    offset = x + y * blockDim.x * gridDim.x

    id = step * offset

    if offset < size * size do
      f(d_array + id, par1, par2, x, y)
    end
  end

  def mapxy_2D_para_no_resp(d_array, step, par1, par2, size, f) do
    PolyHok.spawn(
      &RayTracer.mapxy_2D_step_2_para_no_resp_kernel/6,
      {trunc(size / 16), trunc(size / 16), 1},
      {16, 16, 1},
      [d_array, step, par1, par2, size, f]
    )

    d_array
  end
end

defmodule Main do
  def rnd(x) do
    :rand.uniform() * x
  end

  def sphereMaker(0, _dim), do: []

  def sphereMaker(n, dim) do
    [
      Main.rnd(1),
      Main.rnd(1),
      Main.rnd(1),
      Main.rnd(trunc(dim / 10)) + dim / 50,
      Main.rnd(dim) - trunc(dim / 2),
      Main.rnd(dim) - trunc(dim / 2),
      Main.rnd(dim) - trunc(dim / 2)
      | sphereMaker(n - 1, dim)
    ]
  end

  def dim do
    {d, _} = Integer.parse(Enum.at(System.argv(), 0))
    d
  end

  def spheres do
    20
  end

  def main do
    sphereList = Nx.tensor([sphereMaker(Main.spheres(), Main.dim())], type: {:f, 32})

    width = Main.dim()
    height = width

    prev = System.monotonic_time()

    ref_sphere = PolyHok.new_gnx(sphereList)
    ref_image = PolyHok.new_gnx({1, width * height * 4}, {:s, 32})

    RayTracer.mapxy_2D_para_no_resp(
      ref_image,
      4,
      width,
      ref_sphere,
      width,
      &RayTracer.raytracing/5
    )

    image = PolyHok.get_gnx(ref_image)

    next = System.monotonic_time()

    IO.puts("PolyHok\t#{width}\t#{System.convert_time_unit(next - prev, :native, :millisecond)} ")

    Bmp.gen_bmp_int("raytracer.bmp", width, image)
  end
end

Main.main()
