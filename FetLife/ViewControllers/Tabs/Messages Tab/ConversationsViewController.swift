//
//  ConversationsViewController.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/2/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit
import StatefulViewController
import UserNotifications
import RealmSwift

class ConversationsViewController: UIViewController, StatefulViewController, UITableViewDataSource, UITableViewDelegate, UISplitViewControllerDelegate {
    
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inboxSelector: UISegmentedControl!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var updateLabel: UILabel!
    
    var detailViewController: MessagesTableViewController?
    var refreshControl = UIRefreshControl()
    var mainTabController: MainTabViewController!
    var lastUpdated: Date {
        get {
            return AppSettings.lastUpdated
        }
        set(val) {
            AppSettings.lastUpdated = val
            if let ul = updateLabel {
                dateFormatter.dateStyle = (val.hoursFromNow >= 24) ? .short : .none
                ul.text = "Last updated: \(dateFormatter.string(from: val))"
            }
        }
    }
    let dateFormatter = DateFormatter()
    var havingConnectionIssue = false
    var updateTimer = Timer()
    
    let UPDATE_INTERVAL: Double = 20
    let BACKGROUND_UPDATE_INTERVAL: Double = 60
    
    var inbox: Results<Conversation> {
        get {
            return try! Realm()
                .objects(Conversation.self)
                .filter("isArchived == false")
                .sorted(byKeyPath: "lastMessageCreated", ascending: false)
        }
    }
    var allConversations: Results<Conversation> {
        get {
            return try! Realm()
                .objects(Conversation.self)
                .filter("isArchived == true")
                .sorted(byKeyPath: "lastMessageCreated", ascending: false)
        }
    }
    var conversations: Results<Conversation>!
    
    var notificationToken: NotificationToken? = nil
    
    fileprivate var collapseDetailViewController = true
    
    var showArchived: Bool { get { return inboxSelector.selectedSegmentIndex == 1 } }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        inboxSelector.selectedSegmentIndex = AppSettings.lastSelectedMailbox
        if let tbc = self.tabBarController {
            mainTabController = tbc as? MainTabViewController
        } else {
            mainTabController = storyboard!.instantiateViewController(withIdentifier: "vcMain") as? MainTabViewController
        }
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        
        // setting conversation value here (rather than in file declaration) to allow time for Realm setup and migration if necessary
        let filter = inboxSelector.selectedSegmentIndex == 0 ? "isArchived == false" : "isArchived == true"
        conversations = try! Realm()
            .objects(Conversation.self)
            .filter(filter)
            .sorted(byKeyPath: "lastMessageCreated", ascending: false)
        
        setupStateViews()
        
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        dateFormatter.locale = .current
        
        updateLabel.backgroundColor = UIColor.backgroundColor()
        Connectivity.sharedInstance.listener = { status in
            print("Network status changed: \(status)")
            self.networkStatusChanged()
        }
        Connectivity.apiReachabilityMgr.listener = { status in
            print("API network status changed: \(status)")
            self.networkStatusChanged()
        }
        
        self.refreshControl.addTarget(self, action: #selector(ConversationsViewController.refresh(_:)), for: UIControlEvents.valueChanged)
        
        self.splitViewController?.delegate = self
        
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.separatorInset = UIEdgeInsets.zero
        self.tableView?.addSubview(refreshControl)
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? MessagesTableViewController
        }
        
        notificationToken = conversations.observe({ [weak self] (changes: RealmCollectionChange) in
            guard let tv: UITableView = self?.tableView else { return }
            
            switch changes {
            case .initial(let conversations):
                if conversations.count > 0 {
                    tv.reloadData()
                }
                break
            case .update(_, _, _, _):
//                print("Deletions: \(deletions)")
//                print("Insertions: \(insertions)")
//                print("Modifications: \(modifications)")
                //              tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                //				let d = (deletions.filter { $0 < tableView.numberOfRows(inSection: 0) }).map { IndexPath(row: $0, section: 0) }
                //				print("deleting \(d.count) row(s)")
                //				tableView.deleteRows(at: d, with: .automatic)
                //				if deletions.count > 0 || insertions.count > 0 {
                tv.reloadData()
                //				} else if modifications.count > 0 {
                //					tv.beginUpdates()
                //					let m = (modifications.filter { $0 < tv.numberOfRows(inSection: 0) }).map { IndexPath(row: $0, section: 0) }
                //					print("modifying \(m.count) row(s)")
                //					tv.reloadRows(at: m, with: .none)
                //					tv.endUpdates()
                //				}
                break
            case .error:
                print("Error updating table")
                break
            }
            self?.getUnreadCount()
        })
        
