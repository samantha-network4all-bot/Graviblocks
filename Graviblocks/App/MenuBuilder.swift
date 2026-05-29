import AppKit

final class MenuBuilder {
    func build() {
        let app = NSApplication.shared
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        let appMenu = NSMenu(title: "Graviblocks")
        appMenu.addItem(withTitle: "Quit Graviblocks", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu

        // File menu
        let fileMenuItem = NSMenuItem()
        mainMenu.addItem(fileMenuItem)
        let fileMenu = NSMenu(title: "File")
        fileMenuItem.submenu = fileMenu

        // Game menu
        let gameMenuItem = NSMenuItem()
        mainMenu.addItem(gameMenuItem)
        let gameMenu = NSMenu(title: "Game")
        gameMenu.addItem(withTitle: "New Marathon", action: nil, keyEquivalent: "n")
        gameMenu.addItem(withTitle: "New Sprint", action: nil, keyEquivalent: "N")
        gameMenu.addItem(NSMenuItem.separator())
        gameMenu.addItem(withTitle: "Pause", action: nil, keyEquivalent: "p")
        gameMenu.addItem(withTitle: "Restart", action: nil, keyEquivalent: "r")
        gameMenuItem.submenu = gameMenu

        // View menu
        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        let viewMenu = NSMenu(title: "View")
        viewMenuItem.submenu = viewMenu

        app.mainMenu = mainMenu
    }
}
