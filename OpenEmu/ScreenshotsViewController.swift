// Copyright (c) 2019, OpenEmu Team
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above copyright
//       notice, this list of conditions and the following disclaimer in the
//       documentation and/or other materials provided with the distribution.
//     * Neither the name of the OpenEmu Team nor the
//       names of its contributors may be used to endorse or promote products
//       derived from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
// DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import Cocoa

@objc
class ScreenshotsViewController: NSViewController {
    
    @objc
    weak public var libraryController: OELibraryController!
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    var searchPredicate = NSPredicate(value: true)
    var shouldShowBlankSlate = false
    var searchKeys = ["rom.game.gameTitle", "rom.game.name", "rom.game.system.lastLocalizedName", "name", "userDescription"]
    var currentSearchTerm = ""
    
    // data
    
    var items = [[OEDBScreenshot]]()
    var source: OEDBScreenshotsMedia?
    
    override var representedObject: Any? {
        willSet {
            precondition(newValue == nil || newValue is OEDBScreenshotsMedia, "unexpected object")
            source = newValue as? OEDBScreenshotsMedia
        }
        didSet {
            let _ = self.view
        }
    }
    
    override var nibName: NSNib.Name? {
        return NSNib.Name("ScreenshotsViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        reloadData()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        setupToolbar()
        restoreSelectionFromDefaults()
    }
    
    func setupToolbar() {
        guard let toolbar = libraryController.toolbar else { return }
        
        toolbar.viewSelector.isEnabled = false
        toolbar.gridSizeSlider.isEnabled = false
        
        if let field = toolbar.searchField {
            field.searchMenuTemplate = nil
            field.stringValue = currentSearchTerm
        }
    }
    
    func restoreSelectionFromDefaults() {
        // TODO: implement
        
    }
    
    func updateBlankSlate() {
        // TODO: implement
    }
}

extension ScreenshotsViewController: OELibrarySubviewController {
    
}

extension NSUserInterfaceItemIdentifier {
    static let screenshotsViewItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "CollectionViewItem")
    static let screenshotsHeaderViewItemIdentifier = NSUserInterfaceItemIdentifier(rawValue: "HeaderView")
}

extension ScreenshotsViewController: NSCollectionViewDataSource {
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return items.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return items[section].count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let itemView = collectionView.makeItem(withIdentifier: .screenshotsViewItemIdentifier, for: indexPath) as! CollectionViewItem
        
        let item = items[indexPath.section][indexPath.item]
        itemView.representedObject = item
        itemView.textField?.stringValue = item.name ?? ""
        itemView.imageFile = ImageFile(url: item.url as URL)
        
        return itemView
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        if kind == NSCollectionView.elementKindInterItemGapIndicator {
          return NSView(frame: NSRect(x: 0, y: 0, width: 1, height: 1))
        }
        
        let identifier: String = kind == NSCollectionView.elementKindSectionHeader ? "HeaderView" : ""
        let view = collectionView.makeSupplementaryView(ofKind: kind, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier), for: indexPath)

        if kind == NSCollectionView.elementKindSectionHeader {
            let game = items[indexPath.section].first!.rom!.game!
            let headerView = view as! HeaderView
            headerView.sectionTitle.stringValue = game.displayName!
            headerView.imageCount.stringValue = game.system!.name
        }
        return view
    }
    
    func fetchItems() {
        guard let ctx = OELibraryDatabase.default?.mainThreadContext else { return }
        
        items = []
        
        let req = NSFetchRequest<OEDBRom>(entityName: OEDBRom.entityName())
        req.entity = NSEntityDescription.entity(forEntityName: OEDBRom.entityName(), in: ctx)
        
        let count = try? ctx.count(for: req)
        if count == .none || count! == 0 {
            shouldShowBlankSlate = true
            updateBlankSlate()
            return
        }
        
        req.sortDescriptors = [NSSortDescriptor(key: "game.name", ascending: true)]
        req.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [NSPredicate(format: "screenShots.@count > 0"), searchPredicate])
        
        let base = Date(timeIntervalSince1970: 0)
        
        guard let res = try? ctx.fetch(req) else { return }
        for item in res {
            if let shots = item.screenShots {
                let sorted = shots.sorted { (a, b) -> Bool in
                    let tsa = a.timestamp ?? base
                    let tsb = b.timestamp ?? base
                    return tsa < tsb
                }
                items.append(sorted)
            }
        }
    }
    
    func reloadData() {
        precondition(Thread.isMainThread, "should only be called on main thread")
        
        fetchItems()
        
        collectionView.reloadData()
    }
}

extension ScreenshotsViewController: NSCollectionViewDelegate {
    
}
