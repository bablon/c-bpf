Writing ebpf in C
-----------------

This is the development environment leveraged from linux source for writing
ebpf programs in C.

There are two epbf programs `cpustat` and `offwaketime`. If a new ebpf program
`foo` needs to be added, create two C files foo_user.c and foo_kern.c and add
the bulding target `foo` in Makefile.

	progs += foo
	...
	foo: foo_user.o bpf_load.o ...
		$(CC) -o $@ $^ $(LDFLAGS)

Also, libraries `libelf` and `libbpf` are required to to be installed on the
host system. On Debian based systems, use the following command.

	sudo apt-get install libelf-dev libbpf-dev
	sudo apt-get install linux-headers-$(uname -r)-amd64 linux-headers-$(uname -r)-common
