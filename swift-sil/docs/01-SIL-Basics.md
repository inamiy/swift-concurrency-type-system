# SIL Basics

## SIL Stages

| Stage | Command | `sil_stage` | Description |
|-------|---------|-------------|-------------|
| **SILGen** | `-emit-silgen` | `sil_stage raw` | OSSA form, closest to source |
| **Canonical** | `-emit-sil` | `sil_stage canonical` | After mandatory passes |
| **Optimized** | `-emit-sil -O` | `sil_stage canonical` | After optimization passes |

### Which to Use?

- **SILGen**: Best for ownership/OSSA research
- **Canonical**: Best for general research - clean & readable
- **Optimized**: Skip for isolation research - adds noise from inlining

For actor isolation research, **Canonical** is recommended.

## OSSA (Ownership SSA)

OSSA makes ownership explicit in raw SIL (`-emit-silgen`):

| OSSA Instruction | Meaning |
|------------------|---------|
| `store %x to [init] %addr` | Initialize memory (take ownership) |
| `store %x to [assign] %addr` | Assign to already-initialized memory |
| `load [copy] %addr` | Load a copy (retain) |
| `load [take] %addr` | Load and consume (move) |
| `copy_value %x` | Explicit copy (retain) |
| `destroy_value %x` | Explicit destroy (release) |
| `begin_borrow %x` | Start a borrow |
| `end_borrow %x` | End a borrow |
| `destructure_tuple %t` | Destructure with ownership tracking |

### Example: OSSA vs Canonical

```sil
// SILGen (OSSA) - ownership explicit
sil [ossa] @foo {
  %1 = load [copy] %0       // explicit: this is a copy
  store %2 to [init] %addr  // explicit: initializing memory
  destroy_value %1          // explicit: releasing
}

// Canonical - ownership lowered
sil @foo {
  %1 = load %0              // implicit copy
  store %2 to %addr         // implicit assign/init
  release_value %1          // lowered to release
}
```

## SIL Function Attributes

| Attribute | Meaning |
|-----------|---------|
| `[ossa]` | Uses Ownership SSA (raw SIL only) |
| `[transparent]` | Always inlined |
| `[thunk]` | Thunk function |
| `[global_init]` | Global initializer |
| `[exact_self_class]` | Exact class type for self |

## Calling Conventions

| Convention | Usage |
|------------|-------|
| `$@convention(thin)` | Free function |
| `$@convention(method)` | Instance method |
| `$@convention(witness_method)` | Protocol witness |
| `$@convention(c)` | C function |
