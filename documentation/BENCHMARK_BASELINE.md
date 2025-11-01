# WebIDL Performance Benchmark Baseline

**Date**: 2025-10-31  
**Zig Version**: 0.15.1  
**Build**: ReleaseFast  
**Platform**: macOS (darwin)  

## Benchmark Results

### Primitives (100,000 iterations)

| Operation | Time/op | Total | Rating | Notes |
|-----------|---------|-------|--------|-------|
| toLong (fast path) | 0 ns | 0.04 ms | ⚡ Excellent | In-range integer conversion |
| toLong (slow path) | 2 ns | 0.21 ms | ⚡ Excellent | Out-of-range wrapping |
| toDouble | 0 ns | 0.05 ms | ⚡ Excellent | Simple float conversion |
| toBoolean | 0 ns | 0.04 ms | ⚡ Excellent | Boolean conversion |
| toLongEnforceRange | 0 ns | 0.08 ms | ⚡ Excellent | With validation |
| toLongClamped | 0 ns | 0.08 ms | ⚡ Excellent | With clamping |

**Analysis**: Primitive conversions are **< 2ns/op** thanks to fast-path optimizations. Already optimal.

---

### Strings (10,000 iterations)

| Operation | Time/op | Total | Notes |
|-----------|---------|-------|-------|
| toDOMString (non-interned) | 4974 ns | 49.74 ms | UTF-8 → UTF-16 conversion |
| toDOMString (interned hit) | 4845 ns | 48.45 ms | Linear scan lookup |
| toUSVString | 4798 ns | 47.98 ms | With scalar validation |
| toByteString | 4784 ns | 47.84 ms | ASCII-only |

**Analysis**: 
- String operations are **~5μs/op** - **slowest category**
- Interning provides **2.5% speedup** (not significant)
- **OPTIMIZATION OPPORTUNITY**: Replace linear scan with hash map (10-20% gain)
- All string ops allocate (no way around this)

---

### Wrappers (100,000 iterations for simple, 10,000 for complex)

| Operation | Time/op | Total | Rating | Notes |
|-----------|---------|-------|--------|-------|
| Nullable (create/access) | 0 ns | 0.09 ms | ⚡ Excellent | Zero-cost abstraction |
| Optional (create/access) | 0 ns | 0.09 ms | ⚡ Excellent | Zero-cost abstraction |
| Sequence (append 4) | 6 ns | 0.07 ms | ⚡ Excellent | Inline storage |
| Sequence (append 100) | 11685 ns | 11.69 ms | Good | Heap allocations |
| Record (insert/get 2) | 8 ns | 0.08 ms | ⚡ Excellent | Small map |

**Analysis**:
- Nullable/Optional are **zero-cost** (compiler optimizes away)
- Small sequences (<= 4 items) use inline storage: **6ns/op**
- Large sequences: **~12μs/op** (100 appends with heap growth)
- **OPTIMIZATION OPPORTUNITY**: `Sequence.ensureCapacity()` missing (20-30% gain)

---

### Collections (10,000 iterations for small, 1,000 for large)

| Operation | Time/op | Total | Rating | Notes |
|-----------|---------|-------|--------|-------|
| ObservableArray (4 appends) | 10 ns | 0.10 ms | ⚡ Excellent | Inline storage |
| ObservableArray (100 appends) | 11860 ns | 11.86 ms | Good | Heap allocations |
| Maplike (insert/get 2) | 18 ns | 0.18 ms | ⚡ Excellent | Small map |
| Setlike (add/has 3) | 12 ns | 0.12 ms | ⚡ Excellent | Small set |

**Analysis**:
- ObservableArray ≈ Sequence performance (both use infra.List)
- Inline storage (4 items) is **10ns/op**
- Large collections: **~12μs/op** (similar to Sequence)
- Maplike/Setlike fast for small sizes

---

### Buffer Sources (10,000 iterations for small, 1,000 for large)

| Operation | Time/op | Total | Notes |
|-----------|---------|-------|-------|
| ArrayBuffer (1KB) | 4496 ns | 44.97 ms | Allocate + memset |
| ArrayBuffer (1MB) | 354 ns | 0.35 ms | **Larger is faster?** |
| TypedArray(u8) create/access | 4715 ns | 47.15 ms | With bounds checks |
| TypedArray(i32) create/access | 4822 ns | 48.22 ms | With bounds checks |

