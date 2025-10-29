# Arena Allocator Pattern for Complex Conversions

## Overview

When implementing complex WebIDL type conversions (dictionaries, unions, recursive structures), you often need to allocate multiple temporary objects. The **arena allocator pattern** simplifies memory management by allowing batch deallocation of all temporary allocations at once.

## When to Use Arena Allocators

Use arena allocators for:

1. **Dictionary conversions** - Many fields with temporary allocations
2. **Union type discrimination** - Multiple conversion attempts before finding the right type
3. **Recursive type conversions** - Nested structures with many intermediate allocations
4. **String processing** - Multiple temporary string transformations

**Do NOT use** for:
- Simple type conversions (integers, booleans, floats)
- Long-lived objects (return values that outlive the function)
- Small, fixed allocations (use stack allocation instead)

## Pattern

```zig
pub fn convertComplexType(allocator: std.mem.Allocator, value: JSValue) !ResultType {
    // Create arena for temporary allocations
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit(); // All temporary allocations freed here
    
    const temp_allocator = arena.allocator();
    
    // Step 1: Perform complex conversion using temp_allocator
    const intermediate1 = try someConversion(temp_allocator, value);
    const intermediate2 = try anotherConversion(temp_allocator, intermediate1);
    
    // Step 2: Build final result (allocate with original allocator)
    const result = try buildFinalResult(allocator, intermediate2);
    
    // Step 3: Return result (arena deinit cleans up all temporary data)
    return result;
}
```

## Example: Dictionary Conversion

```zig
const MyDict = struct {
    name: []const u8,
    age: i32,
    tags: [][]const u8,
};

pub fn toDictionary(allocator: std.mem.Allocator, value: JSValue) !MyDict {
    // Arena for temporary conversions
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp = arena.allocator();
    
    // Convert each field (many temporary strings)
    const name_temp = try convertStringField(temp, value, "name");
    const tags_temp = try convertArrayField(temp, value, "tags");
    
    // Allocate final result with original allocator
    const name = try allocator.dupe(u8, name_temp);
    errdefer allocator.free(name);
    
    const tags = try allocator.alloc([]const u8, tags_temp.len);
    errdefer allocator.free(tags);
    
    for (tags_temp, 0..) |tag_temp, i| {
        tags[i] = try allocator.dupe(u8, tag_temp);
    }
    
    return MyDict{
        .name = name,
        .age = try convertIntField(value, "age"),
        .tags = tags,
    };
    // Arena freed here - all temporary strings deallocated
}
```

## Example: Union Type Conversion

```zig
const MyUnion = union(enum) {
    string: []const u8,
    number: f64,
    object: MyObject,
};

pub fn toUnion(allocator: std.mem.Allocator, value: JSValue) !MyUnion {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp = arena.allocator();
    
    // Try each type (may allocate temporary objects)
    if (tryAsString(temp, value)) |str_temp| {
        const str = try allocator.dupe(u8, str_temp);
        return MyUnion{ .string = str };
    }
    
    if (tryAsNumber(value)) |num| {
        return MyUnion{ .number = num };
    }
    
    if (tryAsObject(temp, value)) |obj_temp| {
        const obj = try cloneObject(allocator, obj_temp);
        return MyUnion{ .object = obj };
    }
    
    return error.TypeError;
    // All failed conversion attempts cleaned up here
}
```

## Performance Benefits

### Without Arena (Manual Management)
```zig
const temp1 = try allocator.alloc(u8, 100);
errdefer allocator.free(temp1);

const temp2 = try allocator.alloc(u8, 200);
errdefer {
    allocator.free(temp2);
    allocator.free(temp1);
}

const temp3 = try allocator.alloc(u8, 300);
errdefer {
    allocator.free(temp3);
    allocator.free(temp2);
    allocator.free(temp1);
}

// Error-prone, verbose, O(n²) cleanup code
```

### With Arena (Batch Deallocation)
```zig
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit(); // O(1) cleanup

const temp1 = try arena.allocator().alloc(u8, 100);
const temp2 = try arena.allocator().alloc(u8, 200);
const temp3 = try arena.allocator().alloc(u8, 300);

// Simple, correct, fast
```

**Speedup**: 2-5x for complex conversions with many allocations

## Best Practices

### ✅ DO

- Use arena for temporary allocations within a single function
- Create arena at the start of complex conversions
- Use `defer arena.deinit()` immediately after creation
- Allocate final results with the original allocator
- Document when a function uses arena internally

### ❌ DON'T

- Return arena-allocated memory (it will be freed!)
- Use arena for long-lived objects
- Nest arenas (use a single arena per function)
- Mix arena allocations with return values

## Real-World Example

See `src/types/dictionaries.zig` for production usage:

```zig
pub fn convertDictionary(
    comptime T: type,
    allocator: std.mem.Allocator,
    value: JSValue,
) !T {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const temp = arena.allocator();
    
    // Complex dictionary parsing using temp allocator
    const parsed = try parseFields(temp, value);
    
    // Build final result with original allocator
    return try buildResult(T, allocator, parsed);
}
```

## Memory Safety

Arena allocators are **memory-safe** when used correctly:

1. ✅ **Leak-free**: `defer arena.deinit()` ensures cleanup
2. ✅ **Exception-safe**: Works with Zig's error handling
3. ✅ **Test with `std.testing.allocator`**: Catches leaks and double-frees

```zig
test "arena pattern - no leaks" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    
    const temp = arena.allocator();
    const data = try temp.alloc(u8, 1000);
    _ = data;
    
    // std.testing.allocator will catch any leaks
}
```

## Summary

| Pattern | Use Case | Speedup | Complexity |
|---------|----------|---------|------------|
| Manual | Simple conversions | Baseline | Low |
| Arena | Complex conversions | 2-5x | Low |
| Arena | Many temp allocations | 5-10x | Low |

**Recommendation**: Use arena allocators for any conversion with 3+ temporary allocations.

## References

- [Zig std.heap.ArenaAllocator docs](https://ziglang.org/documentation/master/std/#A;std:heap.ArenaAllocator)
- Browser engines (Chromium, Firefox) use similar "allocation scope" patterns
- WebIDL dictionary conversion (many temporary strings)
- JSON parsing (nested objects with many intermediate allocations)
