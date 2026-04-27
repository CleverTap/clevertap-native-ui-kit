//
//  ContainerExampleViewController.swift
//  NativeDisplayUiKit
//
//  Examples of different container types
//

import UIKit

class ContainerExampleViewController: ExampleViewController {
    
    override func loadExample() {
        guard let type = exampleType else { return }
        
        switch type {
        case .vertical:
            showVerticalExample()
        case .horizontal:
            showHorizontalExample()
        case .box:
            showBoxExample()
        case .stack:
            showStackExample()
        default:
            break
        }
    }
    
    private func showVerticalExample() {
        let json = """
        {
          "theme": {
            "id": "default",
            "defaultStyle": {
              "textColor": "#000000",
              "fontSize": 16
            }
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
                "id": "title",
                "elementType": "text",
                "bindings": {
                  "text": "Vertical Container"
                },
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
                "layout": {
                  "height": {"value": 16, "unit": "dp"}
                }
              },
              {
                "type": "element",
                "id": "desc",
                "elementType": "text",
                "bindings": {
                  "text": "This is a vertical container that stacks children from top to bottom."
                },
                "style": {
                  "fontSize": 14,
                  "textColor": "#666666"
                }
              },
              {
                "type": "element",
                "id": "spacer2",
                "elementType": "spacer",
                "bindings": {},
                "layout": {
                  "height": {"value": 24, "unit": "dp"}
                }
              },
              {
                "type": "container",
                "id": "box1",
                "containerType": "box",
                "layout": {
                  "height": {"value": 60, "unit": "dp"}
                },
                "style": {
                  "backgroundColor": "#E3F2FD",
                  "borderRadius": 8
                },
                "children": [
                  {
                    "type": "element",
                    "id": "text1",
                    "elementType": "text",
                    "bindings": {
                      "text": "Item 1"
                    }
                  }
                ]
              },
              {
                "type": "element",
                "id": "spacer3",
                "elementType": "spacer",
                "bindings": {},
                "layout": {
                  "height": {"value": 12, "unit": "dp"}
                }
              },
              {
                "type": "container",
                "id": "box2",
                "containerType": "box",
                "layout": {
                  "height": {"value": 60, "unit": "dp"}
                },
                "style": {
                  "backgroundColor": "#F3E5F5",
                  "borderRadius": 8
                },
                "children": [
                  {
                    "type": "element",
                    "id": "text2",
                    "elementType": "text",
                    "bindings": {
                      "text": "Item 2"
                    }
                  }
                ]
              },
              {
                "type": "element",
                "id": "spacer4",
                "elementType": "spacer",
                "bindings": {},
                "layout": {
                  "height": {"value": 12, "unit": "dp"}
                }
              },
              {
                "type": "container",
                "id": "box3",
                "containerType": "box",
                "layout": {
                  "height": {"value": 60, "unit": "dp"}
                },
                "style": {
                  "backgroundColor": "#E8F5E9",
                  "borderRadius": 8
                },
                "children": [
                  {
                    "type": "element",
                    "id": "text3",
                    "elementType": "text",
                    "bindings": {
                      "text": "Item 3"
                    }
                  }
                ]
              }
            ]
          }
        }
        """
        
        displayJSON(json, description: "A vertical container stacks children from top to bottom with spacing between them.")
    }
    
