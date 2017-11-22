//
//  ContainerViewController.swift
//  SwipeDismissableMenuPractice
//
//  Created by Keisei Saito on 2017/11/22.
//  Copyright © 2017 Keisei Saito. All rights reserved.
//

import UIKit
import RxSwift
import NSObject_Rx

class ContainerViewController: UIViewController {
    enum MenuState {
        case collapsed
        case expanded
    }

    let centerPanelExpandedOffset: CGFloat = 60

    var currentState: MenuState = .collapsed
    var menuViewController: MenuViewController?

    var centerNavigationController: UINavigationController!
    var centerViewController: CenterViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        centerViewController = UIStoryboard.centerViewController()

        centerNavigationController = UINavigationController(rootViewController: centerViewController)
        view.addSubview(centerNavigationController.view)
        addChildViewController(centerNavigationController)

        centerNavigationController.didMove(toParentViewController: self)

        centerViewController.toggleMenuSubject.subscribe(onNext: { [weak self] in
            let notAlreadyExpanded = (self?.currentState != .expanded)

            if notAlreadyExpanded {
                self?.addMenuViewController()
            }

            self?.animateMenu(shouldExpand: notAlreadyExpanded)
        }).disposed(by: rx.disposeBag)

        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.rx.event.bind(onNext: { [weak self] recognizer in
            guard let `self` = self else { return }

            let gestureIsDraggingFromLeftToRight = (recognizer.velocity(in: self.view).x > 0)

            switch recognizer.state {
            case .began:
                if self.currentState == .collapsed {
                    if gestureIsDraggingFromLeftToRight {
                        self.addMenuViewController()
                    }
                }
            case .changed:
                if let rview = recognizer.view {
                    guard
                        self.currentState == .expanded
                        || (self.currentState == .collapsed && gestureIsDraggingFromLeftToRight)
                    else { return }

                    rview.center.x = rview.center.x + recognizer.translation(in: self.view).x
                    recognizer.setTranslation(CGPoint.zero, in: self.view)
                }
            case .ended:
                if let _ = self.menuViewController,
                    let rview = recognizer.view {
                    // animate the side panel open or closed based on whether the view
                    // has moved more or less than halfway
                    let hasMovedGreaterThanHalfway = rview.center.x > self.view.bounds.size.width
                    self.animateMenu(shouldExpand: hasMovedGreaterThanHalfway)

                }
            default: break
            }
        }).disposed(by: rx.disposeBag)
        centerNavigationController.view.addGestureRecognizer(panGestureRecognizer)
    }

    func addMenuViewController() {
        guard menuViewController == nil else { return }

        if let vc = UIStoryboard.menuViewController() {
            addChildMenuViewController(vc)
            menuViewController = vc
        }
    }

    func addChildMenuViewController(_ menuViewController: MenuViewController) {
        view.insertSubview(menuViewController.view, at: 0)

        addChildViewController(menuViewController)
        menuViewController.didMove(toParentViewController: self)

        let panGestureRecognizer = UIPanGestureRecognizer()
        panGestureRecognizer.rx.event.bind(onNext: { [weak self] recognizer in
            guard let `self` = self else { return }

            let gestureIsDraggingFromRightToLeft = (recognizer.velocity(in: self.menuViewController!.view).x <= 0)

            switch recognizer.state {
            case .began: break
            case .changed:
                if let rview = recognizer.view, gestureIsDraggingFromRightToLeft, recognizer.velocity(in: self.menuViewController!.view).x != 0 {
                    rview.center.x = rview.center.x + recognizer.translation(in: self.menuViewController!.view).x
                    self.centerNavigationController!.view.frame.origin.x = self.centerNavigationController!.view.frame.origin.x + recognizer.translation(in: self.menuViewController!.view).x
                    recognizer.setTranslation(CGPoint.zero, in: self.menuViewController!.view)
                }
            case .ended:
                if !gestureIsDraggingFromRightToLeft {
                    self.animateMenu(shouldExpand: true)
                } else if let rview = recognizer.view {
                    // animate the side panel open or closed based on whether the view
                    // has moved more or less than halfway
                    let hasMovedGreaterThanHalfway = rview.center.x > 0
                    self.animateMenu(shouldExpand: hasMovedGreaterThanHalfway)
                }
            default: break
            }
        }).disposed(by: rx.disposeBag)
        menuViewController.view.addGestureRecognizer(panGestureRecognizer)
    }

    func animateMenu(shouldExpand: Bool) {
        if shouldExpand {
            currentState = .expanded
            animateCenterPanelXPosition(
                targetPosition: centerNavigationController.view.frame.width - centerPanelExpandedOffset)
        } else {
            animateCenterPanelXPosition(targetPosition: 0) { finished in
                self.currentState = .collapsed
                self.menuViewController?.view.removeFromSuperview()
                self.menuViewController = nil
            }
        }
    }

    func animateCenterPanelXPosition(targetPosition: CGFloat, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.5,
                       delay: 0,
                       usingSpringWithDamping: 1,
                       initialSpringVelocity: 0,
                       options: .curveEaseInOut, animations: {
            self.centerNavigationController.view.frame.origin.x = targetPosition
            self.menuViewController?.view.frame.origin.x = -self.centerPanelExpandedOffset
        }, completion: completion)
    }
}

private extension UIStoryboard {

    static func main() -> UIStoryboard { return UIStoryboard(name: "Main", bundle: Bundle.main) }

    static func menuViewController() -> MenuViewController? {
        return main().instantiateViewController(withIdentifier: "MenuViewController") as? MenuViewController
    }

    static func centerViewController() -> CenterViewController? {
        return main().instantiateViewController(withIdentifier: "CenterViewController") as? CenterViewController
    }
}
