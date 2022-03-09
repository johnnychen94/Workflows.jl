# Examples

A collection of examples to show Workflows functionalities.

## run

First initialize the project

```console
julia --project=examples -e 'using Pkg; Pkg.develop(path=".")'
# or
julia --project=examples -e 'using Pkg; Pkg.initialize()'
```

and then execute all examples via

```console
julia --project=examples examples/run.jl
```

## Description

| path                 | description                                                                       |
| -------------------- | --------------------------------------------------------------------------------- |
| `manifest`           | a julia/numpy benchmark example using manifest dialect                            |
| `manifest_loop`      | a julia/numpy benchmark example using manifest dialect with matrix notation       |
