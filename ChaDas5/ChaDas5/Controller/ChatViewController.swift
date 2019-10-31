

import UIKit
import CloudKit
import MessageKit
import InputBarAccessoryView



class ChatViewController: MessagesViewController, UINavigationBarDelegate, MessagesProtocol {

    
    func messageSaved(with error: Error) {
        debugPrint("deu erro porra", error)
    }
    
    func messageSaved() {
        // mudar status da msg
        debugPrint("salvou bunitin")
    }
    
    
    func deleted() {
        
    }
    
    func deletedError(with: Error) {
        
    }
    

    var chatUserRequester: UserRequester!
    var activityView: UIActivityIndicatorView!
    private let channel: Channel
    
    let dao = DAOManager.instance?.ckMessages

    init(channel: Channel) {
        self.channel = channel
        super.init(nibName: nil, bundle: nil)
        checkSubscription()
    }
    
    func checkSubscription() {
        guard let channelID = self.channel.id else { return }
        DaoPushNotifications.instance.retrieveSubscription(on: channelID.recordName) { (exists) in
            if exists == nil {
                debugPrint("error getting subscription")
                return
            }
            if exists! == false {
                let predicate = NSPredicate(format: "onChannel = %@", channelID.recordName)
                DaoPushNotifications.instance.createSubscription(recordType: "Thread", predicate: predicate, option: CKQuerySubscription.Options.firesOnRecordCreation, on: channelID.recordName)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        debugPrint("error initializing chat")
        fatalError("init(coder:) has not been implemented")
    }

    static var lcount = 0
    
    
  
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard channel.id != nil else {
            self.dismiss(animated: true)
            return
        }
        guard let dao = dao else { return }
 
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        maintainPositionOnKeyboardFrameChanged = true
        configureNavigationBar()
        configureInputBar()
        configureActivityView()
        
        let myCollection = messagesCollectionView as UICollectionView
        myCollection.translatesAutoresizingMaskIntoConstraints = false
        //constraints
         NSLayoutConstraint.activate([
             myCollection.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
             myCollection.leftAnchor.constraint(equalTo: view.leftAnchor),
             myCollection.rightAnchor.constraint(equalTo: view.rightAnchor),
             myCollection.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -90)

             ])
        customReloadData()
        dao.loadMessages(from: self.channel, requester: self)
    }
    
    @objc func buttonAction(sender: UIButton!) {
        self.dismiss(animated: false, completion: nil)
    }

