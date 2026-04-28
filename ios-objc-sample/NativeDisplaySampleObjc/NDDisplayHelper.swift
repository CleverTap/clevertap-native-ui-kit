//
//  NDDisplayHelper.swift
//  NativeDisplaySampleObjc
//
//  Swift bridge providing @objc-compatible factory methods for creating
//  NativeDisplayUIView instances from JSON data. ObjC files import this
//  via #import "NativeDisplaySampleObjc-Swift.h".
//

import Foundation
import UIKit
import CleverTapNativeDisplay

/// ObjC-accessible factory for creating NativeDisplayUIView instances from JSON data.
@objc public class NDDisplayHelper: NSObject {

    /// Create a NativeDisplayUIView from JSON data with optional listeners.
    @objc public static func createView(
        from jsonData: Data,
        parentWidth: CGFloat,
        componentListener: NativeDisplayComponentListener?,
        actionListener: NativeDisplayActionListener?,
        error: NSErrorPointer
    ) -> NativeDisplayUIView? {
        do {
            let config = try ResolvedConfig.from(jsonData: jsonData)
            let parentSize: CGSize? = parentWidth > 0 ? CGSize(width: parentWidth - 32, height: 0) : nil
            return NativeDisplayUIView(
                config: config,
                parentSize: parentSize,
                actionListener: actionListener,
                componentListener: componentListener
            )
        } catch let err as NSError {
            error?.pointee = err
            return nil
        }
    }

    /// Create a NativeDisplayUIView from JSON data with an arrangement strategy override.
    @objc public static func createView(
        from jsonData: Data,
        parentWidth: CGFloat,
        arrangementStrategy: String,
        componentListener: NativeDisplayComponentListener?,
        actionListener: NativeDisplayActionListener?,
        error: NSErrorPointer
    ) -> NativeDisplayUIView? {
        do {
            var config = try ResolvedConfig.from(jsonData: jsonData)

            // Map strategy string to ArrangementStrategy enum
            let strategy: ArrangementStrategy
            switch arrangementStrategy {
            case "space_between": strategy = .spaceBetween
            case "space_evenly":  strategy = .spaceEvenly
            case "space_around":  strategy = .spaceAround
            case "start":         strategy = .start
            case "center":        strategy = .center
            case "end":           strategy = .end
            default:              strategy = .spaced
            }

            // Update root container arrangement
            if case .container(let container) = config.root {
                let spacing: CGFloat? = strategy == .spaced ? 16 : nil
                let newArrangement = ChildArrangement(spacing: spacing, spacingUnit: .dp, strategy: strategy)
                let updatedLayout = Layout(
                    width: container.layout?.width,
                    height: container.layout?.height,
                    offset: container.layout?.offset,
                    padding: container.layout?.padding,
                    arrangement: newArrangement
                )
                let updatedContainer = NativeDisplayContainer(
                    id: container.id,
                    containerType: container.containerType,
                    children: container.children,
                    layout: updatedLayout,
                    style: container.style,
                    styleClass: container.styleClass,
                    visible: container.visible,
                    actions: container.actions,
                    animation: container.animation,
                    galleryConfig: container.galleryConfig,
                    dividerConfig: container.dividerConfig
                )
                config = ResolvedConfig(
                    theme: config.theme,
                    styleClasses: config.styleClasses,
                    variables: config.variables,
                    root: .container(updatedContainer)
                )
            }

            let parentSize: CGSize? = parentWidth > 0 ? CGSize(width: parentWidth - 32, height: 0) : nil
            return NativeDisplayUIView(
                config: config,
                parentSize: parentSize,
                actionListener: actionListener,
                componentListener: componentListener
            )
        } catch let err as NSError {
            error?.pointee = err
            return nil
        }
    }

    /// Load JSON data from the bundle, searching multiple directory paths.
    @objc public static func loadJSONData(filename: String, directory: String?) -> Data? {
        let bundle = Bundle.main
        var paths: [String?] = []
        if let dir = directory {
            paths.append(bundle.path(forResource: filename, ofType: "json", inDirectory: dir))
            paths.append(bundle.path(forResource: filename, ofType: "json", inDirectory: "Resources/\(dir)"))
        }
        paths.append(bundle.path(forResource: filename, ofType: "json"))

        for path in paths {
            if let p = path, let data = try? Data(contentsOf: URL(fileURLWithPath: p)) {
                return data
            }
        }
        return nil
    }

    /// Discover all test-NNN-*.json files in the TestConfigs folder (and bundle root as fallback).
    @objc public static func discoverTestFiles() -> [String] {
        guard let resourcePath = Bundle.main.resourcePath else { return [] }
        let fm = FileManager.default
        var seen = Set<String>()
        var results: [String] = []

        func collect(from dirPath: String) {
            guard let files = try? fm.contentsOfDirectory(atPath: dirPath) else { return }
            for file in files where file.hasPrefix("test-") && file.hasSuffix(".json") {
                let name = (file as NSString).deletingPathExtension
                if seen.insert(name).inserted { results.append(name) }
            }
        }

        collect(from: (resourcePath as NSString).appendingPathComponent("TestConfigs"))
        collect(from: resourcePath)
        return results.sorted()
    }
}
