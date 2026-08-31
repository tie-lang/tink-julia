# test_tink.jl —— unit tests for tink.jl. Run: julia test_tink.jl
include("tink.jl")

failures = Ref(0)

function check(cond::Bool, name::String)
    if cond
        println("[PASS] ", name)
    else
        failures[] += 1
        println("[FAIL] ", name)
    end
end

# crc32 check vector
check(tink_crc32(Vector{UInt8}("123456789")) == 0xCBF43926, "crc32 vector")

# frame roundtrip
p = UInt8[1, 2, 3]
frame = tink_frame_encode(p)
check(length(frame) == length(p) + 8, "frame length")
got = tink_frame_next(frame, 1)
check(got !== nothing, "frame present")
if got !== nothing
    check(got.next == length(frame), "frame next == length")
    check(got.payload == p, "frame payload roundtrip")
end

# empty frame roundtrip
fe = tink_frame_encode(UInt8[])
ge = tink_frame_next(fe, 1)
check(ge !== nothing && ge.next == length(fe) && isempty(ge.payload), "empty frame roundtrip")

# CRC tamper rejected
ft = tink_frame_encode(p)
ft[5] += 1 # tamper payload[0] (pos 5 in 1-based)
check(tink_frame_next(ft, 1) === nothing, "crc tamper rejected")

# frame_skip matches length
fs = tink_frame_encode(p)
check(tink_frame_skip(fs, 1) == length(fs), "frame_skip matches length")

# out of bounds
check(tink_frame_next(frame, length(frame) + 1) === nothing, "frame_next out of bounds")
check(tink_frame_skip(frame, length(frame) + 1) === nothing, "frame_skip out of bounds")
check(tink_frame_next(UInt8[], 1) === nothing, "frame_next empty input")

if failures[] > 0
    println(failures[], " checks FAILED")
    exit(1)
end
println("all tests passed")