This is a fork for origin [traveling-ruby](https://github.com/phusion/traveling-ruby), origin README.md please see [here](https://github.com/zw963/traveling-ruby/blob/updated_linux_branch/ORIGIN_README.md)

This is not a completed fork about old project, and current, only `linux/linux64` is supported.

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

1. Current supported version: 2.1.6 2.2.2 2.3.4 2.4.3 2.5.1 2.5.3 2.6.0, in fact, you can add any version you want to `linux/RUBY_VERSIONS.txt`, and build it.
2. When first build, it very slow, maybe need wait 20+ minutes to finish.
3. If you build image failed, it maybe because your kernel not compatible with docker(18.03.1-ce), try use LTS version kernel, current working version is: 4.14.90
4. I use this build since 11 months before (2018-01), it seem like work well for my personal usage (so many ruby tools which need a portable ruby release)
