//
//  MessagesTableViewController.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/11/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit
import SlackTextViewController
import StatefulViewController
import SnapKit
import RealmSwift

class MessagesTableViewController: SLKTextViewController {
    
    // MARK: - Properties
    
    let incomingCellIdentifier = "MessagesTableViewCellIncoming"
    let outgoingCellIdentifier = "MessagesTableViewCellOutgoing"
    var updateTimer: Timer = Timer()
    var navCon: UIViewController!
    
    @IBOutlet weak var titleButton: UIButton!
    
    lazy var loadingView: LoadingView = {
        let lv = LoadingView(frame: self.view.frame)
        
        if self.messages != nil && !self.messages.isEmpty {
            lv.isHidden = true
            lv.alpha = 0
        }
        return lv
    }()
    lazy var noConvoSelectedView: NoConversationsView = {
        let ncsv: NoConversationsView = NoConversationsView(frame: self.view.frame)
        if self.messages != nil && (!self.messages.isEmpty || self.conversation.member != nil) {
            ncsv.isHidden = true
            ncsv.alpha = 0
        }
        return ncsv
    }()
    
    var conversation: Conversation! {
        didSet {
            self.messages = try! Realm().objects(Message.self).filter("conversationId == %@", self.conversation.id).sorted(byKeyPath: "createdAt", ascending: false)
            assert(conversation.member != nil, "Conversation member is nil!")
            self.memberId = conversation.member!.id
            self.member = conversation.member!
        }
    }
    var messages: Results<Message>!
    var notificationToken: NotificationToken? = nil
    var memberId: String!
    var member: Member!
    var conversationId: String = ""
    private var attempts: Int = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(loadingView)
        view.addSubview(noConvoSelectedView)
        
        loadingView.snp.makeConstraints { make in
            if let navigationController = navigationController {
                make.top.equalTo(view).offset(navigationController.navigationBar.frame.height)
            }
            
            make.right.equalTo(view)
            make.bottom.equalTo(view)
            make.left.equalTo(view)
        }
        
        noConvoSelectedView.snp.makeConstraints { make in
            if let navigationController: UINavigationController = navigationController {
                make.top.equalTo(view).offset(navigationController.navigationBar.frame.height)
            }
            
            make.right.equalTo(view)
            make.bottom.equalTo(view)
            make.left.equalTo(view)
        }
        
        tableView!.register(UINib.init(nibName: incomingCellIdentifier, bundle: nil), forCellReuseIdentifier: incomingCellIdentifier)
        tableView!.register(UINib.init(nibName: outgoingCellIdentifier, bundle: nil), forCellReuseIdentifier: outgoingCellIdentifier)
        tableView!.delegate = self
        
        textInputbar.backgroundColor = UIColor.backgroundColor()
        textInputbar.layoutMargins = UIEdgeInsets.zero
        textInputbar.autoHideRightButton = true
        textInputbar.tintColor = UIColor.brickColor()
        
        titleButton.tintColor = UIColor.brickColor()
        if let conversation = conversation {
            titleButton.setTitle("\(conversation.member?.nickname ?? "") ‣", for: UIControlState.normal)
        }
        
        textView.placeholder = "What say you?"
        textView.placeholderColor = UIColor.lightText
        textView.backgroundColor = UIColor.backgroundColor()
        textView.textColor = UIColor.white
        textView.layer.borderWidth = 0.0
        textView.layer.cornerRadius = 2.0
        textView.isDynamicTypeEnabled = true
        textView.keyboardType = .default
        textView.keyboardAppearance = .dark
        textView.returnKeyType = .default
        
        registerUpdateNotifications()
        
