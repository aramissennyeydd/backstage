/*
 * Copyright 2022 The Backstage Authors
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
import {
  Page,
  Content,
  MissingAnnotationEmptyState,
} from '@backstage/core-components';
import { useEntity } from '@backstage/plugin-catalog-react';
import { isPuppetDbAvailable } from '../../plugin';
import { ANNOTATION_PUPPET_CERTNAME } from '../../constants';
import { ReportsTable } from '../Reports/ReportsTable/ReportsTable';
import { NodeCard } from '../Node';

export const PuppetDbTab = () => {
  const { entity } = useEntity();

  if (!isPuppetDbAvailable(entity)) {
    return (
      <MissingAnnotationEmptyState annotation={ANNOTATION_PUPPET_CERTNAME} />
    );
  }

  // @ts-ignore
  // TODO(tdabasinskas): Remove the static value after the testing.
  const certName = entity.metadata.annotations[ANNOTATION_PUPPET_CERTNAME];

  return (
    <Page themeId="tool">
      <Content>
        <ReportsTable certName={certName} />
      </Content>
    </Page>
  );
};
