//
//  ChatBotViewController.swift
//  ChaDas5
//
//  Created by Julia Rocha on 27/11/19.
//  Copyright © 2019 Julia Maria Santos. All rights reserved.
//

import Foundation
import UIKit
import ApiAI
import MessageKit
import InputBarAccessoryView

// MARK: -  Declaration
class ChatBotViewController: MessagesViewController {
    
    // MARK: -  Outlets
    @IBOutlet weak var insertText: UITextField!
    var consersationData:[Message] = []
    let endOfConversationTriggerA = "É, eu acho bem difícil saber o que se passa na cabeça das pessoas… Nossa, não consigo nem terminar de contar a história! Enfim, ele só cortou a conversa e começou a tentar me agarrar, me senti 100% constrangida… Minha sorte foi uma amiga que queria ir embora e chegou bem na hora me chamando pra ir com ela. Senti bastante medo dele, não sei o que teria acontecido se ela não tivesse aparecido."
     let endOfConversationTriggerB = "Realmente queria conseguir saber o que se passa na cabeça das pessoas… Nossa, não consigo nem terminar de contar a história! Enfim, ele só cortou a conversa e começou a tentar me agarrar, me senti 100% constrangida… Minha sorte foi uma amiga que queria ir embora e chegou bem na hora me chamando pra ir com ela. Senti bastante medo dele, não sei o que teria acontecido se ela não tivesse aparecido. "
    
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        debugPrint("error initializing chatbot")
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: -  View Configurations
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self

        
        let myCollection = messagesCollectionView as UICollectionView
        myCollection.translatesAutoresizingMaskIntoConstraints = false
        //constraints
        NSLayoutConstraint.activate([
            myCollection.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),
            myCollection.leftAnchor.constraint(equalTo: view.leftAnchor),
            myCollection.rightAnchor.constraint(equalTo: view.rightAnchor),
            myCollection.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50)
            
        ])
        configureNavigationBar()
        configureInputBar()
    }
    
    
    // MARK: -  Actions
    @IBAction func sendForAPI(_ sender: Any) {
        talkToBot(with: insertText.text ?? "")
    }
    
    
    func talkToBot(with text:String) {
        save(text)
        let request = ApiAI.shared().textRequest()
        if text != "" {
             request?.query = text
         } else { return }
         request?.setMappedCompletionBlockSuccess({ (request, response) in
            let response = response as! AIResponse
            
            // check
            if let textResponse = response.result.fulfillment.messages.first {
                guard let messageTextFromBot = textResponse["speech"] as? String else { return }
                
                if messageTextFromBot == self.endOfConversationTriggerA || messageTextFromBot == self.endOfConversationTriggerB {
                    // end bot
                } else {
                    self.consersationData.append(Message(content: messageTextFromBot, on: "chatbot"))
                    self.customReloadData()
                }
         }
         }, failure: { (request, error) in
             print(error!)
         })
         ApiAI.shared().enqueue(request)
        // esvaziar caixa de resposta
//        insertText.text = ""
    }
    
    private func insertNewMessage(_ message: Message) {
        let isLatestMessage = self.consersationData.firstIndex(of: message) == (consersationData.count - 1)
        let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
        if shouldScrollToBottom {
            DispatchQueue.main.async {
                self.customReloadData()
            }
        }
    }
    
    
    // MARK: -  Database Helpers
    private func save(_ message: String) {
//        let channelID = self.channelRecord.recordID.recordName
        let messageRep = Message(content: message, on: "")
        self.consersationData.append(messageRep)
        self.customReloadData()
    }
    
    
}
// MARK: -  Extensions

// MARK: -  MessagesProtocol extension
extension ChatBotViewController: MessagesDisplayDelegate {
    
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

// MARK: - MessagesLayoutDelegate extension
extension ChatBotViewController: MessagesLayoutDelegate {
    
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
        return CGSize(width: self.view.bounds.width, height: 170)
    }
    
    
}

// MARK: - MessagesDataSource extension
extension ChatBotViewController: MessagesDataSource {
    
    
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return 1
    }
    
    func numberOfItems(inSection section: Int, in messagesCollectionView: MessagesCollectionView) -> Int {
        return self.consersationData.count
    }
    
    
    func currentSender() -> SenderType {
        return Sender(id: MeUser.instance.email , displayName: MeUser.instance.name)
    }
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return self.consersationData.count
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return self.consersationData[indexPath.row]
    }

    
    func customReloadData() {
        // FIXME: - Scroll to bottom not working
        messagesCollectionView.reloadDataAndKeepOffset()
        let view = messagesCollectionView as UICollectionView
        let lastSection = view.numberOfSections - 1
        let lastRow = view.numberOfItems(inSection: lastSection)
        let indexPath = IndexPath(row: lastRow - 1, section: lastSection)
        view.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.bottom, animated: true)
        
    }
    
}

