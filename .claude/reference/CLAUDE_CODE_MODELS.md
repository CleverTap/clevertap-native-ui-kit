# Native Display System - Type Models

Complete type definitions for Claude Code to understand the system structure.

---

## 🛡️ Default Values for Backward Compatibility

**IMPORTANT:** All layout-related types (`Dimension`, `Offset`, `Spacing`, `ChildArrangement`) have default values to ensure robust JSON parsing. This means backend can omit fields without causing parsing failures.

### Default Values Summary

| Type | Property | Default |
|------|----------|---------|
| **Dimension** | `value` | `0` |
| | `unit` | `DP` |
| | `special` | `null` |
| **Offset** | `x` | `0` |
| | `y` | `0` |
| | `unit` | `DP` |
| **Spacing** | `all/horizontal/vertical/top/bottom/left/right` | `null` |
| | `unit` | `DP` |
| **ChildArrangement** | `spacing` | `null` |
| | `spacingUnit` | `DP` |
| | `strategy` | `SPACED` |

### Implementation Strategy

**Android (Kotlin):**
- Uses `@Serializable` data classes with default parameter values
- Example: `val value: Float = 0f`

**iOS (Swift):**
- Uses custom `init(from decoder:)` with `decodeIfPresent` + `??` fallbacks
- Example: `try container.decodeIfPresent(CGFloat.self, forKey: .value) ?? 0`

Both approaches ensure that missing JSON fields don't break parsing, maintaining backward compatibility with backend configurations that may not include all optional fields.

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

@Serializable(with = TextDimensionSerializer::class)
data class TextDimension(
    val value: Float,
    val unit: TextDimensionUnit = TextDimensionUnit.PLATFORM  // PLATFORM or PERCENT
) {
    fun resolve(rootHeightPx: Float): Float = when (unit) {
        TextDimensionUnit.PLATFORM -> value
        TextDimensionUnit.PERCENT -> rootHeightPx * value / 1000f
    }
}
// JSON: number → TextDimension(value, PLATFORM), {"value":40,"unit":"percent"} → TextDimension(40, PERCENT)

@Serializable
data class Style(
    // Text properties (inherit to children)
    val textColor: String? = null,
    val fontSize: TextDimension? = null,    // TextDimension: number or {"value","unit"}
    val fontFamily: String? = null,
    val fontWeight: FontWeight? = null,
    val fontStyle: FontStyle? = null,
    val lineHeight: TextDimension? = null,  // TextDimension: number or {"value","unit"}
    val letterSpacing: Float? = null,
    val textDecoration: TextDecoration? = null,
    val textAlign: String? = null,
    val maxLines: Int? = null,
    val overflow: TextOverflow? = null,
    val textShadow: TextShadow? = null,
    val textGradient: TextGradient? = null,

    // Background properties (do NOT inherit)
    val background: Background? = null,
    val backgroundColor: String? = null,

    // Border properties (do NOT inherit)
    val borderRadius: Dimension? = null,  // Dimension: number (dp) or {"value","unit":"percent"}
    val borderWidth: Float? = null,
    val borderColor: String? = null,

    // Shadow properties (do NOT inherit)
    val shadowColor: String? = null,
    val shadowRadius: Float? = null,
    val shadowOffsetX: Float? = null,
    val shadowOffsetY: Float? = null,

    // Transform properties
    val opacity: Float? = null
)

@Serializable
data class TextShadow(
    val color: String,
    val offsetX: Float = 0f,
    val offsetY: Float = 0f,
    val blur: Float = 0f
)

@Serializable
data class TextGradient(
    val type: String = "linear",
    val colors: List<String>,
    val angle: Float = 0f,
    val stops: List<Float>? = null
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
    val aspectRatio: Float? = null,
    val offset: Offset? = null,
    val padding: Spacing? = null,
    val arrangement: ChildArrangement? = null
)

/**
 * Dimension with default values for robust JSON parsing.
 * Backend can omit any field and parsing will succeed with defaults.
 */
@Serializable
data class Dimension(
    val value: Float = 0f,  // Default: 0
    val unit: DimensionUnit = DimensionUnit.DP,  // Default: DP
    val special: SpecialDimension? = null  // Default: null
)

/**
 * Offset for absolute positioning with default values.
 */
@Serializable
data class Offset(
    val x: Float = 0f,  // Default: 0
    val y: Float = 0f,  // Default: 0
    val unit: DimensionUnit = DimensionUnit.DP  // Default: DP
)

