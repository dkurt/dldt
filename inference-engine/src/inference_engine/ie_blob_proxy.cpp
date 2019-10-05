// Copyright (C) 2018 Intel Corporation
//
// SPDX-License-Identifier: Apache-2.0
//

#include <ie_blob_proxy.hpp>

using namespace InferenceEngine;

template<typename T>
TBlobProxy<T>::~TBlobProxy() {}

template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlobProxy<float>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlobProxy<int16_t>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlobProxy<uint16_t>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlobProxy<int8_t>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlobProxy<uint8_t>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlobProxy<int>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlobProxy<long>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::TBlobProxy<long long>);
