def ray_systemlibs():
    native.new_local_repository(
        name = "boost",
        path = "/usr/lib",
        build_file = "//:thirdparty/systemlibs/boost.BUILD"
    )
