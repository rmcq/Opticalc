//
//  Settings.swift
//  Opticalc 2
//
//  Created by Robert McQualter on 7/11/18.
//  Copyright © 2018 Robert McQualter. All rights reserved.
//

import UIKit

class Settings {
	var useOcularRx: Bool = false
	var patientRx: LensPrescription?
	var toricCLRx: LensPrescription?
	var toricORx: LensPrescription?
	var powerPrecision: Double = 0
	var axisPrecision: Double = 0
	var firstShow: Bool = false
	var vertexDistance: Double = 0
	var observedRotation: Double? = nil
	var rotationClockwise: Bool = true
	var plusCylDefault:Bool = false
	
	var defaultRx: LensPrescription {
		get {
				return LensPrescription(sph: -3, cyl: -2, axis: 180, vertex: 13, plusCyl: plusCylDefault)
		}
	}
	
	let DEFAULTS_POWER_KEY = "power"
	let DEFAULTS_TORIC_CL_POWER_KEY = "clPower"
	let DEFAULTS_TORIC_OV_POWER_KEY = "clORxPower"
	let DEFAULTS_SPH_PRECISION_KEY = "sphPrecision"
	let DEFAULTS_AXIS_PRECISION_KEY = "axisPrecision"
	let DEFAULTS_USE_OCRX_KEY = "useOcRx"
	let DEFAULTS_FIRST_SHOW_KEY = "firstShow"
	let DEFAULTS_VERTEX_KEY = "vertex"
	let DEFAULTS_OBSERVED_ROTATION_KEY = "observedRotation"
	let DEFAULTS_OBSERVED_CLOCKWISE_KEY = "observedRotationClockwise"
	let DEFAULTS_PLUS_CYL_KEY = "plusCylDefault"
	
	func loadSettings() {
		let userDefaults = UserDefaults.standard
		let zeroRx = LensPrescription()
		let encoder = PropertyListEncoder()
		
		do {
		let defaultValues = [
			DEFAULTS_POWER_KEY: try encoder.encode(defaultRx),
			DEFAULTS_TORIC_CL_POWER_KEY: try encoder.encode(zeroRx),
			DEFAULTS_TORIC_OV_POWER_KEY: try encoder.encode(zeroRx),
			DEFAULTS_SPH_PRECISION_KEY: 4.0,
			DEFAULTS_AXIS_PRECISION_KEY: 10.0,
			DEFAULTS_USE_OCRX_KEY: false,
			DEFAULTS_FIRST_SHOW_KEY: true,
			DEFAULTS_VERTEX_KEY: 13.0,
			DEFAULTS_PLUS_CYL_KEY: false
			] as [String : Any]

			userDefaults.register(defaults: defaultValues)

		} catch {
			print("error!")
		}
		
		do {
			let decoder = PropertyListDecoder()
			
			let codedPtRx: Data = userDefaults.object(forKey: DEFAULTS_POWER_KEY) as! Data
			self.patientRx = try decoder.decode(LensPrescription.self, from: codedPtRx)
			self.toricCLRx = try decoder.decode(LensPrescription.self, from: userDefaults.object(forKey: DEFAULTS_TORIC_CL_POWER_KEY) as! Data)
			self.toricORx = try decoder.decode(LensPrescription.self, from: userDefaults.object(forKey: DEFAULTS_TORIC_OV_POWER_KEY) as! Data)
		} catch {
			print("Error.")
		}

		self.powerPrecision = userDefaults.double(forKey: DEFAULTS_SPH_PRECISION_KEY)
		self.axisPrecision = userDefaults.double(forKey: DEFAULTS_AXIS_PRECISION_KEY)
		self.useOcularRx = userDefaults.bool(forKey: DEFAULTS_USE_OCRX_KEY)
		self.vertexDistance = userDefaults.double(forKey: DEFAULTS_VERTEX_KEY)
		self.firstShow = userDefaults.bool(forKey: DEFAULTS_FIRST_SHOW_KEY)
		self.observedRotation = userDefaults.double(forKey: DEFAULTS_OBSERVED_ROTATION_KEY)
		self.rotationClockwise = userDefaults.bool(forKey: DEFAULTS_OBSERVED_CLOCKWISE_KEY)
		self.plusCylDefault = userDefaults.bool(forKey: DEFAULTS_PLUS_CYL_KEY)
	}
	
	func saveSettings() {
		let userDefaults = UserDefaults.standard
		
		do {
			let encoder = PropertyListEncoder()
			let codedPtRx = try encoder.encode(patientRx!)
			let codedToricCLRx = try encoder.encode(toricCLRx!)
			let codedToricORx = try encoder.encode(toricORx!)

			userDefaults.set(codedPtRx, forKey: DEFAULTS_POWER_KEY)
			userDefaults.set(codedToricCLRx, forKey: DEFAULTS_TORIC_CL_POWER_KEY)
			userDefaults.set(codedToricORx, forKey: DEFAULTS_TORIC_OV_POWER_KEY)

		} catch {
			print("Save Failed")
		}

		userDefaults.set(powerPrecision, forKey: DEFAULTS_SPH_PRECISION_KEY)
		userDefaults.set(axisPrecision, forKey: DEFAULTS_AXIS_PRECISION_KEY)
		userDefaults.set(useOcularRx, forKey: DEFAULTS_USE_OCRX_KEY)
		userDefaults.set(patientRx!.vertex, forKey: DEFAULTS_VERTEX_KEY)
		userDefaults.set(firstShow, forKey: DEFAULTS_FIRST_SHOW_KEY)
		userDefaults.set(observedRotation, forKey: DEFAULTS_OBSERVED_ROTATION_KEY)
		userDefaults.set(rotationClockwise, forKey: DEFAULTS_OBSERVED_CLOCKWISE_KEY)
		userDefaults.set(plusCylDefault, forKey: DEFAULTS_PLUS_CYL_KEY)
		print("Settings saved.")
	}
	
	func setRxToDefaults() {
		// Reset Rx settings to default values (not changing precision, etc.)
		patientRx = defaultRx
		toricCLRx = LensPrescription()
		toricORx = LensPrescription()
		observedRotation = nil
		rotationClockwise = true
	}
}
