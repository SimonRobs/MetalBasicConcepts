//
//  MetalToDrawView.swift
//  MetalBasicConcepts
//
//  Created by Simon Robatto on 2020-08-21.
//  Copyright © 2020 Simon Robatto. All rights reserved.
//

import SwiftUI
import MetalKit

struct MetalToDrawView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: NSViewRepresentableContext<MetalToDrawView>) -> MTKView {
        let mtkView = MTKView()

        // Set the view's clear color (background color)
        mtkView.clearColor = MTLClearColorMake(0.9, 0.6, 0.4, 1.0)

        // The view will only draw when the content needs to be updated
        mtkView.enableSetNeedsDisplay = true

        // Delegate the actual rendering to the coordinator (Renderer)
        mtkView.delegate = context.coordinator

        // Initialize the view's device.
        // The device needs to be initialized for the renderPassDescriptor to exist
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            mtkView.device = metalDevice
        } else {
            fatalError("Could not create the default device")
        }
        
        return mtkView
    }
    
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<MetalToDrawView>) { }
    
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: MetalToDrawView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        
        init(_ parent: MetalToDrawView) {
            self.parent = parent
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            } else {
                fatalError("Could not create the default device")
            }
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            super.init()
        }
        
        /**
        This method is called whenevr the size of the contents changes.
         */
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { }
        
        /**
         This method is called whenever it's time to update the view's contents
         */
        func draw(in view: MTKView) {
            // Retrieve the command buffer
            guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
                fatalError("Could not make the command buffer")
            }
            
            // Create the render pass descriptor
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
                fatalError("Could not get the current render pass descriptor")
            }
            
            // Create the command encoder which will not have any commands but will instead erase the current texture.
            guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                fatalError("Could not make the command encoder")
            }
            commandEncoder.endEncoding()
            
            // Get the drawable that owns the render pass's target (the texture)
            guard let drawable = view.currentDrawable else {
                fatalError("Could not get the current drawable")
            }
            
            // Present the current drawable in the command buffer
            commandBuffer.present(drawable)
            
            // Send the instructions to the GPU
            commandBuffer.commit()
            
        }
    }
}

struct MetalToDrawView_Previews: PreviewProvider {
    static var previews: some View {
        MetalToDrawView()
    }
}
