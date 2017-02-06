using Nettle
using Formatting
using Iterators

_regex = r"\w+"
# default in py : r"[\w\u4e00-\u9fcc]+"
# going with the more straightforward get the words

type Simhash
    # this, unfortunately, does not hash on init
    value
    f::Int

    function Simhash(value::BigInt, f::Int)
        new(value, f)
    end
    function Simhash(value::Simhash, f::Int)
        new(value.value, f)
    end
    function Simhash(value::AbstractString, f::Int)
        v = build_by_text(value, f)
        new(v, f)
    end
    function Simhash(value::Dict, f::Int)
        v = build_by_features(value, f)
        new(v, f)
    end
    function Simhash(value::AbstractArray, f::Int)
        v = build_by_features(value, f)
        new(v, f)
    end
    function Simhash(s::Simhash)
        new(s.value, s.f)
    end
end

function _hashfunc(x)
    h = Hasher("md5")
    update!(h, x)
    return parse(UInt128, hexdigest!(h), 16)
end

function distance(one::Simhash, another::Simhash)
    # this is ridiculous, julia
    x =  BigInt((one.value $ another.value) & ((BigInt(1) << BigInt(one.f)) - BigInt(1)))
    ans = 0
    while x > 0
        ans += 1
        x &= x - 1
    end
    return ans
end

function _tokenize(content::String)
    content = lowercase(content)
    content = join(matchall(_regex, content), "")
    return _slide(content)
end

function _slide(content::String, width=4)
    return [content[i:min(i + width-1, length(content))] for i in 1:max(length(content) - width, 1) + 1]
end

function build_by_text(content::String, f)
    features = _tokenize(content)
    fdict = Dict{String, Integer}(g[1] => length(g) for g = groupby(x -> x, sort(features)))
    return build_by_features(fdict, f)
end

function build_by_features(features::Any, f)
    v = zeros(f)
    masks = [BigInt(1) << BigInt(i-1) for i in 1:f]

    if isa(features, Dict)
        # to list of tuples
        features = collect(features)
    end

    for feat in features
        # strings are by default unicode
        if isa(feat, String)
            h = _hashfunc(feat)
            w = 1
        else
            # without assertion for the iterables
            h = _hashfunc(feat[1])
            w = feat[2]
        end

        for i in 1:f
            v[i] += h & masks[i] != 0 ? w : -w
        end
    end

    ans = 0
    for i in 1:f
        if v[i] >= 0
            ans |= masks[i]
        end
    end

    # numeric rep of the string/iterable
    return ans
end
