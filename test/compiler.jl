using Zygote, Test
using Zygote: forward, @grad

macro test_inferred(ex)
  :(let res = nothing
    @test begin
      res = @inferred $ex
      true
    end
    res
  end) |> esc
end

trace_contains(st, func, file, line) = any(st) do fr
  func in (nothing, fr.func) && endswith(String(fr.file), file) &&
    fr.line == line
end

bad(x) = x
@grad bad(x) = x, Δ -> error("bad")

function badly(x)
  x = x + 1
  x = bad(x)
  return x
end

y, back = forward(badly, 2)
@test y == 3
@test_throws Exception back(1)
bt = try back(1) catch e stacktrace(catch_backtrace()) end

@test trace_contains(bt, :badly, "compiler.jl", 24)
@test trace_contains(bt, nothing, "compiler.jl", 20)

# TODO infer what we can without hacks

if Zygote.usetyped
  include("typed.jl")
end