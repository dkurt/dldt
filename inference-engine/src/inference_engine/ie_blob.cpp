// Copyright (C) 2018 Intel Corporation
//
// SPDX-License-Identifier: Apache-2.0
//
#include <ie_blob.h>

using namespace InferenceEngine;

Blob::~Blob() {}

MemoryBlob::~MemoryBlob() {}

template<typename T, typename U>
TBlob<T, U>::~TBlob() { free(); }

template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlob<float>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlob<int16_t>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlob<uint16_t>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlob<int8_t>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlob<uint8_t>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlob<int>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlob<long>);