/**
 * Spacing with default unit for padding.
 */
@Serializable
data class Spacing(
    val all: Float? = null,
    val horizontal: Float? = null,
    val vertical: Float? = null,
    val top: Float? = null,
    val bottom: Float? = null,
    val left: Float? = null,
    val right: Float? = null,
    val unit: DimensionUnit = DimensionUnit.DP  // Default: DP
)

/**
 * Child arrangement with defaults for container spacing.
 */
@Serializable
data class ChildArrangement(
    val spacing: Float? = null,
    val spacingUnit: DimensionUnit = DimensionUnit.DP,  // Default: DP
    val strategy: ArrangementStrategy = ArrangementStrategy.SPACED  // Default: SPACED
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
    val background: Background? = null,
    val dividerConfig: DividerConfig? = null,
    val imageConfig: ImageConfig? = null,
    val htmlConfig: HtmlConfig? = null
) : NativeDisplayNode()

@Serializable
data class HtmlConfig(
    val javascriptEnabled: Boolean = false,
    val scrollEnabled: Boolean = false,
    val baseUrl: String? = null,
    val transparentBackground: Boolean = true
)

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

struct TextDimension: Codable, Equatable {
    let value: CGFloat
    let unit: TextDimensionUnit  // .platform or .percent
    func resolve(containerHeight rootHeight: CGFloat) -> CGFloat {
        switch unit {
        case .platform: return value
        case .percent:  return rootHeight * value / 1000
        }
    }
    // Custom Codable: number → .platform, {"value","unit":"percent"} → .percent
}

struct Style: Codable {
    let textColor: String?
    let fontSize: TextDimension?     // TextDimension: number or {"value","unit"}
    let fontFamily: String?
    let fontWeight: FontWeight?
    let fontStyle: FontStyle?
    let lineHeight: TextDimension?   // TextDimension: number or {"value","unit"}
    let letterSpacing: CGFloat?
    let textDecoration: TextDecoration?
    let textAlign: String?
    let maxLines: Int?
    let overflow: TextOverflow?
    let textShadow: TextShadow?
    let textGradient: TextGradient?
    let background: Background?
    let backgroundColor: String?
    let borderRadius: Dimension?  // Dimension: number (dp) or {"value","unit":"percent"}
    let borderWidth: CGFloat?
    let borderColor: String?
    let shadowColor: String?
    let shadowRadius: CGFloat?
    let shadowOffsetX: CGFloat?
    let shadowOffsetY: CGFloat?
    let opacity: CGFloat?
}

struct TextShadow: Codable {
    let color: String
    let offsetX: CGFloat
    let offsetY: CGFloat
    let blur: CGFloat
}

struct TextGradient: Codable {
    let type: String
    let colors: [String]
    let angle: CGFloat
    let stops: [CGFloat]?
}

struct Layout: Codable {
    let width: Dimension?
    let height: Dimension?
    let padding: Spacing?
    let margin: Spacing?
}

/**
 * Dimension with default values via custom decoder.
 * iOS uses decodeIfPresent with ?? fallbacks for robust parsing.
 */
struct Dimension: Codable {
    let value: CGFloat  // Default: 0
    let unit: DimensionUnit  // Default: .dp
    let special: SpecialDimension?  // Default: nil

    init(value: CGFloat = 0, unit: DimensionUnit = .dp, special: SpecialDimension? = nil) {
        self.value = value
        self.unit = unit
        self.special = special
    }

    // Custom decoder with defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = try container.decodeIfPresent(CGFloat.self, forKey: .value) ?? 0
        self.unit = try container.decodeIfPresent(DimensionUnit.self, forKey: .unit) ?? .dp
        self.special = try container.decodeIfPresent(SpecialDimension.self, forKey: .special)
    }
}

/**
 * Offset with default values via custom decoder.
 */
struct Offset: Codable {
    let x: CGFloat  // Default: 0
    let y: CGFloat  // Default: 0
    let unit: DimensionUnit  // Default: .dp

    init(x: CGFloat = 0, y: CGFloat = 0, unit: DimensionUnit = .dp) {
        self.x = x
        self.y = y
        self.unit = unit
    }

