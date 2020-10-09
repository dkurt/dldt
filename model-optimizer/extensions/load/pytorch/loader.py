"""
 Copyright (C) 2020 Intel Corporation

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
"""
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals

import logging as log

import torch
from torch.autograd import Variable

from extensions.load.loader import Loader
from mo.front.common.register_custom_ops import update_extractors_with_extensions, check_for_duplicates
from mo.front.extractor import extract_node_attrs
from mo.front.pytorch.extractor import pytorch_op_extractor, pytorch_op_extractors
from mo.graph.graph import Graph

from .hooks import OpenVINOTensor, forward_hook

def detectron2_modeling_meta_arch_retinanet_RetinaNet_inference(func, anchors, pred_logits, pred_anchor_deltas, image_sizes):
    print('detectron2_modeling_meta_arch_retinanet_RetinaNet_inference')

    # Convert from lists of OpenVINOTensor to torch.tensor and perform origin run
    pred_logits_t = [v.tensor() for v in pred_logits]
    pred_anchor_deltas_t = [v.tensor() for v in pred_anchor_deltas]
    output = func(anchors, pred_logits_t, pred_anchor_deltas_t, image_sizes)

    # Concatenate the inputs (should be tracked)
    logist = torch.cat(pred_logits, dim=1)
    deltas = torch.cat(pred_anchor_deltas, dim=1)
    assert(isinstance(logist, OpenVINOTensor))
    assert(isinstance(deltas, OpenVINOTensor))

    # Create an alias
    class DetectionOutput(torch.nn.Module):
        def __init__(self):
            super().__init__()

    outputs = [OpenVINOTensor(output[0].pred_boxes.tensor),
               OpenVINOTensor(output[0].scores),
               OpenVINOTensor(output[0].pred_classes)]
    for out in outputs:
        out.graph = pred_logits[0].graph

    print(1)
    forward_hook(DetectionOutput(), (logist, deltas), outputs[1])
    print(2)
    return output


def detectron2_modeling_meta_arch_retinanet_RetinaNet_forward(forward, batched_inputs):
    print('detectron2_modeling_meta_arch_retinanet_RetinaNet_forward')
    output = forward(batched_inputs)
    print('*********************')


class PyTorchLoader(Loader):
    enabled = True

    def load(self, graph: Graph):
        argv = graph.graph['cmd_params']
        graph.graph['fw'] = 'pytorch'
        graph.graph['layout'] = 'NCHW'

        update_extractors_with_extensions(pytorch_op_extractors)

        # Create a dummy input
        inp = OpenVINOTensor(torch.randn(list(argv.placeholder_shapes)))
        inp.graph = graph
        inp.node_name = 'input'

        model = argv.input_model

        for module in model.modules():
            if len([m for m in module.modules()]) != 1:
                continue
            module.register_forward_hook(forward_hook)

        graph.add_node('input', kind='op', op='Parameter', name='input', shape=list(inp.shape))

        # def register_method_hook(func, hook):
        #     old_func = func
        #     func = lambda *args: hook(old_func, *args)
        #
        # register_method_hook(model.inference, detectron2_modeling_meta_arch_retinanet_RetinaNet_inference)
        # register_method_hook(model.forward, detectron2_modeling_meta_arch_retinanet_RetinaNet_forward)
        old_func = model.inference
        model.inference = lambda *args: detectron2_modeling_meta_arch_retinanet_RetinaNet_inference(old_func, *args)
        old_forward = model.forward
        model.forward = lambda *args: detectron2_modeling_meta_arch_retinanet_RetinaNet_forward(old_forward, *args)

        with torch.no_grad():
            outs = model([{'image': inp}])

        # Add output nodes
        if not hasattr(outs, '__contains__'):  # if a single tensor
            outs = [outs]
        if isinstance(outs, dict):
            outs = outs.values()

        print(outs)
        for out in outs:
            name = out.node_name
            graph.add_node('output', kind='op', op='Result')
            edge_attrs = {
                'out': 0,
                'in': 0,
                'name': name,
                'fw_tensor_debug_info': [(name, name)],
                'in_attrs': ['in', 'name'],
                'out_attrs': ['out', 'name'],
                'data_attrs': ['fw_tensor_debug_info']
            }
            graph.add_edge(name, 'output', **edge_attrs)

        extract_node_attrs(graph, lambda node: pytorch_op_extractor(node, check_for_duplicates(pytorch_op_extractors)))