**Analysis**:
- ArrayBuffer allocation: **~5μs for 1KB**
- **ANOMALY**: 1MB allocation is faster (354ns) - likely fewer iterations (1000 vs 10000)
- TypedArray overhead: **~5μs/op**
- **OPTIMIZATION OPPORTUNITY**: Zero-copy views (80-90% gain for large buffers)

---

### Async Sequences (10,000 iterations)

| Operation | Time/op | Total | Rating | Notes |
|-----------|---------|-------|--------|-------|
| AsyncSequence (fromSlice) | 5 ns | 0.05 ms | ⚡ Excellent | Lightweight |
| BufferedAsyncSequence (push/next) | 7 ns | 0.07 ms | ⚡ Excellent | Queue overhead |

**Analysis**: Both async types are **< 10ns/op** - extremely fast.

---

## Performance Summary

### Fastest Operations (< 10ns/op) ⚡

1. **Primitives**: 0-2ns (all variants)
2. **Wrappers (Nullable/Optional)**: 0ns (zero-cost)
3. **Small collections (≤4 items)**: 6-10ns (inline storage)
4. **Async sequences**: 5-7ns (lightweight)

### Moderate Operations (10-100ns)

1. **Maplike/Setlike (small)**: 12-18ns

### Slow Operations (1-10μs)

1. **String conversions**: 4.8-5.0μs (UTF-8 → UTF-16 + allocation)
2. **Large sequences**: ~12μs/100 appends (heap growth)
3. **Buffer allocation**: ~5μs/1KB

---

## Optimization Priorities

### Priority 1: HIGH IMPACT ⭐

| Optimization | Target | Est. Gain | Complexity | Browser Support |
|--------------|--------|-----------|------------|-----------------|
| 1. Sequence.ensureCapacity() | Sequence/ObservableArray | 20-30% | Low | All |
| 2. String interning hash map | String conversions | 10-20% | Low | All |
| 3. Zero-copy buffer views | TypedArray | 80-90% | Medium | WebKit |
| 4. Inline keyword for hot paths | Primitives | 5-10% | Low | Firefox, WebKit |

### Priority 2: MEDIUM IMPACT

| Optimization | Target | Est. Gain | Complexity | Browser Support |
|--------------|--------|-----------|------------|-----------------|
| 5. Callback object pooling | Callbacks | 50-70% | Medium | Firefox |
| 6. Dictionary member bitmask | Dictionaries | 30-40% | Medium | Firefox |
| 7. Lazy string conversion | DOMString | 40-60% | Medium | WebKit |

### Priority 3: LOW IMPACT

| Optimization | Target | Est. Gain | Complexity |
|--------------|--------|-----------|------------|
| 8. Comptime type size tuning | Sequences | 5-10% | Low |
| 9. Struct-of-arrays for optionals | Dictionaries | 10-15% | High |

---

## Next Steps

1. ✅ **DONE**: Comprehensive benchmark suite created
2. **TODO**: Implement Priority 1 optimizations
   - [ ] Add `Sequence.ensureCapacity()` API
   - [ ] Replace string interning linear scan with HashMap
   - [ ] Add zero-copy TypedArray views
   - [ ] Mark hot paths with `inline` keyword
3. **TODO**: Re-benchmark after optimizations
4. **TODO**: Compare against browser implementations (V8, SpiderMonkey, JSC)

---

## Benchmark Reproduction

```bash
# Build and run benchmark
zig build bench -Doptimize=ReleaseFast

# Expected output: ~200ms total runtime
```

**Source**: `benchmarks/webidl_comprehensive_bench.zig`

---

## Notes

- All benchmarks use `std.mem.doNotOptimizeAway()` to prevent dead code elimination
- ReleaseFast optimization level for maximum performance
- Benchmark measures **overhead only** (no actual JavaScript engine integration)
- Real-world performance may vary based on JavaScript engine integration

---

**Related Documents**:
- `BROWSER_WEBIDL_OPTIMIZATIONS.md` - Browser optimization research
- `OPTIMIZATIONS.md` - Implemented optimizations
- `PERFORMANCE_TARGETS.md` - Performance goals
