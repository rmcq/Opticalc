//
//  FirstViewController.swift
//  Opticalc 2
//
//  Created by Robert McQualter on 4/11/18.
//  Copyright © 2018 Robert McQualter. All rights reserved.
//

import UIKit

class PtRxViewController: UIViewController {

	var specRxVC: LensPrescriptionViewController?
	var nomCLRxVC: LensPrescriptionViewController?
	var clORxVC: LensPrescriptionViewController?
	
	@IBOutlet weak var rxView: UIView!
	@IBOutlet weak var nomCLView: UIView!
	@IBOutlet weak var clORxView: UIView!
	@IBOutlet weak var ocularRxLabel: UILabel!
	@IBOutlet weak var sphEquivalentLabel: UILabel!
	@IBOutlet weak var apparentCLPowerLabel: UILabel!
	@IBOutlet weak var apparentRotationLabel: UILabel!
	@IBOutlet weak var lensToOrderLabel: UILabel!
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var contentHeightConstraint: NSLayoutConstraint!
	@IBOutlet weak var observedRotationTF: UITextField!
	@IBOutlet weak var rotationDirectionSC: UISegmentedControl!
	@IBOutlet var clPlusORxLabel: UILabel!
	@IBOutlet var simpleLensRotationLabel: UILabel!
	@IBOutlet var clPlusORxRotationLabel: UILabel!
	
	var keyboardHeight: CGFloat = 0
	var lastOffset: CGPoint = CGPoint()
	
	fileprivate var isVisible = false
	fileprivate var clRxChanged = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		// Create a LPVC.
		specRxVC = LensPrescriptionViewController(nibName: "LensPrescriptionViewController", bundle: nil)
		nomCLRxVC = LensPrescriptionViewController(nibName: "LensPrescriptionViewController", bundle: nil)
		clORxVC = LensPrescriptionViewController(nibName: "LensPrescriptionViewController", bundle: nil)
		
		rxView.addSubview((specRxVC?.view)!)
		nomCLView.addSubview(nomCLRxVC!.view)
		clORxView.addSubview(clORxVC!.view)
		
		specRxVC?.delegate = self
		nomCLRxVC?.delegate = self
		clORxVC?.delegate = self
		
		NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: nil) { (notification) in
			self.keyboardWillShow(notification)
		}
		NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: nil) { (notification) in
			self.keyboardWillHide(notification)
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		if specRxVC?.lensRx == nil {
			settings.patientRx?.plusCylForm = settings.plusCylDefault
			specRxVC?.lensRx = settings.patientRx
			specRxVC?.rxTitle = "Subjective Refraction"
		}
		
		if nomCLRxVC?.lensRx == nil {
			nomCLRxVC?.lensRx = settings.toricCLRx
			nomCLRxVC?.rxTitle = "Nominal C/L Power"
		}
		
		if clORxVC?.lensRx == nil {
			clORxVC?.lensRx = settings.toricORx
			clORxVC?.rxTitle = "C/L Over-Refraction"
		}
		
		// Recalculate the c/l Rx (in case the precision has changed).
		if !clRxChanged {
			nomCLRxVC?.lensRx = specRxVC?.lensRx?.newLensPrescriptionOcularRxWithPowerPrecision(settings.powerPrecision, axisPrecision: settings.axisPrecision)
		}
		
		if let rot = settings.observedRotation {
			self.observedRotationTF.text = String.localizedStringWithFormat("%.0f", rot)
		}
		if settings.rotationClockwise {
			self.rotationDirectionSC.selectedSegmentIndex = 0
		} else {
			self.rotationDirectionSC.selectedSegmentIndex = 1
		}
		
		calcPowers()
		isVisible = true
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		isVisible = false
	}
	
	func keyboardWillShow(_ notification: Notification) {
		
		if keyboardHeight != 0 {
			return
		}

		// Make sure this view controller is currently visible.
		if !isVisible {
			return
		}
		self.lastOffset = self.scrollView.contentOffset

		if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
			keyboardHeight = keyboardSize.height
			// so increase contentView's height by keyboard height
			UIView.animate(withDuration: 0.3, animations: {
				self.contentHeightConstraint.constant += self.keyboardHeight
			})
			// move if keyboard hide input field
			// Find location of textField within contentView.
			let frameInContent = activeTextField?.convert((activeTextField?.frame)!, to: self.scrollView)
			let distanceToBottom = self.scrollView.frame.size.height - (frameInContent?.origin.y)! - (frameInContent?.size.height)!
			let collapseSpace = keyboardHeight - distanceToBottom
			if collapseSpace < 0 {
				// no collapse
				return
			}
			// set new offset for scroll view
			UIView.animate(withDuration: 0.3, animations: {
				// scroll to the position above keyboard 10 points
				self.scrollView.contentOffset = CGPoint(x: self.scrollView.contentOffset.x, y: collapseSpace + 10)
			})
		}
	}
	
	func keyboardWillHide(_ notification: Notification) {
		UIView.animate(withDuration: 0.3) {
			self.contentHeightConstraint.constant -= self.keyboardHeight
			self.scrollView.contentOffset = self.lastOffset
		}
		keyboardHeight = 0
	}

	@IBAction func resetButtonTapped(_ sender: Any) {
		// Reset fields.
		specRxVC?.lensRx = settings.defaultRx
		nomCLRxVC?.lensRx = specRxVC?.lensRx?.newLensPrescriptionOcularRxWithPowerPrecision(settings.powerPrecision, axisPrecision: settings.axisPrecision, plusCyl: settings.plusCylDefault)
		clORxVC?.lensRx = LensPrescription(plusCyl: settings.plusCylDefault)
		
		clRxChanged = false
		self.observedRotationTF.text = nil
		self.rotationDirectionSC.selectedSegmentIndex = 0
		settings.observedRotation = nil
		settings.rotationClockwise = true
		
		calcPowers()
		settings.saveSettings()
	}
	
	@IBAction func rotationValueChanged(_ sender: UISegmentedControl) {
		settings.rotationClockwise = (sender.selectedSegmentIndex == 0)
		settings.saveSettings()
		calcPowers()
	}
	
	func calcPowers() {
		// Called whenever the powers have changed.

		let oc = OpticalCalculator()
		oc.patientRx = specRxVC!.lensRx
		oc.overRx = clORxVC!.lensRx
		oc.nominalCLRx = nomCLRxVC!.lensRx
		oc.axisPrecision = settings.axisPrecision
		oc.powerPrecision = settings.powerPrecision
		oc.useOcularRx = settings.useOcularRx
		oc.defaultToPlusCyl = settings.plusCylDefault
		
		oc.calcToricRx()
		oc.calcRxFromOverRx()
		oc.effectiveCLRx?.plusCylForm = settings.plusCylDefault
		
		self.apparentCLPowerLabel.text = oc.effectiveCLRx?.rxString
		self.clPlusORxLabel.text = oc.lensToOrderFromNominalRx?.rxString
		
		// Set the rotation display.
		apparentRotationLabel.text = oc.stringFromAxis(oc.rotation, shortString: false)
		
		// Display lens to order.
		lensToOrderLabel.text = oc.lensToOrder?.rxString
		
		// Spherical lens details.
		var ocularRx = LensPrescription(sph: specRxVC!.lensRx!.ocularSphere, cyl: specRxVC!.lensRx!.ocularCyl, axis: specRxVC!.lensRx!.axis, vertex: 0)
		ocularRx.plusCylForm = settings.plusCylDefault
		
		ocularRxLabel.text = ocularRx.rxString
		sphEquivalentLabel.text = String.localizedStringWithFormat("%+.2f", specRxVC!.lensRx!.ocularSphericalEquivalentWithPrecision(settings.powerPrecision))

		// Calculate rotation of c/l + ORx.
		if let rot = oc.rotationFromNominalRx {
			clPlusORxRotationLabel.text = oc.stringFromAxis(rot, shortString: false)
		} else {
			clPlusORxRotationLabel.text = nil
		}

		// Calculate new axis from rotation.
		if let rotation = settings.observedRotation, let nomRx = oc.patientRx {
			var newAxis = nomRx.axis
			if settings.rotationClockwise {
				newAxis += rotation
			} else {
				newAxis -= rotation
			}

			if newAxis > 180 {
				newAxis -= 180
			} else if newAxis < 0 {
				newAxis += 180
			}
			
			simpleLensRotationLabel.text = String.localizedStringWithFormat("%.0fº", newAxis)
		} else {
			simpleLensRotationLabel.text = nil
		}
		
		print("Calc Powers")
	}
}

