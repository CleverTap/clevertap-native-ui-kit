# Native Display System - Type Models

Complete type definitions for Claude Code to understand the system structure.

---

## Kotlin Data Models

```kotlin
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

/**
 * Root configuration object sent from server to mobile client
 */
@Serializable
data class NativeDisplayConfig(
    val version: String = "1.0",
    val theme: Theme? = null,
    val styleClasses: List<StyleClass> = emptyList(),
    val variables: Map<String, JsonElement> = emptyMap(),
    val root: NativeDisplayNode? = null
)

// ============ THEME SYSTEM ============

@Serializable
data class Theme(
    val id: String,
    val defaultStyle: Style? = null,
    val colors: Map<String, String> = emptyMap(),
    val typography: Map<String, Style> = emptyMap(),
    val spacing: Map<String, Int> = emptyMap(),
    val cornerRadius: Map<String, Int> = emptyMap(),
    val shadows: Map<String, Shadow> = emptyMap()
)

@Serializable
data class StyleClass(
    val name: String,
    val style: Style
)

// ============ STYLE SYSTEM ============

@Serializable
data class Style(
    // Text properties (inherit to children)
    val textColor: String? = null,
    val fontSize: Int? = null,
    val fontWeight: String? = null,
    val textAlign: String? = null,
    val lineHeight: Int? = null,
    val letterSpacing: Int? = null,
    val textDecoration: String? = null,
    
    // Background properties (do NOT inherit)
    val backgroundColor: String? = null,
    val backgroundGradient: Gradient? = null,
    
    // Border properties (do NOT inherit)
    val borderRadius: Int? = null,
    val borderWidth: Int? = null,
    val borderColor: String? = null,
    
    // Shadow properties (do NOT inherit)
    val shadowColor: String? = null,
    val shadowRadius: Int? = null,
    val shadowOffset: Offset? = null,
    
    // Transform properties
    val opacity: Float? = null,
    val scaleX: Float? = null,
    val scaleY: Float? = null,
    val rotationZ: Int? = null
)

@Serializable
data class Gradient(
    val type: String,
    val colors: List<String> = emptyList(),
    val angle: Int? = null,
    val centerX: Float? = null,
    val centerY: Float? = null,
    val radius: Float? = null
)

@Serializable
data class Offset(val x: Int = 0, val y: Int = 0)

@Serializable
data class Shadow(val color: String, val radius: Int, val offset: Offset)

// ============ LAYOUT SYSTEM ============

@Serializable
data class Layout(
    val width: Dimension? = null,
    val height: Dimension? = null,
    val minWidth: Dimension? = null,
    val maxWidth: Dimension? = null,
    val minHeight: Dimension? = null,
    val maxHeight: Dimension? = null,
    val padding: Spacing? = null,
    val margin: Spacing? = null,
    val aspectRatio: Float? = null
)

@Serializable
data class Dimension(
    val value: Float,
    val unit: String  // dp, percent, px, wrap, fill
)

@Serializable
data class Spacing(
    val value: Int? = null,
    val unit: String? = null,
    val all: Int? = null,
    val horizontal: Int? = null,
    val vertical: Int? = null,
    val top: Int? = null,
    val bottom: Int? = null,
    val left: Int? = null,
    val right: Int? = null,
    val start: Int? = null,
    val end: Int? = null
)

// ============ DISPLAY NODES ============

@Serializable
sealed class NativeDisplayNode {
    abstract val id: String
    abstract val layout: Layout?
    abstract val style: Style?
    abstract val styleClass: String?
    abstract val visible: String?
    abstract val animation: Animation?
}

@Serializable
data class NativeDisplayContainer(
    override val id: String,
    val containerType: String,
    val children: List<NativeDisplayNode> = emptyList(),
    val spacing: Spacing? = null,
    val alignment: String? = null,
    val galleryConfig: GalleryConfig? = null,
    val dividerConfig: DividerConfig? = null,
    override val layout: Layout? = null,
    override val style: Style? = null,
    override val styleClass: String? = null,
    override val visible: String? = null,
    override val animation: Animation? = null,
    val background: Background? = null
) : NativeDisplayNode()

@Serializable
data class NativeDisplayElement(
    override val id: String,
    val elementType: String,
    val bindings: Map<String, String> = emptyMap(),
    val config: Map<String, String> = emptyMap(),
    val actions: Map<String, Action> = emptyMap(),
    override val layout: Layout? = null,
    override val style: Style? = null,
    override val styleClass: String? = null,
    override val visible: String? = null,
    override val animation: Animation? = null,
    val background: Background? = null
) : NativeDisplayNode()

// ============ ACTIONS ============

@Serializable
data class Action(
    val type: String,
    val url: String? = null,
    val target: String? = null,
    val params: Map<String, String>? = null
)

// ============ GALLERY ============

@Serializable
data class GalleryConfig(
    val mode: String? = null,
    val orientation: String? = null,
    val itemsPerView: Float? = null,
    val spacing: Spacing? = null,
    val autoScroll: Boolean? = null,
    val autoScrollInterval: Int? = null,
    val pageIndicator: Boolean? = null,
    val infiniteScroll: Boolean? = null
)

@Serializable
data class DividerConfig(
    val enabled: Boolean? = null,
    val color: String? = null,
    val thickness: Int? = null,
    val startPadding: Int? = null,
    val endPadding: Int? = null
)

// ============ BACKGROUND ============

@Serializable
data class Background(
    val type: String,
    val color: String? = null,
    val colors: List<String>? = null,
    val cellSize: Int? = null,
    val dotSize: Int? = null,
    val amplitude: Int? = null,
    val animation: BackgroundAnimation? = null
)

@Serializable
data class BackgroundAnimation(
    val type: String,
    val duration: Int? = null,
    val minOpacity: Float? = null,
    val maxOpacity: Float? = null,
    val particleCount: Int? = null,
    val speed: Float? = null,
    val angle: Int? = null
)

// ============ ANIMATIONS ============

@Serializable
data class Animation(
    val type: String,
    val duration: Int? = null,
    val delay: Int? = null,
    val curve: String? = null
)
```

