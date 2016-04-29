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

    var detailViewController: MessagesViewController?
    var refreshControl = UIRefreshControl()
    
    let conversations: Results<Conversation> = try! Realm()
        .objects(Conversation.self)
        .filter("isArchived == false")
        .sorted("lastMessageCreated", ascending: false)
    
    var notificationToken: NotificationToken?
    
    private var collapseDetailViewController = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupStateViews()
        
        self.refreshControl.addTarget(self, action: #selector(ConversationsViewController.refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        
        self.splitViewController?.delegate = self
        
        self.tableView?.delegate = self
        self.tableView?.dataSource = self
        self.tableView?.separatorInset = UIEdgeInsetsZero
        self.tableView?.addSubview(refreshControl)
        
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? MessagesViewController
        }
        
        notificationToken = conversations.addNotificationBlock({ [unowned self] results, error in
            guard let results = results else { return }
            
            if results.count > 0 {
                self.tableView.reloadData()
            }
        })
        
        if conversations.isEmpty {
            self.startLoading()
        }
        
        self.fetchConversations()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.setupInitialViewState()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                self.tableView.reloadRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                let conversation = conversations[indexPath.row]
                let controller = (segue.destinationViewController as! UINavigationController).topViewController as! MessagesViewController
                controller.conversation = conversation
                controller.senderDisplayName = API.currentMemberNickname()
                controller.senderId = API.currentMemberId()
                controller.navigationItem.title = conversation.member!.nickname
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    func refresh(refreshControl: UIRefreshControl) {
        fetchConversations()
    }
    
    func fetchConversations() {
        Dispatch.asyncOnUserInitiatedQueue() {
            API.sharedInstance.loadConversations() { error in
                self.endLoading(error: error)
                self.refreshControl.endRefreshing()
            }
        }
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

    @IBAction func logoutButtonPressed(sender: UIBarButtonItem) {
        API.sharedInstance.logout()
        navigationController?.viewControllers = [storyboard!.instantiateViewControllerWithIdentifier("loginView"), self]
        navigationController?.popViewControllerAnimated(true)
    }

    // MARK: - StatefulViewController
    
    func hasContent() -> Bool {
        return conversations.count > 0
    }
    
    // MARK: - TableView Delegate & DateSource
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "ConversationCell"
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ConversationCell
        
        let conversation = conversations[indexPath.row]
        
        cell.conversation = conversation
        
        if cell.respondsToSelector(Selector("setPreservesSuperviewLayoutMargins:")) {
            cell.layoutMargins = UIEdgeInsetsZero
            cell.preservesSuperviewLayoutMargins = false
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        collapseDetailViewController = false
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let archive = UITableViewRowAction(style: .Default, title: "Archive") { action, index in
            let conversationToArchive = self.conversations[indexPath.row]
            
            let realm = try! Realm()
            
            try! realm.write {
                conversationToArchive.isArchived = true
            }
            
            API.sharedInstance.archiveConversation(conversationToArchive.id, completion: nil)
        }
        
        archive.backgroundColor = UIColor.brickColor()
        
        return [archive]
    }
    
    // MARK: - SplitViewController Delegate
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }
}