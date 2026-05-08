import React from 'react';
import {useDocsVersion} from '@docusaurus/plugin-content-docs/client';
import useBaseUrl from '@docusaurus/useBaseUrl';

interface ApiLinkProps {
  platform: 'android' | 'ios';
  path: string;
  children?: React.ReactNode;
}

// Deep-links into the version-pinned API reference at
// /api/<platform>/<version>/<path>. The version is read from the active
// Docusaurus docs version so links from versioned docs always resolve into
// the matching Dokka/DocC snapshot.
export default function ApiLink({platform, path, children}: ApiLinkProps) {
  let version = '1.0.0';
  try {
    version = useDocsVersion().version;
    if (version === 'current') version = 'next';
  } catch {
    // Outside docs context — fall back to 1.0.0.
  }
  const href = useBaseUrl(`/api/${platform}/${version}/${path}`);
  return (
    <a href={href} target="_blank" rel="noopener noreferrer">
      {children ?? path}
    </a>
  );
}
