import Cocoa

@main
enum AppMain {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) {
            app.run()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindowController: MainWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.mainMenu = Self.makeMainMenu()
        let controller = MainWindowController(content: ContentViewController())
        mainWindowController = controller
        controller.showWindow(nil)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        if !hasVisibleWindows { mainWindowController?.showWindow(nil) }
        return true
    }

    private static func makeMainMenu() -> NSMenu {
        let appName = ProcessInfo.processInfo.processName

        func makeAppMenu() -> NSMenuItem {
            let item = NSMenuItem()
            let menu = NSMenu()
            item.submenu = menu

            let aboutItem = NSMenuItem(
                title: String(localized: "About \(appName)"),
                action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                keyEquivalent: ""
            )
            menu.addItem(aboutItem)
            menu.addItem(.separator())

            let hideItem = NSMenuItem(
                title: String(localized: "Hide \(appName)"),
                action: #selector(NSApplication.hide(_:)),
                keyEquivalent: "h"
            )
            menu.addItem(hideItem)

            let hideOthersItem = NSMenuItem(
                title: String(localized: "Hide Others"),
                action: #selector(NSApplication.hideOtherApplications(_:)),
                keyEquivalent: "h"
            )
            hideOthersItem.keyEquivalentModifierMask = [.command, .option]
            menu.addItem(hideOthersItem)

            let showAllItem = NSMenuItem(
                title: String(localized: "Show All"),
                action: #selector(NSApplication.unhideAllApplications(_:)),
                keyEquivalent: ""
            )
            menu.addItem(showAllItem)
            menu.addItem(.separator())

            let quitItem = NSMenuItem(
                title: String(localized: "Quit \(appName)"),
                action: #selector(NSApplication.terminate),
                keyEquivalent: "q"
            )
            quitItem.keyEquivalentModifierMask = [.command]
            menu.addItem(quitItem)

            return item
        }

        func makeEditMenu() -> NSMenuItem {
            let item = NSMenuItem()
            let menu = NSMenu(title: String(localized: "Edit"))
            item.submenu = menu
            menu.addItem(withTitle: String(localized: "Undo"), action: Selector(("undo:")), keyEquivalent: "z")
            menu.addItem(withTitle: String(localized: "Redo"), action: Selector(("redo:")), keyEquivalent: "Z")
            menu.addItem(.separator())
            menu.addItem(withTitle: String(localized: "Cut"), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
            menu.addItem(withTitle: String(localized: "Copy"), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
            menu.addItem(withTitle: String(localized: "Paste"), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
            menu.addItem(withTitle: String(localized: "Delete"), action: #selector(NSText.delete(_:)), keyEquivalent: "")
            menu.addItem(withTitle: String(localized: "Select All"), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
            return item
        }

        func makeViewMenu() -> NSMenuItem {
            let item = NSMenuItem()
            let menu = NSMenu(title: String(localized: "View"))
            item.submenu = menu
            let toggleSidebarItem = NSMenuItem(
                title: String(localized: "Toggle Sidebar"),
                action: #selector(NSSplitViewController.toggleSidebar(_:)),
                keyEquivalent: "s"
            )
            toggleSidebarItem.keyEquivalentModifierMask = [.command, .control]
            menu.addItem(toggleSidebarItem)
            return item
        }

        func makeWindowMenu() -> NSMenuItem {
            let item = NSMenuItem()
            let menu = NSMenu(title: String(localized: "Window"))
            item.submenu = menu
            menu.addItem(withTitle: String(localized: "Close"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
            menu.addItem(
                withTitle: String(localized: "Minimize"),
                action: #selector(NSWindow.performMiniaturize(_:)),
                keyEquivalent: "m"
            )
            menu.addItem(withTitle: String(localized: "Zoom"), action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
            menu.addItem(.separator())
            menu.addItem(
                withTitle: String(localized: "Bring All to Front"),
                action: #selector(NSApplication.arrangeInFront(_:)),
                keyEquivalent: ""
            )
            // Lets macOS append the list of open windows and its own window commands.
            NSApplication.shared.windowsMenu = menu
            return item
        }

        func makeHelpMenu() -> NSMenuItem {
            let item = NSMenuItem()
            let menu = NSMenu(title: String(localized: "Help"))
            item.submenu = menu
            // Lets macOS add the menu search field.
            NSApplication.shared.helpMenu = menu
            return item
        }

        let mainMenu = NSMenu()
        mainMenu.addItem(makeAppMenu())
        mainMenu.addItem(makeEditMenu())
        mainMenu.addItem(makeViewMenu())
        mainMenu.addItem(makeWindowMenu())
        mainMenu.addItem(makeHelpMenu())
        return mainMenu
    }
}

final class MainWindowController: NSWindowController, NSToolbarDelegate {
    init(content: NSViewController) {
        let window = NSWindow(contentViewController: content)
        window.title = String(localized: "AppKit Template")
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView]
        window.isReleasedWhenClosed = false
        super.init(window: window)
        shouldCascadeWindows = false

        let toolbar = NSToolbar(identifier: "MainToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly

        window.toolbar = toolbar
        window.toolbarStyle = .unified
        window.contentMinSize = .init(width: 640, height: 480)

        let frameName = String(describing: Self.self)
        if !window.setFrameUsingName(frameName) {
            window.setContentSize(NSSize(width: 900, height: 600))
            window.center()
        }
        window.setFrameAutosaveName(frameName)
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.toggleSidebar, .sidebarTrackingSeparator, .flexibleSpace]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarDefaultItemIdentifiers(toolbar)
    }

    func toolbar(
        _ toolbar: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? { nil }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class ContentViewController: NSSplitViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        splitView.isVertical = true

        let sidebarViewController = SidebarViewController()
        let sidebar = NSSplitViewItem(sidebarWithViewController: sidebarViewController)
        sidebar.minimumThickness = 240
        sidebar.maximumThickness = 300
        sidebar.canCollapse = true
        addSplitViewItem(sidebar)

        let detail = LabelViewController(label: "")
        let detailItem = NSSplitViewItem(viewController: detail)
        addSplitViewItem(detailItem)

        sidebarViewController.onSelect = { title in
            detail.label = title
        }

        // This needs to be set after finishing up adding the items to make it work.
        splitView.autosaveName = String(describing: Self.self)
    }
}

final class SidebarViewController: NSViewController, NSOutlineViewDelegate, NSOutlineViewDataSource {
    private struct Item {
        let title: String
        let children: [Item]
    }

    private let sections = [
        Item(
            title: String(localized: "Section 1"),
            children: [
                Item(title: String(localized: "Item 1"), children: []),
                Item(title: String(localized: "Item 2"), children: []),
            ]
        ),
        Item(
            title: String(localized: "Section 2"),
            children: [
                Item(title: String(localized: "Item 3"), children: []),
                Item(title: String(localized: "Item 4"), children: []),
            ]
        ),
    ]

    private let outlineView = NSOutlineView(frame: .zero)
    var onSelect: ((String) -> Void)?

    override func loadView() {
        let scrollView = NSScrollView(frame: .zero)
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.headerView = nil
        outlineView.style = .sourceList
        outlineView.floatsGroupRows = false
        outlineView.rowHeight = 28
        outlineView.autoresizingMask = [.width]
        outlineView.delegate = self
        outlineView.dataSource = self

        scrollView.documentView = outlineView
        view = scrollView
    }

    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item as? Item else { return sections.count }
        return item.children.count
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let item = item as? Item else { return true }
        return !item.children.isEmpty
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item = item as? Item else { return sections[index] }
        return item.children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let item = item as? Item else { return nil }
        let identifier = NSUserInterfaceItemIdentifier("SidebarCell")
        let cell = outlineView.makeView(withIdentifier: identifier, owner: self) as? NSTableCellView ?? NSTableCellView()
        cell.identifier = identifier

        if cell.textField == nil {
            let textField = NSTextField(labelWithString: "")
            textField.translatesAutoresizingMaskIntoConstraints = false
            cell.addSubview(textField)
            cell.textField = textField
            NSLayoutConstraint.activate([
                textField.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
                textField.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
                textField.centerYAnchor.constraint(equalTo: cell.centerYAnchor),
            ])
        }

        cell.textField?.stringValue = item.title
        cell.textField?.font = item.children.isEmpty ? .systemFont(ofSize: 13) : .boldSystemFont(ofSize: 11)
        return cell
    }

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        guard let item = item as? Item else { return false }
        return !item.children.isEmpty
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let item = item as? Item else { return false }
        return item.children.isEmpty
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let item = outlineView.item(atRow: outlineView.selectedRow) as? Item else { return }
        onSelect?(item.title)
    }
}

final class LabelViewController: NSViewController {
    private let textField = NSTextField(labelWithString: "")
    var label: String {
        didSet { textField.stringValue = label }
    }

    init(label: String) {
        self.label = label
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        textField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textField)
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
