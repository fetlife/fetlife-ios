//
//  ConversationsViewController.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/2/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit
import StatefulViewController
import RealmSwift

class ConversationsViewController: UIViewController, StatefulViewController, UITableViewDataSource, UITableViewDelegate, UISplitViewControllerDelegate {
    
    @IBOutlet var containerView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inboxSelector: UISegmentedControl!
    
    var detailViewController: MessagesTableViewController?
    var refreshControl = UIRefreshControl()
    var updateTimer: Timer = Timer()
    
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
        
        inboxSelector.selectedSegmentIndex = optLastSelectedMailbox
        
        // setting conversation value here (rather than in file declaration) to allow time for Realm setup and migration if necessary
        let filter = inboxSelector.selectedSegmentIndex == 0 ? "isArchived == false" : "isArchived == true"
        conversations = try! Realm()
            .objects(Conversation.self)
            .filter(filter)
            .sorted(byKeyPath: "lastMessageCreated", ascending: false)
        
        setupStateViews()
        
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
            case .update(_, let deletions, let insertions, let modifications):
                tv.reloadData()
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
        // creates timer to check for new messages/conversations every 10 seconds ± 5 seconds
        // FIXME: - This is stupidly inefficient and should be fixed with push notifications as soon as possible!
        updateTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(fetchConversationsInBackground), userInfo: nil, repeats: true)
        updateTimer.tolerance = 5
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        updateTimer.invalidate()
    }
    
    deinit {
        notificationToken?.invalidate()
        updateTimer.invalidate()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupInitialViewState()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let indexPath = self.tableView.indexPathForSelectedRow ?? IndexPath(row: (sender as! ConversationCell).index, section: 0)
            if self.splitViewController?.displayMode == UISplitViewControllerDisplayMode.primaryHidden {
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
            self.tableView.reloadRows(at: [indexPath], with: .automatic)
            let conversation = conversations[indexPath.row]
            let controller: MessagesTableViewController = (segue.destination as! UINavigationController).topViewController as! MessagesTableViewController
            controller.conversation = conversation
            controller.navigationItem.title = "\(conversation.member!.nickname) ‣"
            controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
        }
    }
    
    func refresh(_ refreshControl: UIRefreshControl) {
        fetchConversations()
    }
    
    func fetchConversations() {
        Dispatch.asyncOnUserInitiatedQueue() {
            API.sharedInstance.loadConversations() { error in
                self.endLoading(error: error)
                self.refreshControl.endRefreshing()
                if !self.hasContent() {
                    // TODO: show empty view if in split screen
                    UIApplication.shared.applicationIconBadgeNumber = 0 // no unread conversations
                } else {
                    self.getUnreadCount()
                }
            }
        }
    }
    
    func fetchConversationsInBackground() {
        print("Checking for new messages in Conversation View in the background...")
        let lastMessageDate: Date = (conversations[0]).lastMessageCreated
        Dispatch.asyncOnUserInitiatedQueue() {
            API.sharedInstance.loadConversations() { error in
                if let e = error {
                    print("Error loading conversations: \(e)")
                }
                let newLastDate: Date = (self.conversations[0]).lastMessageCreated
                if lastMessageDate != newLastDate {
                    self.endLoading(error: error)
                }
                if !self.hasContent() {
                    // TODO: show empty view if in split screen
                    UIApplication.shared.applicationIconBadgeNumber = 0 // no unread conversations
                } else {
                    self.getUnreadCount()
                }
            }
        }
    }
    
    func getUnreadCount() {
        let unreadConversationCount: Int = self.conversations.filter({ (c: Conversation) -> Bool in
            return c.hasNewMessages
        }).count
        UIApplication.shared.applicationIconBadgeNumber = unreadConversationCount
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
    
    @IBAction func logoutButtonPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Are you sure?", message: "Do you really want to log out of FetLife? We'll be very sad... 😢", preferredStyle: .actionSheet)
        let okAction = UIAlertAction(title: "Logout", style: .destructive) { (action) -> Void in
            API.sharedInstance.logout()
            self.navigationController?.viewControllers = [self.storyboard!.instantiateViewController(withIdentifier: "loginView"), self]
            _ = self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: "Never mind", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - StatefulViewController
    
    func hasContent() -> Bool {
        return conversations.count > 0
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
        optLastSelectedMailbox = sender.selectedSegmentIndex
        tableView.reloadData()
        self.startLoading()
        self.fetchConversations()
    }
    
    // MARK: - TableView Delegate & DateSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ConversationCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ConversationCell
        
        let conversation = conversations[indexPath.row]
        
        cell.conversation = conversation
        cell.index = indexPath.row
        
        if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
            cell.layoutMargins = UIEdgeInsets.zero
            cell.preservesSuperviewLayoutMargins = false
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
        var action: UITableViewRowAction!
        if conversations[indexPath.row].isArchived {
            action = UITableViewRowAction(style: .normal, title: "Unarchive") { action, index in
                let conversationToUnarchive = self.conversations[indexPath.row]
                let realm = try! Realm()
                try! realm.write {
                    conversationToUnarchive.isArchived = false
                }
                API.sharedInstance.unarchiveConversation(conversationToUnarchive.id, completion: nil)
            }
        } else {
            action = UITableViewRowAction(style: .destructive, title: "Archive") { action, index in
                let conversationToArchive = self.conversations[indexPath.row]
                let realm = try! Realm()
                try! realm.write {
                    conversationToArchive.isArchived = true
                }
                API.sharedInstance.archiveConversation(conversationToArchive.id, completion: nil)
            }
        }
        action.backgroundColor = UIColor.brickColor()
        return [action]
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
        return false
    }
    
    // MARK: - SplitViewController Delegate
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }
}
