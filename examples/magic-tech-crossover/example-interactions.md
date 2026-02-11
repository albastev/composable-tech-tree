# Magic-Tech Crossover - API Interaction Examples

This document shows the actual queries and responses that would occur when using the composable tech tree engine with the magic-tech crossover example.

## Scenario 1: Pure Technology Path - Step by Step

### Step 1: Starting with Basic Metallurgy

**Query Request:**
```json
{
  "available_capabilities": [],
  "active_tree_ids": ["physics_tree"]
}
```

**Query Response:**
```json
{
  "available_technologies": [
    {
      "id": "basic_metallurgy",
      "tree_id": "physics_tree",
      "name": "Basic Metallurgy",
      "requirements": [],
      "outputs": [
        {
          "capability_type": "metal_working",
          "properties": {
            "sophistication": "basic"
          }
        }
      ]
    }
  ],
  "producible_capabilities": [
    {
      "type": "metal_working",
      "properties": {
        "sophistication": "basic"
      },
      "source_tech_id": "basic_metallurgy"
    }
  ],
  "requirement_margins": {
    "basic_metallurgy": 1.0
  }
}
```

### Step 2: After Acquiring Metal Working

**Query Request:**
```json
{
  "available_capabilities": [
    {
      "type": "metal_working",
      "properties": {
        "sophistication": "basic"
      }
    }
  ],
  "active_tree_ids": ["physics_tree"]
}
```

**Query Response:**
```json
{
  "available_technologies": [
    {
      "id": "basic_metallurgy",
      "name": "Basic Metallurgy",
      "...": "..."
    },
    {
      "id": "hydraulic_press",
      "tree_id": "physics_tree",
      "name": "Hydraulic Press",
      "requirements": [
        {
          "evaluator": "simple_match",
          "config": {
            "capability_type": "metal_working",
            "min_sophistication": "basic"
          }
        }
      ],
      "outputs": [
        {
          "capability_type": "extreme_pressure",
          "properties": {
            "magnitude": 100,
            "unit": "atmospheres",
            "method": "hydraulic"
          }
        }
      ]
    },
    {
      "id": "industrial_furnace",
      "tree_id": "physics_tree",
      "name": "Industrial Furnace",
      "requirements": [
        {
          "evaluator": "simple_match",
          "config": {
            "capability_type": "metal_working",
            "min_sophistication": "basic"
          }
        }
      ],
      "outputs": [
        {
          "capability_type": "extreme_heat",
          "properties": {
            "magnitude": 5000,
            "unit": "kelvin",
            "method": "combustion"
          }
        }
      ]
    }
  ],
  "producible_capabilities": [
    {
      "type": "metal_working",
      "properties": {
        "sophistication": "basic"
      },
      "source_tech_id": "basic_metallurgy"
    },
    {
      "type": "extreme_pressure",
      "properties": {
        "magnitude": 100,
        "unit": "atmospheres",
        "method": "hydraulic"
      },
      "source_tech_id": "hydraulic_press"
    },
    {
      "type": "extreme_heat",
      "properties": {
        "magnitude": 5000,
        "unit": "kelvin",
        "method": "combustion"
      },
      "source_tech_id": "industrial_furnace"
    }
  ],
  "requirement_margins": {
    "basic_metallurgy": 1.0,
    "hydraulic_press": 1.0,
    "industrial_furnace": 1.0
  }
}
```

**Note:** Now that metal_working is available, both hydraulic_press and industrial_furnace unlock!

### Step 3: With Laser System Capabilities

**Query Request:**
```json
{
  "available_capabilities": [
    {
      "type": "metal_working",
      "properties": {
        "sophistication": "basic"
      }
    },
    {
      "type": "electrical_power",
      "properties": {
        "megawatts": 50
      }
    }
  ],
  "active_tree_ids": ["physics_tree"]
}
```

