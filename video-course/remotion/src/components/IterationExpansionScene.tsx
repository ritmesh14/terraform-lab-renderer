import React from 'react';
import {TransformEngine} from './transform/TransformEngine';

/*
 * ITERATION_EXPANSION — how `count = N` turns ONE resource block into N
 * instances: expression (count = 3) -> per-instance count.index values ->
 * state addresses data[0..2] -> the resulting real names. The stages/items
 * data comes from the scenes.json entry (schema-validated by
 * validate_scene_schema.py); rendering is shared TransformEngine.
 */
export const IterationExpansionScene: React.FC<Record<string, unknown>> = (props) => (
  <TransformEngine {...(props as any)} />
);