// MARK: -  self layout extension
extension ChatBotViewController: InputBarAccessoryViewDelegate {
    
    
    func configureNavigationBar() {
        let bar = CustomNavigationBar()
        bar.frame = CGRect(x: 0.5, y: 0.5, width: 375, height: 100)
        bar.barTintColor = UIColor.middleOrange
        bar.isTranslucent = true
        //        let navbarFont = UIFont(name: "SFCompactDisplay-Regular", size: 17) ?? UIFont.systemFont(ofSize: 17)
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
        let dismissButton = UIButton(frame: CGRect(x: 30, y: 45, width: 40, height: 40))
        dismissButton.setImage(img , for: .normal)
//        dismissButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        dismissButton.contentMode = .center
        dismissButton.imageView?.contentMode = .scaleAspectFit
        
        
        self.view.addSubview(dismissButton)
        let complainButtonImg = UIImage(named: "blockIcon")
        let complainButton = UIButton(frame: CGRect(x: 375 - dismissButton.frame.maxX, y: 45, width: 40, height: 40))
        complainButton.setImage(complainButtonImg , for: .normal)
//        complainButton.addTarget(self, action: #selector(complainAction), for: .touchUpInside)
        complainButton.contentMode = .center
        complainButton.imageView?.contentMode = .scaleAspectFit
        complainButton.isEnabled = true
        self.view.addSubview(complainButton)
        
        let backgroudCircle = UIImageView(frame: CGRect(x: 45, y:45, width: 45, height: 45))
        backgroudCircle.image = UIImage(named: "backgroundCircle")
        backgroudCircle.contentMode = .scaleAspectFill
        self.view.addSubview(backgroudCircle)
        
        
        let teaButton = UIButton(frame: CGRect(x: 30, y: 45, width: 45, height: 35))
//        teaButton.addTarget(self, action: #selector(teaAction), for: .touchUpInside)
        let teaName = UILabel(frame: CGRect(x: 45, y:45, width: 45, height: 45))
        teaName.contentMode = .scaleAspectFill
        teaName.textAlignment = .center
        teaName.center.y = backgroudCircle.center.y
        teaName.font = UIFont(name: "SFCompactDisplay-Regular", size: 17)
        
        self.view.addSubview(teaName)
        let photo = UIImage.init(named: "Camomila")
        teaName.text = "Camomila"
        teaButton.setImage(photo , for: .normal)
        
        
        // teaButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        teaButton.contentMode = .center
        teaButton.imageView?.contentMode = .scaleAspectFit
        self.view.addSubview(teaButton)
        
        
        
        
        dismissButton.translatesAutoresizingMaskIntoConstraints = false
        complainButton.translatesAutoresizingMaskIntoConstraints = false
        backgroudCircle.translatesAutoresizingMaskIntoConstraints = false
        teaButton.translatesAutoresizingMaskIntoConstraints = false
        teaName.translatesAutoresizingMaskIntoConstraints = false
        
        //constraints
        NSLayoutConstraint.activate([
            dismissButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 45),
            dismissButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: -150),
            dismissButton.widthAnchor.constraint(equalToConstant: 40),
            dismissButton.heightAnchor.constraint(equalToConstant: 40),
            
            complainButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 45),
            complainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 150),
            complainButton.widthAnchor.constraint(equalToConstant: 40),
            complainButton.heightAnchor.constraint(equalToConstant: 40),
            
            backgroudCircle.topAnchor.constraint(equalTo: view.topAnchor, constant: 45),
            backgroudCircle.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            backgroudCircle.widthAnchor.constraint(equalToConstant: 80),
            backgroudCircle.heightAnchor.constraint(equalToConstant: 80),
            
            teaButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 47),
            teaButton.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            teaButton.widthAnchor.constraint(equalToConstant: 70),
            teaButton.heightAnchor.constraint(equalToConstant: 70),
            
            teaName.topAnchor.constraint(equalTo: view.topAnchor, constant: 130),
            teaName.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0),
            teaName.widthAnchor.constraint(equalToConstant: 300),
            teaName.heightAnchor.constraint(equalToConstant: 30)
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
        messageInputBar.inputTextView.placeholderLabel.font = UIFont(name: "SFCompactDisplay-Regular", size: 18)
        messageInputBar.inputTextView.placeholderLabel.textColor = UIColor.gray
        messageInputBar.inputTextView.backgroundColor = UIColor.white
        messageInputBar.inputTextView.layer.cornerRadius = 15
        messageInputBar.inputTextView.font = UIFont.systemFont(ofSize: 18)
        messageInputBar.setLeftStackViewWidthConstant(to: 10, animated: false)
        
        
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        talkToBot(with: text)
        inputBar.inputTextView.text = ""
    }
}
