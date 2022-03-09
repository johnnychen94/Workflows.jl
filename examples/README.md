# Examples

A collection of examples to show Workflows functionalities.

## run

First initialize the project

```console
julia --project=examples -e 'using Pkg; Pkg.develop(path=".")'
# or
julia --project=examples -e 'using Pkg; Pkg.initialize()'
```

and then run all of them via

```console
julia --project=examples examples/run.jl
```

You may check `examples/run.jl` to see how to run individual example.

## Description

| path                 | description                                                                       |
| -------------------- | --------------------------------------------------------------------------------- |
| `manifest`           | a julia/numpy benchmark example using manifest dialect                            |
| `manifest_loop`      | a julia/numpy benchmark example using manifest dialect with matrix notation       |