        if !updateTimer.isValid { createTimer() }
    }
    
    func registerUpdateNotifications() {
        let realm = try! Realm()
        if realm.isInWriteTransaction { // we can't add a change notification while in a write transaction, so we have to wait...
            if attempts <= 10 {
                attempts += 1
                print("Unable to register for updates. Will try again in \(attempts)s...")
                Dispatch.delay(Double(attempts), closure: registerUpdateNotifications)
            } else {
                print("Notification registration failed too many times! Unable to register change notifications")
            }
        } else {
            if let conversation = conversation {
                notificationToken = messages.observe({ [weak self] (changes: RealmCollectionChange) in
                    guard let tableView = self?.tableView else { return }
                    
                    switch changes {
                    case .initial(let messages):
                        if messages.count > 0 {
                            tableView.reloadData()
                            let newMessageIds = messages.filter("isNew == true").map { $0.id }
                            
                            if !newMessageIds.isEmpty {
                                API.sharedInstance.markMessagesAsRead(conversation.id, messageIds: Array(newMessageIds), completion: nil)
                            }
                        }
                        break
                    case .update(let messages, let deletions, let insertions, let modifications):
                        let newMessageIds = messages.filter("isNew == true").map { $0.id }
                        
                        if !newMessageIds.isEmpty {
                            API.sharedInstance.markMessagesAsRead(conversation.id, messageIds: Array(newMessageIds), completion: nil)
                        }
                        
                        tableView.beginUpdates()
                        tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .bottom)
                        tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                        tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                        tableView.endUpdates()
                        
                        break
                    case .error:
                        break
                    }
                    
                    tableView.reloadData()
                    self?.hideLoadingView()
                    self?.hideNoConvoSelectedView()
                })
                attempts = 0
            } else {
                print("No conversation")
                attempts = 0
            }
        }
    }
    
    deinit {
        notificationToken?.invalidate()
        updateTimer.invalidate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        notificationToken?.invalidate()
        updateTimer.invalidate()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.fetchMessages()
        if !updateTimer.isValid { createTimer() }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /// Creates timer to check for new messages every 10 seconds ± 5 seconds
    func createTimer() {
        // FIXME: - This is stupidly inefficient and should be fixed with push notifications as soon as possible!
        updateTimer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(fetchMessages), userInfo: nil, repeats: true)
        updateTimer.tolerance = 5
    }
    
    // MARK: - Actions
    
    @IBAction func refreshAction(_ sender: UIBarButtonItem) {
        dismissKeyboard(true)
        showLoadingView()
        fetchMessages()
    }
    
    // MARK: - SlackTextViewController
    
    func tableViewStyleForCoder(_ decoder: NSCoder) -> UITableViewStyle {
        return UITableViewStyle.plain
    }
    
    override func didPressRightButton(_ sender: Any!) {
        textView.refreshFirstResponder()
        
        if let text = self.textView.text {
            let conversationId = conversation.id
            Dispatch.asyncOnUserInitiatedQueue() {
                API.sharedInstance.createAndSendMessage(conversationId, messageBody: text)
            }
        }
        
        super.didPressRightButton(sender)
    }
    
    override func keyForTextCaching() -> String? {
        // creates a unique key for each conversation
        return "\(Bundle.main.bundleIdentifier!).\(self.conversationId)"
    }
    
    // MARK: - TableView Delegate & DataSource
    
    override func numberOfSections(in: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let messages = messages else { return 0 }
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        // Decide whether a conversation table cell should be incoming (left) or outgoing (right).
        let cellIdent = (message.memberId != conversation.member!.id) ? self.outgoingCellIdentifier : self.incomingCellIdentifier
        
        // Get a cell, and coerce into a base class.
        let cell: BaseMessagesTableViewCell = tableView.dequeueReusableCell(withIdentifier: cellIdent, for: indexPath) as! BaseMessagesTableViewCell
        
        // SlackTextViewController inverts tables in order to get the layout to work. This means that our table cells needs to
        // apply the same inversion or be upside down.
        cell.transform = self.tableView!.transform // 😬
        
        cell.message = message
        cell.navCon = navCon
        cell.tableView = tableView
        
        // Remove margins from the table cell.
        if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
            cell.layoutMargins = UIEdgeInsets.zero
            cell.preservesSuperviewLayoutMargins = false
        }
        
        // Force autolayout to apply for the cell before rendering it.
        cell.layoutIfNeeded()
        cell.awakeFromNib()
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = cell as! BaseMessagesTableViewCell
        
        // Round that cell.
        cell.messageContainerView.layer.cornerRadius = 3.0
        cell.awakeFromNib()
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    // MARK: - Methods
    
    func fetchMessages() {
        if let conversation = conversation, let messages = messages {
            let conversationId = conversation.id
            if let lastMessage = messages.first {
                let parameters: Dictionary<String, Any> = [
                    "since": Int(lastMessage.createdAt.timeIntervalSince1970),
                    "since_id": lastMessage.id
                ]
                
                Dispatch.asyncOnUserInitiatedQueue() {
                    API.sharedInstance.loadMessages(conversationId, parameters: parameters) { error in
                        if let e = error {
                            print("error fetching messages: \(e.localizedDescription)")
                        }
                        self.hideLoadingView()
                    }
                }
            } else {
                Dispatch.asyncOnUserInitiatedQueue() {
                    API.sharedInstance.loadMessages(conversationId) { error in
                        self.hideLoadingView()
                    }
                }
            }
            self.tableView!.awakeFromNib()
        } else {
            self.hideLoadingView()
        }
        if let visibleCellIndexes = tableView!.indexPathsForVisibleRows {
            for path in visibleCellIndexes {
                if let cell: BaseMessagesTableViewCell = tableView!.cellForRow(at: path) as! BaseMessagesTableViewCell? {
                    cell.awakeFromNib() // This will update the timestamps
                }
            }
        }
    }
    
    func showLoadingView() {
        UIView.animate(withDuration: 0.3,
                       animations: { () -> Void in
                        self.loadingView.alpha = 1
        },
                       completion: { finished  in
                        self.loadingView.isHidden = false
        })
    }
    
    func hideLoadingView() {
        UIView.animate(withDuration: 0.3,
                       animations: { () -> Void in
                        self.loadingView.alpha = 0
        },
                       completion: { finished in
                        self.loadingView.isHidden = true
        })
    }
    
    func hideNoConvoSelectedView() {
        UIView.animate(withDuration: 0.3,
                       animations: { () -> Void in
                        self.noConvoSelectedView.alpha = 0
        },
                       completion: { finished in
                        self.noConvoSelectedView.isHidden = true
        })
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ViewFriendProfileSegueTitle" {
            let fpvc: FriendProfileViewController = segue.destination as! FriendProfileViewController
            fpvc.friend = self.member
            fpvc.messagesViewController = self
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
}