        if conversations.isEmpty {
            self.startLoading()
        }
        
        self.fetchConversations()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // FIXME: - This is stupidly inefficient and should be fixed with push notifications as soon as possible!
        if !updateTimer.isValid {
            updateTimer = Timer.scheduledTimer(timeInterval: UPDATE_INTERVAL, target: self, selector: #selector(fetchConversationsInBackground), userInfo: nil, repeats: true)
            updateTimer.tolerance = 10
        } else if updateTimer.timeInterval != UPDATE_INTERVAL {
            updateTimer.invalidate()
            updateTimer = Timer.scheduledTimer(timeInterval: UPDATE_INTERVAL, target: self, selector: #selector(fetchConversationsInBackground), userInfo: nil, repeats: true)
            updateTimer.tolerance = 10
        }
        tableView.reloadData()
        Dispatch.delay(0.5) { // add a delay to allow network to initialize
            Connectivity.sharedInstance.startListening()
        }
        
        // fix hung refresh animation
        if refreshControl.isRefreshing { refreshControl.beginRefreshing() } else { refreshControl.endRefreshing() }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        updateTimer.invalidate()
        updateTimer = Timer.scheduledTimer(timeInterval: BACKGROUND_UPDATE_INTERVAL, target: self, selector: #selector(fetchConversationsInBackground), userInfo: nil, repeats: true)
        updateTimer.tolerance = 20
    }
    
    deinit {
        notificationToken?.invalidate()
        updateTimer.invalidate()
        Connectivity.sharedInstance.stopListening()
        Connectivity.apiReachabilityMgr.stopListening()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupInitialViewState()
        
        dateFormatter.dateStyle = (lastUpdated.hoursFromNow >= 24) ? .short : .none
        updateLabel.text = "Last updated: \(dateFormatter.string(from: lastUpdated))"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            var conversation: Conversation!
            if let s = sender {
                if let _ = s as? UITableViewCell {
                    let indexPath = self.tableView.indexPathForSelectedRow ?? IndexPath(row: (sender as! ConversationCell).index, section: 0)
                    if self.splitViewController?.displayMode == UISplitViewControllerDisplayMode.primaryHidden {
                        self.tableView.deselectRow(at: indexPath, animated: true)
                    }
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    conversation = conversations[indexPath.row]
                } else if let c = s as? Conversation {
                    conversation = c
                }
            }
            let controller: MessagesTableViewController = (segue.destination as! UINavigationController).topViewController as! MessagesTableViewController
            controller.conversation = conversation
            controller.navCon = controller
            controller.navigationItem.title = "\(conversation.member!.nickname) ‣"
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            controller.conversationId = conversation.id
        }
    }
    
    func refresh(_ refreshControl: UIRefreshControl) {
        fetchConversations()
    }
    
    func fetchConversations() {
        guard API.isAuthorized() else {
            self.dismiss(animated: false, completion: nil)
//            self.dismiss(animated: false, completion: nil)
            refreshControl.endRefreshing()
            return
        }
                    // TODO: show empty view if in split screen
                    UIApplication.shared.applicationIconBadgeNumber = 0 // no unread conversations
                }
        
//        let lastMessageDate: Date = ((conversations ?? inbox)[0]).lastMessageCreated
        API.sharedInstance.loadConversations() { error in
            self.endLoading(error: error)
            if error != nil && Connectivity.canReachAPI {
                self.updateStatus("Error updating conversations", withColor: UIColor.red)
                self.havingConnectionIssue = true
            } else if self.havingConnectionIssue {
                self.updateStatus("Successfully updated conversations", withColor: UIColor.statusOKColor())
                self.havingConnectionIssue = false
                self.lastUpdated = Date()
            } else {
                self.lastUpdated = Date()
            }
            self.refreshControl.endRefreshing()
            if !self.hasContent() {
                // TODO: show empty view if in split screen
                app.applicationIconBadgeNumber = 0 // no unread conversations
            }
//            let newLastDate: Date = ((self.conversations ?? self.inbox)[0]).lastMessageCreated
//            if lastMessageDate != newLastDate {
//                self.endLoading(error: error)
//            }
        }
    }
    
