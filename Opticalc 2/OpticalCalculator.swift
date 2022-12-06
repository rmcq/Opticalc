//
//  OpticalCalculator.swift
//  Opticalc 2
//
//  Created by Robert McQualter on 10/11/18.
//  Copyright © 2018 Robert McQualter. All rights reserved.
//

import UIKit

class OpticalCalculator {
	var patientRx, nominalCLRx, overRx: LensPrescription?
	var powerPrecision, axisPrecision: Double
	
	var lensToOrder, effectiveCLRx: LensPrescription?
	var lensToOrderFromNominalRx: LensPrescription?
	
	var rotation: Double = 0
	var useOcularRx: Bool = true
	var defaultToPlusCyl: Bool = false
	
	var rotationFromNominalRx: Double? // Calculated using NomRx + overRx.
	
	init() {
		self.powerPrecision = 4 // 4 = 0.25, 8 = 0.12, 100 = 0.01
		self.axisPrecision = 5
	}
	
	func calcToricRx() {
		// Called whenever the powers have changed.
		// May be called by an external function to cause update as well (eg. when patient's refraction changes).
		guard var ptRx = patientRx, var nomRx = nominalCLRx, var ovRx = overRx else {
			return
		}
		
		// Calculate Effective C/L Power.
		// This is the big function that does all the work!
		var se, ce, ae, so, co, ao, rs, rc, ra: Double
		var fe11, fe12, fe22, fo11, fo12, fo22, fr11, fr12, fr22, t, d: Double
		
		// Make sure we're using minus cyl for all calculations.
		ptRx.plusCylForm = false
		nomRx.plusCylForm = false
		ovRx.plusCylForm = false
		
		// First calculate Ocular Rx.
		se = ptRx.ocularSphere
		ce = ptRx.ocularCyl
		ae = ptRx.axis
		
		so = ovRx.ocularSphere
		co = ovRx.ocularCyl
		ao = ovRx.axis
		
		// Convert to radians.
		ae = ae * .pi / 180.0;
		ao = ao * .pi / 180.0;
		
		// Set up the matrices.
		fe11 = se + ce * sin(ae) * sin(ae);
		fe12 = -ce * sin(ae) * cos(ae);
		fe22 = se + ce * cos(ae) * cos(ae);
		
		fo11 = so + co * sin(ao) * sin(ao);
		fo12 = -1.0 * co * sin(ao) * cos(ao);
		fo22 = so + co * cos(ao) * cos(ao);
		
		// The new power matrix... subtract over-refraction from refraction to get the contact lens power.
		fr11 = fe11 - fo11;
		fr12 = fe12 - fo12;
		fr22 = fe22 - fo22;
		
		// Extract sph, cyl & axis.
		t = fr11 + fr22;
		d = fr11 * fr22 - fr12 * fr12;
		rc = -sqrt(t * t - 4.0 * d);
		rs = (t - rc) / 2.0;
		
		if (fabs(fr12) < 0.01) {
			// Effective axis of the contact lens is the same as the patient's refraction.
			ra = ae;
		} else {
			// Derive effective axis from the matrix.
			ra = atan((rs - fr11)/fr12);
		}
		
		ra = ra * 180.0 / .pi; // Back to degrees.
		if (ra < 0) {
			ra = ra + 180.0
		}
		
		// Apparent c/l power.
		effectiveCLRx = LensPrescription(sph: rs, cyl: rc, axis: ra, vertex: 0)
		
		// Calculate lens power to order.
		
		// Sphere power: Get ocular Rx, and subtract the difference between that and the effective lens power.
		// In effect, the contact lens power is different to expected, so order that instead.
		lensToOrder = LensPrescription(plusCyl: false)
		
		rotation = ra - nomRx.axis
		if (rotation < -90) {
			rotation += 180
		}
		
		if (rotation > 90) {
			rotation -= 180
		}
		
		// Calculate new axis.
		lensToOrder!.axis = ae * 180.0 / .pi - rotation;
		
		if (useOcularRx) { // Use ocular Rx for contact lens power?
			lensToOrder!.sph = se;
			lensToOrder!.cyl = ce;
		} else {
			//orderPower.sphere = self.ad.toricCLRx.sphere * 2.0 - rs;
			lensToOrder!.sph = ptRx.ocularSphere + (nomRx.sph - rs);
			//orderPower.sphere = [self.ad.patientRx getOcularSphere] * 2.0 - self.ad.toricCLRx.sphere + [self.ad.toricOverRx getOcularSphere]; // Changed - to +.
			//orderPower.cyl = self.ad.toricCLRx.cyl * 2.0 - rc;
			let newCyl = ptRx.ocularCyl + nomRx.cyl - rc
			lensToOrder!.cyl = newCyl; // Automatically corrects sphere, but does not change axis for plus cyl form.
			if (newCyl > 0.0) {
				lensToOrder!.axis = lensToOrder!.axis + 90;
			}
		}
		
		// Round it off.
		lensToOrder = lensToOrder!.newLensPrescriptionOcularRxWithPowerPrecision(powerPrecision, axisPrecision: axisPrecision)
		lensToOrder?.plusCylForm = self.defaultToPlusCyl // Convert to plus cyl if required.
	}
	
