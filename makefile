SHELL = /bin/sh

PROJECT_DIR = $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
export SRC_DIR = $(PROJECT_DIR)src/
export TEST_DIR = $(PROJECT_DIR)test/

GENERATED_TAG = -generated
CLEAN_TAG = .clean
CHECK_TAG = .check

TEST_GENERATORS = dir-slash-test diff-dir-test
GENERATED_TEST_SUITE = $(TEST_GENERATORS)
GENERATED_TESTS = $(addsuffix $(GENERATED_TAG).sh, $(TEST_GENERATORS))
GENERATED_TESTS_FULL_PATH = $(addprefix $(TEST_DIR), $(GENERATED_TESTS))
CLEAN_GENERATED_TESTS = $(addsuffix $(CLEAN_TAG), $(addprefix $(TEST_DIR), $(GENERATED_TESTS)))
TESTS = $(GENERATED_TEST_SUITE)

SRC_FILES = jar-update.sh jar-update-lib.sh
SRC_FILES_FULL_PATH = $(addprefix $(SRC_DIR), $(SRC_FILES))
SRC_FILES_FULL_PATH_CHECK = $(addsuffix $(CHECK_TAG), $(SRC_FILES_FULL_PATH))

TEST_FILES = test-lib.sh $(addsuffix .sh, $(TEST_GENERATORS))
TEST_FILES_FULL_PATH = $(addprefix $(TEST_DIR), $(TEST_FILES))
TEST_FILES_FULL_PATH_CHECK = $(addsuffix $(CHECK_TAG), $(TEST_FILES_FULL_PATH))

CHECK_FILES = $(SRC_FILES_FULL_PATH_CHECK) $(TEST_FILES_FULL_PATH_CHECK)

all: check

check: $(SRC_FILES_FULL_PATH_CHECK)

testcheck: $(TEST_FILES_FULL_PATH_CHECK)

$(CHECK_FILES):
	-cd $(dir $@) && shellcheck -x $(notdir $(subst $(CHECK_TAG),,$@))

testgen: $(GENERATED_TESTS_FULL_PATH)

$(GENERATED_TESTS_FULL_PATH): %-generated.sh : %.sh
	$(subst $(GENERATED_TAG),,$@)

test: $(TESTS)

$(GENERATED_TEST_SUITE): testcheck $(GENERATED_TESTS_FULL_PATH)
	-$(addsuffix $(GENERATED_TAG).sh, $(TEST_DIR)$@)

testclean: $(CLEAN_GENERATED_TESTS)

$(CLEAN_GENERATED_TESTS):
	-rm $(subst $(CLEAN_TAG),,$@)

