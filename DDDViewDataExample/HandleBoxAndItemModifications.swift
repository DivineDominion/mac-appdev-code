import Cocoa

class HandleBoxAndItemModifications: HandlesItemListEvents {
    let provisioningService: ProvisioningService
    
    // This could be injected since it's needed for ProvisioningService setup
    // anyway. Since the ServiceLocator is easily available in this layer, 
    // there's no benefit architecture-wise.
    var repository: BoxRepository! {
        return ServiceLocator.boxRepository()
    }
    
    init(provisioningService: ProvisioningService) {
        self.provisioningService = provisioningService
    }
    
    func createBox() {
        provisioningService.provisionBox()
    }
    
    func createItem(_ boxId: BoxId) {
        guard let box = repository.box(boxId: boxId) else {
            return
        }
        
        provisioningService.provisionItem(inBox: box)
    }
        
    func changeBoxTitle(_ boxId: BoxId, title: String) {
        guard let box = repository.box(boxId: boxId) else {
            return
        }
        
        box.title = title
    }
    
    func changeItemTitle(_ itemId: ItemId, title: String, inBox boxId: BoxId) {
        guard let box = repository.box(boxId: boxId) else {
            return
        }
        
        // TODO add changeItemTitle()
        guard let item = box.item(itemId: itemId) else {
            return
        }

        item.title = title
    }
    
    func removeBox(_ boxId: BoxId) {
        repository.removeBox(boxId: boxId)
    }
    
    func removeItem(_ itemId: ItemId, fromBox boxId: BoxId) {
        guard let box = repository.box(boxId: boxId) else {
            return
        }
        
        box.removeItem(itemId: itemId)
    }
}
