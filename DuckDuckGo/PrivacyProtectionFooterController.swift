//
//  PrivacyProtectionFooterController.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import UIKit
import Core

class PrivacyProtectionFooterController: UIViewController {
    
    @IBOutlet weak var privacyProtectionView: UIView!
    @IBOutlet weak var privacyProtectionSwitch: UISwitch!
    @IBOutlet weak var leaderboard: TrackerNetworkLeaderboardView!

    fileprivate var domain: String?
    fileprivate var protectionStore: ContentBlockerProtectionStore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        leaderboard.didLoad()
        leaderboard.update()
    }
    
    @IBAction func toggleProtection() {
        guard let domain = domain else { return }
        let isProtected = privacyProtectionSwitch.isOn
        
        let window = UIApplication.shared.keyWindow
        window?.hideAllToasts()
        
        if isProtected {
            protectionStore.enableProtection(forDomain: domain)
            
            window?.showBottomToast(UserText.toastProtectionEnabled.format(arguments: domain), duration: 1)
        } else {
            protectionStore.disableProtection(forDomain: domain)
            
            window?.showBottomToast(UserText.toastProtectionDisabled.format(arguments: domain), duration: 1)
        }
        Pixel.fire(pixel: isProtected ? .privacyDashboardProtectionDisabled : .privacyDashboardProtectionEnabled)
    }

    private func update() {
        guard isViewLoaded else { return }
        leaderboard.update()
        updateProtectionToggle()
    }

    private func updateProtectionToggle() {
        let isProtected = protectionStore.isProtected(domain: domain)
        privacyProtectionSwitch.isOn = isProtected
        privacyProtectionView.backgroundColor = isProtected ? UIColor.ppGreen : UIColor.ppGray
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let unprotectedSitesController = segue.destination as? UnprotectedSitesViewController {
            prepareforSegue(to: unprotectedSitesController)
            return
        }
        
        if let navController = segue.destination as? UINavigationController,
            let brokenSiteScreen = navController.topViewController as? ReportBrokenSiteViewController {
            Pixel.fire(pixel: .privacyDashboardReportBrokenSite)
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                segue.destination.modalPresentationStyle = .formSheet
            }
            
            if let privacyProtectionScreen = parent?.parent as? PrivacyProtectionController {
                brokenSiteScreen.brokenSiteInfo = privacyProtectionScreen.privacyProtectionDelegate?.getCurrentWebsiteInfo()
            }
        }
    }
    
    private func prepareforSegue(to unprotectedSitesController: UnprotectedSitesViewController) {
        unprotectedSitesController.enforceLightTheme = true
        if isPad {
            unprotectedSitesController.showBackButton = true
        }
        Pixel.fire(pixel: .privacyDashboardManageProtection)
    }
}

extension PrivacyProtectionFooterController: PrivacyProtectionInfoDisplaying {

    func using(siteRating: SiteRating, protectionStore: ContentBlockerProtectionStore) {
        self.domain = siteRating.domain
        self.protectionStore = protectionStore
        update()
    }

}

class TrackerNetworkLeaderboardView: UIView {

    @IBOutlet weak var gatheringView: UIView!
    @IBOutlet weak var gatheringInfoLabel: UILabel!
    @IBOutlet weak var scoresView: UIView!

    @IBOutlet weak var firstPill: TrackerNetworkPillView!
    @IBOutlet weak var secondPill: TrackerNetworkPillView!
    @IBOutlet weak var thirdPill: TrackerNetworkPillView!

    var leaderboard = NetworkLeaderboard.shared

    func didLoad() {
        firstPill.didLoad()
        secondPill.didLoad()
        thirdPill.didLoad()
    }

    func update() {
        let networksDetected = leaderboard.networksDetected()
        let shouldShow = leaderboard.shouldShow()
        gatheringView.isHidden = shouldShow
        gatheringInfoLabel.setAttributedTextString(UserText.ppNetworkLeaderboardGatheringData)
        scoresView.isHidden = !shouldShow

        if shouldShow {
            let pagesVisited = leaderboard.pagesVisited()
            firstPill.update(network: networksDetected[0], pagesVisited: pagesVisited)
            secondPill.update(network: networksDetected[1], pagesVisited: pagesVisited)
            thirdPill.update(network: networksDetected[2], pagesVisited: pagesVisited)
        }
    }

}

class TrackerNetworkPillView: UIView {

    @IBOutlet weak var networkImage: UIImageView!
    @IBOutlet weak var percentageLabel: UILabel!

    func didLoad() {
        layer.cornerRadius = frame.size.height / 2
    }

    func update(network: PPTrackerNetwork, pagesVisited: Int) {
        let percent = 100 * Int(network.detectedOnCount) / pagesVisited
        let percentText = "\(percent)%"
        let image = network.image

        networkImage.image = image
        percentageLabel.text = percentText
    }

}

fileprivate extension PPTrackerNetwork {

    var image: UIImage {
        let name = TrackerDataManager.shared.findEntity(byName: self.name ?? "")?.displayName ?? ""
        let imageName = "PP Pill \(name.lowercased())"
        return UIImage(named: imageName) ?? #imageLiteral(resourceName: "PP Pill Generic")
    }

}