**Query Response (excerpt):**
```json
{
  "available_technologies": [
    "...",
    {
      "id": "laser_system",
      "tree_id": "physics_tree",
      "name": "High-Energy Laser System",
      "requirements": [
        {
          "evaluator": "simple_match",
          "config": {
            "capability_type": "electrical_power",
            "min_megawatts": 10
          }
        }
      ],
      "outputs": [
        {
          "capability_type": "extreme_heat",
          "properties": {
            "magnitude": 10000000,
            "unit": "kelvin",
            "method": "laser"
          }
        },
        {
          "capability_type": "extreme_pressure",
          "properties": {
            "magnitude": 1000,
            "unit": "atmospheres",
            "method": "laser_compression"
          }
        }
      ]
    },
    {
      "id": "magnetic_confinement",
      "tree_id": "physics_tree",
      "name": "Magnetic Confinement System",
      "requirements": [
        {
          "evaluator": "simple_match",
          "config": {
            "capability_type": "electrical_power",
            "min_megawatts": 50
          }
        }
      ],
      "outputs": [
        {
          "capability_type": "plasma_containment",
          "properties": {
            "method": "magnetic",
            "strength": 10
          }
        }
      ]
    }
  ],
  "producible_capabilities": [
    "...",
    {
      "type": "extreme_heat",
      "properties": {
        "magnitude": 10000000,
        "unit": "kelvin",
        "method": "laser"
      },
      "source_tech_id": "laser_system"
    },
    {
      "type": "extreme_pressure",
      "properties": {
        "magnitude": 1000,
        "unit": "atmospheres",
        "method": "laser_compression"
      },
      "source_tech_id": "laser_system"
    },
    {
      "type": "plasma_containment",
      "properties": {
        "method": "magnetic",
        "strength": 10
      },
      "source_tech_id": "magnetic_confinement"
    }
  ],
  "requirement_margins": {
    "laser_system": 5.0,
    "magnetic_confinement": 1.0
  }
}
```

**Note:** We have 50MW of power, laser only needs 10MW - margin of 5.0x! This could mean higher reliability/efficiency.

### Step 4: Achieving Fusion (Tech Path)

**Query Request:**
```json
{
  "available_capabilities": [
    {
      "type": "extreme_heat",
      "properties": {
        "magnitude": 10000000,
        "unit": "kelvin",
        "method": "laser"
      }
    },
    {
      "type": "extreme_pressure",
      "properties": {
        "magnitude": 1000,
        "unit": "atmospheres",
        "method": "laser_compression"
      }
    }
  ],
  "active_tree_ids": ["physics_tree"]
}
```

**Query Response:**
```json
{
  "available_technologies": [
    "...",
    {
      "id": "fusion_reactor_tech",
      "tree_id": "physics_tree",
      "name": "Fusion Reactor (Tech Path)",
      "requirements": [
        {
          "evaluator": "any_of",
          "config": {
            "alternatives": [
              {
                "comment": "Path 2: Inertial confinement fusion (lasers)",
                "evaluator": "all_of",
                "requirements": [
                  {
                    "evaluator": "simple_match",
                    "config": {
                      "capability_type": "extreme_heat",
                      "min_magnitude": 10000000,
                      "method": "laser"
                    }
                  },
                  {
                    "evaluator": "simple_match",
                    "config": {
                      "capability_type": "extreme_pressure",
                      "min_magnitude": 1000,
                      "method": "laser_compression"
                    }
                  }
                ]
              }
            ]
          }
        }
      ],
      "outputs": [
        {
          "capability_type": "fusion_power",
          "properties": {
            "output_megawatts": 1000,
            "method": "technological"
          }
        }
      ]
    }
  ],
  "producible_capabilities": [
    {
      "type": "fusion_power",
      "properties": {
        "output_megawatts": 1000,
        "method": "technological"
      },
      "source_tech_id": "fusion_reactor_tech"
    }
  ],
  "requirement_margins": {
    "fusion_reactor_tech": 1.0
  }
}
```

