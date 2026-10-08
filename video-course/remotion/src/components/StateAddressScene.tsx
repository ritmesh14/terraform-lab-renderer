import React from 'react';
import {TransformEngine} from './transform/TransformEngine';

/*
 * STATE_ADDRESS — how Terraform addresses (and viewers read) the instances a
 * transformation created: resource address -> splat / index expressions ->
 * the resulting collected values (e.g. azurerm_storage_container.data[*].name
 * -> ["data-0", "data-1", "data-2"]). Schema-driven via TransformEngine.
 */
export const StateAddressScene: React.FC<Record<string, unknown>> = (props) => (
  <TransformEngine {...(props as any)} />
);