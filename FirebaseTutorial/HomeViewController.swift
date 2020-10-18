//
//  HomeViewController.swift
//  FirebaseTutorial
//
//  Created by Joan Paredes on 10/14/20.
//

import UIKit
import FirebaseAuth
import GoogleSignIn
import FirebaseCrashlytics
import FirebaseRemoteConfig
import FirebaseFirestore

enum ProviderType: String {
    case basic
    case google
}

class HomeViewController: UIViewController {
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var providerLabel: UILabel!
    @IBOutlet weak var errorButton: UIButton!
    @IBOutlet weak var addressTextField: UITextField!
    
    @IBOutlet weak var phonenumberTextField: UITextField!
    @IBOutlet weak var closeSessionButton: UIButton!
    
    private let email: String
    private let provider: ProviderType
    
    private let bd = Firestore.firestore()
    
    init(email: String, provider: ProviderType){
        self.email = email
        self.provider = provider
        super.init(nibName: "HomeViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Inicio"
        
        navigationItem.setHidesBackButton(true, animated: false)
        
        emailLabel.text = email
        providerLabel.text = provider.rawValue
        
        //Guardamos los datos del usuario
        let defaults = UserDefaults.standard
        defaults.set(email,forKey: "email")
        defaults.set(provider.rawValue, forKey: "provider")
        defaults.synchronize()
        
        //Remote config
        let remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.fetchAndActivate {(status, error) in
            if status != .error{
                let showErrorButton = remoteConfig.configValue(forKey: "show_error_button").boolValue
                
                let errorButtonText = remoteConfig.configValue(forKey: "error_button_text").stringValue
               
                
                DispatchQueue.main.async {
                    self.errorButton.isHidden = !showErrorButton
                    self.errorButton.setTitle(errorButtonText, for: .normal)
                }
            }
        }
    }

    @IBAction func closeSessionButton(_ sender: Any) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "email")
        defaults.removeObject(forKey: "provider")
        
        switch provider {
        case .basic:
           firebaseLogOut()
        case .google:
            GIDSignIn.sharedInstance()?.signOut()
            firebaseLogOut()
        }
        navigationController?.popViewController(animated: true)
    }
    
    private func firebaseLogOut(){
        do{
            try Auth.auth().signOut()
        }catch {
                //se ha producido un error
            }
    }
    @IBAction func errorButtonAction(_ sender: Any) {
       
        //Enviar el ID de usuario
        Crashlytics.crashlytics().setUserID(email)
        //Envio de claves personalizadas
        Crashlytics.crashlytics().setCustomValue(provider, forKey: "PROVIDER")
        //Envio de Log de errores
        Crashlytics.crashlytics().log("Hemos pulsado el botón Forzar Error")
        fatalError()
        
    }
    @IBAction func saveButtonAction(_ sender: Any) {
        view.endEditing(true)
        
        bd.collection("users").document(email).setData([
                                                        "provider":provider.rawValue,
                                                        "address": addressTextField.text ?? "",
                                                        "phone":phonenumberTextField.text ?? ""])
    }
    @IBAction func getButtonAction(_ sender: Any) {
        view.endEditing(true)
        bd.collection("users").document(email).getDocument{
           (documentSnapshot, error) in
            if let document = documentSnapshot, error == nil{
                if let address = document.get("address") as? String {
                    self.addressTextField.text = address
                }else{
                    self.addressTextField.text = ""
                }
                if let phone = document.get("phone") as? String{
                    self.phonenumberTextField.text = phone
                }else{
                    self.phonenumberTextField.text = ""
                }
                }else{
                    self.addressTextField.text = ""
                    self.phonenumberTextField.text = ""
            }
        }
    }
    @IBAction func deleteButtonAction(_ sender: Any) {
        view.endEditing(true)
        
        bd.collection("users").document(email).delete()
    }
}

