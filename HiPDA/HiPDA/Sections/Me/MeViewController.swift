//
//  MeViewController.swift
//  HiPDA
//
//  Created by leizh007 on 16/9/3.
//  Copyright © 2016年 HiPDA. All rights reserved.
//

import UIKit
import SDWebImage

private enum SectionType: Int {
    case account
    case action
    case settings
}

/// 我的ViewController
class MeViewController: UITableViewController {
    /// 头像
    @IBOutlet private weak var avatarImageView: UIImageView!
    
    /// 用户名
    @IBOutlet private weak var nameLabel: UILabel!
    
    /// uid
    @IBOutlet private weak var uidLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "个人中心"
        
        avatarImageView.layer.borderWidth = 1.0 / C.UI.screenScale
        avatarImageView.layer.borderColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1).cgColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let account = Settings.shared.activeAccount else { return }
        avatarImageView.sd_setImage(with: account.avatarImageURL, placeholderImage: #imageLiteral(resourceName: "avatar_placeholder"))
        nameLabel.text = account.name
        uidLabel.text = "UID: \(account.uid)"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    fileprivate func showAccountProfile() {
        guard let account = Settings.shared.activeAccount else { return }
        let vc = UserProfileViewController.load(from: .home)
        vc.uid = account.uid
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - UITableViewDelegate

extension MeViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case SectionType.account.rawValue:
            showAccountProfile()
        default:
            break
        }
    }
}
