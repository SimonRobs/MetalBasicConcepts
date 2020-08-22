//
//  RenderPrimitivesView.swift
//  MetalBasicConcepts
//
//  Created by Simon Robatto on 2020-08-21.
//  Copyright © 2020 Simon Robatto. All rights reserved.
//

import SwiftUI
import Metal
import MetalKit
import simd


struct RenderPrimitivesView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeNSView(context: NSViewRepresentableContext<RenderPrimitivesView>) -> MTKView {
        let mtkView = MTKView()

        // Set the view's clear color (background color)
        mtkView.clearColor = MTLClearColorMake(0.3, 0.3, 0.3, 1.0)

        // The view will only draw when the content needs to be updated
        mtkView.enableSetNeedsDisplay = true
        
        // Unpause the view
        mtkView.isPaused = false

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
    
    func updateNSView(_ nsView: MTKView, context: NSViewRepresentableContext<RenderPrimitivesView>) { }
    
    class Coordinator : NSObject, MTKViewDelegate {
        var parent: RenderPrimitivesView
        var metalDevice: MTLDevice!
        var metalCommandQueue: MTLCommandQueue!
        var pipelineState: MTLRenderPipelineState!
        var viewportSize: SIMD2<Float>!
        
        // The vertices of the triangle which will be drawn
        static let triangleVertices: [Vertex] = [
            Vertex(position: SIMD2<Float>( 250, -250), color:SIMD4<Float>(1, 0, 0, 1)),
            Vertex(position: SIMD2<Float>(-250, -250), color:SIMD4<Float>(0, 1, 0, 1)),
            Vertex(position: SIMD2<Float>(   0,  250), color:SIMD4<Float>(0, 0, 1, 1)),
        ]
        
        init(_ parent: RenderPrimitivesView) {
            self.parent = parent
            
            // Initialize the default device
            if let metalDevice = MTLCreateSystemDefaultDevice() {
                self.metalDevice = metalDevice
            } else {
                fatalError("Could not create the default device")
            }
            
            self.metalCommandQueue = metalDevice.makeCommandQueue()!
            self.viewportSize = [0, 0]
            super.init()
        }
        
        func initPipelineState(for view: MTKView) {
            
            // Initialize the library
            guard let defaultLibrary: MTLLibrary = metalDevice.makeDefaultLibrary() else {
                fatalError("Could not create the default library")
            }
            
            // Retrieve the vertex and fragment functions
            guard let vertexFunction = defaultLibrary.makeFunction(name: "vertexShader_Ex3") else {
                fatalError("Could not get vertex function")
            }
            
            guard let fragmentFunction = defaultLibrary.makeFunction(name: "fragmentShader_Ex3") else {
                fatalError("Could not get fragment function")
            }
            
            // Create the RenderPipelineState object along with its descriptor to configure
            // the pipeline
            let pipelineStateDescriptor: MTLRenderPipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineStateDescriptor.label = "State Pipeline"

            pipelineStateDescriptor.vertexFunction = vertexFunction
            pipelineStateDescriptor.fragmentFunction = fragmentFunction
            
            // This sample contains only one render target and is provided by the view.
            // So the pixel description can come directly from the view.
            // The pixelFormat must be compatible with the one specified by the render pass.
            pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            
            self.pipelineState = try! metalDevice.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        }
        
        /**
        This method is called whenevr the size of the contents changes.
         */
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            viewportSize.x = Float(size.width)
            viewportSize.y = Float(size.height)
        }
        
        /**
         This method is called whenever it's time to update the view's contents
         */
        func draw(in view: MTKView) {
            if pipelineState == nil {
                self.initPipelineState(for: view)
            }
            
            // Retrieve the command buffer
            guard let commandBuffer = metalCommandQueue.makeCommandBuffer() else {
                fatalError("Could not make the command buffer")
            }
            
            // Create the render pass descriptor
            guard let renderPassDescriptor = view.currentRenderPassDescriptor else {
                fatalError("Could not get the current render pass descriptor")
            }
            
            // Create the command encoder
            guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                fatalError("Could not make the command encoder")
            }
            
            // Set the viewport to the correct size
            renderEncoder.setViewport(MTLViewport(originX: 0.0, originY: 0.0, width: Double(viewportSize[0]), height: Double(viewportSize[1]), znear: 0.0, zfar: 1.0))
            
            // Set the render pipeline state
            renderEncoder.setRenderPipelineState(pipelineState)
            
            // Pass the vertices and the viewport size to the vertex function
            renderEncoder.setVertexBytes(Coordinator.triangleVertices,
                                         length: MemoryLayout.size(ofValue: Vertex()) * Coordinator.triangleVertices.count,
                                         index: Int(VertexInputIndexVertices.rawValue))
            renderEncoder.setVertexBytes(&viewportSize,
                                         length: MemoryLayout.size(ofValue: viewportSize),
                                         index: Int(VertexInputIndexViewportSize.rawValue))
            
            // The Render Pipeline has three main stages:
            //      1. Vertex functions: Provides the data for each vertex
            //      2. Rasterization: Determines which pixels in the render targets lie within the boundaries
            //                        of the primitive
            //      3. Fragment functions: Determines the values to write into the render targets for those pixels
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
            
            renderEncoder.endEncoding()
            
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

struct RenderPrimitivesView_Previews: PreviewProvider {
    static var previews: some View {
        RenderPrimitivesView()
    }
}
