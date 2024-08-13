# self describing makefile
#    based on idea in https://gist.github.com/jeffsp/3e1b2e10b9181681a604dd9ec6d64ecf
#
# add support for any Makefile name, see https://www.gnu.org/software/make/manual/make.html#Special-Variables
# add colon after target name so bat -l mk gives nicer display on terminal
# for nicer Markdown add asterix around \1 in sed, e.g. for bat or mdcat
#
# Usage
# ==========
#
# Example 1: No post-processing
#    make --file self-describing-makefile.mk
#
# Example 2: Using the current grep/sed w/o the asterix:
#
#    make --file self-describing-makefile.mk | bat -l mk
#
# Example 3: Change grep+sed to two asterix around the \1 turns into **\1**
#
#    make --file self-describing-makefile.mk | mdcat
#    make --file self-describing-makefile.mk | bat -l md
#

# Get name of Makefile so the grep picks the right one
name1 := $(lastword $(MAKEFILE_LIST))

# Set help as the default goal
.DEFAULT_GOAL := help

TAG := kali-linux

.PHONY: build # Builds the Docker image under the TAG name which is by default kali-linux
build:
	@echo "Building $(TAG) image"
	@sleep 1
	docker build -t $(TAG) \
        --build-arg KALI_IMAGE_BASE_TAG=20240811 \
        --build-arg KALI_PACKAGE=core \
        --build-arg RDP_PORT=13389 \
        --build-arg SSH_PORT=20022 \
        --build-arg UNAME=xuser \
        --build-arg UPASS=password123 \
        .

.PHONY: run # Runs the Docker image under the TAG name which is by default kali-linux
run: build
	@echo "Running $(TAG) image"
	@sleep 1
	docker run -it -p 13389:13389 -p 20022:22 --rm --name $(TAG) $(TAG)

.PHONY: clean # Removes the Docker image under the TAG name which is by default kali-linux
clean:
	@echo "Cleaning up $(TAG) image"
	@sleep 1
	docker image rm $(TAG)

.PHONY: help # Generate list of targets with descriptions
help:
	@grep '^.PHONY: .* #' "$(name1)" | sed 's/\.PHONY: \(.*\) # \(.*\)/\1: \2/' | expand -t20
