#!/usr/bin/env python

import sys
import os
from fnmatch import fnmatch
from setuptools import setup, find_packages
from setuptools.command.install import install

def create_package(framework):
    deps = []
    with open('requirements_{}.txt'.format(framework), 'rt') as f:
        for line in f.read().splitlines():
            if not fnmatch(line, 'test-generator*'):
                deps.append(line)

    class InstallCmd(install):
        def run(self):
            install.run(self)
            path = os.path.join(self.install_purelib, 'requirements_{}.txt'.format(framework))
            with open(path, 'wt') as f:
                f.write('\n'.join(deps))


    setup(name='openvino-mo-{}'.format(framework),
          version='2021.1',
          author='Intel',
          url='https://github.com/openvinotoolkit/openvino/',
          packages=find_packages(),
          py_modules=['mo_{}'.format(framework)],
          cmdclass={
              'install': InstallCmd,
          },
          install_requires=deps,
          include_package_data=True,
    )

create_package('onnx')
