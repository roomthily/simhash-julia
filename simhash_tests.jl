using Base.Test

# ported tests
@test Simhash(["aaa", "bbb"], 64).value == 8637903533912358349

# distance tests
sh = Simhash("How are you? I AM fine. Thanks. And you?", 64)
sh2 = Simhash("How old are you ? :-) i am fine. Thanks. And you?", 64)
@test distance(sh, sh2) > 0

sh3 = Simhash(sh2, 64)
@test distance(sh2, sh3) == 0

@test distance(Simhash("1", 64), Simhash("2", 64)) != 0


# short tests
shs = [Simhash(s, 64).value for s in ("aa", "aaa", "aaaa", "aaaab", "aaaaabb", "aaaaabbb")]

@testset "Short Strings" begin
  for (i, sh1) in enumerate(shs)
      for (j, sh2) in enumerate(shs)
          if i != j
              @test sh1 != sh2
          end
      end
  end
end
