import MDXComponents from '@theme-original/MDXComponents';
import PlatformTabs, {TabItem as PlatformTabItem} from '@site/src/components/PlatformTabs';
import ApiLink from '@site/src/components/ApiLink';
import JsonPreview from '@site/src/components/JsonPreview';

// Globally inject our SDK-docs MDX components so authors can use
// <PlatformTabs>, <ApiLink>, <JsonPreview> in any .md/.mdx without imports.
export default {
  ...MDXComponents,
  PlatformTabs,
  PlatformTabItem,
  ApiLink,
  JsonPreview,
};