    private func showHorizontalExample() {
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
                "bindings": {
                  "text": "Horizontal Container"
                },
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
                "type": "container",
                "id": "horizontal",
                "containerType": "horizontal",
                "children": [
                  {
                    "type": "container",
                    "id": "item1",
                    "containerType": "box",
                    "layout": {
                      "width": {"value": 80, "unit": "dp"},
                      "height": {"value": 80, "unit": "dp"}
                    },
                    "style": {
                      "backgroundColor": "#FF5722",
                      "borderRadius": 8
                    },
                    "children": [
                      {
                        "type": "element",
                        "id": "text1",
                        "elementType": "text",
                        "bindings": {"text": "1"},
                        "style": {
                          "textColor": "#FFFFFF",
                          "fontSize": 32,
                          "fontWeight": "bold"
                        }
                      }
                    ]
                  },
                  {
                    "type": "element",
                    "id": "spacer2",
                    "elementType": "spacer",
                    "bindings": {},
                    "layout": {"width": {"value": 12, "unit": "dp"}}
                  },
                  {
                    "type": "container",
                    "id": "item2",
                    "containerType": "box",
                    "layout": {
                      "width": {"value": 80, "unit": "dp"},
                      "height": {"value": 80, "unit": "dp"}
                    },
                    "style": {
                      "backgroundColor": "#2196F3",
                      "borderRadius": 8
                    },
                    "children": [
                      {
                        "type": "element",
                        "id": "text2",
                        "elementType": "text",
                        "bindings": {"text": "2"},
                        "style": {
                          "textColor": "#FFFFFF",
                          "fontSize": 32,
                          "fontWeight": "bold"
                        }
                      }
                    ]
                  },
                  {
                    "type": "element",
                    "id": "spacer3",
                    "elementType": "spacer",
                    "bindings": {},
                    "layout": {"width": {"value": 12, "unit": "dp"}}
                  },
                  {
                    "type": "container",
                    "id": "item3",
                    "containerType": "box",
                    "layout": {
                      "width": {"value": 80, "unit": "dp"},
                      "height": {"value": 80, "unit": "dp"}
                    },
                    "style": {
                      "backgroundColor": "#4CAF50",
                      "borderRadius": 8
                    },
                    "children": [
                      {
                        "type": "element",
                        "id": "text3",
                        "elementType": "text",
                        "bindings": {"text": "3"},
                        "style": {
                          "textColor": "#FFFFFF",
                          "fontSize": 32,
                          "fontWeight": "bold"
                        }
                      }
                    ]
                  }
                ]
              }
            ]
          }
        }
        """
        
        displayJSON(json, description: "A horizontal container arranges children from left to right.")
    }
    
    private func showBoxExample() {
        let json = """
        {
          "theme": {
            "id": "default"
          },
          "root": {
            "type": "container",
            "id": "root",
            "containerType": "box",
            "layout": {
              "padding": {"all": 32}
            },
            "style": {
              "backgroundColor": "#F5F5F5"
            },
            "children": [
              {
                "type": "container",
                "id": "card",
                "containerType": "vertical",
                "layout": {
                  "padding": {"all": 24}
                },
                "style": {
                  "backgroundColor": "#FFFFFF",
                  "borderRadius": 16,
                  "shadowColor": "#000000",
                  "shadowRadius": 12
                },
                "children": [
                  {
                    "type": "element",
                    "id": "icon",
                    "elementType": "text",
                    "bindings": {"text": "📦"},
                    "style": {
                      "fontSize": 64,
                      "textAlign": "center"
                    }
                  },
                  {
                    "type": "element",
                    "id": "spacer",
                    "elementType": "spacer",
                    "bindings": {},
                    "layout": {"height": {"value": 16, "unit": "dp"}}
                  },
                  {
                    "type": "element",
                    "id": "title",
                    "elementType": "text",
                    "bindings": {"text": "Box Container"},
                    "style": {
                      "fontSize": 24,
                      "fontWeight": "bold",
                      "textAlign": "center"
                    }
                  },
                  {
                    "type": "element",
                    "id": "desc",
                    "elementType": "text",
                    "bindings": {"text": "Centers a single child"},
                    "style": {
                      "fontSize": 14,
                      "textColor": "#666666",
                      "textAlign": "center"
                    }
                  }
                ]
              }
            ]
          }
        }
        """
        
        displayJSON(json, description: "A box container holds a single child and centers it within the available space.")
    }
    
    private func showStackExample() {
        let json = """
        {
          "theme": {
            "id": "default"
          },
          "root": {
            "type": "container",
            "id": "root",
            "containerType": "box",
            "layout": {
              "padding": {"all": 16}
            },
            "children": [
              {
                "type": "container",
                "id": "stack",
                "containerType": "stack",
                "layout": {
                  "width": {"special": "match_parent"},
                  "height": {"value": 300, "unit": "dp"}
                },
                "style": {
                  "borderRadius": 16
                },
                "children": [
                  {
                    "type": "container",
                    "id": "background",
                    "containerType": "box",
                    "style": {
                      "backgroundColor": "#FF5722",
                      "borderRadius": 16
                    },
                    "children": []
                  },
                  {
                    "type": "container",
                    "id": "content",
                    "containerType": "vertical",
                    "layout": {
                      "padding": {"all": 24},
                      "offset": {"x": 0, "y": 120, "unit": "dp"}
                    },
                    "children": [
                      {
                        "type": "element",
                        "id": "title",
                        "elementType": "text",
                        "bindings": {"text": "Stack Container"},
                        "style": {
                          "fontSize": 28,
                          "fontWeight": "bold",
                          "textColor": "#FFFFFF"
                        }
                      },
                      {
                        "type": "element",
                        "id": "subtitle",
                        "elementType": "text",
                        "bindings": {"text": "Layered children with z-index"},
                        "style": {
                          "fontSize": 16,
                          "textColor": "#FFFFFF"
                        }
                      }
                    ]
                  }
                ]
              }
            ]
          }
        }
        """
        
        displayJSON(json, description: "A stack container layers children on top of each other with z-index ordering.")
    }
}
