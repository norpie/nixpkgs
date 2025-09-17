{
  lib,
  stdenv,
  buildPythonPackage,

  # build-system
  pybind11,
  setuptools,

  # dependencies
  ctranslate2-rocm-cpp,
  numpy,
  pyyaml,

  # tests
  pytestCheckHook,
  torch,
  transformers,
  writableTmpDirAsHomeHook,
  wurlitzer,
}:

buildPythonPackage rec {
  inherit (ctranslate2-rocm-cpp) pname version src;
  pyproject = true;

  # https://github.com/arlo-phoenix/CTranslate2-rocm/tree/master/python
  sourceRoot = "${src.name}/python";

  build-system = [
    pybind11
    setuptools
  ];

  buildInputs = [ ctranslate2-rocm-cpp ];

  dependencies = [
    numpy
    pyyaml
  ];

  pythonImportsCheck = [
    # https://opennmt.net/CTranslate2/python/overview.html
    "ctranslate2"
    "ctranslate2.converters"
    "ctranslate2.models"
    "ctranslate2.specs"
  ];

  nativeCheckInputs = [
    pytestCheckHook
    torch
    transformers
    writableTmpDirAsHomeHook
    wurlitzer
  ];

  preCheck = ''
    # run tests against build result, not sources
    rm -rf ctranslate2
  '';

  disabledTests = lib.optionals stdenv.hostPlatform.isDarwin [
    # Fatal Python error: Aborted
    "test_invalid_model_path"
  ] ++ [
    # bfloat16 support is commented out in this ROCm fork
    "test_storageview_conversion"
  ];

  disabledTestPaths = [
    # TODO: ModuleNotFoundError: No module named 'opennmt'
    "tests/test_opennmt_tf.py"
    # OSError: We couldn't connect to 'https://huggingface.co' to load this file
    "tests/test_transformers.py"
  ];

  meta = {
    description = "Fast inference engine for Transformer models with ROCm support";
    homepage = "https://github.com/arlo-phoenix/CTranslate2-rocm";
    changelog = "https://github.com/arlo-phoenix/CTranslate2-rocm/blob/${src.rev}/README_ROCM.md";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      # Add yourself as maintainer here
    ];
    platforms = lib.platforms.linux; # ROCm is Linux-only
  };
}