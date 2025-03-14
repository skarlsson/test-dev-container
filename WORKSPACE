workspace(name = "test_dev_container")

# This WORKSPACE file is for the container itself.
# The actual project dependencies will be defined in the test-dev-bazel project.

# You can add additional dependencies required for development here
# For example, add rules for C++ development

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# Hedron's Compile Commands Extractor for Bazel
# This is useful for getting compile_commands.json for CLion
http_archive(
    name = "hedron_compile_commands",
    url = "https://github.com/hedronvision/bazel-compile-commands-extractor/archive/refs/tags/v0.6.3.tar.gz",
    strip_prefix = "bazel-compile-commands-extractor-0.6.3",
    sha256 = "d10b3c6abd4dfa5d913c75b1a52d8cc304ff55472fca73631b87ee12f12dc805",
)
load("@hedron_compile_commands//:workspace_setup.bzl", "hedron_compile_commands_setup")
hedron_compile_commands_setup()
