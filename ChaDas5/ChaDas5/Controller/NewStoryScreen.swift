//
//  NewStoryScreen.swift
//  ChaDas5
//
//  Created by Gabriela Szpilman on 29/11/18.
//  Copyright © 2018 Julia Maria Santos. All rights reserved.
//

import UIKit

class NewStoryScreen: UIViewController, UITextViewDelegate {
    
    //outlets
    
    @IBOutlet weak var newStoryLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    
    
    
    
    //actions
    @IBAction func dismissButton(_ sender: Any) {
        dismiss()
    }
    @IBAction func sendButton(_ sender: Any) {
        
        let alert = UIAlertController(title: "Seu relato possui conteúdo sensível?", message: "", preferredStyle: .alert)
        let yes = UIAlertAction(title: "Sim", style: .default, handler: { (action) -> Void in
            
            _ = Story(conteudo: self.newStoryTextView.text, gatilho: 5)
            self.dismiss()
        })
        
        let no = UIAlertAction(title: "Não", style: .default, handler: { (action) -> Void in
                
            _ = Story(conteudo: self.newStoryTextView.text, gatilho: 0)
            self.dismiss()
            })
        
        let cancelar = UIAlertAction(title: "Cancelar", style: .cancel ) { (action) -> Void in
            alert.dismiss(animated: true, completion: nil)
        }
        alert.addAction(yes)
        alert.addAction(no)
        alert.addAction(cancelar)
        self.present(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.buttonOrange
        
    }
    
    @IBOutlet weak var newStoryTextView: UITextView!
    
    override func viewDidLoad() {
        
        hideKeyboardWhenTappedAround()
        
        newStoryTextView.delegate = self
        
        newStoryLabel.textColor = UIColor.gray
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        newStoryLabel.text = ""
        newStoryTextView.text = String()
      
    }

    
    
    @objc private func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
}
