This is a fork for origin [traveling-ruby](https://github.com/phusion/traveling-ruby), origin README.md please see [here](https://github.com/zw963/traveling-ruby/blob/updated_linux_branch/ORIGIN_README.md)

This is not a completed fork of old project, and current, only `linux/linux64` is supported,
and only partial external library is supported, So, you can think it as a just working version pure traveling ruby.

But, anyway, it still is a traveling ruby!

## Way of the Traveling Ruby

Following is the step to build newest ruby for linux.

### 1. cd linux folder

```sh
$ cd linux
```

### 2. build phusion/traveling-ruby-builder image yourself. (As we know, phusion offcial image is broken, that is the reason this script not working)
```sh
./setup-docker-image
```

### 3. run rake task to build expected ruby version.

Following is a example to build ruby 2.5.3.

```sh
$: rake build:2.5.3:x86_64
```

## Caveats

1. foreign binary package only sqlite supported is included, postgres, mysql, ICU, libssh is removed.
2. CMake is removed. (I don't know where to use it, seem like make just working)
2. Current supported version: 2.1.6 2.2.2 2.3.4 2.4.3 2.5.1 2.5.3 2.6.0, in fact, you can add any version you want to `linux/RUBY_VERSIONS.txt`, and build it.
3. When first build, it very slow, maybe need wait 20+ minutes to finish.
4. If you build image failed, it maybe because your kernel not compatible with docker(18.03.1-ce), try use LTS version kernel, current working version is: 4.14.90
5. I use this build since 11 months before (2018-01), it seem like work well for my personal usage (so many ruby tools which need a portable ruby release)
6. As changed in 76c157b, we need add `-std=gnu99` to let make work, for other environment, maybe can try with `-std=c99`

## Others

If you don't want build yourself with docker, you can download precompiled version [2.6.0-x86_64](https://zw963.github.io/files/2.6.0-x86_64.tar.gz), [2.6.0-x86](https://zw963.github.io/files/2.6.0-x86.tar.gz)

### Why i maintain a forked x86_64 linux version traveling ruby?

It's for my own [ruby_tools](https://github.com/zw963/ruby_tools) project, maybe you are interested.
