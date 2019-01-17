//
//  Channel.swift
//  ChaDas5
//
//  Created by Nathalia Inacio on 29/12/18.
//  Copyright © 2018 Julia Maria Santos. All rights reserved.
//

import FirebaseFirestore
import UserNotifications

class Channel {
  
    var id: String?
    var firstUser:String?
    var created:String?
    var secondUser:String?
    var lastMessageDate:String?
    var username1:String?
    var username2:String?
  
    init(story: QueryDocumentSnapshot) {
        self.firstUser = (UserManager.instance.currentUser)
        self.created = Date().keyString
        self.id = self.channelID
        self.secondUser = ChannelsManager.instance.author(dc: story)
        self.lastMessageDate = created
        let newDoc = FBRef.db.collection("channels").document(self.channelID).setData(self.asDictionary)
        getUsernames()
        
    }
  
    init?(document: QueryDocumentSnapshot) {
        var data = document.data()
        id = document.documentID
        self.firstUser = data["firstUser"] as! String
        self.secondUser = data["secondUser"] as! String
        self.created = data["created"] as! String
        getUsernames()
    }
    
    init?(document: DocumentReference) {
        document.getDocument { (snapshot, err) in
            var data = snapshot?.data()
            print(type(of:self), #function, data)
            self.id = document.documentID
            self.firstUser = data!["firstUser"] as! String
            self.secondUser = data!["secondUser"] as! String
        }
        getUsernames()
    }
    
    func getUsernames() {
//        let user1Ref = FBRef.db.collection("users").document(firstUser!)
//
//        user1Ref.getDocument(source: .cache) { (document, error) in
//            if let document = document {
//                self.username1 = document.get("username") as! String
//            }
//
//        }
//
//        let user2Ref = FBRef.db.collection("users").document(firstUser!)
//        user2Ref.getDocument(source: .cache) { (document, error) in
//            if let document = document {
//                self.username2 = document.get("username") as! String
//            }
//        }
//        print(username1, username2)
    }
    
    
    
    
    func add(message:Message) {
        //SALVA A MENSAGEM NO CHANNEL
        guard let id = self.id else {
            print("error saving message")
            return}
        let channelMessagesRef = FBRef.db.collection("channels").document(id).collection("thread")
        channelMessagesRef.addDocument(data: message.representation) { (error) in
            if let error = error {
                debugPrint(error.localizedDescription)
            } else {
                debugPrint("saved message")            }
        }
        self.lastMessageDate = message.sentDate.keyString
        FBRef.db.collection("channels").document(id).updateData(["lastMessageDate" : self.lastMessageDate])
    }
    
    
//    
//    func createNotification(){
//        
//        
//        print("HERE")
//        let content = UNMutableNotificationContent()
//        content.title = "Title"
//        content.subtitle = "Sub"
//        content.body = "body"
//        content.sound = UNNotificationSound.default
//        //content.launchImageName = AppDelegate
//        
//        let myTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
//        let myRequest = UNNotificationRequest(identifier: "Notification", content: content, trigger: myTrigger)
//        
//        UNUserNotificationCenter.current().add(myRequest) { (error) in
//            print(error as Any)
//        }
//        
//        
//    }
    
    
    
    
  }

extension Channel: DatabaseRepresentation {
    
    var asDictionary:[String:Any] {
        var result:[String:Any] = [:]
        result["firstUser"] = self.firstUser
        result["created"] = self.created
        result["secondUser"] = self.secondUser
        result["lastMessageDate"] = self.lastMessageDate
//        result["username1"] = self.username1
//        result["username2"] = self.username2
        return result
    }
    
    var channelID:String {
        guard let first = self.firstUser else {
            return "user_error"
        }
        guard let created = self.created else {
            return "data_non_avaliable"
        }
        return first+"|"+created
    }


}
