# Composable Tech Tree Engine - Project Brief

## Vision

A flexible technology tree engine that models technological advancement through **composable capabilities and requirements** rather than rigid prerequisite chains. Technologies specify what they *need* (abstract capabilities) rather than specific predecessor technologies, enabling emergent cross-domain synergies, multiple valid development paths, and novel combinations across disparate technology trees.

## Motivation

Traditional tech trees are directed acyclic graphs where specific technologies unlock other specific technologies. This is limiting:

- **Inflexible**: Only one path to any given technology
- **Domain-isolated**: Magic systems and technology systems cannot interact
- **Non-emergent**: All possibilities must be explicitly defined upfront
- **Unrealistic**: Real innovation often comes from applying solutions from one domain to problems in another

This engine treats technologies as **transformers of capabilities** - they consume certain capabilities and produce others. Requirements are satisfied by capabilities regardless of their source, enabling:

- Cross-domain synergies (magic satisfying tech requirements, vice versa)
- Multiple implementation paths to the same endpoint
- Emergent discoveries through novel combinations
- Realistic modeling of research and development

## Core Concepts

### Capabilities
Abstract properties or phenomena that can be produced and consumed. Examples:
- "Extreme pressure" (could come from hydraulics, magnetic confinement, or earth magic)
- "Thermal energy at 10^6 K" (lasers, plasma, fire magic)
- "Cleanroom environment" (infrastructure capability)
- "Precision lithography" (technique capability)

Capabilities have **types** and **properties** (magnitude, purity, etc.) but are implementation-agnostic.

### Technologies
Processes or knowledge that transform input capabilities into output capabilities. A technology specifies:
- **Requirements**: What capabilities must be available (evaluated by pluggable functions)
- **Outputs**: What capabilities this technology produces
- **Metadata**: Application-specific data (cost, time, flavor text)

Example: Fusion Reactor requires [extreme pressure, extreme heat, plasma containment] and produces [sustained energy output, radiation].

### Technology Trees
Collections of related technologies, typically organized by theme or domain. Examples:
- Industrial technology tree (steam → electricity → nuclear)
- Magical tree (elemental manipulation → transmutation)
- Biotech tree (genetics → synthetic biology)

Multiple trees can be active simultaneously, with technologies from different trees satisfying each other's requirements.

### Requirements
Pluggable predicates that evaluate whether available capabilities satisfy a technology's needs. The engine provides the requirement evaluation framework; implementers provide specific evaluator functions.

Requirements can be:
- Simple matches ("has capability X with magnitude >= Y")
- Formula-based ("pressure * temperature >= threshold")
- Complex custom logic (stoichiometry, physical laws)
- Alternative satisfaction paths (requirement met by *any of* multiple capability combinations)

### Sophistication and Margins
Barely meeting requirements vs. greatly exceeding them affects outcomes:
- **Margin**: How much capabilities exceed requirements
- **Reliability**: Higher margins → higher success rates, lower resource waste
- **Throughput**: Exceeding requirements enables faster/larger-scale production

The engine calculates margins; applications use them to determine success probability, efficiency, etc.

## Architecture

### Engine Responsibilities
- Define and store technology tree definitions (trees, technologies, requirements, capability definitions)
- Provide query API: given available capabilities and active trees, what technologies are accessible?
- Provide discovery API: given capability combinations, what new technologies/capabilities emerge?
- Calculate requirement satisfaction and margins via pluggable evaluators
- Remain stateless regarding capability instances (no tracking of "who has what")

### Application Layer Responsibilities
- Track which entities (players, civilizations, etc.) know which technologies
- Manage capability instances: production capacity, quality, availability
- Implement discovery mechanics: tinkerers, research labs, combination testing, resource consumption
- Handle success/failure based on requirement margins
- Persist game state
- UI/visualization

### Clear Separation
The engine is a **definition and evaluation system**. It does not manage simulation state, game progression, or player actions. Applications query the engine with current capability state and receive information about what's possible.

## Data Model

### TechnologyTree
```
{
  id: string
  name: string
  description: string
  metadata: {[key: string]: any}  // application-specific
}
```

### Technology
```
{
  id: string
  tree_id: string  // belongs to a technology tree
  name: string
  description: string
  requirements: Requirement[]
  outputs: CapabilityDefinition[]
  metadata: {[key: string]: any}
}
```

### Requirement
```
{
  evaluator: string  // references an evaluator function (e.g., "formula", "simple_match", "custom.lawson_criterion")
  config: {[key: string]: any}  // evaluator-specific configuration
}
```

### CapabilityDefinition (stored in engine)
```
{
  capability_type: string  // e.g., "thermal_energy", "magnetic_field"
  properties: {
    [key: string]: number | string | boolean
    // could include formulas based on input capabilities
  }
}
```

### CapabilityInstance (runtime, not stored by engine)
```
{
  type: string
  properties: {[key: string]: number | string | boolean}
  source_tech_id?: string  // optional provenance tracking
}
```

## API Surface

### Query API
```
query(
  available_capabilities: CapabilityInstance[],
  active_tree_ids: string[]
) -> {
  available_technologies: Technology[]
  producible_capabilities: CapabilityInstance[]
  requirement_margins: {[tech_id: string]: number}  // how well requirements are met
}
```

Given the current set of available capabilities and which technology trees are active, returns what technologies can be utilized and what new capabilities they would produce.

