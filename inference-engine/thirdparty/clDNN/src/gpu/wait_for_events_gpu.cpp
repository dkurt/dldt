/*
// Copyright (c) 2016 Intel Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
*/

#include "primitive_inst.h"
#include "data_inst.h"
#include "prior_box_inst.h"
#include "input_layout_inst.h"
#include "implementation_map.h"

#include "network_impl.h"
#include "events_waiter.h"

namespace cldnn { namespace gpu {

class wait_for_events_gpu : public primitive_impl
{
public:
    wait_for_events_gpu(const program_node& /*node*/) {}

    event_impl::ptr execute(const std::vector<event_impl::ptr>& events, primitive_inst& instance) override
    {
        events_waiter events_waiter(instance.get_network().get_engine().get_context());
        return events_waiter.run(events);
    }

    static primitive_impl* create_data(const data_node& data)
    {
        return new wait_for_events_gpu(data);
    }

    static primitive_impl* create_input_layout(const input_layout_node& input)
    {
        return new wait_for_events_gpu(input);
    }

    static primitive_impl* create_prior_box(const prior_box_node& prior_box)
    {
        // This primitive is being executed on CPU during network compilation.
        return new wait_for_events_gpu(prior_box);
    }
};

namespace {
    struct attach {
        attach() {
            implementation_map<data>::add({
                { engine_types::ocl, wait_for_events_gpu::create_data }
            });

            implementation_map<input_layout>::add({
                { engine_types::ocl, wait_for_events_gpu::create_input_layout }
            });

            implementation_map<prior_box>::add({
                { engine_types::ocl, wait_for_events_gpu::create_prior_box }
            });
        }
        ~attach() {}
    };
    attach attach_impl;
}

}}
