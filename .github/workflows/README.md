# GitHub Actions CI/CD Workflows

This directory contains the CI/CD workflows for the WebIDL runtime library.

## Workflows

### 1. CI (Continuous Integration) - `ci.yml`

**Triggers**: Push to main/master, Pull Requests

**Jobs**:
- **test**: Run all tests on Linux, macOS, Windows
- **memory-stress**: 2-minute memory stress test (2.9M operations)
- **lint**: Format checking with `zig fmt`
- **coverage**: Test coverage reporting
- **optimization-validation**: Verify inline storage, string interning, fast paths
- **security**: Check for hardcoded secrets and unsafe patterns
- **docs**: Verify documentation completeness
- **all-checks**: Final gate ensuring all checks pass

**Duration**: ~10-15 minutes

**Quality Gates**:
- ✅ 141+ tests passing
- ✅ Zero memory leaks
- ✅ Code formatting compliance
- ✅ All optimizations validated
- ✅ Documentation complete

### 2. Nightly (Extended Testing) - `nightly.yml`

**Triggers**: Daily at 2 AM UTC, Manual dispatch

**Jobs**:
- **extended-memory-stress**: 5 × 2-minute runs (10 minutes, 14.5M operations)
- **performance-benchmarks**: Optimization validation
- **test-matrix**: Test on Zig 0.15.0, 0.15.1, master
- **memory-sanitizer**: AddressSanitizer checks
- **fuzzing**: 5-minute fuzzing test
- **release-check**: Release readiness validation

**Duration**: ~30-45 minutes

**Purpose**:
- Catch regressions early
- Validate against Zig master branch
- Extended memory stress testing
- Release readiness checks

### 3. Release - `release.yml`

**Triggers**: Git tags (v*.*.*), Manual dispatch

**Jobs**:
- **validate-release**: Run all tests and memory stress
- **build-artifacts**: Build for Linux, macOS, Windows
- **create-release**: Create GitHub release with artifacts
- **publish-status**: Report release status

**Artifacts**:
- `webidl-linux-x86_64.tar.gz`
- `webidl-macos-x86_64.tar.gz`
- `webidl-windows-x86_64.zip`

**Duration**: ~20-30 minutes

## Workflow Status Badges

Add these to your README.md:

```markdown
![CI](https://github.com/YOUR_ORG/webidl/actions/workflows/ci.yml/badge.svg)
![Nightly](https://github.com/YOUR_ORG/webidl/actions/workflows/nightly.yml/badge.svg)
![Release](https://github.com/YOUR_ORG/webidl/actions/workflows/release.yml/badge.svg)
```

## Manual Workflow Triggers

### Run Nightly Build Manually

```bash
# Via GitHub UI
Go to Actions → Nightly Extended Tests → Run workflow

# Via GitHub CLI
gh workflow run nightly.yml
```

### Create a Release Manually

```bash
# Via GitHub CLI
gh workflow run release.yml -f version=1.0.0

# Or create a git tag
git tag v1.0.0
git push origin v1.0.0
```

## Quality Standards

All workflows enforce these quality standards:

### Code Quality
- ✅ All tests must pass (141+ tests)
- ✅ Zero memory leaks (verified by GPA)
- ✅ Code formatting (`zig fmt`)
- ✅ No TODOs/FIXMEs in release

### Performance
- ✅ Inline storage optimization (4-element capacity)
- ✅ String interning (43 common strings)
- ✅ Fast paths (primitive conversions)
- ✅ Memory stress: 24K+ ops/sec

### Documentation
- ✅ README.md present
- ✅ CHANGELOG.md present
- ✅ OPTIMIZATIONS.md present
- ✅ ARENA_ALLOCATOR_PATTERN.md present
- ✅ MEMORY_STRESS_TEST.md present

### Security
- ✅ No hardcoded secrets
- ✅ Memory-safe allocator patterns
- ✅ std.testing.allocator for leak detection

## Optimization Validation

The CI validates all four optimization strategies:

1. **Inline Storage** (5-10x speedup)
   - ObservableArray: 4-element inline storage
   - Maplike: 4-entry inline storage
   - Setlike: 4-value inline storage
   - Test: Verify heap_map/heap_set == null for ≤4 items

2. **String Interning** (20-30x speedup)
   - 43 common web strings pre-computed
   - Test: Verify interned string conversions

3. **Fast Paths** (2-3x speedup)
   - toLong, toDouble, toBoolean optimized
   - Test: Verify fast path vs slow path behavior

4. **Arena Allocator Pattern** (2-5x speedup)
   - Documentation and examples
   - Test: Validate pattern examples compile

## Memory Stress Testing

### CI (2 minutes)
- **Operations**: ~2,905,000
- **Throughput**: ~24,205 ops/sec
- **Result**: Zero leaks

### Nightly (10 minutes)
- **Operations**: ~14,500,000 (5 runs)
- **Throughput**: ~24,200 ops/sec average
- **Result**: Zero leaks across all runs

### What Gets Tested
- ObservableArray (inline + heap)
- Maplike (inline + heap)
- Setlike (inline + heap)
- FrozenArray
- String conversions (interned + non-interned)
- Primitive conversions (fast paths + slow paths)
- Error paths (proper cleanup on error)
- Mixed operations (realistic workloads)

## Platform Support

All workflows test on:
- **Linux**: ubuntu-latest
- **macOS**: macos-latest
- **Windows**: windows-latest

Zig version: 0.15.1 (with nightly testing on 0.15.0 and master)

## Debugging Workflow Failures

### Test Failures
```bash
# Run tests locally
zig build test

# Run specific test
zig test src/types/observable_arrays.zig
```

### Memory Stress Failures
```bash
# Run memory stress test locally
zig build memory-stress

# Should complete in ~2 minutes with zero leaks
```

### Format Failures
```bash
# Check formatting
zig fmt --check src/ benchmarks/

# Auto-fix formatting
zig fmt src/ benchmarks/
```

### Build Failures
```bash
# Clean build
rm -rf zig-cache zig-out .zig-cache
zig build

# Verbose build
zig build --verbose
```

## Contributing

When submitting a PR:

1. ✅ Ensure all tests pass locally: `zig build test`
2. ✅ Run memory stress test: `zig build memory-stress`
3. ✅ Format code: `zig fmt src/ benchmarks/`
4. ✅ Update CHANGELOG.md if user-visible changes
5. ✅ Add tests for new features
6. ✅ Update documentation if needed

The CI will run automatically on your PR and verify all quality gates.

## Release Process

1. **Update CHANGELOG.md** with version and changes
2. **Run nightly workflow** to ensure extended tests pass
3. **Create git tag**: `git tag v1.0.0 && git push origin v1.0.0`
4. **Release workflow** runs automatically:
   - Validates all tests
   - Runs memory stress test
   - Builds artifacts for all platforms
   - Creates GitHub release

## Monitoring

### CI Status
- Check Actions tab: https://github.com/YOUR_ORG/webidl/actions
- View workflow runs and logs
- Download artifacts from successful builds

### Nightly Results
- Review nightly summaries in Actions
- Check for regressions or compatibility issues
- Verify extended memory stress tests pass

### Performance Tracking
- Monitor operations/second in stress tests
- Track memory usage patterns
- Verify optimization hit rates

## Support

For CI/CD issues:
- Check workflow logs in GitHub Actions
- Review this documentation
- Open an issue with workflow run URL