### Discovery API
```
discover(
  input_capabilities: CapabilityInstance[],
  active_tree_ids: string[],
  conditions?: any
) -> {
  discovered_technologies: Technology[]
  emergent_capabilities: CapabilityInstance[]
}
```

Given a set of capabilities being combined (e.g., a tinkerer experimenting), returns any technologies that would be revealed or novel capability combinations that emerge.

## Example Use Cases

### Multi-Domain Fusion
A civilization develops advanced cryomancy (magic tree), which produces "extreme pressure via ice compression." This satisfies the pressure requirement for fusion reactors (physics tree), even though the reactor was designed around hydraulic or magnetic confinement. The civilization achieves fusion through a novel magical-technological hybrid.

### Theory Before Practice
The space elevator technology exists in the tree with a requirement: "tensile strength >= 130 GPa at kilometer scale." No known material satisfies this. Researchers know it's theoretically possible and can direct materials research toward high-tensile-strength compounds. When carbon nanotubes are discovered (different research path), the system recognizes they satisfy the space elevator requirement.

### Tinkerer Discovery
A researcher is given access to: [electrical current, copper wire, iron core, magnetic lodestone]. Through random or guided experimentation, the discovery API reveals that this combination produces "electromagnetic field" - the researcher has stumbled upon the electromagnet, unlocking new technologies that require controlled magnetic fields.

### Alternative Requirement Paths
Cold fusion is "unreachable" in the standard physics tree - its requirements are impossibly high. The steampunk tree includes "ether stabilization" technology, which adds an *alternative satisfaction path* to fusion requirements: instead of [extreme pressure, extreme heat], fusion can also be achieved via [moderate heat, ether field]. The steampunk tree makes previously impossible technologies accessible.

### Scaling and Sophistication
A civilization discovers gunpowder (capability: explosive force) through alchemy. Initially they can produce small amounts with low reliability. As they develop better refinement techniques (higher sophistication), production becomes:
- More reliable (higher success rate)
- Higher quality (more consistent explosive force)
- Larger scale (from lab quantities to industrial production)

This enables technologies requiring "explosive force at industrial scale" like mining or artillery.

## Non-Goals

The engine explicitly does NOT handle:

- **Game state management**: Who knows what, resource tracking, turn progression
- **Discovery mechanics**: How tinkerers work, research funding, success probabilities
- **Balance or gameplay**: Technology costs, research times, strategic choices
- **UI/Visualization**: Tech tree displays, progress indicators
- **Specific technology trees**: The engine is content-agnostic
- **Requirement evaluator implementations**: Beyond possibly providing reference implementations
- **Formula evaluation**: If outputs use formulas, implementers provide evaluation
- **Capability instance lifecycle**: Production, consumption, decay, storage

These are application layer concerns. The engine provides the substrate for capability-based technology systems.

## Implementation Considerations

### Extensibility
- Requirement evaluators are pluggable - implementers can define custom logic
- Technology trees can be added dynamically (mods, expansions, user content)
- Capability types are freeform strings - no hardcoded taxonomy
- Metadata fields allow arbitrary application-specific data

### Performance
- Query operations should be efficient even with hundreds of technologies and complex requirement graphs
- Consider indexing by capability types for faster lookups
- Requirement evaluation might be expensive (complex formulas) - caching may be needed

### Data Integrity
- Technologies reference capability types by string - ensure consistency
- Circular dependencies possible (Tech A produces capability that Tech B needs, Tech B produces capability Tech A needs) - detection/handling?
- Invalid requirement configurations should fail gracefully with clear errors

### Example Implementations
Provide reference implementations demonstrating:
- Simple tech tree (stone age → information age)
- Sophistication modeled as capability quality tiers
- Formula-based requirements (Lawson criterion for fusion)
- Cross-tree interaction (magic + technology)
- Discovery mechanics (tinkerer simulation)

These serve as documentation and starting points for implementers.

## Success Criteria

The engine is successful if:

1. **Multiple valid paths exist**: Different capability sources can satisfy the same requirement
2. **Cross-domain synergy works**: Technologies from different trees can satisfy each other's requirements
3. **Emergent discovery feels natural**: Novel combinations reveal new technologies without explicit scripting
4. **Theory and practice separate cleanly**: Knowing a technology exists ≠ being able to build it
5. **Implementers have freedom**: Application layer can implement diverse mechanics on the same engine
6. **Content creators have power**: Tech trees can be arbitrarily complex (formulas, custom evaluators) or simple (boolean checks)

## Next Steps

1. **Formalize requirement evaluator interface**: Define contract for pluggable evaluators
2. **Implement core data structures**: Trees, technologies, capabilities in chosen language/platform
3. **Build query engine**: Evaluate which technologies are accessible given capabilities
4. **Create discovery system**: Handle capability combinations and emergence
5. **Develop reference implementations**: Example tech trees and evaluators
6. **Documentation**: Guide for content creators and application developers
7. **Validation tools**: Help creators test tech trees, detect impossible requirements, visualize dependency graphs

## Open Questions

- Should the engine provide built-in evaluators (simple_match, formula, any_of, all_of) or leave entirely to implementers?
- How to handle circular dependencies in technology graphs?
- Should capability instances track provenance (which tech produced them)?
- Do we need versioning for technology tree definitions (backwards compatibility)?
- Should the engine validate tech trees on load (impossible requirements, orphaned technologies)?
- How to handle partial satisfaction elegantly (tech works but poorly if requirements barely met)?

---

*This brief represents the conceptual design. Implementation details (language, platform, storage) are deliberately left open.*