**Success!** Pure tech path to fusion achieved via inertial confinement.

---

## Scenario 2: Cross-Tree Magic Fulfilling Tech Requirements

### The Key Moment: Magic Heat Available

**Query Request:**
```json
{
  "available_capabilities": [
    {
      "type": "extreme_heat",
      "properties": {
        "magnitude": 15000000,
        "unit": "kelvin",
        "method": "pyromancy"
      }
    },
    {
      "type": "plasma_containment",
      "properties": {
        "method": "magnetic",
        "strength": 10
      }
    }
  ],
  "active_tree_ids": ["physics_tree", "elemental_magic_tree"]
}
```

**Query Response:**
```json
{
  "available_technologies": [
    "...",
    {
      "id": "fusion_reactor_tech",
      "tree_id": "physics_tree",
      "name": "Fusion Reactor (Tech Path)",
      "note": "SATISFIED by magic heat + tech containment!"
    },
    {
      "id": "fusion_reactor_hybrid",
      "tree_id": "physics_tree",
      "name": "Fusion Reactor (Hybrid Path)"
    }
  ],
  "producible_capabilities": [
    {
      "type": "fusion_power",
      "properties": {
        "output_megawatts": 1000,
        "method": "technological"
      },
      "source_tech_id": "fusion_reactor_tech"
    },
    {
      "type": "fusion_power",
      "properties": {
        "output_megawatts": 1500,
        "method": "hybrid",
        "efficiency": "superior"
      },
      "source_tech_id": "fusion_reactor_hybrid"
    }
  ],
  "requirement_margins": {
    "fusion_reactor_tech": 1.5,
    "fusion_reactor_hybrid": 1.5
  }
}
```

**Critical Insight:** 
- The physics tree fusion reactor doesn't care that heat comes from pyromancy!
- The requirement just checks for "extreme_heat >= 10M K" - satisfied
- Both tech-path fusion AND hybrid fusion are now available
- Margin of 1.5x because magic fire is hotter (15M K vs 10M K required)

---

## Scenario 3: Discovery API - Accidental Combination

### Researcher Experiments with Capabilities

**Discovery Request:**
```json
{
  "input_capabilities": [
    {
      "type": "extreme_heat",
      "properties": {
        "magnitude": 15000000,
        "unit": "kelvin",
        "method": "pyromancy"
      }
    },
    {
      "type": "plasma_containment",
      "properties": {
        "method": "magnetic",
        "strength": 10
      }
    }
  ],
  "active_tree_ids": ["physics_tree", "elemental_magic_tree"],
  "conditions": {
    "researcher_skill": "expert",
    "laboratory": "advanced"
  }
}
```

**Discovery Response:**
```json
{
  "discovered_technologies": [
    {
      "id": "fusion_reactor_tech",
      "tree_id": "physics_tree",
      "name": "Fusion Reactor (Tech Path)",
      "discovery_note": "Requirements satisfied - this combination enables fusion!"
    },
    {
      "id": "fusion_reactor_hybrid",
      "tree_id": "physics_tree",
      "name": "Fusion Reactor (Hybrid Path)",
      "discovery_note": "Cross-domain synergy detected!"
    }
  ],
  "emergent_capabilities": [
    {
      "type": "fusion_power",
      "properties": {
        "output_megawatts": 1500,
        "method": "hybrid",
        "efficiency": "superior"
      },
      "source_tech_id": "fusion_reactor_hybrid"
    }
  ]
}
```

**Narrative:**
A mage-scientist experimenting with combining pyromancy and magnetic containment discovers that this combination can achieve controlled fusion. This wasn't obvious from either discipline alone - emergent discovery!

---

## Scenario 4: Comparing All Three Paths Side-by-Side

### Query with All Capabilities Available

