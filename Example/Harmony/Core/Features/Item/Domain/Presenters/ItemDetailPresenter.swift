//
//  ItemDetailPresenter.swift
//  Harmony_Example
//
//  Created by Joan Martin on 22/3/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation

protocol ItemDetailPresenterView: AnyObject {
    func onDisplayItem(_ item: Item)
}

protocol ItemDetailPresenter {
    func onActionSelectedItem(_ item: Item)
}

class ItemDetailDefaultPresenter: ItemDetailPresenter {
    private weak var view: ItemDetailPresenterView?
    
    init(_ view: ItemDetailPresenterView) {
        self.view = view
    }
    
    func onActionSelectedItem(_ item: Item) {
        view?.onDisplayItem(item)
    }
}