	func calcRxFromOverRx() {
		// This calculates the lens to order just by adding the over-refraction to the nominal contact lens Rx.
		guard var nomRx = nominalCLRx, var ovRx = overRx else {
			return
		}
		
		// Make sure we're using minus cyl.
		nomRx.plusCylForm = false
		ovRx.plusCylForm = false
		
		var se, ce, ae, so, co, ao, rs, rc, ra: Double
		var fe11, fe12, fe22, fo11, fo12, fo22, fr11, fr12, fr22, t, d: Double

		se = nomRx.ocularSphere
		ce = nomRx.ocularCyl
		ae = nomRx.axis
		
		so = ovRx.ocularSphere
		co = ovRx.ocularCyl
		ao = ovRx.axis

		// Convert to radians.
		ae = ae * .pi / 180.0;
		ao = ao * .pi / 180.0;
		
		// Set up the matrices.
		fe11 = se + ce * sin(ae) * sin(ae);
		fe12 = -ce * sin(ae) * cos(ae);
		fe22 = se + ce * cos(ae) * cos(ae);
		
		fo11 = so + co * sin(ao) * sin(ao);
		fo12 = -1.0 * co * sin(ao) * cos(ao);
		fo22 = so + co * cos(ao) * cos(ao);
		
		// The new power matrix... add over-refraction to nominal c/l power to get the final contact lens power.
		fr11 = fe11 + fo11;
		fr12 = fe12 + fo12;
		fr22 = fe22 + fo22;

		// Extract sph, cyl & axis.
		t = fr11 + fr22;
		d = fr11 * fr22 - fr12 * fr12;
		rc = -sqrt(t * t - 4.0 * d);
		rs = (t - rc) / 2.0;
		
		if (fabs(fr12) < 0.01) {
			// Effective axis of the contact lens is the same as the patient's refraction.
			ra = ae;
		} else {
			// Derive effective axis from the matrix.
			ra = atan((rs - fr11)/fr12);
		}
		
		ra = ra * 180.0 / .pi; // Back to degrees.
		if (ra < 0) {
			ra = ra + 180.0
		}
		
		// Apparent c/l power.
		let orderLens = LensPrescription(sph: rs, cyl: rc, axis: ra, vertex: 0)
		self.lensToOrderFromNominalRx = orderLens.newLensPrescriptionOcularRxWithPowerPrecision(powerPrecision, axisPrecision: axisPrecision)
		var rot = orderLens.axis - nomRx.axis
		if (rot < -90) {
			rot += 180
		} else if rot > 90 {
			rot -= 180
		}
		
		self.lensToOrderFromNominalRx?.plusCylForm = self.defaultToPlusCyl //  Finally convert to plus cyl if required.
		self.rotationFromNominalRx = rot
	}
	
	func stringFromAxis(_ axis:Double, shortString:Bool) -> String {
		var acw = "anticlockwise"
		var cw = "clockwise"
	
		if (shortString) {
			acw = "ACW"
			cw = "CW"
		}
	
		let str = String.localizedStringWithFormat("%.0fº %@", abs(axis), axis < 0 ? cw : acw)
	
		return str
	}

}
