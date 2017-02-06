using Formatting
using Iterators

# port of the SimHashIndex class

_fe = FormatExpr("{1:x},{2}")

type SimhashIndex 
    # from py : list of tuples
    objs::Array{Tuple{String,Simhash}}
    f::Int
    k::Int
    count::Int
    
    # from py : default dict of sets
    bucket::Dict{String, Set} 
    
    # generate the offsets from the f, k
    offsets::Array{Int}
    
    function SimhashIndex(objs::Array{Tuple{String,Simhash}}, f::Int, k::Int)
        bucket = Dict{String, Set}(Set())
        offsets = _offsets(f, k)
        for obj in objs
            add_to_index(bucket, obj, offsets)
        end
        new(objs, f, k, length(objs), bucket, offsets)
    end
end

function add_to_index(bucket, obj, offsets)
    # obj = Tuple(string, simhash)
    obj_id = obj[1]
    simhash = obj[2]
    for key in _get_keys(simhash, offsets)
        v = format(_fe, simhash.value, obj_id) 
        if !haskey(bucket, key)
            bucket[key] = Set()
        end
        push!(bucket[key], v)
    end
end

function _offsets(f, k)
    # per the orig.: You may optimize this method according to 
    #     <http://www.wwwconference.org/www2007/papers/paper215.pdf>
    return [fld(f, (k + 1)) * (i - 1) for i in 1:(k + 1)] 
end

function _get_keys(simhash, offsets)
    keys = []
    fe = FormatExpr("{1:x}:{2:x}")
    for (i, offset) in enumerate(offsets)
        if i == length(offsets)
            m = 2 ^ (simhash.f - offset) - 1
        else
            m = 2 ^ (offsets[i+1] - offset) - 1
        end
        c = (simhash.value >> offset) & m
        push!(keys, format(fe, c, i-1))
    end
    return keys
end

function get_near_dups(index, simhash)
    # simhash = simhash obj to check against index
    ans = Set()

    for key in _get_keys(simhash, index.offsets)
        if !haskey(index.bucket, key)
            continue 
        end
        dups = index.bucket[key]
        
        if length(dups) > 200
            println("Warning: big bucket found: ", key) 
        end
        
        for dup in dups
            simhash2, obj_id = split(dup, ',', limit=2)
            simhash2 = Simhash(parse(BigInt, simhash2, 16), simhash.f)
            d = distance(simhash, simhash2)
            if d <= index.k
                push!(ans, obj_id)
            end
        end
    end
    
    return collect(ans)
end

function delete_from_index(index, obj_id, simhash)
    # string, simhash
    for key in _get_keys(simhash, index.offsets)
        v = format(_fe, simhash.value, obj_id)
        delete!(index.bucket[key], v)
    end
end
