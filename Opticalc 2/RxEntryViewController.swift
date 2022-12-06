//
//  RxEntryViewController.swift
//  Opticalc 2
//
//  Created by Robert McQualter on 7/11/18.
//  Copyright © 2018 Robert McQualter. All rights reserved.
//

import UIKit

protocol RxEntryDelegate {
	func rxEntryDoneWithRx(_ newRx: LensPrescription?)
}

class RxEntryViewController: UIViewController {
	let axis_interval = 5
	
	@IBOutlet weak var rxPicker: UIPickerView?
	@IBOutlet weak var rxLabel: UILabel?
	@IBOutlet weak var plusMinusCylFormSegControl: UISegmentedControl!
	
	var delegate: RxEntryDelegate?
	var lensRx: LensPrescription? {
		didSet {
			self.setPickerToPower(animated: false)
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	override func viewWillAppear(_ animated: Bool) {
		self.setPickerToPower(animated: false)
	}
	
	@IBAction func doneTapped(_ sender: Any) {
		delegate?.rxEntryDoneWithRx(lensRx)
	}
	
	@IBAction func cancelTapped(_ sender: Any) {
		delegate?.rxEntryDoneWithRx(nil)
	}
	
	@IBAction func plusMinusCylValueChanged(_ sender: UISegmentedControl) {
		self.lensRx?.plusCylForm = (sender.selectedSegmentIndex == 0)
		self.rxPicker?.reloadAllComponents()
		self.setPickerToPower(animated: true)
	}
	
	func updateResultLabel() {
		rxLabel?.text = lensRx?.rxString
	}
	
	func rxChanged() {
		if let picker = rxPicker {
			let sphRow = picker.selectedRow(inComponent: 0)
		
			var newSph, newCyl, newAxis: Double
			
			newSph = Double(sphRow - 20)
			if newSph > 0 {
				newSph -= 1
			}
			
			
			newSph += Double(picker.selectedRow(inComponent: 1)) / (sphRow <= 20 ? -4.0 : +4.0)
			newCyl = 0.25 * Double(picker.selectedRow(inComponent: 2))
			newAxis = Double((picker.selectedRow(inComponent: 3) + 1) * axis_interval)
		
			if !self.lensRx!.plusCylForm {
				newCyl = -newCyl
			}
			
			self.lensRx = LensPrescription(sph: newSph, cyl: newCyl, axis: newAxis, vertex: self.lensRx!.vertex, plusCyl: self.lensRx!.plusCylForm)
			
			// Redisplay result label.
			self.updateResultLabel()
		}

	}
	
	func setPickerToPower(animated: Bool) {
		// Set the picker to the current power values.
		var sphRow, sphDecRow, cylRow, axisRow : Int
		
		guard let power = lensRx else {
			return
		}
		
		
		sphRow = Int(power.sph)
		sphDecRow = Int(abs((power.sph - Double(sphRow)) * 4.0)) // remainder of sphere * 4.
		sphRow += 20;
		if (power.sph >= 0) {
			sphRow += 1
		}
		
		cylRow = Int(abs(power.cyl * 4.0))
		axisRow = Int(power.axis) / axis_interval - 1
		
		rxPicker?.selectRow(sphRow, inComponent: 0, animated: animated)
		rxPicker?.selectRow(sphDecRow, inComponent: 1, animated: animated)
		rxPicker?.selectRow(cylRow, inComponent: 2, animated: animated)
		rxPicker?.selectRow(axisRow, inComponent: 3, animated: animated)
		
		self.plusMinusCylFormSegControl?.selectedSegmentIndex = (power.plusCylForm ? 0 : 1)
		
		self.updateResultLabel()
	}
}

extension RxEntryViewController: UIPickerViewDataSource, UIPickerViewDelegate {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 4
	}
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		var retVal: Int = 0
		
		switch (component) {
		case 0: // Sph power: Support -20 to +20 = 41
			retVal = 42
			
		case 1: // Sph power decimal = 4
			retVal = 4
			
		case 2: // Cyl power: Support 0 to -9.75 = 40
			retVal = 40
			
		case 3: // Axis: Support 0 to 175 in 5º steps = 36
			retVal = 180 / axis_interval;
			
		default:
			break;
		}
		
		return retVal;
	}
	
	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		
		var retval = "";
		
		switch (component) {
		case 0: // Sphere power. Return string value, eg. +2. or -17.
			if (row == 20) {
				// -0
				retval = String.localizedStringWithFormat("%1.0f", -0.001)
			} else {
				retval = String.localizedStringWithFormat("%+3i", (row < 20 ? row - 20 : row - 21))
			}
			
		case 1: // Sphere power decimal. Returns 00, 25, 50 or 75
			let str = String.localizedStringWithFormat("%.2f", (Float(row) / 4.0))
			let indexStart = str.index(str.startIndex, offsetBy:1) // Get rid of the leading zero.
			retval = String(str[indexStart...])
			
		case 2: // Cyl power. Returns eg. -9.75, -0.25, DS, or +9.75, etc. if user has selected plus cyls.
			if (row == 0) {
				retval = NSLocalizedString("DS", comment: "DS")
			} else {
				let divider: Float = self.lensRx?.plusCylForm ?? false ? 4.0 : -4.0
				retval = String.localizedStringWithFormat("/ %+.2f", (Float(row) / divider))
			}
			
		case 3: // Axis power. Returns eg. 5, 10, 175, 180 right-justified.
			retval = String.localizedStringWithFormat("x %3i", ((row + 1) * axis_interval))
			
		default:
			break;
		}
		
		return retval;
	}
	
	func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
		var retval: CGFloat
		
		switch (component) {
		case 0:
			retval = 62 //52
			
		case 1:
			retval = 54 //46
			
		case 2:
			retval = 90 //88
			
		case 3:
			retval = 74 //68
			
		default:
			retval = 0
		}
		
		return retval
	}
	
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		self.rxChanged()
	}
}