**Query Request:**
```json
{
  "available_capabilities": [
    {
      "type": "extreme_heat",
      "properties": {
        "magnitude": 10000000,
        "unit": "kelvin",
        "method": "laser"
      }
    },
    {
      "type": "extreme_heat",
      "properties": {
        "magnitude": 15000000,
        "unit": "kelvin",
        "method": "pyromancy"
      }
    },
    {
      "type": "plasma_containment",
      "properties": {
        "method": "magnetic",
        "strength": 10
      }
    },
    {
      "type": "plasma_containment",
      "properties": {
        "method": "aetheric",
        "strength": 15
      }
    },
    {
      "type": "extreme_pressure",
      "properties": {
        "magnitude": 1000,
        "unit": "atmospheres",
        "method": "laser_compression"
      }
    }
  ],
  "active_tree_ids": ["physics_tree", "elemental_magic_tree"]
}
```

**Query Response:**
```json
{
  "available_technologies": [
    {
      "id": "fusion_reactor_tech",
      "name": "Fusion Reactor (Tech Path)",
      "satisfied_by": "laser_heat + laser_pressure OR laser_heat + magnetic_containment"
    },
    {
      "id": "fusion_reactor_magic",
      "name": "Fusion Reactor (Magic Path)",
      "satisfied_by": "pyromancy_heat + aetheric_containment"
    },
    {
      "id": "fusion_reactor_hybrid",
      "name": "Fusion Reactor (Hybrid Path)",
      "satisfied_by": "MULTIPLE PATHS - pyromancy + magnetic, laser + aetheric, etc."
    }
  ],
  "producible_capabilities": [
    {
      "type": "fusion_power",
      "properties": {
        "output_megawatts": 1000,
        "method": "technological"
      },
      "source_tech_id": "fusion_reactor_tech"
    },
    {
      "type": "fusion_power",
      "properties": {
        "output_megawatts": 1200,
        "method": "magical"
      },
      "source_tech_id": "fusion_reactor_magic"
    },
    {
      "type": "fusion_power",
      "properties": {
        "output_megawatts": 1500,
        "method": "hybrid",
        "efficiency": "superior"
      },
      "source_tech_id": "fusion_reactor_hybrid"
    }
  ],
  "requirement_margins": {
    "fusion_reactor_tech": 1.0,
    "fusion_reactor_magic": 1.5,
    "fusion_reactor_hybrid": 2.0
  }
}
```

**Analysis:**
- All three fusion paths are available simultaneously
- Magic path has better margin (1.5x) due to hotter fire
- Hybrid path has best margin (2.0x) due to synergies
- Player can choose based on resource costs (mana vs materials vs power)

---

## Scenario 5: Magic-Enhanced Infrastructure Cascade

### Step 1: Just Cryomancy and Metallurgy

**Query Request:**
```json
{
  "available_capabilities": [
    {
      "type": "extreme_cold",
      "properties": {
        "magnitude": 1,
        "unit": "kelvin",
        "method": "cryomancy"
      }
    },
    {
      "type": "metal_working",
      "properties": {
        "sophistication": "basic"
      }
    }
  ],
  "active_tree_ids": ["physics_tree", "elemental_magic_tree"]
}
```

**Query Response:**
```json
{
  "available_technologies": [
    {
      "id": "cryomancy_superconductor",
      "tree_id": "elemental_magic_tree",
      "name": "Cryogenic Superconductors",
      "note": "Combining magic cold + tech metallurgy!"
    }
  ],
  "producible_capabilities": [
    {
      "type": "electrical_power",
      "properties": {
        "megawatts": 60,
        "efficiency": "high",
        "method": "magic_enhanced_superconductor"
      },
      "source_tech_id": "cryomancy_superconductor"
    }
  ],
  "requirement_margins": {
    "cryomancy_superconductor": 1.0
  }
}
```

### Step 2: With Magic-Enhanced Power

**Query Request:**
```json
{
  "available_capabilities": [
    {
      "type": "electrical_power",
      "properties": {
        "megawatts": 60,
        "efficiency": "high",
        "method": "magic_enhanced_superconductor"
      }
    }
  ],
  "active_tree_ids": ["physics_tree", "elemental_magic_tree"]
}
```

