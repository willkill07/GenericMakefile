# Generic Makefile v2.1
#
# William Killian
# william.killian@gmail.com
#
# 2014 April 5
#

CC := gcc
CFLAGS := -std=c11

CXX := g++
CXXFLAGS := -std=c++11

CPPFLAGS := -O3 -march=native

TARGET_ARCH := -m64

# no -D,-I,-L,-l flags required
DEFINES := NODEBUG
INCLUDE_PATHS := .. inc/ 
LIBRARY_PATHS :=
LIBRARIES := m

HEADERS := .h .hpp .hh
SUFFIXES := .c .cpp .cxx .cc .C

# group definitions for link. whichever source file is matched FIRST will use the compiler
# (indicated after the colon) as the LINKER
LINK_ORDER := (.cpp,.cxx,.cc,.C:$(CXX)) (.c:$(CC))

# used for auto dependency generation
AUTO_DEPEND_FLAG := -MMD



# ----- DO NOT EDIT ANYTHING BELOW HERE UNLESS YOU ARE CRAZY -----


#                                                       . -> \. | any whitespace -> \|     | delete first \|
SUFFIXES_MUTATOR := \($(shell echo $(SUFFIXES) | sed 's/\./\\./g;s/[[:space:]]\{1,\}/\\\|/g;s/^\\|//')\)

#                                           delete whitespace   | . -> ' %.' | delete leading whitespace
HEADERS := $(shell echo $(HEADERS) | sed 's/[[:space:]]\{1,\}//g;s/\./ %./g;s/^[[:space:]]*//')

SOURCES := $(shell find . -regextype posix-extended -regex .*$(SUFFIXES_MUTATOR))

OBJECTS := $(shell echo $(SOURCES) | sed 's/$(SUFFIXES_MUTATOR)/.o/g')

DEPENDS := $(shell echo $(SOURCES) | sed 's/$(SUFFIXES_MUTATOR)/.d/g')

# Linking Magic!

# will print out compiler used for given sources (or nothing)
LINK_TEST = $(shell echo '$(SOURCES)' | sed -n '$(LINK_TRANSFORM)')
# generates sed regex to convert source -> compiler
LINK_TRANSFORM = $(shell echo "$(LINK_OPTION)" | sed "s/,/\\\|/g;s^(\(.*\):\(.*\))^s/.*\\\(\1\\\)\\\>.*/\2/p^")
# builds a list of compilers invoked for given sources
LINK_LIST := $(foreach LINK_OPTION, $(LINK_ORDER), $(LINK_TEST))
# grab the first one we see
LINK := $(shell echo $(LINK_LIST) | sed 's/[[:space:]]*\(.*\)[[:space:]]\{1,\}.*/\1/')

# given words in PARAM_LIST, add a -FLAG prefix where FLAG is a passed flag
INSERT_FLAG = $(if $(PARAM_LIST), $(FLAG)$(shell echo $(PARAM_LIST) | sed 's/\([[:space:]]\{1,\}\)\([^[:space:]]\)/\1$(FLAG)\2/g'))

# DEFINES
PARAM_LIST := $(DEFINES)
FLAG := -D
DEFINES := $(INSERT_FLAG)

# INCLUDES
PARAM_LIST := $(INCLUDE_PATHS)
FLAG := -I
INCLUDE_PATHS := $(INSERT_FLAG)

# LDFLAGS
PARAM_LIST := $(LIBRARY_PATHS)
FLAG := -L
LDFLAGS := $(INSERT_FLAG)

# LDLIBS
PARAM_LIST := $(LIBRARIES)
FLAG := -l
LDLIBS := $(INSERT_FLAG)

# Update CPP flags for compilation
CPPFLAGS := $(AUTO_DEPEND_FLAG) $(DEFINES) $(INCLUDE_PATHS) $(CPPFLAGS)

.PHONY: clean veryclean info Makefile flags $(DEPENDS)

# Default to display info
info:
	@echo "DISPLAYING MAKE INFO"
	@echo "--------------------"
	@echo "SOURCES:"
	@echo "$(SOURCES)"
	@echo "OBJECTS:"
	@echo "$(OBJECTS)"
	@echo "DEPENDS:"
	@echo "$(DEPENDS)"
	@echo " "
	@echo "To compile, specify a target name  e.g. 'make myBinary'"

# Flags -- useful for ac-clang in emacs
flags:
ifeq (($LINK),$(CC))
	@echo $(DEFINES) $(INCLUDE_PATHS) $(CFLAGS)
else
	@echo $(DEFINES) $(INCLUDE_PATHS) $(CXXFLAGS)
endif

# Cleaning
clean:
	@rm -v -f $(OBJECTS)

veryclean : clean
	@rm -v -f $(DEPENDS)

# Final Linking
% : $(OBJECTS)
	$(eval CPPFLAGS := $(shell echo $(CPPFLAGS) | sed 's/$(AUTO_DEPEND_FLAG)//g'))
ifeq ($(LINK),$(CC))
	$(eval CPPFLAGS := $(CPPFLAGS) $(CFLAGS))
else
	$(eval CPPFLAGS := $(CPPFLAGS) $(CXXFLAGS))
endif
	$(LINK) $(CPPFLAGS) $(LDFLAGS) $(TARGET_ARCH) $^ $(LOADLIBES) $(LDLIBS) -o $@

# Don't forget the dependencies
-include $(DEPENDS)
