# syntax=docker/dockerfile:1
#
# Build a Kairos "core" base image from an upstream OS image using kairos-init.
# Use this for OS versions Spectro has NOT (yet) published to palette-images
# (e.g. Ubuntu 26.04), where the curated kairos-ubuntu:<ver>-core-... tag does
# not exist. Feed the result to CanvOS via .arg BASE_IMAGE=<this tag> — CanvOS
# only derives the curated tag when BASE_IMAGE is empty, so setting it bypasses
# the lookup and builds FROM this image directly. CanvOS still layers the k8s
# provider (k3s/rke2) on top, so this stays VARIANT=core with NO provider baked.
#
# Build via:  make kairos-base BASE_OS_IMAGE=ubuntu:26.04
#
ARG BASE_IMAGE=ubuntu:26.04
ARG KAIROS_INIT_VERSION=v0.13.0

FROM quay.io/kairos/kairos-init:${KAIROS_INIT_VERSION} AS kairos-init

FROM ${BASE_IMAGE} AS base-kairos
ARG VARIANT=core
ARG MODEL=generic
ARG TRUSTED_BOOT=false
# Kairos framework version to stamp. Default matches CanvOS master's KAIROS_VERSION
# so the produced base lines up with what CanvOS expects.
ARG KAIROS_VERSION=v4.0.3

COPY --from=kairos-init /kairos-init /kairos-init

# Two-phase kairos-init: `install` lays down the framework packages, `init`
# wires up immutability / bootloader / initramfs.
RUN /kairos-init -l debug -s install -m "${MODEL}" -v "${VARIANT}" -t "${TRUSTED_BOOT}" --version "${KAIROS_VERSION}"
RUN /kairos-init -l debug -s init    -m "${MODEL}" -v "${VARIANT}" -t "${TRUSTED_BOOT}" --version "${KAIROS_VERSION}"

RUN rm -f /kairos-init
