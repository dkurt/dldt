// Copyright (C) 2018 Intel Corporation
//
// SPDX-License-Identifier: Apache-2.0
//


#include <ie_layers.h>

using namespace InferenceEngine;

CNNLayer::~CNNLayer() {}
WeightableLayer::~WeightableLayer() {}
ConvolutionLayer::~ConvolutionLayer() {}
PoolingLayer::~PoolingLayer() {}
ConcatLayer::~ConcatLayer() {}
SplitLayer::~SplitLayer() {}
NormLayer::~NormLayer() {}
SoftMaxLayer::~SoftMaxLayer() {}
GRNLayer::~GRNLayer() {}
MVNLayer::~MVNLayer() {}
ReLULayer::~ReLULayer() {}
ClampLayer::~ClampLayer() {}
ReLU6Layer::~ReLU6Layer() {}
EltwiseLayer::~EltwiseLayer() {}
CropLayer::~CropLayer() {}
ReshapeLayer::~ReshapeLayer() {}
TileLayer::~TileLayer() {}
ScaleShiftLayer::~ScaleShiftLayer() {}
TensorIterator::~TensorIterator() {}
RNNCellBase::~RNNCellBase() {}
RNNSequenceLayer::~RNNSequenceLayer() {}
PReLULayer::~PReLULayer() {}
PowerLayer::~PowerLayer() {}
BatchNormalizationLayer::~BatchNormalizationLayer() {}
GemmLayer::~GemmLayer() {}
PadLayer::~PadLayer() {}
GatherLayer::~GatherLayer() {}
StridedSliceLayer::~StridedSliceLayer() {}
ShuffleChannelsLayer::~ShuffleChannelsLayer() {}
DepthToSpaceLayer::~DepthToSpaceLayer() {}
SpaceToDepthLayer::~SpaceToDepthLayer() {}
ReverseSequenceLayer::~ReverseSequenceLayer() {}
OneHotLayer::~OneHotLayer() {}
RangeLayer::~RangeLayer() {}
FillLayer::~FillLayer() {}
SelectLayer::~SelectLayer() {}
BroadcastLayer::~BroadcastLayer() {}
QuantizeLayer::~QuantizeLayer() {}
MathLayer::~MathLayer() {}
ReduceLayer::~ReduceLayer() {}
TopKLayer::~TopKLayer() {}
