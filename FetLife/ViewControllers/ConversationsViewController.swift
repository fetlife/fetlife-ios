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

    var detailViewController: MessagesTableViewController?
    var refreshControl = UIRefreshControl()
	var updateTimer: Timer = Timer()
    
    let conversations: Results<Conversation> = try! Realm()
        .objects(Conversation.self)
        .filter("isArchived == false")
        .sorted(byKeyPath: "lastMessageCreated", ascending: false)
    
    var notificationToken: NotificationToken? = nil
    
    fileprivate var collapseDetailViewController = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            guard let tableView = self?.tableView else { return }
            
            switch changes {
            case .initial(let conversations):
                if conversations.count > 0 {
                    tableView.reloadData()
                }
                break
            case .update(_, let deletions, let insertions, let modifications):
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) },
                    with: .automatic)
                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) },
                    with: .automatic)
                tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) },
                    with: .automatic)
                tableView.endUpdates()
                break
            case .error:
                break
            }
        })
        
        if conversations.isEmpty {
            self.startLoading()
        }
        
        self.fetchConversations()
		
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
            if let indexPath = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRow(at: indexPath, animated: true)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                let conversation = conversations[indexPath.row]
				let controller: MessagesTableViewController = (segue.destination as! UINavigationController).topViewController as! MessagesTableViewController
                controller.conversation = conversation
                controller.navigationItem.title = conversation.member!.nickname
                controller.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
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

    @IBAction func logoutButtonPressed(_ sender: UIBarButtonItem) {
        API.sharedInstance.logout()
        navigationController?.viewControllers = [storyboard!.instantiateViewController(withIdentifier: "loginView"), self]
        _ = navigationController?.popViewController(animated: true)
    }

    // MARK: - StatefulViewController
    
    func hasContent() -> Bool {
        return conversations.count > 0
    }
    
    // MARK: - TableView Delegate & DateSource
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "ConversationCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! ConversationCell
        
        let conversation = conversations[indexPath.row]
        
        cell.conversation = conversation
        
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
        let archive = UITableViewRowAction(style: .destructive, title: "Archive") { action, index in
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
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }
}
