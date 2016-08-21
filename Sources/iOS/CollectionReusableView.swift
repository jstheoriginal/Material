/*
 * Copyright (C) 2015 - 2016, Daniel Dahan and CosmicMind, Inc. <http://cosmicmind.io>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *	*	Redistributions of source code must retain the above copyright notice, this
 *		list of conditions and the following disclaimer.
 *
 *	*	Redistributions in binary form must reproduce the above copyright notice,
 *		this list of conditions and the following disclaimer in the documentation
 *		and/or other materials provided with the distribution.
 *
 *	*	Neither the name of CosmicMind nor the names of its
 *		contributors may be used to endorse or promote products derived from
 *		this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import UIKit

@IBDesignable
@objc(MaterialCollectionReusableView)
open class MaterialCollectionReusableView: UICollectionReusableView {
	/**
     A CAShapeLayer used to manage elements that would be affected by
     the clipToBounds property of the backing layer. For example, this
     allows the dropshadow effect on the backing layer, while clipping
     the image to a desired shape within the visualLayer.
     */
	open private(set) var visualLayer: CAShapeLayer!
	
	/// A base delegate reference used when subclassing View.
	public weak var delegate: MaterialDelegate?
	
	/// An Array of pulse layers.
	open private(set) lazy var pulseLayers = [CAShapeLayer]()
	
	/// The opcaity value for the pulse animation.
	@IBInspectable open var pulseOpacity: CGFloat = 0.25
	
	/// The color of the pulse effect.
	@IBInspectable open var pulseColor = Color.grey.base
	
	/// The type of PulseAnimation.
	open var pulseAnimation: PulseAnimation = .pointWithBacking
	
	/**
     A property that manages an image for the visualLayer's contents
     property. Images should not be set to the backing layer's contents
     property to avoid conflicts when using clipsToBounds.
     */
	@IBInspectable open var image: UIImage? {
		didSet {
			visualLayer.contents = image?.cgImage
		}
	}
	
	/**
     Allows a relative subrectangle within the range of 0 to 1 to be
     specified for the visualLayer's contents property. This allows
     much greater flexibility than the contentsGravity property in
     terms of how the image is cropped and stretched.
     */
	@IBInspectable open var contentsRect: CGRect {
		get {
			return visualLayer.contentsRect
		}
		set(value) {
			visualLayer.contentsRect = value
		}
	}
	
	/**
     A CGRect that defines a stretchable region inside the visualLayer
     with a fixed border around the edge.
     */
	@IBInspectable open var contentsCenter: CGRect {
		get {
			return visualLayer.contentsCenter
		}
		set(value) {
			visualLayer.contentsCenter = value
		}
	}
	
	/**
     A floating point value that defines a ratio between the pixel
     dimensions of the visualLayer's contents property and the size
     of the view. By default, this value is set to the Device.scale.
     */
	@IBInspectable open var contentsScale: CGFloat {
		get {
			return visualLayer.contentsScale
		}
		set(value) {
			visualLayer.contentsScale = value
		}
	}
	
	/// A Preset for the contentsGravity property.
	open var contentsGravityPreset: MaterialGravity {
		didSet {
			contentsGravity = MaterialGravityToValue(gravity: contentsGravityPreset)
		}
	}
	
	/// Determines how content should be aligned within the visualLayer's bounds.
	@IBInspectable open var contentsGravity: String {
		get {
			return visualLayer.contentsGravity
		}
		set(value) {
			visualLayer.contentsGravity = value
		}
	}
	
	/// A preset wrapper around contentInset.
	open var contentEdgeInsetsPreset: EdgeInsetsPreset {
		get {
			return grid.contentEdgeInsetsPreset
		}
		set(value) {
			grid.contentEdgeInsetsPreset = value
		}
	}
	
	/// A wrapper around grid.contentInset.
	@IBInspectable open var contentInset: UIEdgeInsets {
		get {
			return grid.contentEdgeInsets
		}
		set(value) {
			grid.contentEdgeInsets = value
		}
	}
	
	/// A preset wrapper around interimSpace.
	open var interimSpacePreset: InterimSpacePreset = .none {
		didSet {
            interimSpace = InterimSpacePresetToValue(preset: interimSpacePreset)
		}
	}
	
	/// A wrapper around grid.interimSpace.
	@IBInspectable open var interimSpace: InterimSpace {
		get {
			return grid.interimSpace
		}
		set(value) {
			grid.interimSpace = value
		}
	}
	
	/// A property that accesses the backing layer's backgroundColor.
	@IBInspectable open override var backgroundColor: UIColor? {
		didSet {
			layer.backgroundColor = backgroundColor?.cgColor
		}
	}
	
	/**
	An initializer that initializes the object with a NSCoder object.
	- Parameter aDecoder: A NSCoder instance.
	*/
	public required init?(coder aDecoder: NSCoder) {
		contentsGravityPreset = .ResizeAspectFill
		super.init(coder: aDecoder)
		prepareView()
	}
	
	/**
	An initializer that initializes the object with a CGRect object.
	If AutoLayout is used, it is better to initilize the instance
	using the init() initializer.
	- Parameter frame: A CGRect instance.
	*/
	public override init(frame: CGRect) {
		contentsGravityPreset = .ResizeAspectFill
		super.init(frame: frame)
		prepareView()
	}
	
	/// A convenience initializer.
	public convenience init() {
		self.init(frame: .zero)
	}
	
	open override func layoutSublayers(of layer: CALayer) {
		super.layoutSublayers(of: layer)
		if self.layer == layer {
			layoutShape()
			layoutVisualLayer()
		}
	}
	
	open override func layoutSubviews() {
		super.layoutSubviews()
		layoutShadowPath()
	}
	
    /**
     Triggers the pulse animation.
     - Parameter point: A Optional point to pulse from, otherwise pulses
     from the center.
     */
    open func pulse(point: CGPoint? = nil) {
        let p: CGPoint = nil == point ? CGPoint(x: CGFloat(width / 2), y: CGFloat(height / 2)) : point!
        Animation.pulseExpandAnimation(layer: layer, visualLayer: visualLayer, pulseColor: pulseColor, pulseOpacity: pulseOpacity, point: p, width: width, height: height, pulseLayers: &pulseLayers, pulseAnimation: pulseAnimation)
        _ = Animation.delay(time: 0.35) { [weak self] in
            guard let s = self else {
                return
            }
            Animation.pulseContractAnimation(layer: s.layer, visualLayer: s.visualLayer, pulseColor: s.pulseColor, pulseLayers: &s.pulseLayers, pulseAnimation: s.pulseAnimation)
        }
    }
    
    /**
     A delegation method that is executed when the view has began a
     touch event.
     - Parameter touches: A set of UITouch objects.
     - Parameter event: A UIEvent object.
     */
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        Animation.pulseExpandAnimation(layer: layer, visualLayer: visualLayer, pulseColor: pulseColor, pulseOpacity: pulseOpacity, point: layer.convert(touches.first!.location(in: self), from: layer), width: width, height: height, pulseLayers: &pulseLayers, pulseAnimation: pulseAnimation)
    }
    
    /**
     A delegation method that is executed when the view touch event has
     ended.
     - Parameter touches: A set of UITouch objects.
     - Parameter event: A UIEvent object.
     */
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        Animation.pulseContractAnimation(layer: layer, visualLayer: visualLayer, pulseColor: pulseColor, pulseLayers: &pulseLayers, pulseAnimation: pulseAnimation)
    }
    
    /**
     A delegation method that is executed when the view touch event has
     been cancelled.
     - Parameter touches: A set of UITouch objects.
     - Parameter event: A UIEvent object.
     */
    open override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        Animation.pulseContractAnimation(layer: layer, visualLayer: visualLayer, pulseColor: pulseColor, pulseLayers: &pulseLayers, pulseAnimation: pulseAnimation)
    }
	
	/**
	Prepares the view instance when intialized. When subclassing,
	it is recommended to override the prepareView method
	to initialize property values and other setup operations.
	The super.prepareView method should always be called immediately
	when subclassing.
	*/
	open func prepareView() {
		contentScaleFactor = Device.scale
		pulseAnimation = .none
		prepareVisualLayer()
	}
	
	/// Prepares the visualLayer property.
	internal func prepareVisualLayer() {
        visualLayer = CAShapeLayer()
		visualLayer.zPosition = 0
		visualLayer.masksToBounds = true
		layer.addSublayer(visualLayer)
	}
	
	/// Manages the layout for the visualLayer property.
	internal func layoutVisualLayer() {
		visualLayer.frame = bounds
		visualLayer.cornerRadius = cornerRadius
	}
}
