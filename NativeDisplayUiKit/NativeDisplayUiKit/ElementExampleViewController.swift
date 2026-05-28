//
//  ElementExampleViewController.swift
//  NativeDisplayUiKit
//
//  Examples of different element types
//

import UIKit

class ElementExampleViewController: ExampleViewController {
    
    override func loadExample() {
        guard let type = exampleType else { return }
        
        switch type {
        case .text:
            showTextExample()
        case .image:
            showImageExample()
        case .button:
            showButtonExample()
        case .spacer:
            showSpacerExample()
        default:
            break
        }
    }
    
    private func showTextExample() {
        let json = """
        {
          "theme": {
            "id": "default"
          },
          "root": {
            "type": "container",
            "id": "root",
            "containerType": "vertical",
            "layout": {
              "padding": {"all": 16}
            },
            "style": {
              "backgroundColor": "#FFFFFF"
            },
            "children": [
              {
                "type": "element",
                "id": "heading",
                "elementType": "text",
                "bindings": {"text": "Text Element"},
                "style": {
                  "fontSize": 32,
                  "fontWeight": "bold",
                  "textColor": "#FF5722"
                }
              },
              {
                "type": "element",
                "id": "spacer1",
                "elementType": "spacer",
                "bindings": {},
                "layout": {"height": {"value": 16, "unit": "dp"}}
              },
              {
                "type": "element",
                "id": "body",
                "elementType": "text",
                "bindings": {
                  "text": "This is a text element with custom styling. You can control font size, weight, color, and alignment."
                },
                "style": {
                  "fontSize": 16,
                  "textColor": "#333333",
                  "lineHeight": 24
                }
              },
              {
                "type": "element",
                "id": "spacer2",
                "elementType": "spacer",
                "bindings": {},
                "layout": {"height": {"value": 24, "unit": "dp"}}
              },
              {
                "type": "element",
                "id": "center",
                "elementType": "text",
                "bindings": {"text": "Centered Text"},
                "style": {
                  "fontSize": 18,
                  "textAlign": "center",
                  "textColor": "#2196F3"
                }
              },
              {
                "type": "element",
                "id": "spacer3",
                "elementType": "spacer",
                "bindings": {},
                "layout": {"height": {"value": 16, "unit": "dp"}}
              },
              {
                "type": "element",
                "id": "right",
                "elementType": "text",
                "bindings": {"text": "Right-aligned Text"},
                "style": {
                  "fontSize": 18,
                  "textAlign": "right",
                  "textColor": "#4CAF50"
                }
              }
            ]
          }
        }
        """
        
        displayJSON(json, description: "Text elements display styled text with support for various font sizes, weights, colors, and alignments.")
    }
    
    private func showImageExample() {
        let json = """
        {
          "theme": {
            "id": "default"
          },
          "root": {
            "type": "container",
            "id": "root",
            "containerType": "vertical",
            "layout": {
              "padding": {"all": 16}
            },
            "children": [
              {
                "type": "element",
                "id": "title",
                "elementType": "text",
                "bindings": {"text": "Image Element"},
                "style": {
                  "fontSize": 24,
                  "fontWeight": "bold",
                  "textColor": "#FF5722"
                }
              },
              {
                "type": "element",
                "id": "spacer1",
                "elementType": "spacer",
                "bindings": {},
                "layout": {"height": {"value": 16, "unit": "dp"}}
              },
              {
                "type": "element",
                "id": "image",
                "elementType": "image",
                "bindings": {
                  "url": "https://picsum.photos/400/300"
                },
                "layout": {
                  "width": {"special": "match_parent"},
                  "height": {"value": 200, "unit": "dp"}
                },
                "style": {
                  "borderRadius": 12
                }
              },
              {
                "type": "element",
                "id": "spacer2",
                "elementType": "spacer",
                "bindings": {},
                "layout": {"height": {"value": 16, "unit": "dp"}}
              },
              {
                "type": "element",
                "id": "caption",
                "elementType": "text",
                "bindings": {"text": "Images can be loaded from URLs with custom sizing and border radius."},
                "style": {
                  "fontSize": 14,
                  "textColor": "#666666",
                  "textAlign": "center"
                }
              }
            ]
          }
        }
        """
        
        displayJSON(json, description: "Image elements display images from URLs with customizable sizing and styling.")
    }
    
