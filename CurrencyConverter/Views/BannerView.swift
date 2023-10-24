//
//  Banner.swift
//  CurrencyConverter
//
//  Created by Kirill Kirilenko on 01/05/2023.
//

import GoogleMobileAds
import SwiftUI

protocol BannerViewControllerWidthDelegate: AnyObject {
    func bannerViewController(
        _ bannerViewController: BannerViewController,
        didUpdate width: CGFloat
    )
}

class BannerViewController: UIViewController {
    weak var delegate: BannerViewControllerWidthDelegate?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        delegate?.bannerViewController(
            self,
            didUpdate: view.frame.inset(by: view.safeAreaInsets).size.width
        )
    }

    override func viewWillTransition(
        to _: CGSize,
        with coordinator: UIViewControllerTransitionCoordinator
    ) {
        coordinator.animate { _ in } completion: { _ in
            self.delegate?.bannerViewController(
                self,
                didUpdate: self.view.frame.inset(by: self.view.safeAreaInsets).size.width
            )
        }
    }
}

struct BannerView: UIViewControllerRepresentable {
    @State var viewWidth: CGFloat = .zero
    private let bannerView = GADBannerView()
    private let adUnitID = "ca-app-pub-4204494162411871/5053256130"

    func makeUIViewController(context _: Context) -> some UIViewController {
        let bannerViewController = BannerViewController()
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = bannerViewController
        bannerViewController.view.addSubview(bannerView)

        return bannerViewController
    }

    func updateUIViewController(_: UIViewControllerType, context _: Context) {
        guard viewWidth != .zero else { return }

        bannerView.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        bannerView.load(GADRequest())
    }
}
