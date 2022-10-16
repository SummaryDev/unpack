CC = gcc
GOCMD=go
GOBUILD=$(GOCMD) build
CFLAGS = -Wall -Wextra -O2 -g -I. -I./ -I$(shell pg_config --includedir-server)
LDFLAGS = -bundle -multiply_defined suppress -lpthread -L$(shell pg_config --libdir) -bundle_loader $(shell pg_config --bindir)/postgres
RM = rm -f

# C shared object
TARGET_EXT = pg-func.so
SRCS_EXT = pg-func.c
OBJS_EXT = $(SRCS_EXT:.c=.o)
PG_MOD=$(shell pwd)/$(TARGET_EXT)

# GO static library without wildcard
TARGET_LIB = libunpack.a
SRCS_LIB = libunpack.go

.PHONY: all
all: $(TARGET_LIB) $(TARGET_EXT)

$(TARGET_LIB): $(SRCS_LIB)
	$(GOBUILD) -buildmode=c-archive -o $(TARGET_LIB) $(SRCS_LIB)

$(TARGET_EXT): $(OBJS_EXT)
	$(CC) $(LDFLAGS) -o $@ $^ $(TARGET_LIB)

$(SRCS_EXT:.c=.d):%.d:%.c
	$(CC) $(CFLAGS) -MM $< >$@

install: $(PG_MOD)
	psql $(PG_DBNAME) --set=MOD=\'$(PG_MOD)\' -f install-func.sql

install-db:
	psql $(PG_DBNAME) -f setup-db.sql

.PHONY: clean
clean:
	-$(RM) $(TARGET_EXT) $(OBJS_EXT) $(SRCS_EXT:.c=.d) $(TARGET_LIB) $(SRCS_LIB:.go=.h)