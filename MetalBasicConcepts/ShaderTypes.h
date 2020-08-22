//
//  ShaderTypes.h
//  MetalBasicConcepts
//
//  Created by Simon Robatto on 2020-08-21.
//  Copyright © 2020 Simon Robatto. All rights reserved.
//

#ifndef ShaderTypes_h
#define ShaderTypes_h

#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#define NSInteger metal::int32_t
#else
#import <Foundation/Foundation.h>
#endif

// Included to be able to use data types with
// multiple channels.
// For example: vector_float4 is a float with 4 channels
// (commonly used for colors)
#include <simd/simd.h>

// Buffer index values shared between shader and C code to ensure Metal shader buffer inputs
// match Metal API buffer set calls.
typedef enum VertexInputIndex
{
    VertexInputIndexVertices     = 0,
    VertexInputIndexViewportSize = 1,
} VertexInputIndex;

typedef struct
{
    vector_float2 position;
    vector_float4 color;
} Vertex;

#endif /* ShaderTypes_h */
