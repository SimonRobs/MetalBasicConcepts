//
//  ContentView.swift
//  MetalBasicConcepts
//
//  Created by Simon Robatto on 2020-08-20.
//  Copyright © 2020 Simon Robatto. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // Example 1: https://developer.apple.com/documentation/metal/basic_tasks_and_concepts/performing_calculations_on_a_gpu
//        CalculationsOnGPUView()
        
        // Example 2: https://developer.apple.com/documentation/metal/basic_tasks_and_concepts/using_metal_to_draw_a_view_s_contents
//        MetalToDrawView()
        
        // Example 3: https://developer.apple.com/documentation/metal/using_a_render_pipeline_to_render_primitives
        RenderPrimitivesView()
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
