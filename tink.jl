# tink.jl —— tink data-flow node frame protocol (universal, language-agnostic).
#
# Frame = [len u32 BE][payload][crc u32 BE]; crc = CRC32-IEEE (0xEDB88320).
# Mirrors ext/tink.tie (tie standard library) and the other-language tink
# libraries; pure functions over Vector{UInt8}, IO (stdin/stdout) left to the
# caller. Julia, stdlib-only, no dependencies.
#
#   frame = tink_frame_encode(UInt8[1, 2, 3])
#   got = tink_frame_next(frame, 1)  # Julia is 1-based

"""
    tink_crc32(data::AbstractVector{UInt8}) -> UInt32

CRC32-IEEE over a byte vector (bit-loop, no table; matches Base.crc32c for the
same semantics). Check vector: `tink_crc32(data"123456789") == 0xCBF43926`.
"""
function tink_crc32(data::AbstractVector{UInt8})::UInt32
    crc = UInt32(0xFFFFFFFF)
    for b in data
        crc ⊻= UInt32(b)
        for _ in 1:8
            crc = (crc & 1 == 1) ? ((crc >> 1) ⊻ UInt32(0xEDB88320)) : (crc >> 1)
        end
    end
    (crc ⊻ UInt32(0xFFFFFFFF)) & UInt32(0xFFFFFFFF)
end

"""
    tink_frame_encode(payload::AbstractVector{UInt8}) -> Vector{UInt8}

Encode a payload into a full frame: `[len u32 BE][payload][crc u32 BE]`.
"""
function tink_frame_encode(payload::AbstractVector{UInt8})::Vector{UInt8}
    n = length(payload)
    out = Vector{UInt8}(undef, n + 8)
    out[1] = UInt8((n >> 24) & 0xFF)
    out[2] = UInt8((n >> 16) & 0xFF)
    out[3] = UInt8((n >> 8) & 0xFF)
    out[4] = UInt8(n & 0xFF)
    for i in 1:n
        out[i + 4] = payload[i]
    end
    c = tink_crc32(payload)
    out[n + 5] = UInt8((c >> 24) & 0xFF)
    out[n + 6] = UInt8((c >> 16) & 0xFF)
    out[n + 7] = UInt8((c >> 8) & 0xFF)
    out[n + 8] = UInt8(c & 0xFF)
    out
end

struct TinkFrame
    payload::Vector{UInt8}
    next::Int
end

"""
    tink_frame_next(bytes::AbstractVector{UInt8}, pos::Int) -> Union{TinkFrame, Nothing}

Parse one frame at 1-based `pos` (verifies CRC). Returns a `TinkFrame` on
success or `nothing` on out-of-bounds / CRC mismatch. Payload is a copy.
"""
function tink_frame_next(bytes::AbstractVector{UInt8}, pos::Int)
    pos < 1 && return nothing
    length(bytes) < pos + 7 && return nothing
    n = tink_be32(bytes, pos)
    endpos = pos + 7 + n
    length(bytes) < endpos && return nothing
    payload = bytes[pos + 4:pos + 3 + n]
    want = tink_be32(bytes, endpos - 3)
    tink_crc32(payload) == want || return nothing
    TinkFrame(collect(payload), endpos)
end

"""
    tink_frame_skip(bytes::AbstractVector{UInt8}, pos::Int) -> Union{Int, Nothing}

Skip one frame at 1-based `pos` without copying or verifying (zero-copy).
Returns the position after the frame, or `nothing` on out-of-bounds.
"""
function tink_frame_skip(bytes::AbstractVector{UInt8}, pos::Int)
    pos < 1 && return nothing
    length(bytes) < pos + 7 && return nothing
    n = tink_be32(bytes, pos)
    endpos = pos + 7 + n
    length(bytes) < endpos && return nothing
    endpos
end

function tink_be32(b::AbstractVector{UInt8}, off::Int)::Int
    Int(b[off]) << 24 | Int(b[off + 1]) << 16 | Int(b[off + 2]) << 8 | Int(b[off + 3])
end