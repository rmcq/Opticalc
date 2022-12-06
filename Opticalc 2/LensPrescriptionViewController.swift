//
//  LensPrescriptionViewController.swift
//  Opticalc 2
//
//  Created by Robert McQualter on 5/11/18.
//  Copyright © 2018 Robert McQualter. All rights reserved.
//

import UIKit

protocol LensPrescriptionViewControllerProtocol {
	func rxChanged(newRx: LensPrescription, from lpVC: LensPrescriptionViewController)
	func showRxEntry(_ viewController: UIViewController, animated: Bool)
	func dismissRxEntry()
}

class LensPrescriptionViewController: UIViewController {

	@IBOutlet weak var sphTF: UITextField!
	@IBOutlet weak var cylTF: UITextField!
	@IBOutlet weak var axisTF: UITextField!
	@IBOutlet weak var titleLabel: UILabel!
	
	fileprivate var clNotChanged = true
	
	var delegate: LensPrescriptionViewControllerProtocol?
	var rxTitle: String? {
		didSet {
			titleLabel.text = rxTitle
		}
	}
	
	var lensRx: LensPrescription? {
		didSet {
			// When lens prescription is set, we need to update the UI.
			updateUI()
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

	func updateUI() {
		if let rx = lensRx {
			sphTF.text = String.localizedStringWithFormat("%+.2f", rx.sph)
			if rx.cyl != 0 {
				cylTF.text = String.localizedStringWithFormat("%.2f", rx.cyl)
			} else {
				cylTF.text = ""
			}
			
			axisTF.text = rx.axisText
		}
	}

	@IBAction func wheelButtonTapped(_ sender: UIButton) {
		// Show RxEntryViewController
		let storyBoard = UIStoryboard(name: "RxEntryStoryboard", bundle: nil)
		let vc = storyBoard.instantiateViewController(withIdentifier: "RxEntry") as! UINavigationController
		if let rxVC = vc.topViewController as? RxEntryViewController {
			rxVC.lensRx = self.lensRx
			rxVC.title = self.rxTitle
			rxVC.delegate = self
			delegate?.showRxEntry(vc, animated: true)
		}
		
	}
	
	@IBAction func sphTextDone(_ sender: UITextField) {
		let val = LensPrescription.doubleFromSphString(sender.text ?? "")
		lensRx!.sph = val
		sender.text = String.localizedStringWithFormat("%+.2f", lensRx!.sph)
		rxChanged()
	}
	
	@IBAction func cylTextDone(_ sender: UITextField) {
		let val = LensPrescription.doubleFromCylString(sender.text ?? "")
		lensRx!.cyl = val
		if lensRx!.cyl != 0 {
			cylTF.text = String.localizedStringWithFormat("%.2f", lensRx!.cyl)
		} else {
			cylTF.text = ""
		}
		rxChanged()
	}
	
	@IBAction func axisTextDone(_ sender: UITextField) {
		let val = LensPrescription.doubleFromString(sender.text ?? "")
		lensRx!.axis = val
		sender.text = lensRx?.axisText
		rxChanged()
	}
	
	func rxChanged() {
		delegate?.rxChanged(newRx: lensRx!, from: self)
	}

}

extension LensPrescriptionViewController: RxEntryDelegate {
	func rxEntryDoneWithRx(_ newRx: LensPrescription?) {
		delegate?.dismissRxEntry()
		if newRx != nil {
			self.lensRx = newRx
			self.rxChanged()
		}
	}
}

extension LensPrescriptionViewController: UITextFieldDelegate {
	
	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		activeTextField = textField
		//lastOffset = self.scrollView.contentOffset
		return true
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		switch textField {
		case sphTF:
			cylTF.becomeFirstResponder()
		case cylTF:
			axisTF.becomeFirstResponder()
		default:
			activeTextField?.resignFirstResponder()
			activeTextField = nil
		}
		
		return true
	}
	
}
