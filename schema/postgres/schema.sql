-- Composable Tech Tree Engine - PostgreSQL Schema
-- Version 1.0.0
--
-- This schema implements the abstract data model for capability-based technology trees.
-- It uses JSONB for flexible metadata and configuration storage.

-- Enable UUID extension for generating IDs (optional, can use string IDs instead)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- CORE TABLES
-- ============================================================================

-- Technology Trees: Collections of related technologies
CREATE TABLE technology_trees (
    id VARCHAR(255) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Index for searching trees by metadata properties
CREATE INDEX idx_trees_metadata ON technology_trees USING GIN (metadata);

COMMENT ON TABLE technology_trees IS 'Collections of related technologies, typically organized by theme or domain';
COMMENT ON COLUMN technology_trees.metadata IS 'Application-specific metadata (theme, era, tags, etc.)';

-- Technologies: Processes that transform capabilities
CREATE TABLE technologies (
    id VARCHAR(255) PRIMARY KEY,
    tree_id VARCHAR(255) NOT NULL REFERENCES technology_trees(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for efficient queries
CREATE INDEX idx_technologies_tree_id ON technologies(tree_id);
CREATE INDEX idx_technologies_name ON technologies(name);
CREATE INDEX idx_technologies_metadata ON technologies USING GIN (metadata);

COMMENT ON TABLE technologies IS 'Processes or knowledge that transform input capabilities into output capabilities';
COMMENT ON COLUMN technologies.metadata IS 'Application-specific data (cost, research_time, flavor_text, etc.)';

-- Requirements: Conditions that must be satisfied for a technology
CREATE TABLE requirements (
    id SERIAL PRIMARY KEY,
    technology_id VARCHAR(255) NOT NULL REFERENCES technologies(id) ON DELETE CASCADE,
    evaluator VARCHAR(255) NOT NULL,
    config JSONB NOT NULL DEFAULT '{}',
    requirement_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for efficient requirement lookups
CREATE INDEX idx_requirements_technology_id ON requirements(technology_id);
CREATE INDEX idx_requirements_evaluator ON requirements(evaluator);
CREATE INDEX idx_requirements_config ON requirements USING GIN (config);

COMMENT ON TABLE requirements IS 'Conditions that must be satisfied for a technology to be available';
COMMENT ON COLUMN requirements.evaluator IS 'Name/identifier of the evaluator function (e.g., simple_match, formula, any_of)';
COMMENT ON COLUMN requirements.config IS 'Evaluator-specific configuration (contents depend on evaluator)';
COMMENT ON COLUMN requirements.requirement_order IS 'Order for display purposes (not evaluation order)';

-- Capability Definitions: Templates for what technologies produce
CREATE TABLE capability_definitions (
    id SERIAL PRIMARY KEY,
    technology_id VARCHAR(255) NOT NULL REFERENCES technologies(id) ON DELETE CASCADE,
    capability_type VARCHAR(255) NOT NULL,
    properties JSONB NOT NULL DEFAULT '{}',
    output_order INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for efficient capability lookups
CREATE INDEX idx_capability_defs_technology_id ON capability_definitions(technology_id);
CREATE INDEX idx_capability_defs_type ON capability_definitions(capability_type);
CREATE INDEX idx_capability_defs_properties ON capability_definitions USING GIN (properties);

COMMENT ON TABLE capability_definitions IS 'Templates defining capabilities that technologies produce';
COMMENT ON COLUMN capability_definitions.capability_type IS 'Type identifier for this capability (e.g., thermal_energy, magnetic_field)';
COMMENT ON COLUMN capability_definitions.properties IS 'Properties of this capability (can include formulas based on inputs)';
COMMENT ON COLUMN capability_definitions.output_order IS 'Order for display purposes';

-- ============================================================================
-- HELPER VIEWS
-- ============================================================================

-- Complete technology view with all requirements and outputs
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

COMMENT ON VIEW v_technologies_complete IS 'Complete view of technologies with all requirements and capability outputs';

-- Technology trees with technology counts
CREATE VIEW v_trees_summary AS
SELECT 
    tt.id,
    tt.name,
    tt.description,
    tt.metadata,
    COUNT(t.id) as technology_count,
    tt.created_at,
    tt.updated_at
FROM technology_trees tt
LEFT JOIN technologies t ON tt.id = t.tree_id
GROUP BY tt.id, tt.name, tt.description, tt.metadata, tt.created_at, tt.updated_at;

COMMENT ON VIEW v_trees_summary IS 'Technology trees with counts of technologies';

-- Capability type usage statistics
CREATE VIEW v_capability_types AS
SELECT 
    cd.capability_type,
    COUNT(DISTINCT cd.technology_id) as producing_tech_count,
    json_agg(DISTINCT t.tree_id) as trees,
    json_agg(DISTINCT t.name) as technology_names
FROM capability_definitions cd
JOIN technologies t ON cd.technology_id = t.id
GROUP BY cd.capability_type
ORDER BY producing_tech_count DESC;

COMMENT ON VIEW v_capability_types IS 'Statistics on capability types and which technologies produce them';

-- ============================================================================
-- QUERY HELPER FUNCTIONS
-- ============================================================================

-- Function to get all technologies from specific trees
CREATE OR REPLACE FUNCTION get_technologies_by_trees(tree_ids VARCHAR[])
RETURNS TABLE (
    technology_id VARCHAR,
    technology_name VARCHAR,
    tree_id VARCHAR,
    tree_name VARCHAR,
    requirements JSONB,
    outputs JSONB,
    metadata JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.name,
        t.tree_id,
        tt.name,
        to_jsonb(
            (SELECT array_agg(
                json_build_object(
                    'evaluator', r.evaluator,
                    'config', r.config
                ) ORDER BY r.requirement_order
            )
            FROM requirements r
            WHERE r.technology_id = t.id)
        ),
        to_jsonb(
            (SELECT array_agg(
                json_build_object(
                    'capability_type', cd.capability_type,
                    'properties', cd.properties
                ) ORDER BY cd.output_order
            )
            FROM capability_definitions cd
            WHERE cd.technology_id = t.id)
        ),
        t.metadata
    FROM technologies t
    JOIN technology_trees tt ON t.tree_id = tt.id
    WHERE t.tree_id = ANY(tree_ids);
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_technologies_by_trees IS 'Get all technologies from specified technology trees';

-- Function to get technologies that produce a specific capability type
CREATE OR REPLACE FUNCTION get_technologies_producing_capability(
    cap_type VARCHAR,
    active_tree_ids VARCHAR[] DEFAULT NULL
)
RETURNS TABLE (
    technology_id VARCHAR,
    technology_name VARCHAR,
    tree_id VARCHAR,
    capability_properties JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.name,
        t.tree_id,
        cd.properties
    FROM capability_definitions cd
    JOIN technologies t ON cd.technology_id = t.id
    WHERE cd.capability_type = cap_type
    AND (active_tree_ids IS NULL OR t.tree_id = ANY(active_tree_ids));
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_technologies_producing_capability IS 'Find technologies that produce a specific capability type';

-- Function to get all capability types required by a technology
CREATE OR REPLACE FUNCTION get_required_capability_types(tech_id VARCHAR)
RETURNS TABLE (
    capability_type VARCHAR,
    evaluator VARCHAR,
    config JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (config->>'capability_type')::VARCHAR,
        r.evaluator,
        r.config
    FROM requirements r
    WHERE r.technology_id = tech_id
    AND r.config ? 'capability_type';  -- Only requirements that specify a capability_type
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_required_capability_types IS 'Extract capability types required by a technology';

-- ============================================================================
-- VALIDATION FUNCTIONS
-- ============================================================================

-- Function to validate that a technology tree is well-formed
CREATE OR REPLACE FUNCTION validate_technology_tree(tree_id_param VARCHAR)
RETURNS TABLE (
    is_valid BOOLEAN,
    errors JSONB
) AS $$
DECLARE
    error_list JSONB := '[]'::JSONB;
    tech_count INTEGER;
    orphaned_count INTEGER;
BEGIN
    -- Check if tree exists
    IF NOT EXISTS (SELECT 1 FROM technology_trees WHERE id = tree_id_param) THEN
        error_list := error_list || jsonb_build_object('error', 'Tree does not exist');
        RETURN QUERY SELECT FALSE, error_list;
        RETURN;
    END IF;
    
    -- Check for technologies without requirements or outputs
    SELECT COUNT(*) INTO orphaned_count
    FROM technologies t
    WHERE t.tree_id = tree_id_param
    AND NOT EXISTS (SELECT 1 FROM requirements r WHERE r.technology_id = t.id)
    AND NOT EXISTS (SELECT 1 FROM capability_definitions cd WHERE cd.technology_id = t.id);
    
    IF orphaned_count > 0 THEN
        error_list := error_list || jsonb_build_object(
            'warning', 
            format('%s technologies have no requirements or outputs', orphaned_count)
        );
    END IF;
    
    -- Check for requirements without config
    IF EXISTS (
        SELECT 1 FROM requirements r
        JOIN technologies t ON r.technology_id = t.id
        WHERE t.tree_id = tree_id_param
        AND r.config = '{}'::JSONB
    ) THEN
        error_list := error_list || jsonb_build_object(
            'error',
            'Some requirements have empty config'
        );
    END IF;
    
    -- Return result
    IF jsonb_array_length(error_list) = 0 THEN
        RETURN QUERY SELECT TRUE, '[]'::JSONB;
    ELSE
        RETURN QUERY SELECT FALSE, error_list;
    END IF;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION validate_technology_tree IS 'Validate that a technology tree is well-formed';

-- ============================================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updating timestamps
CREATE TRIGGER update_technology_trees_updated_at
    BEFORE UPDATE ON technology_trees
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_technologies_updated_at
    BEFORE UPDATE ON technologies
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SAMPLE QUERIES (Commented Examples)
-- ============================================================================

/*
-- Example 1: Get all technologies from physics and magic trees
SELECT * FROM get_technologies_by_trees(ARRAY['physics_tree', 'elemental_magic_tree']);

-- Example 2: Find all technologies that produce "extreme_heat"
SELECT * FROM get_technologies_producing_capability('extreme_heat');

-- Example 3: Get complete technology with all details
SELECT * FROM v_technologies_complete WHERE id = 'fusion_reactor_tech';

-- Example 4: Find all technologies in a tree with their requirements
SELECT 
    t.id,
    t.name,
    json_agg(
        json_build_object(
            'evaluator', r.evaluator,
            'config', r.config
        )
    ) as requirements
FROM technologies t
LEFT JOIN requirements r ON t.technology_id = r.technology_id
WHERE t.tree_id = 'physics_tree'
GROUP BY t.id, t.name;

-- Example 5: Validate a technology tree
SELECT * FROM validate_technology_tree('physics_tree');

-- Example 6: Get capability type usage statistics
SELECT * FROM v_capability_types;

-- Example 7: Find technologies with no prerequisites (starting techs)
SELECT t.id, t.name, t.tree_id
FROM technologies t
WHERE NOT EXISTS (
    SELECT 1 FROM requirements r WHERE r.technology_id = t.id
);

-- Example 8: Complex query - find all tech paths to a capability
WITH RECURSIVE capability_chain AS (
    -- Base case: technologies that directly produce the capability
    SELECT 
        t.id as tech_id,
        t.name as tech_name,
        1 as depth,
        ARRAY[t.id] as path
    FROM technologies t
    JOIN capability_definitions cd ON t.id = cd.technology_id
    WHERE cd.capability_type = 'fusion_power'
    
    UNION ALL
    
    -- Recursive case: technologies that produce capabilities needed by previous techs
    SELECT 
        t.id,
        t.name,
        cc.depth + 1,
        cc.path || t.id
    FROM capability_chain cc
    JOIN requirements r ON r.technology_id = cc.tech_id
    JOIN capability_definitions cd ON cd.capability_type = (r.config->>'capability_type')
    JOIN technologies t ON t.id = cd.technology_id
    WHERE NOT t.id = ANY(cc.path)  -- Prevent cycles
    AND cc.depth < 10  -- Prevent infinite recursion
)
SELECT DISTINCT tech_id, tech_name, depth, path
FROM capability_chain
ORDER BY depth, tech_name;
*/

-- ============================================================================
-- INDEXES FOR COMMON QUERY PATTERNS
-- ============================================================================

-- Index for finding technologies by capability they require
CREATE INDEX idx_requirements_capability_type ON requirements ((config->>'capability_type'));

-- Index for finding technologies by their output capability properties
CREATE INDEX idx_capability_defs_by_property_keys ON capability_definitions 
    USING GIN ((properties -> 'magnitude'));

-- Composite index for tree + technology queries
CREATE INDEX idx_technologies_tree_name ON technologies(tree_id, name);

-- ============================================================================
-- UTILITY FUNCTIONS FOR DATA MANAGEMENT
-- ============================================================================

-- Function to bulk insert a technology with requirements and outputs
CREATE OR REPLACE FUNCTION insert_technology_complete(
    tech_id VARCHAR,
    tech_tree_id VARCHAR,
    tech_name VARCHAR,
    tech_description TEXT,
    tech_metadata JSONB,
    tech_requirements JSONB,  -- Array of {evaluator, config}
    tech_outputs JSONB        -- Array of {capability_type, properties}
)
RETURNS VARCHAR AS $$
DECLARE
    req JSONB;
    out JSONB;
    req_order INTEGER := 0;
    out_order INTEGER := 0;
BEGIN
    -- Insert technology
    INSERT INTO technologies (id, tree_id, name, description, metadata)
    VALUES (tech_id, tech_tree_id, tech_name, tech_description, tech_metadata);
    
    -- Insert requirements
    IF tech_requirements IS NOT NULL THEN
        FOR req IN SELECT * FROM jsonb_array_elements(tech_requirements)
        LOOP
            INSERT INTO requirements (technology_id, evaluator, config, requirement_order)
            VALUES (
                tech_id,
                req->>'evaluator',
                req->'config',
                req_order
            );
            req_order := req_order + 1;
        END LOOP;
    END IF;
    
    -- Insert outputs
    IF tech_outputs IS NOT NULL THEN
        FOR out IN SELECT * FROM jsonb_array_elements(tech_outputs)
        LOOP
            INSERT INTO capability_definitions (technology_id, capability_type, properties, output_order)
            VALUES (
                tech_id,
                out->>'capability_type',
                out->'properties',
                out_order
            );
            out_order := out_order + 1;
        END LOOP;
    END IF;
    
    RETURN tech_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION insert_technology_complete IS 'Bulk insert a technology with all its requirements and outputs in a single call';

-- ============================================================================
-- MATERIALIZED VIEW FOR PERFORMANCE (Optional)
-- ============================================================================

-- Materialized view for faster access to complete technology data
-- Useful if you're doing many reads and few writes
CREATE MATERIALIZED VIEW mv_technologies_complete AS
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
                'evaluator', r.evaluator,
                'config', r.config
            ) ORDER BY r.requirement_order
        )
        FROM requirements r
        WHERE r.technology_id = t.id
    ) as requirements,
    (
        SELECT json_agg(
            json_build_object(
                'capability_type', cd.capability_type,
                'properties', cd.properties
            ) ORDER BY cd.output_order
        )
        FROM capability_definitions cd
        WHERE cd.technology_id = t.id
    ) as outputs,
    t.created_at,
    t.updated_at
FROM technologies t
JOIN technology_trees tt ON t.tree_id = tt.id;

-- Index on materialized view
CREATE INDEX idx_mv_technologies_complete_id ON mv_technologies_complete(id);
CREATE INDEX idx_mv_technologies_complete_tree_id ON mv_technologies_complete(tree_id);

-- Function to refresh materialized view
CREATE OR REPLACE FUNCTION refresh_technologies_cache()
RETURNS VOID AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY mv_technologies_complete;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION refresh_technologies_cache IS 'Refresh the materialized view of complete technology data';

-- ============================================================================
-- NOTES ON USAGE
-- ============================================================================

/*
IMPORTANT NOTES:

1. Capability Instances (Runtime State):
   - NOT stored in this database schema
   - Passed as parameters to application-layer queries
   - The schema stores DEFINITIONS, not INSTANCES

2. Requirement Evaluation:
   - Happens in application layer, not in database
   - Database stores evaluator names and configs
   - Application implements evaluator functions

3. Query Performance:
   - For heavy read workloads, use mv_technologies_complete
   - Remember to refresh materialized view after updates
   - GIN indexes on JSONB fields enable efficient property searches

4. Scaling Considerations:
   - If tech trees grow very large (1000+ technologies), consider partitioning by tree_id
   - Capability type lookups benefit from the specialized indexes
   - Complex recursive queries may need optimization for production use

5. Extension Points:
   - Add columns to technologies/trees for game-specific data
   - Use metadata JSONB fields for flexible extensions
   - Create additional views for application-specific query patterns
*/