//
//  CalculationsOnGPUView.swift
//  MetalBasicConcepts
//
//  Created by Simon Robatto on 2020-08-20.
//  Copyright © 2020 Simon Robatto. All rights reserved.
//

import SwiftUI

struct CalculationsOnGPUView: View {
    
    let MAX_NUMBERS = 100_000
    
    @State private var result: Float = 0
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("The result is: \(result)")
                .padding()
            
            Button("Calculate Result", action: calculateResult)
                .padding()
        }
    .padding()
        .frame(width: 400, height: 400, alignment: .center)
    }
    
    func fillBufferWithRandomData(_ buffer: MTLBuffer) {
        let floatSize = MemoryLayout.size(ofValue: Float())
        let bufferData: UnsafeMutableRawPointer = buffer.contents()
        for i in 0..<self.MAX_NUMBERS {
            let num = Float(Double.random(in: 0..<1000))
            bufferData.storeBytes(of: num, toByteOffset: floatSize * i , as: Float.self)
        }
    }
    
    func calculateResult() {
        // Get an available GPU
        let device: MTLDevice = MTLCreateSystemDefaultDevice()!
        
        // Get the add function from the default library
        let defaultLibrary: MTLLibrary = device.makeDefaultLibrary()!
        let addFunc: MTLFunction = defaultLibrary.makeFunction(name: "add_arrays")!
        
        // Prepare the Metal Pipeline to convert the function proxy
        // into executable code
        // A Pipeline runs a single compute function!
        let addFunctionPSO: MTLComputePipelineState = try! device.makeComputePipelineState(function: addFunc)
        
        // Create the command queue
        let commandQueue: MTLCommandQueue = device.makeCommandQueue()!
        
        // Create the buffers that will be used by the function
        let FloatSize: Int = MemoryLayout.size(ofValue: Float())
        let bufferIn1: MTLBuffer = device.makeBuffer(length: FloatSize * self.MAX_NUMBERS, options: [.storageModeShared])!
        let bufferIn2: MTLBuffer = device.makeBuffer(length: FloatSize * self.MAX_NUMBERS, options: [.storageModeShared])!
        let bufferOut: MTLBuffer = device.makeBuffer(length: FloatSize * self.MAX_NUMBERS, options: [.storageModeShared])!
        
        // Populate the buffers
        self.fillBufferWithRandomData(bufferIn1)
        self.fillBufferWithRandomData(bufferIn2)

        // Create the command buffer
        let commandBuffer: MTLCommandBuffer = commandQueue.makeCommandBuffer()!
        
        /** The structure of the pipeline is the following:
         
                PSO            Argument           Argument           Command Arguments
                 |                 |                  |                      |
                  -----------------------------------------------------------
                                           |
                                           V
         
                                    Command Encoder
                                           |
                                           V
         
                                    Command Buffer
         */
        
        // Create the command encoder
        let computeEncoder: MTLComputeCommandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        // Set the Pipeline State and Argument Data
        // The Buffer Offset allows to store multiple arguments at different offsets
        computeEncoder.setComputePipelineState(addFunctionPSO)
        computeEncoder.setBuffer(bufferIn1, offset: 0, index: 0)
        computeEncoder.setBuffer(bufferIn2, offset: 0, index: 1)
        computeEncoder.setBuffer(bufferOut, offset: 0, index: 2)
        
        
        // Specify Thread Count and Organisation
        // In this case, we are making a 1D array.
        let gridSize: MTLSize = MTLSizeMake(self.MAX_NUMBERS, 1, 1)
        
        // Specify Threadgroup Size
        var threadGroupSize: Int = addFunctionPSO.maxTotalThreadsPerThreadgroup
        if threadGroupSize > self.MAX_NUMBERS {
            threadGroupSize = self.MAX_NUMBERS
        }
        let threadgroupSize: MTLSize = MTLSizeMake(threadGroupSize, 1, 1)
        
        // Encode the compute command and execute the threads
        computeEncoder.dispatchThreadgroups(gridSize, threadsPerThreadgroup: threadgroupSize)
        
        // Set the completion handler
        commandBuffer.addCompletedHandler { cb in
            self.result = 0
            var temp: Float = 0
            let outData: UnsafeMutableRawPointer = bufferOut.contents()
            for i in 0..<self.MAX_NUMBERS {
                let data: Float = outData.load(fromByteOffset: FloatSize * i, as: Float.self)
                temp += data
            }
            self.result = temp
        }
        
        // Close the compute pass
        computeEncoder.endEncoding()
        
        // Places the commandBuffer on the commandQueue and executes the commands when ready
        commandBuffer.commit()
    }
}


struct CalculationsOnGPUView_Previews: PreviewProvider {
    static var previews: some View {
        CalculationsOnGPUView()
    }
}
