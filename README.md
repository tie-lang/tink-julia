# tink-julia

tink data-flow node frame protocol — Julia module (stdlib-only, no
dependencies). Universal and language-agnostic: any component that obeys the
frame protocol can join a tink pipeline.

```
帧 = [ len: u32 BE ][ payload: len 字节 ][ crc: u32 BE ]
len = payload 字节数
crc = CRC32-IEEE(payload)（多项式 0xEDB88320）
```

Mirrors `std/tink.tie` (tie standard library) and the other-language tink
libraries; pure functions over `Vector{UInt8}`, IO (stdin/stdout) left to the
caller. Function names follow the Julia convention (`tink_` prefix, snake_case)
to stay unambiguous at the top level.

## API

| function | description |
| --- | --- |
| `tink_crc32(data) -> UInt32` | CRC32-IEEE over a byte vector. Check vector: `tink_crc32(utf8"123456789") = 0xCBF43926` |
| `tink_frame_encode(payload) -> Vector{UInt8}` | encode a payload into a full frame `[len][payload][crc]` |
| `tink_frame_next(bytes, pos) -> TinkFrame \| nothing` | parse one frame at 1-based `pos`, verify CRC; `TinkFrame(payload, next)` on success, `nothing` on out-of-bounds / mismatch |
| `tink_frame_skip(bytes, pos) -> Int \| nothing` | skip one frame at 1-based `pos` without copying or verifying; `nothing` on out-of-bounds |

## Usage

```julia
include("tink.jl")
frame = tink_frame_encode(UInt8[1, 2, 3])
got = tink_frame_next(frame, 1)  # Julia is 1-based
```

## Test

```bash
julia test_tink.jl
```

## Cross-language

tink 帧协议各语言实现（API 语义与校验向量一致）：

| language | library |
| --- | --- |
| tie | `std/tink.tie` |
| Rust | `tink-rust`（tink crate） |
| C | `tink-c`（`tink.h` + `tink.c`） |
| Python | `tink-python`（`tink.py`） |
| JavaScript | `tink-js`（`tink.js` + `tink.d.ts`） |
| C++ | `tink-cpp`（`tink.hpp`） |
| Java | `tink-java`（`org.tielang.tink`） |
| C# | `tink-csharp`（namespace `Tink`） |
| Go | `tink-go`（package `tink`） |
| Zig | `tink-zig`（`tink.zig`） |
| Lua | `tink-lua`（`tink.lua`） |
| GDScript | `tink-godot`（`tink.gd`） |
| F# | `tink-fsharp`（`Tink.fs`） |
| PowerShell | `tink-powershell`（`tink.ps1`） |
| Kotlin | `tink-kotlin`（`Tink.kt`） |
| Ruby | `tink-ruby`（`tink.rb`） |
| Julia | this module（`tink-julia`） |

## License

本仓库使用 **Tie Public License v1.2 (TPL 1.2)**，完整文本见 [LICENSE](LICENSE)。
This repository is distributed under the **Tie Public License v1.2 (TPL 1.2)** — see [LICENSE](LICENSE) for the full text.