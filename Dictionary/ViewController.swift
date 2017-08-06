//
//  ViewController.swift
//  Dictionary
//
//  Created by Julian Dunskus on 06.08.17.
//  Copyright © 2017 Julian Dunskus. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
	
	let lookUpQueue = DispatchQueue(label: "Looking Up Words")
	var currentLookUpOperation = UUID()
	var dictionaryController: UIReferenceLibraryViewController? {
		willSet {
			// TODO how much of this is necessary?
			dictionaryController?.willMove(toParentViewController: nil)
			dictionaryController?.view.removeFromSuperview()
			dictionaryController?.removeFromParentViewController()
		}
		didSet {
			if let new = dictionaryController {
				self.addChildViewController(new)
				self.containerView.addSubview(new.view)
				self.dictionaryController = new
			}
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		textField.becomeFirstResponder()
		
		// so as not to intercept scrolling
		keyboardHidingView.touchDetected = { [unowned self] (point, event) in
			let location = self.view.convert(point, to: self.containerView)
			if self.containerView.point(inside: location, with: event) {
				self.textField.resignFirstResponder()
			}
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		if UIApplication.shared.applicationState != .active {
			dictionaryController = nil
		}
	}
	
	@IBOutlet weak var textField: UITextField!
	@IBOutlet weak var containerView: UIView!
	@IBOutlet weak var keyboardHidingView: PassThroughView!
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var helpingLabel: UILabel!
	
	@IBAction func textChanged() {
		let term = textField.text!
		let id = UUID()
		currentLookUpOperation = id
		DispatchQueue.main.async {
			self.dictionaryController = nil
			self.activityIndicator.startAnimating()
			self.helpingLabel.text = ""
		}
		lookUpQueue.async {
			guard self.currentLookUpOperation == id else { return }
			if UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: term) {
				DispatchQueue.main.async {
					guard self.currentLookUpOperation == id else { return }
					self.activityIndicator.stopAnimating()
					self.dictionaryController = UIReferenceLibraryViewController(term: term)
				}
			} else {
				DispatchQueue.main.async {
					guard self.currentLookUpOperation == id else { return }
					self.activityIndicator.stopAnimating()
					self.helpingLabel.text = term.isEmpty ? "" : "no matches for \"\(term)\""
				}
			}
		}
	}
}

class PassThroughView: UIView {
	
	var touchDetected: ((CGPoint, UIEvent?) -> Void)?
	
	override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
		touchDetected?(point, event) // cheeky
		return false
	}
}
