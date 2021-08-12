---
keywords: Julia,C++
CJKmainfont: KaiTi
---

# A Guide to Wrap a C++ Library with CxxWrap.jl and BinaryBuilder.jl in Julia

The following parts are not covered here:

1. How to write the wrapper code in C++. (It is detailed [here](https://github.com/JuliaInterop/CxxWrap.jl). And I find the [examples](https://github.com/JuliaInterop/libcxxwrap-julia/tree/master/examples) are also very useful!)

And you will learn the following parts after reading this post.

1. How to quickly debug your code?
1. The missing parts that are not documented in [BinaryBuilder.jl](https://github.com/JuliaPackaging/BinaryBuilder.jl) and [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl)

## Prepare

First things first. Suppose you want to write a Julia wrapper for a C++ package (I'll take the one I wrote, [VisualDL](https://github.com/PaddlePaddle/VisualDL), for example). You need to fork that repo into your own account and clone that repo to your local computer. Then install necessary dependencies according to the document and make sure you can compile it successfully.

The next step is to write the wrapper code. Usually you would like to add a flag in the `CMakeLists.txt` file to signafy whether to build the Julia wrapper or not. Like [this](https://github.com/findmyway/VisualDL/blob/julia/CMakeLists.txt#L37)

```
option(WITH_JULIA       "Compile VisualDL with Julia"               OFF)
```

Then make a seperate folder containing all your source codes and corresponding `CMakeLists.txt`. And include that folder in the root `CMakeLists.txt` file. Like [this](https://github.com/findmyway/VisualDL/blob/julia/CMakeLists.txt#L76-L78)

```
if(WITH_JULIA)
  add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/visualdl/julia)
endif()
```

For the simplest case, only a `CMakeLists.txt` file and `your_wrapper_code.cc` are needed. Like [this](https://github.com/findmyway/VisualDL/tree/julia/visualdl/julia)

Following the instructions from [CxxWrap.jl](https://github.com/JuliaInterop/CxxWrap.jl), you should find it easy to write the wrapper codes. If the project you are working on already has a python wrapper, I strongly suggest you to take look at it first. And it will save you a lot of time.

Then you need to specify how to build your target in the `CMakeLists.txt`, for [example](https://github.com/findmyway/VisualDL/blob/julia/visualdl/julia/CMakeLists.txt):

```
# 1. find JlCxx

find_package(JlCxx REQUIRED)

# 2. add libraries and dependencies

add_library(im ${PROJECT_SOURCE_DIR}/visualdl/logic/im.cc)
add_library(sdk ${PROJECT_SOURCE_DIR}/visualdl/logic/sdk.cc ${PROJECT_SOURCE_DIR}/visualdl/utils/image.h)
add_dependencies(im storage_proto)
add_dependencies(sdk entry binary_record storage storage_proto eigen3)
add_library(vdljl SHARED vdljl.cc)
add_dependencies(vdljl im entry tablet sdk storage protobuf eigen3)

# 3. specify targets

target_link_libraries(vdljl PRIVATE JlCxx::cxxwrap_julia entry binary_record im tablet storage sdk protobuf ${OPTIONAL_LINK_FLAGS})

# 4. install

install(TARGETS vdljl
    RUNTIME DESTINATION lib
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib)
```

## Local Debug

Now you have finished all the necessary changes to the original package, you may want to get the compiled library.

Let's install `CxxWrap` in Julia first. Enter the package mode and add `CxxWrap`

```julia
(v1.1) pkg> add CxxWrap
```

Now you have `CxxWrap` and the underlying [`libcxxwrap-julia`](https://github.com/JuliaInterop/libcxxwrap-julia) installed. We can print the library path and the cmake file path:

```julia
julia> using CxxWrap

julia> CxxWrap.jlcxx_path
"/home/tj/.julia/packages/CxxWrap/KcmSi/deps/usr/lib/libcxxwrap_julia.so"

julia> julia> readdir(joinpath(dirname(CxxWrap.jlcxx_path), "cmake", "JlCxx"))
5-element Array{String,1}:
 "FindJulia.cmake"
 "JlCxxConfig.cmake"
 "JlCxxConfigExports-release.cmake"
 "JlCxxConfigExports.cmake"
 "JlCxxConfigVersion.cmake"
```

What we are interested in here is the the path of `joinpath(dirname(CxxWrap.jlcxx_path), "cmake", "JlCxx")` (Here is the `/home/tj/.julia/packages/CxxWrap/KcmSi/deps/usr/lib/cmake/JlCxx`). Now we can compile the package with `JlCxx_DIR` properly set:

```
$ mkdir build

$ cd build

$ cmake -DWITH_JULIA=ON -DJlCxx_DIR=/home/tj/.julia/packages/CxxWrap/KcmSi/deps/usr/lib/cmake/JlCxx ..

$ make

$ make install
```

Then you can load the compiled library in the Julia REPL for testing:

```julia
module VisualDL
  using CxxWrap
  @wrapmodule("/absolute/path/to/your/lib")

  function __init__()
    @initcxx
  end
end

using .VisualDL
```

## BinaryBuilder

In order to leverage the BinaryBuilder, we create an independent repo (for example, [VisualDLBuilder](https://github.com/findmyway/VisualDLBuilder)) to build the tarballs. Be careful with the following lines:

1. Don't forget to specify the `compiler_abi` field in the platforms like [this](https://github.com/findmyway/VisualDLBuilder/blob/master/build_tarballs.jl#L7) here, if your code doesn't compile with old gcc.
1. For the [`sources`](https://github.com/findmyway/VisualDLBuilder/blob/master/build_tarballs.jl#L10) in the `build_tarballs.jl`, you can specify an absolute local path pointing to the modified package above for debugging. After making sure that everything works fine, you make a PR then ask the repo owner to tag a new release. And then change this variable into the `url => hash` form.
1. Do not forget to run `make install` at the end of [script](https://github.com/findmyway/VisualDLBuilder/blob/master/build_tarballs.jl#L19). Seriously!
1. In the `dependencies` [part](https://github.com/findmyway/VisualDLBuilder/blob/master/build_tarballs.jl#L26), remember to add both CxxWrap and Julia.

As for the `.travis.yml` [file](https://github.com/findmyway/VisualDLBuilder/blob/master/.travis.yml#L21), for now you need to specify the `MbedTLS` to version `0.6.6` due to the [error](https://github.com/JuliaWeb/MbedTLS.jl/issues/193).

Althought there's a helper function in BinaryBuilder.jl named `setup_travis` to help you set up the deploy step, I never succeed. So I'd suggest you to install [travis cli](https://github.com/travis-ci/travis.rb#installation) and run **travis login --pro** first!!! Then `travis setup releases`.

## The Julia Wrapper Package

This is the final step. You create a new package. Add the `CxxWrap` as your dependency. Rename the build file you get by BinaryBuilder to `build.jl` and put it into the `deps` folder. And you expect to get the `deps.jl` after running `julia deps/build.jl`. Unfortunately, you'll see an error like this:

```
ERROR: LoadError: LibraryProduct(nothing, ["libvdljl"], :libvdljl, "Prefix(/home/tianjun/tmp/visualdl/deps/usr)") is not satisfied, cannot generate deps.jl!
```

The reason is that we need the shared package of `jlcxx`. So remember to put `using CxxWrap` in the first line of `build.jl`. Then everything should work as you wish.