//
//  LensPrescription.swift
//  Opticalc 2
//
//  Created by Robert McQualter on 5/11/18.
//  Copyright © 2018 Robert McQualter. All rights reserved.
//

import UIKit

struct LensPrescription: Codable {

	fileprivate var _sph: Double
	fileprivate var _cyl : Double
	fileprivate var _axis: Double
	
	var vertex: Double
	var plusCylForm: Bool // Power stored internally as minus cyl. User will supply powers as plus cyl, and values / strings returned in plus cyl form.
	var noRx: Bool = true
	
	init(sph: Double, cyl: Double, axis: Double, vertex: Double) {
		if cyl > 0 {
			// User has provided plus cyl form. Assume that's what they also want it displayed as.
			self.plusCylForm = true
			self._sph = sph + cyl
			self._cyl = -cyl
			self._axis = axis + 90
			if self._axis > 180 {
				self._axis -= 180
			}
		} else {
			self.plusCylForm = false
			self._sph = sph
			self._cyl = cyl
			self._axis = axis
		}
		
		self.vertex = vertex
		self.noRx = false
	}
	
	init() {
		self.init(sph: 0, cyl: 0, axis: 0, vertex: 0)
		self.noRx = true
	}
	
	init(plusCyl: Bool) {
		self.init()
		self.plusCylForm = plusCyl
	}
	
	init(sph: Double, cyl: Double, axis: Double, vertex: Double, plusCyl:Bool) {
		// Always convert to minus cyl form first.
		var newSph = sph
		var newCyl = cyl
		var newAxis = axis
		
		if newCyl > 0 {
			newSph += cyl
			newCyl = -cyl
			newAxis += 90
			if newAxis > 180 {
				newAxis -= 180
			}
		}

		self.init(sph: newSph, cyl: newCyl, axis:newAxis, vertex: vertex)
		self.plusCylForm = plusCyl // In case it isn't set by the init function (if cyl is zero).
	}
	
//	 Getters and setters for _sph, _cyl and _axis
	var sph: Double {
		get {
			return self.plusCylForm ? _sph + _cyl : _sph
		}
		set {
			noRx = false
			if (self.plusCylForm) {
				_sph = newValue - _cyl;
			} else {
				_sph = newValue;
			}
		}
	}
	
	var cyl: Double {
		get {
			return self.plusCylForm ? -_cyl : _cyl

		}
		set {
			noRx = false
			if (newValue > 0) {
				_sph = _sph + (newValue + _cyl);
				_cyl = -newValue;
			} else {
				_cyl = newValue;
			}
		}
	}
	
	var axis: Double {
		get {
			var a = self.plusCylForm ? _axis + 90 : _axis
			if (a > 180) {
				a = a - 180
			}
			
			return a
		}
		set {
			noRx = false
			// Conveniently fix up the axis.
			_axis = newValue
			if (self.plusCylForm) {
				// User is supply plus cyl format, switch to minus cyl format.
				_axis += 90
			}
			while (_axis <= 0.0) {
				_axis += 180.0;
			}
			
			while (_axis > 180.0) {
				_axis -= 180.0;
			}
			
		}
	}
	
	// Computed values
	var ocularSphere: Double {
		get {
			let s = self.sph // Takes into account plus/minus cyl form.
			
			let ocSph = 1.0 / (1.0 / s - self.vertex / 1000)
			
			return ocSph;
		}
	}
	
	var ocularCyl: Double {
		get {
			let c = self.cyl
			let s = self.sph
	
			// Calculate the cylindrical component of the ocular Rx.
			let ocCyl = 1.0 / (1.0 / (s + c) - self.vertex / 1000) - 1.0 / (1.0 / s - self.vertex / 1000)
	
			return ocCyl;
		}
	}

	var horizontalPower: Double {
		get {
			return _sph + _cyl * sin(_axis * Double.pi / 180)
		}
	}
	
	var verticalPower: Double {
		get {
			return _sph + _cyl * cos(_axis * .pi / 180)
		}
	}

	
	var rxString: String {
		get {
			// Calculate an appropriate display string for the given Rx.
			// Blank Rx.
			if (self.noRx) {
				return "";
			}
	
			var resultString: String
			let c = self.cyl // Automatically converts to plus cyl form if required.
			let s = self.sph
			let a = self.axis
	
			if (abs(c) < 0.12) {
				if (abs(s) < 0.12) {
					resultString = NSLocalizedString("plano", comment: "Plano")
				} else {
					resultString = String.localizedStringWithFormat("%+0.2f %@", s, NSLocalizedString("DS", comment: "DS"));
				}
			} else {
				if (abs(s) < 0.12) {
					resultString = String.localizedStringWithFormat("%@ / %+.2f x %.0f", NSLocalizedString("plano", comment: "Plano"), c, a)
				} else {
					resultString = String.localizedStringWithFormat("%+.2f / %+.2f x %.0f", s, c, a)
				}
			}
	
			return resultString
		}
	}
	
	var transposedString: String {
		mutating get {
			self.plusCylForm = !self.plusCylForm
			let resultString = self.rxString
			self.plusCylForm = !self.plusCylForm
			return resultString
		}
	}
	
