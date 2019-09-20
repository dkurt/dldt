// Copyright (C) 2018 Intel Corporation
//
// SPDX-License-Identifier: Apache-2.0
//
#include <ie_parameter.hpp>

using namespace InferenceEngine;

Parameter::~Parameter() {
    clear();
}

Parameter::Any::~Any() {}

template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::Parameter::RealData<uint32_t>);
template class INFERENCE_ENGINE_API_CLASS(InferenceEngine::Parameter::RealData<std::string>);
