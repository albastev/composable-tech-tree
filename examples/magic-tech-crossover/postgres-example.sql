-- ============================================================================
-- Composable Tech Tree Engine - Magic-Tech Crossover Example
-- PostgreSQL Implementation (Standalone)
-- ============================================================================
--
-- This file includes:
-- 1. Complete schema creation
-- 2. Magic-tech crossover example data
-- 3. Sample queries demonstrating the system
--
-- Run this entire file to set up a working example database.

-- ============================================================================
-- SCHEMA CREATION
-- ============================================================================

-- Drop existing objects if they exist (for clean re-runs)
DROP MATERIALIZED VIEW IF EXISTS mv_technologies_complete CASCADE;
DROP VIEW IF EXISTS v_capability_types CASCADE;
DROP VIEW IF EXISTS v_trees_summary CASCADE;
DROP VIEW IF EXISTS v_technologies_complete CASCADE;
DROP TABLE IF EXISTS capability_definitions CASCADE;
DROP TABLE IF EXISTS requirements CASCADE;
DROP TABLE IF EXISTS technologies CASCADE;
DROP TABLE IF EXISTS technology_trees CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS refresh_technologies_cache() CASCADE;
DROP FUNCTION IF EXISTS insert_technology_complete(VARCHAR, VARCHAR, VARCHAR, TEXT, JSONB, JSONB, JSONB) CASCADE;
DROP FUNCTION IF EXISTS validate_technology_tree(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS get_required_capability_types(VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS get_technologies_producing_capability(VARCHAR, VARCHAR[]) CASCADE;
DROP FUNCTION IF EXISTS get_technologies_by_trees(VARCHAR[]) CASCADE;
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;

-- Technology Trees
CREATE TABLE technology_trees (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_trees_metadata ON technology_trees USING GIN (metadata);

-- Technologies
CREATE TABLE technologies (
    id VARCHAR(255) PRIMARY KEY,
    tree_id VARCHAR(255) NOT NULL REFERENCES technology_trees(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_technologies_tree_id ON technologies(tree_id);
CREATE INDEX idx_technologies_name ON technologies(name);
CREATE INDEX idx_technologies_metadata ON technologies USING GIN (metadata);

-- Requirements
CREATE TABLE requirements (
    id SERIAL PRIMARY KEY,
    technology_id VARCHAR(255) NOT NULL REFERENCES technologies(id) ON DELETE CASCADE,
    evaluator VARCHAR(255) NOT NULL,
    config JSONB NOT NULL DEFAULT '{}',
    requirement_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_requirements_technology_id ON requirements(technology_id);
CREATE INDEX idx_requirements_evaluator ON requirements(evaluator);
CREATE INDEX idx_requirements_config ON requirements USING GIN (config);
CREATE INDEX idx_requirements_capability_type ON requirements ((config->>'capability_type'));

-- Capability Definitions
CREATE TABLE capability_definitions (
    id SERIAL PRIMARY KEY,
    technology_id VARCHAR(255) NOT NULL REFERENCES technologies(id) ON DELETE CASCADE,
    capability_type VARCHAR(255) NOT NULL,
    properties JSONB NOT NULL DEFAULT '{}',
    output_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_capability_defs_technology_id ON capability_definitions(technology_id);
CREATE INDEX idx_capability_defs_type ON capability_definitions(capability_type);
CREATE INDEX idx_capability_defs_properties ON capability_definitions USING GIN (properties);

-- ============================================================================
-- VIEWS
-- ============================================================================

CREATE VIEW v_technologies_complete AS
SELECT 
    t.id,
    t.tree_id,
    t.name,
    t.description,
    t.metadata,
    tt.name as tree_name,
    (
        SELECT json_agg(
            json_build_object(
                'id', r.id,
                'evaluator', r.evaluator,
                'config', r.config,
                'order', r.requirement_order
            ) ORDER BY r.requirement_order
        )
        FROM requirements r
        WHERE r.technology_id = t.id
    ) as requirements,
    (
        SELECT json_agg(
            json_build_object(
                'id', cd.id,
                'capability_type', cd.capability_type,
                'properties', cd.properties,
                'order', cd.output_order
            ) ORDER BY cd.output_order
        )
        FROM capability_definitions cd
        WHERE cd.technology_id = t.id
    ) as outputs
FROM technologies t
JOIN technology_trees tt ON t.tree_id = tt.id;

-- ============================================================================
-- EXAMPLE DATA: MAGIC-TECH CROSSOVER
-- ============================================================================

-- Insert Technology Trees
INSERT INTO technology_trees (id, name, description, metadata) VALUES
('physics_tree', 'Physics & Engineering', 'Technologies based on physical laws and engineering', 
 '{"theme": "hard_science", "color": "#2196F3"}'::jsonb),
('elemental_magic_tree', 'Elemental Magic', 'Manipulation of fundamental elemental forces',
 '{"theme": "arcane", "color": "#9C27B0"}'::jsonb);

-- ============================================================================
-- PHYSICS TREE TECHNOLOGIES
-- ============================================================================

-- Basic Metallurgy (Starting tech - no requirements)
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('basic_metallurgy', 'physics_tree', 'Basic Metallurgy', 
 'Understanding of heating and shaping metals', '{"tier": 1}'::jsonb);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('basic_metallurgy', 'metal_working', '{"sophistication": "basic"}'::jsonb, 0);

-- Hydraulic Press
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('hydraulic_press', 'physics_tree', 'Hydraulic Press',
 'Mechanical system for generating extreme pressure', '{"tier": 2}'::jsonb);

INSERT INTO requirements (technology_id, evaluator, config, requirement_order) VALUES
('hydraulic_press', 'simple_match', '{"capability_type": "metal_working", "min_sophistication": "basic"}'::jsonb, 0);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('hydraulic_press', 'extreme_pressure', '{"magnitude": 100, "unit": "atmospheres", "method": "hydraulic"}'::jsonb, 0);

-- Industrial Furnace
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('industrial_furnace', 'physics_tree', 'Industrial Furnace',
 'High-temperature furnace for industrial applications', '{"tier": 2}'::jsonb);

INSERT INTO requirements (technology_id, evaluator, config, requirement_order) VALUES
('industrial_furnace', 'simple_match', '{"capability_type": "metal_working", "min_sophistication": "basic"}'::jsonb, 0);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('industrial_furnace', 'extreme_heat', '{"magnitude": 5000, "unit": "kelvin", "method": "combustion"}'::jsonb, 0);

-- Laser System
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('laser_system', 'physics_tree', 'High-Energy Laser System',
 'Focused laser for heating and compression', '{"tier": 4, "note": "Lasers can provide both heat and compression"}'::jsonb);

INSERT INTO requirements (technology_id, evaluator, config, requirement_order) VALUES
('laser_system', 'simple_match', '{"capability_type": "electrical_power", "min_megawatts": 10}'::jsonb, 0);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('laser_system', 'extreme_heat', '{"magnitude": 10000000, "unit": "kelvin", "method": "laser"}'::jsonb, 0),
('laser_system', 'extreme_pressure', '{"magnitude": 1000, "unit": "atmospheres", "method": "laser_compression"}'::jsonb, 1);

-- Magnetic Confinement
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('magnetic_confinement', 'physics_tree', 'Magnetic Confinement System',
 'Powerful magnetic fields to contain plasma', '{"tier": 4}'::jsonb);

INSERT INTO requirements (technology_id, evaluator, config, requirement_order) VALUES
('magnetic_confinement', 'simple_match', '{"capability_type": "electrical_power", "min_megawatts": 50}'::jsonb, 0);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('magnetic_confinement', 'plasma_containment', '{"method": "magnetic", "strength": 10}'::jsonb, 0);

-- Fusion Reactor (Tech Path)
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('fusion_reactor_tech', 'physics_tree', 'Fusion Reactor (Tech Path)',
 'Controlled fusion using conventional physics and engineering',
 '{"tier": 5, "note": "Pure tech path to fusion - multiple routes possible"}'::jsonb);

-- Note: This uses nested any_of/all_of structure - stored as JSONB config
INSERT INTO requirements (technology_id, evaluator, config, requirement_order) VALUES
('fusion_reactor_tech', 'any_of', 
 '{
   "alternatives": [
     {
       "comment": "Path 1: Magnetic confinement fusion",
       "evaluator": "all_of",
       "requirements": [
         {"evaluator": "simple_match", "config": {"capability_type": "extreme_heat", "min_magnitude": 10000000, "unit": "kelvin"}},
         {"evaluator": "simple_match", "config": {"capability_type": "plasma_containment", "method": "magnetic"}}
       ]
     },
     {
       "comment": "Path 2: Inertial confinement fusion (lasers)",
       "evaluator": "all_of",
       "requirements": [
         {"evaluator": "simple_match", "config": {"capability_type": "extreme_heat", "min_magnitude": 10000000, "method": "laser"}},
         {"evaluator": "simple_match", "config": {"capability_type": "extreme_pressure", "min_magnitude": 1000, "method": "laser_compression"}}
       ]
     }
   ]
 }'::jsonb, 0);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('fusion_reactor_tech', 'fusion_power', '{"output_megawatts": 1000, "method": "technological"}'::jsonb, 0);

-- Fusion Reactor (Hybrid Path)
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('fusion_reactor_hybrid', 'physics_tree', 'Fusion Reactor (Hybrid Path)',
 'Controlled fusion using the best of magic and technology',
 '{"tier": 5, "note": "Hybrid approach is most powerful - synergy bonus!", "research_insight": "Combining magic and technology creates emergent benefits"}'::jsonb);

INSERT INTO requirements (technology_id, evaluator, config, requirement_order) VALUES
('fusion_reactor_hybrid', 'any_of',
 '{
   "alternatives": [
     {
       "comment": "Hybrid: Magic heat + Tech containment",
       "evaluator": "all_of",
       "requirements": [
         {"evaluator": "simple_match", "config": {"capability_type": "extreme_heat", "min_magnitude": 10000000, "method": "pyromancy"}},
         {"evaluator": "simple_match", "config": {"capability_type": "plasma_containment", "method": "magnetic"}}
       ]
     },
     {
       "comment": "Hybrid: Tech heat + Magic containment",
       "evaluator": "all_of",
       "requirements": [
         {"evaluator": "simple_match", "config": {"capability_type": "extreme_heat", "min_magnitude": 10000000, "method": "laser"}},
         {"evaluator": "simple_match", "config": {"capability_type": "plasma_containment", "method": "aetheric"}}
       ]
     },
     {
       "comment": "Hybrid: Magic-enhanced superconductors + Tech systems",
       "evaluator": "all_of",
       "requirements": [
         {"evaluator": "simple_match", "config": {"capability_type": "extreme_heat", "min_magnitude": 10000000, "method": "laser"}},
         {"evaluator": "simple_match", "config": {"capability_type": "electrical_power", "min_megawatts": 50, "method": "magic_enhanced_superconductor"}}
       ]
     }
   ]
 }'::jsonb, 0);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('fusion_reactor_hybrid', 'fusion_power', '{"output_megawatts": 1500, "method": "hybrid", "efficiency": "superior"}'::jsonb, 0);

-- ============================================================================
-- ELEMENTAL MAGIC TREE TECHNOLOGIES
-- ============================================================================

-- Basic Pyromancy (Starting tech)
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('pyromancy_basic', 'elemental_magic_tree', 'Basic Pyromancy',
 'Fundamental fire magic - create and control flames', '{"tier": 1, "mana_cost": "low"}'::jsonb);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('pyromancy_basic', 'magical_fire', '{"intensity": "basic", "control": "moderate"}'::jsonb, 0);

-- Advanced Pyromancy
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('pyromancy_advanced', 'elemental_magic_tree', 'Advanced Pyromancy',
 'Mastery of fire - achieve extreme temperatures', '{"tier": 3, "mana_cost": "high", "note": "Magic fire can be hotter than any furnace"}'::jsonb);

INSERT INTO requirements (technology_id, evaluator, config, requirement_order) VALUES
('pyromancy_advanced', 'simple_match', '{"capability_type": "magical_fire", "min_intensity": "basic"}'::jsonb, 0);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('pyromancy_advanced', 'extreme_heat', '{"magnitude": 15000000, "unit": "kelvin", "method": "pyromancy"}'::jsonb, 0);

-- Basic Geomancy (Starting tech)
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('geomancy_basic', 'elemental_magic_tree', 'Basic Geomancy',
 'Earth magic - manipulate stone and pressure', '{"tier": 1, "mana_cost": "low"}'::jsonb);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('geomancy_basic', 'earth_manipulation', '{"intensity": "basic"}'::jsonb, 0);

-- Geomantic Compression
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('geomancy_compression', 'elemental_magic_tree', 'Geomantic Compression',
 'Use earth magic to generate extreme pressure', '{"tier": 2, "mana_cost": "moderate"}'::jsonb);

INSERT INTO requirements (technology_id, evaluator, config, requirement_order) VALUES
('geomancy_compression', 'simple_match', '{"capability_type": "earth_manipulation", "min_intensity": "basic"}'::jsonb, 0);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('geomancy_compression', 'extreme_pressure', '{"magnitude": 500, "unit": "atmospheres", "method": "geomancy"}'::jsonb, 0);

-- Basic Cryomancy (Starting tech)
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('cryomancy_basic', 'elemental_magic_tree', 'Basic Cryomancy',
 'Ice magic - freeze and cool materials', '{"tier": 1, "mana_cost": "low"}'::jsonb);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('cryomancy_basic', 'extreme_cold', '{"magnitude": 1, "unit": "kelvin", "method": "cryomancy"}'::jsonb, 0);

-- Cryogenic Superconductors (Hybrid tech!)
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('cryomancy_superconductor', 'elemental_magic_tree', 'Cryogenic Superconductors',
 'Use ice magic to enable superconducting materials for magnetic systems',
 '{"tier": 3, "mana_cost": "moderate", "note": "Hybrid tech: magic cooling enables better conventional electromagnets"}'::jsonb);

INSERT INTO requirements (technology_id, evaluator, config, requirement_order) VALUES
('cryomancy_superconductor', 'all_of',
 '{
   "requirements": [
     {"evaluator": "simple_match", "config": {"capability_type": "extreme_cold", "method": "cryomancy"}},
     {"evaluator": "simple_match", "config": {"capability_type": "metal_working", "min_sophistication": "basic"}}
   ]
 }'::jsonb, 0);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('cryomancy_superconductor', 'electrical_power', '{"megawatts": 60, "efficiency": "high", "method": "magic_enhanced_superconductor"}'::jsonb, 0);

-- Aether Weaving
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('aether_weaving', 'elemental_magic_tree', 'Aether Weaving',
 'Manipulate the fabric of magical energy itself', '{"tier": 3, "mana_cost": "very_high"}'::jsonb);

INSERT INTO requirements (technology_id, evaluator, config, requirement_order) VALUES
('aether_weaving', 'all_of',
 '{
   "requirements": [
     {"evaluator": "simple_match", "config": {"capability_type": "magical_fire", "min_intensity": "basic"}},
     {"evaluator": "simple_match", "config": {"capability_type": "earth_manipulation", "min_intensity": "basic"}}
   ]
 }'::jsonb, 0);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('aether_weaving', 'aether_field', '{"stability": "moderate"}'::jsonb, 0);

-- Plasma Prison
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('plasma_prison', 'elemental_magic_tree', 'Plasma Prison',
 'Magical containment field for plasma', '{"tier": 4, "mana_cost": "extreme", "note": "Stronger than magnetic containment!"}'::jsonb);

INSERT INTO requirements (technology_id, evaluator, config, requirement_order) VALUES
('plasma_prison', 'simple_match', '{"capability_type": "aether_field", "min_stability": "moderate"}'::jsonb, 0);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('plasma_prison', 'plasma_containment', '{"method": "aetheric", "strength": 15}'::jsonb, 0);

-- Fusion Reactor (Magic Path)
INSERT INTO technologies (id, tree_id, name, description, metadata) VALUES
('fusion_reactor_magic', 'elemental_magic_tree', 'Fusion Reactor (Magic Path)',
 'Controlled fusion using pure elemental magic',
 '{"tier": 5, "mana_cost": "extreme", "note": "Pure magic path to fusion - slightly more powerful than tech!"}'::jsonb);

INSERT INTO requirements (technology_id, evaluator, config, requirement_order) VALUES
('fusion_reactor_magic', 'any_of',
 '{
   "alternatives": [
     {
       "comment": "Path 1: Pyromancy + Aetheric containment",
       "evaluator": "all_of",
       "requirements": [
         {"evaluator": "simple_match", "config": {"capability_type": "extreme_heat", "min_magnitude": 10000000, "method": "pyromancy"}},
         {"evaluator": "simple_match", "config": {"capability_type": "plasma_containment", "method": "aetheric"}}
       ]
     }
   ]
 }'::jsonb, 0);

INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order) VALUES
('fusion_reactor_magic', 'fusion_power', '{"output_megawatts": 1200, "method": "magical"}'::jsonb, 0);

-- ============================================================================
-- SAMPLE QUERIES
-- ============================================================================

-- Query 1: Show all technology trees
SELECT 
    '=== TECHNOLOGY TREES ===' as section;
SELECT id, name, description FROM technology_trees;

-- Query 2: Show all technologies with their trees
SELECT 
    '' as blank_line,
    '=== ALL TECHNOLOGIES ===' as section;
SELECT 
    t.tree_id,
    tt.name as tree_name,
    t.id as tech_id,
    t.name as tech_name,
    t.metadata->>'tier' as tier
FROM technologies t
JOIN technology_trees tt ON t.tree_id = tt.id
ORDER BY t.tree_id, (t.metadata->>'tier')::int NULLS FIRST, t.name;

-- Query 3: Show starting technologies (no requirements)
SELECT 
    '' as blank_line,
    '=== STARTING TECHNOLOGIES (No Prerequisites) ===' as section;
SELECT 
    t.id,
    t.name,
    t.tree_id
FROM technologies t
WHERE NOT EXISTS (
    SELECT 1 FROM requirements r WHERE r.technology_id = t.id
)
ORDER BY t.tree_id, t.name;

-- Query 4: Show all technologies that produce "extreme_heat"
SELECT 
    '' as blank_line,
    '=== TECHNOLOGIES PRODUCING EXTREME_HEAT ===' as section;
SELECT 
    t.id,
    t.name,
    t.tree_id,
    cd.properties->>'magnitude' as magnitude,
    cd.properties->>'method' as method
FROM capability_definitions cd
JOIN technologies t ON cd.technology_id = t.id
WHERE cd.capability_type = 'extreme_heat'
ORDER BY (cd.properties->>'magnitude')::numeric DESC;

-- Query 5: Show all paths to fusion power
SELECT 
    '' as blank_line,
    '=== ALL FUSION REACTOR TECHNOLOGIES ===' as section;
SELECT 
    t.id,
    t.name,
    t.tree_id,
    cd.properties->>'output_megawatts' as megawatts,
    cd.properties->>'method' as method
FROM capability_definitions cd
JOIN technologies t ON cd.technology_id = t.id
WHERE cd.capability_type = 'fusion_power'
ORDER BY (cd.properties->>'output_megawatts')::numeric DESC;

-- Query 6: Show the hybrid tech (cryomancy superconductor) requirements
SELECT 
    '' as blank_line,
    '=== HYBRID TECH EXAMPLE: Cryogenic Superconductors ===' as section;
SELECT 
    t.id,
    t.name,
    t.description,
    r.evaluator,
    r.config
FROM technologies t
JOIN requirements r ON t.technology_id = r.id
WHERE t.id = 'cryomancy_superconductor';

-- Query 7: Show complete view of fusion_reactor_hybrid
SELECT 
    '' as blank_line,
    '=== COMPLETE VIEW: Hybrid Fusion Reactor ===' as section;
SELECT 
    id,
    name,
    tree_name,
    requirements,
    outputs
FROM v_technologies_complete
WHERE id = 'fusion_reactor_hybrid';

-- Query 8: Count technologies by tree and tier
SELECT 
    '' as blank_line,
    '=== TECHNOLOGY COUNT BY TREE AND TIER ===' as section;
SELECT 
    t.tree_id,
    tt.name as tree_name,
    t.metadata->>'tier' as tier,
    COUNT(*) as tech_count
FROM technologies t
JOIN technology_trees tt ON t.tree_id = tt.id
GROUP BY t.tree_id, tt.name, t.metadata->>'tier'
ORDER BY t.tree_id, (t.metadata->>'tier')::int NULLS FIRST;

-- Query 9: Show capability type statistics
SELECT 
    '' as blank_line,
    '=== CAPABILITY TYPES AND THEIR SOURCES ===' as section;
SELECT 
    cd.capability_type,
    COUNT(DISTINCT cd.technology_id) as tech_count,
    string_agg(DISTINCT t.tree_id, ', ') as trees
FROM capability_definitions cd
JOIN technologies t ON cd.technology_id = t.id
GROUP BY cd.capability_type
ORDER BY tech_count DESC, cd.capability_type;

-- Query 10: Demonstration - What if we have pyromancy heat and magnetic containment?
SELECT 
    '' as blank_line,
    '=== SIMULATION: Available Capabilities ===' as section;
SELECT 
    'extreme_heat (pyromancy, 15M K)' as capability_1,
    'plasma_containment (magnetic, strength 10)' as capability_2,
    'These should enable: fusion_reactor_tech AND fusion_reactor_hybrid!' as result;

-- Show which fusion techs would be unlocked
SELECT 
    '' as blank_line,
    '=== TECHNOLOGIES REQUIRING PYROMANCY HEAT ===' as section;
SELECT DISTINCT
    t.id,
    t.name,
    t.tree_id
FROM technologies t
JOIN requirements r ON t.technology_id = r.id
WHERE r.config::text LIKE '%pyromancy%'
ORDER BY t.tree_id, t.name;

-- ============================================================================
-- NOTES ON USING THIS EXAMPLE
-- ============================================================================

/*
This database now contains the complete magic-tech crossover example!

To explore:

1. View all technologies:
   SELECT * FROM v_technologies_complete;

2. Find technologies producing a capability:
   SELECT * FROM capability_definitions WHERE capability_type = 'extreme_heat';

3. See technology requirements:
   SELECT * FROM requirements WHERE technology_id = 'fusion_reactor_hybrid';

4. Simulate queries (application layer):
   - Check which technologies are available given current capabilities
   - Calculate requirement margins
   - Discover new technologies through capability combinations

Remember: The actual requirement evaluation (checking if capabilities satisfy
requirements) happens in the application layer, not in SQL. This database
stores the DEFINITIONS and CONFIGURATION.

Example application-layer logic:
1. Load technologies from active trees
2. For each technology, evaluate its requirements against available capabilities
3. Use the evaluator functions (simple_match, any_of, all_of) to check satisfaction
4. Calculate margins (how much capabilities exceed requirements)
5. Return available technologies and producible capabilities

The magic of this system: pyromancy's "extreme_heat" satisfies the same
requirement as a laser's "extreme_heat" - cross-domain synergy emerges naturally!
*/