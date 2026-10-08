import React from 'react';
import {TransformEngine} from './transform/TransformEngine';

/*
 * FOR_EACH_MAP — how `for_each = <set|map>` turns ONE resource block into
 * one instance per collection key: the collection (toset(...) or { k = v })
 * -> the single block -> state addresses addressed by KEY (`stage["dev"]`,
 * never a positional index) -> the resulting real names. The stages/items
 * data comes from the scenes.json entry (schema-validated by
 * validate_scene_schema.py); rendering is shared TransformEngine.
 */
export const ForEachMapScene: React.FC<Record<string, unknown>> = (props) => (
  <TransformEngine {...(props as any)} />
);