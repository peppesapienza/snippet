import UIKit
import FirebaseAuth
import FBSDKLoginKit

struct FacebookUser {
    var id: String
    var token: String
    var name: String
    var gender: String
}


class FBRequest {
    
    func name(completionHandler: @escaping (String, String) -> ()) {
        FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"name, gender"]).start { (req, result, error) in
            guard let dict = result as? [String:String], let name = dict["name"], let gender = dict["gender"] else { return }
            completionHandler(name, gender)
        }
    }
}

class FIRFacebookUser {

    init(_ fbUser: FacebookUser) {
       self.fbUser = fbUser
    }

    let fbUser: FacebookUser
    
    var isLogged: Bool {
        return Auth.auth().currentUser != nil ? true : false
    }
    
    func login(completionHandler: @escaping () -> (), errorHandler: (Error)->()) {
        let credential = FacebookAuthProvider.credential(withAccessToken: fbUser.token)
        
        Auth.auth().signIn(with: credential) { (user, error) in
            guard let user = user else {
                errorHandler(error!)
                return
            }
            
            print("[Firebase] Welcome:", fbUser.name, fbUser.id, user.uid)
            
            DispatchQueue.global().async {
                let change = user.createProfileChangeRequest()
                change.displayName = fbUser.name
                change.photoURL = URL.init(string: "http://graph.facebook.com/\(fbUser.id)/picture?type=large")
                change.commitChanges(completion: nil)
            }
        
            completionHandler()
        }
    }
}

/* HOW TO USE */

let manager = FBSDKLoginManager.init()
manager.loginBehavior = .native
manager.logIn(withReadPermissions: ["email", "public_profile"], from: self, handler: { (result, error) in
    guard error == nil else {
        print(error!.localizedDescription)
        return
    }
    
    guard
        let loginResult = result,
        let token = loginResult.token?.tokenString,
        let fbId = loginResult.token?.userID
    else {
        return
    }
        
    FBRequest.init().name(completionHandler: { (name, gender) in
                
        let fb_user = FacebookUser.init(id: fbId, token: token, name: name, gender: gender)
        
        FIRFacebookUser(fb_user).login(completionHandler: {
           // do something
        }, errorHandler: { error in 
           print(error.localizedDescription)
        })
    })
})
