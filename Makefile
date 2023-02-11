#
# Benchmarks
#
# For each benchmark, please add to init::, clean::, and fio::
# as well as exporting MOUNT and JOB.
#
# Note: Make sure to trim trailing whitespaces.
#

MOUNT_PRIFIX=$(HOME)/mnt

#
# s3fs-vanilla
#
init_s3fs_vanilla: MOUNT=$(MOUNT_PRIFIX)/s3fs-vanilla
init_s3fs_vanilla: export AWSACCESSKEYID=$(S3FS_AWS_ACCESS_KEY_ID)
init_s3fs_vanilla: export AWSSECRETACCESSKEY=$(S3FS_AWS_SECRET_ACCESS_KEY)
init_s3fs_vanilla:
	mkdir -p $(MOUNT)
	s3fs s3fs-vanilla $(MOUNT) -o url=https://s3.us-west-004.backblazeb2.com
init:: init_s3fs_vanilla

clean_s3fs_vanilla: MOUNT=$(MOUNT_PRIFIX)/s3fs-vanilla
clean_s3fs_vanilla:
	rm -rf $(MOUNT)/*
	umount $(MOUNT)
clean:: clean_s3fs_vanilla

fio_s3fs_vanilla: export JOB=s3fs-vanilla
fio_s3fs_vanilla: export MOUNT=$(MOUNT_PRIFIX)/$(JOB)
fio_s3fs_vanilla:
	fio bench.fio
fio:: fio_s3fs_vanilla

s3fs_vanilla:: init_s3fs_vanilla
s3fs_vanilla:: fio_s3fs_vanilla
s3fs_vanilla:: clean_s3fs_vanilla

#
# local
#
init_local: MOUNT=$(MOUNT_PRIFIX)/local
init_local:
	mkdir -p $(MOUNT)
init:: init_local

clean_local: MOUNT=$(MOUNT_PRIFIX)/local
clean_local:
	rm -rf $(MOUNT)
clean:: clean_local

fio_local: export JOB=local
fio_local: export MOUNT=$(MOUNT_PRIFIX)/$(JOB)
fio_local:
	fio bench.fio
fio:: fio_local

local:: init_local
local:: fio_local
local:: clean_local

#
# fsspec + fuse
# TODO: this doesn't work with B2 right now. not sure why.
#
init_fsspec: MOUNT=$(MOUNT_PRIFIX)/fsspec
init_fsspec: export AWS_ACCESS_KEY_ID=$(FSSPEC_AWS_ACCESS_KEY_ID)
init_fsspec: export AWS_SECRET_ACCESS_KEY=$(FSSPEC_AWS_SECRET_ACCESS_KEY)
init_fsspec:
	mkdir -p $(MOUNT)
	python -m fsspec.fuse "s3://" -o "client_kwargs-endpoint_url=https://s3.us-west-004.backblazeb2.com" / $(MOUNT) -r -l./fuse.log
# init:: init_fsspec

clean_fsspec: MOUNT=$(MOUNT_PRIFIX)/fsspec
clean_fsspec:
	rm -rf $(MOUNT)
# clean:: clean_fsspec

fio_fsspec: export JOB=fsspec
fio_fsspec: export MOUNT=$(MOUNT_PRIFIX)/$(JOB)
fio_fsspec:
	fio bench.fio
# fio:: fio_fsspec

fsspec:: init_fsspec
fsspec:: fio_fsspec
fsspec:: clean_fsspec

#
#
#
plot:
	mkdir -p ./results
	mv -f *.log ./results || exit 0
	cd ./results && python ../plot.py result
fio:: plot

