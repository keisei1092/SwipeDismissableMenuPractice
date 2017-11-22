//
//  ViewController.swift
//  SwipeDismissableMenuPractice
//
//  Created by Keisei Saito on 2017/11/22.
//  Copyright © 2017 Keisei Saito. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CenterViewController: UIViewController {
    @IBOutlet weak var menuButton: UIBarButtonItem!

    let toggleMenuSubject = PublishSubject<Void>()
    let addMenuViewControllerSubject = PublishSubject<Void>()
    let animateMenuSubject = PublishSubject<Bool>() // shouldExpand: Bool

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup Menu Button
        let menuButton = UIBarButtonItem(title: "Menu", style: .plain, target: self, action: nil)
        menuButton.rx.tap.subscribe(onNext: { [weak self] _ in
            self?.toggleMenuSubject.on(.next())
        }).disposed(by: rx.disposeBag)
        navigationItem.leftBarButtonItem = menuButton
    }
}