    @objc func complainAction(sender: UIButton!) {
        
        let alert = UIAlertController(title: "Deseja mesmo bloquear esse usuário?", message: "Vocês não verão postagens um do outro mais! Esse usuário também será mandado para análise.", preferredStyle: .alert)
        let bloquear = UIAlertAction(title: "Bloquear Usuário", style: .default, handler: { (action) -> Void in
            
        
            
            guard let channelID = self.channel.id else {
                return
            }
            
            if MeUser.instance.email == self.channel.ownerID {
                DAOManager.instance?.ckUsers.block(self.channel.fromStory, requester: self)
                DAOManager.instance?.ckUsers.blockAnother(self.channel.fromStory, requester: self)
            }else{
                DAOManager.instance?.ckUsers.block(self.channel.ownerID, requester: self)
                        DAOManager.instance?.ckUsers.blockAnother(self.channel.ownerID, requester: self)
            }
            
            self.dismiss(animated: false)
            
            DAOManager.instance?.ckChannels.deleteChannel(channelID: channelID, completion: { (completed) in
                if completed {
                   
                }
            })
            
        })
        let cancelar = UIAlertAction(title: "Cancelar", style: .default ) { (action) -> Void in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(bloquear)
        alert.addAction(cancelar)
        self.present(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.buttonOrange
    }


  // MARK: -  Database Helpers

    private func save(_ message: String) {
        guard let channelID = self.channel.id else {
            return
        }
        let messageRep = Message(content: message, on: channelID.recordName)
        dao?.save(message: messageRep, to: self)
        self.customReloadData()
    }

    private func insertNewMessage(_ message: Message) {
        
        guard let messages = dao?.messages else {
            return
        }
        let isLatestMessage = messages.firstIndex(of: message) == (messages.count - 1)
        let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
        if shouldScrollToBottom {
            DispatchQueue.main.async {
                self.customReloadData()
            }
        }
    }
    
    
    func readedMessagesFromChannel(messages: [Message]?, error: Error?) {
        if messages != nil {
            DispatchQueue.main.async {
                self.customReloadData()
                self.activityView.stopAnimating()
            }
        }
        DispatchQueue.main.async {
            self.activityView.stopAnimating()
        }
    }
    
    
    // MARK: - Configure self layout
    
    func configureActivityView() {
        if #available(iOS 13.0, *) {
            activityView = UIActivityIndicatorView(style: .medium)
        } else {
            activityView = UIActivityIndicatorView(style: .gray)
        }
        activityView.color = UIColor.buttonOrange
        activityView.frame = CGRect(x: 0, y: 0, width: 300.0, height: 300.0)
        activityView.center = view.center
        activityView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        view.addSubview(activityView)
        activityView.startAnimating()
    }
    
    func configureNavigationBar() {
        let bar = CustomNavigationBar()
        bar.frame = CGRect(x: 0.5, y: 0.5, width: 375, height: 100)
        bar.barTintColor = UIColor.middleOrange
        bar.isTranslucent = true
//        let navbarFont = UIFont(name: "SFCompactDisplay-Ultralight", size: 17) ?? UIFont.systemFont(ofSize: 17)
        self.view.addSubview(bar)
        configureButtons()
        
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        //constraints
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: view.topAnchor),
            bar.leftAnchor.constraint(equalTo: view.leftAnchor),
            bar.rightAnchor.constraint(equalTo: view.rightAnchor)
            
            ])
        
    }
    
    func configureButtons() {
        let img = UIImage(named: "dismissIcon")
        let dismissButton = UIButton(frame: CGRect(x: 30, y: 45, width: 45, height: 35))
        dismissButton.setImage(img , for: .normal)
        dismissButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        dismissButton.contentMode = .center
        dismissButton.imageView?.contentMode = .scaleAspectFit
        
        
        self.view.addSubview(dismissButton)
        let complainButtonImg = UIImage(named: "complainIcon")
        let complainButton = UIButton(frame: CGRect(x: 375 - dismissButton.frame.maxX, y: 45, width: 65, height: 55))
        complainButton.setImage(complainButtonImg , for: .normal)
        complainButton.addTarget(self, action: #selector(complainAction), for: .touchUpInside)
        complainButton.contentMode = .center
        complainButton.imageView?.contentMode = .scaleAspectFit
        complainButton.isEnabled = true

        
        self.view.addSubview(complainButton)
        
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        complainButton.translatesAutoresizingMaskIntoConstraints = false
        
        //constraints
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 45),
            dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -112.5),
            dismissButton.widthAnchor.constraint(equalToConstant: 65),
            dismissButton.heightAnchor.constraint(equalToConstant: 55),
            
            complainButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 45),
            complainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 112.5),
            complainButton.widthAnchor.constraint(equalToConstant: 65),
            complainButton.heightAnchor.constraint(equalToConstant: 55)
            ])
    
    }
    
    func configureInputBar() {
        messageInputBar.inputTextView.tintColor = UIColor.middleOrange
        messageInputBar.sendButton.setTitleColor(UIColor.buttonOrange, for: .normal)
        messageInputBar.sendButton.title = ""
        messageInputBar.sendButton.image = UIImage(named: "sendIcon")
        messageInputBar.sendButton.contentMode = .scaleAspectFill
        messageInputBar.delegate = self
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.sendButton.title = "Enviar"
        messageInputBar.backgroundView.backgroundColor = UIColor.middleOrange
      //  messageInputBar.backgroundView.frame = CGRect(x: 50, y: 50, width: view.frame.width, height: 10)
        messageInputBar.isTranslucent = true
        messageInputBar.inputTextView.placeholderLabel.text = "Nova mensagem"
        messageInputBar.inputTextView.placeholderLabel.font = UIFont(name: "SFCompactDisplay-Ultralight", size: 18)
        messageInputBar.inputTextView.placeholderLabel.textColor = UIColor.gray
        messageInputBar.inputTextView.backgroundColor = UIColor.white
        messageInputBar.inputTextView.layer.cornerRadius = 15
        messageInputBar.inputTextView.font = UIFont(name: "SFCompactDisplay-Ultralight", size: 18)
        messageInputBar.setLeftStackViewWidthConstant(to: 10, animated: false)

    
    }
}

// MARK: - MessagesDisplayDelegate

extension ChatViewController: MessagesDisplayDelegate {

    func backgroundColor(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor.middleOrange : UIColor.lightGray.withAlphaComponent(0.25)
    }
    
    func shouldDisplayHeader(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool {
        return true
    }
    
    func messageStyle(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(corner, .curved)
    }

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.removeFromSuperview()
    }
    
}

// MARK: - MessagesLayoutDelegate

extension ChatViewController: MessagesLayoutDelegate {

    func avatarSize(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return .zero
    }

    func footerViewSize(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 0, height: 8)
    }

    func textColor(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor.black : UIColor.black
    }
    
    func headerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: self.view.bounds.width, height: 120)
    }


}

// MARK: - MessagesDataSource

extension ChatViewController: MessagesDataSource {
    
    
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return 1
    }

    func numberOfItems(inSection section: Int, in messagesCollectionView: MessagesCollectionView) -> Int {
        guard let dao = dao else {
            fatalError()
        }
        return dao.messages.count
    }


    func currentSender() -> SenderType {
        return Sender(id: MeUser.instance.email , displayName: MeUser.instance.name)
    }

    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        guard let dao = dao else {
            fatalError()
        }
        return dao.messages.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        guard let dao = dao else {
            fatalError()
        }
        return dao.messages[indexPath.row]
    }
    
    
    func customReloadData() {
        // FIXME: - Scroll to bottom not working
        messagesCollectionView.reloadData()
        let view = messagesCollectionView as UICollectionView
        
        let lastSection = view.numberOfSections - 1
        let lastRow = view.numberOfItems(inSection: lastSection)
        let indexPath = IndexPath(row: lastRow - 1, section: lastSection)
        view.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.bottom, animated: true)

    }

}

// MARK: - MessageInputBarDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {

    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        save(text)
        inputBar.inputTextView.text = ""
    }
    
}
extension ChatViewController: UserRequester {
    func saved(userRecord: CKRecord?, userError: Error?) {}
    
    func retrieved(user: User?, userError: Error?) {}
    
    func retrieved(userArray: [User]?, userError: Error?) {}
    
    func retrieved(meUser: MeUser?, meUserError: Error?) {}
    
    func retrieved(user: User?, fromIndex: Int, userError: Error?) {}
     
}



