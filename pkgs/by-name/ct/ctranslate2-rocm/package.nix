{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  llvmPackages,
  writeText,

  config,
  rocmSupport ? true, # Default to true for this ROCm-specific package
  rocmPackages ? { },
  gpuTargets ? [
    "gfx900"  # MI25, Vega 56/64
    "gfx906"  # MI50/60, Radeon VII
    "gfx908"  # MI100
    "gfx90a"  # MI210/250
    "gfx942"  # MI300
    "gfx1030" # W6800, various Radeon cards
    "gfx1100" # RDNA3
    "gfx1101" # RDNA3
    "gfx1102" # RDNA3
  ], # Conservative default covering major ROCm architectures

  withMkl ? false,
  mkl,
  withOneDNN ? false,
  oneDNN,
  withOpenblas ? true,
  openblas,
  withRuy ? true,
}:

let
  cmakeBool = b: if b then "ON" else "OFF";
  stdenv' = if rocmSupport then rocmPackages.stdenv else stdenv;
in
stdenv'.mkDerivation rec {
  pname = "ctranslate2-rocm";
  version = "4.1.0";

  src = fetchFromGitHub {
    owner = "arlo-phoenix";
    repo = "CTranslate2-rocm";
    rev = "81c77087ec264299dbfe32a202c01f2b7e798a91";
    hash = "sha256-ALS6Bl/U4AY7j4IWLcKeUR8coXnxSNKn5z3yHjqwd1M=";
    fetchSubmodules = true;
  };

  postPatch = lib.optionalString rocmSupport ''
    # Fix OpenMP include directory handling for COMP runtime
    substituteInPlace CMakeLists.txt \
      --replace "add_compile_options(\''${OpenMP_CXX_FLAGS})" \
                "add_compile_options(\''${OpenMP_CXX_FLAGS})
      if(OpenMP_CXX_INCLUDE_DIRS)
        include_directories(\''${OpenMP_CXX_INCLUDE_DIRS})
      endif()"

    # Add hiprand include directories for HIP compilation
    substituteInPlace CMakeLists.txt \
      --replace "if (WITH_HIP)" \
                "if (WITH_HIP)
      include_directories(\"${rocmPackages.hiprand}/include\")
      include_directories(\"${rocmPackages.rocrand}/include\")"
  '';

  nativeBuildInputs = [
    cmake
  ]
  ++ lib.optionals rocmSupport [
    rocmPackages.clr
    rocmPackages.hiprand
    rocmPackages.rocrand
  ];

  cmakeFlags = [
    "-DOPENMP_RUNTIME=COMP"
    "-DWITH_HIP=${cmakeBool rocmSupport}"
    "-DWITH_CUDA=OFF"
    "-DWITH_CUDNN=${cmakeBool rocmSupport}" # ROCm fork uses this for MIOpen
    "-DWITH_DNNL=${cmakeBool withOneDNN}"
    "-DWITH_OPENBLAS=${cmakeBool withOpenblas}"
    "-DWITH_RUY=${cmakeBool withRuy}"
    "-DWITH_MKL=${cmakeBool withMkl}"
    "-DBUILD_TESTS=OFF" # Disable tests to focus on library build
    "-DCMAKE_CXX_FLAGS=-w" # Will be overridden by preConfigure
    "-DOpenMP_CXX_INCLUDE_DIRS=${rocmPackages.llvm.openmp.dev}/include" # Explicit include path for OpenMP
  ]
  ++ lib.optionals (rocmSupport && gpuTargets != [ ]) [
    "-DCMAKE_HIP_ARCHITECTURES=${lib.concatStringsSep ";" gpuTargets}"
  ]
  ++ lib.optionals rocmSupport [
    "-DCMAKE_HIP_COMPILER=${rocmPackages.clr.hipClangPath}/clang++"
    "-DCMAKE_HIP_COMPILE_OPTIONS=-I${rocmPackages.hiprand}/include;-I${rocmPackages.rocrand}/include"
    "-DCMAKE_SKIP_BUILD_RPATH=FALSE"
    "-DCMAKE_BUILD_WITH_INSTALL_RPATH=TRUE"
    "-DCMAKE_INSTALL_RPATH_USE_LINK_PATH=TRUE"
    "-DOpenMP_C_FLAGS=-fopenmp"
    "-DOpenMP_CXX_FLAGS=-fopenmp"
    "-DOpenMP_C_LIB_NAMES=omp"
    "-DOpenMP_CXX_LIB_NAMES=omp"
    "-DOpenMP_omp_LIBRARY=${rocmPackages.llvm.openmp}/lib/libomp.so"
    "-DOpenMP_C_INCLUDE_DIR=${rocmPackages.llvm.openmp.dev}/include"
    "-DOpenMP_CXX_INCLUDE_DIR=${rocmPackages.llvm.openmp.dev}/include"
  ]
  ++ lib.optional stdenv.hostPlatform.isDarwin "-DWITH_ACCELERATE=ON";

  CFLAGS = lib.optionalString rocmSupport "-I${rocmPackages.llvm.openmp.dev}/include -I${rocmPackages.hiprand}/include -I${rocmPackages.rocrand}/include";
  CXXFLAGS = lib.optionalString rocmSupport "-I${rocmPackages.llvm.openmp.dev}/include -I${rocmPackages.hiprand}/include -I${rocmPackages.rocrand}/include";

  preConfigure = lib.optionalString rocmSupport ''
    echo "=== DEBUG: Checking hiprand/rocrand headers ==="
    find /nix/store -name "hiprand_kernel.h" | head -5
    find /nix/store -name "rocrand.h" | head -5
    ls -la ${rocmPackages.hiprand}/include/hiprand/ || true
    ls -la ${rocmPackages.rocrand}/include/rocrand/ || true

    # Set HIP-specific environment variables for proper compilation
    export HIP_PATH="${rocmPackages.clr}"
    export HIP_INCLUDE_PATH="${rocmPackages.clr}/include:${rocmPackages.hiprand}/include:${rocmPackages.rocrand}/include"
    export HIPCXX="${rocmPackages.clr.hipClangPath}/clang++"

    # Set CMAKE flags with all necessary includes
    export CMAKE_CXX_FLAGS="-w -I${rocmPackages.llvm.openmp.dev}/include -I${rocmPackages.hiprand}/include -I${rocmPackages.rocrand}/include"

    echo "HIP_PATH: $HIP_PATH"
    echo "HIP_INCLUDE_PATH: $HIP_INCLUDE_PATH"
    echo "CMAKE_CXX_FLAGS: $CMAKE_CXX_FLAGS"
  '';

  buildInputs =
    lib.optionals withMkl [
      mkl
    ]
    ++ lib.optionals rocmSupport [
      rocmPackages.clr
      rocmPackages.hipblas
      rocmPackages.rocblas
      rocmPackages.hiprand
      rocmPackages.rocrand
      rocmPackages.rocprim
      rocmPackages.rocthrust
      rocmPackages.hipcub
      rocmPackages.miopen-hip
      rocmPackages.llvm.openmp
    ]
    ++ lib.optionals withOneDNN [
      oneDNN
    ]
    ++ lib.optionals withOpenblas [
      openblas
    ]
    ++ lib.optionals (!rocmSupport && stdenv.hostPlatform.isDarwin) [
      stdenv.cc.cc.lib
    ];

  meta = with lib; {
    description = "Fast inference engine for Transformer models with ROCm support";
    mainProgram = "ct2-translator";
    homepage = "https://github.com/arlo-phoenix/CTranslate2-rocm";
    changelog = "https://github.com/arlo-phoenix/CTranslate2-rocm/blob/${src.rev}/README_ROCM.md";
    license = licenses.mit;
    maintainers = with maintainers; [
      # Add yourself as maintainer here
    ];
    platforms = platforms.linux; # ROCm is Linux-only
  };
}