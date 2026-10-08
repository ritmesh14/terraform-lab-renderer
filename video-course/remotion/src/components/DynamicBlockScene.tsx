import React from 'react';
import {TransformEngine} from './transform/TransformEngine';

/*
 * DYNAMIC_BLOCK — how a `dynamic "<label>" { for_each = ... content { ... } }`
 * block stamps out repeated NESTED blocks inside ONE resource: the source
 * collection -> the single resource block -> one generated <label> block per
 * element (addressed by each.key, rendered via each.value). The stages/items
 * data comes from the scenes.json entry (schema-validated by
 * validate_scene_schema.py); rendering is shared TransformEngine.
 */
export const DynamicBlockScene: React.FC<Record<string, unknown>> = (props) => (
  <TransformEngine {...(props as any)} />
);