    func fetchConversationsInBackground() {
                if let e = error {
                    print("Error loading conversations: \(e)")
                if !self.hasContent() {
                    // TODO: show empty view if in split screen
                    UIApplication.shared.applicationIconBadgeNumber = 0 // no unread conversations
                }
        guard API.isAuthorized() else { print("Not authorized!"); return }
        print("Fetching conversations in the background...")
//        guard (conversations ?? inbox).count > 0 else { return }
        
//        let lastMessageDate: Date = ((conversations ?? inbox)[0]).lastMessageCreated
        API.sharedInstance.loadConversations() { error in
            if let e = error {
                guard Connectivity.canReachAPI else { return }
                print("Error loading conversations: \(e.localizedDescription)")
                self.updateStatus("Error updating conversations", withColor: UIColor.red)
                self.havingConnectionIssue = true
            } else if self.havingConnectionIssue {
                self.updateStatus("Successfully updated conversations", withColor: UIColor.statusOKColor())
                self.havingConnectionIssue = false
                self.lastUpdated = Date()
            } else {
                self.lastUpdated = Date()
            }
//            let newLastDate: Date = ((self.conversations ?? self.inbox)[0]).lastMessageCreated
//            if lastMessageDate != newLastDate {
//                self.endLoading(error: error)
//            }
            if !self.hasContent() {
                // TODO: show empty view if in split screen
                app.applicationIconBadgeNumber = 0 // no unread conversations
            }
        }
    }
    
    func getUnreadCount() {
        guard API.isAuthorized() else {
//            self.dismiss(animated: false, completion: nil)
            return
        }
        // FIXME: - If there is an existing notification, opening the app will show another notification once conversations are updated
        let unreadConversations: [Conversation] = inbox.filter({ (c: Conversation) -> Bool in
            return c.hasNewMessages
        }).sorted(by: { (a, b) -> Bool in
            return a.lastMessageCreated < b.lastMessageCreated
        })
        let unreadConversationCount = unreadConversations.count
        if unreadConversationCount != 0 {
            let backItem = UIBarButtonItem()
            backItem.title = "Back (\(unreadConversationCount))"
            navigationItem.backBarButtonItem = backItem
        } else {
            navigationItem.backBarButtonItem = nil
        }
        if unreadConversationCount > 0 {
            inboxSelector.setTitle("Inbox (\(unreadConversationCount))", forSegmentAt: 0)
        } else {
            inboxSelector.setTitle("Inbox", forSegmentAt: 0)
        }
        let unreadArchiveCount: Int = self.allConversations.filter({ (c: Conversation) -> Bool in
            return c.hasNewMessages
        }).count
        if unreadArchiveCount > 0 {
            inboxSelector.setTitle("Archived (\(unreadArchiveCount))", forSegmentAt: 1)
        } else {
            inboxSelector.setTitle("Archived", forSegmentAt: 1)
        }
        inboxSelector.layoutIfNeeded()
        checkForMessages(mainTabController)
    }
    
    func checkForMessages(_ mainTabController: MainTabViewController) {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .long
        
        let unreadConversations: [Conversation] = (self.conversations ?? self.inbox).filter({ (c: Conversation) -> Bool in
            return c.hasNewMessages
        }).sorted(by: { (a, b) -> Bool in
            return a.lastMessageCreated < b.lastMessageCreated
        })
        let unreadConversationCount = unreadConversations.count
        
        API.sharedInstance.getRequests { (requests, err) in
            guard err == nil else { return }
            mainTabController.setBadge(requests.count, forTab: .Requests)
        }
        guard unreadConversationCount != 0 else {
            app.applicationIconBadgeNumber = unreadConversationCount
            mainTabController.setBadge(unreadConversationCount, forTab: .Messages)
            return
        }
        let convo = unreadConversations[0]
        guard convo.member != nil else { return }
        let user = convo.member!.nickname
        let messages: Results<Message> = try! Realm()
            .objects(Message.self)
            .filter("conversationId == %@", convo.id)
            .sorted(byKeyPath: "createdAt", ascending: false)
        API.sharedInstance.loadMessages(convo.id, parameters: [:], completion: { (err2) in
            guard err2 == nil else {
                print("Error loading messages: \(err2!.localizedDescription)")
                app.applicationIconBadgeNumber = unreadConversationCount
                mainTabController.setBadge(unreadConversationCount, forTab: .Messages)
                return
            }
            let lastMessage = messages[0]
            if mainTabController.getBadge(.Messages) != unreadConversationCount || lastMessage.createdAt != convo.lastMessageCreated {
                if unreadConversationCount != 0 {
                    let title = "New message from \(user)"
                    let body = convo.lastMessageBody
                    let category = "newMessage"
                    let userInfo = [
                        "conversationId": convo.id,
                        "messageId": messages[0].id,
                        "user": user,
                        "userId": convo.member!.id,
                        "createdAt": df.string(from: convo.lastMessageCreated)
                    ]
                    let uuidString = "\(convo.id)-\(messages[0].id)"
                    let threadID = "\(category)-\(user)"
                    sendNotification(title, body: body, category: category, userInfo: userInfo, uuid: uuidString, threadID: threadID)
                }
                app.applicationIconBadgeNumber = unreadConversationCount
                mainTabController.setBadge(unreadConversationCount, forTab: .Messages)
            }
        })
    }
    
    func setupStateViews() {
        let noConvoView = NoConversationsView(frame: view.frame)
        noConvoView.refreshAction = {
            self.startLoading()
            self.fetchConversations()
        }
        
        self.emptyView = noConvoView
        self.loadingView = LoadingView(frame: view.frame)
        self.errorView = ErrorView(frame: view.frame)
    }
    
    private var firstConnection = true
    func networkStatusChanged() {
        if Connectivity.canReachAPI && (firstConnection || havingConnectionIssue) {
            self.updateStatus(havingConnectionIssue ? "Connection restored!" : "Connected", withColor: UIColor.statusOKColor())
            havingConnectionIssue = false
            Dispatch.delay(2.0, closure: self.hideStatus)
        } else if Connectivity.isConnected && (firstConnection || havingConnectionIssue) {
            self.updateStatus(havingConnectionIssue ? "Connection restored!" : "Connected", withColor: UIColor.statusOKColor())
            havingConnectionIssue = false
            Dispatch.delay(2.0, closure: self.hideStatus)
        } else if firstConnection {
            havingConnectionIssue = true
            self.updateStatus("Your internet connection appears to be offline.", withColor: UIColor.red)
        }
        firstConnection = false
    }
    
    func updateStatus(_ status: String, withColor color: UIColor?) {
        statusLabel.text = status
        statusLabel.backgroundColor = color ?? UIColor.backgroundColor()
        UIView.animate(withDuration: 0.5, animations: {
            self.statusLabel.isHidden = false
        }) { (_) in
            Dispatch.delay(2.0, closure: self.hideStatus)
        }
    }
    
    private func hideStatus() {
        guard !havingConnectionIssue else { return }
        UIView.animate(withDuration: 0.5, animations: {
            self.statusLabel.isHidden = true
        })
    }
    
    // MARK: - StatefulViewController
    
    func hasContent() -> Bool {
        return (conversations ?? inbox).count > 0
    }
    
    @IBAction func inboxSelectionChanged(_ sender: UISegmentedControl) {
        print("Inbox count: \(inbox.count)")
        print("Archived count: \(allConversations.count)")
        switch sender.selectedSegmentIndex {
        case 0: // Inbox
            conversations = inbox
            print("Inbox selected")
        default: // 1: Archived
            conversations = allConversations
            print("Archived messages selected")
        }
        AppSettings.lastSelectedMailbox = sender.selectedSegmentIndex
        tableView.reloadData()
        self.startLoading()
        self.fetchConversations()
    }
    
    // MARK: - TableView Delegate & DateSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ConversationCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ConversationCell
        
        let conversation = try! Realm().objects(Conversation.self).filter("id == %@", conversations[indexPath.row].id).first!
        
        cell.conversation = conversation
        cell.tableView = self.tableView
        cell.index = indexPath.row
        
        if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
            cell.layoutMargins = UIEdgeInsets.zero
            cell.preservesSuperviewLayoutMargins = false
        }
        Dispatch.delay(0.1) {
            cell.authorAvatarImage.awakeFromNib()
            cell.awakeFromNib()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        collapseDetailViewController = false
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        var archiveAction: UITableViewRowAction!
        if conversations[indexPath.row].isArchived {
            archiveAction = UITableViewRowAction(style: .normal, title: "Unarchive") { action, index in
                let conversationToUnarchive = self.conversations[indexPath.row]
                let realm = try! Realm()
                try! realm.write {
                    conversationToUnarchive.isArchived = false
                }
                API.sharedInstance.unarchiveConversation(conversationToUnarchive.id, completion: { (err) in
                    if err == nil {
                        tableView.deleteRows(at: [indexPath], with: .left)
                    } else {
                        print(err!.localizedDescription)
                    }
                })
            }
        } else {
            archiveAction = UITableViewRowAction(style: .destructive, title: "Archive") { action, index in
                let conversationToArchive = self.conversations[indexPath.row]
                let realm = try! Realm()
                try! realm.write {
                    conversationToArchive.isArchived = true
                }
                API.sharedInstance.archiveConversation(conversationToArchive.id, completion: { (err) in
                    if err == nil {
                        tableView.deleteRows(at: [indexPath], with: .left)
                    } else {
                        print(err!.localizedDescription)
                    }
                })
            }
        }
        archiveAction.backgroundColor = UIColor.brickColor()
        
        var deleteAction: UITableViewRowAction!
        deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: { (_, index) in
            let alertController = UIAlertController(title: "Are you sure?", message: "Are you sure you want to permanently delete this conversation? This cannot be undone!", preferredStyle: UIAlertControllerStyle.alert)
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let deleteConfirmAction = UIAlertAction(title: "Delete", style: .destructive) { (action) -> Void in
                let conversationToDelete = self.conversations[indexPath.row]
                API.sharedInstance.deleteConversation(conversationToDelete.id, completion: { (err) in
                    if err == nil {
                        tableView.deleteRows(at: [indexPath], with: .left)
                    } else {
                        print(err!.localizedDescription)
                    }
                })
            }
            alertController.addAction(deleteConfirmAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        })
        deleteAction.backgroundColor = UIColor.red
        
        return [archiveAction, deleteAction]
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let conversationToChange: Conversation = self.conversations[indexPath.row]
        
        let messages: Results<Message> = try! Realm().objects(Message.self).filter("conversationId == %@", conversationToChange.id).sorted(byKeyPath: "createdAt", ascending: false) as Results<Message>
        if let m: Message = messages.first {
            if conversationToChange.hasNewMessages {
                let ca = UIContextualAction(style: .normal, title: "Mark as Read") { (action, view, completion) in
                    // no need to try realm.write: that's done in the API
                    API.sharedInstance.markMessagesAsRead(conversationToChange.id, messageIds: [m.id], completion: { (err) in
                        if err != nil { print(err!) }
                    })
                }
                ca.backgroundColor = UIColor.unreadMarkerColor()
                return UISwipeActionsConfiguration(actions: [ca])
            }
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // MARK: - SplitViewController Delegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }
}

@available(iOS 10.0, *)
extension ConversationsViewController: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response.notification.request.content.userInfo)
        let content = response.notification.request.content
        if content.categoryIdentifier == "newMessage" {
            // FIXME: - Tapping on the notification will present message view from current view controller instead of from conversation view controller
            let convoId = content.userInfo["conversationId"] as! String
            let conversation: Conversation = try! Realm().objects(Conversation.self).filter("id == \"\(convoId)\"").first!
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let controller: MessagesTableViewController = storyboard.instantiateViewController(withIdentifier: "vcMessagesTable") as! MessagesTableViewController
            controller.conversation = conversation
            controller.navigationItem.title = "\(conversation.member!.nickname) ‣"
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            controller.conversationId = conversation.id
            self.performSegue(withIdentifier: "showDetail", sender: conversation)
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}