    private func showButtonExample() {
        let json = """
        {
          "theme": {
            "id": "default"
          },
          "root": {
            "type": "container",
            "id": "root",
            "containerType": "vertical",
            "layout": {
              "padding": {"all": 16}
            },
            "children": [
              {
                "type": "element",
                "id": "title",
                "elementType": "text",
                "bindings": {"text": "Button Element"},
                "style": {
                  "fontSize": 24,
                  "fontWeight": "bold",
                  "textColor": "#FF5722"
                }
              },
              {
                "type": "element",
                "id": "spacer1",
                "elementType": "spacer",
                "bindings": {},
                "layout": {"height": {"value": 24, "unit": "dp"}}
              },
              {
                "type": "element",
                "id": "button1",
                "elementType": "button",
                "bindings": {"text": "Primary Button"},
                "layout": {
                  "padding": {"horizontal": 24, "vertical": 12}
                },
                "style": {
                  "backgroundColor": "#FF5722",
                  "textColor": "#FFFFFF",
                  "fontSize": 16,
                  "fontWeight": "medium",
                  "borderRadius": 8
                }
              },
              {
                "type": "element",
                "id": "spacer2",
                "elementType": "spacer",
                "bindings": {},
                "layout": {"height": {"value": 16, "unit": "dp"}}
              },
              {
                "type": "element",
                "id": "button2",
                "elementType": "button",
                "bindings": {"text": "Secondary Button"},
                "layout": {
                  "padding": {"horizontal": 24, "vertical": 12}
                },
                "style": {
                  "backgroundColor": "#E0E0E0",
                  "textColor": "#333333",
                  "fontSize": 16,
                  "borderRadius": 8
                }
              },
              {
                "type": "element",
                "id": "spacer3",
                "elementType": "spacer",
                "bindings": {},
                "layout": {"height": {"value": 16, "unit": "dp"}}
              },
              {
                "type": "element",
                "id": "button3",
                "elementType": "button",
                "bindings": {"text": "Outline Button"},
                "layout": {
                  "padding": {"horizontal": 24, "vertical": 12}
                },
                "style": {
                  "backgroundColor": "#FFFFFF",
                  "textColor": "#2196F3",
                  "fontSize": 16,
                  "borderRadius": 8,
                  "borderWidth": 2,
                  "borderColor": "#2196F3"
                }
              }
            ]
          }
        }
        """
        
        displayJSON(json, description: "Button elements provide interactive actions with customizable styling including colors, borders, and padding.")
    }
    
    private func showSpacerExample() {
        let json = """
        {
          "theme": {
            "id": "default"
          },
          "root": {
            "type": "container",
            "id": "root",
            "containerType": "vertical",
            "layout": {
              "padding": {"all": 16}
            },
            "style": {
              "backgroundColor": "#F5F5F5"
            },
            "children": [
              {
                "type": "element",
                "id": "text1",
                "elementType": "text",
                "bindings": {"text": "Item 1"},
                "layout": {
                  "padding": {"all": 12}
                },
                "style": {
                  "fontSize": 18,
                  "backgroundColor": "#E3F2FD",
                  "borderRadius": 8
                }
              },
              {
                "type": "element",
                "id": "spacer1",
                "elementType": "spacer",
                "bindings": {},
                "layout": {"height": {"value": 8, "unit": "dp"}},
                "style": {"backgroundColor": "#FFCDD2"}
              },
              {
                "type": "element",
                "id": "text2",
                "elementType": "text",
                "bindings": {"text": "Item 2"},
                "layout": {
                  "padding": {"all": 12}
                },
                "style": {
                  "fontSize": 18,
                  "backgroundColor": "#F3E5F5",
                  "borderRadius": 8
                }
              },
              {
                "type": "element",
                "id": "spacer2",
                "elementType": "spacer",
                "bindings": {},
                "layout": {"height": {"value": 24, "unit": "dp"}},
                "style": {"backgroundColor": "#C8E6C9"}
              },
              {
                "type": "element",
                "id": "text3",
                "elementType": "text",
                "bindings": {"text": "Item 3"},
                "layout": {
                  "padding": {"all": 12}
                },
                "style": {
                  "fontSize": 18,
                  "backgroundColor": "#E8F5E9",
                  "borderRadius": 8
                }
              },
              {
                "type": "element",
                "id": "spacer3",
                "elementType": "spacer",
                "bindings": {},
                "layout": {"height": {"value": 32, "unit": "dp"}},
                "style": {"backgroundColor": "#FFF9C4"}
              },
              {
                "type": "element",
                "id": "text4",
                "elementType": "text",
                "bindings": {"text": "Item 4"},
                "layout": {
                  "padding": {"all": 12}
                },
                "style": {
                  "fontSize": 18,
                  "backgroundColor": "#FFE0B2",
                  "borderRadius": 8
                }
              }
            ]
          }
        }
        """
        
        displayJSON(json, description: "Spacer elements add fixed or flexible spacing between other elements. The colored spacers show different height values.")
    }
}