**Query Response:**
```json
{
  "available_technologies": [
    {
      "id": "laser_system",
      "name": "High-Energy Laser System",
      "note": "Unlocked by magic-enhanced power!"
    },
    {
      "id": "magnetic_confinement",
      "name": "Magnetic Confinement System",
      "note": "Also unlocked!"
    }
  ],
  "producible_capabilities": [
    {
      "type": "extreme_heat",
      "properties": {
        "magnitude": 10000000,
        "unit": "kelvin",
        "method": "laser"
      },
      "source_tech_id": "laser_system"
    },
    {
      "type": "extreme_pressure",
      "properties": {
        "magnitude": 1000,
        "unit": "atmospheres",
        "method": "laser_compression"
      },
      "source_tech_id": "laser_system"
    },
    {
      "type": "plasma_containment",
      "properties": {
        "method": "magnetic",
        "strength": 10
      },
      "source_tech_id": "magnetic_confinement"
    }
  ],
  "requirement_margins": {
    "laser_system": 6.0,
    "magnetic_confinement": 1.2
  }
}
```

**Cascade Effect:**
Ice magic → Better superconductors → More efficient power → Better lasers and magnets → Eventually enables fusion

The margins are higher (6.0x for laser) because magic-enhanced power is more efficient!

---

## Scenario 6: Requirement Margins and Sophistication

### Barely Meeting Requirements

**Query Request:**
```json
{
  "available_capabilities": [
    {
      "type": "extreme_heat",
      "properties": {
        "magnitude": 10000000,
        "unit": "kelvin",
        "method": "laser"
      }
    },
    {
      "type": "extreme_pressure",
      "properties": {
        "magnitude": 1000,
        "unit": "atmospheres",
        "method": "laser_compression"
      }
    }
  ],
  "active_tree_ids": ["physics_tree"]
}
```

**Query Response:**
```json
{
  "available_technologies": [
    {
      "id": "fusion_reactor_tech",
      "name": "Fusion Reactor (Tech Path)"
    }
  ],
  "producible_capabilities": [
    {
      "type": "fusion_power",
      "properties": {
        "output_megawatts": 1000,
        "method": "technological"
      },
      "source_tech_id": "fusion_reactor_tech"
    }
  ],
  "requirement_margins": {
    "fusion_reactor_tech": 1.0
  }
}
```

**Application Layer Interpretation:**
- Margin = 1.0 → Just barely meeting requirements
- Success probability: 60%
- Resource waste on failures: High
- Build time: Nominal

### Greatly Exceeding Requirements

**Query Request:**
```json
{
  "available_capabilities": [
    {
      "type": "extreme_heat",
      "properties": {
        "magnitude": 15000000,
        "unit": "kelvin",
        "method": "pyromancy"
      }
    },
    {
      "type": "extreme_pressure",
      "properties": {
        "magnitude": 2000,
        "unit": "atmospheres",
        "method": "geomancy"
      }
    }
  ],
  "active_tree_ids": ["physics_tree", "elemental_magic_tree"]
}
```

**Query Response:**
```json
{
  "available_technologies": [
    {
      "id": "fusion_reactor_hybrid",
      "name": "Fusion Reactor (Hybrid Path)"
    }
  ],
  "producible_capabilities": [
    {
      "type": "fusion_power",
      "properties": {
        "output_megawatts": 1500,
        "method": "hybrid",
        "efficiency": "superior"
      },
      "source_tech_id": "fusion_reactor_hybrid"
    }
  ],
  "requirement_margins": {
    "fusion_reactor_hybrid": 3.0
  }
}
```

**Application Layer Interpretation:**
- Margin = 3.0 → Far exceeding requirements (1.5x heat, 2x pressure)
- Success probability: 99%
- Resource waste: Minimal
- Build time: 50% faster
- Output quality: Higher (reflected in 1500MW vs 1000MW)

