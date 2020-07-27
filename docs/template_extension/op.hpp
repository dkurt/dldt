// Copyright (C) 2020 Intel Corporation
// SPDX-License-Identifier: Apache-2.0
//

#pragma once

#include <ngraph/ngraph.hpp>

//! [op:header]
namespace TemplateExtension {

class FFT1D : public ngraph::op::Op {
public:
    static constexpr ngraph::NodeTypeInfo type_info{"FFT1D", 0};
    const ngraph::NodeTypeInfo& get_type_info() const override { return type_info;  }

    FFT1D() = default;
    FFT1D(const ngraph::Output<ngraph::Node>& arg);
    void validate_and_infer_types() override;
    std::shared_ptr<ngraph::Node> copy_with_new_args(const ngraph::NodeVector& new_args) const override;
    bool visit_attributes(ngraph::AttributeVisitor& visitor) override;
};
//! [op:header]

}  // namespace TemplateExtension
