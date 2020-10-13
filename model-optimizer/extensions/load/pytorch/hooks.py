import torch
import torch.nn as nn
import torch.nn.functional as F

# Callback which is executed after nn.Module forward
def forward_hook(self, inputs, output):
    # Skip if we already processed as functional hook
    if isinstance(output, OpenVINOTensor) and output.node_name:
        return output

    graph = inputs[0].graph
    assert(graph is not None)
    layer_type = self.__class__.__name__

    # Create a unique name
    name = graph.unique_id(prefix=layer_type + '_')

    graph.add_node(name, kind='op', op=layer_type, name=name, module=self)

    # Find all inputs
    for idx, inp in enumerate(inputs):
        src_id = inp.node_name
        print(src_id, self)
        assert(src_id is not None)

        edge_attrs = {
            'out': 0,
            'in': idx,
            'name': src_id,
            'fw_tensor_debug_info': [(src_id, src_id)],
            'in_attrs': ['in', 'name'],
            'out_attrs': ['out', 'name'],
            'data_attrs': ['fw_tensor_debug_info']
        }
        graph.add_edge(src_id, name, **edge_attrs)

    # state_dict is an OrderedDict that means all the parameterd are
    # ordered by connection
    for idx, (key, value) in enumerate(self.state_dict().items()):
        param_name = name + '/' + key
        graph.add_node(param_name, kind='op', op='Const', value=value.numpy())
        edge_attrs = {
            'out': 0,
            'in': len(inputs) + idx,
            'name': param_name,
            'fw_tensor_debug_info': [(param_name, param_name)],
            'in_attrs': ['in', 'name'],
            'out_attrs': ['out', 'name'],
            'data_attrs': ['fw_tensor_debug_info']
        }
        graph.add_edge(param_name, name, **edge_attrs)


    if not isinstance(output, OpenVINOTensor):
        output = OpenVINOTensor(output)
        output.graph = graph

    output.node_name = name
    return output

# PyTorch functional ops and Tensor operations are not tracked by forward_hook.
# So we need to introduce own tensor type to track them.
HANDLED_FUNCTIONS = {}
class OpenVINOTensor(object):
    def __init__(self, value):
        self._value = value
        self.graph = None
        self.node_name = None
        self.shape = value.shape
        self.requires_grad = self._value.requires_grad
        assert(not self.requires_grad)

    def __repr__(self):
        return self.node_name

    def tensor(self):
        return self._value

    def to(self, device):
        return self._value

    def numel(self):
        return self._value.numel()

    def dim(self):
        return self._value.dim()

    def data_ptr(self):
        return self._value.data_ptr()

    # Overrides += over tensors
    def __iadd__(self, a):
        self._value += a._value
        class Add(nn.Module):
            pass
        forward_hook(Add(), (self, a), self)
        return self

    def __add__(self, a):
        res = OpenVINOTensor(self._value + a._value)
        res.graph = self.graph
        class Add(nn.Module):
            pass
        forward_hook(Add(), (self, a), res)
        return res

    def view(self, *shape):
        res = OpenVINOTensor(self._value.view(shape))
        res.graph = self.graph

        class Reshape(nn.Module):
            def __init__(self, shape):
                super().__init__()
                self.shape = shape

        forward_hook(Reshape(shape), (self,), res)
        return res

    def reshape(self, *shape):
        res = OpenVINOTensor(self._value.reshape(shape))
        res.graph = self.graph

        class Reshape(nn.Module):
            def __init__(self, shape):
                super().__init__()
                self.shape = shape

        forward_hook(Reshape(shape), (self,), res)
        return res

    def permute(self, *order):
        res = OpenVINOTensor(self._value.permute(order))
        res.graph = self.graph

        class Transpose(nn.Module):
            def __init__(self, order):
                super().__init__()
                self.order = order

        forward_hook(Transpose(order), (self,), res)
        return res

    def __getitem__(self, idx):
        assert(idx == 0)
        return self

    def __torch_function__(self, func, types, args=(), kwargs=None):
        if kwargs is None:
            kwargs = {}
        if func not in HANDLED_FUNCTIONS or not all(
            issubclass(t, (torch.Tensor, OpenVINOTensor))
            for t in types
        ):
            return NotImplemented
        return HANDLED_FUNCTIONS[func](*args, **kwargs)