    // Custom decoder with defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.x = try container.decodeIfPresent(CGFloat.self, forKey: .x) ?? 0
        self.y = try container.decodeIfPresent(CGFloat.self, forKey: .y) ?? 0
        self.unit = try container.decodeIfPresent(DimensionUnit.self, forKey: .unit) ?? .dp
    }
}

/**
 * Spacing with default unit via custom decoder.
 */
struct Spacing: Codable {
    let all: CGFloat?
    let horizontal: CGFloat?
    let vertical: CGFloat?
    let top: CGFloat?
    let bottom: CGFloat?
    let left: CGFloat?
    let right: CGFloat?
    let unit: DimensionUnit  // Default: .dp

    // Custom decoder with default for unit
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.all = try container.decodeIfPresent(CGFloat.self, forKey: .all)
        self.horizontal = try container.decodeIfPresent(CGFloat.self, forKey: .horizontal)
        self.vertical = try container.decodeIfPresent(CGFloat.self, forKey: .vertical)
        self.top = try container.decodeIfPresent(CGFloat.self, forKey: .top)
        self.bottom = try container.decodeIfPresent(CGFloat.self, forKey: .bottom)
        self.left = try container.decodeIfPresent(CGFloat.self, forKey: .left)
        self.right = try container.decodeIfPresent(CGFloat.self, forKey: .right)
        self.unit = try container.decodeIfPresent(DimensionUnit.self, forKey: .unit) ?? .dp
    }
}

/**
 * ChildArrangement with defaults via custom decoder.
 */
struct ChildArrangement: Codable {
    let spacing: CGFloat?
    let spacingUnit: DimensionUnit  // Default: .dp
    let strategy: ArrangementStrategy  // Default: .spaced

    // Custom decoder with defaults
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.spacing = try container.decodeIfPresent(CGFloat.self, forKey: .spacing)
        self.spacingUnit = try container.decodeIfPresent(DimensionUnit.self, forKey: .spacingUnit) ?? .dp
        self.strategy = try container.decodeIfPresent(ArrangementStrategy.self, forKey: .strategy) ?? .spaced
    }
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
    let dividerConfig: DividerConfig?
    let imageConfig: ImageConfig?
    let htmlConfig: HtmlConfig?
}

struct HtmlConfig: Codable {
    let javascriptEnabled: Bool  // Default: false
    let scrollEnabled: Bool  // Default: false
    let baseUrl: String?  // Default: nil
    let transparentBackground: Bool  // Default: true
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

// TextDimension: number → platform units, or object → percentage
type TextDimension = number | { value: number; unit: 'platform' | 'percent' };

interface Style {
  textColor?: string;
  fontSize?: TextDimension;   // number (platform units) or {"value", "unit":"percent"}
  fontFamily?: string;
  fontWeight?: 'normal' | 'medium' | 'bold' | 'light';
  fontStyle?: 'normal' | 'italic';
  lineHeight?: TextDimension; // number (platform units) or {"value", "unit":"percent"}
  letterSpacing?: number;
  textDecoration?: 'none' | 'underline' | 'strikethrough';
  textAlign?: 'left' | 'center' | 'right' | 'justify';
  maxLines?: number;
  overflow?: 'clip' | 'ellipsis' | 'visible';
  textShadow?: TextShadow;
  textGradient?: TextGradient;
  background?: Background;
  backgroundColor?: string;
  borderRadius?: number | { value: number; unit: 'dp' | 'percent' };
  borderWidth?: number;
  borderColor?: string;
  shadowColor?: string;
  shadowRadius?: number;
  shadowOffsetX?: number;
  shadowOffsetY?: number;
  opacity?: number;
}

interface TextShadow {
  color: string;
  offsetX: number;
  offsetY: number;
  blur: number;
}

interface TextGradient {
  type: 'linear';
  colors: string[];
  angle: number;
  stops?: number[];
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
  elementType: 'text' | 'image' | 'button' | 'video' | 'html' | 'spacer' | 'divider';
  bindings?: Record<string, string>;
  actions?: Record<string, Action>;
  layout?: Layout;
  style?: Style;
  styleClass?: string;
  visible?: string;
  dividerConfig?: DividerConfig;
  imageConfig?: ImageConfig;
  htmlConfig?: HtmlConfig;
}

interface HtmlConfig {
  javascriptEnabled?: boolean;  // default: false
  scrollEnabled?: boolean;  // default: false
  baseUrl?: string;  // default: null
  transparentBackground?: boolean;  // default: true
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
