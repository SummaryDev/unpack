CC = gcc
GOCMD=go
GOBUILD=$(GOCMD) build
UNAME=$(shell uname)
INCLUDE_DIR=$(shell pg_config --includedir-server)
LIB_DIR=$(shell pg_config --libdir)
BIN_DIR=$(shell pg_config --bindir)
CFLAGS = -Wall -O2 -g -I. -I./ -I$(INCLUDE_DIR)

ifeq ($(UNAME),Darwin)
	LDFLAGS = -bundle -multiply_defined suppress -lpthread -L$(LIB_DIR) -bundle_loader $(BIN_DIR)/postgres
else
	LDFLAGS = -shared -lpthread -L$(LIB_DIR)
endif

RM = rm -f

# C shared object
TARGET_EXT = pg-func.so
SRCS_EXT = pg-func.c
OBJS_EXT = $(SRCS_EXT:.c=.o)
PG_MOD=$(PWD)/$(TARGET_EXT)

# GO static library without wildcard
TARGET_LIB = libunpack.a
SRCS_LIB = libunpack.go

.PHONY: all
all: clean $(TARGET_LIB) $(TARGET_EXT) install

$(TARGET_LIB): $(SRCS_LIB)
	$(GOBUILD) -buildmode=c-archive -o $(TARGET_LIB) $(SRCS_LIB)

$(TARGET_EXT): $(OBJS_EXT)
	$(CC) $(LDFLAGS) -o $@ $^ $(TARGET_LIB)

$(SRCS_EXT:.c=.d):%.d:%.c
	$(CC) $(CFLAGS) -MM $< >$@

install: $(PG_MOD)
	psql --set=MOD=\'$(PG_MOD)\' -f install-func.sql

install-db:
	psql -f setup-db.sql

.PHONY: clean
clean:
	-$(RM) $(TARGET_EXT) $(OBJS_EXT) $(SRCS_EXT:.c=.d) $(TARGET_LIB) $(SRCS_LIB:.go=.h)