import functools
def implements(torch_function):
    """Register a torch function override for OpenVINOTensor"""
    @functools.wraps(torch_function)
    def decorator(func):
        HANDLED_FUNCTIONS[torch_function] = func
        return func
    return decorator


def register_functional_hook(func):
    @implements(func)
    def function_hook(input, *args, **kwargs):
        output = OpenVINOTensor(func(input.tensor(), *args, **kwargs))
        output.graph = input.graph
        return output

# register_functional_hook(torch.conv2d)
register_functional_hook(F.batch_norm)
# register_functional_hook(F.relu)
# register_functional_hook(F.max_pool2d)
register_functional_hook(F.adaptive_avg_pool2d)
register_functional_hook(F.linear)
register_functional_hook(F.dropout)


@implements(F.max_pool2d)
def function_hook(input, *args, **kwargs):

    class MaxPool2d(nn.Module):
        def __init__(self, kernel_size, stride, padding, dilation, return_indices, ceil_mode):
            super().__init__()
            self.kernel_size = kernel_size
            self.stride = stride
            self.padding = padding
            self.dilation = dilation
            self.return_indices = return_indices
            self.ceil_mode = ceil_mode

    output = OpenVINOTensor(F.max_pool2d(input.tensor(), *args, **kwargs))
    output.graph = input.graph

    forward_hook(MaxPool2d(*args, **kwargs), (input,), output)
    return output


@implements(torch.relu_)
def function_hook(input, *args, **kwargs):

    class ReLU(nn.Module):
        def __init__(self):
            super().__init__()

    output = OpenVINOTensor(torch.relu_(input.tensor(), *args, **kwargs))
    output.graph = input.graph

    forward_hook(ReLU(*args, **kwargs), (input,), output)
    return output


@implements(F.relu)
def function_hook(input, *args, **kwargs):

    class ReLU(nn.Module):
        def __init__(self, inplace):
            super().__init__()

    output = OpenVINOTensor(F.relu(input.tensor(), *args, **kwargs))
    output.graph = input.graph

    forward_hook(ReLU(*args, **kwargs), (input,), output)
    return output


@implements(torch.conv2d)
def function_hook(input, weight, bias, *args, **kwargs):

    class Conv2d(nn.Conv2d):
        def __init__(self, weight, bias, stride, padding, dilation, groups):
            super().__init__(in_channels=input.shape[1],
                             out_channels=weight.shape[0],
                             kernel_size=weight.shape[2:],
                             stride=stride,
                             padding=padding,
                             dilation=dilation,
                             groups=groups,
                             bias=not bias is None)
            params = {'weight': weight}
            if not bias is None:
                params['bias'] = bias
            self.load_state_dict(params)

    output = OpenVINOTensor(torch.conv2d(input.tensor(), weight, bias, *args, **kwargs))
    output.graph = input.graph
    forward_hook(Conv2d(weight, bias, *args, **kwargs), (input,), output)
    return output


@implements(torch.flatten)
def function_hook(input, *args, **kwargs):

    class Flatten(nn.Module):
        def __init__(self, axis):
            super().__init__()
            self.axis = axis

    output = OpenVINOTensor(torch.flatten(input.tensor(), *args, **kwargs))
    output.graph = input.graph

    forward_hook(Flatten(*args, **kwargs), (input,), output)
    return output


@implements(F.interpolate)
def function_hook(input, *args, **kwargs):

    class Upsample(nn.Module):
        def __init__(self, size, scale_factor, mode, align_corners, recompute_scale_factor):
            super().__init__()
            self.size = size
            self.scale_factor = scale_factor
            self.mode = mode
            self.align_corners = align_corners
            self.recompute_scale_factor = recompute_scale_factor

    output = OpenVINOTensor(F.interpolate(input.tensor(), *args, **kwargs))
    output.graph = input.graph

    forward_hook(Upsample(*args, **kwargs), (input,), output)
    return output


# Workaround for a bug https://github.com/pytorch/pytorch/issues/34294
original_cat = torch.cat
def concat(inputs, dim=0):
    class Concat(nn.Module):
        def __init__(self, dim):
            super().__init__()
            self.dim = dim

    if not isinstance(inputs[0], OpenVINOTensor):
        return original_cat(inputs, dim)

    tensors = [inp.tensor() for inp in inputs]
    output = OpenVINOTensor(original_cat(tensors, dim))
    output.graph = inputs[0].graph

    forward_hook(Concat(dim), inputs, output)
    return output

torch.cat = concat