---

## Scenario 7: Trees Not Active - No Cross-Domain

### Magic Capabilities, But Magic Tree Not Active

**Query Request:**
```json
{
  "available_capabilities": [
    {
      "type": "extreme_heat",
      "properties": {
        "magnitude": 15000000,
        "unit": "kelvin",
        "method": "pyromancy"
      }
    },
    {
      "type": "plasma_containment",
      "properties": {
        "method": "magnetic",
        "strength": 10
      }
    }
  ],
  "active_tree_ids": ["physics_tree"]
}
```

**Query Response:**
```json
{
  "available_technologies": [
    {
      "id": "fusion_reactor_tech",
      "name": "Fusion Reactor (Tech Path)",
      "note": "Magic heat still satisfies tech requirements!"
    }
  ],
  "producible_capabilities": [
    {
      "type": "fusion_power",
      "properties": {
        "output_megawatts": 1000,
        "method": "technological"
      },
      "source_tech_id": "fusion_reactor_tech"
    }
  ],
  "requirement_margins": {
    "fusion_reactor_tech": 1.5
  }
}
```

**Note:** Hybrid fusion reactor doesn't appear because it's only in the tree when elemental_magic_tree is active. But the magic capabilities still satisfy tech tree requirements!

---

## Summary of Key API Patterns

### Pattern 1: Capability Source Agnosticism
Requirements check capability type and properties, not source. "extreme_heat" from pyromancy = "extreme_heat" from lasers.

### Pattern 2: Alternative Satisfaction Paths
`any_of` evaluator allows multiple ways to satisfy same requirement. Engine checks all paths, returns satisfied if any work.

### Pattern 3: Margin Calculation
Engine calculates how much capabilities exceed requirements. Application layer uses this for:
- Success probability
- Resource efficiency  
- Build time
- Output quality

### Pattern 4: Cross-Tree Synergy
When multiple trees active, technologies from different trees can satisfy each other's requirements - emergent, not pre-programmed.

### Pattern 5: Discovery as Query
Discovery API is essentially: "Given these specific capabilities, what technologies become available that weren't obvious?" Returns surprising combinations.

### Pattern 6: Tree Activation Control
Same capabilities might enable different technologies depending on which trees are active. Application controls what's "in scope" for a civilization/player.

---

## Evaluator Implementation Notes

To make this example work, you'd need to implement:

### simple_match evaluator
```javascript
function simple_match(available_capabilities, config) {
  const matching = available_capabilities.find(
    cap => cap.type === config.capability_type
  );
  
  if (!matching) {
    return { satisfied: false, margin: 0 };
  }
  
  // Check property constraints if specified
  if (config.min_magnitude) {
    const magnitude = matching.properties.magnitude;
    if (magnitude < config.min_magnitude) {
      return { 
        satisfied: false, 
        margin: magnitude / config.min_magnitude 
      };
    }
    return { 
      satisfied: true, 
      margin: magnitude / config.min_magnitude 
    };
  }
  
  return { satisfied: true, margin: 1.0 };
}
```

### any_of evaluator
```javascript
function any_of(available_capabilities, config) {
  for (const alternative of config.alternatives) {
    const result = evaluate_requirement(
      available_capabilities, 
      alternative
    );
    if (result.satisfied) {
      return result; // First satisfied path wins
    }
  }
  return { satisfied: false, margin: 0 };
}
```

### all_of evaluator
```javascript
function all_of(available_capabilities, config) {
  let min_margin = Infinity;
  
  for (const requirement of config.requirements) {
    const result = evaluate_requirement(
      available_capabilities, 
      requirement
    );
    if (!result.satisfied) {
      return { satisfied: false, margin: result.margin };
    }
    min_margin = Math.min(min_margin, result.margin);
  }
  
  return { satisfied: true, margin: min_margin };
}
```

These evaluators enable all the cross-domain interactions shown in this example!