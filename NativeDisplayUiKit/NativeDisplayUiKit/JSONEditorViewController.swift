//
//  JSONEditorViewController.swift
//  NativeDisplayUiKit
//
//  Live JSON editor with preview
//

import UIKit

class JSONEditorViewController: ExampleViewController {
    
    private let textView: UITextView = {
        let tv = UITextView()
        tv.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        tv.autocorrectionType = .no
        tv.autocapitalizationType = .none
        tv.backgroundColor = .systemBackground
        tv.layer.borderColor = UIColor.systemGray4.cgColor
        tv.layer.borderWidth = 1
        tv.layer.cornerRadius = 8
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private let renderButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Render Preview", for: .normal)
        button.backgroundColor = UIColor(red: 1.0, green: 0.34, blue: 0.13, alpha: 1.0)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.layer.cornerRadius = 8
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomUI()
        loadSampleJSON()
    }
    
    private func setupCustomUI() {
        view.backgroundColor = .systemBackground
        title = "JSON Editor"
        
        let containerStack = UIStackView()
        containerStack.axis = .vertical
        containerStack.spacing = 16
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        
        let editorLabel = UILabel()
        editorLabel.text = "Edit JSON:"
        editorLabel.font = .systemFont(ofSize: 14, weight: .medium)
        editorLabel.textColor = .secondaryLabel
        
        containerStack.addArrangedSubview(editorLabel)
        containerStack.addArrangedSubview(textView)
        containerStack.addArrangedSubview(renderButton)
        
        view.addSubview(containerStack)
        
        NSLayoutConstraint.activate([
            containerStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            containerStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            containerStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            containerStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            
            textView.heightAnchor.constraint(equalToConstant: 300),
            renderButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        renderButton.addTarget(self, action: #selector(renderTapped), for: .touchUpInside)
        
        // Add toolbar
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let clearButton = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearTapped))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let sampleButton = UIBarButtonItem(title: "Load Sample", style: .plain, target: self, action: #selector(loadSampleTapped))
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneTapped))
        
        toolbar.items = [clearButton, flexSpace, sampleButton, flexSpace, doneButton]
        textView.inputAccessoryView = toolbar
    }
    
    private func loadSampleJSON() {
        textView.text = """
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
                  "text": "Hello, World!"
                },
                "style": {
                  "fontSize": 24,
                  "fontWeight": "bold",
                  "textColor": "#FF5722"
                }
              },
              {
                "type": "element",
                "id": "spacer",
                "elementType": "spacer",
                "bindings": {},
                "layout": {
                  "height": {"value": 16, "unit": "dp"}
                }
              },
              {
                "type": "element",
                "id": "description",
                "elementType": "text",
                "bindings": {
                  "text": "Edit the JSON above and tap 'Render Preview' to see your changes."
                },
                "style": {
                  "fontSize": 16,
                  "textColor": "#666666"
                }
              }
            ]
          }
        }
        """
    }
    
    @objc private func renderTapped() {
        guard let json = textView.text, !json.isEmpty else {
            showAlert(title: "Error", message: "Please enter JSON configuration")
            return
        }
        
        // Dismiss keyboard
        textView.resignFirstResponder()
        
        // Show preview
        let previewVC = JSONPreviewViewController()
        previewVC.jsonString = json
        previewVC.title = "Preview"
        navigationController?.pushViewController(previewVC, animated: true)
    }
    
    @objc private func clearTapped() {
        let alert = UIAlertController(
            title: "Clear JSON?",
            message: "This will remove all your edits.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            self?.textView.text = ""
        })
        present(alert, animated: true)
    }
    
    @objc private func loadSampleTapped() {
        let alert = UIAlertController(
            title: "Load Sample",
            message: "Choose a sample JSON to load",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Simple Text", style: .default) { [weak self] _ in
            self?.loadSampleJSON()
        })
        
        alert.addAction(UIAlertAction(title: "Profile Card", style: .default) { [weak self] _ in
            self?.loadProfileCard()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    @objc private func doneTapped() {
        textView.resignFirstResponder()
    }
    
    private func loadProfileCard() {
        textView.text = """
        {
          "theme": {
            "id": "default"
          },
          "root": {
            "type": "container",
            "id": "profile",
            "containerType": "vertical",
            "layout": {
              "padding": {"all": 16}
            },
            "style": {
              "backgroundColor": "#FFFFFF",
              "borderRadius": 12,
              "shadowColor": "#000000",
              "shadowRadius": 8
            },
            "children": [
              {
                "type": "container",
                "id": "header",
                "containerType": "horizontal",
                "children": [
                  {
                    "type": "element",
                    "id": "avatar",
                    "elementType": "image",
                    "bindings": {
                      "url": "https://i.pravatar.cc/100"
                    },
                    "layout": {
                      "width": {"value": 60, "unit": "dp"},
                      "height": {"value": 60, "unit": "dp"}
                    },
                    "style": {
                      "borderRadius": 30
                    }
                  },
                  {
                    "type": "element",
                    "id": "spacer1",
                    "elementType": "spacer",
                    "bindings": {},
                    "layout": {"width": {"value": 12, "unit": "dp"}}
                  },
                  {
                    "type": "container",
                    "id": "info",
                    "containerType": "vertical",
                    "children": [
                      {
                        "type": "element",
                        "id": "name",
                        "elementType": "text",
                        "bindings": {"text": "John Doe"},
                        "style": {
                          "fontSize": 20,
                          "fontWeight": "bold"
                        }
                      },
                      {
                        "type": "element",
                        "id": "role",
                        "elementType": "text",
                        "bindings": {"text": "Software Engineer"},
                        "style": {
                          "fontSize": 14,
                          "textColor": "#666666"
                        }
                      }
                    ]
                  }
                ]
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
                "id": "bio",
                "elementType": "text",
                "bindings": {
                  "text": "Passionate about building beautiful mobile experiences with native technologies."
                },
                "style": {
                  "fontSize": 14,
                  "textColor": "#333333",
                  "lineHeight": 20
                }
              }
            ]
          }
        }
        """
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Preview ViewController

class JSONPreviewViewController: UIViewController {
    
    var jsonString: String = ""
    
    private var displayView: NativeDisplayHostingView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        
        displayView = NativeDisplayHostingView(json: jsonString, parentViewController: self)
        displayView?.backgroundColor = .clear
        displayView?.translatesAutoresizingMaskIntoConstraints = false
        
        if let displayView = displayView {
            view.addSubview(displayView)
            
            NSLayoutConstraint.activate([
                displayView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                displayView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                displayView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                displayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        // Add share button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareTapped)
        )
    }
    
    @objc private func shareTapped() {
        let activityVC = UIActivityViewController(activityItems: [jsonString], applicationActivities: nil)
        present(activityVC, animated: true)
    }
}
