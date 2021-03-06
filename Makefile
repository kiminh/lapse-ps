ifdef config
include $(config)
endif

include make/ps.mk

ifndef CXX
CXX = g++
endif

ifndef DEPS_PATH
DEPS_PATH = $(shell pwd)/deps
endif


ifndef PROTOC
PROTOC = ${DEPS_PATH}/bin/protoc
endif

INCPATH = -I./src -I./include -I$(DEPS_PATH)/include
CFLAGS = -std=c++11 -msse2 -fPIC -O3 -ggdb -march=native -Wall -finline-functions $(INCPATH) $(ADD_CFLAGS)

all: ps tests apps

include make/deps.mk

clean:
	rm -rf build $(TESTS) tests/*.d
	rm -rf build $(APPS) apps/*.d
	find src -name "*.pb.[ch]*" -delete
	rm -rf deps/
	rm -rf protobuf-*

lint:
	python tests/lint.py ps all include/ps src

ps: build/libps.a

OBJS = $(addprefix build/, customer.o postoffice.o van.o meta.pb.o)
build/libps.a: $(OBJS)
	ar crv $@ $(filter %.o, $?)

build/%.o: src/%.cc ${ZMQ} src/meta.pb.h
	@mkdir -p $(@D)
	$(CXX) $(INCPATH) -std=c++0x -MM -MT build/$*.o $< >build/$*.d
	$(CXX) $(CFLAGS) -c $< -o $@

src/%.pb.cc src/%.pb.h : src/%.proto ${PROTOBUF}
	$(PROTOC) --cpp_out=./src --proto_path=./src $<

-include build/*.d
-include build/*/*.d

include tests/test.mk
tests: $(TESTS)

include apps/apps.mk
apps: $(APPS)

include mb/mb.mk
mb: $(MB)

run:
	fab -H localhost makedsgd dsgdtoy --servers 2 --coloc

include custom.mk
