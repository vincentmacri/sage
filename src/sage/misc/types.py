r"""
Aliases for typing annotations

This typing module defines some common aliases to be used for type annotations in Sage.
This module performs many possibly heavy imports, and so it should only be imported
within an ``if typing.TYPE_CHECKING`` block. This module will raise an error if it
is imported at runtime.

The purpose of this module is to provide aliases when there are many types that
easily coerce into another type, or when the same code will give a different type
depending on whether the preparser is enabled or not.

Type unions defined in this module should usually only be used for annotating parameters,
for return values we should be able to give the exact type. If the return type depends
on the parameters, a union can be used as the return type and ``typing.overload``
can be used to specify the return type for various combinations of parameters.
"""
# ****************************************************************************
#       Copyright (C) 2025 Vincent Macri <vincent.macri@ucalgary.ca>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#                  https://www.gnu.org/licenses/
# ****************************************************************************

import typing

if typing.TYPE_CHECKING:
    from sage.rings.finite_rings.integer_mod import IntegerMod_abstract
    from sage.rings.integer import Integer

    type Int = Integer | int
    type IntMod = IntegerMod_abstract | Int
else:
    assert False, 'sage.misc.types cannot be imported at runtime, it may only be imported in an if `typing.TYPE_CHECKING` block'
