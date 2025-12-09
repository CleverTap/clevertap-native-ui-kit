# Documentation

This directory contains all documentation for the CleverTap Native Display Kit project.

## 📂 Directory Structure

```
docs/
└── architecture/           # Architecture design documents
    ├── ARCHITECTURE_DOCS_INDEX.md
    ├── ADAPTIVE_ARCHITECTURE.md
    ├── SCALABLE_ARCHITECTURE.md
    ├── TEMPLATE_DATA_EXAMPLE.md
    ├── LAYOUT_IN_TEMPLATE_EXPLAINED.md
    └── LAYOUT_CONTENT_SEPARATION.md
```

## 📖 Quick Start

### New to the Project?

Start here in this order:

1. **[architecture/ARCHITECTURE_DOCS_INDEX.md](architecture/ARCHITECTURE_DOCS_INDEX.md)**
   - Overview of all architecture documents
   - Quick reference guide
   - Reading recommendations

2. **[architecture/ADAPTIVE_ARCHITECTURE.md](architecture/ADAPTIVE_ARCHITECTURE.md)** ⭐ **Most Important**
   - Main implementation guide
   - Phase 1 (monolithic) and Phase 2+ (split APIs)
   - How to build the system

3. **[architecture/SCALABLE_ARCHITECTURE.md](architecture/SCALABLE_ARCHITECTURE.md)**
   - Style inheritance system
   - Variable system (static → reactive)
   - Future-proof design patterns

### Need Examples?

4. **[architecture/TEMPLATE_DATA_EXAMPLE.md](architecture/TEMPLATE_DATA_EXAMPLE.md)**
   - Complete product card example
   - Visual mockups
   - 12 bindings demonstration
   - Bandwidth calculations

### Need Clarification?

5. **[architecture/LAYOUT_IN_TEMPLATE_EXPLAINED.md](architecture/LAYOUT_IN_TEMPLATE_EXPLAINED.md)**
   - Where layout information lives
   - Template vs data separation
   - Rendering process explained

6. **[architecture/LAYOUT_CONTENT_SEPARATION.md](architecture/LAYOUT_CONTENT_SEPARATION.md)**
   - 5 different approaches compared
   - Pros and cons analysis
   - Design rationale

## 🎯 Key Concepts

### Phase 1: Monolithic (Current)

Backend sends everything together in one JSON:

```json
{
  "version": "1.0",
  "theme": { },
  "styleClasses": [ ],
  "variables": { "userName": "John" },
  "root": { "type": "container", "children": [ ] }
}
```

### Phase 2+: Split APIs (Future)

Backend can send separate APIs:

```json
{
  "version": "2.0",
  "templateRef": { "templateId": "card-v1" },
  "styleRef": { "styleId": "theme-v1" },
  "dataRef": { "url": "/api/data/123" }
}
```

**Same mobile code works for both!**

## 🏗️ Architecture Decisions

| Decision | Details |
|----------|---------|
| **API Evolution** | Monolithic → Split APIs (adaptive loader) |
| **Containers** | Unlimited nesting support |
| **Styles** | Cascading inheritance (like CSS) |
| **Variables** | Static (Phase 1) → Reactive (Phase 2+) |
| **Layout** | In template, not in data |

## 📊 Document Summary

| Document | Size | Priority | Purpose |
|----------|------|----------|---------|
| ARCHITECTURE_DOCS_INDEX.md | 9KB | ⭐⭐⭐ | Overview & quick reference |
| ADAPTIVE_ARCHITECTURE.md | 18KB | ⭐⭐⭐ | Main implementation guide |
| SCALABLE_ARCHITECTURE.md | 16KB | ⭐⭐⭐ | Style & variable systems |
| TEMPLATE_DATA_EXAMPLE.md | 20KB | ⭐⭐ | Complete working example |
| LAYOUT_IN_TEMPLATE_EXPLAINED.md | 13KB | ⭐ | Layout clarification |
| LAYOUT_CONTENT_SEPARATION.md | 15KB | ⭐ | Design alternatives |

**Total**: 91KB of comprehensive documentation

## 🚀 Getting Started

1. Read [ARCHITECTURE_DOCS_INDEX.md](architecture/ARCHITECTURE_DOCS_INDEX.md) for overview
2. Read [ADAPTIVE_ARCHITECTURE.md](architecture/ADAPTIVE_ARCHITECTURE.md) for implementation
3. Reference other docs as needed

## 📝 Contributing

When adding new documentation:

1. Keep documents focused on a single topic
2. Include visual examples where possible
3. Update this README with links to new docs
4. Add entries to ARCHITECTURE_DOCS_INDEX.md

## 🔗 Related Files

- **Project Setup**: [../PROJECT_SETUP.md](../PROJECT_SETUP.md)
- **Main README**: [../README.md](../README.md)
- **Native Approach**: [../NATIVE_APPROACH.md](../NATIVE_APPROACH.md)
- **Changelog**: [../CHANGELOG.md](../CHANGELOG.md)

---

**Ready to build?** Start with [ADAPTIVE_ARCHITECTURE.md](architecture/ADAPTIVE_ARCHITECTURE.md)! 🎉
