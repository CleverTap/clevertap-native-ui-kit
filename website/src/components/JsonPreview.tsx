import React, {useEffect, useState} from 'react';
import CodeBlock from '@theme/CodeBlock';

interface JsonPreviewProps {
  src: string;
  title?: string;
  collapsed?: boolean;
}

// Static JSON viewer for v1.0.0. Future versions may render the JSON as an
// actual SDK preview; for now this loads the raw JSON over HTTP and renders
// it inside a Docusaurus <CodeBlock> with copy-to-clipboard.
export default function JsonPreview({src, title, collapsed = false}: JsonPreviewProps) {
  const [content, setContent] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [open, setOpen] = useState(!collapsed);

  useEffect(() => {
    fetch(src)
      .then((r) => (r.ok ? r.text() : Promise.reject(`HTTP ${r.status}`)))
      .then((text) => {
        try {
          setContent(JSON.stringify(JSON.parse(text), null, 2));
        } catch {
          setContent(text);
        }
      })
      .catch((e) => setError(String(e)));
  }, [src]);

  return (
    <details open={open} onToggle={(e) => setOpen((e.target as HTMLDetailsElement).open)}>
      <summary>{title ?? src.split('/').pop()}</summary>
      {error && <p style={{color: 'var(--ifm-color-danger)'}}>Failed to load: {error}</p>}
      {content && <CodeBlock language="json">{content}</CodeBlock>}
      {!content && !error && <p>Loading…</p>}
    </details>
  );
}
