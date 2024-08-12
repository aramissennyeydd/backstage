/*
 * Copyright 2023 The Backstage Authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import React from 'react';

import { Table, TableProps } from '@backstage/core-components';
import { CatalogTableRow } from './types';
import { CatalogTableToolbar } from './CatalogTableToolbar';
import {
  EntityOrderFieldsFilter,
  useEntityList,
} from '@backstage/plugin-catalog-react';

type PaginatedCatalogTableProps = {
  prev?(): void;
  next?(): void;
} & TableProps<CatalogTableRow>;

/**
 * @internal
 */
export function PaginatedCatalogTable(props: PaginatedCatalogTableProps) {
  const { columns, data, next, prev, title, isLoading, options, ...restProps } =
    props;
  const { updateFilters } = useEntityList();

  const updatedColumns = columns.map(column => {
    return {
      ...column,
      // Disable client side sorting (only those in the current page) because it causes a double render.
      customSort: () => 0,
    };
  });

  return (
    <Table
      onOrderChange={(orderBy: number, orderDirection: string | undefined) => {
        // Reset order if no column is selected
        if (orderBy === -1) {
          updateFilters({
            orderFields: undefined,
          });
        } else {
          const field = columns[orderBy].field!;
          const order = orderDirection === 'asc' ? 'asc' : 'desc';
          if (field.startsWith('resolved.')) {
            // Resolved field that cannot be server-side ordered. Do nothing.
          } else if (field.startsWith('entity.')) {
            updateFilters({
              orderFields: new EntityOrderFieldsFilter([
                { field: field.replace('entity.', ''), order },
              ]),
            });
          }
        }
      }}
      title={isLoading ? '' : title}
      columns={updatedColumns}
      data={data}
      options={{
        ...options,
        // These settings are configured to force server side pagination
        paginationPosition: 'both',
        pageSizeOptions: [],
        showFirstLastPageButtons: false,
        pageSize: Number.MAX_SAFE_INTEGER,
        emptyRowsWhenPaging: false,
      }}
      onPageChange={page => {
        if (page > 0) {
          next?.();
        } else {
          prev?.();
        }
      }}
      components={{
        Toolbar: CatalogTableToolbar,
      }}
      /* this will enable the prev button accordingly */
      page={prev ? 1 : 0}
      /* this will enable the next button accordingly */
      totalCount={next ? Number.MAX_VALUE : Number.MAX_SAFE_INTEGER}
      localization={{ pagination: { labelDisplayedRows: '' } }}
      {...restProps}
    />
  );
}