---

## Swift Type Models

```swift
import Foundation

struct NativeDisplayConfig: Codable {
    let version: String
    let theme: Theme?
    let styleClasses: [StyleClass]?
    let variables: [String: AnyCodable]?
    let root: NativeDisplayNode?
}

struct Theme: Codable {
    let id: String
    let defaultStyle: Style?
    let colors: [String: String]?
}

struct StyleClass: Codable {
    let name: String
    let style: Style
}

struct Style: Codable {
    let textColor: String?
    let fontSize: Int?
    let fontWeight: String?
    let textAlign: String?
    let backgroundColor: String?
    let borderRadius: Int?
    let borderWidth: Int?
    let borderColor: String?
    let shadowColor: String?
    let shadowRadius: Int?
    let opacity: Float?
}

struct Layout: Codable {
    let width: Dimension?
    let height: Dimension?
    let padding: Spacing?
    let margin: Spacing?
}

struct Dimension: Codable {
    let value: Float
    let unit: String
}

struct Spacing: Codable {
    let all: Int?
    let horizontal: Int?
    let vertical: Int?
    let top: Int?
    let bottom: Int?
    let left: Int?
    let right: Int?
}

enum NativeDisplayNode: Codable {
    case container(NativeDisplayContainer)
    case element(NativeDisplayElement)
}

struct NativeDisplayContainer: Codable {
    let id: String
    let containerType: String
    let children: [NativeDisplayNode]?
    let spacing: Spacing?
    let alignment: String?
    let galleryConfig: GalleryConfig?
    let layout: Layout?
    let style: Style?
    let styleClass: String?
    let visible: String?
}

struct NativeDisplayElement: Codable {
    let id: String
    let elementType: String
    let bindings: [String: String]?
    let actions: [String: Action]?
    let layout: Layout?
    let style: Style?
    let styleClass: String?
    let visible: String?
}

struct Action: Codable {
    let type: String
    let url: String?
    let target: String?
    let params: [String: String]?
}

struct GalleryConfig: Codable {
    let mode: String?
    let orientation: String?
    let itemsPerView: Float?
    let spacing: Spacing?
    let autoScroll: Bool?
    let pageIndicator: Bool?
}
```

---

## TypeScript Interfaces

```typescript
interface NativeDisplayConfig {
  version: string;
  theme?: Theme;
  styleClasses?: StyleClass[];
  variables?: Record<string, any>;
  root?: NativeDisplayNode;
}

interface Theme {
  id: string;
  defaultStyle?: Style;
  colors?: Record<string, string>;
}

interface StyleClass {
  name: string;
  style: Style;
}

interface Style {
  textColor?: string;
  fontSize?: number;
  fontWeight?: string;
  textAlign?: string;
  backgroundColor?: string;
  borderRadius?: number;
  borderWidth?: number;
  borderColor?: string;
  shadowColor?: string;
  shadowRadius?: number;
  opacity?: number;
}

interface Layout {
  width?: Dimension;
  height?: Dimension;
  padding?: Spacing;
  margin?: Spacing;
}

interface Dimension {
  value: number;
  unit: 'dp' | 'percent' | 'px' | 'wrap' | 'fill';
}

interface Spacing {
  all?: number;
  horizontal?: number;
  vertical?: number;
  top?: number;
  bottom?: number;
  left?: number;
  right?: number;
}

type NativeDisplayNode = NativeDisplayContainer | NativeDisplayElement;

interface NativeDisplayContainer {
  id: string;
  containerType: 'vertical' | 'horizontal' | 'box' | 'gallery';
  children?: NativeDisplayNode[];
  spacing?: Spacing;
  alignment?: string;
  galleryConfig?: GalleryConfig;
  layout?: Layout;
  style?: Style;
  styleClass?: string;
  visible?: string;
}

interface NativeDisplayElement {
  id: string;
  elementType: 'text' | 'image' | 'button' | 'spacer' | 'video' | 'divider';
  bindings?: Record<string, string>;
  actions?: Record<string, Action>;
  layout?: Layout;
  style?: Style;
  styleClass?: string;
  visible?: string;
}

interface Action {
  type: 'deeplink' | 'custom' | 'dismiss' | 'log';
  url?: string;
  target?: string;
  params?: Record<string, string>;
}

interface GalleryConfig {
  mode?: 'snapping' | 'freeFlow' | 'freeFlowGrid';
  orientation?: 'horizontal' | 'vertical';
  itemsPerView?: number;
  spacing?: Spacing;
  autoScroll?: boolean;
  pageIndicator?: boolean;
}
```

---

**Version**: 1.0  
**Status**: Complete Type Definitions  
**For**: Claude Code Integration