extension PtRxViewController: UITextFieldDelegate {
	func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
		activeTextField = textField
		//lastOffset = self.scrollView.contentOffset
		return true
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if (textField == observedRotationTF) {
			// A rotation has been provided. Validate it, then recalculate powers.
			settings.observedRotation = nil
			if let tft = textField.text {
				if let rotation = Double(tft) {
					if rotation > 90 || rotation < -90 {
						textField.text = nil
					} else {
						settings.observedRotation = rotation
					}
				}
			}
			
			settings.saveSettings()
			calcPowers()
		}
		
		activeTextField?.resignFirstResponder()
		activeTextField = nil
		return true
	}
}

// Need to distinguish between programmatic changes and user changes. Only want this to be called for user changes! (I think this has already been implemented).
extension PtRxViewController: LensPrescriptionViewControllerProtocol {
	func showRxEntry(_ viewController: UIViewController, animated: Bool) {
		self.present(viewController, animated: true, completion: nil)
	}
	
	func dismissRxEntry() {
		self.dismiss(animated: true, completion: nil)
	}
	
	
	func rxChanged(newRx: LensPrescription, from lpVC: LensPrescriptionViewController) {
		// Prescription has been changed.
		// Determine which Rx has changed.
		if lpVC == specRxVC {
			// Spec Rx. Update the appropriate fields.
			
			settings.patientRx = lpVC.lensRx
			// If the apparent c/l Rx field is empty, then set it now? -- really only want to do this after the subjective Rx entry is totally complete.
			//		-- How to do this???
			// If c/l Rx hasn't been changed yet, then update the c/l Rx.
			if !clRxChanged {
				nomCLRxVC?.lensRx = specRxVC?.lensRx?.newLensPrescriptionOcularRxWithPowerPrecision(settings.powerPrecision, axisPrecision: settings.axisPrecision)
				settings.toricCLRx = nomCLRxVC?.lensRx
			}
			calcPowers()
		} else if lpVC == clORxVC {
			// One of the toric lens fields updated.
			// Update the toric text if there's any over-refraction entered.
			calcPowers()
			settings.toricORx = lpVC.lensRx
			//clRxChanged = true
		} else {
			calcPowers()
			settings.toricCLRx = lpVC.lensRx
			clRxChanged = true
		}
		
		settings.saveSettings()
	}
	
}
