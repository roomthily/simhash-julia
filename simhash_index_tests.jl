using Base.Test
include("simhash.jl")
include("simhash_index.jl")

data = Dict{Int, String}(1=>"How are you? I Am fine. blar blar blar blar blar Thanks.",
    2=>"How are you i am fine. blar blar blar blar blar than",
    3=>"This is simhash test.",
    4=>"How are you i am fine. blar blar blar blar blar thank1"
)

objs = [("$(k)", Simhash(v, 64)) for (k,v) in collect(data)]

simhash_index = SimhashIndex(objs, 64, 10)

@testset "Get Near Dupes" begin
    s1 = Simhash("How are you i am fine.ablar ablar xyz blar blar blar blar blar blar blar thank", 64)
    dups = get_near_dups(simhash_index, s1)
    @test length(dups) == 3
    
    delete_from_index(simhash_index, '1', Simhash(data[1], 64))
    dups = get_near_dups(simhash_index, s1)
    @test length(dups) == 2
    
    delete_from_index(simhash_index, '1', Simhash(data[1], 64))
    dups = get_near_dups(simhash_index, s1)
    @test length(dups) == 2
    
    add_to_index(simhash_index.bucket, ('1', Simhash(data[1], 64)), simhash_index.offsets)
    dups = get_near_dups(simhash_index, s1)
    @test length(dups) == 3
    
    add_to_index(simhash_index.bucket, ('1', Simhash(data[1], 64)), simhash_index.offsets)
    dups = get_near_dups(simhash_index, s1)
    @test length(dups) == 3
end
