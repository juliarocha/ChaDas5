//
//  Channel.swift
//  ChaDas5
//
//  Created by Nathalia Inacio on 29/12/18.
//  Copyright © 2018 Julia Maria Santos. All rights reserved.
//


import UserNotifications
import CloudKit

struct ChannelUser {
    var uid: String
    var displayName: String?
}

class Channel {
  
    var id: CKRecord.ID?
    var ownerID: String
    var fromStory: String
    var storyAuthor: String
    var lastMessageDate: String
    var lastMessageID: String
    var lastOpenedByMe: String
    var hasNonReadMessages: Bool = false
  
    init(fromStory: Story, lastMessageDate: Date = Date.distantFuture) {
        self.ownerID = MeUser.instance.email
        self.fromStory = fromStory.id?.recordName ?? ""
        self.storyAuthor = fromStory.author
        self.lastMessageDate = lastMessageDate.keyString
        self.lastOpenedByMe = Date.distantFuture.keyString
        
        // CHECK
        self.lastMessageID = fromStory.id?.recordName ?? ""
        
        self.id = nil
    }
    
    init?(from record:CKRecord, completion: @escaping (Channel?, String?) -> Void)  {
        guard let recordOwner           = record["owner"] as? String,
              let recordFromStory       = record["fromStory"] as? String,
              let recordLastMessageDate = record["lastMessageDate"] as? String,
              let recordLastMessageID   = record["lastMessageID"] as? String,
              let recordStoryAuthor     = record["storyAuthor"] as? String
        else {
            completion(nil, "Error")
            return nil
        }
        if recordOwner == MeUser.instance.email {
            lastOpenedByMe = record["lastOpenByOwner"] as? String ?? ""
        } else {
            lastOpenedByMe = record["lastOpenByStoryAuthor"] as? String ?? ""
        }
        ownerID = recordOwner
        fromStory = recordFromStory
        lastMessageDate = recordLastMessageDate
        lastMessageID = recordLastMessageID
        storyAuthor = recordStoryAuthor
        id = record.recordID
        if lastOpenedByMe < lastMessageDate {
            self.hasNonReadMessages = true
        }
        completion(self, nil)
    }
    
    var asCKRecord:CKRecord {
        let record = CKRecord(recordType: "Channel")
        record.setObject(self.fromStory as __CKRecordObjCValue?, forKey: "fromStory")
        record.setObject(self.ownerID as __CKRecordObjCValue?, forKey: "owner")
        record.setObject(self.lastMessageDate as __CKRecordObjCValue?, forKey: "lastMessageDate")
        record.setObject(self.lastMessageID as __CKRecordObjCValue?, forKey: "lastMessageID")
        record.setObject(self.storyAuthor as __CKRecordObjCValue?, forKey: "storyAuthor")
        record.setObject(Date.distantPast.keyString as __CKRecordObjCValue?, forKey: "lastOpenByOwner")
        record.setObject(Date.distantPast.keyString as __CKRecordObjCValue?, forKey: "lastOpenByStoryAuthor")
        return record
    }

  }
