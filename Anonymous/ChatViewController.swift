

import UIKit
import Firebase
import JSQMessagesViewController

final class ChatViewController: JSQMessagesViewController{
  
  // MARK: Properties
  
  // MARK: View Lifecycle
    var messages = [JSQMessage]()
    var channelRef: DatabaseReference?
    var channel: Channel? {
        didSet {
            title = channel?.name
        }
    }
    
    private lazy var messageRef : DatabaseReference = self.channelRef!.child("messages")
    private var newMessageRefhandle : DatabaseHandle?
    lazy var outgoingBubbleImageView : JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView : JSQMessagesBubbleImage = self.setupIncomingBubble()
    
  override func viewDidLoad() {
    super.viewDidLoad()
    self.senderId = Auth.auth().currentUser?.uid
    collectionView!.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
    collectionView!.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
    observeMessages()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  }
  
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        let itemRef = self.messageRef.childByAutoId()
        let messageItem = [
            "senderId" : senderId!,
            "senderName" : senderDisplayName!,
            "text" : text!
        ]
        itemRef.setValue(messageItem)
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        finishSendingMessage()
    }
    
  // MARK: Collection view data source (and related) methods
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == senderId{
            return outgoingBubbleImageView
        }else{
            return incomingBubbleImageView
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        if message.senderId == senderId{
            
            cell.textView.textColor = UIColor.white
        }else{
            cell.textView.textColor = UIColor.black
        }
        return cell
    }
    
  
    private func addMessage( withId id : String, name : String , text : String){
        
        if let message = JSQMessage(senderId: id, displayName: name, text: text){
            messages.append(message)
        }
    }
  
    private func observeMessages(){
        
        messageRef = channelRef!.child("messages")
        let messageQuery = messageRef.queryLimited(toLast: 25)
        newMessageRefhandle = messageQuery.observe(.childAdded, with: {(snapshot)
            -> Void in
            let messageData = snapshot.value as! Dictionary<String, String>
            
            if let id = messageData["senderId"] as String!, let name = messageData["senderName"] as String! , let text = messageData["text"] as String!, text.characters.count > 0{
                
                self.addMessage(withId: id, name: name, text: text)
                self.finishReceivingMessage()
            }else{
                print("Error! Could not decode message data")
            }
        
        })
    }

    private func setupOutgoingBubble() -> JSQMessagesBubbleImage{
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    private func setupIncomingBubble() -> JSQMessagesBubbleImage{
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        
    }
    
    
  
  
}
