//
//  SettingsViewController.swift
//  Opticalc 2
//
//  Created by Robert McQualter on 7/11/18.
//  Copyright © 2018 Robert McQualter. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()


    }
	
	override func viewWillAppear(_ animated: Bool) {
		// Set localized text in seg controls.
		let ohOne = String.localizedStringWithFormat("%0.2f", 0.01)
		let ohTwelve = String.localizedStringWithFormat("%0.2f", 0.12)
		let ohTwoFive = String.localizedStringWithFormat("%0.2f", 0.25)
		
		powerSegControl.setTitle(ohOne, forSegmentAt: 0)
		powerSegControl.setTitle(ohTwelve, forSegmentAt: 1)
		powerSegControl.setTitle(ohTwoFive, forSegmentAt: 2)
		
		axisSegControl.setTitle(String.localizedStringWithFormat("%dº", 1), forSegmentAt: 0)
		axisSegControl.setTitle(String.localizedStringWithFormat("%dº", 5), forSegmentAt: 1)
		axisSegControl.setTitle(String.localizedStringWithFormat("%dº", 10), forSegmentAt: 2)
		
		// Set the current values.
		ocularRxSwitch.isOn = settings.useOcularRx
		vertexSlider.setValue(Float(settings.patientRx!.vertex), animated: false)
		vertexTextField.text = String.localizedStringWithFormat("%.0f", settings.patientRx!.vertex)
		plusCylSwitch.isOn = settings.plusCylDefault
		
		switch settings.powerPrecision {
		case 0..<5:
			powerSegControl.selectedSegmentIndex = 2
			
		case 5..<9:
			powerSegControl.selectedSegmentIndex = 1
			
		default:
			powerSegControl.selectedSegmentIndex = 0
			
		}
		
		switch settings.axisPrecision {
		case 0..<2:
			axisSegControl.selectedSegmentIndex = 0
			
		case 2..<6:
			axisSegControl.selectedSegmentIndex = 1
			
		default:
			axisSegControl.selectedSegmentIndex = 2
			
		}
	}
    
	@IBOutlet weak var ocularRxSwitch: UISwitch!
	@IBOutlet weak var powerSegControl: UISegmentedControl!
	@IBOutlet weak var axisSegControl: UISegmentedControl!
	@IBOutlet weak var vertexSlider: UISlider!
	@IBOutlet weak var vertexTextField: UITextField!
	@IBOutlet var plusCylSwitch: UISwitch!
	
	
	@IBAction func ocularRxSwitchChanged(_ sender: UISwitch) {
		settings.useOcularRx = sender.isOn
	}
	
	@IBAction func plusCylSwitchChanged(_ sender: UISwitch) {
		settings.plusCylDefault = sender.isOn
	}
	
	@IBAction func powerSegChanged(_ sender: UISegmentedControl) {
		switch sender.selectedSegmentIndex {
		case 0:
			settings.powerPrecision = 100
		case 1:
			settings.powerPrecision = 8
		default:
			settings.powerPrecision = 4
		}
	}
	
	@IBAction func axisSegChanged(_ sender: UISegmentedControl) {
		switch sender.selectedSegmentIndex {
		case 0:
			settings.axisPrecision = 1
		case 1:
			settings.axisPrecision = 5
		default:
			settings.axisPrecision = 10
		}
	}
	
	@IBAction func vertexSliderChanged(_ sender: UISlider) {
		vertexTextField.text = String.localizedStringWithFormat("%.0f", sender.value)
		settings.patientRx?.vertex = Double(sender.value)
	}

	@IBAction func vertexTextChanged(_ sender: UITextField) {
		if let text = sender.text {
			if let valNum = NumberFormatter().number(from: text) {
				vertexSlider.setValue(valNum.floatValue, animated: true)
				vertexSliderChanged(vertexSlider)
			}
		}
	}
}

extension SettingsViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		
		return true
	}
}