	var sphText: String {
		get {
			if (self.noRx) {
				return ""
			}
	
			var resultString: String
			let s = self.sph;
	
			if (fabs(s) < 0.12) {
				resultString = NSLocalizedString("plano", comment: "Plano");
			} else {
				resultString = String.localizedStringWithFormat("%+.2f", s);
			}
			return resultString
		}
	}
	
	var cylText: String {
		get {
			if (self.noRx) {
				return ""
			}
			
			var resultString:String
			let c = self.cyl
			let s = self.sph
	
			if (abs(c) < 0.12) {
				if (abs(s) < 0.12) {
					resultString = ""
				} else {
					resultString = NSLocalizedString("DS", comment: "DS")
				}
	
			} else {
				resultString = String.localizedStringWithFormat("%+.2f", c)
			}
	
			return resultString
		}
	}
	
	var axisText: String {
		if (self.noRx) {
			return ""
		}
	
		var resultString = ""
		
		if (abs(self.cyl) < 0.12) {
			resultString = ""
		} else {
			resultString = String.localizedStringWithFormat("%.0f", self.axis)
		}
	
		return resultString;
	}


	// Functions
	func ocularSphericalEquivalentWithPrecision(_ precision: Double) -> Double {
		var rx = self.ocularSphere + self.ocularCyl / 2.0;
		rx = floor(rx * precision + 0.5) / precision;
	
		return rx;
	}
	
	func newLensPrescriptionOcularRxWithPowerPrecision(_ precision: Double, axisPrecision: Double) -> LensPrescription {
		// Returns a new ocular prescription of this prescription with a precision of 'precision'.
		// Precision: 100 = .01  8 = .12  4 = .25
		// Axis precision: 1, 5 or 10 (degrees).
		let newRx = LensPrescription(
			sph: floor(self.ocularSphere * precision + 0.5) / precision,
			cyl: floor(self.ocularCyl * precision + 0.5) / precision,
			axis: floor(self.axis / axisPrecision + 0.5) * axisPrecision,
			vertex: 0.0
		)
	
		return newRx;
	}

	func newLensPrescriptionOcularRxWithPowerPrecision(_ precision: Double, axisPrecision: Double, plusCyl: Bool) -> LensPrescription {
		var newRx = self.newLensPrescriptionOcularRxWithPowerPrecision(precision, axisPrecision: axisPrecision)
		newRx.plusCylForm = plusCyl
		return newRx
	}
	
	func internalAxis() -> Double {
		// Returns the minus cyl axis for calculation purposes.
		return _axis
	}
	
// Static functions
	static func lensPrescriptionFromText(_ text:String) -> LensPrescription {
		var s, c, a : Double
		
		let slashLocation = text.firstIndex(of: "/")
		var xLocation = text.firstIndex(of: "x")
		
		if xLocation == nil {
			xLocation = text.firstIndex(of: "@")
		}
		
		if slashLocation == nil || slashLocation!.encodedOffset > xLocation!.encodedOffset + 1 {
			s = LensPrescription.doubleFromString(text)
			c = 0
			a = 180
		} else {
			s = LensPrescription.doubleFromString(String(text[..<slashLocation!]))
			if xLocation == nil {
				c = (text[slashLocation!...] as NSString).doubleValue
				a = 180
			} else {
				let afterSlash = text.index(after: slashLocation!)
				c = (text[afterSlash..<xLocation!] as NSString).doubleValue
				let afterX = text.index(after: xLocation!)
				a = (text[afterX...] as NSString).doubleValue
			}
		}
		
		var returnRx = LensPrescription(sph: s, cyl: c, axis: a, vertex: 0)
		
		if text == "" {
			returnRx.noRx = true
		}
		
		return returnRx
	}

	static func rotationFrom(_ power1:LensPrescription, to power2:LensPrescription) -> Double {
		// Subtract axes, take plus cyl into account.
		let result = power2._cyl - power1._cyl
		return result
	}
	
	static func doubleFromString(_ string:String) -> Double {
		// If there's a plus sign, remove it.
		var newString = string
		if let plusLoc = string.firstIndex(of: NumberFormatter().plusSign.first!) {
			newString.remove(at: plusLoc)
		}
		
		let num = NumberFormatter().number(from: newString)
		return num?.doubleValue ?? 0
	}
	
	static func doubleFromSphString(_ string:String) -> Double {
		var val = LensPrescription.doubleFromString(string)
		
		guard let decimalSep = NSLocale.current.decimalSeparator else {
			return 0
		}
		
		// If there's no period, then convert to 0.25, etc.
		if string.firstIndex(of: Character(decimalSep)) == nil {
			if val > 24 || val < -24 {
				val /= 100
			}
		}
		
		return val
	}
	
	static func doubleFromCylString(_ string:String) -> Double {
		guard let decimalSep = NSLocale.current.decimalSeparator else {
			return 0
		}
		
		var val = abs(LensPrescription.doubleFromString(string))

		if string.firstIndex(of: Character(decimalSep)) == nil {
			if val > 24 {
				val /= 100
			}
		}
		
		return val
	}
}
